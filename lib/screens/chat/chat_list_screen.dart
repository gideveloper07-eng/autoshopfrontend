import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'challan_chat_dialog.dart';
import 'direct_chat_screen.dart';
import 'group_chat_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  // ── Tabs ─────────────────────────────────────────────────────────
  late TabController _tabController;

  // ── Data ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> challans = [];
  final Map<String, _ChatMeta> _chatMeta = {};

  List<dynamic> _groups = [];

  // ── Users ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _allUsers = [];

  bool isLoading = true;
  String? errorMessage;

  // ── Search ───────────────────────────────────────────────────────
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Polling ──────────────────────────────────────────────────────
  Timer? _pollTimer;

  static const Color _green = Color(0xFF075E54);

  // ── Chat Customizations ──────────────────────────────────────────
  bool _showLists = false;
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    super.dispose();
  }

  // ── Load ─────────────────────────────────────────────────────────

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }
    try {
      final results = await Future.wait([
        ApiService.getChallanRetailIncentive(),
        ApiService.getMyGroups(),
        ApiService.getMergedUsers(),
        ApiService.getUserId(),
      ]);

      final challanList = results[0] as List<Map<String, dynamic>>;
      final groupList = results[1] as List<dynamic>;
      final userList = results[2] as List<Map<String, dynamic>>;
      final myUserId = results[3] as String? ?? '';

      if (mounted) {
        setState(() {
          challans = challanList;
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

  Future<void> _loadAllChatMeta(List<Map<String, dynamic>> list) async {
    await Future.wait(
      list.map((challan) async {
        final challanId = challan['sp_462']?.toString() ?? '';
        if (challanId.isEmpty) return;

        final results = await Future.wait([
          ApiService.getChatMessages(challanId),
          ApiService.getUnreadChatCount(challanId),
        ]);

        final messages = results[0] as List<dynamic>;
        final unread = results[1] as int;

        String lastMsg = '';
        String lastTime = '';
        if (messages.isNotEmpty) {
          final last = messages.last;
          lastMsg = last['MessageText']?.toString() ?? '';
          if ((last['MessageType']?.toString() ?? 'TEXT') == 'DOCUMENT') {
            lastMsg =
                '📄 ${last['DocumentType'] ?? ''} #${last['DocumentNo'] ?? ''}';
          }
          lastTime = last['MessageTime']?.toString() ?? '';
        }

        if (mounted) {
          setState(() {
            _chatMeta[challanId] = _ChatMeta(
              lastMessage: lastMsg,
              lastTime: lastTime,
              unreadCount: unread,
            );
          });
        }
      }),
    );
  }

  Future<void> _refreshSingleMeta(String challanId) async {
    final results = await Future.wait([
      ApiService.getChatMessages(challanId),
      ApiService.getUnreadChatCount(challanId),
    ]);

    final messages = results[0] as List<dynamic>;
    final unread = results[1] as int;

    String lastMsg = '';
    String lastTime = '';
    if (messages.isNotEmpty) {
      final last = messages.last;
      lastMsg = last['MessageText']?.toString() ?? '';
      if ((last['MessageType']?.toString() ?? 'TEXT') == 'DOCUMENT') {
        lastMsg =
            '📄 ${last['DocumentType'] ?? ''} #${last['DocumentNo'] ?? ''}';
      }
      lastTime = last['MessageTime']?.toString() ?? '';
    }

    if (mounted) {
      setState(() {
        _chatMeta[challanId] = _ChatMeta(
          lastMessage: lastMsg,
          lastTime: lastTime,
          unreadCount: unread,
        );
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

    if (mounted) setState(() => _showLists = true);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallanChatDialog(
          challanId: challanId,
          challanNo: challanNo,
          customerName: challan['sp_469']?.toString() ?? '',
        ),
      ),
    );

    _refreshSingleMeta(challanId);
  }

  void _openGroup(dynamic group) async {
    final groupId = group['GroupId']?.toString() ?? '';
    final groupName = group['GroupName']?.toString() ?? 'Group';
    if (mounted) setState(() => _showLists = true);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupChatScreen(groupId: groupId, groupName: groupName),
      ),
    );
    _loadAll(silent: true);
  }

  /// Open a 1-on-1 chat with a user.
  /// Finds an existing direct-message group or creates one, then opens it.
  void _openUserChat(String targetUserId, String targetUserName, {String? companyName}) async {
    if (targetUserId.isEmpty) return;

    // Always show the lists when opening a chat so the back button returns to
    // the chat list instead of the welcome screen.
    if (mounted) setState(() => _showLists = true);
    final myId = _myId.isNotEmpty ? _myId : (await ApiService.getUserId() ?? '');

    if (!mounted) return;

    // Look for an existing 1-on-1 group with this user in the already-loaded list.
    // DM group name pattern: "DM:userId1:userId2" (case-insensitive comparison)
    dynamic existingGroup;
    for (final g in _groups) {
      final name = g['GroupName']?.toString() ?? '';
      final memberCount = (g['MemberCount'] as num?)?.toInt() ?? 0;
      if (memberCount == 2 && name.startsWith('DM:')) {
        final parts = name.split(':');
        if (parts.length == 3) {
          final id1 = parts[1].toLowerCase();
          final id2 = parts[2].toLowerCase();
          final myLow = myId.toLowerCase();
          final targetLow = targetUserId.toLowerCase();
          if ((id1 == myLow && id2 == targetLow) ||
              (id1 == targetLow && id2 == myLow)) {
            existingGroup = g;
            break;
          }
        }
      }
    }

    if (existingGroup != null) {
      final groupId = existingGroup['GroupId']?.toString() ?? '';
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DirectChatScreen(
              groupId: groupId,
              userName: targetUserName,
              companyName: companyName),
        ),
      );
      _loadAll(silent: true);
      return;
    }

    // No existing DM group — create one silently
    final dmName = 'DM:$myId:$targetUserId';
    final result = await ApiService.createGroup(
      groupName: dmName,
      memberIds: [targetUserId],
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final groupId = result['groupId']?.toString() ?? '';
      await _loadAll(silent: true);
      if (groupId.isNotEmpty && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DirectChatScreen(
                groupId: groupId,
                userName: targetUserName,
                companyName: companyName),
          ),
        );
        _loadAll(silent: true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Could not open chat. Please try again.'),
        ),
      );
    }
  }

  /// New Group flow — Step 1 pick members, Step 2 name
  void _showNewGroupFlow() async {
    final allUsers = await ApiService.getCompanyUsers();
    if (!mounted) return;

    final pickedIds = await showDialog<List<String>>(
      context: context,
      builder: (_) => _PickMembersDialog(allUsers: allUsers),
    );
    if (pickedIds == null || pickedIds.isEmpty) return;
    if (!mounted) return;

    final groupName = await showDialog<String>(
      context: context,
      builder: (_) => const _NameGroupDialog(),
    );
    if (groupName == null || groupName.trim().isEmpty) return;

    final result = await ApiService.createGroup(
      groupName: groupName.trim(),
      memberIds: pickedIds,
    );

    if (!mounted) return;
    if (result['success'] == true) {
      final groupId = result['groupId']?.toString() ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _green,
          content: Text('Group "$groupName" created!'),
        ),
      );
      await _loadAll(silent: true);
      if (groupId.isNotEmpty && mounted) {
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
    if (_myId.isEmpty) return [];

    // Build a map of targetUserId -> DM group data for quick lookup
    final Map<String, Map<String, dynamic>> dmGroupByTargetId = {};
    for (final g in _groups) {
      final name = g['GroupName']?.toString() ?? '';
      if (name.startsWith('DM:')) {
        final parts = name.split(':');
        if (parts.length == 3) {
          // parts[1] and parts[2] are the two user IDs
          final id1 = parts[1];
          final id2 = parts[2];
          final targetId = id1 == _myId ? id2 : id1;
          if (targetId.isNotEmpty) {
            // Keep the group data so we can show last message in tile
            dmGroupByTargetId[targetId] = Map<String, dynamic>.from(g);
          }
        }
      }
    }

    if (dmGroupByTargetId.isEmpty) return [];

    // Build the user list with merged DM group meta (for last message display)
    final List<Map<String, dynamic>> result = [];
    for (final u in _allUsers) {
      final id = u['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      if (dmGroupByTargetId.containsKey(id)) {
        final merged = Map<String, dynamic>.from(u);
        merged['_dmGroup'] = dmGroupByTargetId[id];
        // companyName is already in u if it came from getMergedUsers
        result.add(merged);
      }
    }

    // Sort by LastMessageTime descending (most recent first)
    result.sort((a, b) {
      final timeA =
          (a['_dmGroup'] as Map?)?['LastMessageTime']?.toString() ?? '';
      final timeB =
          (b['_dmGroup'] as Map?)?['LastMessageTime']?.toString() ?? '';
      if (timeA.isEmpty && timeB.isEmpty) return 0;
      if (timeA.isEmpty) return 1;
      if (timeB.isEmpty) return -1;
      try {
        return DateTime.parse(timeB).compareTo(DateTime.parse(timeA));
      } catch (_) {
        return 0;
      }
    });

    return result;
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final list = _chattedUsers;
    if (!_isSearching) return list;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((u) {
      final name = (u['name']?.toString() ?? '').toLowerCase();
      final id = (u['id']?.toString() ?? '').toLowerCase();
      final lastMsg =
          ((u['_dmGroup'] as Map?)?['LastMessage']?.toString() ?? '')
              .toLowerCase();
      return name.contains(q) || id.contains(q) || lastMsg.contains(q);
    }).toList();
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
    final recentChallans = challans.map((c) {
      final challanId = c['sp_462']?.toString() ?? '';
      final meta = _chatMeta[challanId];
      return {
        ...c,
        'lastMessage': meta?.lastMessage ?? '',
        'lastTime': meta?.lastTime ?? '',
      };
    }).where((c) => (c['sp_462']?.toString() ?? '').isNotEmpty).toList();

    final selectedItem = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewChatScreen(
          allUsers: _allUsers,
          recentChallans: recentChallans,
        ),
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
      setState(() => _showLists = true);
      final challanId = selectedItem['challanId']?.toString() ?? '';
      final challanNo = selectedItem['challanNo']?.toString() ?? '';
      final customerName = selectedItem['customerName']?.toString() ?? '';
      await Navigator.push(
        context,
        MaterialPageRoute(
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

    // Show the lists/tabs immediately so the Chats tab is visible after return
    if (mounted) {
      setState(() {
        _showLists = true;
      });
    }

    _openUserChat(userId, userName, companyName: companyName);
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
              : !_showLists
                  ? _buildWelcomeWidget()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildChatsTab(),
                        _buildGroupsTab(),
                      ],
                    ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          // Only show FAB on Groups tab (index 1) and when lists are shown
          if (!_showLists || _tabController.index != 1 || isLoading) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            tooltip: "New Group",
            onPressed: _showNewGroupFlow,
            child: const Icon(Icons.group_add_outlined),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeWidget() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _green.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/logo.png',
                  height: 90,
                  width: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 80,
                      color: _green,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Welcome to MyAutoShop Chat",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Tap the logo on the top-left to view your chats or click the button below to start a new chat.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 2,
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text(
                "Start a Chat",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: _showNewChatFlow,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _green,
      iconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: _isSearching ? 0 : 16,
      title: _isSearching
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: "Search chats…",
                hintStyle:
                    TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (_) => setState(() {}),
            )
          : GestureDetector(
              onTap: () {
                setState(() {
                  _showLists = !_showLists;
                });
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
                        return const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "MyAutoShop",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (_totalUnread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
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
          icon: Icon(_isSearching ? Icons.close : Icons.search,
              color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchCtrl.clear();
            });
          },
        ),

        // New Chat Button
        IconButton(
          icon: const Icon(Icons.chat_outlined, color: Colors.white),
          tooltip: "New Chat",
          onPressed: _showNewChatFlow,
        ),

        // Three-dot menu
        if (!_isSearching)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            tooltip: "Menu",
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    icon: Icons.group_add_outlined, label: 'New Group'),
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
      bottom: _showLists
          ? TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.4,
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
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (_chattedUsers.length + challans.length) > 99
                                ? '99+'
                                : '${_chattedUsers.length + challans.length}',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
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
                      if (_groups.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_groups.length}',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }

  // ── Chats Tab ─────────────────────────────────────────────────────

  Widget _buildChatsTab() {
    // Build a unified list: challan chats + DM user chats, sorted by most recent
    final List<_UnifiedChatItem> items = [];

    // Add challan chats that have at least one message
    for (final challan in _filteredChallans) {
      final challanId = challan['sp_462']?.toString() ?? '';
      if (challanId.isEmpty) continue;
      final meta = _chatMeta[challanId];
      final lastTime = meta?.lastTime ?? '';
      items.add(_UnifiedChatItem(
        type: _ChatItemType.challan,
        challan: challan,
        lastTime: lastTime,
      ));
    }

    // Add DM user chats
    for (final user in _filteredUsers) {
      final dmGroup = user['_dmGroup'] as Map?;
      final lastTime = dmGroup?['LastMessageTime']?.toString() ?? '';
      items.add(_UnifiedChatItem(
        type: _ChatItemType.user,
        user: user,
        lastTime: lastTime,
      ));
    }

    // Sort by last message time descending
    items.sort((a, b) {
      if (a.lastTime.isEmpty && b.lastTime.isEmpty) return 0;
      if (a.lastTime.isEmpty) return 1;
      if (b.lastTime.isEmpty) return -1;
      try {
        return DateTime.parse(b.lastTime)
            .compareTo(DateTime.parse(a.lastTime));
      } catch (_) {
        return 0;
      }
    });

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              _isSearching ? "No results found" : "No chats yet",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              _isSearching
                  ? "Try a different search term"
                  : "Tap the chat icon on the top-right to start a new chat.",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAll(),
      color: _green,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.type == _ChatItemType.challan) {
            return _buildIndividualTile(item.challan!);
          } else {
            return _buildUserTile(item.user!);
          }
        },
      ),
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
            Icon(Icons.groups_outlined,
                size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              _isSearching ? "No groups found" : "No groups yet",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
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
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text("Create New Group",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
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
      color: _green,
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

    final avatarLetter =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openChat(challan),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFF0F0F0)),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_green, const Color(0xFF128C7E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
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
                              color: unreadCount > 0
                                  ? _green
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
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
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
    final avatarLetter =
        groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G';
    final timeLabel = _formatTime(lastMsgTime.isNotEmpty ? lastMsgTime : null);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openGroup(group),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFF0F0F0)),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1565C0),
                      const Color(0xFF1E88E5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
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
                                fontSize: 11, color: Colors.grey),
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
                                fontSize: 13, color: Colors.grey),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.grey, size: 18),
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

    // Extract DM group metadata merged in _chattedUsers getter
    final dmGroup = user['_dmGroup'] as Map?;
    final lastMessage = dmGroup?['LastMessage']?.toString() ?? '';
    final lastMsgTime = dmGroup?['LastMessageTime']?.toString() ?? '';
    final timeLabel = _formatTime(lastMsgTime.isNotEmpty ? lastMsgTime : null);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openUserChat(userId, userName, companyName: companyName.isNotEmpty ? companyName : null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFF0F0F0)),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF075E54), Color(0xFF128C7E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
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
                                fontSize: 11, color: Colors.grey),
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
                            color: Color(0xFF075E54),
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
                            fontSize: 13, color: Colors.grey),
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
                fontWeight: FontWeight.w600),
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
        decoration: const BoxDecoration(
          color: Color(0xFF075E54),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.group_add_outlined,
                color: Colors.white, size: 20),
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
                  color: Colors.white.withOpacity(0.25),
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
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final user = filtered[i];
                        final userId = user['id']?.toString() ?? '';
                        final userName =
                            user['name']?.toString() ?? userId;
                        final isSelected = _selected.contains(userId);

                        return CheckboxListTile(
                          key: ValueKey(userId),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
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
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
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
                borderRadius: BorderRadius.circular(8)),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
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
