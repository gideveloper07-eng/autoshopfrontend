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
  String _timeFilter = 'All';
  late TabController _tabController;
  String get _currentSource {
    switch (_tabController.index) {
      case 1:
        return 'Group';
      case 2:
        return 'Individual';
      default:
        return 'All';
    }
  }

  static const List<String> _statusOptions = [
    'All',
    'Pending',
    'In Progress',
    'Completed',
    'Cancelled',
  ];
  static const List<String> _timeOptions = [
    'All',
    'Today',
    'Week',
    'Month',
    'Quarter',
    'Year',
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

    final challanTasks = results[0];
    final individualTasks = results[1];
    final groupTasks = results[2];

    for (final t in challanTasks) {
      t['TaskSource'] ??= t['GroupId'] != null
          ? 'Group'
          : t['ChallanId'] != null
          ? 'Challan'
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
      final da =
          DateTime.tryParse(a['CreatedDate']?.toString() ?? '') ??
          DateTime(2000);
      final db =
          DateTime.tryParse(b['CreatedDate']?.toString() ?? '') ??
          DateTime(2000);
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
      final matchStatus =
          _statusFilter == 'All' ||
          (t['Status']?.toString() ?? '') == _statusFilter;
      final createdDate = DateTime.tryParse(t['CreatedDate'] ?? '');

      final matchTime = createdDate == null
          ? true
          : _matchesTimeFilter(createdDate);
      return matchSrc && matchStatus && matchTime;
    }).toList();
  }

  // ── Counts ────────────────────────────────────────────────────────────────
  int _countFiltered(String status) {
    return _filtered(_currentSource).where((t) => t['Status'] == status).length;
  }

  int _count(String status) =>
      _tasks.where((t) => t['Status']?.toString() == status).length;

  // ── Status update ─────────────────────────────────────────────────────────

  Future<void> _updateStatus(dynamic task, String newStatus) async {
    final taskId = task['TaskId']?.toString() ?? '';
    final taskDb = task['TaskDatabase']?.toString() ?? '';
    final groupId = task['GroupId']?.toString() ?? '';
    final source = task['TaskSource']?.toString() ?? '';

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(14),
        ),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _sourceColor(String s) {
    switch (s.toLowerCase()) {
      case 'group':
        return const Color(0xFF1565C0);
      case 'challan':
        return const Color(0xFF00695C);
      case 'individual':
        return const Color(0xFF6A1B9A);
      default:
        return Colors.grey;
    }
  }

  IconData _sourceIcon(String s) {
    switch (s.toLowerCase()) {
      case 'group':
        return Icons.groups_outlined;
      case 'challan':
        return Icons.receipt_long_outlined;
      case 'individual':
        return Icons.person_outline;
      default:
        return Icons.task_alt;
    }
  }

  bool _matchesTimeFilter(DateTime date) {
    final now = DateTime.now();

    switch (_timeFilter) {
      case 'Today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

      case 'Week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));

        return !date.isBefore(start) && !date.isAfter(end);

      case 'Month':
        return date.year == now.year && date.month == now.month;

      case 'Quarter':
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;

        final taskQuarter = ((date.month - 1) ~/ 3) + 1;

        return date.year == now.year && currentQuarter == taskQuarter;

      case 'Year':
        return date.year == now.year;

      default:
        return true;
    }
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return '';
    }
  }

  void _showFilterBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Filters",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTimeFilter(modalSetState),
                      const SizedBox(height: 30),
                      _buildStatusFilter(modalSetState),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Apply Filters"),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardBg = theme.colorScheme.surface;
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
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
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
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
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                _buildStatRow(),
                const SizedBox(height: 10.0),

                if (!isMobile)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeFilter(null),

                        const Divider(height: 30),

                        _buildStatusFilter(null),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.filter_alt),
                          label: const Text("Filters"),
                          onPressed: _showFilterBottomSheet,
                        ),
                      ],
                    ),
                  ),

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF111B21) : const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          _statChip('Pending', _countFiltered('Pending'), Colors.orange),
          const SizedBox(width: 8),
          _statChip('In Progress', _countFiltered('In Progress'), Colors.blue),
          const SizedBox(width: 8),
          _statChip('Completed', _countFiltered('Completed'), Colors.green),
          const SizedBox(width: 8),
          _statChip('Total', _filtered(_currentSource).length,
              isDark ? Colors.white54 : Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    // "Total" chip resets filter to All; others toggle to that status
    final filterValue = label == 'Total' ? 'All' : label;
    final isActive = label == 'Total'
        ? _statusFilter == 'All'
        : _statusFilter == label;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _statusFilter = filterValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.22) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? color : color.withOpacity(0.3),
              width: isActive ? 1.8 : 1,
            ),
            boxShadow: isActive
                ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: isActive ? FontWeight.w700 : FontWeight.w400),
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Container(
                  width: 16,
                  height: 2,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(StateSetter? modalSetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.filter_alt_rounded, color: Color(0xFF1565C0), size: 20),
            SizedBox(width: 8),
            Text(
              "Status Filter",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _statusOptions.map((status) {
            final selected = status == _statusFilter;

            Color chipColor;

            switch (status) {
              case "Pending":
                chipColor = Colors.orange;
                break;
              case "In Progress":
                chipColor = Colors.blue;
                break;
              case "Completed":
                chipColor = Colors.green;
                break;
              case "Cancelled":
                chipColor = Colors.red;
                break;
              default:
                chipColor = const Color(0xFF111B21);
            }

            return ChoiceChip(
              selected: selected,

              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.check, size: 16, color: Colors.white),
                    ),
                  Text(status),
                ],
              ),

              onSelected: (value) {
                if (!value) return;

                setState(() {
                  _statusFilter = status;
                });

                modalSetState?.call(() {});
              },

              backgroundColor: Colors.grey.shade100,
              selectedColor: chipColor,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: selected ? chipColor : Colors.grey.shade300,
                ),
              ),

              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeFilter(StateSetter? modalSetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.schedule_rounded, color: Color(0xFF1565C0), size: 20),
            SizedBox(width: 8),
            Text(
              "Time Filter",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _timeOptions.map((filter) {
            final selected = filter == _timeFilter;

            Color chipColor;

            switch (filter) {
              case "Today":
                chipColor = Colors.blue;
                break;

              case "Week":
                chipColor = Colors.green;
                break;

              case "Month":
                chipColor = Colors.orange;
                break;

              case "Quarter":
                chipColor = Colors.purple;
                break;

              case "Year":
                chipColor = Colors.red;
                break;

              default:
                chipColor = const Color(0xFF111B21);
            }

            return ChoiceChip(
              selected: selected,

              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.check, size: 16, color: Colors.white),
                    ),
                  Text(filter),
                ],
              ),

              onSelected: (value) {
                if (!value) return;

                setState(() {
                  _timeFilter = filter;
                });

                modalSetState?.call(() {});
              },

              backgroundColor: Colors.grey.shade100,
              selectedColor: chipColor,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: selected ? chipColor : Colors.grey.shade300,
                ),
              ),

              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTaskList(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt,
              size: 56,
              color: Colors.grey.withOpacity(0.35),
            ),
            const SizedBox(height: 12),
            Text(
              _statusFilter == 'All'
                  ? 'No tasks yet'
                  : 'No $_statusFilter tasks',
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
    final title = task['TaskTitle']?.toString() ?? 'No Title';
    final desc = task['TaskDescription']?.toString() ?? '';
    final assignedTo =
        task['AssignedToName']?.toString() ??
        task['AssignedTo']?.toString() ??
        '';
    final priority = task['Priority']?.toString() ?? '';
    final status = task['Status']?.toString() ?? 'Pending';
    final source = task['TaskSource']?.toString() ?? 'Chat';
    final dueDate = _fmtDate(task['DueDate']?.toString());
    final createdAt = _fmtDate(task['CreatedDate']?.toString());

    final srcColor = _sourceColor(source);
    final priColor = _priorityColor(priority);
    final statColor = _statusColor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A2535) : Colors.white;

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
        border: Border(left: BorderSide(color: srcColor, width: 4)),
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
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: srcColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: srcColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_sourceIcon(source), size: 11, color: srcColor),
                      const SizedBox(width: 4),
                      Text(
                        source,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: srcColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Priority badge
                if (priority.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: priColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: priColor,
                      ),
                    ),
                  ),

                const Spacer(),

                // Created date
                if (createdAt.isNotEmpty)
                  Text(
                    createdAt,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Title ──────────────────────────────────────────────
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            // ── Description ────────────────────────────────────────
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],

            const SizedBox(height: 10),

            // ── Assigned to + due date ─────────────────────────────
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignedTo.isNotEmpty ? assignedTo : '—',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (dueDate.isNotEmpty) ...[
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dueDate,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Status dropdown ────────────────────────────────────
            Row(
              children: [
                Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statColor.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: status,
                        isDense: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: statColor,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statColor,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'In Progress',
                            child: Text('In Progress'),
                          ),
                          DropdownMenuItem(
                            value: 'Completed',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'Cancelled',
                            child: Text('Cancelled'),
                          ),
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
