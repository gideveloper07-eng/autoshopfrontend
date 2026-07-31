class ConversationType {
  ConversationType._();

  static const String direct = 'DIRECT';
  static const String group = 'GROUP';
  static const String challan = 'CHALLAN';
}

class MessageType {
  MessageType._();

  static const String text = 'TEXT';
  static const String image = 'IMAGE';
  static const String video = 'VIDEO';
  static const String audio = 'AUDIO';
  static const String document = 'DOCUMENT';
  static const String task = 'TASK';
}

class MessageStatus {
  MessageStatus._();

  static const String sending = 'sending';
  static const String sent = 'sent';
  static const String delivered = 'delivered';
  static const String read = 'read';
  static const String failed = 'failed';
}

class MemberRole {
  MemberRole._();

  static const String admin = 'admin';
  static const String member = 'member';
}

class DownloadStatus {
  DownloadStatus._();

  static const String pending = 'pending';
  static const String downloading = 'downloading';
  static const String downloaded = 'downloaded';
  static const String failed = 'failed';
}