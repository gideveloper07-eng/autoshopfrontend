import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import 'chat_document_picker_dialog.dart';
import 'group_chat_screen.dart';

/// A 1-on-1 direct chat screen backed by a group conversation.
/// UI is identical to ChallanChatDialog (individual chat style).
class DirectChatScreen extends StatefulWidget {
  final String groupId;
  final String userName;

  /// Optional company name shown below the user name in the app bar.
  /// Pass this when the contact belongs to a different dealership.
  final String? companyName;

  /// The database where this group's data is stored (employee's company DB).
  /// Used to route task creation and messages to the correct dealership DB.
  final String? groupDatabase;

  const DirectChatScreen({
    super.key,
    required this.groupId,
    required this.userName,
    this.companyName,
    this.groupDatabase,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  List<dynamic> messages = [];
  bool loading = true;
  bool _sending = false;
  String _myName = '';
  String _myId = '';
  bool _userScrolledUp = false;
  int _newWhileScrolledUp = 0;

  // ── Members ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> _members = [];

  // ── Document attachment ─────────────────────────────────────────
  String? _selectedDocumentId;
  String? _selectedDocumentType;

  // ── Task assign ─────────────────────────────────────────────────
  final TextEditingController _taskTitleCtrl = TextEditingController();
  final TextEditingController _taskDescCtrl = TextEditingController();
  String _selectedPriority = 'Medium';
  DateTime? _taskStartDate;
  DateTime? _taskDueDate;

  // ── Search ──────────────────────────────────────────────────────
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<int> _matchIndices = [];
  int _currentMatch = 0;
  final Map<int, GlobalKey> _itemKeys = {};

  Timer? _timer;
  static const Color _green = Color(0xFF075E54);
  static const Color _subGreen = Color(0xFF128C7E);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
    _init();
    // FIX: guard with mounted check to prevent setState after dispose
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_isSearching) _loadMessages();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _msgCtrl.dispose();
    _inputFocus.dispose();
    _taskTitleCtrl.dispose();
    _taskDescCtrl.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _myName = await ApiService.getUserName() ?? '';
    _myId = await ApiService.getUserId() ?? '';
    await Future.wait([_loadMessages(isInitial: true), _loadMembers()]);
  }

  Future<void> _loadMembers() async {
    final data = await ApiService.getGroupMembers(widget.groupId);
    if (mounted) setState(() => _members = data);
  }

