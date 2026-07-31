import 'package:sqflite_sqlcipher/sqflite.dart';

import '../constants/db_constants.dart';

class DocumentsTable {
  DocumentsTable._();

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE ${DBConstants.documents} (

        documentId TEXT PRIMARY KEY,

        chatId TEXT NOT NULL,

        fileName TEXT,

        fileExtension TEXT,

        mimeType TEXT,

        serverPath TEXT,

        localPath TEXT,

        thumbnailPath TEXT,

        fileSize INTEGER,

        uploadedBy TEXT,

        uploadedAt INTEGER,

        downloadStatus TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_document_chat
      ON ${DBConstants.documents}(chatId)
    ''');

    await db.execute('''
      CREATE INDEX idx_document_download
      ON ${DBConstants.documents}(downloadStatus)
    ''');
  }
}