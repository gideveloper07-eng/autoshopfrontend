import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController messageController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  List<dynamic> messages = [];

  bool loading = true;

  String currentUserName = "";

  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();

    loadCurrentUser();

    loadMessages();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadMessages(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();

    messageController.dispose();

    scrollController.dispose();

    super.dispose();
  }

  Future<void> loadCurrentUser() async {
    currentUserName = await ApiService.getUserName() ?? "";
  }

  Future<void> loadMessages() async {
    try {
      final data = await ApiService.getGroupMessages(widget.groupId);

      if (!mounted) return;

      setState(() {
        messages = data;
        loading = false;
      });

      scrollToBottom();
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) {
      return;
    }

    final success = await ApiService.sendGroupMessage(
      groupId: widget.groupId,
      messageText: messageController.text.trim(),
    );

    if (success) {
      messageController.clear();

      await loadMessages();

      scrollToBottom();
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text("Group Chat", style: TextStyle(fontSize: 12)),
          ],
        ),

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),

            onSelected: (value) {
              switch (value) {
                case "members":
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("View Members")));
                  break;

                case "add":
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Add Member")));
                  break;

                case "remove":
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Remove Member")),
                  );
                  break;

                case "info":
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Group Info")));
                  break;
              }
            },

            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "members",
                child: Row(
                  children: [
                    Icon(Icons.people, size: 18),
                    SizedBox(width: 10),
                    Text("View Members"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "add",
                child: Row(
                  children: [
                    Icon(Icons.person_add, size: 18),
                    SizedBox(width: 10),
                    Text("Add Member"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "remove",
                child: Row(
                  children: [
                    Icon(Icons.person_remove, size: 18),
                    SizedBox(width: 10),
                    Text("Remove Member"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "info",
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 10),
                    Text("Group Info"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];

                      final senderName = msg["SenderName"]?.toString() ?? "";

                      final message = msg["MessageText"]?.toString() ?? "";

                      final isMine =
                          senderName.toLowerCase() ==
                          currentUserName.toLowerCase();

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(top: 4, bottom: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Colors.green.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMine)
                                Text(
                                  senderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),

                              if (!isMine) const SizedBox(height: 4),

                              Text(message),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    // PDF Share Later
                  },
                ),

                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