  // ── Scroll ──────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final atBottom =
        _scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 50;
    if (atBottom) {
      if (_userScrolledUp) {
        setState(() {
          _userScrolledUp = false;
          _newWhileScrolledUp = 0;
        });
      }
    } else {
      _userScrolledUp = true;
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      if (animated) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  // ── Data ────────────────────────────────────────────────────────

  Future<void> _loadMessages({bool isInitial = false}) async {
    final data = await ApiService.getGroupMessages(widget.groupId);

    print("Messages received = ${data.length}");
    print(messages);

    if (!mounted) return;
    final oldCount = messages.length;
    final hasNew = data.length > oldCount;
    int newFromOthers = 0;
    if (hasNew && !isInitial) {
      for (int i = oldCount; i < data.length; i++) {
        final sender = data[i]['SenderName']?.toString() ?? '';
        if (sender.toLowerCase() != _myName.toLowerCase()) newFromOthers++;
      }
    }
    setState(() {
      messages = data;
      loading = false;
      if (!isInitial && _userScrolledUp && newFromOthers > 0) {
        _newWhileScrolledUp += newFromOthers;
      }
    });
    if (_isSearching && _searchCtrl.text.trim().isNotEmpty) {
      _rebuildMatchIndices();
    }
    if (isInitial) {
      _scrollToBottom(animated: false);
    } else if (hasNew && !_userScrolledUp) {
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    final senderName = await ApiService.getUserName() ?? "";
    print("MY ID: $_myId");
    print("GROUP MEMBERS:");
    for (final m in _members) {
      print(m);
    }

    if (text.isEmpty && _selectedDocumentId == null) return;
    setState(() => _sending = true);
    _msgCtrl.clear();

    String receiverUserId = "";
    String receiverName = "";
    String receiverDatabase = "";

    print("MY ID = $_myId");

    for (final m in _members) {
      final uid = m["UserId"]?.toString() ?? "";

      print("Checking member: $uid");

      if (uid != _myId && uid.isNotEmpty) {
        receiverUserId = uid;
        receiverName = m["UserName"]?.toString() ?? "";
        receiverDatabase = m["DatabaseName"]?.toString() ?? "";

        print("FOUND RECEIVER");
        print(receiverUserId);
        print(receiverDatabase);
        break;
      }
    }

    print("receiverUserId = $receiverUserId");

    final ok = await ApiService.sendChatMessage(
      challanId: "0001",
      messageText: text.isNotEmpty ? text : (_selectedDocumentType ?? ''),
      senderName: senderName,
      challanNo: "", // or actual challan number
      databaseName: '',
      receiverDbName: receiverDatabase,
      receiverUserId: receiverUserId,
      receiverName: receiverName,
      messageType: _selectedDocumentId != null ? "DOCUMENT" : "TEXT",
      documentId: _selectedDocumentId,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _selectedDocumentId = null;
        _selectedDocumentType = null;
        _userScrolledUp = false;
        _newWhileScrolledUp = 0;
      });
      await _loadMessages();
      _scrollToBottom();
    } else {
      _msgCtrl.text = text;
    }
    if (mounted) setState(() => _sending = false);
  }

  // ── Task assign dialog ───────────────────────────────────────────

