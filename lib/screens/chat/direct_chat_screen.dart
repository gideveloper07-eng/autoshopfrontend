import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import 'chat_document_picker_dialog.dart';
import 'group_chat_screen.dart';
import '../../database/models/chat_message.dart';
import '../../database/models/chat_receiver.dart';
import '../../chat/repository/chat_repository.dart';
import '../../chat/utils/conversation_helper.dart';
import '../../theme/app_colors.dart';

// ── Avatar color helper ─────────────────────────────────────────────────────
const List<Color> _kAvatarColors = [
  Color(0xFF00BCD4), // cyan
  Color(0xFF7B68EE), // slate blue
  Color(0xFFFF7043), // deep orange
  Color(0xFF26A69A), // teal
  Color(0xFFAB47BC), // purple
  Color(0xFF42A5F5), // blue
  Color(0xFFEC407A), // pink
  Color(0xFF66BB6A), // green
  Color(0xFFFFB300), // amber
  Color(0xFF8D6E63), // brown
];

Color _avatarColorFrom(String name) {
  if (name.isEmpty) return _kAvatarColors[0];
  return _kAvatarColors[name.codeUnitAt(0) % _kAvatarColors.length];
}

/// A 1-on-1 direct chat screen backed by a group conversation.
/// UI is identical to ChallanChatDialog (individual chat style).
class DirectChatScreen extends StatefulWidget {
  final String groupId;
  final String userName;
  final String targetUserId;

  /// Optional company name shown below the user name in the app bar.
  /// Pass this when the contact belongs to a different dealership.
  final String? companyName;

  /// Optional branch name shown alongside company name in the app bar.
  final String? branchName;

  final String? receiverPropertyCode;

  /// The database where this group's data is stored (employee's company DB).
  /// Used to route task creation and messages to the correct dealership DB.
  final String? groupDatabase;

  const DirectChatScreen({
    super.key,
    required this.groupId,
    required this.userName,
    required this.targetUserId,
    this.companyName,
    this.branchName,
    this.receiverPropertyCode,
    this.groupDatabase,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  Timer? _syncTimer;
  StreamSubscription<String>? _chatSubscription;

  //List<dynamic> messages = [];
  List<ChatMessage> messages = [];
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

  // ── Theme colors ───────────────────────────────────────────────
  Color get _appBarBg => Theme.of(context).colorScheme.surface;
  Color get _appBarText => Theme.of(context).colorScheme.onSurface;
  Color get _appBarIcon =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
  Color get _sendButtonBg => AppColors.primary;

  /// Returns the receiver's PropertyCode.
  /// Uses [widget.receiverPropertyCode] if set, otherwise extracts it from
  /// loaded messages by finding the other participant's SenderPropertyCode.
  String get _receiverPropertyCode {
    final fromWidget = widget.receiverPropertyCode ?? '';
    if (fromWidget.isNotEmpty) return fromWidget;

    for (final msg in messages) {
      if (msg.senderUserId != _myId &&
          (msg.senderPropertyCode?.isNotEmpty ?? false)) {
        return msg.senderPropertyCode!;
      }
    }

    return '';
  }

  /// Returns the receiver's company name for display in messages.
  /// Uses [widget.companyName] if set, otherwise infers from messages.
  String get _receiverCompanyName {
    return widget.companyName ?? "";
  }

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

  ChatReceiver _resolveReceiver() {
    String receiverUserId = widget.targetUserId.trim();
    String receiverName = widget.userName;
    String receiverDatabase = widget.groupDatabase ?? '';

    for (final m in _members) {
      final uid = (m["UserId"]?.toString() ?? "").trim();

      if (uid != _myId && uid.isNotEmpty) {
        receiverUserId = uid;
        receiverName = m["UserName"]?.toString() ?? "";
        receiverDatabase = m["DatabaseName"]?.toString() ?? "";
        break;
      }
    }

    return ChatReceiver(
      userId: receiverUserId,
      name: receiverName,
      database: receiverDatabase,
      propertyCode: widget.receiverPropertyCode ?? '',
    );
  }

  @override
  void initState() {
    super.initState();

    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);

    _chatSubscription = ChatRepository.instance.conversationUpdates.listen(
      _onConversationChanged,
    );

    _init();
    _syncTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _syncConversation(),
    );
  }

