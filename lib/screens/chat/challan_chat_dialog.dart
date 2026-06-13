import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'chat_document_picker_dialog.dart';
import 'group_chat_screen.dart';
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
  List<int> _matchIndices = [];
  int _currentMatchIndex = 0;
  final Map<int, GlobalKey> _itemKeys = {};

  // ── Members ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _members = [];

  static const Color _headerColor = Color(0xFF075E54);
  static const Color _subHeaderColor = Color(0xFF128C7E);

  // ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    loadCurrentUser().then((_) {
      loadMessages(isInitial: true);
      _loadMembers();
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

  // ── Search ───────────────────────────────────────────────────────

  void _onSearchChanged() => _rebuildMatchIndices();

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
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _searchFocusNode.requestFocus());
    }
  }

  void _goToPrevMatch() {
    if (_matchIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchIndices.length) % _matchIndices.length;
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

  bool _isCurrentMatch(int msgIndex) =>
      _matchIndices.isNotEmpty && _matchIndices[_currentMatchIndex] == msgIndex;

  // ── New Group flow (Step 1: pick members → Step 2: name) ────────

  void _showNewGroupFlow() async {
    // Step 1 — pick members
    final allUsers = await ApiService.getCompanyUsers();
    if (!mounted) return;

    final pickedIds = await showDialog<List<String>>(
      context: context,
      builder: (_) => _PickMembersDialog(allUsers: allUsers),
    );
    if (pickedIds == null || pickedIds.isEmpty) return;

    // Step 2 — name the group
    if (!mounted) return;
    final groupName = await showDialog<String>(
      context: context,
      builder: (_) => const _NameGroupDialog(),
    );
    if (groupName == null || groupName.trim().isEmpty) return;

    // Create
    final result = await ApiService.createGroup(
      groupName: groupName.trim(),
      memberIds: pickedIds,
    );

    if (!mounted) return;
    if (result['success'] == true) {
      final groupId = result['groupId']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF075E54),
          content: Text('Group "$groupName" created!'),
        ),
      );
      if (groupId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              groupId: groupId,
              groupName: groupName.trim(),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to create group. Try again.'),
        ),
      );
    }
  }

  // ── Challan Members ──────────────────────────────────────────────

  Future<void> _loadMembers() async {
    final data = await ApiService.getChatMembers(widget.challanId);
    if (mounted) setState(() => _members = data);
  }

  void _showViewMembers() {
    showDialog(
      context: context,
      builder: (_) => _MembersDialog(
        challanId: widget.challanId,
        challanNo: widget.challanNo,
        members: _members,
        currentUserId: currentUserId,
        onRemoved: (userId, userName) async {
          final ok = await ApiService.removeChatMember(
            challanId: widget.challanId,
            userId: userId,
            userName: userName,
          );
          if (ok && mounted) {
            _loadMembers();
            loadMessages();
          }
          return ok;
        },
      ),
    );
  }

  void _showAddMember() async {
    final users = await ApiService.getCompanyUsers();
    if (!mounted) return;
    final existingIds = _members.map((m) => m['UserId']?.toString()).toSet();
    final available = users
        .where((u) => !existingIds.contains(u['UserId']?.toString()))
        .toList();

    showDialog(
      context: context,
      builder: (_) => _AddMemberDialog(
        availableUsers: available,
        onAdd: (userId, userName) async {
          final ok = await ApiService.addChatMember(
            challanId: widget.challanId,
            userId: userId,
            userName: userName,
          );
          if (ok && mounted) {
            _loadMembers();
            loadMessages();
          }
          return ok;
        },
      ),
    );
  }

  void _showRemoveMember() {
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No members to remove.")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _MembersDialog(
        challanId: widget.challanId,
        challanNo: widget.challanNo,
        members: _members,
        currentUserId: currentUserId,
        removeMode: true,
        onRemoved: (userId, userName) async {
          final ok = await ApiService.removeChatMember(
            challanId: widget.challanId,
            userId: userId,
            userName: userName,
          );
          if (ok && mounted) {
            _loadMembers();
            loadMessages();
          }
          return ok;
        },
      ),
    );
  }

  void _showGroupInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: _headerColor, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text("Group Info"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.tag, "Challan No", widget.challanNo),
            if (widget.customerName != null &&
                widget.customerName!.isNotEmpty)
              _infoRow(Icons.person, "Customer", widget.customerName!),
            _infoRow(Icons.group, "Members", "${_members.length}"),
            _infoRow(Icons.message, "Messages", "${messages.length}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _headerColor),
          const SizedBox(width: 10),
          Text("$label: ",
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
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
      final prev =
          DateTime.parse(messages[index - 1]['MessageTime'].toString());
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
                  Text("$documentType #$documentNo",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const Text("PDF Document · Tap to open",
                      style: TextStyle(fontSize: 11, color: Colors.black54)),
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

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text,
          style: const TextStyle(fontSize: 14, color: Colors.black87));
    }
    final lowerText = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx;
    while ((idx = lowerText.indexOf(query, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(
            text: text.substring(start, idx),
            style: const TextStyle(fontSize: 14, color: Colors.black87)));
      }
      spans.add(TextSpan(
          text: text.substring(idx, idx + query.length),
          style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              backgroundColor: Color(0xFFFFE082),
              fontWeight: FontWeight.bold)));
      start = idx + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(
          text: text.substring(start),
          style: const TextStyle(fontSize: 14, color: Colors.black87)));
    }
    return RichText(text: TextSpan(children: spans));
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final searchQuery = _searchController.text.trim().toLowerCase();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 700,
        height: 620,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: _headerColor,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (!_isSearching) ...[
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
                                fontWeight: FontWeight.bold),
                          ),
                          if (widget.customerName != null &&
                              widget.customerName!.isNotEmpty)
                            Text(
                              widget.customerName!,
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12),
                            )
                          else if (_members.isNotEmpty)
                            Text(
                              "${_members.length} member${_members.length == 1 ? '' : 's'}",
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: "Search messages…",
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],

                  // Search icon
                  IconButton(
                    icon: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: Colors.white),
                    tooltip: _isSearching ? "Close search" : "Search",
                    onPressed: _toggleSearch,
                  ),

                  // ── Three-dot menu ──────────────────────────────
                  if (!_isSearching)
                    PopupMenuButton<String>(
                      icon:
                          const Icon(Icons.more_vert, color: Colors.white),
                      tooltip: "Menu",
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onSelected: (value) {
                        switch (value) {
                          case 'newGroup':
                            _showNewGroupFlow();
                          case 'viewMembers':
                            _showViewMembers();
                          case 'addMember':
                            _showAddMember();
                          case 'removeMember':
                            _showRemoveMember();
                          case 'groupInfo':
                            _showGroupInfo();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'newGroup',
                          child: _MenuRow(
                              icon: Icons.group_add_outlined,
                              label: 'New Group'),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'viewMembers',
                          child: _MenuRow(
                              icon: Icons.people_outline,
                              label: 'View Members'),
                        ),
                        const PopupMenuItem(
                          value: 'addMember',
                          child: _MenuRow(
                              icon: Icons.person_add_alt_1_outlined,
                              label: 'Add Member'),
                        ),
                        const PopupMenuItem(
                          value: 'removeMember',
                          child: _MenuRow(
                              icon: Icons.person_remove_outlined,
                              label: 'Remove Member',
                              danger: true),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'groupInfo',
                          child: _MenuRow(
                              icon: Icons.info_outline,
                              label: 'Group Info'),
                        ),
                      ],
                    ),

                  // Close dialog
                  if (!_isSearching)
                    IconButton(
                      icon:
                          const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),

            // ── Search result bar ──────────────────────────────────
            if (_isSearching)
              Container(
                color: _subHeaderColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
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
                            fontSize: 13),
                      ),
                    ),
                    if (_matchIndices.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up,
                            color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _goToPrevMatch,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _goToNextMatch,
                      ),
                    ],
                  ],
                ),
              ),

            // ── Message list ───────────────────────────────────────
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        Container(
                          color: const Color(0xFFECE5DD),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              _itemKeys[index] ??= GlobalKey();
                              final separator = _dateSeparator(index);
                              final msg = messages[index];
                              final senderName =
                                  msg["SenderName"]?.toString() ?? "";
                              final message =
                                  msg["MessageText"]?.toString() ?? "";
                              final messageType =
                                  msg["MessageType"]?.toString() ??
                                      "TEXT";
                              final documentId =
                                  msg["DocumentId"]?.toString();
                              final documentNo =
                                  msg["DocumentNo"]?.toString() ?? "";
                              final documentType =
                                  msg["DocumentType"]?.toString() ?? "";
                              final messageTime =
                                  msg["MessageTime"]?.toString() ?? "";
                              final isRead = (msg["IsRead"] == true ||
                                  msg["IsRead"] == 1);

                              // System messages (member add/remove)
                              if (messageType == "SYSTEM") {
                                return Padding(
                                  key: _itemKeys[index],
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
                                  child: Center(
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 5),
                                      decoration: BoxDecoration(
                                        color:
                                            const Color(0xFFD1E8D5),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        message,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF4A4A4A),
                                            fontStyle: FontStyle.italic),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final isMine = senderName.toLowerCase() ==
                                  currentUserName.toLowerCase();
                              final isMatch =
                                  _matchIndices.contains(index);
                              final isActiveMatch =
                                  _isCurrentMatch(index);

                              return Column(
                                key: _itemKeys[index],
                                children: [
                                  // Date separator
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
                                            color:
                                                const Color(0xFFD1E8D5),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10),
                                          ),
                                          child: Text(
                                            separator,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF4A4A4A),
                                                fontWeight:
                                                    FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Bubble
                                  Align(
                                    alignment: isMine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      margin: EdgeInsets.only(
                                          left: isMine ? 60 : 10,
                                          right: isMine ? 10 : 60,
                                          top: 2,
                                          bottom: 2),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isActiveMatch
                                            ? const Color(0xFFFFF176)
                                            : isMatch
                                                ? const Color(0xFFFFF9C4)
                                                : isMine
                                                    ? const Color(
                                                        0xFFDCF8C6)
                                                    : Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft:
                                              const Radius.circular(18),
                                          topRight:
                                              const Radius.circular(18),
                                          bottomLeft: Radius.circular(
                                              isMine ? 18 : 4),
                                          bottomRight: Radius.circular(
                                              isMine ? 4 : 18),
                                        ),
                                        border: isActiveMatch
                                            ? Border.all(
                                                color: const Color(
                                                    0xFFFFB300),
                                                width: 1.5)
                                            : null,
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
                                          if (!isMine)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      bottom: 3),
                                              child: Text(
                                                senderName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Color(
                                                        0xFF075E54)),
                                              ),
                                            ),
                                          messageType == "DOCUMENT"
                                              ? _buildDocumentMessage(
                                                  documentNo,
                                                  documentType,
                                                  documentId)
                                              : (_isSearching && isMatch)
                                                  ? _buildHighlightedText(
                                                      message,
                                                      searchQuery)
                                                  : Text(message,
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors
                                                              .black87)),
                                          const SizedBox(height: 3),
                                          Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              const Spacer(),
                                              Text(
                                                formatTime(messageTime),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black
                                                      .withValues(
                                                          alpha: 0.45),
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

                        // New messages banner
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
                                  ApiService.markChatRead(
                                      widget.challanId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _headerColor,
                                    borderRadius:
                                        BorderRadius.circular(20),
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
                                            fontWeight: FontWeight.w600),
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

            // ── Input bar ─────────────────────────────────────────
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
                                selectedDocumentId = selectedDoc[
                                        "DocumentId"]
                                    ?.toString();
                                selectedDocumentType = selectedDoc[
                                        "DocumentType"]
                                    ?.toString();
                                messageController.text =
                                    selectedDoc["DocumentNo"]
                                            ?.toString() ??
                                        "";
                              }
                            },
                    ),
                    Expanded(
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey ==
                                  LogicalKeyboardKey.enter) {
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
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.send,
                                  color: _headerColor),
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

