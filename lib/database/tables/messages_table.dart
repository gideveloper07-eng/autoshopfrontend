import 'package:sqflite_sqlcipher/sqflite.dart';

import '../constants/db_constants.dart';

class MessagesTable {
  MessagesTable._();

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE ${DBConstants.messages} (

        chatId TEXT PRIMARY KEY,

        conversationId TEXT NOT NULL,
        conversationType TEXT NOT NULL,

        senderUserId TEXT NOT NULL,
        senderName TEXT,

        receiverId TEXT,

        senderPropertyCode TEXT,
        receiverPropertyCode TEXT,

        messageText TEXT,

        messageType TEXT NOT NULL,

        documentId TEXT,
        taskId TEXT,

        messageTime INTEGER NOT NULL,

        isRead INTEGER NOT NULL DEFAULT 0,

        status TEXT NOT NULL DEFAULT 'sent',

        isDeleted INTEGER NOT NULL DEFAULT 0,

        isEdited INTEGER NOT NULL DEFAULT 0,

        isSynced INTEGER NOT NULL DEFAULT 1,

        localPath TEXT,

        thumbnailPath TEXT,

        extraData TEXT,

        -- Task fields
        taskDatabase TEXT,
        taskStatus TEXT,
        taskDescription TEXT,
        assignedTo TEXT,
        assignedToName TEXT,
        priority TEXT,

        -- Document fields
        documentNo TEXT,
        documentType TEXT,
        companyName TEXT,

        -- Receiver information
        receiverDatabase TEXT,
        receiverName TEXT
      )
    ''');

    //-----------------------------------------
    // Performance Indexes
    //-----------------------------------------

    await db.execute('''
      CREATE INDEX idx_messages_conversation
      ON ${DBConstants.messages}(conversationId)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_time
      ON ${DBConstants.messages}(messageTime)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_sender
      ON ${DBConstants.messages}(senderUserId)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_receiver
      ON ${DBConstants.messages}(receiverId)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_synced
      ON ${DBConstants.messages}(isSynced)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_status
      ON ${DBConstants.messages}(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_receiver_db
      ON ${DBConstants.messages}(receiverDatabase)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_document
      ON ${DBConstants.messages}(documentId)
    ''');
  }
}