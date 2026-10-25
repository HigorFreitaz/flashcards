import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

abstract class SessionStore {
  Future<String?> read();
  Future<void> save(String token);
  Future<void> clear();
  Future<Map<String, dynamic>?> readUser();
  Future<void> saveUser(Map<String, dynamic> user);
}

class MemorySessionStore implements SessionStore {
  String? token;
  Map<String, dynamic>? user;
  @override
  Future<Map<String, dynamic>?> readUser() async => user;
  @override
  Future<void> saveUser(Map<String, dynamic> value) async {
    user = value;
  }

  @override
  Future<String?> read() async => token;
  @override
  Future<void> save(String value) async {
    token = value;
    user = null;
  }

  @override
  Future<void> clear() async {
    token = null;
    user = null;
  }
}

class SqliteSessionStore implements SessionStore {
  @override
  Future<Map<String, dynamic>?> readUser() async {
    final rows = await (await _database())
        .query('session', where: 'id = ?', whereArgs: [1]);
    final profile = rows.isEmpty ? null : rows.first['profile'] as String?;
    return profile == null ? null : jsonDecode(profile) as Map<String, dynamic>;
  }

  @override
  Future<void> saveUser(Map<String, dynamic> user) async {
    await (await _database()).update('session', {'profile': jsonEncode(user)},
        where: 'id = ?', whereArgs: [1]);
  }

  Future<Database> _database() async => openDatabase(
      path.join(await getDatabasesPath(), 'lume_session.db'),
      version: 2,
      onUpgrade: (db, old, version) async {
        if (old < 2) {
          await db.execute('ALTER TABLE session ADD COLUMN profile TEXT');
        }
      },
      onCreate: (db, _) => db.execute(
          'CREATE TABLE session (id INTEGER PRIMARY KEY, token TEXT NOT NULL, profile TEXT)'));
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
