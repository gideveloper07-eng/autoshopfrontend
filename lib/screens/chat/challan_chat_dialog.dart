import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'chat_document_picker_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';

class ChallanChatDialog extends StatefulWidget {
  final String challanId;
  final String challanNo;
  // Optional: customer name shown in header (Step 10)
  final String? customerName;

  const ChallanChatDialog({
    super.key,
    required this.challanId,
    required this.challanNo,
    this.customerName,
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
  bool _sending = false; // Step 6 — loading animation while sending
  String currentUserName = "";
  String currentUserId = "";

  bool _userScrolledUp = false;
  int _newWhileScrolledUp = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    loadCurrentUser().then((_) {
      loadMessages(isInitial: true);
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadMessages();
    });
  }

  @override
  void dispose() {
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
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;
    if (atBottom) {
      if (_userScrolledUp) {
        setState(() {
          _userScrolledUp = false;
          _newWhileScrolledUp = 0;
        });
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
    currentUserId = await ApiService.getUserId() ?? "";
  }

  Future<void> loadMessages({bool isInitial = false}) async {
    final data = await ApiService.getChatMessages(widget.challanId);
    if (!mounted) return;

    final oldCount = messages.length;
    final newCount = data.length;
    final hasNew = newCount > oldCount;

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
      ApiService.markChatRead(widget.challanId);
      scrollToBottom(animated: false);
    } else if (hasNew) {
      if (!_userScrolledUp) {
        scrollToBottom();
        if (newFromOthers > 0) ApiService.markChatRead(widget.challanId);
      }
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    // Step 6 — disable send button, show "Sending…" state
    setState(() => _sending = true);
    messageController.clear();

    final success = await ApiService.sendChatMessage(
      challanId: widget.challanId,
      messageText: text,
      senderName: currentUserName,
      challanNo: widget.challanNo,
      messageType: selectedDocumentId == null ? "TEXT" : "DOCUMENT",
      documentId: selectedDocumentId,
    );

    if (!mounted) return;

    if (success) {
      selectedDocumentId = null;
      selectedDocumentType = null;
      _userScrolledUp = false;
      _newWhileScrolledUp = 0;
      await loadMessages();
      scrollToBottom();
    } else {
      messageController.text = text; // restore on failure
    }

    setState(() => _sending = false);
  }

  String formatTime(String value) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  /// Step 7 — return "10 Jun 2026" label or null if same day as previous msg
  String? _dateSeparator(int index) {
    if (index == 0) {
      final t = messages[0]['MessageTime']?.toString() ?? '';
      try {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(t));
      } catch (_) {
        return null;
      }
    }
    try {
      final prev = DateTime.parse(messages[index - 1]['MessageTime'].toString());
      final curr = DateTime.parse(messages[index]['MessageTime'].toString());
      if (prev.year != curr.year ||
          prev.month != curr.month ||
          prev.day != curr.day) {
        return DateFormat('dd MMM yyyy').format(curr);
      }
    } catch (_) {}
    return null;
  }

  Widget _buildDocumentMessage(
      String documentNo, String documentType, String? documentId) {
    return InkWell(
      onTap: () async {
        if (documentId == null) return;
        final doc = await ApiService.getDocument(documentId);
        if (doc == null) return;
        final filePath = doc["FilePath"]?.toString() ?? "";
        if (filePath.isEmpty) return;
        final url = "http://myautoshop365.com/$filePath";
        await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$documentType #$documentNo",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Text(
                    "PDF Document · Tap to open",
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 2 — ✓ / ✓✓ tick widget
  Widget _buildTicks(bool isMine, bool isRead) {
    if (!isMine) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        isRead ? Icons.done_all : Icons.done,
        size: 14,
        color: isRead ? const Color(0xFF34B7F1) : Colors.black45,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          children: [
            // ── Step 10: Better Chat Header ──────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF075E54),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Avatar with challan icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Challan #${widget.challanNo}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.customerName != null &&
                            widget.customerName!.isNotEmpty)
                          Text(
                            widget.customerName!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                      ],
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
                            // Step 7: each message may be preceded by a date separator
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final separator = _dateSeparator(index);
                              final msg = messages[index];
                              final senderName =
                                  msg["SenderName"]?.toString() ?? "";
                              final message =
                                  msg["MessageText"]?.toString() ?? "";
                              final messageType =
                                  msg["MessageType"]?.toString() ?? "TEXT";
                              final documentId =
                                  msg["DocumentId"]?.toString();
                              final documentNo =
                                  msg["DocumentNo"]?.toString() ?? "";
                              final documentType =
                                  msg["DocumentType"]?.toString() ?? "";
                              final messageTime =
                                  msg["MessageTime"]?.toString() ?? "";
                              // Step 2: read status
                              final isRead =
                                  (msg["IsRead"] == true ||
                                      msg["IsRead"] == 1);
                              final isMine = senderName.toLowerCase() ==
                                  currentUserName.toLowerCase();

                              return Column(
                                children: [
                                  // Step 7 — Date separator
                                  if (separator != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      child: Center(
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD1E8D5),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            separator,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF4A4A4A),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Message bubble
                                  Align(
                                    alignment: isMine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        left: isMine ? 60 : 10,
                                        right: isMine ? 10 : 60,
                                        top: 2,
                                        bottom: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
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
                                            color: Colors.black
                                                .withValues(alpha: 0.08),
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
                                          // Sender name for others
                                          if (!isMine)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 3),
                                              child: Text(
                                                senderName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Color(0xFF075E54),
                                                ),
                                              ),
                                            ),

                                          // Content
                                          messageType == "DOCUMENT"
                                              ? _buildDocumentMessage(
                                                  documentNo,
                                                  documentType,
                                                  documentId,
                                                )
                                              : Text(
                                                  message,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),

                                          const SizedBox(height: 3),

                                          // Time + Step 2 ticks
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
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
                                              _buildTicks(isMine, isRead),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // WhatsApp-style "N new messages ↓" banner
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
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF075E54),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.2),
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
                                          size: 18),
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

            // ── Input bar (Step 6: sending state) ────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Attach document button
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _sending
                        ? null
                        : () async {
                            final selectedDoc =
                                await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (_) =>
                                  const ChatDocumentPickerDialog(),
                            );
                            if (selectedDoc != null) {
                              selectedDocumentId =
                                  selectedDoc["DocumentId"]?.toString();
                              selectedDocumentType =
                                  selectedDoc["DocumentType"]?.toString();
                              messageController.text =
                                  selectedDoc["DocumentNo"]?.toString() ?? "";
                            }
                          },
                  ),

                  // Text field
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          if (!_sending) sendMessage();
                        }
                      },
                      child: TextField(
                        controller: messageController,
                        focusNode: _inputFocusNode,
                        enabled: !_sending,
                        decoration: InputDecoration(
                          hintText:
                              _sending ? "Sending…" : "Type message...",
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (!_sending) sendMessage();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Step 6 — show spinner while sending, send icon otherwise
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon:
                                const Icon(Icons.send, color: Color(0xFF075E54)),
                            onPressed: sendMessage,
                          ),
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
