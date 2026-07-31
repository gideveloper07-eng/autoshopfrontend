import 'package:sqflite_sqlcipher/sqflite.dart';

import '../constants/db_constants.dart';

class ConversationsTable {
  ConversationsTable._();

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE ${DBConstants.conversations} (

        conversationId TEXT PRIMARY KEY,

        conversationType TEXT NOT NULL,

        title TEXT,

        databaseName TEXT,
        propertyCode TEXT,
        clientId TEXT,

        lastMessage TEXT,

        lastMessageType TEXT,

        lastSenderId TEXT,

        lastMessageTime INTEGER,

        unreadCount INTEGER NOT NULL DEFAULT 0,

        isPinned INTEGER NOT NULL DEFAULT 0,

        isMuted INTEGER NOT NULL DEFAULT 0,

        isArchived INTEGER NOT NULL DEFAULT 0,

        draftMessage TEXT,

        lastSyncTime INTEGER,

        avatar TEXT
      )
    ''');

    //-----------------------------------------
    // Indexes
    //-----------------------------------------

    await db.execute('''
      CREATE INDEX idx_conversation_last_message_time
      ON ${DBConstants.conversations}(lastMessageTime)
    ''');

    await db.execute('''
      CREATE INDEX idx_conversation_unread
      ON ${DBConstants.conversations}(unreadCount)
    ''');

    await db.execute('''
      CREATE INDEX idx_conversation_archived
      ON ${DBConstants.conversations}(isArchived)
    ''');

    await db.execute('''
      CREATE INDEX idx_conversation_pinned
      ON ${DBConstants.conversations}(isPinned)
    ''');
  }
}