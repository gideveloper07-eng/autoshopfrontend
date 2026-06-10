import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _inputFocusNode = FocusNode();

  Timer? _refreshTimer;
  List<dynamic> messages = [];
  bool loading = true;
  String currentUserName = "";

  // Track if user has manually scrolled up — if so, don't force-scroll
  bool _userScrolledUp = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    loadCurrentUser().then((_) {
      // Mark messages as read as soon as the chat is opened
      ApiService.markChatRead(widget.challanId);
      loadMessages(isInitial: true);
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    messageController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;
    if (atBottom) {
      _userScrolledUp = false;
    } else {
      _userScrolledUp = true;
    }
  }

  /// Scroll to the very bottom of the list.
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
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
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

    setState(() {
      messages = data;
      loading = false;
    });

    // On first load always jump to bottom; on refresh only scroll if user
    // hasn't manually scrolled up AND there are new messages.
    if (isInitial) {
      scrollToBottom(animated: false);
    } else if (!_userScrolledUp && data.length > oldCount) {
      scrollToBottom();
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();

    final success = await ApiService.sendChatMessage(
      challanId: widget.challanId,
      messageText: text,
      senderName: currentUserName,
      challanNo: widget.challanNo,
    );

    if (success) {
      _userScrolledUp = false; // always scroll after own send
      await loadMessages();
      scrollToBottom();
    } else {
      // Restore text if send failed
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
                  : Container(
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
                          final isMine = senderName.toLowerCase() ==
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
                                  bottomLeft:
                                      Radius.circular(isMine ? 18 : 4),
                                  bottomRight:
                                      Radius.circular(isMine ? 4 : 18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMine)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 3),
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
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Spacer(),
                                      Text(
                                        formatTime(messageTime),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.black
                                              .withValues(alpha: 0.45),
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

            const Divider(height: 1),

            // ── Input bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    // KeyboardListener intercepts Enter so the field itself
                    // doesn't add a newline — Send fires instead.
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey ==
                                LogicalKeyboardKey.enter) {
                          sendMessage();
                        }
                      },
                      child: TextField(
                        controller: messageController,
                        focusNode: _inputFocusNode,
                        decoration: const InputDecoration(
                          hintText: "Type message...",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
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
