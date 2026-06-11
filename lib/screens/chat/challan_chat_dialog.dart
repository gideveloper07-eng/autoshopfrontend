import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'chat_document_picker_dialog.dart';

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
  final FocusNode _inputFocusNode = FocusNode();
  String? selectedDocumentId;
  String? selectedDocumentType;
  Timer? _refreshTimer;
  List<dynamic> messages = [];
  bool loading = true;
  String currentUserName = "";

  // Track if user has manually scrolled up
  bool _userScrolledUp = false;

  // Count of new messages that arrived while user is scrolled up
  // — shows a "↓ N new messages" banner like WhatsApp
  int _newWhileScrolledUp = 0;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    loadCurrentUser().then((_) {
      loadMessages(isInitial: true);
    });

    // Poll every 5 s — new messages from others get marked read immediately
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadMessages();
    });
  }

  @override
  void dispose() {
    // Final mark-read so anything that slipped through is cleaned up
    ApiService.markChatRead(widget.challanId);
    _refreshTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    messageController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;
    if (atBottom) {
      if (_userScrolledUp) {
        // User scrolled back to bottom — clear the "new messages" counter
        setState(() {
          _userScrolledUp = false;
          _newWhileScrolledUp = 0;
        });
        // Mark everything read now that user sees the bottom
        ApiService.markChatRead(widget.challanId);
      }
    } else {
      _userScrolledUp = true;
    }
  }

  void scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> loadCurrentUser() async {
    currentUserName = await ApiService.getUserName() ?? "";
  }

  Future<void> loadMessages({bool isInitial = false}) async {
    final data = await ApiService.getChatMessages(widget.challanId);
    if (!mounted) return;

    final oldCount = messages.length;
    final newCount = data.length;
    final hasNew = newCount > oldCount;

    // Count how many of the new messages are from others
    int newFromOthers = 0;
    if (hasNew && !isInitial) {
      for (int i = oldCount; i < newCount; i++) {
        final sender = data[i]['SenderName']?.toString() ?? '';
        if (sender.toLowerCase() != currentUserName.toLowerCase()) {
          newFromOthers++;
        }
      }
    }

    setState(() {
      messages = data;
      loading = false;
      if (!isInitial && _userScrolledUp && newFromOthers > 0) {
        _newWhileScrolledUp += newFromOthers;
      }
    });

    if (isInitial) {
      // On open: mark everything read then jump to bottom
      ApiService.markChatRead(widget.challanId);
      scrollToBottom(animated: false);
    } else if (hasNew) {
      if (!_userScrolledUp) {
        // User is at the bottom — auto-scroll and mark read immediately
        scrollToBottom();
        if (newFromOthers > 0) {
          ApiService.markChatRead(widget.challanId);
        }
      }
      // If scrolled up, the "N new messages" banner will appear instead
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();

    final success = await ApiService.sendChatMessage(
      challanId: widget.challanId,
      messageText: messageController.text.trim(),
      senderName: currentUserName,
      challanNo: widget.challanNo,

      messageType: selectedDocumentId == null ? "TEXT" : "DOCUMENT",

      documentId: selectedDocumentId,
    );

    if (success) {
      _userScrolledUp = false;
      _newWhileScrolledUp = 0;
      await loadMessages();
      scrollToBottom();
    } else {
      messageController.text = text;
    }
  }

  String formatTime(String value) {
    try {
      return DateFormat('dd/MM/yyyy  hh:mm a').format(DateTime.parse(value));
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
            // ── Header ──────────────────────────────────────────────
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Message list ─────────────────────────────────────────
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        Container(
                          color: const Color(0xFFECE5DD),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final senderName =
                                  msg["SenderName"]?.toString() ?? "";
                              final message =
                                  msg["MessageText"]?.toString() ?? "";
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
                                        ? const Color(0xFFDCF8C6)
                                        : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: Radius.circular(
                                        isMine ? 18 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMine ? 4 : 18,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isMine)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 3,
                                          ),
                                          child: Text(
                                            senderName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Color(0xFF075E54),
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
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          const Spacer(),
                                          Text(
                                            formatTime(messageTime),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.black.withValues(
                                                alpha: 0.45,
                                              ),
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

                        // ── "N new messages ↓" banner (WhatsApp style) ──
                        if (_newWhileScrolledUp > 0)
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _userScrolledUp = false;
                                    _newWhileScrolledUp = 0;
                                  });
                                  scrollToBottom();
                                  ApiService.markChatRead(widget.challanId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF075E54),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_newWhileScrolledUp new message${_newWhileScrolledUp > 1 ? 's' : ''}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            const Divider(height: 1),

            // ── Input bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () async {
                      final selectedDoc =
                          await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (_) => const ChatDocumentPickerDialog(),
                          );

                      if (selectedDoc != null) {
                        selectedDocumentId = selectedDoc["DocumentId"]
                            ?.toString();

                        selectedDocumentType = selectedDoc["DocumentType"]
                            ?.toString();

                        messageController.text =
                            selectedDoc["DocumentNo"]?.toString() ?? "";
                      }
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
      ),
    );
  }
}
