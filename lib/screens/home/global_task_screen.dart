import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class GlobalTaskScreen extends StatefulWidget {
  /// When [openAssignDialog] is true and the user is admin,
  /// the "Assign Task" dialog opens automatically after loading.
  final bool openAssignDialog;

  const GlobalTaskScreen({super.key, this.openAssignDialog = false});

  @override
  State<GlobalTaskScreen> createState() => _GlobalTaskScreenState();
}

class _GlobalTaskScreenState extends State<GlobalTaskScreen> {
  List<dynamic> _tasks = [];
  bool _loading = true;
  bool _isAdmin = false;

  // Assign task dialog controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'Medium';
  DateTime? _startDate;
  DateTime? _dueDate;

  // Users list for assign-to dropdown
  List<Map<String, dynamic>> _users = [];
  String? _selectedUserId;

  // Filters
  String _statusFilter = 'All';

  static const List<String> _statusOptions = [
    'All', 'Pending', 'In Progress', 'Completed', 'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _isAdmin = await ApiService.isAdmin();
    if (_isAdmin) await _loadUsers();
    await _loadTasks();
    // Auto-open assign dialog if admin tapped the purple card directly
    if (mounted && _isAdmin && widget.openAssignDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAssignDialog();
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ApiService.getMergedUsers();
      if (mounted) setState(() => _users = users);
    } catch (_) {}
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      // get-tasks returns all tasks for admin, own tasks for non-admin
      final tasks = await ApiService.getTasks();
      // Also fetch individual tasks (global ones) not tied to challan/group
      final individualTasks = await ApiService.getIndividualTasks();

      // Merge & deduplicate
      final seen = <String>{};
      final merged = <dynamic>[];
      for (final t in [...tasks, ...individualTasks]) {
        final id = t['TaskId']?.toString() ?? '';
        if (id.isNotEmpty && seen.add(id)) merged.add(t);
      }
      merged.sort((a, b) {
        final da = DateTime.tryParse(a['CreatedDate']?.toString() ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['CreatedDate']?.toString() ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });
      if (mounted) setState(() { _tasks = merged; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    return _tasks.where((t) {
      if (_statusFilter == 'All') return true;
      return (t['Status']?.toString() ?? '') == _statusFilter;
    }).toList();
  }

  Future<void> _updateStatus(dynamic task, String newStatus) async {
    // Only admin can update task status
    if (!_isAdmin) return;

    final taskId = task['TaskId']?.toString() ?? '';
    final groupId = task['GroupId']?.toString() ?? '';
    final source = task['TaskSource']?.toString() ?? '';
    final taskDb = task['TaskDatabase']?.toString() ?? '';

    bool ok;
    if (source == 'Group' && groupId.isNotEmpty) {
      ok = await ApiService.updateTaskStatus(
        taskId: taskId, status: newStatus,
        groupId: groupId,
        taskDatabase: taskDb.isNotEmpty ? taskDb : null,
      );
    } else {
      ok = await ApiService.updateChatTaskStatus(taskId: taskId, status: newStatus);
    }
    if (!mounted) return;
    if (ok) {
      setState(() => task['Status'] = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status updated to $newStatus'),
        backgroundColor: const Color(0xFF111B21),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to update status'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Non-admin: notify admin without changing DB status
  Future<void> _notifyTaskComplete(dynamic task) async {
    final taskId = task['TaskId']?.toString() ?? '';
    if (taskId.isEmpty) return;

    final ok = await ApiService.notifyTaskComplete(taskId: taskId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Admin has been notified. They will update the status.')),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 4),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to notify admin. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showAssignDialog() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _priority = 'Medium';
    _startDate = null;
    _dueDate = null;
    _selectedUserId = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Assign Task'),
          content: SizedBox(
            width: MediaQuery.sizeOf(ctx).width < 500
                ? double.infinity
                : 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Task Title
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Assign To
                  DropdownButtonFormField<String>(
                    value: _selectedUserId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Assign To',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: _users.map((u) {
                      final id = u['UserId']?.toString() ?? u['id']?.toString() ?? '';
                      final name = u['UserName']?.toString() ?? u['name']?.toString() ?? id;
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setDlg(() {
                        _selectedUserId = v;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Priority
                  DropdownButtonFormField<String>(
                    value: _priority,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'High', child: Text('High')),
                    ],
                    onChanged: (v) => setDlg(() => _priority = v!),
                  ),
                  const SizedBox(height: 12),

                  // Start Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDlg(() => _startDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        _startDate != null
                            ? '${_startDate!.day.toString().padLeft(2, '0')} '
                              '${_monthName(_startDate!.month)} '
                              '${_startDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          color: _startDate != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Due Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: _dueDate ?? (_startDate ?? DateTime.now()),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDlg(() => _dueDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        _dueDate != null
                            ? '${_dueDate!.day.toString().padLeft(2, '0')} '
                              '${_monthName(_dueDate!.month)} '
                              '${_dueDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          color: _dueDate != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_titleCtrl.text.trim().isEmpty || _selectedUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill title and select a user')),
                  );
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                final ok = await ApiService.createGlobalTask(
                  receiverId: _selectedUserId!,
                  taskTitle: _titleCtrl.text.trim(),
                  taskDescription: _descCtrl.text.trim(),
                  priority: _priority,
                  startDate: _startDate?.toIso8601String(),
                  dueDate: _dueDate?.toIso8601String(),
                );
                if (!mounted) return;
                navigator.pop();
                if (ok) {
                  await _loadTasks();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Task assigned successfully')),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Failed to assign task'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'in progress': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(raw)); }
    catch (_) { return ''; }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tasks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTasks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAssignDialog,
              icon: const Icon(Icons.add),
              label: const Text('Assign Task'),
              backgroundColor: const Color(0xFF00695C),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Stats bar ──────────────────────────────────────
                _buildStatBar(),
                // ── Status filter chips ────────────────────────────
                _buildStatusFilter(),
                // ── Task list ──────────────────────────────────────
                Expanded(child: _buildTaskList()),
              ],
            ),
    );
  }

  Widget _buildStatBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final all = _tasks;
    int count(String s) => all.where((t) => t['Status']?.toString() == s).length;
    return Container(
      color: isDark ? const Color(0xFF111B21) : const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _statChip('Pending', count('Pending'), Colors.orange),
          const SizedBox(width: 8),
          _statChip('In Progress', count('In Progress'), Colors.blue),
          const SizedBox(width: 8),
          _statChip('Completed', count('Completed'), Colors.green),
          const SizedBox(width: 8),
          _statChip('Total', all.length, isDark ? Colors.white54 : Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((s) {
            final selected = s == _statusFilter;
            final color = s == 'Pending' ? Colors.orange
                : s == 'In Progress' ? Colors.blue
                : s == 'Completed' ? Colors.green
                : s == 'Cancelled' ? Colors.grey
                : const Color(0xFF111B21);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selected,
                label: Text(s),
                selectedColor: color,
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: selected ? color : Colors.grey.shade300),
                ),
                onSelected: (_) => setState(() => _statusFilter = s),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    final tasks = _filtered;
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 56, color: Colors.grey.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text(
              _statusFilter == 'All' ? 'No tasks yet' : 'No $_statusFilter tasks',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
        itemCount: tasks.length,
        itemBuilder: (_, i) => _buildTaskCard(tasks[i]),
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final title = task['TaskTitle']?.toString() ?? 'No Title';
    final desc = task['TaskDescription']?.toString() ?? '';
    final assignedTo = task['AssignedToName']?.toString() ?? task['AssignedTo']?.toString() ?? '';
    final priority = task['Priority']?.toString() ?? '';
    final status = task['Status']?.toString() ?? 'Pending';
    final dueDate = _fmtDate(task['DueDate']?.toString());
    final createdAt = _fmtDate(task['CreatedDate']?.toString());
    final priColor = _priorityColor(priority);
    final statColor = _statusColor(status);
    final cardBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A2535)
        : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border(left: BorderSide(color: statColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: priority + created date ──────────────────
            Row(
              children: [
                if (priority.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(priority, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: priColor)),
                  ),
                const Spacer(),
                if (createdAt.isNotEmpty)
                  Text(createdAt, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            // ── Title ──────────────────────────────────────────────
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
            const SizedBox(height: 10),
            // ── Assigned info ──────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignedTo.isNotEmpty ? assignedTo : '—',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (dueDate.isNotEmpty) ...[
                  const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dueDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // ── Status: editable for admin, read-only + complete button for non-admin ─
            Row(
              children: [
                Text('Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statColor.withOpacity(0.3)),
                    ),
                    child: _isAdmin
                        ? DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: status,
                              isDense: true,
                              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: statColor),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statColor),
                              items: const [
                                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                                DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                              ],
                              onChanged: (val) {
                                if (val != null && val != status) _updateStatus(task, val);
                              },
                            ),
                          )
                        : Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statColor)),
                  ),
                ),
                // ── Mark Complete button for non-admin ─────────────
                if (!_isAdmin && status != 'Completed') ...[
                  const SizedBox(width: 10),
                  Tooltip(
                    message: 'Mark as Complete',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Complete Task'),
                            content: const Text('Mark this task as completed?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Complete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) _notifyTaskComplete(task);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Complete',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                // ── Already completed badge for non-admin ───────────
                if (!_isAdmin && status == 'Completed') ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use
