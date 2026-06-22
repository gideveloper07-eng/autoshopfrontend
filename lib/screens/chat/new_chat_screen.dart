import 'package:flutter/material.dart';

class NewChatScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allUsers;

  const NewChatScreen({
    super.key,
    required this.allUsers,
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
    // Exclude users with empty IDs
    final validUsers = widget.allUsers
        .where((u) => (u['id']?.toString() ?? '').isNotEmpty)
        .toList();

    // Sort alphabetically by name
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

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
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchCtrl.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // WhatsApp style action options at the top when not searching
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
              onTap: () {
                // Return a special code to trigger group flow if needed
                Navigator.pop(context, 'TRIGGER_NEW_GROUP');
              },
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Contacts on MyAutoShop",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      "No contacts found",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final userId = user['id']?.toString() ?? '';
                      final userName = user['name']?.toString() ?? userId;
                      final userEmail = user['email']?.toString() ?? 'No description/email';
                      final avatarLetter = userName.isNotEmpty
                          ? userName[0].toUpperCase()
                          : '?';

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
                          userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context, user);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
