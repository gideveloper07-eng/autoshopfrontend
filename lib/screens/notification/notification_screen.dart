import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    // ── Step 1: Show cached notifications immediately ─────────────────────
    final cached = await CacheService.getListMap(
      CacheService.keyNotifications,
      ttlMs: CacheService.ttlShort,
    );
    if (cached != null && mounted) {
      setState(() {
        notifications = _filterRecent(cached);
        isLoading = false;
      });
    }

    // ── Step 2: Fetch fresh from backend ─────────────────────────────────
    final data = await ApiService.getNotifications();
    if (!mounted) return;

    // ── Step 3: Update cache ──────────────────────────────────────────────
    if (data.isNotEmpty) {
      await CacheService.setListMap(
        CacheService.keyNotifications,
        List<Map<String, dynamic>>.from(data),
      );
    }

    final filtered = _filterRecent(List<Map<String, dynamic>>.from(data));
    setState(() {
      notifications = filtered;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> _filterRecent(List<Map<String, dynamic>> data) {
    final now = DateTime.now();
    return data.where((item) {
      try {
        final createdDate = DateTime.parse(item["created_on"].toString());
        return now.difference(createdDate).inDays <= 7;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Clear All"),
                    content: const Text(
                      "Are you sure you want to clear all notifications?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Clear"),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                // Call backend to delete all notifications from DB
                final success = await ApiService.clearAllNotifications();

                if (!mounted) return;

                if (success) {
                  // Clear local cache and in-memory list
                  await CacheService.delete(CacheService.keyNotifications);
                  setState(() => notifications.clear());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All notifications cleared")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to clear notifications. Please try again."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text(
              "Clear All",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("No notifications"))
          : RefreshIndicator(
              onRefresh: loadNotifications,
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final isRead = item["is_read"] == true || item["is_read"] == 1;

                  final cardColor = isDark
                      ? (isRead
                          ? const Color(0xFF1E2535)
                          : const Color(0xFF1A2A45))
                      : (isRead ? Colors.white : Colors.blue.shade50);

                  final borderColor = isDark
                      ? Colors.blue.withOpacity(0.25)
                      : Colors.blue.shade100;

                  final isApproved = item["type"] == "CHALLAN_APPROVED";
                  final avatarBg = isDark
                      ? (isApproved
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2))
                      : (isApproved
                          ? Colors.green.shade100
                          : Colors.red.shade100);

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(isDark ? 0.04 : 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () async {
                          await ApiService.markNotificationAsRead(
                            item["id"].toString(),
                          );
                          // Invalidate cache so next open fetches fresh
                          await CacheService.delete(
                              CacheService.keyNotifications);
                          loadNotifications();
                        },
                        leading: CircleAvatar(
                          backgroundColor: avatarBg,
                          child: Icon(
                            isApproved ? Icons.check : Icons.close,
                            color: isApproved ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          item["title"] ?? "",
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(item["message"] ?? ""),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item["created_on"]
                                      ?.toString()
                                      .split("T")
                                      .first ??
                                  "",
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
