import '../repository/chat_repository.dart';

class ChatSyncService {
  ChatSyncService._();

  static final ChatSyncService instance = ChatSyncService._();

  final ChatRepository _repository = ChatRepository.instance;

  bool _running = false;

  /// Main synchronization entry point
  Future<void> sync() async {
    if (_running) return;

    _running = true;

    try {
      // 1. Upload pending offline messages
      try {
        await _uploadPendingMessages();
      } catch (e, stackTrace) {
        print('Pending upload failed: $e');
        print(stackTrace);
      }

      // 2. Sync conversations
      try {
        await _repository.syncConversations();
      } catch (e, stackTrace) {
        print('Conversation sync failed: $e');
        print(stackTrace);
      }

      // 3. Sync messages for all conversations
      try {
        await _repository.syncAllMessages();
      } catch (e, stackTrace) {
        print('Message sync failed: $e');
        print(stackTrace);
      }
    } finally {
      _running = false;
    }
  }

  /// Upload all locally pending messages
  Future<void> _uploadPendingMessages() async {
    final pendingMessages = await _repository.pendingSync();

    if (pendingMessages.isEmpty) return;

    for (final message in pendingMessages) {
      try {
        await _repository.resendMessage(message);
      } catch (e, stackTrace) {
        print('Failed to resend ${message.chatId}: $e');
        print(stackTrace);
      }
    }
  }

  /// Returns true if a synchronization is currently running.
  bool get isSyncing => _running;
}