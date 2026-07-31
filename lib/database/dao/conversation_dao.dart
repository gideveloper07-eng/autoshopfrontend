import 'package:sqflite_sqlcipher/sqflite.dart';

import '../chat_database.dart';
import '../constants/db_constants.dart';
import '../models/conversation.dart';

class ConversationDao {
  ConversationDao._();

  static final ConversationDao instance = ConversationDao._();

  Future<Database> get _db async => ChatDatabase.instance.database;


Future<void> upsert(
    Conversation conversation) async {

    final db =
        await ChatDatabase.instance.database;

    await db.insert(
        "conversations",
        conversation.toMap(),
        conflictAlgorithm:
            ConflictAlgorithm.replace,
    );
}
  /// Insert multiple conversations
  Future<void> upsertAll(List<Conversation> conversations) async {
    if (conversations.isEmpty) return;

    final db = await _db;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final conversation in conversations) {
        batch.insert(
          DBConstants.conversations,
          conversation.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  /// Get all conversations
  Future<List<Conversation>> getAll() async {
    final db = await _db;

    final result = await db.query(
      DBConstants.conversations,
      where: 'isArchived = ?',
      whereArgs: [0],
      orderBy: 'isPinned DESC, lastMessageTime DESC',
    );

    return result.map(Conversation.fromMap).toList();
  }

  /// Get archived conversations
  Future<List<Conversation>> getArchived() async {
    final db = await _db;

    final result = await db.query(
      DBConstants.conversations,
      where: 'isArchived = ?',
      whereArgs: [1],
      orderBy: 'lastMessageTime DESC',
    );

    return result.map(Conversation.fromMap).toList();
  }


  /// Get one conversation
  Future<Conversation?> findById(String conversationId) async {
    final db = await _db;

    final result = await db.query(
      DBConstants.conversations,
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return Conversation.fromMap(result.first);
  }
Future<void> updateLastSyncTime(
  String conversationId,
  int syncTime,
) async {
  final db = await _db;

  await db.update(
    DBConstants.conversations,
    {
      'lastSyncTime': syncTime,
    },
    where: 'conversationId = ?',
    whereArgs: [conversationId],
  );
}

Future<bool> exists(
  String conversationId,
) async {
  final db = await _db;

  final result = await db.query(
    DBConstants.conversations,
    columns: ['conversationId'],
    where: 'conversationId=?',
    whereArgs: [conversationId],
    limit: 1,
  );

  return result.isNotEmpty;
}


  /// Update conversation
  Future<int> update(Conversation conversation) async {
    final db = await _db;

    return await db.update(
      DBConstants.conversations,
      conversation.toMap(),
      where: 'conversationId = ?',
      whereArgs: [conversation.conversationId],
    );
  }

  /// Delete conversation
  Future<int> delete(String conversationId) async {
    final db = await _db;

    return await db.delete(
      DBConstants.conversations,
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
  }

  /// Update last message
  Future<int> updateLastMessage({
    required String conversationId,
    required String lastMessage,
    required String messageType,
    required String senderId,
    required int messageTime,
  }) async {
    final db = await _db;

    return await db.update(
      DBConstants.conversations,
      {
        'lastMessage': lastMessage,
        'lastMessageType': messageType,
        'lastSenderId': senderId,
        'lastMessageTime': messageTime,
      },
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
  }

  /// Increase unread count
  Future<int> incrementUnread(String conversationId) async {
    final db = await _db;

    return await db.rawUpdate(
      '''
      UPDATE ${DBConstants.conversations}
      SET unreadCount = unreadCount + 1
      WHERE conversationId = ?
      ''',
      [conversationId],
    );
  }

  /// Reset unread count
  Future<int> resetUnread(String conversationId) async {
    final db = await _db;

    return await db.update(
      DBConstants.conversations,
      {
        'unreadCount': 0,
      },
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
  }

  /// Pin / Unpin
  Future<int> pinConversation(
      String conversationId,
      bool pinned,
      ) async {
    final db = await _db;

    return await db.update(
      DBConstants.conversations,
      {
        'isPinned': pinned ? 1 : 0,
      },
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
  }

  /// Archive / Unarchive
  Future<int> archiveConversation(
      String conversationId,
      bool archived,
      ) async {
    final db = await _db;

    return await db.update(
      DBConstants.conversations,
      {
        'isArchived': archived ? 1 : 0,
      },
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
  }

  /// Mute / Unmute
  Future<int> muteConversation(
      String conversationId,
      bool muted,
      ) async {
    final db = await _db;

    return await db.update(
      DBConstants.conversations,
      {
        'isMuted': muted ? 1 : 0,
      },
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
  }

  /// Save draft
  Future<int> saveDraft(
      String conversationId,
      String draft,
      ) async {
    final db = await _db;

    return await db.update(
      DBConstants.conversations,
      {
        'draftMessage': draft,
      },
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
  }

  /// Clear draft
  Future<int> clearDraft(String conversationId) async {
    final db = await _db;

    return await db.update(
      DBConstants.conversations,
      {
        'draftMessage': null,
      },
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
  }

  /// Total conversation count
  Future<int> count() async {
    final db = await _db;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM ${DBConstants.conversations}
        ''',
      ),
    );

    return result ?? 0;
  }
}