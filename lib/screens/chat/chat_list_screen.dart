import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'challan_chat_dialog.dart';
import 'direct_chat_screen.dart';
import 'group_chat_screen.dart';
import 'new_chat_screen.dart';

// ── WhatsApp-style colour palette ─────────────────────────────────────────────
const Color _kAppBarBg    = Colors.white;
const Color _kAppBarText  = Color(0xFF111B21);
const Color _kAppBarIcon  = Color(0xFF54656F);

// WhatsApp-style avatar palette — picks a consistent color from the name
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

  // ── Tabs ─────────────────────────────────────────────────────────
  late TabController _tabController;

  // ── Data ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> challans = [];
  final Map<String, _ChatMeta> _chatMeta = {};

  List<dynamic> _groups = [];
  List<dynamic> _directChats = [];

  // ── Users ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _allUsers = [];

  bool isLoading = true;
  String? errorMessage;

  // ── Search ───────────────────────────────────────────────────────
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ── Polling ──────────────────────────────────────────────────────
  Timer? _pollTimer;

  static const Color _appBarBg   = _kAppBarBg;
  static const Color _appBarText = _kAppBarText;
  static const Color _appBarIcon = _kAppBarIcon;

  String _myId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  // ── Load ─────────────────────────────────────────────────────────

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }
    for (final chat in _directChats) {
      debugPrint(chat.toString());
    }
    try {
      final results = await Future.wait([
        ApiService.getChallanRetailIncentive(),
        ApiService.getMyDirectChats(allChats: true), // NEW
        ApiService.getMyGroups(), // Existi
        ApiService.getMergedUsers(),
        ApiService.getUserId(),
      ]);

      final challanList = results[0] as List<Map<String, dynamic>>;
      final directChats = results[1] as List<dynamic>;
      debugPrint("===== DIRECT CHATS =====");
      for (final chat in directChats) {
        debugPrint(chat.toString());
      }
      debugPrint("========================");
      final groupList = results[2] as List<dynamic>;
      final userList = results[3] as List<Map<String, dynamic>>;
      final myUserId = results[4] as String? ?? '';

      if (mounted) {
        print("hello");
        setState(() {
          challans = challanList;
          _directChats = directChats;
          print(_directChats);
          _groups = groupList;
          _allUsers = userList;
          _myId = myUserId;
          isLoading = false;
        });
      }

      // Load per-challan meta in background
      _loadAllChatMeta(challanList);
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'GroupChatScreen'),
        builder: (_) => GroupChatScreen(
          groupId: groupId,
          groupName: groupName,
          groupDatabase: groupDatabase,
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
    String? targetDatabase, // the DB where the target user belongs
    String? receiverPropertyCode,
  }) async {
    if (targetUserId.isEmpty) return;

    Map<String, dynamic>? existingChat;
    try {
      existingChat = _directChats.cast<Map<String, dynamic>>().firstWhere(
        (g) => (g["UserId"]?.toString() ?? "") == targetUserId,
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
    // Exclude DM (direct message) groups from the Groups tab
    final nonDm = _groups.where((g) {
      final name = g['GroupName']?.toString() ?? '';
      return !name.startsWith('DM:');
    }).toList();
    if (!_isSearching) return nonDm;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return nonDm;
    return nonDm.where((g) {
      final name = (g['GroupName']?.toString() ?? '').toLowerCase();
      return name.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _chattedUsers {
    return _directChats.map<Map<String, dynamic>>((chat) {
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

      debugPrint(
        "User: $userName | CompanyName: '$companyName' | "
        "PropertyCode: ${directChat["PropertyCode"]} | "
        "DatabaseName: ${directChat["DatabaseName"]}",
      );

      return {
        "id": userId,
        "name": userName,
        "companyName": companyName,
        "database": directChat["DatabaseName"] ?? "",
        "propertyCode": directChat["PropertyCode"] ?? "",
        "_dmGroup": {
          ...directChat,
          "LastMessage": lastMessage,
          "LastMessageTime": lastMessageTime,
        },
      };
    }).toList();
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
    final targetDatabase = selectedItem['database']?.toString();

    // The id from _allUsers may be a UUID while _directChats stores the short
    // login UserId. Try to find the matching existing chat by UserName so we
    // can pass the correct UserId and PropertyCode to DirectChatScreen.
    Map<String, dynamic>? matchedDirectChat;
    try {
      matchedDirectChat = _directChats.cast<Map<String, dynamic>>().firstWhere(
        (g) =>
            (g["UserId"]?.toString() ?? '').toLowerCase() ==
                userId.toLowerCase() ||
            (g["UserName"]?.toString() ?? '').toLowerCase() ==
                userName.toLowerCase(),
      );
    } catch (_) {
      matchedDirectChat = null;
    }

    // Prefer the short userId and propertyCode from the existing direct chat.
    // Fall back to the propertyCode / companyCode embedded in the user map
    // (populated by getMergedUsers) so cross-company detection always works,
    // even when there is no existing chat history yet.
    final resolvedUserId = matchedDirectChat?["UserId"]?.toString() ?? userId;
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
      targetDatabase: resolvedDatabase,
      receiverPropertyCode: resolvedPropertyCode,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: [_buildChatsTab(), _buildGroupsTab()],
            ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          // Only show FAB on Groups tab (index 1)
          if (_tabController.index != 1 || isLoading) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            backgroundColor: const Color(0xFF111B21),
            foregroundColor: Colors.white,
            tooltip: "New Group",
            onPressed: _showNewGroupFlow,
            child: const Icon(Icons.group_add_outlined),
          );
        },
      ),
    );
  }

  Widget _buildCompanyFilters() {
    return Container(
      height: 62,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: _companies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final company = _companies[index];
          final selected = company == _selectedCompany;

          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => setState(() => _selectedCompany = company),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF111B21) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? const Color(0xFF111B21) : const Color(0xFFD1D7DB),
                  width: 1.2,
                ),
              ),
              child: Text(
                company.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? Colors.white : const Color(0xFF111B21),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _appBarBg,
      elevation: 0.5,
      iconTheme: IconThemeData(color: _appBarIcon),
      titleSpacing: _isSearching ? 0 : 16,
      title: _isSearching
          ? TextField(
              controller: _searchCtrl,
              focusNode: _searchFocusNode,
              style: TextStyle(color: _appBarText, fontSize: 16),
              cursorColor: const Color(0xFF111B21),
              decoration: InputDecoration(
                hintText: "Search chats…",
                hintStyle: TextStyle(
                  color: _appBarIcon.withOpacity(0.6),
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
                          color: _appBarIcon,
                          size: 24,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "MyAutoShop",
                    style: TextStyle(
                      color: _appBarText,
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
                        color: const Color(0xFF111B21),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _totalUnread > 99 ? '99+' : '$_totalUnread',
                        style: const TextStyle(
                          color: Colors.white,
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
            color: _appBarIcon,
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
          icon: Icon(Icons.chat_outlined, color: _appBarIcon),
          tooltip: "New Chat",
          onPressed: _showNewChatFlow,
        ),

        // Three-dot menu
        if (!_isSearching)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _appBarIcon),
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
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF111B21),
        indicatorWeight: 3,
        labelColor: const Color(0xFF111B21),
        unselectedLabelColor: _appBarIcon,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 6),
                const Text("Chats"),
                if (_chattedUsers.isNotEmpty || challans.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111B21).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (_chattedUsers.length) > 99
                          ? '99+'
                          : '${_chattedUsers.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111B21),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups_outlined, size: 18),
                const SizedBox(width: 6),
                const Text("Groups"),
                if (_filteredGroups.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111B21).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_filteredGroups.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111B21),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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

      return DateTime.parse(b.lastTime).compareTo(DateTime.parse(a.lastTime));
    });

    if (items.isEmpty) {
      return const Center(child: Text("No Direct Chats"));
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

    return RefreshIndicator(
      onRefresh: () => _loadAll(),
      color: const Color(0xFF111B21),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: grps.length,
        itemBuilder: (context, index) => _buildGroupTile(grps[index]),
      ),
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
      color: Colors.white,
      child: InkWell(
        onTap: () => _openChat(challan),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _avatarColor(customerName.isNotEmpty ? customerName : challanNo),
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
                              color: const Color(0xFF1A1A1A),
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
                              color: unreadCount > 0 ? const Color(0xFF111B21) : Colors.grey,
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

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openGroup(group),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
          ),
          child: Row(
            children: [
              // Avatar
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
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
    debugPrint("Rendering user: $userName | companyName='$companyName'");
    // Extract DM group metadata merged in _chattedUsers getter
    final dmGroup = user['_dmGroup'] as Map?;
    final lastMessage = dmGroup?['LastMessage']?.toString() ?? '';
    final lastMsgTime = dmGroup?['LastMessageTime']?.toString() ?? '';
    final timeLabel = _formatTime(lastMsgTime.isNotEmpty ? lastMsgTime : null);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openUserChat(
          userId,
          userName,
          companyName: companyName.isNotEmpty ? companyName : null,
          targetDatabase: user['database']?.toString(),
          receiverPropertyCode: user['propertyCode']?.toString(),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
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

              // Name + company + last message
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
                              color: const Color(0xFF1A1A1A),
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
                    if (companyName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          companyName,
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
  final String lastTime;

  const _UnifiedChatItem({
    required this.type,
    this.challan,
    this.user,
    required this.lastTime,
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
      title: Container(
        decoration: BoxDecoration(
          color: _kAppBarBg,
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.group_add_outlined, color: Color(0xFF54656F), size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Add Group Members",
                style: TextStyle(
                  color: _kAppBarText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF111B21).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_selected.length} selected",
                  style: const TextStyle(color: Color(0xFF111B21), fontSize: 12, fontWeight: FontWeight.w600),
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
        child: const Row(
          children: [
            Icon(Icons.group, color: const Color(0xFF54656F), size: 20),
            SizedBox(width: 10),
            Text(
              "Name Your Group",
              style: TextStyle(
                color: _kAppBarText,
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
            backgroundColor: const Color(0xFF111B21),
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

// ignore_for_file: deprecated_member_use
