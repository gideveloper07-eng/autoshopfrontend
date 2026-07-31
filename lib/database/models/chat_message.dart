import '../constants/db_enums.dart';

class ChatMessage {
  final String chatId;
  final String conversationId;
  final String conversationType;
  final String senderUserId;
  final String? senderName;
  final String? receiverId;
  final String? senderPropertyCode;
  final String? receiverPropertyCode;
  final String? messageText;
  final String messageType;
  final String? documentId;
  final String? taskId;
  final int messageTime;
  final bool isRead;
  final String status;
  final bool isDeleted;
  final bool isEdited;
  final bool isSynced;
  final String? localPath;
  final String? thumbnailPath;
  final String? extraData;
final String? taskDatabase;
final String? taskStatus;
final String? taskDescription;
final String? assignedTo;
final String? assignedToName;
final String? priority;

final String? documentNo;
final String? documentType;
final String? companyName;
final String? receiverDatabase;
final String? receiverName;

  const ChatMessage({
    required this.chatId,
    required this.conversationId,
    required this.conversationType,
    required this.senderUserId,
    this.senderName,
    this.receiverId,
    this.senderPropertyCode,
    this.receiverPropertyCode,
    this.messageText,
    required this.messageType,
    this.documentId,
    this.taskId,
    required this.messageTime,
    this.isRead = false,
    this.status = MessageStatus.sent,
    this.isDeleted = false,
    this.isEdited = false,
    this.isSynced = true,
    this.localPath,
    this.thumbnailPath,
    this.extraData,
this.taskDatabase,
this.taskStatus,
this.taskDescription,
this.assignedTo,
this.assignedToName,
this.priority,
this.documentNo,
this.documentType,
this.companyName,
this.receiverDatabase,
this.receiverName,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      chatId: map['chatId'],
      conversationId: map['conversationId'],
      conversationType: map['conversationType'],
      senderUserId: map['senderUserId'],
      senderName: map['senderName'],
      receiverId: map['receiverId'],
      senderPropertyCode: map['senderPropertyCode'],
      receiverPropertyCode: map['receiverPropertyCode'],
      messageText: map['messageText'],
      messageType: map['messageType'],
      documentId: map['documentId'],
      taskId: map['taskId'],
      messageTime: map['messageTime'],
      isRead: map['isRead'] == 1,
      status: map['status'],
      isDeleted: map['isDeleted'] == 1,
      isEdited: map['isEdited'] == 1,
      isSynced: map['isSynced'] == 1,
      localPath: map['localPath'],
      thumbnailPath: map['thumbnailPath'],
      extraData: map['extraData'],
taskDatabase: map['TaskDatabase'],
taskStatus: map['TaskStatus'],
taskDescription: map['TaskDescription'],
assignedTo: map['AssignedTo'],
assignedToName: map['AssignedToName'],
priority: map['Priority'],
documentNo: map['DocumentNo'],
documentType: map['DocumentType'],
companyName: map['CompanyName'],
receiverDatabase: map['receiverDatabase'],
receiverName: map['receiverName'],
    );
  }

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'conversationId': conversationId,
        'conversationType': conversationType,
        'senderUserId': senderUserId,
        'senderName': senderName,
        'receiverId': receiverId,
        'senderPropertyCode': senderPropertyCode,
        'receiverPropertyCode': receiverPropertyCode,
        'messageText': messageText,
        'messageType': messageType,
        'documentId': documentId,
        'taskId': taskId,
        'messageTime': messageTime,
        'isRead': isRead ? 1 : 0,
        'status': status,
        'isDeleted': isDeleted ? 1 : 0,
        'isEdited': isEdited ? 1 : 0,
        'isSynced': isSynced ? 1 : 0,
        'localPath': localPath,
        'thumbnailPath': thumbnailPath,
        'extraData': extraData,
'taskDatabase': taskDatabase,
'taskStatus': taskStatus,
'taskDescription': taskDescription,
'assignedTo': assignedTo,
'assignedToName': assignedToName,
'priority': priority,
'documentNo': documentNo,
'documentType': documentType,
'companyName': companyName,
'receiverDatabase': receiverDatabase,
'receiverName': receiverName,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      ChatMessage.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

 ChatMessage copyWith({
  String? chatId,
  String? conversationId,
  String? conversationType,
  String? senderUserId,
  String? senderName,
  String? receiverId,
  String? senderPropertyCode,
  String? receiverPropertyCode,
  String? messageText,
  String? messageType,
  String? documentId,
  String? taskId,
  int? messageTime,
  bool? isRead,
  String? status,
  bool? isDeleted,
  bool? isEdited,
  bool? isSynced,
  String? localPath,
  String? thumbnailPath,
  String? extraData,

  // Task fields
  String? taskDatabase,
  String? taskStatus,
  String? taskDescription,
  String? assignedTo,
  String? assignedToName,
  String? priority,
  String? documentNo,
  String? documentType,
  String? companyName,

  // Chat fields
  String? receiverDatabase,
  String? receiverName,
}) {
  return ChatMessage(
    chatId: chatId ?? this.chatId,
    conversationId: conversationId ?? this.conversationId,
    conversationType: conversationType ?? this.conversationType,
    senderUserId: senderUserId ?? this.senderUserId,
    senderName: senderName ?? this.senderName,
    receiverId: receiverId ?? this.receiverId,
    senderPropertyCode:
        senderPropertyCode ?? this.senderPropertyCode,
    receiverPropertyCode:
        receiverPropertyCode ?? this.receiverPropertyCode,
    messageText: messageText ?? this.messageText,
    messageType: messageType ?? this.messageType,
    documentId: documentId ?? this.documentId,
    taskId: taskId ?? this.taskId,
    messageTime: messageTime ?? this.messageTime,
    isRead: isRead ?? this.isRead,
    status: status ?? this.status,
    isDeleted: isDeleted ?? this.isDeleted,
    isEdited: isEdited ?? this.isEdited,
    isSynced: isSynced ?? this.isSynced,
    localPath: localPath ?? this.localPath,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    extraData: extraData ?? this.extraData,

    taskDatabase: taskDatabase ?? this.taskDatabase,
    taskStatus: taskStatus ?? this.taskStatus,
    taskDescription:
        taskDescription ?? this.taskDescription,
    assignedTo: assignedTo ?? this.assignedTo,
    assignedToName:
        assignedToName ?? this.assignedToName,
    priority: priority ?? this.priority,
    documentNo: documentNo ?? this.documentNo,
    documentType: documentType ?? this.documentType,
    companyName: companyName ?? this.companyName,

    receiverDatabase:
        receiverDatabase ?? this.receiverDatabase,
    receiverName: receiverName ?? this.receiverName,
  );
}
}