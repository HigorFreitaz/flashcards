import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

abstract class SessionStore {
  Future<String?> read();
  Future<void> save(String token);
  Future<void> clear();
}

class MemorySessionStore implements SessionStore {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> save(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

class SqliteSessionStore implements SessionStore {
  Future<Database> _database() async => openDatabase(
      path.join(await getDatabasesPath(), 'lume_session.db'),
      version: 1,
      onCreate: (db, _) => db.execute(
          'CREATE TABLE session (id INTEGER PRIMARY KEY, token TEXT NOT NULL)'));
  @override
  Future<String?> read() async {
    final db = await _database();
    final rows = await db.query('session', where: 'id = ?', whereArgs: [1]);
    return rows.isEmpty ? null : rows.first['token'] as String;
  }

  @override
  Future<void> save(String token) async {
    final db = await _database();
    await db.insert('session', {'id': 1, 'token': token},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> clear() async {
    final db = await _database();
    await db.delete('session');
  }
}
