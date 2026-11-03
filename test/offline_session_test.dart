import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/data/repositories/user_repository.dart';
import 'package:lume/data/services/api_service.dart';
import 'package:lume/data/services/auth_service.dart';
import 'package:lume/data/services/session_store.dart';
import 'package:lume/models/app_user.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SessionApi extends ApiService {
  final validation = Completer<dynamic>();
  final requested = Completer<void>();
  @override
  Future<dynamic> get(String endpoint) {
    requested.complete();
    return validation.future;
  }

  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async => {
        'token': 'test-session',
        'user': {'id': 'alice', 'name': 'Alice', 'email': 'alice@test.local'}
      };
}

Future<void> seed(AuthService auth) async {
  await auth.login(AppUser.login(email: 'alice@test.local', password: 'test'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SQLite session reopens immediately while offline validation is pending',
      () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('lume-session-');
    final previousPath = await getDatabasesPath();
    await databaseFactory.setDatabasesPath(dir.path);
    try {
      await seed(AuthService(SessionApi(), sessionStore: SqliteSessionStore()));
      final db = await openDatabase('${dir.path}/lume_session.db');
      await db.close();
      final api = SessionApi();
      final repository =
          UserRepository(AuthService(api, sessionStore: SqliteSessionStore()));
      final restoring = repository.restore();
      await api.requested.future;
      expect(repository.restoring, isFalse);
      expect(repository.currentUser?.id, 'alice');
      api.validation.completeError(const SocketException('No network'));
      await restoring;
      expect(repository.currentUser?.id, 'alice');
      expect(repository.restoreError, isNull);
      repository.dispose();
      await (await openDatabase('${dir.path}/lume_session.db')).close();
    } finally {
      await databaseFactory.setDatabasesPath(previousPath);
      await dir.delete(recursive: true);
    }
  });

  test('server rejection clears an immediately restored cached session',
      () async {
    final api = SessionApi();
    final store = MemorySessionStore();
    final auth = AuthService(api, sessionStore: store);
    await seed(auth);
    final repository = UserRepository(auth);
    final restoring = repository.restore();
    await api.requested.future;
    expect(repository.currentUser?.id, 'alice');
    api.validation.completeError(ApiException(401, 'Expired'));
    await restoring;
    expect(repository.currentUser, isNull);
    expect(await store.read(), isNull);
    repository.dispose();
  });

  test('late validation cannot restore a logged out session', () async {
    final api = SessionApi();
    final store = MemorySessionStore();
    final auth = AuthService(api, sessionStore: store);
    await seed(auth);
    final repository = UserRepository(auth);
    final restoring = repository.restore();
    await api.requested.future;
    await repository.logout();
    api.validation.complete({
      'user': {'id': 'alice', 'name': 'Alice', 'email': 'alice@test.local'}
    });
    await restoring;
    expect(repository.currentUser, isNull);
    expect(await store.readUser(), isNull);
    expect(api.authToken, isNull);
    repository.dispose();
  });
}