  Future<void> _syncConversation() async {
    if (!mounted) return;

    final receiver = _resolveReceiver();

    await ChatRepository.instance.loadDirectConversation(
      targetUserId: receiver.userId,
      receiverPropertyCode: receiver.propertyCode,
      receiverDatabase: receiver.database,
    );
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _msgCtrl.dispose();
    _inputFocus.dispose();
    _taskTitleCtrl.dispose();
    _taskDescCtrl.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final sw = Stopwatch()..start();

    debugPrint("INIT START");

    _myName = await ApiService.getUserName() ?? '';
    debugPrint("getUserName: ${sw.elapsedMilliseconds} ms");

    _myId = await ApiService.getUserId() ?? '';
    debugPrint("getUserId: ${sw.elapsedMilliseconds} ms");

    await _loadMembers();
    debugPrint("loadMembers: ${sw.elapsedMilliseconds} ms");

    await _loadMessages(isInitial: true);
    debugPrint("loadMessages: ${sw.elapsedMilliseconds} ms");

    debugPrint("INIT COMPLETE");
  }

  Future<void> _loadMembers() async {
    if (widget.groupId.isEmpty) {
      if (mounted) setState(() => _members = []);
      return;
    }
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
    final receiver = _resolveReceiver();

    final data = await ChatRepository.instance.loadDirectConversation(
      targetUserId: receiver.userId,
      receiverPropertyCode: receiver.propertyCode,
      receiverDatabase: receiver.database,
    );

    if (!mounted) return;

    final hasNew = data.length != messages.length;

    setState(() {
      messages = data;
      debugPrint("===== UI =====");
      for (final m in messages) {
        debugPrint("${m.chatId} | ${m.messageText}");
      }
      debugPrint("==============");
      loading = false;
    });

    if (isInitial) {
      _scrollToBottom(animated: false);
    } else if (hasNew && !_userScrolledUp) {
      _scrollToBottom();
    } else if (hasNew && _userScrolledUp) {
      setState(() {
        _newWhileScrolledUp++;
      });
    }
  }

