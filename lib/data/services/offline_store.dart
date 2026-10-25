import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

abstract class OfflineStore {
  Future<Map<String, dynamic>?> read(String userId);
  Future<void> write(String userId, Map<String, dynamic> state);
}

class SqliteOfflineStore implements OfflineStore {
  SqliteOfflineStore({Database? database}) : _injected = database;
  final Database? _injected;
  Future<Database>? _opening;
  Future<Database> _db() => _opening ??= _open();
  Future<Database> _open() async {
    final db = _injected ??
        await openDatabase(
            path.join(await getDatabasesPath(), 'lume_offline.db'),
            version: 1);
    await db.execute('CREATE TABLE IF NOT EXISTS accounts '
        '(user_id TEXT PRIMARY KEY, state TEXT NOT NULL)');
    return db;
  }

  @override
  Future<Map<String, dynamic>?> read(String userId) async {
    final rows = await (await _db())
        .query('accounts', where: 'user_id = ?', whereArgs: [userId]);
    return rows.isEmpty
        ? null
        : jsonDecode(rows.single['state'] as String) as Map<String, dynamic>;
  }

  @override
  Future<void> write(String userId, Map<String, dynamic> state) async {
    // One SQLite transaction persists both the visible snapshot and its outbox.
    await (await _db()).transaction((txn) => txn.insert(
        'accounts', {'user_id': userId, 'state': jsonEncode(state)},
        conflictAlgorithm: ConflictAlgorithm.replace));
  }
}

class MemoryOfflineStore implements OfflineStore {
  final _states = <String, String>{};
  @override
  Future<Map<String, dynamic>?> read(String userId) async =>
      _states[userId] == null
          ? null
          : jsonDecode(_states[userId]!) as Map<String, dynamic>;
  @override
  Future<void> write(String userId, Map<String, dynamic> state) async {
    _states[userId] = jsonEncode(state);
  }
}
