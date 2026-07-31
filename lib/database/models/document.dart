import '../constants/db_enums.dart';

class ChatDocument {
  final String documentId;
  final String chatId;
  final String? fileName;
  final String? fileExtension;
  final String? mimeType;
  final String? serverPath;
  final String? localPath;
  final String? thumbnailPath;
  final int? fileSize;
  final String? uploadedBy;
  final int? uploadedAt;
  final String downloadStatus;

  const ChatDocument({
    required this.documentId,
    required this.chatId,
    this.fileName,
    this.fileExtension,
    this.mimeType,
    this.serverPath,
    this.localPath,
    this.thumbnailPath,
    this.fileSize,
    this.uploadedBy,
    this.uploadedAt,
    this.downloadStatus = DownloadStatus.pending,
  });

  factory ChatDocument.fromMap(Map<String, dynamic> map) {
    return ChatDocument(
      documentId: map['documentId'],
      chatId: map['chatId'],
      fileName: map['fileName'],
      fileExtension: map['fileExtension'],
      mimeType: map['mimeType'],
      serverPath: map['serverPath'],
      localPath: map['localPath'],
      thumbnailPath: map['thumbnailPath'],
      fileSize: map['fileSize'],
      uploadedBy: map['uploadedBy'],
      uploadedAt: map['uploadedAt'],
      downloadStatus: map['downloadStatus'],
    );
  }

  Map<String, dynamic> toMap() => {
        'documentId': documentId,
        'chatId': chatId,
        'fileName': fileName,
        'fileExtension': fileExtension,
        'mimeType': mimeType,
        'serverPath': serverPath,
        'localPath': localPath,
        'thumbnailPath': thumbnailPath,
        'fileSize': fileSize,
        'uploadedBy': uploadedBy,
        'uploadedAt': uploadedAt,
        'downloadStatus': downloadStatus,
      };
}