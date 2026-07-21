import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';

/// A screen that lists all pending chat requests received by the current user.
/// Shown when a non-admin taps the requests icon in [NewChatScreen].
class ChatRequestsScreen extends StatefulWidget {
  const ChatRequestsScreen({super.key});

  @override
  State<ChatRequestsScreen> createState() => _ChatRequestsScreenState();
}

class _ChatRequestsScreenState extends State<ChatRequestsScreen> {
  List<dynamic> _requests = [];
  bool _loading = true;

  static const List<Color> _kAvatarColors = [
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

  Color _avatarColor(String name) {
    if (name.isEmpty) return _kAvatarColors[0];
    return _kAvatarColors[name.codeUnitAt(0) % _kAvatarColors.length];
  }

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  /// Resolves a human-readable display name from a request map.
  /// The API returns [FromLoginId] (e.g. "adm") as the sender identifier.
  /// We prefer a full name if present, then fall back to the login ID.
  String _resolveSenderName(dynamic request) {
    // Prefer any full-name field if the backend ever adds one
    final fullName = request['FromUserName']?.toString() ??
        request['SenderName']?.toString() ??
        '';
    if (fullName.isNotEmpty) return fullName;

    // Use the login ID — this is what the backend stores (e.g. "adm")
    final loginId = request['FromLoginId']?.toString() ?? '';
    if (loginId.isNotEmpty) return loginId;

    // Last resort
    return request['FromUserGuid']?.toString() ?? 'Unknown';
  }

  static const String _cacheKey = 'chat_requests';

  Future<void> _loadRequests() async {
    // ── Step 1: Show cached requests immediately ──────────────────────────
    final cached = await CacheService.getList(
      _cacheKey,
      ttlMs: CacheService.ttlShort,
    );
    if (cached != null && mounted) {
      setState(() {
        _requests = cached;
        _loading = false;
      });
    } else {
      setState(() => _loading = true);
    }

    // ── Step 2: Fetch fresh from backend ──────────────────────────────────
    final data = await ApiService.getChatRequests();
    if (data.isNotEmpty) {
      await CacheService.setList(_cacheKey, data);
    }
    if (mounted) {
      setState(() {
        _requests = data;
        _loading = false;
      });
    }
  }

  Future<void> _showAcceptRejectDialog(dynamic request) async {
    // The API returns FromLoginId as the sender identifier (e.g. "adm")
    // and optionally FromCompanyName / FromBranchName for context.
    final senderName = _resolveSenderName(request);
    // RequestGuid is used by the correct accept/reject backend routes
    final requestGuid = request['RequestGuid']?.toString() ?? '';

    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _avatarColor(senderName),
              radius: 20,
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                senderName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '$senderName wants to connect with you.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'REJECT'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'ACCEPT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F6AE2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (action == null || requestGuid.isEmpty) return;

    Map<String, dynamic> result;
    if (action == 'ACCEPT') {
      result = await ApiService.acceptChatRequestByGuid(requestGuid: requestGuid);
    } else {
      result = await ApiService.rejectChatRequestByGuid(requestGuid: requestGuid);
    }

    if (!mounted) return;

    final message = result['message']?.toString() ??
        (action == 'ACCEPT' ? 'Request accepted' : 'Request rejected');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    if (result['success'] == true) {
      // Invalidate cache so next open fetches fresh data
      await CacheService.delete(_cacheKey);
      // Reload to reflect the change
      await _loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarBg = theme.colorScheme.surface;
    final appBarText = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1923)
          : const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0.5,
        iconTheme: IconThemeData(color: appBarText),
        centerTitle: true,
        title: Text(
          'Chat Requests (${_requests.length})',
          style: TextStyle(
            color: appBarText,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mark_chat_unread_outlined,
                        size: 64,
                        color: Colors.grey.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No pending requests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Chat requests will appear here',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      final senderName = _resolveSenderName(request);
                      final avatarLetter = senderName.isNotEmpty
                          ? senderName[0].toUpperCase()
                          : '?';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showAcceptRejectDialog(request),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              border: Border(
                                bottom: BorderSide(
                                  color: theme.dividerColor,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  backgroundColor: _avatarColor(senderName),
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

                                // Name
                                Expanded(
                                  child: Text(
                                    senderName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // "Pending" badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3CD),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFFFD166),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF856404),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