// ── Reusable popup menu row ──────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;

  const _MenuRow(
      {required this.icon, required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : Colors.black87;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}

// ── View / Remove Members Dialog ─────────────────────────────────────────────

class _MembersDialog extends StatefulWidget {
  final String challanId;
  final String challanNo;
  final List<Map<String, dynamic>> members;
  final String currentUserId;
  final bool removeMode;
  final Future<bool> Function(String userId, String userName) onRemoved;

  const _MembersDialog({
    required this.challanId,
    required this.challanNo,
    required this.members,
    required this.currentUserId,
    required this.onRemoved,
    this.removeMode = false,
  });

  @override
  State<_MembersDialog> createState() => _MembersDialogState();
}

class _MembersDialogState extends State<_MembersDialog> {
  late List<Map<String, dynamic>> _list;
  final Set<String> _removing = {};

  @override
  void initState() {
    super.initState();
    _list = List.from(widget.members);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF075E54),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              widget.removeMode
                  ? Icons.person_remove_outlined
                  : Icons.people_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              widget.removeMode ? "Remove Member" : "Group Members",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${_list.length}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 380,
        height: 340,
        child: _list.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_off, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text("No members yet",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final member = _list[i];
                  final userId = member['UserId']?.toString() ?? '';
                  final userName = member['UserName']?.toString() ?? userId;
                  final addedOn = member['AddedOn']?.toString() ?? '';
                  final isRemoving = _removing.contains(userId);
                  final isMe = userId == widget.currentUserId;

                  String timeLabel = '';
                  try {
                    timeLabel = DateFormat('dd MMM yyyy')
                        .format(DateTime.parse(addedOn));
                  } catch (_) {}

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF075E54),
                      child: Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ),
                        if (isMe)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF075E54),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("You",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ),
                      ],
                    ),
                    subtitle: timeLabel.isNotEmpty
                        ? Text("Added $timeLabel",
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey))
                        : null,
                    trailing: widget.removeMode && !isMe
                        ? isRemoving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red, size: 22),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Remove Member"),
                                      content: Text(
                                          "Remove $userName from this chat?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Remove",
                                              style: TextStyle(
                                                  color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return;
                                  setState(() => _removing.add(userId));
                                  final ok = await widget.onRemoved(
                                      userId, userName);
                                  if (ok && mounted) {
                                    setState(() {
                                      _list.removeAt(i);
                                      _removing.remove(userId);
                                    });
                                  } else {
                                    setState(() => _removing.remove(userId));
                                  }
                                },
                              )
                        : null,
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}

