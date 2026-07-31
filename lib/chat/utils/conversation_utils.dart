class ConversationUtils {
  ConversationUtils._();

  /// Direct Chat
  static String directConversationId({
    required String receiverId,
    required String receiverPropertyCode,
  }) {
    return "DM_${receiverPropertyCode.trim()}_${receiverId.trim()}";
  }

  /// Group Chat
  static String groupConversationId(String groupId) {
    return "GROUP_${groupId.trim()}";
  }

  /// Challan Chat
  static String challanConversationId(String challanId) {
    return "CHALLAN_${challanId.trim()}";
  }
}