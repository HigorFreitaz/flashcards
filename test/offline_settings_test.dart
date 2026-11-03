import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/data/services/api_service.dart';
import 'package:lume/data/services/offline_api_service.dart';
import 'package:lume/data/services/offline_store.dart';

class SlowServer extends ApiService {
  final gate = Completer<void>();
  final writes = <Map<String, dynamic>>[];
  @override
  Future<dynamic> sendQueuedMutation(
      String method, String path, Map<String, dynamic> body, String id) async {
    await gate.future;
    writes.add(body);
    return body;
  }

  @override
  Future<dynamic> get(String endpoint) async {
    await gate.future;
    if (endpoint == '/settings') return {'themeMode': 'dark'};
    if (endpoint == '/challenges') return {'history': []};
    if (endpoint == '/progress') return <String, dynamic>{};
    return <dynamic>[];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('theme is durable and local edits do not wait for stalled network',
      () async {
    final remote = SlowServer()..authToken = 'session';
    final store = MemoryOfflineStore();
    final api = OfflineApiService(remote, store, 'alice', automatic: false);
    final sync = api.synchronize();
    await api.put(
        '/settings', {'themeMode': 'dark'}).timeout(const Duration(seconds: 1));
    await api.post(
        '/decks', {'name': 'Offline'}).timeout(const Duration(seconds: 1));
    expect((await api.get('/settings'))['themeMode'], 'dark');
    expect((await store.read('alice'))!['queue'], hasLength(2));
    final reopened =
        OfflineApiService(remote, store, 'alice', automatic: false);
    expect((await reopened.get('/settings'))['themeMode'], 'dark');
    reopened.dispose();
    remote.gate.complete();
    await sync;
    // A fetch started before the edit cannot overwrite the local theme/deck.
    expect((await api.get('/settings'))['themeMode'], 'dark');
    if (api.status.pending > 0) await api.synchronize();
    expect(api.status.pending, 0);
    expect(remote.writes.first['themeMode'], 'dark');
    api.dispose();
  });
}
