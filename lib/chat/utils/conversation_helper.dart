class ConversationHelper {
  ConversationHelper._();

  static String directConversationId({
    required String databaseName,
    required String userId,
    required String propertyCode,
  }) {
    return [
      databaseName.trim().toUpperCase(),
      userId.trim().toUpperCase(),
      propertyCode.trim().toUpperCase(),
    ].join("_");
  }
}