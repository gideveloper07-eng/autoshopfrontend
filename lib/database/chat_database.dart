import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'constants/db_constants.dart';
import 'tables/messages_table.dart';
import 'tables/conversations_table.dart';
import 'tables/documents_table.dart';
import 'tables/conversation_members_table.dart';

class ChatDatabase {
  ChatDatabase._internal();

  static final ChatDatabase instance = ChatDatabase._internal();

  static Database? _database;

  static const String _dbPassword =
      "MyAutoShop@2026#EncryptedDatabase";

Future<Database> get database async {
  debugPrint("DB GET 1");

  if (_database != null) {
    debugPrint("DB GET 2");
    return _database!;
  }

  debugPrint("DB GET 3");

  _database = await _initDatabase();

  debugPrint("DB GET 4");

  return _database!;
}


  Future<Database> _initDatabase() async {
  debugPrint("DB INIT 1");

  final directory = await getApplicationDocumentsDirectory();

  debugPrint("DB INIT 2: ${directory.path}");

  final path = join(directory.path, DBConstants.databaseName);

  debugPrint("DB INIT 3: $path");

  final db = await openDatabase(
    path,
    password: _dbPassword,
    version: DBConstants.databaseVersion,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
    onOpen: (db) async {
      debugPrint("Database Opened");
    },
  );

  debugPrint("DB INIT 4");

  return db;
}

  Future<void> _onCreate(Database db, int version) async {
    await MessagesTable.create(db);
    await ConversationsTable.create(db);
    await ConversationMembersTable.create(db);
    await DocumentsTable.create(db);

    debugPrint("Database Created");
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint("Migrating Database $oldVersion -> $newVersion");
  }

  Future<void> close() async {
    if (kIsWeb) return;

    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}