// ── Add Member Dialog ─────────────────────────────────────────────────────────

class _AddMemberDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableUsers;
  final Future<bool> Function(String userId, String userName) onAdd;

  const _AddMemberDialog(
      {required this.availableUsers, required this.onAdd});

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final TextEditingController _filter = TextEditingController();
  final Set<String> _adding = {};
  final Set<String> _added = {};

  List<Map<String, dynamic>> get _filtered {
    final q = _filter.text.trim().toLowerCase();
    if (q.isEmpty) return widget.availableUsers;
    return widget.availableUsers.where((u) {
      final name = (u['UserName']?.toString() ?? '').toLowerCase();
      final id = (u['UserId']?.toString() ?? '').toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF075E54),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: const Row(
          children: [
            Icon(Icons.person_add_alt_1_outlined,
                color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text("Add Member",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      content: SizedBox(
        width: 380,
        height: 380,
        child: Column(
          children: [
            // Search box
            TextField(
              controller: _filter,
              decoration: InputDecoration(
                hintText: "Search users…",
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text("No users found",
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final user = filtered[i];
                        final userId =
                            user['UserId']?.toString() ?? '';
                        final userName =
                            user['UserName']?.toString() ?? userId;
                        // HeadName no longer returned — subtitle omitted
                        final isAdding = _adding.contains(userId);
                        final isAdded = _added.contains(userId);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          leading: CircleAvatar(
                            backgroundColor: isAdded
                                ? Colors.green
                                : const Color(0xFF128C7E),
                            child: isAdded
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                          title: Text(userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          subtitle: null,
                          trailing: isAdded
                              ? const Text("Added",
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600))
                              : isAdding
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF075E54),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        minimumSize: const Size(60, 32),
                                        textStyle: const TextStyle(
                                            fontSize: 12),
                                      ),
                                      onPressed: () async {
                                        setState(
                                            () => _adding.add(userId));
                                        final ok = await widget.onAdd(
                                            userId, userName);
                                        if (mounted) {
                                          setState(() {
                                            _adding.remove(userId);
                                            if (ok) _added.add(userId);
                                          });
                                        }
                                      },
                                      child: const Text("Add"),
                                    ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Done"),
        ),
      ],
    );
  }
}

// ── Step 1: Pick Members Dialog ──────────────────────────────────────────────
// Multi-select user list. Returns List<String> of selected userIds.

class _PickMembersDialog extends StatefulWidget {
  final List<Map<String, dynamic>> allUsers;
  const _PickMembersDialog({required this.allUsers});

  @override
  State<_PickMembersDialog> createState() => _PickMembersDialogState();
}

class _PickMembersDialogState extends State<_PickMembersDialog> {
  final TextEditingController _filter = TextEditingController();
  final Set<String> _selected = {};

  List<Map<String, dynamic>> get _filtered {
    final q = _filter.text.trim().toLowerCase();
    if (q.isEmpty) return widget.allUsers;
    return widget.allUsers.where((u) {
      final name = (u['UserName']?.toString() ?? '').toLowerCase();
      final id = (u['UserId']?.toString() ?? '').toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF075E54),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.group_add_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Add Group Members",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            if (_selected.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_selected.length} selected",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _filter,
              decoration: InputDecoration(
                hintText: "Search users…",
                prefixIcon: const Icon(Icons.search, size: 18),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text("No users found",
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final user = filtered[i];
                        final userId = user['UserId']?.toString() ?? '';
                        final userName =
                            user['UserName']?.toString() ?? userId;
                        final isSelected = _selected.contains(userId);

                        return CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          activeColor: const Color(0xFF075E54),
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selected.add(userId);
                              } else {
                                _selected.remove(userId);
                              }
                            });
                          },
                          secondary: CircleAvatar(
                            backgroundColor: isSelected
                                ? const Color(0xFF075E54)
                                : const Color(0xFF128C7E),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                          ),
                          title: Text(userName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF075E54),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.toList()),
          child: Text("Next  (${_selected.length})"),
        ),
      ],
    );
  }
}

// ── Step 2: Name Group Dialog ─────────────────────────────────────────────────

class _NameGroupDialog extends StatefulWidget {
  const _NameGroupDialog();

  @override
  State<_NameGroupDialog> createState() => _NameGroupDialogState();
}

class _NameGroupDialogState extends State<_NameGroupDialog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF075E54),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: const Row(
          children: [
            Icon(Icons.group, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              "Name Your Group",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLength: 50,
        decoration: const InputDecoration(
          hintText: "Group name…",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.edit),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.pop(context, v.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF075E54),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final name = _ctrl.text.trim();
            if (name.isNotEmpty) Navigator.pop(context, name);
          },
          child: const Text("Create Group"),
        ),
      ],
    );
  }
}
