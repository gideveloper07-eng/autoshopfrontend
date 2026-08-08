import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../main.dart' show taskCompleteStreamController, pendingTaskCompletions, pendingTaskCompletionCount;

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({super.key});

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _tasks = [];
  bool _loading = true;
  bool _isAdmin = false;

  // ── Task completion notification banner ───────────────────────────────────
  StreamSubscription<Map<String, String>>? _completionSub;
  // List of pending completion notifications to show as banners
  final List<Map<String, String>> _completionBanners = [];
  
  // ── Repeating notification system ──────────────────────────────────────────
  // Track tasks that have been marked complete but not yet reviewed by admin
  // Map<taskId, {taskTitle, completedBy, timestamp}>
  final Map<String, Map<String, dynamic>> _pendingCompletions = {};
  Timer? _reminderTimer;

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
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    _isAdmin = await ApiService.isAdmin();
    // Only admins need the completion banner stream
    if (_isAdmin) {
      // Load any pending notifications that arrived before the dashboard opened
      if (pendingTaskCompletions.isNotEmpty) {
        for (final item in List<Map<String, String>>.from(pendingTaskCompletions)) {
          _addPendingCompletion(item);
        }
        pendingTaskCompletions.clear();
        pendingTaskCompletionCount.value = 0;
        setState(() {});
      }
      // Listen for new ones arriving while dashboard is open
      _completionSub = taskCompleteStreamController.stream.listen((data) {
        if (mounted) {
          _addPendingCompletion(data);
          // Remove from pending since dashboard is now open
          pendingTaskCompletions.remove(data);
          pendingTaskCompletionCount.value = pendingTaskCompletions.length;
          setState(() {});
        }
      });

      // ── Repeating reminder: re-show banner every 2 minutes if
      //    admin hasn't acted yet ──────────────────────────────────
      _reminderTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        if (!mounted || _pendingCompletions.isEmpty) return;
        // Re-add banners for all tasks still waiting for admin review
        setState(() {
          for (final entry in _pendingCompletions.entries) {
            final taskId = entry.key;
            final info = entry.value;
            // Only add a new banner if one isn't already visible for this task
            final alreadyShowing = _completionBanners.any(
              (b) => b['taskId'] == taskId,
            );
            if (!alreadyShowing) {
              _completionBanners.add({
                'taskId': taskId,
                'taskTitle': info['taskTitle'] as String,
                'completedBy': info['completedBy'] as String,
              });
            }
          }
        });
      });
    }
    _loadTasks();
  }

  void _addPendingCompletion(Map<String, String> data) {
    final taskId = data['taskId'] ?? data['taskTitle'] ?? '';
    if (taskId.isEmpty) return;
    // Track in persistent pending map so reminders keep firing
    _pendingCompletions[taskId] = {
      'taskTitle': data['taskTitle'] ?? '',
      'completedBy': data['completedBy'] ?? '',
      'timestamp': DateTime.now(),
    };
    // Show banner immediately
    _completionBanners.add({
      'taskId': taskId,
      'taskTitle': data['taskTitle'] ?? '',
      'completedBy': data['completedBy'] ?? '',
    });
  }

  /// Called when admin updates a task status — removes it from the
  /// repeating-reminder tracking so the banner stops firing.
  void _clearPendingCompletion(String taskId) {
    _pendingCompletions.remove(taskId);
  }

  @override
  void dispose() {
    _completionSub?.cancel();
    _reminderTimer?.cancel();
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
    // Only admin can update task status
    if (!_isAdmin) return;

    final taskId = task['TaskId']?.toString() ?? '';
    final taskDb = task['TaskDatabase']?.toString() ?? '';
    final groupId = task['GroupId']?.toString() ?? '';
    final source = task['TaskSource']?.toString() ?? '';

    bool ok = false;

    if (source == 'Group' && groupId.isNotEmpty) {
      ok = await ApiService.updateTaskStatus(
        taskId: taskId,
        status: newStatus,
        groupId: groupId,
        taskDatabase: taskDb.isNotEmpty ? taskDb : null,
      );
    } else {
      ok = await ApiService.updateChatTaskStatus(
        taskId: taskId,
        status: newStatus,
      );
    }

    if (!mounted) return;
    if (ok) {
      setState(() => task['Status'] = newStatus);
      // ── Clear from pending completions so reminders stop ──────────────
      _clearPendingCompletion(taskId);
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

  // ── Non-admin: notify admin without touching DB status ────────────────────

  Future<void> _notifyTaskComplete(dynamic task) async {
    final taskId = task['TaskId']?.toString() ?? '';
    if (taskId.isEmpty) return;

    final ok = await ApiService.notifyTaskComplete(taskId: taskId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Admin has been notified. They will update the status.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(14),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to notify admin. Please try again.'),
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

  // ── Performance scoring ───────────────────────────────────────────────────
  //
  // Scoring (0-100) computed purely from existing fields — no new DB columns.
  //
  //  Completion  (50 pts max)
  //    Completed   → 50
  //    In Progress → 20
  //    Pending     →  0
  //    Cancelled   →  0
  //
  //  Timeliness  (30 pts max)   — needs DueDate
  //    Completed on-time/early  → 30
  //    Completed ≤3 days late   → 15
  //    Completed >3 days late   →  5
  //    Not completed, overdue   →  0  (penalty applied below)
  //    No DueDate               → 15  (neutral)
  //
  //  Quality/Priority bonus (20 pts max) — only if Completed
  //    High   → +20
  //    Medium → +10
  //    Low    →  +5
  //
  //  Overdue penalty (for Pending/In Progress past DueDate): –10
  //
  //  Final = clamp(sum, 0, 100)

  int _calcScore(dynamic task) {
    final status = task['Status']?.toString() ?? 'Pending';
    final priority = task['Priority']?.toString() ?? 'Medium';
    final dueDateRaw = task['DueDate']?.toString();
    final now = DateTime.now();

    int score = 0;

    // 1. Completion score
    if (status == 'Completed') {
      score += 50;
    } else if (status == 'In Progress') {
      score += 20;
    }

    // 2. Timeliness score
    final dueDate = dueDateRaw != null ? DateTime.tryParse(dueDateRaw) : null;
    if (dueDate == null) {
      score += 15; // neutral — no due date set
    } else if (status == 'Completed') {
      // Use CreatedDate as proxy for completion date (best available)
      // In practice completedDate ≈ last updated, but we don't store it.
      // We compare now (when admin marks complete) vs dueDate.
      final diff = now.difference(dueDate).inDays;
      if (diff <= 0) {
        score += 30; // on-time or early
      } else if (diff <= 3) {
        score += 15; // slightly late
      } else {
        score += 5; // very late but done
      }
    } else {
      // Not completed — check if overdue
      if (now.isAfter(dueDate)) {
        score -= 10; // overdue penalty
      } else {
        score += 15; // still within deadline
      }
    }

    // 3. Priority bonus — only awarded on completion
    if (status == 'Completed') {
      switch (priority.toLowerCase()) {
        case 'high':
          score += 20;
          break;
        case 'medium':
          score += 10;
          break;
        case 'low':
          score += 5;
          break;
      }
    }

    return score.clamp(0, 100);
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF2E7D32); // dark green
    if (score >= 60) return const Color(0xFF388E3C); // green
    if (score >= 40) return const Color(0xFFF57C00); // orange
    if (score >= 20) return const Color(0xFFE64A19); // deep orange
    return const Color(0xFFC62828); // red
  }

  String _scoreGrade(int score) {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B+';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 35) return 'D';
    return 'F';
  }

  String _scoreLegend(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Average';
    if (score >= 20) return 'Below Average';
    return 'Poor';
  }

  /// Builds the per-employee performance summary card shown above task list.
  /// Groups tasks by AssignedTo, calculates avg score per employee.
  Widget _buildPerformanceSummary(List<dynamic> tasks) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    // Group tasks by employee
    final Map<String, List<dynamic>> byEmployee = {};
    for (final t in tasks) {
      final emp =
          t['AssignedToName']?.toString() ??
          t['AssignedTo']?.toString() ??
          'Unknown';
      byEmployee.putIfAbsent(emp, () => []).add(t);
    }

    // Sort employees by avg score descending
    final entries = byEmployee.entries.toList()
      ..sort((a, b) {
        final avgA =
            a.value.map(_calcScore).fold(0, (s, v) => s + v) ~/
            a.value.length;
        final avgB =
            b.value.map(_calcScore).fold(0, (s, v) => s + v) ~/
            b.value.length;
        return avgB.compareTo(avgA);
      });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A2535) : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.07),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Theme(
            data:
                Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              leading: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF1565C0),
                  size: 20,
                ),
              ),
              title: const Text(
                'Employee Performance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1565C0),
                ),
              ),
              subtitle: Text(
                '${entries.length} employee${entries.length == 1 ? '' : 's'} · tap to expand',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              children: entries.map((entry) {
                final emp = entry.key;
                final empTasks = entry.value;
                final total = empTasks.length;
                final completed = empTasks
                    .where((t) => t['Status'] == 'Completed')
                    .length;
                final inProgress = empTasks
                    .where((t) => t['Status'] == 'In Progress')
                    .length;
                final overdue = empTasks.where((t) {
                  final due =
                      DateTime.tryParse(t['DueDate']?.toString() ?? '');
                  final st = t['Status']?.toString() ?? '';
                  return due != null &&
                      DateTime.now().isAfter(due) &&
                      st != 'Completed' &&
                      st != 'Cancelled';
                }).length;

                final avgScore =
                    empTasks.map(_calcScore).fold(0, (s, v) => s + v) ~/
                    total;
                final scoreColor = _scoreColor(avgScore);
                final grade = _scoreGrade(avgScore);
                final legend = _scoreLegend(avgScore);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      // Employee name + grade badge
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: scoreColor.withOpacity(0.15),
                            child: Text(
                              emp.isNotEmpty ? emp[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: scoreColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emp,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '$total task${total == 1 ? '' : 's'}'
                                  '  ·  $completed completed'
                                  '  ·  $inProgress in-progress'
                                  '${overdue > 0 ? '  ·  $overdue overdue' : ''}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Grade badge
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: scoreColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: scoreColor, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                grade,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: scoreColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Score bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: avgScore / 100,
                                minHeight: 7,
                                backgroundColor: scoreColor.withOpacity(0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  scoreColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$avgScore / 100',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: scoreColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· $legend',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
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
    return Stack(
      children: [
        Scaffold(
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
        ),
        // ── Completion notification banners ────────────────────────
        if (_isAdmin && _completionBanners.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: _completionBanners.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final banner = entry.value;
                  return _TaskCompletionBanner(
                    key: ValueKey('${banner['taskId']}_$idx'),
                    taskTitle: banner['taskTitle'] ?? '',
                    completedBy: banner['completedBy'] ?? '',
                    onDismiss: () {
                      setState(() => _completionBanners.removeAt(idx));
                    },
                  );
                }).toList(),
              ),
            ),
          ),
      ],
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
        itemCount: tasks.length + (_isAdmin ? 1 : 0),
        itemBuilder: (_, i) {
          // Admin sees the performance summary as the first item
          if (_isAdmin && i == 0) return _buildPerformanceSummary(tasks);
          final task = tasks[_isAdmin ? i - 1 : i];
          return _buildTaskCard(task);
        },
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: _isAdmin ? 2 : 4,
                    ),
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
                          )
                        : Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statColor,
                            ),
                          ),
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
                            content: const Text(
                              'Mark this task as completed?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Complete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) _notifyTaskComplete(task);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Colors.green,
                            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
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

            // ── Performance score row ──────────────────────────────
            Builder(builder: (_) {
              final score = _calcScore(task);
              final sColor = _scoreColor(score);
              final grade = _scoreGrade(score);
              final legend = _scoreLegend(score);
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Performance:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$score / 100',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: sColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: sColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                            border:
                                Border.all(color: sColor.withOpacity(0.35)),
                          ),
                          child: Text(
                            grade,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: sColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          legend,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        minHeight: 5,
                        backgroundColor: sColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(sColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── In-screen task completion banner ─────────────────────────────────────────

class _TaskCompletionBanner extends StatefulWidget {
  final String taskTitle;
  final String completedBy;
  final VoidCallback onDismiss;

  const _TaskCompletionBanner({
    super.key,
    required this.taskTitle,
    required this.completedBy,
    required this.onDismiss,
  });

  @override
  State<_TaskCompletionBanner> createState() => _TaskCompletionBannerState();
}

class _TaskCompletionBannerState extends State<_TaskCompletionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();

    // Auto-dismiss after 45 seconds (stays visible until admin reads it)
    Future.delayed(const Duration(seconds: 45), _dismiss);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade400, width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Task Completed by User',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.completedBy} completed: "${widget.taskTitle}"',
                        style: TextStyle(
                          color: Colors.green.shade100,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please review and update the task status below.',
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _dismiss,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use
