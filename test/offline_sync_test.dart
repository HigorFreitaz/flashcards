import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lume/app.dart';
import 'package:lume/data/repositories/user_repository.dart';
import 'package:lume/data/repositories/deck_repository.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lume/data/services/api_service.dart';
import 'package:lume/data/services/offline_api_service.dart';
import 'package:lume/data/services/offline_store.dart';
import 'package:lume/data/services/auth_service.dart';
import 'package:lume/data/services/session_store.dart';
import 'package:lume/models/app_user.dart';

class ToggleApi extends ApiService {
  ToggleApi({super.baseUrl});
  bool connected = true;
  bool loseResponse = false;
  bool unauthorized = false;
  final calls = <String>[];
  void check() {
    if (!connected) throw http.ClientException('Offline');
    if (unauthorized) throw ApiException(401, 'Expired');
  }

  @override
  Future<dynamic> get(String endpoint) async {
    check();
    return super.get(endpoint);
  }

  @override
  Future<dynamic> sendQueuedMutation(String method, String endpoint,
      Map<String, dynamic> body, String id) async {
    check();
    calls.add(id);
    final result = await super.sendQueuedMutation(method, endpoint, body, id);
    if (loseResponse) {
      connected = false;
      loseResponse = false;
      throw http.ClientException('Response lost');
    }
    return result;
  }
}

