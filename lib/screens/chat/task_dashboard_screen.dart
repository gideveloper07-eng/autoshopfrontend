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

    // Fetch group tasks and individual tasks separately, then merge
    final results = await Future.wait([
      ApiService.getTasks(),
      ApiService.getIndividualTasks(),
    ]);

    final groupTasks = results[0];
    final individualTasks = results[1];
    print("GROUP TASKS: ${groupTasks.length}");
    print(groupTasks);

    print("INDIVIDUAL TASKS: ${individualTasks.length}");
    print(individualTasks);
    // Merge and sort by CreatedDate descending
    final merged = [...groupTasks, ...individualTasks];
    merged.sort((a, b) {
      final dateA =
          DateTime.tryParse(a['CreatedDate']?.toString() ?? '') ??
          DateTime(2000);
      final dateB =
          DateTime.tryParse(b['CreatedDate']?.toString() ?? '') ??
          DateTime(2000);
      return dateB.compareTo(dateA);
    });

    if (!mounted) return;

    setState(() {
      _tasks = merged;
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

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task["TaskTitle"]?.toString() ?? "",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      Text(
                                        task["TaskDescription"]?.toString() ??
                                            "",
                                      ),

                                      const SizedBox(height: 10),

                                      Text(
                                        "Assigned To: ${task["AssignedToName"] ?? task["AssignedTo"] ?? ""}",
                                      ),

                                      const SizedBox(height: 6),

                                      Row(
                                        children: [
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
                                              ),
                                            ),
                                          ),

                                          const Spacer(),

                                          Chip(
                                            label: Text(
                                              task["Status"]?.toString() ?? "",
                                            ),
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
