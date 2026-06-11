import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import 'challan_chat_dialog.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> challans = [];

  /// challanId → {lastMessage, unreadCount}
  final Map<String, ChatMeta> _chatMeta = {};

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChallans();
  }

  Future<void> _loadChallans() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getChallanRetailIncentive();
      setState(() {
        challans = data;
        isLoading = false;
      });

      // Load chat meta (last message + unread count) for every challan in
      // parallel, then refresh UI once all futures resolve.
      _loadAllChatMeta(data);
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadAllChatMeta(List<Map<String, dynamic>> list) async {
    await Future.wait(list.map((challan) async {
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
        // For DOCUMENT messages show a nicer preview
        if ((last['MessageType']?.toString() ?? 'TEXT') == 'DOCUMENT') {
          lastMsg =
              '📄 ${last['DocumentType'] ?? ''} #${last['DocumentNo'] ?? ''}';
        }
        lastTime = last['MessageTime']?.toString() ?? '';
      }

      if (mounted) {
        setState(() {
          _chatMeta[challanId] = ChatMeta(
            lastMessage: lastMsg,
            lastTime: lastTime,
            unreadCount: unread,
          );
        });
      }
    }));
  }

  void _openChat(Map<String, dynamic> challan) async {
    final challanId = challan['sp_462']?.toString() ?? '';
    final challanNo = challan['sp_468']?.toString() ?? '';

    if (challanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid challan. Cannot open chat.")),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => ChallanChatDialog(
        challanId: challanId,
        challanNo: challanNo,
        customerName: challan['sp_469']?.toString() ?? '',
      ),
    );

    // After dialog closes, refresh meta for this challan so badge clears
    _refreshSingleMeta(challanId);
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
        lastMsg = '📄 ${last['DocumentType'] ?? ''} #${last['DocumentNo'] ?? ''}';
      }
      lastTime = last['MessageTime']?.toString() ?? '';
    }

    if (mounted) {
      setState(() {
        _chatMeta[challanId] = ChatMeta(
          lastMessage: lastMsg,
          lastTime: lastTime,
          unreadCount: unread,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.vibrantGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Chat",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadChallans,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildError()
              : challans.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            "Failed to load challans",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadChallans,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            "No challans found",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Your challans will appear here",
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadChallans,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: challans.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final challan = challans[index];
          final challanId = challan['sp_462']?.toString() ?? '';
          final challanNo = challan['sp_468']?.toString() ?? 'N/A';
          final customerName = challan['sp_469']?.toString() ?? '';
          final date = challan['date']?.toString() ?? '';

          final meta = _chatMeta[challanId];
          final lastMessage = meta?.lastMessage ?? '';
          final unreadCount = meta?.unreadCount ?? 0;
          final lastTime = meta?.lastTime ?? '';

          // Format lastTime as "hh:mm a" or "dd MMM"
          String timeLabel = '';
          if (lastTime.isNotEmpty) {
            try {
              final dt = DateTime.parse(lastTime);
              final now = DateTime.now();
              if (dt.year == now.year &&
                  dt.month == now.month &&
                  dt.day == now.day) {
                timeLabel = DateFormat('hh:mm a').format(dt);
              } else {
                timeLabel = DateFormat('dd MMM').format(dt);
              }
            } catch (_) {}
          }

          return GestureDetector(
            onTap: () => _openChat(challan),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Chat icon bubble
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Challan info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Challan #$challanNo",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (customerName.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            customerName,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],

                        // Last message preview
                        if (lastMessage.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: unreadCount > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary.withOpacity(0.7),
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],

                        if (date.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Right side: time + unread badge + chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: unreadCount > 0
                                ? Colors.green
                                : AppColors.textSecondary.withOpacity(0.6),
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green,
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
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Small holder for per-challan chat metadata shown in the list.
class ChatMeta {
  final String lastMessage;
  final String lastTime;
  final int unreadCount;

  const ChatMeta({
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
  });
}

// ignore_for_file: deprecated_member_use
