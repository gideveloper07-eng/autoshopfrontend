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
  bool _isSearching = false;

  static const Color _green = Color(0xFF075E54);
  static const Color _teal = Color(0xFF128C7E);

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
      return name.contains(query) || id.contains(query) || email.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredChallans {
    if (!_isSearching) return widget.recentChallans;
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return widget.recentChallans;
    return widget.recentChallans.where((c) {
      final no = (c['sp_468']?.toString() ?? '').toLowerCase();
      final name = (c['sp_469']?.toString() ?? '').toLowerCase();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;
    final filteredChallans = _filteredChallans;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _green,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: "Search…",
                  hintStyle: TextStyle(color: Colors.white60, fontSize: 18),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select contact",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${widget.allUsers.length} contacts",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── Action tiles (New group / New contact) ──────────────
          if (!_isSearching) ...[
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: _teal,
                child: Icon(Icons.group, color: Colors.white),
              ),
              title: const Text(
                "New group",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onTap: () => Navigator.pop(context, 'TRIGGER_NEW_GROUP'),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: _teal,
                child: Icon(Icons.person_add, color: Colors.white),
              ),
              title: const Text(
                "New contact",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              trailing: const Icon(Icons.qr_code, color: Colors.grey),
              onTap: () {},
            ),
          ],

          // ── Recent Challan Chats ─────────────────────────────────
          if (filteredChallans.isNotEmpty) ...[
            _sectionHeader(Icons.receipt_long_outlined, "Recent Challan Chats"),
            ...filteredChallans.map((challan) {
              final challanId = challan['sp_462']?.toString() ?? '';
              final challanNo = challan['sp_468']?.toString() ?? '';
              final customerName = challan['sp_469']?.toString() ?? '';
              final lastMsg = challan['lastMessage']?.toString() ?? '';
              final lastTime = _formatTime(challan['lastTime']?.toString());
              final title = customerName.isNotEmpty
                  ? customerName
                  : 'Challan #$challanNo';
              final avatarLetter =
                  title.isNotEmpty ? title[0].toUpperCase() : 'C';

              return _chatTile(
                avatarLetter: avatarLetter,
                avatarColor: _green,
                title: title,
                subtitle: lastMsg.isNotEmpty ? lastMsg : 'Challan #$challanNo',
                timeLabel: lastTime,
                onTap: () => Navigator.pop(context, {
                  '_type': 'challan',
                  'challanId': challanId,
                  'challanNo': challanNo,
                  'customerName': customerName,
                }),
              );
            }),
          ],

          // ── Contacts header ──────────────────────────────────────
          _sectionHeader(Icons.people_outline, "Contacts on MyAutoShop"),

          // ── Users ────────────────────────────────────────────────
          if (filteredUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  "No contacts found",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            )
          else
            ...filteredUsers.map((user) {
              final userId = user['id']?.toString() ?? '';
              final userName = user['name']?.toString() ?? userId;
              final companyName = user['companyName']?.toString() ?? '';
              final userEmail = user['email']?.toString() ?? '';
              // Prefer companyName, then email, then fallback label
              final subtitle = companyName.isNotEmpty
                  ? companyName
                  : userEmail.isNotEmpty
                      ? userEmail
                      : 'No description/email';
              final avatarLetter =
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?';

              return ListTile(
                key: ValueKey(userId),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEFEFEF),
                  child: Text(
                    avatarLetter,
                    style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: companyName.isNotEmpty
                        ? const Color(0xFF075E54)
                        : Colors.grey,
                    fontSize: 13,
                    fontWeight: companyName.isNotEmpty
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
                onTap: () => Navigator.pop(context, user),
              );
            }),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Container(
      color: const Color(0xFFF0F2F5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _green),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF555555),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatTile({
    required String avatarLetter,
    required Color avatarColor,
    required String title,
    required String subtitle,
    required String timeLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1A1A1A),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.grey),
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
