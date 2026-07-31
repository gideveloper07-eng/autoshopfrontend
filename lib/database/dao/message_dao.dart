import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../chat_database.dart';
import '../constants/db_constants.dart';
import '../models/chat_message.dart';

class MessageDao {
  MessageDao._();

  static final MessageDao instance = MessageDao._();

  Future<Database> get _db async => ChatDatabase.instance.database;


Future<void> upsert(ChatMessage message) async {
  final db = await ChatDatabase.instance.database;

  final sw = Stopwatch()..start();

  try {
    print("INSERT START");

    final map = message.toMap();
map['chatId'] = map['chatId'].toString().toLowerCase();

final id=await db.insert(
  DBConstants.messages,
  map,
  conflictAlgorithm: ConflictAlgorithm.replace,
);

    print("INSERT FINISHED: $id");
  } catch (e, st) {
    print("INSERT EXCEPTION");
    print(e);
    print(st);
  } finally {
    print("INSERT TIME = ${sw.elapsedMilliseconds} ms");
  }
}
Future<List<ChatMessage>> getPendingSyncMessages() async {
  final db = await _db;

  final rows = await db.query(
    DBConstants.messages,
    where: 'isSynced = ?',
    whereArgs: [0],
    orderBy: 'messageTime ASC',
  );

  return rows.map(ChatMessage.fromMap).toList();
}

Future<void> upsertAll(
  List<ChatMessage> messages,
) async {
  if (messages.isEmpty) return;

  final db = await _db;

  await db.transaction((txn) async {
    final batch = txn.batch();

    for (final message in messages) {
      final map = message.toMap();
      map['chatId'] = map['chatId'].toString().toLowerCase();

      // Query using the SAME transaction
      final existing = await txn.query(
        DBConstants.messages,
        columns: ['messageTime'],
        where: 'chatId = ?',
        whereArgs: [message.chatId.toLowerCase()],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        map['messageTime'] = existing.first['messageTime'];
      }

      batch.insert(
        DBConstants.messages,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  });
}

  /// Get all messages of a conversation
  Future<List<ChatMessage>> getConversationMessages(
    String conversationId,
  ) async {
    final db = await _db;

final rows = await db.query(
  DBConstants.messages,
  where: "conversationId=?",
  whereArgs: [conversationId],
);

for (final r in rows) {
  print(
      "DB -> ${r['chatId']} | ${r['messageText']} | ${r['messageTime']}");
}

    final result = await db.query(
      DBConstants.messages,
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'messageTime ASC',
    );

    return result.map(ChatMessage.fromMap).toList();
  }

  /// Get latest message
  Future<ChatMessage?> getLatestMessage(
    String conversationId,
  ) async {
    final db = await _db;

    final result = await db.query(
      DBConstants.messages,
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'messageTime DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return ChatMessage.fromMap(result.first);
  }

  /// Get message by ChatId
  Future<ChatMessage?> findById(String chatId) async {
    final db = await _db;

    final result = await db.query(
      DBConstants.messages,
      where: 'chatId = ?',
      whereArgs: [chatId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return ChatMessage.fromMap(result.first);
  }

  /// Update message
  Future<int> update(ChatMessage message) async {
    final db = await _db;

    return await db.update(
      DBConstants.messages,
      message.toMap(),
      where: 'chatId = ?',
      whereArgs: [message.chatId],
    );
  }

  /// Delete message
  Future<int> delete(String chatId) async {
    final db = await _db;

    return await db.delete(
      DBConstants.messages,
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  /// Soft delete
  Future<int> softDelete(String chatId) async {
    final db = await _db;

    return await db.update(
      DBConstants.messages,
      {
        'isDeleted': 1,
      },
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  /// Mark conversation as read
  Future<int> markConversationRead(
    String conversationId,
  ) async {
    final db = await _db;

    return await db.update(
      DBConstants.messages,
      {
        'isRead': 1,
      },
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
  }

  /// Pending Sync
  Future<List<ChatMessage>> getUnsyncedMessages() async {
    final db = await _db;

    final result = await db.query(
      DBConstants.messages,
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'messageTime ASC',
    );

    return result.map(ChatMessage.fromMap).toList();
  }
Future<bool> exists(
    String chatId) async {

  final db = await _db;

  final result = await db.query(
    DBConstants.messages,
    columns: ['chatId'],
    where: 'chatId=?',
    whereArgs: [chatId],
    limit: 1,
  );

  return result.isNotEmpty;
}

  /// Search Messages
  Future<List<ChatMessage>> searchMessages(
    String keyword,
  ) async {
    final db = await _db;

    final result = await db.query(
      DBConstants.messages,
      where: 'messageText LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'messageTime DESC',
    );

    return result.map(ChatMessage.fromMap).toList();
  }

  /// Clear conversation
  Future<int> clearConversation(
    String conversationId,
  ) async {
    final db = await _db;

    return await db.delete(
      DBConstants.messages,
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
  }

  /// Count unread messages
  Future<int> unreadCount(
    String conversationId,
  ) async {
    final db = await _db;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM ${DBConstants.messages}
        WHERE conversationId = ?
        AND isRead = 0
        ''',
        [conversationId],
      ),
    );

    return result ?? 0;
  }

  /// Total messages in conversation
  Future<int> messageCount(
    String conversationId,
  ) async {
    final db = await _db;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM ${DBConstants.messages}
        WHERE conversationId = ?
        ''',
        [conversationId],
      ),
    );

    return result ?? 0;
  }
}