  void _showAssignTaskDialog() {
    _taskTitleCtrl.clear();
    _taskDescCtrl.clear();
    _selectedPriority = 'Medium';
    _taskStartDate = null;
    _taskDueDate = null;

    // Determine the other participant in this DM group
    String assignedToId = '';
    String assignedToName = widget.userName;
    String assignedToDatabase = widget.groupDatabase ?? '';
    for (final m in _members) {
      final uid = m['UserId']?.toString() ?? '';
      if (uid != _myId && uid.isNotEmpty) {
        assignedToId = uid;
        assignedToName = m['UserName']?.toString() ?? widget.userName;
        // Use the member's stored DatabaseName if available
        final memberDb = m['DatabaseName']?.toString() ?? '';
        if (memberDb.isNotEmpty) assignedToDatabase = memberDb;
        break;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          title: const Text('Assign Task'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _taskTitleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taskDescCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Show who the task will be assigned to
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Assign To: $assignedToName',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'High', child: Text('High')),
                    ],
                    onChanged: (v) => setDS(() => _selectedPriority = v!),
                  ),
                  const SizedBox(height: 12),
                  // ── Start Date ──────────────────────────────────
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: _taskStartDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDS(() => _taskStartDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        _taskStartDate != null
                            ? DateFormat('dd MMM yyyy').format(_taskStartDate!)
                            : 'Select date',
                        style: TextStyle(
                          color: _taskStartDate != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Due Date ────────────────────────────────────
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate:
                            _taskDueDate ?? (_taskStartDate ?? DateTime.now()),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDS(() => _taskDueDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        _taskDueDate != null
                            ? DateFormat('dd MMM yyyy').format(_taskDueDate!)
                            : 'Select date',
                        style: TextStyle(
                          color: _taskDueDate != null
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_taskTitleCtrl.text.trim().isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                final ok = await ApiService.createTask(
                  groupId: widget.groupId,
                  taskTitle: _taskTitleCtrl.text.trim(),
                  taskDescription: _taskDescCtrl.text.trim(),
                  assignedTo: assignedToId.isNotEmpty ? assignedToId : _myId,
                  priority: _selectedPriority,
                  startDate: _taskStartDate?.toIso8601String(),
                  dueDate: _taskDueDate?.toIso8601String(),
                  assignedToDatabase: assignedToDatabase.isNotEmpty
                      ? assignedToDatabase
                      : null,
                );
                if (!mounted) return;
                nav.pop();
                if (ok) {
                  await _loadMessages();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Task assigned successfully')),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Failed to assign task')),
                  );
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  // ── New Group flow ───────────────────────────────────────────────

  void _showNewGroupFlow() async {
    final allUsers = await ApiService.getCompanyUsers();
    if (!mounted) return;
    // Returns List<Map<String,dynamic>> with full user objects (including 'database')
    final pickedUsers = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => _DmPickMembersDialog(allUsers: allUsers),
    );
    if (pickedUsers == null || pickedUsers.isEmpty) return;
    if (!mounted) return;

    final pickedIds = pickedUsers
        .map((u) => u['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    // Determine the group's target DB from the first member that has one set
    final groupDb = pickedUsers
        .map((u) => u['database']?.toString() ?? '')
        .firstWhere((db) => db.isNotEmpty, orElse: () => '');

    final groupName = await showDialog<String>(
      context: context,
      builder: (_) => const _DmNameGroupDialog(),
    );
    if (groupName == null || groupName.trim().isEmpty) return;
    final result = await ApiService.createGroup(
      groupName: groupName.trim(),
      memberIds: pickedIds,
      databaseName: groupDb.isNotEmpty ? groupDb : null,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final gId = result['groupId']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _green,
          content: Text('Group "$groupName" created!'),
        ),
      );
      if (gId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              groupId: gId,
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

  // ── Search ──────────────────────────────────────────────────────

  void _onSearchChanged() => _rebuildMatchIndices();

  void _rebuildMatchIndices() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _matchIndices = [];
        _currentMatch = 0;
      });
      return;
    }
    final matches = <int>[];
    for (int i = 0; i < messages.length; i++) {
      final text = (messages[i]['MessageText']?.toString() ?? '').toLowerCase();
      if (text.contains(q)) matches.add(i);
    }
    setState(() {
      _matchIndices = matches;
      _currentMatch = matches.isEmpty ? 0 : matches.length - 1;
    });
    if (matches.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToIndex(matches.last),
      );
    }
  }

  void _scrollToIndex(int idx) {
    final key = _itemKeys[idx];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.3,
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchCtrl.clear();
        _matchIndices = [];
        _currentMatch = 0;
      }
    });
    if (_isSearching) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _searchFocus.requestFocus(),
      );
    }
  }

  void _prevMatch() {
    if (_matchIndices.isEmpty) return;
    setState(() {
      _currentMatch =
          (_currentMatch - 1 + _matchIndices.length) % _matchIndices.length;
    });
    _scrollToIndex(_matchIndices[_currentMatch]);
  }

  void _nextMatch() {
    if (_matchIndices.isEmpty) return;
    setState(() => _currentMatch = (_currentMatch + 1) % _matchIndices.length);
    _scrollToIndex(_matchIndices[_currentMatch]);
  }

  // ── Formatters ───────────────────────────────────────────────────

  String _formatTime(String? raw) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(raw!));
    } catch (_) {
      return raw ?? '';
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

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      _buildMessageList(),
                      if (_userScrolledUp && _newWhileScrolledUp > 0)
                        _buildNewMessageBanner(),
                    ],
                  ),
          ),
          if (!_isSearching) _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _green,
      iconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: 0,
      title: _isSearching
          ? TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search messages…',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
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
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : 'U',
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.companyName != null &&
                          widget.companyName!.isNotEmpty)
                        Text(
                          widget.companyName!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: _toggleSearch,
        ),
        if (!_isSearching)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onSelected: (v) {
              if (v == 'newGroup') _showNewGroupFlow();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'newGroup',
                child: _DmMenuRow(
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
                color: _subGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _searchCtrl.text.trim().isEmpty
                            ? 'Type to search…'
                            : _matchIndices.isEmpty
                            ? 'No results'
                            : '${_currentMatch + 1} of ${_matchIndices.length} matches',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
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
                        onPressed: _prevMatch,
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
                        onPressed: _nextMatch,
                      ),
                    ],
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        _itemKeys[index] ??= GlobalKey();
        final sep = _dateSeparator(index);
        final msg = messages[index];
        final sender = msg['SenderName']?.toString() ?? '';
        final text = msg['MessageText']?.toString() ?? '';
        final time = msg['MessageTime']?.toString() ?? '';
        final msgType = msg['MessageType']?.toString() ?? 'TEXT';
        final docId = msg['DocumentId']?.toString();
        final docNo = msg['DocumentNo']?.toString() ?? '';
        final docType = msg['DocumentType']?.toString() ?? '';
        final isMine = sender.toLowerCase() == _myName.toLowerCase();
        final isMatch = _matchIndices.contains(index);
        final isActive =
            _matchIndices.isNotEmpty && _matchIndices[_currentMatch] == index;

        return Column(
          key: _itemKeys[index],
          children: [
            if (sep != null) _buildDateSeparator(sep),
            Align(
              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
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
                  color: isActive
                      ? const Color(0xFFFFF176)
                      : isMatch
                      ? const Color(0xFFFFF9C4)
                      : isMine
                      ? const Color(0xFFDCF8C6)
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
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
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          sender,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _green,
                          ),
                        ),
                      ),
                    msgType == 'DOCUMENT'
                        ? _buildDocumentBubble(docNo, docType, docId)
                        : msgType == 'TASK'
                        ? _buildTaskMessage(msg)
                        : Text(
                            text,
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
                          _formatTime(time),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black.withOpacity(0.45),
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.done_all,
                            size: 14,
                            color: Colors.black45,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskMessage(dynamic msg) {
    final taskId = msg['TaskId']?.toString() ?? '';
    final taskDatabase = msg['TaskDatabase']?.toString() ?? '';
    final currentStatus = msg['TaskStatus']?.toString() ?? 'Pending';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 6),
              const Text(
                'TASK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            msg['MessageText']?.toString() ?? '',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Assigned To: ${msg['AssignedToName'] ?? msg['AssignedTo'] ?? ''}',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          if ((msg['TaskDescription']?.toString() ?? '').isNotEmpty) ...[
            Text(
              msg['TaskDescription'].toString(),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'Priority: ${msg['Priority'] ?? ''}',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: $currentStatus',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: currentStatus,
            items: const [
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              DropdownMenuItem(
                value: 'In Progress',
                child: Text('In Progress'),
              ),
              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
            ],
            onChanged: (value) async {
              if (value == null) return;
              final ok = await ApiService.updateTaskStatus(
                taskId: taskId,
                status: value,
                groupId: widget.groupId,
                taskDatabase: taskDatabase.isNotEmpty ? taskDatabase : null,
              );
              if (ok && mounted) {
                await _loadMessages();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Task marked as $value')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentBubble(
    String documentNo,
    String documentType,
    String? documentId,
  ) {
    return InkWell(
      onTap: () async {
        if (documentId == null) return;
        final doc = await ApiService.getDocument(documentId);
        if (doc == null) return;
        final filePath = doc['FilePath']?.toString() ?? '';
        if (filePath.isEmpty) return;
        final url = 'http://myautoshop365.com/$filePath';
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
                    '$documentType #$documentNo',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    'PDF Document · Tap to open',
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

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD1E8D5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A4A4A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewMessageBanner() {
    return Positioned(
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
            _scrollToBottom();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
    );
  }

  // ── Input bar (with attach + task + send) ────────────────────────

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Attach button — opens document picker + task option
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _sending
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      builder: (sheetCtx) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.picture_as_pdf),
                              title: const Text('Document'),
                              onTap: () async {
                                Navigator.pop(sheetCtx);
                                final selectedDoc =
                                    await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (_) =>
                                          const ChatDocumentPickerDialog(),
                                    );
                                if (selectedDoc != null && mounted) {
                                  setState(() {
                                    _selectedDocumentId =
                                        selectedDoc['DocumentId']?.toString();
                                    _selectedDocumentType =
                                        selectedDoc['DocumentType']?.toString();
                                    _msgCtrl.text =
                                        selectedDoc['DocumentNo']?.toString() ??
                                        '';
                                  });
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.task_alt),
                              title: const Text('Assign Task'),
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                _showAssignTaskDialog();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
          ),

          // Text field
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  final isCtrl = HardwareKeyboard.instance.isControlPressed;
                  final isShift = HardwareKeyboard.instance.isShiftPressed;
                  if ((isCtrl || isShift) && !_sending) _sendMessage();
                }
              },
              child: TextField(
                controller: _msgCtrl,
                focusNode: _inputFocus,
                enabled: !_sending,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: _sending ? 'Sending…' : 'Type message...',
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

          // Send button
          SizedBox(
            width: 44,
            height: 44,
            child: _sending
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Material(
                    color: _green,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sendMessage,
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
    );
  }
}

// ── Menu row ─────────────────────────────────────────────────────────────────

class _DmMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DmMenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black87),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }
}

// ── Pick Members Dialog ───────────────────────────────────────────────────────

class _DmPickMembersDialog extends StatefulWidget {
  final List<Map<String, dynamic>> allUsers;
  const _DmPickMembersDialog({required this.allUsers});

  @override
  State<_DmPickMembersDialog> createState() => _DmPickMembersDialogState();
}

class _DmPickMembersDialogState extends State<_DmPickMembersDialog> {
  final TextEditingController _filter = TextEditingController();
  final Set<String> _selected = {};

  List<Map<String, dynamic>> get _filtered {
    final q = _filter.text.trim().toLowerCase();
    final valid = widget.allUsers
        .where((u) => (u['id']?.toString() ?? '').isNotEmpty)
        .toList();
    if (q.isEmpty) {
      return valid;
    }
    return valid.where((u) {
      final name = (u['name']?.toString() ?? '').toLowerCase();
      return name.contains(q);
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
                'Add Group Members',
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
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selected.length} selected',
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
                hintText: 'Search users…',
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
                        'No users found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final u = filtered[i];
                        final uid = u['id']?.toString() ?? '';
                        final uname = u['name']?.toString() ?? uid;
                        final sel = _selected.contains(uid);
                        return CheckboxListTile(
                          key: ValueKey(uid),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          activeColor: const Color(0xFF075E54),
                          value: sel,
                          onChanged: uid.isEmpty
                              ? null
                              : (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selected.add(uid);
                                    } else {
                                      _selected.remove(uid);
                                    }
                                  });
                                },
                          secondary: CircleAvatar(
                            backgroundColor: sel
                                ? const Color(0xFF075E54)
                                : const Color(0xFF128C7E),
                            child: sel
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : Text(
                                    uname.isNotEmpty
                                        ? uname[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                          title: Text(
                            uname,
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
          child: const Text('Cancel'),
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
          child: Text('Next  (${_selected.length})'),
        ),
      ],
    );
  }
}

// ── Name Group Dialog ─────────────────────────────────────────────────────────

class _DmNameGroupDialog extends StatefulWidget {
  const _DmNameGroupDialog();
  @override
  State<_DmNameGroupDialog> createState() => _DmNameGroupDialogState();
}

class _DmNameGroupDialogState extends State<_DmNameGroupDialog> {
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
              'Name Your Group',
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
          hintText: 'Group name…',
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
          child: const Text('Cancel'),
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
          child: const Text('Create Group'),
        ),
      ],
    );
  }
}

// ignore_for_file: deprecated_member_use
