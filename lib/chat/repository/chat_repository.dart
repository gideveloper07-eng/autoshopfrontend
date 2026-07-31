import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../database/dao/conversation_dao.dart';
import '../../database/dao/message_dao.dart';
import '../../database/models/chat_message.dart';
import '../../database/models/conversation.dart';
import '../../services/api_service.dart';
import '../mappers/chat_mapper.dart';
import '../utils/conversation_helper.dart';

class ChatRepository {
  ChatRepository._();

  static final ChatRepository instance = ChatRepository._();

  final MessageDao _messageDao = MessageDao.instance;
  final ConversationDao _conversationDao = ConversationDao.instance;

  final StreamController<String> _conversationUpdates =
      StreamController<String>.broadcast();

  Stream<String> get conversationUpdates => _conversationUpdates.stream;
  //==========================================================
  // MESSAGE OPERATIONS
  //==========================================================
  static const _uuid = Uuid();

  Future<void> _notifyConversation(String conversationId) async {
    if (kIsWeb) return;

    _conversationUpdates.add(conversationId);
  }

  Future<void> updateMessage(ChatMessage message) async {
    await _messageDao.update(message);
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    await _messageDao.upsertAll(messages);
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    if (kIsWeb) {
      return [];
    }

    return await _messageDao.getConversationMessages(conversationId);
  }

  Future<void> upsertMessage(ChatMessage message) async {
    debugPrint("UPSERT 1");

    if (kIsWeb) return;

    debugPrint("UPSERT 2");

    await _messageDao.upsert(message);

    debugPrint("UPSERT 3");

    await _conversationDao.updateLastMessage(
      conversationId: message.conversationId,
      lastMessage: message.messageText ?? "",
      messageType: message.messageType,
      senderId: message.senderUserId,
      messageTime: message.messageTime,
    );

    debugPrint("UPSERT 4");

    await _notifyConversation(message.conversationId);

    debugPrint("UPSERT 5");
  }

  Future<bool> sendDirectMessage({
    required String receiverId,
    required String receiverPropertyCode,
    required String receiverDatabase,
    required String receiverName,
    required String senderName,
    required String senderId,
    required String message,
    String? documentId,
    String? documentType,
  }) async {
    debugPrint("REPO 1");
    final session = await ApiService.getUserSession();

    final companyCode = session?['companyCode']?.toString() ?? '';

    final conversationId = ConversationHelper.directConversationId(
      databaseName: receiverDatabase,
      userId: receiverId,
      propertyCode: receiverPropertyCode,
    );

    if (kIsWeb) {
      final chatId = const Uuid().v4().toLowerCase();

      final result = await ApiService.sendChatMessage(
        chatId: chatId,
        challanId: "0001",
        messageText: message,
        senderName: senderName,
        challanNo: "",
        databaseName: "",
        receiverDbName: receiverDatabase,
        receiverUserId: receiverId,
        receiverName: receiverName,
        messageType: documentId == null ? "TEXT" : "DOCUMENT",
        documentId: documentId,
        receiverPropertyCode: receiverPropertyCode,
      );

      return result.success;
    }
    debugPrint("REPO 2");
    final localMessage = ChatMessage(
      chatId: const Uuid().v4().toLowerCase(),
      conversationId: conversationId,
      senderUserId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      senderPropertyCode: companyCode,
      receiverPropertyCode: receiverPropertyCode,
      messageText: message,
      messageType: documentId == null ? 'TEXT' : 'DOCUMENT',
      documentId: documentId,
      messageTime: DateTime.now().millisecondsSinceEpoch,
      status: 'sending',
      isRead: false,
      isSynced: false,
      receiverDatabase: receiverDatabase,
      receiverName: receiverName,
      conversationType: 'DIRECT',
    );
    debugPrint(
      "LOCAL CREATED -> "
      "ID=${localMessage.chatId} | "
      "TEXT=${localMessage.messageText} | "
      "TIME=${localMessage.messageTime}",
    );
    await upsertMessage(localMessage);
    debugPrint("REPO 3");
    return await resendMessage(localMessage);
  }

  Future<bool> resendMessage(ChatMessage message) async {
    try {
      debugPrint("RESEND 1");
      debugPrint(
        "SENDING SERVER -> "
        "ID=${message.chatId} | "
        "TEXT=${message.messageText}",
      );
      final result = await ApiService.sendChatMessage(
        chatId: message.chatId,
        challanId: "0001",
        messageText: message.messageText ?? '',
        senderName: message.senderName ?? '',
        challanNo: "",
        databaseName: "",
        receiverDbName: message.receiverDatabase ?? "",
        receiverUserId: message.receiverId,
        receiverName: message.receiverName ?? "",
        messageType: message.messageType,
        documentId: message.documentId,
        receiverPropertyCode: message.receiverPropertyCode,
      );
      debugPrint("RESEND 2");
      debugPrint("Server ChatId: ${result.chatId}");
      debugPrint(
        "SERVER RESPONSE -> "
        "success=${result.success} | "
        "localId=${message.chatId} | "
        "serverId=${result.chatId}",
      );
      if (result.success) {
        await updateMessage(message.copyWith(status: 'sent', isSynced: true));

        await _notifyConversation(message.conversationId);
        return true;
      } else {
        await updateMessage(message.copyWith(status: 'failed'));

        await _notifyConversation(message.conversationId);
        return false;
      }
    } catch (e, st) {
      debugPrint("RESEND ERROR: $e");
      debugPrintStack(stackTrace: st);

      await updateMessage(message.copyWith(status: 'failed'));

      await _notifyConversation(message.conversationId);

      return false;
    }
  }

