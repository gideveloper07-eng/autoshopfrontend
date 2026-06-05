import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class ChallanChatDialog extends StatefulWidget {
  final String challanId;
  final String challanNo;

  const ChallanChatDialog({
    super.key,
    required this.challanId,
    required this.challanNo,
  });

  @override
  State<ChallanChatDialog> createState() => _ChallanChatDialogState();
}

class _ChallanChatDialogState extends State<ChallanChatDialog> {
  final TextEditingController messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  Timer? _refreshTimer;

  List<dynamic> messages = [];

  bool loading = true;

  String currentUserName = "";

  @override
  void initState() {
    super.initState();

    loadCurrentUser().then((_) {
      loadMessages();
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> loadCurrentUser() async {
    currentUserName = await ApiService.getUserName() ?? "";
  }

  Future<void> loadMessages() async {
    final data = await ApiService.getChatMessages(widget.challanId);

    if (!mounted) return;

    final oldCount = messages.length;

    setState(() {
      messages = data;
      loading = false;
    });

    if (data.length > oldCount) {
      scrollToBottom();
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) {
      return;
    }

    final success = await ApiService.sendChatMessage(
      challanId: widget.challanId,
      messageText: messageController.text.trim(),
      senderName: currentUserName,
    );

    if (success) {
      messageController.clear();

      await loadMessages();

      scrollToBottom();
    }
  }

  String formatTime(String value) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(value));
    } catch (e) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          children: [
            Container(
              color: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Challan Chat - ${widget.challanNo}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      color: const Color(0xFFECE5DD), // WhatsApp chat background
                      child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];

                        final senderName = msg["SenderName"]?.toString() ?? "";

                        final message = msg["MessageText"]?.toString() ?? "";

                        final messageTime =
                            msg["MessageTime"]?.toString() ?? "";

                        final isMine =
                            senderName.toLowerCase() ==
                            currentUserName.toLowerCase();

                        return Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(
                              left: isMine ? 60 : 10,
                              right: isMine ? 10 : 60,
                              top: 4,
                              bottom: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? const Color(0xFFDCF8C6) // WhatsApp green
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMine ? 18 : 4),
                                bottomRight: Radius.circular(isMine ? 4 : 18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Show sender name only for others
                                if (!isMine)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      senderName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF075E54), // WhatsApp teal
                                      ),
                                    ),
                                  ),

                                Text(
                                  message,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                // Time aligned to bottom-right, mimicking WhatsApp
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Spacer(),
                                    Text(
                                      formatTime(messageTime),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black.withValues(alpha: 0.45),
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
            ),

            const Divider(),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
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
      ),
    );
  }
}
