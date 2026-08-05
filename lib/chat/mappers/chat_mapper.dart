import 'package:uuid/uuid.dart';
import '../../database/constants/db_enums.dart';
import '../../database/models/chat_message.dart';
import '../../database/models/conversation.dart';
import '../utils/conversation_helper.dart';

class ChatMapper {
  ChatMapper._();

  static Conversation fromConversationApi(Map<String, dynamic> json) {
    final conversationId = ConversationHelper.directConversationId(
      databaseName: json["DatabaseName"]?.toString() ?? "",
      userId: json["UserId"]?.toString() ?? "",
      propertyCode: json["PropertyCode"]?.toString() ?? "",
    );

    return Conversation(
      conversationId: conversationId,
      conversationType: ConversationType.direct,
      userId: json["UserId"]?.toString(),
      title: json["UserName"]?.toString(),

      databaseName: json["DatabaseName"]?.toString(),

      propertyCode: json["PropertyCode"]?.toString(),

      clientId: null,

      lastMessage: json["MessageText"]?.toString(),

      lastMessageType: (json["MessageType"] ?? MessageType.text).toString(),

      lastSenderId: json["SenderUserId"]?.toString(),

      lastMessageTime: json["LastMessageTime"] == null
          ? null
          : DateTime.parse(json["LastMessageTime"]).millisecondsSinceEpoch,

      unreadCount: json["UnreadCount"] ?? 0,

      isPinned: false,
      isMuted: false,
      isArchived: false,

      draftMessage: null,

      lastSyncTime: DateTime.now().millisecondsSinceEpoch,

      avatar: null,
    );
  }

  static ChatMessage fromDirectApi({
    required Map<String, dynamic> json,
    required String conversationId,
  }) {
    print("MESSAGE JSON = $json");
    return ChatMessage(
      chatId:
          (json['ChatId'] ?? json['chatId'] ?? json['Id'] ?? const Uuid().v4())
              .toString()
              .toLowerCase(),

      conversationId: conversationId,

      conversationType: 'DIRECT',

      senderUserId: (json['SenderId'] ?? json['SenderUserId'] ?? '').toString(),

      senderName: (json['SenderName'] ?? '').toString(),

      receiverId: (json['ReceiverId'] ?? '').toString(),

      senderPropertyCode: (json['SenderPropertyCode'] ?? '').toString(),

      receiverPropertyCode: (json['ReceiverPropertyCode'] ?? '').toString(),

      messageText: (json['MessageText'] ?? json['Message'] ?? '').toString(),

      messageType: (json['MessageType'] ?? 'TEXT').toString(),

      documentId: json['DocumentId']?.toString(),

      taskId: json['TaskId']?.toString(),

      messageTime: _parseMessageTime(json),

      isRead: _parseBool(json['IsRead']),

      status: _parseBool(json['IsRead']) ? 'read' : 'sent',

      isDeleted: (json['IsDeleted'] ?? false) == true,

      isEdited: (json['IsEdited'] ?? false) == true,

      isSynced: true,

      receiverDatabase: json['ReceiverDbName']?.toString(),

      receiverName: json['ReceiverName']?.toString(),

      taskDatabase: json['TaskDatabase']?.toString(),

      taskStatus: json['TaskStatus']?.toString(),

      taskDescription: json['TaskDescription']?.toString(),

      assignedTo: json['AssignedTo']?.toString(),

      assignedToName: json['AssignedToName']?.toString(),

      priority: json['Priority']?.toString(),

      documentNo: json['DocumentNo']?.toString(),

      documentType: json['DocumentType']?.toString(),

      companyName: json['CompanyName']?.toString(),
    );
  }

  /// Safely converts SQL bit (0/1), bool, or null to a Dart bool.
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static int _parseMessageTime(Map<String, dynamic> json) {
    final value =
        json['MessageTime'] ?? json['CreatedOn'] ?? json['CreatedDate'];

    if (value == null) {
      return DateTime.now().millisecondsSinceEpoch;
    }

    if (value is int) {
      return value;
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return DateTime.now().millisecondsSinceEpoch;
    }

    // If the server sent UTC (ends with Z), convert to local.
    if (value.toString().endsWith('Z')) {
      return date.toLocal().millisecondsSinceEpoch;
    }

    // Otherwise it's already a local SQL datetime.
    return date.millisecondsSinceEpoch;
  }
}
