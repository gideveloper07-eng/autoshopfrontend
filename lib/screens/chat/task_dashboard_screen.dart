import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({super.key});

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _tasks = [];
  bool _loading = true;

  // Filter
  String _statusFilter = 'All';
  late TabController _tabController;

  static const List<String> _statusOptions = [
    'All', 'Pending', 'In Progress', 'Completed', 'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  static const String _cacheKey = 'task_dashboard_all';

  Future<void> _loadTasks() async {
    // ── Step 1: Show cached tasks immediately ─────────────────────────────
    final cached = await CacheService.getList(
      _cacheKey,
      ttlMs: CacheService.ttlMedium,
    );
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _tasks = cached;
        _loading = false;
      });
    } else {
      setState(() => _loading = true);
    }

    // ── Step 2: Fetch fresh from backend ──────────────────────────────────
    final results = await Future.wait([
      ApiService.getTasks(),
      ApiService.getIndividualTasks(),
      ApiService.getGroupTasks(),
    ]);

    final challanTasks    = results[0];
    final individualTasks = results[1];
    final groupTasks      = results[2];

    for (final t in challanTasks) {
      t['TaskSource'] ??= t['GroupId'] != null ? 'Group'
          : t['ChallanId'] != null ? 'Challan'
          : 'Individual';
    }
    for (final t in individualTasks) {
      t['TaskSource'] ??= 'Individual';
    }
    for (final t in groupTasks) {
      t['TaskSource'] ??= 'Group';
    }

    final seen = <String>{};
    final merged = <dynamic>[];
    for (final t in [...challanTasks, ...individualTasks, ...groupTasks]) {
      final id = t['TaskId']?.toString() ?? '';
      if (id.isNotEmpty && seen.add(id)) merged.add(t);
    }

    merged.sort((a, b) {
      final da = DateTime.tryParse(a['CreatedDate']?.toString() ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['CreatedDate']?.toString() ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    // ── Step 3: Update cache ──────────────────────────────────────────────
    if (merged.isNotEmpty) {
      await CacheService.setList(_cacheKey, merged);
    }

    if (!mounted) return;
    setState(() {
      _tasks = merged;
      _loading = false;
    });
  }

  // ── Derived lists per tab ─────────────────────────────────────────────────

  List<dynamic> _filtered(String source) {
    return _tasks.where((t) {
      final src = (t['TaskSource']?.toString() ?? '');
      final matchSrc = source == 'All' || src == source;
      final matchStatus = _statusFilter == 'All' ||
          (t['Status']?.toString() ?? '') == _statusFilter;
      return matchSrc && matchStatus;
    }).toList();
  }

  // ── Counts ────────────────────────────────────────────────────────────────

  int _count(String status) =>
      _tasks.where((t) => t['Status']?.toString() == status).length;

  // ── Status update ─────────────────────────────────────────────────────────

  Future<void> _updateStatus(dynamic task, String newStatus) async {
    final taskId     = task['TaskId']?.toString()    ?? '';
    final taskDb     = task['TaskDatabase']?.toString() ?? '';
    final groupId    = task['GroupId']?.toString()   ?? '';
    final source     = task['TaskSource']?.toString() ?? '';

    bool ok = false;

    if (source == 'Group' && groupId.isNotEmpty) {
      // Group tasks — use /api/group/update-task-status
      ok = await ApiService.updateTaskStatus(
        taskId: taskId,
        status: newStatus,
        groupId: groupId,
        taskDatabase: taskDb.isNotEmpty ? taskDb : null,
      );
    } else {
      // Challan / Individual tasks — use /api/chat/update-task-status
      ok = await ApiService.updateChatTaskStatus(
        taskId: taskId,
        status: newStatus,
      );
    }

    if (!mounted) return;
    if (ok) {
      setState(() => task['Status'] = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: const Color(0xFF111B21),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(14),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update status'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(14),
        ),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':   return Colors.red;
      case 'medium': return Colors.orange;
      case 'low':    return Colors.green;
      default:       return Colors.grey;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':     return Colors.orange;
      case 'in progress': return Colors.blue;
      case 'completed':   return Colors.green;
      case 'cancelled':   return Colors.grey;
      default:            return Colors.grey;
    }
  }

  Color _sourceColor(String s) {
    switch (s.toLowerCase()) {
      case 'group':      return const Color(0xFF1565C0);
      case 'challan':    return const Color(0xFF00695C);
      case 'individual': return const Color(0xFF6A1B9A);
      default:           return Colors.grey;
    }
  }

  IconData _sourceIcon(String s) {
    switch (s.toLowerCase()) {
      case 'group':      return Icons.groups_outlined;
      case 'challan':    return Icons.receipt_long_outlined;
      case 'individual': return Icons.person_outline;
      default:           return Icons.task_alt;
    }
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) { return ''; }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF4F6FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Task Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTasks,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Group'),
            Tab(text: 'Individual'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Stat row ────────────────────────────────────────
                _buildStatRow(),

                // ── Status filter chips ──────────────────────────────
                _buildStatusFilter(),

                // ── Tab content ──────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList(_filtered('All')),
                      _buildTaskList(_filtered('Group')),
                      _buildTaskList(_filtered('Individual')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatRow() {
    return Container(
      color: const Color(0xFF111B21),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          _statChip('Pending',     _count('Pending'),     Colors.orange),
          const SizedBox(width: 8),
          _statChip('In Progress', _count('In Progress'), Colors.blue),
          const SizedBox(width: 8),
          _statChip('Completed',   _count('Completed'),   Colors.green),
          const SizedBox(width: 8),
          _statChip('Total',       _tasks.length,         Colors.white54),
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
            Text('$count',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 46,
      color: Theme.of(context).colorScheme.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _statusOptions.length,
        separatorBuilder: (_, s) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s        = _statusOptions[i];
          final selected = s == _statusFilter;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _statusFilter = s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF111B21)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF111B21)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Text(
                s,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 56,
                color: Colors.grey.withOpacity(0.35)),
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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
        itemCount: tasks.length,
        itemBuilder: (_, i) => _buildTaskCard(tasks[i]),
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final title      = task['TaskTitle']?.toString()      ?? 'No Title';
    final desc       = task['TaskDescription']?.toString() ?? '';
    final assignedTo = task['AssignedToName']?.toString()
        ?? task['AssignedTo']?.toString() ?? '';
    final priority   = task['Priority']?.toString()  ?? '';
    final status     = task['Status']?.toString()    ?? 'Pending';
    final source     = task['TaskSource']?.toString() ?? 'Chat';
    final dueDate    = _fmtDate(task['DueDate']?.toString());
    final createdAt  = _fmtDate(task['CreatedDate']?.toString());

    final srcColor  = _sourceColor(source);
    final priColor  = _priorityColor(priority);
    final statColor = _statusColor(status);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final cardBg    = isDark ? const Color(0xFF1A2535) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(
          left: BorderSide(color: srcColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Top row: source badge + priority + status ──────────
            Row(
              children: [
                // Source badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: srcColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: srcColor.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_sourceIcon(source), size: 11, color: srcColor),
                      const SizedBox(width: 4),
                      Text(source,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: srcColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Priority badge
                if (priority.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(priority,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: priColor)),
                  ),

                const Spacer(),

                // Created date
                if (createdAt.isNotEmpty)
                  Text(createdAt,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 10),

            // ── Title ──────────────────────────────────────────────
            Text(title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                )),

            // ── Description ────────────────────────────────────────
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],

            const SizedBox(height: 10),

            // ── Assigned to + due date ─────────────────────────────
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignedTo.isNotEmpty ? assignedTo : '—',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (dueDate.isNotEmpty) ...[
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dueDate,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Status dropdown ────────────────────────────────────
            Row(
              children: [
                Text('Status:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7))),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: statColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: statColor.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: status,
                        isDense: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16, color: statColor),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statColor),
                        items: const [
                          DropdownMenuItem(
                              value: 'Pending',
                              child: Text('Pending')),
                          DropdownMenuItem(
                              value: 'In Progress',
                              child: Text('In Progress')),
                          DropdownMenuItem(
                              value: 'Completed',
                              child: Text('Completed')),
                          DropdownMenuItem(
                              value: 'Cancelled',
                              child: Text('Cancelled')),
                        ],
                        onChanged: (val) {
                          if (val != null && val != status) {
                            _updateStatus(task, val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use
