import 'package:sqflite_sqlcipher/sqflite.dart';

import '../constants/db_constants.dart';

class ConversationMembersTable {
  ConversationMembersTable._();

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE ${DBConstants.conversationMembers} (

        id INTEGER PRIMARY KEY AUTOINCREMENT,

        conversationId TEXT NOT NULL,

        userId TEXT NOT NULL,

        userName TEXT,

        propertyCode TEXT,

        role TEXT DEFAULT 'member',

        joinedAt INTEGER,

        leftAt INTEGER,

        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    //-----------------------------------------
    // Indexes
    //-----------------------------------------

    await db.execute('''
      CREATE INDEX idx_members_conversation
      ON ${DBConstants.conversationMembers}(conversationId)
    ''');

    await db.execute('''
      CREATE INDEX idx_members_user
      ON ${DBConstants.conversationMembers}(userId)
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_members_unique
      ON ${DBConstants.conversationMembers}
      (conversationId,userId)
    ''');
  }
}