import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import 'challan_chat_dialog.dart';
import 'direct_chat_screen.dart';
import 'group_chat_screen.dart';
import 'new_chat_screen.dart';

// ── Avatar palette — picks a consistent colour from the name ─────────────────
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

Color _avatarColor(String name) {
  if (name.isEmpty) return _kAvatarColors[0];
  final index = name.codeUnitAt(0) % _kAvatarColors.length;
  return _kAvatarColors[index];
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCompany = "ALL";
  String _selectedGroupCompany = "ALL";
  String _selectedAllCompany = "ALL";

  // ── Tabs ─────────────────────────────────────────────────────────
  // 0 = All, 1 = Chats, 2 = Groups
  late TabController _tabController;

  // ── Data ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> challans = [];
  final Map<String, _ChatMeta> _chatMeta = {};

  List<dynamic> _groups = [];
  List<dynamic> _directChats = [];

  // ── Users ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _allUsers = [];

  // ── Accepted contacts (may have zero messages) ───────────────────
  List<dynamic> _myContacts = [];

  bool isLoading = true;
  String? errorMessage;

  // ── Search ───────────────────────────────────────────────────────
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ── Polling ──────────────────────────────────────────────────────
  Timer? _pollTimer;

  static const Color _appBarIcon = Color(0xFF54656F);

  String _myId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() {
      if (_isSearching) setState(() {});
    });
    _loadAll();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadAll(silent: true),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollTimer?.cancel();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<String> get _companies {
    final companies = _directChats
        .map((e) => (e["CompanyName"] ?? "").toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    companies.sort();

    return ["ALL", ...companies];
  }

  List<String> get _groupCompanies {
    final companies = _groups
        .map((g) => (g["DatabaseName"] ?? "").toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    companies.sort();

    return ["ALL", ...companies];
  }
  // ── Load ─────────────────────────────────────────────────────────

  Future<void> _loadAll({bool silent = false}) async {
    // ── Step 1: Load from cache immediately ─────────────────────────────────
    final cachedChallans = await CacheService.getListMap(
      CacheService.keyChallanList,
    );
    final cachedDirectChats = await CacheService.getList(
      CacheService.keyDirectChats,
    );
    final cachedGroups = await CacheService.getList(CacheService.keyGroups);
    final cachedUsers = await CacheService.getListMap(
      CacheService.keyMergedUsers,
    );
    final cachedContacts = await CacheService.getList(CacheService.keyContacts);
    final hasCached = cachedChallans != null || cachedDirectChats != null;

    if (hasCached && mounted) {
      setState(() {
        if (cachedChallans != null) challans = cachedChallans;
        if (cachedDirectChats != null) _directChats = cachedDirectChats;
        if (cachedGroups != null) _groups = cachedGroups;
        if (cachedUsers != null) _allUsers = cachedUsers;
        if (cachedContacts != null) _myContacts = cachedContacts;
        // Only show spinner if we truly have nothing cached
        isLoading = false;
      });
    } else if (!silent) {
      // No cache at all — show loading spinner
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    // ── Step 2: Fetch fresh data from backend in background ──────────────────
    try {
      final results = await Future.wait([
        ApiService.getChallanRetailIncentive(),
        ApiService.getMyDirectChats(allChats: true),
        ApiService.getMyGroups(),
        ApiService.getMergedUsers(),
        ApiService.getUserId(),
        ApiService.getChatRequests(),
        ApiService.getMyContacts(),
      ]);

      final challanList = results[0] as List<Map<String, dynamic>>;
      final directChats = results[1] as List<dynamic>;
      final groupList = results[2] as List<dynamic>;
      final userList = results[3] as List<Map<String, dynamic>>;
      final myUserId = results[4] as String? ?? '';
      final myContacts = results[6] as List<dynamic>;

      // ── Step 3: Update cache ──────────────────────────────────────────────
      await Future.wait([
        CacheService.setListMap(CacheService.keyChallanList, challanList),
        CacheService.setList(CacheService.keyDirectChats, directChats),
        CacheService.setList(CacheService.keyGroups, groupList),
        CacheService.setListMap(CacheService.keyMergedUsers, userList),
        CacheService.setList(CacheService.keyContacts, myContacts),
      ]);

      // ── Step 4: Update UI if data changed ─────────────────────────────────
      if (mounted) {
        setState(() {
          challans = challanList;
          _directChats = directChats;
          _groups = groupList;
          _allUsers = userList;
          _myId = myUserId;
          _myContacts = myContacts;
          isLoading = false;
        });
      }

      // Load per-challan meta in background
      _loadAllChatMeta(challanList);
    } catch (e) {
      if (mounted) {
        setState(() {
          // Only show error if we couldn't show cached data either
          if (!hasCached) errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAllChatMeta(List<dynamic> chats) async {
    await Future.wait(
      chats.map((chat) async {
        final userId = chat["UserId"]?.toString() ?? "";
        final propertyCode = chat["PropertyCode"]?.toString() ?? "";

        if (userId.isEmpty || propertyCode.isEmpty) return;

        final unread = await ApiService.getUnreadChatCount(
          userId,
          propertyCode,
        );

        if (mounted) {
          setState(() {
            _chatMeta[userId] = _ChatMeta(
              lastMessage: chat["LastMessage"]?.toString() ?? "",
              lastTime: chat["LastMessageTime"]?.toString() ?? "",
              unreadCount: unread,
            );
          });
        }
      }),
    );
  }

  Future<void> _refreshSingleMeta(
    String receiverId,
    String receiverPropertyCode,
  ) async {
    final unread = await ApiService.getUnreadChatCount(
      receiverId,
      receiverPropertyCode,
    );

    if (mounted) {
      setState(() {
        final old = _chatMeta[receiverId];

        if (old != null) {
          _chatMeta[receiverId] = _ChatMeta(
            lastMessage: old.lastMessage,
            lastTime: old.lastTime,
            unreadCount: unread,
          );
        }
      });
    }
  }

  // ── Actions ──────────────────────────────────────────────────────

  void _openChat(Map<String, dynamic> challan) async {
    final challanId = challan['sp_462']?.toString() ?? '';
    final challanNo = challan['sp_468']?.toString() ?? '';

    if (challanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid challan. Cannot open chat.")),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ChallanChatDialog'),
        builder: (_) => ChallanChatDialog(
          challanId: challanId,
          challanNo: challanNo,
          customerName: challan['sp_469']?.toString() ?? '',
        ),
      ),
    );

    //  _refreshSingleMeta(challanId);
  }

  void _openGroup(dynamic group) async {
    final groupId = group['GroupId']?.toString() ?? '';
    final groupName = group['GroupName']?.toString() ?? 'Group';
    final groupDatabase = group['DatabaseName']?.toString();

    // Look up branchName from _allUsers by matching the group's database
    String branchName = '';
    if (groupDatabase != null && groupDatabase.isNotEmpty) {
      try {
        final matched = _allUsers.firstWhere(
          (u) =>
              (u['database']?.toString() ?? '').toLowerCase() ==
              groupDatabase.toLowerCase(),
          orElse: () => {},
        );
        branchName = (matched['branchName']?.toString() ?? '').trim();
      } catch (_) {}
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'GroupChatScreen'),
        builder: (_) => GroupChatScreen(
          groupId: groupId,
          groupName: groupName,
          groupDatabase: groupDatabase,
          branchName: branchName.isNotEmpty ? branchName : null,
        ),
      ),
    );
    _loadAll(silent: true);
  }

  /// Open a 1-on-1 chat with a user.
  /// Direct messages are stored in MA_ChallanChat, so this must not create MA_ChatGroups rows.
  void _openUserChat(
    String targetUserId,
    String targetUserName, {
    String? companyName,
    String? branchName,
    String? targetDatabase,
    String? receiverPropertyCode,
  }) async {
    if (targetUserId.isEmpty) return;

    Map<String, dynamic>? existingChat;
    try {
      existingChat = _directChats.cast<Map<String, dynamic>>().firstWhere(
        (g) =>
            (g["UserId"]?.toString() ?? "").toLowerCase() ==
            targetUserId.toLowerCase(),
      );
    } catch (_) {
      existingChat = null;
    }

    if (!mounted) return;

    // If an existing chat is found, prefer its PropertyCode so messages load correctly.
    final resolvedPropertyCode = receiverPropertyCode?.isNotEmpty == true
        ? receiverPropertyCode
        : existingChat?["PropertyCode"]?.toString();

    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'DirectChatScreen'),
        builder: (_) => DirectChatScreen(
          groupId: existingChat?["GroupId"]?.toString() ?? "",
          userName: targetUserName,
          targetUserId: targetUserId,
          companyName: companyName,
          branchName: branchName,
          groupDatabase:
              existingChat?["DatabaseName"]?.toString() ?? targetDatabase,
          receiverPropertyCode: resolvedPropertyCode,
        ),
      ),
    );

    _loadAll(silent: true);
  }

  /// New Group flow — Step 1 pick members, Step 2 name
  void _showNewGroupFlow() async {
    final allUsers = await ApiService.getCompanyUsers();
    //final allUsers = await ApiService.getMergedUsers();
    if (!mounted) return;

    // Returns List<Map<String,dynamic>> with full user objects (including 'database')
    final pickedUsers = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => _PickMembersDialog(allUsers: allUsers),
    );
    if (pickedUsers == null || pickedUsers.isEmpty) return;
    if (!mounted) return;

    // Extract plain IDs for the API call
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
      builder: (_) => const _NameGroupDialog(),
    );
    if (groupName == null || groupName.trim().isEmpty) return;

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
          backgroundColor: const Color(0xFF111B21),
          content: Text('Group "$groupName" created!'),
        ),
      );
      await _loadAll(silent: true);
      if (groupId.isNotEmpty && mounted) {
        await Navigator.push(
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
        _loadAll(silent: true);
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

  // ── Search filter helpers ─────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredChallans {
    if (!_isSearching) return challans;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return challans;
    return challans.where((c) {
      final no = (c['sp_468']?.toString() ?? '').toLowerCase();
      final name = (c['sp_469']?.toString() ?? '').toLowerCase();
      final challanId = c['sp_462']?.toString() ?? '';
      final lastMsg = (_chatMeta[challanId]?.lastMessage ?? '').toLowerCase();
      return no.contains(q) || name.contains(q) || lastMsg.contains(q);
    }).toList();
  }

  List<dynamic> get _filteredGroups {
    var groups = _groups.where((g) {
      final name = g["GroupName"]?.toString() ?? "";
      return !name.startsWith("DM:");
    }).toList();

    if (_selectedGroupCompany != "ALL") {
      groups = groups.where((g) {
        return (g["DatabaseName"] ?? "") == _selectedGroupCompany;
      }).toList();
    }

    if (_isSearching) {
      final q = _searchCtrl.text.toLowerCase();

      groups = groups.where((g) {
        return (g["GroupName"] ?? "").toString().toLowerCase().contains(q);
      }).toList();
    }

    return groups;
  }

  List<Map<String, dynamic>> get _chattedUsers {
    // Build from actual chat history first
    final fromChats = _directChats.map<Map<String, dynamic>>((chat) {
      final directChat = Map<String, dynamic>.from(chat as Map);
      final userId = _directChatUserId(directChat);
      final userName = _directChatUserName(directChat, userId);
      final lastMessage = _firstDirectChatValue(directChat, [
        'LastMessage',
        'MessageText',
        'TaskDescription',
      ]);
      final lastMessageTime = _firstDirectChatValue(directChat, [
        'LastMessageTime',
        'MessageTime',
      ]);

      final companyName = (directChat["CompanyName"]?.toString() ?? "").trim();

      // Look up branchName from _allUsers by matching loginId (uti = short login ID)
      String branchName = '';
      try {
        final matched = _allUsers.firstWhere(
          (u) =>
              (u['loginId']?.toString() ?? '').toLowerCase() ==
              userId.toLowerCase(),
          orElse: () => {},
        );
        branchName = (matched['branchName']?.toString() ?? '').trim();
      } catch (_) {}

      debugPrint(
        "User: $userName | CompanyName: '$companyName' | BranchName: '$branchName' | "
        "PropertyCode: ${directChat["PropertyCode"]} | "
        "DatabaseName: ${directChat["DatabaseName"]}",
      );

      return {
        "id": userId,
        "name": userName,
        "companyName": companyName,
        "branchName": branchName,
        "database": directChat["DatabaseName"] ?? "",
        "propertyCode": directChat["PropertyCode"] ?? "",
        "_dmGroup": {
          ...directChat,
          "LastMessage": lastMessage,
          "LastMessageTime": lastMessageTime,
        },
      };
    }).toList();

    // Collect IDs already present from chat history to avoid duplicates
    final existingIds = fromChats
        .map((u) => (u["id"] as String).toLowerCase())
        .toSet();

    // Add accepted contacts that have no chat history yet
    for (final contact in _myContacts) {
      final contactLoginId = (contact['loginId']?.toString() ?? '')
          .toLowerCase();
      final contactUserGuid = (contact['userGuid']?.toString() ?? '')
          .toLowerCase();

      // Skip if already represented in chat history
      if (existingIds.contains(contactLoginId) ||
          existingIds.contains(contactUserGuid)) {
        continue;
      }

      // Try to resolve full name + company from _allUsers
      Map<String, dynamic> matched = {};
      try {
        matched = _allUsers.firstWhere(
          (u) =>
              (u['id']?.toString() ?? '').toLowerCase() == contactUserGuid ||
              (u['loginId']?.toString() ?? '').toLowerCase() == contactLoginId,
          orElse: () => {},
        );
      } catch (_) {}

      final userName =
          matched['name']?.toString() ??
          contact['loginId']?.toString() ??
          contactUserGuid;
      final companyName = matched['companyName']?.toString() ?? '';
      final branchName = matched['branchName']?.toString() ?? '';
      final resolvedId =
          matched['loginId']?.toString() ??
          contact['loginId']?.toString() ??
          contactUserGuid;
      final database =
          matched['database']?.toString() ??
          contact['database']?.toString() ??
          '';
      final propertyCode =
          matched['companyCode']?.toString() ??
          contact['companyCode']?.toString() ??
          '';

      fromChats.add({
        "id": resolvedId,
        "name": userName,
        "companyName": companyName,
        "branchName": branchName,
        "database": database,
        "propertyCode": propertyCode,
        "_dmGroup": {"LastMessage": "", "LastMessageTime": ""},
        "_isContactOnly": true, // flag: no messages yet
      });

      existingIds.add(resolvedId.toLowerCase());
    }

    return fromChats;
  }

  String _firstDirectChatValue(Map<String, dynamic> chat, List<String> keys) {
    for (final key in keys) {
      final value = chat[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  String _directChatUserId(Map<String, dynamic> chat) {
    final summaryUserId = _firstDirectChatValue(chat, ['UserId']);
    if (summaryUserId.isNotEmpty) return summaryUserId;

    final senderId = _firstDirectChatValue(chat, ['SenderUserId']);
    final receiverId = _firstDirectChatValue(chat, ['ReceiverId']);

    if (senderId.isNotEmpty && senderId != _myId) return senderId;
    if (receiverId.isNotEmpty && receiverId != _myId) return receiverId;
    return senderId.isNotEmpty ? senderId : receiverId;
  }

  String _directChatUserName(Map<String, dynamic> chat, String fallbackId) {
    final name = _firstDirectChatValue(chat, [
      'UserName',
      'SenderName',
      'AssignedToName',
    ]);
    return name.isNotEmpty ? name : fallbackId;
  }

  List<Map<String, dynamic>> get _filteredUsers {
    List<Map<String, dynamic>> list = _chattedUsers;

    if (_selectedCompany != "ALL") {
      list = list.where((u) {
        return (u["companyName"] ?? "") == _selectedCompany;
      }).toList();
    }

    if (_isSearching) {
      final q = _searchCtrl.text.toLowerCase();

      list = list.where((u) {
        final name = (u["name"] ?? "").toString().toLowerCase();
        final last = ((u["_dmGroup"] as Map?)?["LastMessage"] ?? "")
            .toString()
            .toLowerCase();

        return name.contains(q) || last.contains(q);
      }).toList();
    }

    return list;
  }

  // ── Formatters ────────────────────────────────────────────────────

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return DateFormat('hh:mm a').format(dt);
      }
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return '';
    }
  }

  int get _totalUnread =>
      _chatMeta.values.fold(0, (sum, m) => sum + m.unreadCount);

  // ── Custom Chat Flow Actions ──────────────────────────────────────

  void _showNewChatFlow() async {
    // Build recent challan list with last message metadata to pass to NewChatScreen
    final recentChallans = challans
        .map((c) {
          final challanId = c['sp_462']?.toString() ?? '';
          final meta = _chatMeta[challanId];
          return {
            ...c,
            'lastMessage': meta?.lastMessage ?? '',
            'lastTime': meta?.lastTime ?? '',
          };
        })
        .where((c) => (c['sp_462']?.toString() ?? '').isNotEmpty)
        .toList();

    final selectedItem = await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'NewChatScreen'),
        builder: (_) =>
            NewChatScreen(allUsers: _allUsers, recentChallans: recentChallans),
      ),
    );

    if (selectedItem == null) return;

    // User picked "New Group"
    if (selectedItem == 'TRIGGER_NEW_GROUP') {
      _showNewGroupFlow();
      return;
    }

    // User picked a challan chat
    if (selectedItem is Map && selectedItem['_type'] == 'challan') {
      if (!mounted) return;
      final challanId = selectedItem['challanId']?.toString() ?? '';
      final challanNo = selectedItem['challanNo']?.toString() ?? '';
      final customerName = selectedItem['customerName']?.toString() ?? '';
      await Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'ChallanChatDialog'),
          builder: (_) => ChallanChatDialog(
            challanId: challanId,
            challanNo: challanNo,
            customerName: customerName,
          ),
        ),
      );
      _loadAll(silent: true);
      return;
    }

    // User picked a person for 1-on-1 DM
    final userId = selectedItem['id']?.toString() ?? '';
    final userName = selectedItem['name']?.toString() ?? userId;
    final companyName = selectedItem['companyName']?.toString();
    final branchName = selectedItem['branchName']?.toString();
    final targetDatabase = selectedItem['database']?.toString();

    // ── Resolve the correct short login ID ────────────────────────────────
    // _allUsers has:  id = UUID,  loginId = short login (e.g. "kishor")
    // _directChats has: UserId = short login
    // The API expects the short login ID, not the UUID.

    // Step 1: look up the loginId from _allUsers for this UUID
    String loginId = '';
    try {
      final matched = _allUsers.firstWhere(
        (u) =>
            (u['id']?.toString() ?? '').toLowerCase() == userId.toLowerCase(),
        orElse: () => {},
      );
      loginId = matched['loginId']?.toString() ?? '';
    } catch (_) {}

    // Step 2: find the existing direct chat using loginId OR UUID OR name
    Map<String, dynamic>? matchedDirectChat;
    try {
      matchedDirectChat = _directChats.cast<Map<String, dynamic>>().firstWhere((
        g,
      ) {
        final chatUserId = (g["UserId"]?.toString() ?? '').toLowerCase();
        final chatUserName = (g["UserName"]?.toString() ?? '').toLowerCase();
        return chatUserId == userId.toLowerCase() ||
            (loginId.isNotEmpty && chatUserId == loginId.toLowerCase()) ||
            chatUserName == userName.toLowerCase();
      });
    } catch (_) {
      matchedDirectChat = null;
    }

    // Step 3: prefer short loginId > existing chat UserId > original UUID
    final resolvedUserId =
        matchedDirectChat?["UserId"]?.toString() ??
        (loginId.isNotEmpty ? loginId : userId);
    final resolvedPropertyCode =
        matchedDirectChat?["PropertyCode"]?.toString() ??
        selectedItem['propertyCode']?.toString() ??
        selectedItem['companyCode']?.toString();
    final resolvedDatabase =
        matchedDirectChat?["DatabaseName"]?.toString() ?? targetDatabase;

    _openUserChat(
      resolvedUserId,
      userName,
      companyName: companyName,
      branchName: branchName,
      targetDatabase: resolvedDatabase,
      receiverPropertyCode: resolvedPropertyCode,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: [_buildAllTab(), _buildChatsTab(), _buildGroupsTab()],
            ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          // Only show FAB on Groups tab (index 2)
          if (_tabController.index != 2 || isLoading) {
            return const SizedBox.shrink();
          }
          final theme = Theme.of(context);
          return FloatingActionButton(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            tooltip: "New Group",
            onPressed: _showNewGroupFlow,
            child: const Icon(Icons.group_add_outlined),
          );
        },
      ),
    );
  }

  Widget _buildCompanyFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        return Container(
          height: isSmallScreen ? 52 : 62,
          color: Theme.of(context).colorScheme.surface,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 14,
              vertical: isSmallScreen ? 8 : 10,
            ),
            itemCount: _companies.length,
            separatorBuilder: (_, __) => SizedBox(width: isSmallScreen ? 4 : 8),
            itemBuilder: (_, index) {
              final company = _companies[index];
              final selected = company == _selectedCompany;
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final selectedBg = isDark
                  ? const Color(0xFFE8EDF5)
                  : const Color(0xFF111B21);
              final selectedText = isDark ? const Color(0xFF111B21) : Colors.white;
              final unselectedBg = theme.colorScheme.surface;
              final unselectedBorder = isDark
                  ? const Color(0xFF3A4A5A)
                  : const Color(0xFFD1D7DB);
              final unselectedText = theme.colorScheme.onSurface;

              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => setState(() => _selectedCompany = company),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 20,
                    vertical: isSmallScreen ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? selectedBg : unselectedBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? selectedBg : unselectedBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    company.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 11 : 13,
                      color: selected ? selectedText : unselectedText,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupCompanyFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        return Container(
          height: isSmallScreen ? 52 : 62,
          color: Theme.of(context).colorScheme.surface,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 14,
              vertical: isSmallScreen ? 8 : 10,
            ),
            itemCount: _groupCompanies.length,
            separatorBuilder: (_, __) => SizedBox(width: isSmallScreen ? 4 : 8),
            itemBuilder: (_, index) {
              final company = _groupCompanies[index];
              final selected = company == _selectedGroupCompany;
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final selectedBg = isDark
                  ? const Color(0xFFE8EDF5)
                  : const Color(0xFF111B21);
              final selectedText = isDark ? const Color(0xFF111B21) : Colors.white;
              final unselectedBg = theme.colorScheme.surface;
              final unselectedBorder = isDark
                  ? const Color(0xFF3A4A5A)
                  : const Color(0xFFD1D7DB);
              final unselectedText = theme.colorScheme.onSurface;

              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  setState(() {
                    _selectedGroupCompany = company;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 20,
                    vertical: isSmallScreen ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? selectedBg : unselectedBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? selectedBg : unselectedBorder,
                    ),
                  ),
                  child: Text(
                    company.toUpperCase(),
                    style: TextStyle(
                      color: selected ? selectedText : unselectedText,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 11 : 13,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final appBarBg = theme.colorScheme.surface;
    final appBarText = theme.colorScheme.onSurface;
    final appBarIcon = theme.brightness == Brightness.dark
        ? const Color(0xFF8A9BB0)
        : _appBarIcon;

    return AppBar(
      backgroundColor: appBarBg,
      elevation: 0.5,
      iconTheme: IconThemeData(color: appBarIcon),
      titleSpacing: _isSearching ? 0 : 16,
      title: _isSearching
          ? TextField(
              controller: _searchCtrl,
              focusNode: _searchFocusNode,
              style: TextStyle(color: appBarText, fontSize: 16),
              cursorColor: appBarText,
              decoration: InputDecoration(
                hintText: "Search chats…",
                hintStyle: TextStyle(
                  color: appBarIcon.withOpacity(0.6),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            )
          : GestureDetector(
              onTap: () {
                // Logo tap — no-op (always showing chat lists)
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 35,
                      width: 35,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.chat_bubble_outline,
                          color: appBarIcon,
                          size: 24,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "MyAutoShop",
                    style: TextStyle(
                      color: appBarText,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  if (_totalUnread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: appBarText.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _totalUnread > 99 ? '99+' : '$_totalUnread',
                        style: TextStyle(
                          color: appBarText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        // Search toggle
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: appBarIcon,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchCtrl.clear();
                _searchFocusNode.unfocus();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _searchFocusNode.requestFocus();
                });
              }
            });
          },
        ),

        // New Chat Button
        IconButton(
          icon: Icon(Icons.chat_outlined, color: appBarIcon),
          tooltip: "New Chat",
          onPressed: _showNewChatFlow,
        ),

        // Three-dot menu
        if (!_isSearching)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: appBarIcon),
            tooltip: "Menu",
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onSelected: (v) {
              switch (v) {
                case 'newGroup':
                  _showNewGroupFlow();
                case 'refresh':
                  _loadAll();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'newGroup',
                child: _MenuRow(
                  icon: Icons.group_add_outlined,
                  label: 'New Group',
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'refresh',
                child: _MenuRow(icon: Icons.refresh, label: 'Refresh'),
              ),
            ],
          ),
      ],
      // ── Tab bar ──────────────────────────────────────────────────
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;
            return TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelColor: appBarText,
              unselectedLabelColor: appBarIcon,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 10 : 14,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 10 : 14,
              ),
              tabs: [
                // ── ALL tab ──────────────────────────────────────────────
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isSmallScreen) Icon(Icons.forum_outlined, size: 18),
                      if (!isSmallScreen) const SizedBox(width: 6),
                      const Text("All"),
                      if (!isSmallScreen && (_chattedUsers.isNotEmpty || _filteredGroups.isNotEmpty)) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_chattedUsers.length + _filteredGroups.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ── CHATS tab ─────────────────────────────────────────────
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isSmallScreen) Icon(Icons.person_outline, size: 18),
                      if (!isSmallScreen) const SizedBox(width: 6),
                      const Text("Chats"),
                      if (!isSmallScreen && _chattedUsers.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (_chattedUsers.length) > 99
                                ? '99+'
                                : '${_chattedUsers.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ── GROUPS tab ────────────────────────────────────────────
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isSmallScreen) Icon(Icons.groups_outlined, size: 18),
                      if (!isSmallScreen) const SizedBox(width: 6),
                      const Text("Groups"),
                      if (!isSmallScreen && _filteredGroups.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_filteredGroups.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── All Companies filter (union of chat + group companies, deduplicated) ──

  /// Builds a map of databaseName (lowercase, no spaces) → CompanyName display label.
  /// e.g. "rajademo" → "RAJA DEMO", "tatademo" → "TATA DEMO"
  Map<String, String> get _dbToCompanyName {
    final map = <String, String>{};
    for (final u in _directChats) {
      final companyName = (u["CompanyName"] ?? "").toString().trim();
      final dbName = (u["DatabaseName"] ?? "").toString().trim().toLowerCase();
      if (companyName.isNotEmpty && dbName.isNotEmpty) {
        map[dbName] = companyName;
        // Also map with spaces removed, for loose matching
        map[dbName.replaceAll(' ', '')] = companyName;
      }
    }
    return map;
  }

  /// Resolves a group's company label using the dbToCompanyName map.
  String _groupCompanyLabel(dynamic g) {
    final companyName = (g["CompanyName"] ?? "").toString().trim();
    if (companyName.isNotEmpty) return companyName;
    final dbName = (g["DatabaseName"] ?? "").toString().trim();
    if (dbName.isEmpty) return '';
    // Try exact match first, then lowercase
    final map = _dbToCompanyName;
    return map[dbName] ?? map[dbName.toLowerCase()] ?? dbName;
  }

  List<String> get _allCompanies {
    final companies = <String>{};
    // From direct chats
    for (final u in _directChats) {
      final c = (u["CompanyName"] ?? "").toString().trim();
      if (c.isNotEmpty) companies.add(c);
    }
    // From groups — resolve DatabaseName → CompanyName display label
    for (final g in _groups) {
      final name = (g["GroupName"]?.toString() ?? "");
      if (name.startsWith("DM:")) continue;
      final label = _groupCompanyLabel(g);
      if (label.isNotEmpty) companies.add(label);
    }
    final sorted = companies.toList()..sort();
    return ["ALL", ...sorted];
  }

  Widget _buildAllCompanyFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        return Container(
          height: isSmallScreen ? 52 : 62,
          color: Theme.of(context).colorScheme.surface,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 14,
              vertical: isSmallScreen ? 8 : 10,
            ),
            itemCount: _allCompanies.length,
            separatorBuilder: (_, __) => SizedBox(width: isSmallScreen ? 4 : 8),
            itemBuilder: (_, index) {
              final company = _allCompanies[index];
              final selected = company == _selectedAllCompany;
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final selectedBg = isDark
                  ? const Color(0xFFE8EDF5)
                  : const Color(0xFF111B21);
              final selectedText = isDark ? const Color(0xFF111B21) : Colors.white;
              final unselectedBg = theme.colorScheme.surface;
              final unselectedBorder = isDark
                  ? const Color(0xFF3A4A5A)
                  : const Color(0xFFD1D7DB);
              final unselectedText = theme.colorScheme.onSurface;

              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => setState(() => _selectedAllCompany = company),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 20,
                    vertical: isSmallScreen ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? selectedBg : unselectedBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? selectedBg : unselectedBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    company.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 11 : 13,
                      color: selected ? selectedText : unselectedText,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── All Tab — combined chats + groups sorted by last activity ──────────────

  Widget _buildAllTab() {
    // Build unified list of items
    final List<_UnifiedChatItem> items = [];

    // Add direct chats (filtered by company)
    List<Map<String, dynamic>> users = _chattedUsers;
    if (_selectedAllCompany != "ALL") {
      users = users
          .where(
            (u) =>
                (u["companyName"] ?? "") == _selectedAllCompany ||
                (u["database"] ?? "") == _selectedAllCompany,
          )
          .toList();
    }
    if (_isSearching) {
      final q = _searchCtrl.text.toLowerCase();
      users = users.where((u) {
        final name = (u["name"] ?? "").toString().toLowerCase();
        final last = ((u["_dmGroup"] as Map?)?["LastMessage"] ?? "")
            .toString()
            .toLowerCase();
        return name.contains(q) || last.contains(q);
      }).toList();
    }
    for (final user in users) {
      final dmGroup = user['_dmGroup'] as Map?;
      final lastTime = dmGroup?['LastMessageTime']?.toString() ?? '';
      items.add(
        _UnifiedChatItem(
          type: _ChatItemType.user,
          user: user,
          lastTime: lastTime,
          isGroup: false,
        ),
      );
    }

    // Add groups (filtered by company, excluding DM groups)
    List<dynamic> grps = _groups.where((g) {
      final name = g["GroupName"]?.toString() ?? "";
      return !name.startsWith("DM:");
    }).toList();
    if (_selectedAllCompany != "ALL") {
      grps = grps.where((g) {
        return _groupCompanyLabel(g) == _selectedAllCompany;
      }).toList();
    }
    if (_isSearching) {
      final q = _searchCtrl.text.toLowerCase();
      grps = grps
          .where(
            (g) => (g["GroupName"] ?? "").toString().toLowerCase().contains(q),
          )
          .toList();
    }
    for (final group in grps) {
      final lastMsgTime = group['LastMessageTime']?.toString() ?? '';
      items.add(
        _UnifiedChatItem(
          type: _ChatItemType.user,
          group: group,
          lastTime: lastMsgTime,
          isGroup: true,
        ),
      );
    }

    // Sort by last activity time descending (most recent first)
    items.sort((a, b) {
      if (a.lastTime.isEmpty && b.lastTime.isEmpty) return 0;
      if (a.lastTime.isEmpty) return 1;
      if (b.lastTime.isEmpty) return -1;
      try {
        return DateTime.parse(b.lastTime).compareTo(DateTime.parse(a.lastTime));
      } catch (_) {
        return 0;
      }
    });

    if (items.isEmpty) {
      return Column(
        children: [
          _buildAllCompanyFilters(),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No conversations yet",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Start a chat or create a group",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildAllCompanyFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadAll(),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) {
                final item = items[index];
                if (item.isGroup) {
                  return _buildGroupTile(item.group!);
                } else {
                  return _buildUserTile(item.user!);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Chats Tab ─────────────────────────────────────────────────────

  Widget _buildChatsTab() {
    final List<_UnifiedChatItem> items = [];

    // ONLY Direct Chats
    for (final user in _filteredUsers) {
      final dmGroup = user['_dmGroup'] as Map?;
      final lastTime = dmGroup?['LastMessageTime']?.toString() ?? '';

      items.add(
        _UnifiedChatItem(
          type: _ChatItemType.user,
          user: user,
          lastTime: lastTime,
        ),
      );
    }

    items.sort((a, b) {
      if (a.lastTime.isEmpty && b.lastTime.isEmpty) return 0;
      if (a.lastTime.isEmpty) return 1;
      if (b.lastTime.isEmpty) return -1;
      try {
        return DateTime.parse(b.lastTime).compareTo(DateTime.parse(a.lastTime));
      } catch (_) {
        return 0;
      }
    });

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Start a conversation from the contacts list',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildCompanyFilters(),

        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, index) => _buildUserTile(items[index].user!),
          ),
        ),
      ],
    );
  }
  // ── Groups Tab ────────────────────────────────────────────────────

  Widget _buildGroupsTab() {
    final grps = _filteredGroups;

    if (grps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? "No groups found" : "No groups yet",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            if (!_isSearching) ...[
              const Text(
                "Create a group to chat with multiple people",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111B21),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text(
                  "Create New Group",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onPressed: _showNewGroupFlow,
              ),
            ] else
              const Text(
                "Try a different search term",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildGroupCompanyFilters(),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadAll(),
            child: ListView.builder(
              itemCount: grps.length,
              itemBuilder: (_, i) => _buildGroupTile(grps[i]),
            ),
          ),
        ),
      ],
    );
  }

  // unused cast suppressed below

  // ── Individual chat tile ──────────────────────────────────────────

  Widget _buildIndividualTile(Map<String, dynamic> challan) {
    final challanId = challan['sp_462']?.toString() ?? '';
    final challanNo = challan['sp_468']?.toString() ?? 'N/A';
    final customerName = challan['sp_469']?.toString() ?? '';

    final meta = _chatMeta[challanId];
    final lastMessage = meta?.lastMessage ?? '';
    final unreadCount = meta?.unreadCount ?? 0;
    final timeLabel = _formatTime(meta?.lastTime);

    final avatarLetter = customerName.isNotEmpty
        ? customerName[0].toUpperCase()
        : 'C';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openChat(challan),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _avatarColor(
                    customerName.isNotEmpty ? customerName : challanNo,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customerName.isNotEmpty
                                ? customerName
                                : "Challan #$challanNo",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (timeLabel.isNotEmpty)
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: unreadCount > 0
                                  ? const Color(0xFF111B21)
                                  : Colors.grey,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage.isNotEmpty
                                ? lastMessage
                                : "Challan #$challanNo",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: unreadCount > 0
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.grey,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111B21),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Group tile ────────────────────────────────────────────────────

  Widget _buildGroupTile(dynamic group) {
    final groupName = group['GroupName']?.toString() ?? 'Group';
    final memberCount = (group['MemberCount'] as num?)?.toInt() ?? 0;
    final lastMsgTime = group['LastMessageTime']?.toString() ?? '';
    final lastMessage = group['LastMessage']?.toString() ?? '';
    final avatarLetter = groupName.isNotEmpty
        ? groupName[0].toUpperCase()
        : 'G';
    final timeLabel = _formatTime(lastMsgTime.isNotEmpty ? lastMsgTime : null);

    // Look up branchName from _allUsers by matching the group's DatabaseName
    String branchName = '';
    final groupDatabase = (group['DatabaseName']?.toString() ?? '')
        .toLowerCase();
    if (groupDatabase.isNotEmpty) {
      try {
        final matched = _allUsers.firstWhere(
          (u) =>
              (u['database']?.toString() ?? '').toLowerCase() == groupDatabase,
          orElse: () => {},
        );
        branchName = (matched['branchName']?.toString() ?? '').trim();
      } catch (_) {}
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openGroup(group),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              // Avatar with group indicator
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _avatarColor(groupName),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        avatarLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.people,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            groupName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (timeLabel.isNotEmpty)
                          Text(
                            timeLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (branchName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          branchName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF54656F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage.isNotEmpty
                                ? lastMessage
                                : "$memberCount member${memberCount == 1 ? '' : 's'}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Users Tab ─────────────────────────────────────────────────────
  // (Users are now shown inside the Chats tab as a section)

  Widget _buildUserTile(Map<String, dynamic> user) {
    final userId = user['id']?.toString() ?? '';
    final userName = user['name']?.toString() ?? userId;
    final avatarLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final companyName = user['companyName']?.toString() ?? '';
    final branchName = user['branchName']?.toString() ?? '';
    debugPrint(
      "Rendering user: $userName | companyName='$companyName' | branchName='$branchName'",
    );

    // Build subtitle: "COMPANY • BRANCH" or just "COMPANY"
    final subtitle = companyName.isNotEmpty
        ? (branchName.isNotEmpty ? "$companyName • $branchName" : companyName)
        : branchName;

    // Extract DM group metadata merged in _chattedUsers getter
    final dmGroup = user['_dmGroup'] as Map?;
    final lastMessage = dmGroup?['LastMessage']?.toString() ?? '';
    final lastMsgTime = dmGroup?['LastMessageTime']?.toString() ?? '';
    final timeLabel = _formatTime(lastMsgTime.isNotEmpty ? lastMsgTime : null);
    final isContactOnly = user['_isContactOnly'] == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openUserChat(
          userId,
          userName,
          companyName: companyName.isNotEmpty ? companyName : null,
          branchName: branchName.isNotEmpty ? branchName : null,
          targetDatabase: user['database']?.toString(),
          receiverPropertyCode: user['propertyCode']?.toString(),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _avatarColor(userName),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name + company • branch + last message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName.isNotEmpty ? userName : userId,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: lastMessage.isNotEmpty
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeLabel.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            timeLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF54656F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (lastMessage.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ] else if (isContactOnly) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'Say Hello 👋',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF54656F),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text(
            "Failed to load chats",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}

// ── Simple holder for per-challan chat metadata ───────────────────────────────

// ── Unified chat item type ────────────────────────────────────────────────────

enum _ChatItemType { challan, user }

class _UnifiedChatItem {
  final _ChatItemType type;
  final Map<String, dynamic>? challan;
  final Map<String, dynamic>? user;
  final dynamic group;
  final String lastTime;
  final bool isGroup;

  const _UnifiedChatItem({
    required this.type,
    this.challan,
    this.user,
    this.group,
    required this.lastTime,
    this.isGroup = false,
  });
}

class _ChatMeta {
  final String lastMessage;
  final String lastTime;
  final int unreadCount;

  const _ChatMeta({
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
  });
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
    final color = danger ? Colors.red : Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}

// ── Step 1: Pick Members Dialog ──────────────────────────────────────────────

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
      title: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.group_add_outlined,
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF8A9BB0)
                      : const Color(0xFF54656F),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Add Group Members",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_selected.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${_selected.length} selected",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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
                        final companyName =
                            user['companyName']?.toString() ?? '';
                        final branchName = user['branchName']?.toString() ?? '';
                        final isSelected = _selected.contains(userId);

                        return CheckboxListTile(
                          key: ValueKey(userId),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          activeColor: const Color(0xFF111B21),
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
                                ? const Color(0xFF111B21)
                                : _avatarColor(userName),
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
                          subtitle: Text(
                            [
                              if (companyName.isNotEmpty) companyName,
                              if (branchName.isNotEmpty) branchName,
                            ].join(" • "),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
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
            backgroundColor: const Color(0xFF111B21),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _selected.isEmpty
              ? null
              : () {
                  // Return full user objects so callers can access the 'database' field
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
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.group, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              "Name Your Group",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
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
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

// ignore_for_file: deprecated_member_use
