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
  final TextEditingController _msgCtrl = TextEditingController();
  final TextEditingController _taskTitleCtrl = TextEditingController();
  final TextEditingController _taskDescCtrl = TextEditingController();

  String _selectedPriority = 'Medium';

  DateTime? _startDate;
  DateTime? _dueDate;
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

  void _showAssignTaskDialog() {
    _taskTitleCtrl.clear();
    _taskDescCtrl.clear();

    _selectedPriority = "Medium";
    _startDate = null;
    _dueDate = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Assign Task"),

              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _taskTitleCtrl,
                        decoration: const InputDecoration(
                          labelText: "Task Title",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _taskDescCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: "Priority",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Low', child: Text('Low')),
                          DropdownMenuItem(
                            value: 'Medium',
                            child: Text('Medium'),
                          ),
                          DropdownMenuItem(value: 'High', child: Text('High')),
                        ],
                        onChanged: (v) {
                          setDialogState(() {
                            _selectedPriority = v!;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // ── Start Date ──────────────────────────────
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() => _startDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Start Date",
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _startDate != null
                                ? DateFormat('dd MMM yyyy').format(_startDate!)
                                : 'Select date',
                            style: TextStyle(
                              color: _startDate != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Due Date ────────────────────────────────
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ??
                                (_startDate ?? DateTime.now()),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() => _dueDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Due Date",
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _dueDate != null
                                ? DateFormat('dd MMM yyyy').format(_dueDate!)
                                : 'Select date',
                            style: TextStyle(
                              color: _dueDate != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (_taskTitleCtrl.text.trim().isEmpty) {
                      return;
                    }

                    final ok = await ApiService.createChatTask(
                      challanId: widget.challanId,
                      taskTitle: _taskTitleCtrl.text.trim(),
                      taskDescription: _taskDescCtrl.text.trim(),
                      priority: _selectedPriority,
                      startDate: _startDate?.toIso8601String(),
                      dueDate: _dueDate?.toIso8601String(),
                    );

                    if (!mounted) return;

                    if (ok) {
                      Navigator.pop(context);

                      await loadMessages();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Task assigned successfully"),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to assign task")),
                      );
                    }
                  },
                  child: const Text("Assign"),
                ),
              ],
            );
          },
        );
      },
    );
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
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _searchFocusNode.requestFocus(),
      );
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

  bool _isCurrentMatch(int msgIndex) =>
      _matchIndices.isNotEmpty && _matchIndices[_currentMatchIndex] == msgIndex;

  // ── New Group flow (Step 1: pick members → Step 2: name) ────────

  void _showNewGroupFlow() async {
    // Step 1 — pick members
    final allUsers = await ApiService.getCompanyUsers();
    if (!mounted) return;

    // Returns List<Map<String,dynamic>> with full user objects (including 'database')
    final pickedUsers = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => _PickMembersDialog(allUsers: allUsers),
    );
    if (pickedUsers == null || pickedUsers.isEmpty) return;

    // Extract plain IDs and determine the group's target DB
    final pickedIds = pickedUsers
        .map((u) => u['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final groupDb = pickedUsers
        .map((u) => u['database']?.toString() ?? '')
        .firstWhere((db) => db.isNotEmpty, orElse: () => '');

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
      databaseName: groupDb.isNotEmpty ? groupDb : null,
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
            settings: const RouteSettings(name: 'GroupChatScreen'),
            builder: (_) => GroupChatScreen(
              groupId: groupId,
              groupName: groupName.trim(),
              groupDatabase: groupDb.isNotEmpty ? groupDb : null,
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
        .where((u) => !existingIds.contains(u['id']?.toString()))
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No members to remove.")));
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
                color: _headerColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 18,
              ),
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
            if (widget.customerName != null && widget.customerName!.isNotEmpty)
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
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
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

  Widget _buildTaskMessage(Map<String, dynamic> task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.task_alt, color: Colors.orange),
              SizedBox(width: 6),
              Text(
                "TASK",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            task["MessageText"]?.toString() ?? "",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text("Assigned To: ${task["AssignedToName"] ?? task["AssignedTo"] ?? ""}"),

          if ((task["TaskDescription"]?.toString() ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                task["TaskDescription"].toString(),
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),

          Text("Priority: ${task["Priority"] ?? ""}"),

          Text("Status: ${task["TaskStatus"] ?? "Pending"}"),
        ],
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
      return Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      );
    }
    final lowerText = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx;
    while ((idx = lowerText.indexOf(query, start)) != -1) {
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
            backgroundColor: Color(0xFFFFE082),
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

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final searchQuery = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: _headerColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
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
              )
            : Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (widget.customerName != null &&
                                widget.customerName!.isNotEmpty)
                            ? widget.customerName![0].toUpperCase()
                            : widget.challanNo.isNotEmpty
                            ? widget.challanNo[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName != null &&
                                  widget.customerName!.isNotEmpty
                              ? widget.customerName!
                              : "Challan #${widget.challanNo}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Challan #${widget.challanNo}",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          // Search icon
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            tooltip: _isSearching ? "Close search" : "Search",
            onPressed: _toggleSearch,
          ),

          // Three-dot menu
          if (!_isSearching)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              tooltip: "Menu",
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (value) {
                if (value == 'newGroup') _showNewGroupFlow();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'newGroup',
                  child: _MenuRow(
                    icon: Icons.group_add_outlined,
                    label: 'New Group',
                  ),
                ),
              ],
            ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Container(
                  color: _subHeaderColor,
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
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _goToNextMatch,
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
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

                            // System messages (member add/remove)
                            if (messageType == "SYSTEM") {
                              return Padding(
                                key: _itemKeys[index],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1E8D5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      message,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4A4A4A),
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final isMine =
                                senderName.toLowerCase() ==
                                currentUserName.toLowerCase();
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

                                // Bubble
                                Align(
                                  alignment: isMine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
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
                                            : messageType == "TASK"
                                            ? _buildTaskMessage(msg)
                                            : (_isSearching && isMatch)
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
                                                color: Colors.black.withValues(
                                                  alpha: 0.45,
                                                ),
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
                                ApiService.markChatRead(widget.challanId);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: _headerColor,
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

          // ── Input bar ─────────────────────────────────────────
          if (!_isSearching) ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _sending
                        ? null
                        : () async {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(
                                          Icons.picture_as_pdf,
                                        ),
                                        title: const Text("Document"),
                                        onTap: () async {
                                          Navigator.pop(context);

                                          final selectedDoc =
                                              await showDialog<
                                                Map<String, dynamic>
                                              >(
                                                context: this.context,
                                                builder: (_) =>
                                                    const ChatDocumentPickerDialog(),
                                              );

                                          if (selectedDoc != null) {
                                            setState(() {
                                              selectedDocumentId =
                                                  selectedDoc["DocumentId"]
                                                      ?.toString();

                                              selectedDocumentType =
                                                  selectedDoc["DocumentType"]
                                                      ?.toString();

                                              messageController.text =
                                                  selectedDoc["DocumentNo"]
                                                      ?.toString() ??
                                                  "";
                                            });
                                          }
                                        },
                                      ),

                                      ListTile(
                                        leading: const Icon(Icons.task_alt),
                                        title: const Text("Assign Task"),
                                        onTap: () {
                                          Navigator.pop(context);

                                          _showAssignTaskDialog();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                  ),
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        // Ctrl+Enter or Shift+Enter sends on desktop
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          final isCtrl =
                              HardwareKeyboard.instance.isControlPressed;
                          final isShift =
                              HardwareKeyboard.instance.isShiftPressed;
                          if ((isCtrl || isShift) && !_sending) {
                            sendMessage();
                          }
                        }
                      },
                      child: TextField(
                        controller: messageController,
                        focusNode: _inputFocusNode,
                        enabled: !_sending,
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: _sending ? "Sending…" : "Type message...",
                          filled: true,
                          fillColor: const Color(0xFFF0F0F0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Material(
                            color: _headerColor,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: sendMessage,
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Reusable popup menu row ──────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

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
                fontWeight: FontWeight.bold,
              ),
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
                  fontWeight: FontWeight.bold,
                ),
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
                    Text(
                      "No members yet",
                      style: TextStyle(color: Colors.grey),
                    ),
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
                    timeLabel = DateFormat(
                      'dd MMM yyyy',
                    ).format(DateTime.parse(addedOn));
                  } catch (_) {}

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF075E54),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isMe)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF075E54),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "You",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: timeLabel.isNotEmpty
                        ? Text(
                            "Added $timeLabel",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                    trailing: widget.removeMode && !isMe
                        ? isRemoving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                    size: 22,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Remove Member"),
                                        content: Text(
                                          "Remove $userName from this chat?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              "Remove",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm != true) return;
                                    setState(() => _removing.add(userId));
                                    final ok = await widget.onRemoved(
                                      userId,
                                      userName,
                                    );
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

  const _AddMemberDialog({required this.availableUsers, required this.onAdd});

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
      final name = (u['name']?.toString() ?? '').toLowerCase();
      final id = (u['id']?.toString() ?? '').toLowerCase();
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
            Icon(
              Icons.person_add_alt_1_outlined,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              "Add Member",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        "No users found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final user = filtered[i];
                        final userId = user['id']?.toString() ?? '';
                        final userName = user['name']?.toString() ?? userId;
                        // HeadName no longer returned — subtitle omitted
                        final isAdding = _adding.contains(userId);
                        final isAdded = _added.contains(userId);

                        return ListTile(
                          key: ValueKey(userId),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isAdded
                                ? Colors.green
                                : const Color(0xFF128C7E),
                            child: isAdded
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: null,
                          trailing: isAdded
                              ? const Text(
                                  "Added",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : isAdding
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF075E54),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    minimumSize: const Size(60, 32),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () async {
                                    setState(() => _adding.add(userId));
                                    final ok = await widget.onAdd(
                                      userId,
                                      userName,
                                    );
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
// Multi-select user list. Returns List<Map<String,dynamic>> of selected users (full objects with 'database').

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
    // Only include users with a valid (non-empty) id to avoid duplicate-key issues
    final valid = widget.allUsers
        .where((u) => (u['id']?.toString() ?? '').isNotEmpty)
        .toList();
    if (q.isEmpty) return valid;
    return valid.where((u) {
      final name = (u['name']?.toString() ?? '').toLowerCase();
      final id = (u['id']?.toString() ?? '').toLowerCase();
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        "No users found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final user = filtered[i];
                        final userId = user['id']?.toString() ?? '';
                        final userName = user['name']?.toString() ?? userId;
                        final isSelected = _selected.contains(userId);

                        return CheckboxListTile(
                          key: ValueKey(userId),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          activeColor: const Color(0xFF075E54),
                          value: isSelected,
                          onChanged: userId.isEmpty
                              ? null
                              : (v) {
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
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF075E54),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _selected.isEmpty
              ? null
              : () {
                  // Return full user objects so callers can access 'database'
                  final selected = widget.allUsers
                      .where((u) => _selected.contains(u['id']?.toString()))
                      .toList();
                  Navigator.pop(context, selected);
                },
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
                fontWeight: FontWeight.bold,
              ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
