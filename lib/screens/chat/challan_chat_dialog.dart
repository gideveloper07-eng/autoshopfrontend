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
  // ── Messaging ────────────────────────────────────────────────────
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  String? selectedDocumentId;
  String? selectedDocumentType;
  Timer? _refreshTimer;
  List<dynamic> messages = [];
  bool loading = true;
  bool _sending = false;
  String currentUserName = "";
  String currentUserId = "";
  bool _userScrolledUp = false;
  int _newWhileScrolledUp = 0;

  // ── Search ───────────────────────────────────────────────────────
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  /// Indices (into [messages]) that match the current query
  List<int> _matchIndices = [];

  /// Which match the user is currently viewing (0-based)
  int _currentMatchIndex = 0;

  // One GlobalKey per message so we can scroll to it
  final Map<int, GlobalKey> _itemKeys = {};

  // ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    loadCurrentUser().then((_) {
      loadMessages(isInitial: true);
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isSearching) loadMessages();
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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Scroll ───────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom =
        _scrollController.position.pixels >=
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

  void _scrollToMessageIndex(int msgIndex) {
    final key = _itemKeys[msgIndex];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.3,
      );
    }
  }

  // ── Search logic ─────────────────────────────────────────────────

  void _onSearchChanged() {
    _rebuildMatchIndices();
  }

  void _rebuildMatchIndices() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _matchIndices = [];
        _currentMatchIndex = 0;
      });
      return;
    }
    final matches = <int>[];
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final text = (msg['MessageText']?.toString() ?? '').toLowerCase();
      final docNo = (msg['DocumentNo']?.toString() ?? '').toLowerCase();
      final docType = (msg['DocumentType']?.toString() ?? '').toLowerCase();
      if (text.contains(q) || docNo.contains(q) || docType.contains(q)) {
        matches.add(i);
      }
    }
    setState(() {
      _matchIndices = matches;
      _currentMatchIndex = matches.isEmpty ? 0 : matches.length - 1;
    });
    if (matches.isNotEmpty) {
      // Jump to last (newest) match first, like WhatsApp
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMessageIndex(matches.last);
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _matchIndices = [];
        _currentMatchIndex = 0;
      }
    });
    if (_isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  void _goToPrevMatch() {
    if (_matchIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchIndices.length) %
          _matchIndices.length;
    });
    _scrollToMessageIndex(_matchIndices[_currentMatchIndex]);
  }

  void _goToNextMatch() {
    if (_matchIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchIndices.length;
    });
    _scrollToMessageIndex(_matchIndices[_currentMatchIndex]);
  }

  bool _isCurrentMatch(int msgIndex) {
    if (_matchIndices.isEmpty) return false;
    return _matchIndices[_currentMatchIndex] == msgIndex;
  }

  // ── Messages ─────────────────────────────────────────────────────

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
    // Rebuild search matches after new messages arrive
    if (_isSearching && _searchController.text.trim().isNotEmpty) {
      _rebuildMatchIndices();
    }
    if (isInitial) {
      ApiService.markChatRead(widget.challanId);
      scrollToBottom(animated: false);
    } else if (hasNew && !_isSearching) {
      if (!_userScrolledUp) {
        scrollToBottom();
        if (newFromOthers > 0) ApiService.markChatRead(widget.challanId);
      }
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
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
      messageController.text = text;
    }
    setState(() => _sending = false);
  }

  // ── Formatters ───────────────────────────────────────────────────

  String formatTime(String value) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

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
      final prev = DateTime.parse(
        messages[index - 1]['MessageTime'].toString(),
      );
      final curr = DateTime.parse(messages[index]['MessageTime'].toString());
      if (prev.year != curr.year ||
          prev.month != curr.month ||
          prev.day != curr.day) {
        return DateFormat('dd MMM yyyy').format(curr);
      }
    } catch (_) {}
    return null;
  }

  // ── Widgets ──────────────────────────────────────────────────────

  Widget _buildDocumentMessage(
    String documentNo,
    String documentType,
    String? documentId,
  ) {
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
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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

  /// Highlight matched text inside a message bubble with a yellow background
  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      );
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx;
    while ((idx = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (idx > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, idx),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            backgroundColor: Color(0xFFFFE082), // yellow highlight
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = idx + query.length;
    }
    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      );
    }
    return RichText(text: TextSpan(children: spans));
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final searchQuery = _searchController.text.trim().toLowerCase();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF075E54),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (!_isSearching) ...[
                    // Normal header: avatar + title/subtitle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 20,
                      ),
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
                  ] else ...[
                    // Search mode: text field fills header
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: "Search messages…",
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],

                  // Search toggle icon
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close : Icons.search,
                      color: Colors.white,
                    ),
                    tooltip: _isSearching ? "Close search" : "Search",
                    onPressed: _toggleSearch,
                  ),

                  // WhatsApp Style 3 Dot Menu
                  if (!_isSearching)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        switch (value) {
                          case "chatInfo":
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Chat Info")),
                            );
                            break;

                          case "export":
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Export Chat")),
                            );
                            break;

                          case "clear":
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Clear Chat")),
                            );
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "chatInfo",
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18),
                              SizedBox(width: 8),
                              Text("Chat Info"),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: "export",
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 18),
                              SizedBox(width: 8),
                              Text("Export Chat"),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: "clear",
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18),
                              SizedBox(width: 8),
                              Text("Clear Chat"),
                            ],
                          ),
                        ),
                      ],
                    ),

                  // Close Dialog
                  if (!_isSearching)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),

            // ── Search result bar ────────────────────────────────────
            if (_isSearching)
              Container(
                color: const Color(0xFF128C7E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        searchQuery.isEmpty
                            ? "Type to search…"
                            : _matchIndices.isEmpty
                            ? "No results"
                            : "${_currentMatchIndex + 1} of ${_matchIndices.length} matches",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (_matchIndices.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: "Previous",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _goToPrevMatch,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: "Next",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _goToNextMatch,
                      ),
                    ],
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
                              // Assign a key so we can scroll to this item
                              _itemKeys[index] ??= GlobalKey();

                              final separator = _dateSeparator(index);
                              final msg = messages[index];
                              final senderName =
                                  msg["SenderName"]?.toString() ?? "";
                              final message =
                                  msg["MessageText"]?.toString() ?? "";
                              final messageType =
                                  msg["MessageType"]?.toString() ?? "TEXT";
                              final documentId = msg["DocumentId"]?.toString();
                              final documentNo =
                                  msg["DocumentNo"]?.toString() ?? "";
                              final documentType =
                                  msg["DocumentType"]?.toString() ?? "";
                              final messageTime =
                                  msg["MessageTime"]?.toString() ?? "";
                              final isRead =
                                  (msg["IsRead"] == true || msg["IsRead"] == 1);
                              final isMine =
                                  senderName.toLowerCase() ==
                                  currentUserName.toLowerCase();

                              // Is this message a search match?
                              final isMatch = _matchIndices.contains(index);
                              final isActiveMatch = _isCurrentMatch(index);

                              return Column(
                                key: _itemKeys[index],
                                children: [
                                  // Date separator
                                  if (separator != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD1E8D5),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      margin: EdgeInsets.only(
                                        left: isMine ? 60 : 10,
                                        right: isMine ? 10 : 60,
                                        top: 2,
                                        bottom: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        // Active match: light yellow bg; other match: subtle highlight
                                        color: isActiveMatch
                                            ? const Color(0xFFFFF176)
                                            : isMatch
                                            ? const Color(0xFFFFF9C4)
                                            : isMine
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
                                        border: isActiveMatch
                                            ? Border.all(
                                                color: const Color(0xFFFFB300),
                                                width: 1.5,
                                              )
                                            : null,
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
                                          messageType == "DOCUMENT"
                                              ? _buildDocumentMessage(
                                                  documentNo,
                                                  documentType,
                                                  documentId,
                                                )
                                              : _isSearching && isMatch
                                              ? _buildHighlightedText(
                                                  message,
                                                  searchQuery,
                                                )
                                              : Text(
                                                  message,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                          const SizedBox(height: 3),
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

                        // "N new messages ↓" banner
                        if (_newWhileScrolledUp > 0 && !_isSearching)
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

            // ── Input bar (hidden while searching) ───────────────────
            if (!_isSearching) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
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
                                selectedDocumentId = selectedDoc["DocumentId"]
                                    ?.toString();
                                selectedDocumentType =
                                    selectedDoc["DocumentType"]?.toString();
                                messageController.text =
                                    selectedDoc["DocumentNo"]?.toString() ?? "";
                              }
                            },
                    ),
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
                            hintText: _sending ? "Sending…" : "Type message...",
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (!_sending) sendMessage();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Color(0xFF075E54),
                              ),
                              onPressed: sendMessage,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
