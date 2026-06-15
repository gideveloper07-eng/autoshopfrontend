import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'challan_chat_dialog.dart';
import 'group_chat_screen.dart';

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

  bool isLoading = true;
  String? errorMessage;

  // ── Search ───────────────────────────────────────────────────────
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Polling ──────────────────────────────────────────────────────
  Timer? _pollTimer;

  static const Color _green = Color(0xFF075E54);

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
      ]);

      final challanList = results[0] as List<Map<String, dynamic>>;
      final groupList = results[1] as List<dynamic>;

      if (mounted) {
        setState(() {
          challans = challanList;
          _groups = groupList;
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupChatScreen(groupId: groupId, groupName: groupName),
      ),
    );
    _loadAll(silent: true);
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
    if (!_isSearching) return _groups;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _groups;
    return _groups.where((g) {
      final name = (g['GroupName']?.toString() ?? '').toLowerCase();
      return name.contains(q);
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
                  children: [
                    _buildChatsTab(),
                    _buildGroupsTab(),
                  ],
                ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          // Only show FAB on Groups tab (index 1)
          if (_tabController.index != 1 || isLoading) {
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _green,
      iconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: _isSearching ? 0 : null,
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
          : Row(
              children: [
                const Text(
                  "Chat",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                if (_totalUnread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
      bottom: TabBar(
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
                if (challans.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      challans.length > 99 ? '99+' : '${challans.length}',
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
      ),
    );
  }

  // ── Chats Tab ─────────────────────────────────────────────────────

  Widget _buildChatsTab() {
    final indChats = _filteredChallans;

    if (indChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              _isSearching ? "No chats found" : "No chats yet",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              _isSearching
                  ? "Try a different search term"
                  : "Your challan chats will appear here",
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
        itemCount: indChats.length,
        itemBuilder: (context, index) =>
            _buildIndividualTile(indChats[index]),
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
