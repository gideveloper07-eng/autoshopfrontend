import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({super.key});

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen> {
  List<dynamic> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);

    final data = await ApiService.getTasks();

    if (!mounted) return;

    setState(() {
      _tasks = data;
      _loading = false;
    });
  }

  int get pendingCount => _tasks.where((e) => e["Status"] == "Pending").length;

  int get progressCount =>
      _tasks.where((e) => e["Status"] == "In Progress").length;

  int get completedCount =>
      _tasks.where((e) => e["Status"] == "Completed").length;

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      case "low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "in progress":
        return Colors.blue;
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Returns whether the task came from a challan or a group
  String _taskSource(dynamic task) {
    final challanId = task["ChallanId"]?.toString() ?? "";
    final groupId = task["GroupId"]?.toString() ?? "";
    if (challanId.isNotEmpty) return "Challan";
    if (groupId.isNotEmpty) return "Group";
    return "Task";
  }

  IconData _taskSourceIcon(dynamic task) {
    final challanId = task["ChallanId"]?.toString() ?? "";
    if (challanId.isNotEmpty) return Icons.receipt_long_rounded;
    return Icons.group_rounded;
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  /// Update task status via API and refresh the list
  Future<void> _updateStatus(String taskId, String newStatus) async {
    final ok = await ApiService.updateTaskStatus(taskId, newStatus);
    if (ok && mounted) {
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Dashboard")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: Column(
                children: [
                  // ── Stats row ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            "Pending",
                            pendingCount.toString(),
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _statCard(
                            "In Progress",
                            progressCount.toString(),
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _statCard(
                            "Completed",
                            completedCount.toString(),
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Task list ──────────────────────────────────────────
                  Expanded(
                    child: _tasks.isEmpty
                        ? const Center(
                            child: Text(
                              "No Tasks Found",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              final status =
                                  task["Status"]?.toString() ?? "Pending";
                              final source = _taskSource(task);
                              final sourceIcon = _taskSourceIcon(task);

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ── Title + Source badge ────────
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              task["TaskTitle"]?.toString() ??
                                                  "",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Source badge (Challan / Group)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: source == "Challan"
                                                  ? const Color(0xFF3B2A96)
                                                      .withOpacity(0.1)
                                                  : const Color(0xFF075E54)
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: source == "Challan"
                                                    ? const Color(0xFF3B2A96)
                                                    : const Color(0xFF075E54),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  sourceIcon,
                                                  size: 12,
                                                  color: source == "Challan"
                                                      ? const Color(0xFF3B2A96)
                                                      : const Color(0xFF075E54),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  source,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: source == "Challan"
                                                        ? const Color(
                                                            0xFF3B2A96)
                                                        : const Color(
                                                            0xFF075E54),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      if ((task["TaskDescription"]
                                                  ?.toString() ??
                                              "")
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          task["TaskDescription"]
                                                  ?.toString() ??
                                              "",
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 10),

                                      Text(
                                        "Assigned To: ${task["AssignedToName"] ?? task["AssignedTo"] ?? ""}",
                                        style: const TextStyle(fontSize: 13),
                                      ),

                                      const SizedBox(height: 8),

                                      // ── Priority + Status row ───────
                                      Row(
                                        children: [
                                          // Priority badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _priorityColor(
                                                task["Priority"]?.toString() ??
                                                    "",
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              task["Priority"]?.toString() ??
                                                  "",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),

                                          const Spacer(),

                                          // Status dropdown
                                          PopupMenuButton<String>(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _statusColor(status),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    status,
                                                    style: TextStyle(
                                                      color:
                                                          _statusColor(status),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.arrow_drop_down,
                                                    size: 16,
                                                    color: _statusColor(status),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            itemBuilder: (_) => [
                                              "Pending",
                                              "In Progress",
                                              "Completed",
                                              "Cancelled",
                                            ]
                                                .where((s) => s != status)
                                                .map(
                                                  (s) => PopupMenuItem(
                                                    value: s,
                                                    child: Text(s),
                                                  ),
                                                )
                                                .toList(),
                                            onSelected: (newStatus) {
                                              _updateStatus(
                                                task["TaskId"]?.toString() ??
                                                    "",
                                                newStatus,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
