import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'group_chat_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  List<dynamic> groups = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  Future<void> loadGroups() async {
    try {
      final data = await ApiService.getMyGroups();

      if (!mounted) return;

      setState(() {
        groups = data;
        loading = false;
      });
    } catch (e) {
      print("GROUP LOAD ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No Groups Found",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];

          final groupId = group["GroupId"]?.toString() ?? "";

          final groupName = group["GroupName"]?.toString() ?? "Group";

          final memberCount = group["MemberCount"]?.toString() ?? "0";

          final avatarText = groupName.isNotEmpty
              ? groupName.substring(0, 1).toUpperCase()
              : "G";

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),

              leading: CircleAvatar(
                radius: 24,
                child: Text(
                  avatarText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              title: Text(
                groupName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("$memberCount Members"),
              ),

              trailing: const Icon(Icons.chevron_right),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        GroupChatScreen(groupId: groupId, groupName: groupName),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
