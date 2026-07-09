import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewChatScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allUsers;

  /// Recent challan chats to show at the top (optional).
  /// Each map should have keys: sp_462 (id), sp_468 (no), sp_469 (customer),
  /// lastMessage, lastTime.
  final List<Map<String, dynamic>> recentChallans;

  const NewChatScreen({
    super.key,
    required this.allUsers,
    this.recentChallans = const [],
  });

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {});
    });
  }

  static const Color _iconGrey = Color(0xFF54656F);

  static const List<Color> _avatarPalette = [
    Color(0xFF00BCD4),
    Color(0xFF7B68EE),
    Color(0xFFFF7043),
    Color(0xFF26A69A),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFFEC407A),
    Color(0xFF66BB6A),
    Color(0xFFFFB300),
    Color(0xFF8D6E63),
  ];

  static Color _avatarColorFromName(String name) {
    if (name.isEmpty) return _avatarPalette[0];
    return _avatarPalette[name.codeUnitAt(0) % _avatarPalette.length];
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchCtrl.text.trim().toLowerCase();
    final validUsers = widget.allUsers
        .where((u) => (u['id']?.toString() ?? '').isNotEmpty)
        .toList();

    validUsers.sort((a, b) {
      final nameA = (a['name']?.toString() ?? '').toLowerCase();
      final nameB = (b['name']?.toString() ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    if (query.isEmpty) return validUsers;

    return validUsers.where((u) {
      final name = (u['name']?.toString() ?? '').toLowerCase();
      final id = (u['id']?.toString() ?? '').toLowerCase();
      final email = (u['email']?.toString() ?? '').toLowerCase();
      return name.contains(query) ||
          id.contains(query) ||
          email.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredChallans {
    if (!_isSearching) return widget.recentChallans;
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return widget.recentChallans;
    return widget.recentChallans.where((c) {
      final no = (c['sp_468']?.toString() ?? '').toLowerCase();
      final name = (c['challanmade']?.toString() ?? '').toLowerCase();
      final msg = (c['lastMessage']?.toString() ?? '').toLowerCase();
      return no.contains(query) || name.contains(query) || msg.contains(query);
    }).toList();
  }

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;
    final filteredChallans = _filteredChallans;

    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF8A9BB0)
              : _iconGrey,
        ),
        titleSpacing: 0,
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                ),
                cursorColor: Theme.of(context).colorScheme.onSurface,
                decoration: InputDecoration(
                  hintText: "Search…",
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select contact",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${widget.allUsers.length} contacts",
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF8A9BB0)
                  : _iconGrey,
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
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF8A9BB0)
                  : _iconGrey,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: widget.allUsers.isEmpty && !_isSearching
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                final items = _buildItems(filteredUsers, filteredChallans);
                return ListView.builder(
                  // key forces a full rebuild when search mode toggles,
                  // preventing the RenderSliverPadding / duplicate-key assertion.
                  key: ValueKey(_isSearching),
                  itemCount: items.length,
                  itemBuilder: (context, index) => items[index],
                );
              },
            ),
    );
  }

  /// Builds the flat list of widgets for the ListView.builder.
  /// Using a flat list avoids Flutter's widget-tree identity issues
  /// when toggling _isSearching with spread-operator conditional children.
  List<Widget> _buildItems(
    List<Map<String, dynamic>> filteredUsers,
    List<Map<String, dynamic>> filteredChallans,
  ) {
    final List<Widget> items = [];

    // ── Action tiles (New group / New contact) ──────────────
    if (!_isSearching) {
      items.add(
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.group, color: Colors.white),
          ),
          title: const Text(
            "New group",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          onTap: () => Navigator.pop(context, 'TRIGGER_NEW_GROUP'),
        ),
      );
      items.add(
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
          title: const Text(
            "New contact",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          trailing: const Icon(Icons.qr_code, color: Colors.grey),
          onTap: () {},
        ),
      );
    }

    // ── Recent Challan Chats ─────────────────────────────────
    if (filteredChallans.isNotEmpty) {
      items.add(
        _sectionHeader(Icons.receipt_long_outlined, "Recent Challan Chats"),
      );

      for (final challan in filteredChallans) {
        final challanId = challan['sp_462']?.toString() ?? '';
        final challanNo = challan['sp_468']?.toString() ?? '';
        final customerName = challan['challanmade']?.toString() ?? '';
        final lastMsg = challan['lastMessage']?.toString() ?? '';
        final lastTime = _formatTime(challan['lastTime']?.toString());
        final title = customerName.isNotEmpty
            ? customerName
            : 'Challan #$challanNo';
        final avatarLetter = title.isNotEmpty ? title[0].toUpperCase() : 'C';

        items.add(
          _chatTile(
            key: ValueKey('challan_$challanId'),
            avatarLetter: avatarLetter,
            avatarColor: _avatarColorFromName(title),
            title: title,
            subtitle: lastMsg.isNotEmpty ? lastMsg : 'Challan #$challanNo',
            timeLabel: lastTime,
            onTap: () => Navigator.pop(context, {
              '_type': 'challan',
              'challanId': challanId,
              'challanNo': challanNo,
              'customerName': customerName,
            }),
          ),
        );
      }
    }

    // ── Contacts header ──────────────────────────────────────
    items.add(_sectionHeader(Icons.people_outline, "Contacts on MyAutoShop"));

    // ── Users ────────────────────────────────────────────────
    if (filteredUsers.isEmpty) {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              "No contacts found",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ),
        ),
      );
    } else {
      for (final user in filteredUsers) {
        final userId = user['id']?.toString() ?? '';
        final userName = user['name']?.toString() ?? userId;
        final companyName = user['companyName']?.toString() ?? '';
        final userEmail = user['email']?.toString() ?? '';
        final subtitle = companyName.isNotEmpty
            ? companyName
            : userEmail.isNotEmpty
            ? userEmail
            : 'No description/email';
        final avatarLetter = userName.isNotEmpty
            ? userName[0].toUpperCase()
            : '?';

        items.add(
          ListTile(
            key: ValueKey('user_$userId'),
            leading: CircleAvatar(
              backgroundColor: _avatarColorFromName(userName),
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: companyName.isNotEmpty
                    ? const Color(0xFF54656F)
                    : Colors.grey,
                fontSize: 13,
                fontWeight: companyName.isNotEmpty
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
            onTap: () => Navigator.pop(context, user),
          ),
        );
      }
    }

    return items;
  }

  Widget _sectionHeader(IconData icon, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2E42) : const Color(0xFFF0F2F5);
    final textColor = isDark
        ? const Color(0xFF8A9BB0)
        : const Color(0xFF555555);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatTile({
    Key? key,
    required String avatarLetter,
    required Color avatarColor,
    required String title,
    required String subtitle,
    required String timeLabel,
    required VoidCallback onTap,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: avatarColor,
              radius: 24,
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeLabel.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: onSurface.withOpacity(0.55),
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
}
