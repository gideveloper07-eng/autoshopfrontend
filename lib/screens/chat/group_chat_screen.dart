import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  // ── Messaging ──────────────────────────────────────────────────
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  List<dynamic> messages = [];
  bool loading = true;
  bool _sending = false;
  bool _userScrolledUp = false;
  int _newWhileScrolledUp = 0;
  String currentUserName = "";
  String currentUserId = "";

  // ── Members ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _members = [];

  // ── Polling ────────────────────────────────────────────────────
  Timer? _timer;

  static const Color _green = Color(0xFF075E54);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _init();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _msgCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ── Init ───────────────────────────────────────────────────────

  Future<void> _init() async {
    currentUserName = await ApiService.getUserName() ?? "";
    currentUserId = await ApiService.getUserId() ?? "";
    await Future.wait([_loadMessages(isInitial: true), _loadMembers()]);
  }

  // ── Scroll ─────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final atBottom = _scrollCtrl.position.pixels >=
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
      if (_scrollCtrl.hasClients) {
        if (animated) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      }
    });
  }

  // ── Data ───────────────────────────────────────────────────────

  Future<void> _loadMessages({bool isInitial = false}) async {
    final data = await ApiService.getGroupMessages(widget.groupId);
    if (!mounted) return;

    final oldCount = messages.length;
    final hasNew = data.length > oldCount;
    int newFromOthers = 0;
    if (hasNew && !isInitial) {
      for (int i = oldCount; i < data.length; i++) {
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
      _scrollToBottom(animated: false);
    } else if (hasNew && !_userScrolledUp) {
      _scrollToBottom();
    }
  }

  Future<void> _loadMembers() async {
    final data = await ApiService.getGroupMembers(widget.groupId);
    if (mounted) setState(() => _members = data);
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _msgCtrl.clear();

    final ok = await ApiService.sendGroupMessage(
      groupId: widget.groupId,
      messageText: text,
    );

    if (!mounted) return;
    if (ok) {
      _userScrolledUp = false;
      _newWhileScrolledUp = 0;
      await _loadMessages();
      _scrollToBottom();
    } else {
      _msgCtrl.text = text;
    }
    setState(() => _sending = false);
  }

  // ── Menu actions ───────────────────────────────────────────────

  void _showViewMembers() {
    showDialog(
      context: context,
      builder: (_) => _GroupMembersDialog(
        groupId: widget.groupId,
        members: _members,
        currentUserId: currentUserId,
        removeMode: false,
        onRemoved: (u, n) async => false, // view-only
      ),
    );
  }

  void _showAddMember() async {
    final allUsers = await ApiService.getCompanyUsers();
    if (!mounted) return;
    final existingIds = _members.map((m) => m['UserId']?.toString()).toSet();
    final available =
        allUsers.where((u) => !existingIds.contains(u['UserId']?.toString())).toList();

    showDialog(
      context: context,
      builder: (_) => _GroupAddMemberDialog(
        availableUsers: available,
        onAdd: (userId) async {
          final ok = await ApiService.addGroupMember(
            groupId: widget.groupId,
            userId: userId,
          );
          if (ok && mounted) {
            await _loadMembers();
            await _loadMessages();
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
      builder: (_) => _GroupMembersDialog(
        groupId: widget.groupId,
        members: _members,
        currentUserId: currentUserId,
        removeMode: true,
        onRemoved: (userId, _) async {
          final ok = await ApiService.removeGroupMember(
            groupId: widget.groupId,
            userId: userId,
          );
          if (ok && mounted) {
            await _loadMembers();
            await _loadMessages();
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
        titlePadding: EdgeInsets.zero,
        title: Container(
          decoration: const BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.groupName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow(Icons.group, "Group Name", widget.groupName),
            _infoRow(Icons.people, "Members", "${_members.length}"),
            _infoRow(Icons.message, "Messages", "${messages.length}"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _green),
          const SizedBox(width: 10),
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  // ── Formatters ─────────────────────────────────────────────────

  String _formatTime(String value) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  String? _dateSeparator(int index) {
    if (index == 0) {
      try {
        return DateFormat('dd MMM yyyy')
            .format(DateTime.parse(messages[0]['MessageTime'].toString()));
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

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: _green,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.groupName.isNotEmpty
                      ? widget.groupName[0].toUpperCase()
                      : 'G',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  Text(
                    _members.isEmpty
                        ? "Group"
                        : "${_members.length} member${_members.length == 1 ? '' : 's'}",
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (v) {
              switch (v) {
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
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'viewMembers',
                child: _GMenuRow(icon: Icons.people_outline, label: 'View Members'),
              ),
              PopupMenuItem(
                value: 'addMember',
                child: _GMenuRow(icon: Icons.person_add_alt_1_outlined, label: 'Add Member'),
              ),
              PopupMenuItem(
                value: 'removeMember',
                child: _GMenuRow(
                    icon: Icons.person_remove_outlined,
                    label: 'Remove Member',
                    danger: true),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'groupInfo',
                child: _GMenuRow(icon: Icons.info_outline, label: 'Group Info'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ────────────────────────────────────────────
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final separator = _dateSeparator(index);
                          final msg = messages[index];
                          final senderName =
                              msg['SenderName']?.toString() ?? '';
                          final text = msg['MessageText']?.toString() ?? '';
                          final msgTime = msg['MessageTime']?.toString() ?? '';
                          final msgType =
                              msg['MessageType']?.toString() ?? 'TEXT';
                          final isMine = senderName.toLowerCase() ==
                              currentUserName.toLowerCase();

                          // System pill
                          if (msgType == 'SYSTEM') {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1E8D5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    text,
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

                          return Column(
                            children: [
                              // Date separator
                              if (separator != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
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
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                ),

                              // Bubble
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
                                      // Show sender name for others
                                      if (!isMine)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 3),
                                          child: Text(
                                            senderName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: _green,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        text,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87),
                                      ),
                                      const SizedBox(height: 3),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          _formatTime(msgTime),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.black
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // New messages banner
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
                                _scrollToBottom();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _green,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
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

          // ── Input bar ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter) {
                        if (!_sending) _sendMessage();
                      }
                    },
                    child: TextField(
                      controller: _msgCtrl,
                      focusNode: _inputFocus,
                      enabled: !_sending,
                      decoration: InputDecoration(
                        hintText: _sending ? "Sending…" : "Type message…",
                        filled: true,
                        fillColor: const Color(0xFFF0F0F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!_sending) _sendMessage();
                      },
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
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Material(
                          color: _green,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _sendMessage,
                            child: const Icon(Icons.send,
                                color: Colors.white, size: 20),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Popup menu row ────────────────────────────────────────────────────────────

class _GMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;

  const _GMenuRow(
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

class _GroupMembersDialog extends StatefulWidget {
  final String groupId;
  final List<Map<String, dynamic>> members;
  final String currentUserId;
  final bool removeMode;
  final Future<bool> Function(String userId, String userName) onRemoved;

  const _GroupMembersDialog({
    required this.groupId,
    required this.members,
    required this.currentUserId,
    required this.removeMode,
    required this.onRemoved,
  });

  @override
  State<_GroupMembersDialog> createState() => _GroupMembersDialogState();
}

class _GroupMembersDialogState extends State<_GroupMembersDialog> {
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
            Expanded(
              child: Text(
                widget.removeMode ? "Remove Member" : "Group Members",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  final userName =
                      member['UserName']?.toString() ?? userId;
                  final isAdmin =
                      member['IsAdmin'] == true || member['IsAdmin'] == 1;
                  final isRemoving = _removing.contains(userId);
                  final isMe = userId == widget.currentUserId;

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
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
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
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF075E54),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("Admin",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ),
                        if (isMe && !isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("You",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ),
                      ],
                    ),
                    trailing: widget.removeMode && !isMe && !isAdmin
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
                                  final confirm =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Remove Member"),
                                      content: Text(
                                          "Remove $userName from this group?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                              context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                              context, true),
                                          child: const Text("Remove",
                                              style: TextStyle(
                                                  color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return;
                                  setState(
                                      () => _removing.add(userId));
                                  final ok = await widget.onRemoved(
                                      userId, userName);
                                  if (ok && mounted) {
                                    setState(() {
                                      _list.removeAt(i);
                                      _removing.remove(userId);
                                    });
                                  } else {
                                    setState(() =>
                                        _removing.remove(userId));
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

// ── Add Member to Group Dialog ────────────────────────────────────────────────

class _GroupAddMemberDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableUsers;
  final Future<bool> Function(String userId) onAdd;

  const _GroupAddMemberDialog(
      {required this.availableUsers, required this.onAdd});

  @override
  State<_GroupAddMemberDialog> createState() => _GroupAddMemberDialogState();
}

class _GroupAddMemberDialogState extends State<_GroupAddMemberDialog> {
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
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final user = filtered[i];
                        final userId = user['UserId']?.toString() ?? '';
                        final userName =
                            user['UserName']?.toString() ?? userId;
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
                                        final ok =
                                            await widget.onAdd(userId);
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