  Future<void> markConversationRead(String conversationId) async {
    await _messageDao.markConversationRead(conversationId);

    await _conversationDao.resetUnread(conversationId);
  }

  Future<List<ChatMessage>> pendingSync() async {
    return await _messageDao.getUnsyncedMessages();
  }

  Future<void> deleteMessage(String chatId) async {
    await _messageDao.softDelete(chatId);
  }

  //==========================================================
  // CONVERSATION OPERATIONS
  //==========================================================

  Future<List<Conversation>> getConversations() async {
    if (kIsWeb) {
      return [];
    }

    return await _conversationDao.getAll();
  }

  Future<Conversation?> getConversation(String conversationId) async {
    return await _conversationDao.findById(conversationId);
  }

  Future<void> pinConversation(String conversationId, bool pin) async {
    await _conversationDao.pinConversation(conversationId, pin);
  }

  Future<void> muteConversation(String conversationId, bool mute) async {
    await _conversationDao.muteConversation(conversationId, mute);
  }

  Future<void> archiveConversation(String conversationId, bool archive) async {
    await _conversationDao.archiveConversation(conversationId, archive);
  }

  Future<List<ChatMessage>> loadDirectConversation({
    required String targetUserId,
    required String receiverPropertyCode,
    required String receiverDatabase,
  }) async {
    final conversationId = ConversationHelper.directConversationId(
      databaseName: receiverDatabase,
      userId: targetUserId,
      propertyCode: receiverPropertyCode,
    );

    // WEB
    if (kIsWeb) {
      final serverData = await ApiService.syncDirectChatMessages(
        targetUserId,
        receiverPropertyCode,
      );

      return serverData
          .map(
            (e) => ChatMapper.fromDirectApi(
              json: Map<String, dynamic>.from(e),
              conversationId: conversationId,
            ),
          )
          .toList();
    }

    // MOBILE
    final localMessages = await _messageDao.getConversationMessages(
      conversationId,
    );

    _syncDirectConversation(
      targetUserId: targetUserId,
      receiverPropertyCode: receiverPropertyCode,
      receiverDatabase: receiverDatabase,
      conversationId: conversationId,
    );

    return localMessages;
  }

  Future<void> _syncDirectConversation({
    required String targetUserId,
    required String receiverPropertyCode,
    required String receiverDatabase,
    required String conversationId,
  }) async {
    try {
      final serverData = await ApiService.syncDirectChatMessages(
        targetUserId,
        receiverPropertyCode,
      );

      if (serverData.isEmpty) return;

      final serverMessages = serverData
          .map(
            (e) => ChatMapper.fromDirectApi(
              json: Map<String, dynamic>.from(e),
              conversationId: conversationId,
            ),
          )
          .toList();

      if (serverMessages.isEmpty) return;

      if (!kIsWeb) {
        print("========= SERVER MESSAGES =========");

        for (final m in serverMessages) {
          print(
            "ID=${m.chatId}, TEXT=${m.messageText}, TIME=${m.messageTime}, SENDER=${m.senderUserId}",
          );
        }

        print("==================================");

        await _messageDao.upsertAll(serverMessages);
        final all = await _messageDao.getConversationMessages(conversationId);

        debugPrint("===== SQLITE =====");
        for (final m in all) {
          debugPrint("${m.chatId} | ${m.messageText}");
        }
        debugPrint("==================");
        final last = serverMessages.last;

        await _conversationDao.updateLastMessage(
          conversationId: last.conversationId,
          lastMessage: last.messageText ?? "",
          messageType: last.messageType,
          senderId: last.senderUserId,
          messageTime: last.messageTime,
        );

        await _notifyConversation(conversationId);
      }
    } catch (e) {
      debugPrint("Direct chat sync failed: $e");
    }
  }

  Future<void> syncDirectConversation(Conversation conversation) async {
    final lastSync = conversation.lastSyncTime ?? 0;
    final response = await ApiService.getDirectChatMessages(
      conversation.userId!,
      conversation.propertyCode!,
    );

    final messages = List<Map<String, dynamic>>.from(response["data"] ?? []);

    int newestSync = lastSync;

    for (final json in messages) {
      final message = ChatMapper.fromDirectApi(
        json: json,
        conversationId: conversation.conversationId,
      );

      await upsertMessage(message);

      if (message.messageTime > newestSync) {
        newestSync = message.messageTime;
      }
    }

    if (newestSync > lastSync) {
      await _conversationDao.updateLastSyncTime(
        conversation.conversationId,
        newestSync,
      );
    }
  }

  Future<void> _uploadPendingMessages() async {
    final pending = await pendingSync();

    for (final message in pending) {
      await resendMessage(message);
    }
  }

  Future<void> sync() async {
    await _uploadPendingMessages();
    await syncConversations();
    await syncAllMessages();
  }

  Future<void> syncConversations() async {
    final apiConversations = await ApiService.getMyDirectChats();

    if (apiConversations.isEmpty) return;

    for (final json in apiConversations) {
      final conversation = ChatMapper.fromConversationApi(
        Map<String, dynamic>.from(json),
      );

      await upsertConversation(conversation);
    }
  }

  Future<void> upsertConversation(Conversation conversation) async {
    await _conversationDao.upsert(conversation);
  }

  Future<void> syncAllMessages() async {
    final conversations = await getConversations();

    for (final conversation in conversations) {
      await syncDirectConversation(conversation);
    }
  }
}
