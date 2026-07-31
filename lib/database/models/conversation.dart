class Conversation {
  final String conversationId;
  final String conversationType;
  final String? title;
  final String? databaseName;
  final String? propertyCode;
  final String? clientId;
  final String? lastMessage;
  final String? lastMessageType;
  final String? lastSenderId;
  final int? lastMessageTime;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final bool isArchived;
  final String? draftMessage;
  final int? lastSyncTime;
  final String? avatar;
  final String? userId;

  const Conversation({
    required this.conversationId,
    required this.conversationType,
    this.title,
    this.databaseName,
    this.propertyCode,
    this.clientId,
    this.lastMessage,
    this.lastMessageType,
    this.lastSenderId,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
    this.draftMessage,
    this.lastSyncTime,
    this.avatar,
    this.userId,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      conversationId: map['conversationId'],
      conversationType: map['conversationType'],
      title: map['title'],
      databaseName: map['databaseName'],
      propertyCode: map['propertyCode'],
      clientId: map['clientId'],
      lastMessage: map['lastMessage'],
      lastMessageType: map['lastMessageType'],
      lastSenderId: map['lastSenderId'],
      lastMessageTime: map['lastMessageTime'],
      unreadCount: map['unreadCount'] ?? 0,
      isPinned: map['isPinned'] == 1,
      isMuted: map['isMuted'] == 1,
      isArchived: map['isArchived'] == 1,
      draftMessage: map['draftMessage'],
      lastSyncTime: map['lastSyncTime'],
      avatar: map['avatar'],
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'conversationId': conversationId,
        'conversationType': conversationType,
        'title': title,
        'databaseName': databaseName,
        'propertyCode': propertyCode,
        'clientId': clientId,
        'lastMessage': lastMessage,
        'lastMessageType': lastMessageType,
        'lastSenderId': lastSenderId,
        'lastMessageTime': lastMessageTime,
        'unreadCount': unreadCount,
        'isPinned': isPinned ? 1 : 0,
        'isMuted': isMuted ? 1 : 0,
        'isArchived': isArchived ? 1 : 0,
        'draftMessage': draftMessage,
        'lastSyncTime': lastSyncTime,
        'avatar': avatar,
	'userId': userId,
      };

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      Conversation.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}