class LocalRemote extends ApiService {
  bool offline = true;
  bool unauthorized = false;
  int writes = 0;
  @override
  Future<dynamic> get(String endpoint) async {
    if (offline) throw http.ClientException('Offline');
    if (unauthorized) throw ApiException(401, 'Expired');
    if (endpoint == '/auth/me') {
      return {
        'user': {'id': 'alice', 'name': 'Alice', 'email': 'alice@test.local'}
      };
    }
    return <dynamic>[];
  }

  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async => {
        'token': 'alice-session',
        'user': {'id': 'alice', 'name': 'Alice', 'email': 'alice@test.local'}
      };
  @override
  Future<dynamic> sendQueuedMutation(
      String method, String path, Map<String, dynamic> body, String id) async {
    if (offline) throw http.ClientException('Offline');
    writes++;
    throw ApiException(404, 'Deleted remotely');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  sqfliteFfiInit();

  test(
      'SQLite persists snapshot and outbox together across reopening and isolates accounts',
      () async {
    final dir = await Directory.systemTemp.createTemp('lume-offline-test-');
    final dbPath = '${dir.path}/cache.db';
    var db = await databaseFactoryFfi.openDatabase(dbPath);
    var store = SqliteOfflineStore(database: db);
    final remote = LocalRemote()..authToken = 'alice-session';
    var api = OfflineApiService(remote, store, 'alice', automatic: false);
    final deck =
        await api.post('/decks', {'name': 'Offline deck', 'dailyGoal': 20});
    final card = await api.post(
        '/decks/${deck['id']}/cards', {'front': 'Question', 'back': 'Answer'});
    await api.post('/decks/${deck['id']}/cards/${card['id']}/review',
        {'correct': false, 'durationSeconds': 60});
    await api.synchronize();
    expect(api.status.pending, 3);
    expect(
        (await api.cachedDecks()).single['cards'].single['status'], 'aRevisar');
    api.dispose();
    await db.close();
    db = await databaseFactoryFfi.openDatabase(dbPath);
    store = SqliteOfflineStore(database: db);
    api = OfflineApiService(remote, store, 'alice', automatic: false);
    await api.synchronize();
    expect(api.status.pending, 3);
    expect((await api.cachedDecks()).single['name'], 'Offline deck');
    final bob = OfflineApiService(
        LocalRemote()..authToken = 'bob', store, 'bob',
        automatic: false);
    expect(await bob.cachedDecks(), isEmpty);
    await expectLater(api.post('/decks', {'name': ''}), throwsStateError);
    expect(api.status.pending, 3);
    remote.offline = false;
    await api.synchronize();
    expect(api.status.conflict, true);
    expect(api.status.pending, 3);
    expect((await api.cachedDecks()).length, 1);
    remote.offline = true;
    await expectLater(
        api.discardPending(), throwsA(isA<http.ClientException>()));
    expect(api.status.pending, 3);
    remote.offline = false;
    await api.discardPending();
    expect(api.status.pending, 0);
    expect(await api.cachedDecks(), isEmpty);
    api.dispose();
    bob.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  test(
      'cached identity allows offline reopen but never bypasses a rejected or expired session',
      () async {
    final store = MemorySessionStore();
    final remote = LocalRemote();
    final auth = AuthService(remote, sessionStore: store);
    await auth.login(
        AppUser.login(email: 'alice@test.local', password: 'password123'));
    expect((await AuthService(remote, sessionStore: store).restore())?.id,
        'alice');
    final cached = await store.readUser();
    cached!['offlineUntil'] =
        DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    await store.saveUser(cached);
    await expectLater(auth.restore(), throwsA(isA<http.ClientException>()));
    remote.offline = false;
    remote.unauthorized = true;
    expect(await auth.restore(), isNull);
    expect(await store.readUser(), isNull);
    expect(await store.read(), isNull);
  });

  testWidgets(
      'app exposes pending offline writes and clears the account scope on logout',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final remote = LocalRemote();
    final store = MemoryOfflineStore();
    await tester.pumpWidget(LumeApp(apiService: remote, offlineStore: store));
    await tester.pumpAndSettle();
    final users =
        tester.element(find.byType(MaterialApp)).read<UserRepository>();
    await users.login('alice', 'password');
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(MaterialApp));
    final repository = context.read<DeckRepository>();
    final api = context.read<ApiService>();
    expect(api, isA<OfflineApiService>());
    await repository.createDeck(name: 'Saved offline');
    await tester.pumpAndSettle();
    expect(repository.decks.single.name, 'Saved offline');
    expect(
        find.text('1 alterações salvas no aparelho, aguardando sincronização.'),
        findsOneWidget);
    await users.logout();
    await tester.pumpAndSettle();
    expect(find.text('Entrar na sua conta'), findsOneWidget);
    await expectLater(api.get('/decks'), throwsStateError);
    expect((await store.read('alice'))!['queue'], hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  final liveUrl = Platform.environment['LUME_TEST_API'];
  test(
      'SQLite outbox reconnects to PostgreSQL without duplicates after losing a response',
      () async {
    final remote = ToggleApi(baseUrl: liveUrl);
    final signup = await remote.post('/auth/signup', {
      'name': 'Offline integration',
      'email': 'offline-${DateTime.now().microsecondsSinceEpoch}@test.invalid',
      'password': 'test-only123'
    });
    remote.authToken = signup['token'];
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    final store = SqliteOfflineStore(database: db);
    var api = OfflineApiService(remote, store, signup['user']['id'],
        automatic: false);
    try {
      await api.synchronize();
      remote.connected = false;
      final deck = await api.post('/decks', {'name': 'Created offline'});
      final second = await api.post('/decks', {'name': 'Target'});
      final card = await api
          .post('/decks/${deck['id']}/cards', {'front': 'Q', 'back': 'A'});
      await api.put('/decks/${deck['id']}/cards/${card['id']}',
          {'front': 'Edited', 'targetDeckId': second['id']});
      await api.post('/decks/${second['id']}/cards/${card['id']}/review',
          {'correct': true, 'durationSeconds': 60});
      await api.synchronize();
      expect(api.status.pending, 5);
      remote.connected = true;
      remote.loseResponse = true;
      await api.synchronize();
      expect(api.status.pending, 5);
      api.dispose();
      api = OfflineApiService(remote, store, signup['user']['id'],
          automatic: false);
      remote.connected = true;
      await api.synchronize();
      expect(api.status.error, isNull);
      expect(api.status.pending, 0);
      final decks = await remote.get('/decks') as List;
      expect(decks.length, 2);
      expect(
          decks
              .firstWhere((d) => d['id'] == second['id'])['cards']
              .single['front'],
          'Edited');
      expect((await remote.get('/progress'))['totalXp'], 10);
      remote.connected = false;
      await api.put(
          '/decks/${second['id']}/cards/${card['id']}', {'suspended': true});
      await api.delete('/decks/${deck['id']}');
      await api.synchronize();
      remote.connected = true;
      await api.synchronize();
      expect(api.status.pending, 0);
      expect(
          (await remote.get('/decks') as List)
              .single['cards']
              .single['suspended'],
          true);
      remote.connected = false;
      await api.put('/decks/${second['id']}', {'name': 'Pending edit'});
      await api.synchronize();
      remote.connected = true;
      await remote.delete('/decks/${second['id']}');
      await api.synchronize();
      expect(api.status.conflict, true);
      expect(api.status.pending, 1);
      await api.discardPending();
      expect(await api.cachedDecks(), isEmpty);
    } finally {
      await api.synchronize();
      api.dispose();
      remote.connected = true;
      await remote.delete('/auth/account');
      await db.close();
    }
  },
      skip: liveUrl == null
          ? 'Set LUME_TEST_API to a disposable test API'
          : false);
}