  Future<void> _onConversationChanged(String conversationId) async {
    final receiver = _resolveReceiver();

    final currentConversationId = ConversationHelper.directConversationId(
      databaseName: receiver.database,
      userId: receiver.userId,
      propertyCode: receiver.propertyCode,
    );

    if (conversationId != currentConversationId) {
      return;
    }

    final latest = await ChatRepository.instance.getMessages(conversationId);

    if (!mounted) return;

    final oldCount = messages.length;
    final hasNew = latest.length > oldCount;

    setState(() {
      messages = latest;
      loading = false;

      if (_userScrolledUp && hasNew) {
        _newWhileScrolledUp++;
      }
    });

    if (!_userScrolledUp) {
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();

    if (text.isEmpty && _selectedDocumentId == null) {
      return;
    }

    final senderName = await ApiService.getUserName() ?? '';

    final receiver = _resolveReceiver();

    setState(() {
      _sending = true;
    });

    _msgCtrl.clear();

    debugPrint("SEND 1");
    final ok = await ChatRepository.instance.sendDirectMessage(
      receiverId: receiver.userId,
      receiverPropertyCode: receiver.propertyCode,
      receiverDatabase: receiver.database,
      receiverName: receiver.name,
      senderName: senderName,
      senderId: _myId,
      message: text,
      documentId: _selectedDocumentId,
      documentType: _selectedDocumentType,
    );
    debugPrint("SEND 2");
    _selectedDocumentId = null;
    _selectedDocumentType = null;

    if (mounted) {
      setState(() {
        _sending = false;
      });
    }

    if (ok) {
      _scrollToBottom();
    }
  }
  // ── Task assign dialog ───────────────────────────────────────────

  void _showAssignTaskDialog() async {
    // ── Cross-company check ────────────────────────────────────────────────
    // Tasks can only be assigned within the same company. If the receiver
    // belongs to a different company, show the switch-company message.
    final receiverCode = _receiverPropertyCode;
    if (receiverCode.isNotEmpty) {
      final session = await ApiService.getUserSession();
      final currentCode = (session?['companyCode'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (currentCode.isNotEmpty && receiverCode.toLowerCase() != currentCode) {
        if (!mounted) return;
        final companyLabel = _receiverCompanyName.isNotEmpty
            ? _receiverCompanyName
            : 'the other company';
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.swap_horiz_rounded, color: Colors.orange, size: 26),
                SizedBox(width: 10),
                Text(
                  'Switch Company',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Text(
              'Tasks can only be assigned to employees of the same company.\n\n'
              'Please switch to $companyLabel to assign a task to this user.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }
    // ── Same company — show the task dialog ───────────────────────────────
    _taskTitleCtrl.clear();
    _taskDescCtrl.clear();
    _selectedPriority = 'Medium';
    _taskStartDate = null;
    _taskDueDate = null;

    // Determine the other participant in this DM group
    String assignedToId = widget.targetUserId;
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
                final ok = await ApiService.createIndividualTask(
                  receiverId: assignedToId.isNotEmpty ? assignedToId : _myId,
                  receiverPropertyCode: widget.receiverPropertyCode ?? '',
                  taskTitle: _taskTitleCtrl.text.trim(),
                  taskDescription: _taskDescCtrl.text.trim(),
                  priority: _selectedPriority,
                  startDate: _taskStartDate?.toIso8601String(),
                  dueDate: _taskDueDate?.toIso8601String(),
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
          backgroundColor: AppColors.primary,
          content: Text('Group "$groupName" created!'),
        ),
      );
      if (gId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'GroupChatScreen'),
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
      final text = (messages[i].messageText ?? '').toLowerCase();
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

  String _formatTime(int millis) {
    return DateFormat(
      'hh:mm a',
    ).format(DateTime.fromMillisecondsSinceEpoch(millis));
  }

  String? _dateSeparator(int index) {
    final current = DateTime.fromMillisecondsSinceEpoch(
      messages[index].messageTime,
    );

    if (index == 0) {
      return DateFormat('dd MMM yyyy').format(current);
    }

    final previous = DateTime.fromMillisecondsSinceEpoch(
      messages[index - 1].messageTime,
    );

    if (previous.year != current.year ||
        previous.month != current.month ||
        previous.day != current.day) {
      return DateFormat('dd MMM yyyy').format(current);
    }

    return null;
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? _buildEmptyState()
                : Stack(
                    children: [
                      _buildMessageList(isDark),
                      if (_userScrolledUp && _newWhileScrolledUp > 0)
                        _buildNewMessageBanner(isDark),
                    ],
                  ),
          ),
          if (!_isSearching) _buildInputBar(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _appBarBg,
      elevation: 0.5,
      iconTheme: IconThemeData(color: _appBarIcon),
      titleSpacing: 0,
      title: _isSearching
          ? TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style: TextStyle(color: _appBarText, fontSize: 16),
              cursorColor: _appBarText,
              decoration: InputDecoration(
                hintText: 'Search messages…',
                hintStyle: TextStyle(color: _appBarIcon.withOpacity(0.6)),
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
                    color: _avatarColorFrom(widget.userName),
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
                        style: TextStyle(
                          color: _appBarText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.companyName != null &&
                          widget.companyName!.isNotEmpty)
                        Text(
                          (widget.branchName != null &&
                                  widget.branchName!.isNotEmpty)
                              ? '${widget.companyName!} • ${widget.branchName!}'
                              : widget.companyName!,
                          style: TextStyle(
                            color: _appBarIcon,
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
            color: _appBarIcon,
          ),
          onPressed: _toggleSearch,
        ),
        if (!_isSearching)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _appBarIcon),
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
                color: AppColors.bg(context),
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
                        style: TextStyle(color: _appBarIcon, fontSize: 13),
                      ),
                    ),
                    if (_matchIndices.isNotEmpty) ...[
                      IconButton(
                        icon: Icon(
                          Icons.keyboard_arrow_up,
                          color: _appBarIcon,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _prevMatch,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: _appBarIcon,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.card(context),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👋', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMed(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Say Hello to ${widget.userName} 👋',
            style: TextStyle(fontSize: 13, color: AppColors.textMed(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        _itemKeys[index] ??= GlobalKey();
        final sep = _dateSeparator(index);
        final msg = messages[index];
        final sender = msg.senderName ?? '';
        final text = msg.messageText ?? '';
        final time = msg.messageTime;
        final msgType = msg.messageType;
        final docId = msg.documentId;
        final docNo = msg.documentNo ?? '';
        final docType = msg.documentType ?? '';
        final isMine = msg.senderUserId == _myId;
        final isMatch = _matchIndices.contains(index);
        final isActive =
            _matchIndices.isNotEmpty && _matchIndices[_currentMatch] == index;

        return Column(
          key: _itemKeys[index],
          children: [
            if (sep != null) _buildDateSeparator(sep, isDark),
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
                      ? Colors.yellow.shade200
                      : isMatch
                      ? Colors.yellow.shade100
                      : isMine
                      ? (isDark
                            ? const Color(0xFF005C4B)
                            : const Color(0xFFD9FDD3))
                      : (isDark ? const Color(0xFF202C33) : Colors.white),
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
                    if (!isMine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          sender,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF54656F),
                          ),
                        ),
                      ),
                    msgType == 'DOCUMENT'
                        ? _buildDocumentBubble(docNo, docType, docId, isDark)
                        : msgType == 'TASK'
                        ? _buildTaskMessage(msg, isDark)
                        : Text(
                            text,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Spacer(),
                        Text(
                          _formatTime(msg.messageTime),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white54
                                : Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          _buildMessageStatus(msg),
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

  Widget _buildMessageStatus(ChatMessage msg) {
    switch (msg.status) {
      case 'sending':
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        );

      case 'failed':
        return const Icon(Icons.error_outline, color: Colors.red, size: 14);

      case 'sent':
        return const Icon(Icons.done, size: 14);

      case 'delivered':
        return const Icon(Icons.done_all, size: 14);

      case 'read':
        return const Icon(Icons.done_all, color: Colors.blue, size: 14);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTaskMessage(ChatMessage msg, bool isDark) {
    final taskId = msg.taskId ?? '';
    final taskDatabase = msg.taskDatabase ?? '';
    final currentStatus = msg.taskStatus ?? 'Pending';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange.shade900.withOpacity(0.3)
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.orange.shade700 : Colors.orange.shade300,
        ),
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
            msg.messageText ?? '',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assigned To: ${msg.assignedToName ?? msg.assignedTo ?? ''}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          if ((msg.taskDescription ?? '').isNotEmpty) ...[
            Text(
              msg.taskDescription ?? '',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'Priority: ${msg.priority ?? ''}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: $currentStatus',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
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
    bool isDark,
  ) {
    return InkWell(
      onTap: () async {
        if (documentId == null) return;

        // If this is a cross-company chat, check upfront whether the current
        // session's company matches the receiver's company. If not, the backend
        // will deny access — show the switch-company message immediately.
        final session = await ApiService.getUserSession();
        final currentPropertyCode = session?['companyCode'] ?? '';
        final receiverPropertyCode = _receiverPropertyCode;

        if (receiverPropertyCode.isNotEmpty &&
            currentPropertyCode.isNotEmpty &&
            receiverPropertyCode.toLowerCase() !=
                currentPropertyCode.toLowerCase()) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.orange,
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Switch Company',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: Text(
                'This document belongs to ${_receiverCompanyName.isNotEmpty ? _receiverCompanyName : "another company"}.\n\n'
                'Please switch to that company to view this document.',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        // Same company — fetch and open the document.
        final doc = await ApiService.getDocument(documentId);

        if (doc == null) {
          // Fallback: access denied even within same company context.
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.orange,
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Switch Company',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: const Text(
                'This document belongs to a different company.\n\n'
                'Please switch to the correct company to view this document.',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        final filePath = doc['FilePath']?.toString() ?? '';
        if (filePath.isEmpty) return;
        final url = 'http://myautoshop365.com/$filePath';
        await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.red.shade900.withOpacity(0.3)
              : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.red.shade700 : Colors.red.shade200,
          ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'PDF Document · Tap to open',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
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

  Widget _buildDateSeparator(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A3942) : const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF4A4A4A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewMessageBanner(bool isDark) {
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
              color: const Color(0xFF111B21),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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

  Widget _buildInputBar(bool isDark) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
      color: theme.colorScheme.surface,
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
                                      builder: (_) => ChatDocumentPickerDialog(
                                        receiverPropertyCode:
                                            _receiverPropertyCode,
                                        receiverCompanyName:
                                            _receiverCompanyName,
                                      ),
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
                  hintText: _sending ? 'Sending…' : 'Type message…',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
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
                    color: _sendButtonBg,
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
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.group_add_outlined,
              color: AppColors.textMed(context),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Add Group Members',
                style: TextStyle(
                  color: AppColors.textHigh(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selected.length} selected',
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
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
                          activeColor: AppColors.primary,
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
                                ? AppColors.primary
                                : _avatarColorFrom(uname),
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
            backgroundColor: AppColors.primary,
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
        decoration: BoxDecoration(
          color: AppColors.card(context),
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.group, color: AppColors.textMed(context), size: 20),
            const SizedBox(width: 10),
            Text(
              'Name Your Group',
              style: TextStyle(
                color: AppColors.textHigh(context),
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
            backgroundColor: AppColors.primary,
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
