import '../constants/db_enums.dart';

class ConversationMember {
  final int? id;
  final String conversationId;
  final String userId;
  final String? userName;
  final String? propertyCode;
  final String role;
  final int? joinedAt;
  final int? leftAt;
  final bool isActive;

  const ConversationMember({
    this.id,
    required this.conversationId,
    required this.userId,
    this.userName,
    this.propertyCode,
    this.role = MemberRole.member,
    this.joinedAt,
    this.leftAt,
    this.isActive = true,
  });

  factory ConversationMember.fromMap(Map<String, dynamic> map) {
    return ConversationMember(
      id: map['id'],
      conversationId: map['conversationId'],
      userId: map['userId'],
      userName: map['userName'],
      propertyCode: map['propertyCode'],
      role: map['role'],
      joinedAt: map['joinedAt'],
      leftAt: map['leftAt'],
      isActive: map['isActive'] == 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversationId': conversationId,
        'userId': userId,
        'userName': userName,
        'propertyCode': propertyCode,
        'role': role,
        'joinedAt': joinedAt,
        'leftAt': leftAt,
        'isActive': isActive ? 1 : 0,
      };
}