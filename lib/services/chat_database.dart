import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/chat_message.dart';

/// ============================================================================
///  CHAT DATABASE — persistent chat history (SQLite)
/// ----------------------------------------------------------------------------
///  Persists every message locally so JARVIS remembers the conversation
///  across app restarts. Uses the native `sqflite` plugin on Android.
/// ============================================================================

class ChatDatabase {
  static const _dbName = 'jarvis_chat.db';
  static const _table = 'messages';

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id        TEXT PRIMARY KEY,
            text      TEXT NOT NULL,
            is_user   INTEGER NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Load all stored messages, oldest first.
  Future<List<ChatMessage>> loadMessages() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'timestamp ASC');
    return rows.map((row) {
      return ChatMessage.from(
        row['id'] as String,
        row['text'] as String,
        (row['is_user'] as int) == 1,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      );
    }).toList();
  }

  /// Insert (or replace) a message. Newer messages take priority.
  Future<void> upsert(ChatMessage message) async {
    final db = await _database;
    await db.insert(
      _table,
      {
        'id': message.id,
        'text': message.text,
        'is_user': message.isUser ? 1 : 0,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update just the text of an existing message (streaming replies).
  Future<void> updateText(String id, String text) async {
    final db = await _database;
    await db.update(
      _table,
      {'text': text},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Wipe all history.
  Future<void> clearAll() async {
    final db = await _database;
    await db.delete(_table);
  }

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }
}
