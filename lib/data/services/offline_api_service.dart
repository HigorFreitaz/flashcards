import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'api_service.dart';
import 'offline_store.dart';

class SyncStatus extends ChangeNotifier {
  int pending = 0;
  int revision = 0;
  bool offline = false;
  bool syncing = false;
  String? error;
  bool conflict = false;
  void changed() => notifyListeners();
}

/// Account-scoped durable cache/outbox. Remote PostgreSQL remains authoritative.
/// Pending writes are replayed FIFO, then replaced by the server's snapshot.
class OfflineApiService extends ApiService with WidgetsBindingObserver {
  OfflineApiService(this.remote, this.store, this.userId,
      {bool automatic = true})
      : _sessionToken = remote.authToken {
    if (automatic) {
      WidgetsBinding.instance.addObserver(this);
      _timer =
          Timer.periodic(const Duration(seconds: 30), (_) => synchronize());
    }
  }
  final ApiService remote;
  final OfflineStore store;
  final String userId;
  final String? _sessionToken;
  final status = SyncStatus();
  Timer? _timer;
  bool _disposed = false;
  Future<void> _tail = Future.value();
  Map<String, dynamic>? _state;
  final _random = Random.secure();
  String _id() => List.generate(
      16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  @override
  String? get authToken => remote.authToken;
  @override
  set authToken(String? value) => remote.authToken = value;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(synchronize());
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // In-flight work checks _disposed before publishing any updates.
    status.dispose();
  }

  void _notify() {
    if (!_disposed) status.changed();
  }

  Future<T> _exclusive<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _load() async {
    _state ??= await store.read(userId) ??
        {
          'decks': <dynamic>[],
          'queue': <dynamic>[],
          'reads': <String, dynamic>{}
        };
    status.pending = (_state!['queue'] as List).length;
  }

  dynamic _copy(dynamic value) => jsonDecode(jsonEncode(value));
  Future<void> _save(Map<String, dynamic> next) async {
    await store.write(userId, next);
    _state = next;
    status.pending = (next['queue'] as List).length;
  }

  @override
  Future<dynamic> get(String endpoint) async {
    _assertActive();
    if (endpoint == '/decks') {
      final result = await _exclusive(() async {
        await _load();
        return _copy(_state!['decks']);
      });
      unawaited(synchronize());
      return result;
    }
    try {
      final value = await remote.get(endpoint);
      await _exclusive(() async {
        await _load();
        final next = _copy(_state) as Map<String, dynamic>;
        next['reads'][endpoint] = value;
        await _save(next);
      });
      return value;
    } catch (error) {
      if (!isConnectionFailure(error)) rethrow;
      return _exclusive(() async {
        await _load();
        status.offline = true;
        _notify();
        if ((_state!['reads'] as Map).containsKey(endpoint)) {
          return _copy(_state!['reads'][endpoint]);
        }
        rethrowError(error);
      });
    }
  }

  Never rethrowError(Object error) => throw error;

  Future<void> synchronize() => _exclusive(() async {
        if (_disposed ||
            remote.authToken != _sessionToken ||
            _sessionToken == null) {
          return;
        }
        await _load();
        if (status.conflict) return;
        status.syncing = true;
        _notify();
        try {
          while ((_state!['queue'] as List).isNotEmpty) {
            if (_disposed || remote.authToken != _sessionToken) return;
            final operation = (_state!['queue'] as List).first as Map;
            await remote.sendQueuedMutation(
                operation['method'],
                operation['path'],
                Map<String, dynamic>.from(operation['body']),
                operation['id']);
            final next = _copy(_state) as Map<String, dynamic>;
            (next['queue'] as List).removeAt(0);
            await _save(next);
          }
          if (_disposed || remote.authToken != _sessionToken) return;
          final decks = await remote.get('/decks');
          final next = _copy(_state) as Map<String, dynamic>;
          next['decks'] = decks;
          await _save(next);
          status.offline = false;
          status.error = null;
          status.revision++;
        } catch (error) {
          status.offline = isConnectionFailure(error);
          status.conflict = error is ApiException &&
              [400, 403, 404, 409, 413].contains(error.statusCode);
          status.error = error is ApiException && error.statusCode == 401
              ? 'Sessão expirada. Entre novamente; as alterações locais serão mantidas.'
              : status.conflict
                  ? 'Sincronização interrompida: $error. As alterações estão salvas neste aparelho.'
                  : status.offline
                      ? null
                      : 'Não foi possível sincronizar: $error';
        } finally {
          status.syncing = false;
          _notify();
        }
      });

  Future<List<dynamic>> cachedDecks() => _exclusive(() async {
        await _load();
        return _copy(_state!['decks']) as List;
      });

  /// Called only after an explicit user confirmation. Fetch first so a network
  /// failure never destroys the only local copy of unsynchronized work.
  Future<void> discardPending() => _exclusive(() async {
        _assertActive();
        final decks = await remote.get('/decks');
        await _load();
        final next = _copy(_state) as Map<String, dynamic>;
        next['decks'] = decks;
        next['queue'] = <dynamic>[];
        await _save(next);
        status.conflict = false;
        status.error = null;
        status.offline = false;
        _notify();
      });

  void _assertActive() {
    if (_disposed ||
        remote.authToken != _sessionToken ||
        _sessionToken == null) {
      throw StateError('Entre novamente.');
    }
  }

  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    _assertActive();
    return endpoint.startsWith('/decks')
        ? _mutate('POST', endpoint, body)
        : remote.post(endpoint, body);
  }

  @override
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    _assertActive();
    return endpoint.startsWith('/decks')
        ? _mutate('PUT', endpoint, body)
        : remote.put(endpoint, body);
  }

  @override
  Future<dynamic> delete(String endpoint) async {
    _assertActive();
    return endpoint.startsWith('/decks')
        ? _mutate('DELETE', endpoint, {})
        : remote.delete(endpoint);
  }

  Future<dynamic> _mutate(
      String method, String endpoint, Map<String, dynamic> body) async {
    if (endpoint.endsWith('/review') && body['challengeId'] != null) {
      await synchronize();
      if (status.pending > 0 || status.offline || status.error != null) {
        throw StateError(
            'Sincronize seus cartões antes de iniciar um desafio.');
      }
      final result = await remote.post(endpoint, body);
      await synchronize();
      return result;
    }
    final result = await _exclusive(() async {
      if (_disposed || remote.authToken != _sessionToken) {
        throw StateError('Entre novamente.');
      }
      await _load();
      final next = _copy(_state) as Map<String, dynamic>;
      final data = _copy(body) as Map<String, dynamic>;
      final decks = next['decks'] as List;
      final parts = endpoint.split('/').where((s) => s.isNotEmpty).toList();
      Map<String, dynamic>? deck;
      if (parts.length > 1) {
        deck = decks
            .cast<Map<String, dynamic>>()
            .where((d) => d['id'] == parts[1])
            .firstOrNull;
        if (deck == null) {
          throw StateError('Baralho não encontrado neste aparelho.');
        }
      }
      dynamic value;
      void validateDeck(Map d) {
        if (d['name'] is! String ||
            (d['name'] as String).trim().isEmpty ||
            d['dailyGoal'] is! int ||
            d['dailyGoal'] < 1) {
          throw StateError('Informe nome e meta diária válida.');
        }
        if ((d['reminderTimes'] as List)
            .any((t) => !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(t))) {
          throw StateError('Horário inválido.');
        }
      }

      void validateCard(Map c) {
        if (c['front'] is! String ||
            (c['front'] as String).trim().isEmpty ||
            c['back'] is! String ||
            (c['back'] as String).trim().isEmpty) {
          throw StateError('Preencha frente e verso.');
        }
        final options = c['options'];
        if (options != null &&
            (options is! List ||
                options.length < 2 ||
                options.any((v) => v is! String || v.trim().isEmpty) ||
                c['correctIndex'] is! int ||
                c['correctIndex'] < 0 ||
                c['correctIndex'] >= options.length)) {
          throw StateError('Alternativas inválidas.');
        }
      }

      Map<String, dynamic> newCard(Map<String, dynamic> c) {
        c['id'] = 'local-${_id()}';
        final card = <String, dynamic>{
          'status': 'novo',
          'suspended': false,
          'type': 'text',
          ...c
        };
        validateCard(card);
        return card;
      }

      if (parts.length == 1 && method == 'POST') {
        data['id'] = 'local-${_id()}';
        value = {
          'description': '',
          'dailyGoal': 20,
          'remindersEnabled': true,
          'reminderTimes': ['20:00'],
          ...data,
          'cards': <dynamic>[],
          'updatedAt': DateTime.now().toIso8601String()
        };
        validateDeck(value);
        decks.add(value);
      } else if (parts.length == 2) {
        if (method == 'DELETE') {
          decks.remove(deck);
        } else {
          deck!.addAll(data);
          validateDeck(deck);
          value = deck;
        }
      } else {
        final cards = deck!['cards'] as List;
        if (parts.length == 3 && method == 'POST') {
          value = newCard(data);
          cards.add(value);
        } else if (parts.last == 'batch') {
          final batch = (data['cards'] as List)
              .map((c) => newCard(Map<String, dynamic>.from(c)))
              .toList();
          for (final c in batch) {
            c['aiGenerated'] = true;
          }
          data['cards'] = batch;
          cards.addAll(batch);
          value = batch;
        } else {
          final card = cards
              .cast<Map<String, dynamic>>()
              .where((c) => c['id'] == parts[3])
              .firstOrNull;
          if (card == null) {
            throw StateError('Cartão não encontrado neste aparelho.');
          }
          if (parts.last == 'review') {
            if (data['challengeId'] != null) {
              throw StateError('Revisões de desafio precisam de conexão.');
            }
            if (card['suspended'] == true) throw StateError('Cartão suspenso.');
            data['reviewedAt'] = DateTime.now().toUtc().toIso8601String();
            card['status'] =
                data['correct'] == false || card['status'] == 'novo'
                    ? 'aRevisar'
                    : 'dominado';
            value = card;
          } else if (method == 'DELETE') {
            cards.remove(card);
          } else {
            card.addAll({...data}..remove('targetDeckId'));
            validateCard(card);
            if (data['targetDeckId'] != null &&
                data['targetDeckId'] != deck['id']) {
              final target = decks
                  .cast<Map<String, dynamic>>()
                  .where((d) => d['id'] == data['targetDeckId'])
                  .firstOrNull;
              if (target == null) {
                throw StateError('Baralho de destino indisponível.');
              }
              cards.remove(card);
              (target['cards'] as List).add(card);
            }
            value = card;
          }
        }
      }
      if (deck != null) deck['updatedAt'] = DateTime.now().toIso8601String();
      (next['queue'] as List)
          .add({'id': _id(), 'method': method, 'path': endpoint, 'body': data});
      await _save(next);
      return _copy(value);
    });
    unawaited(synchronize());
    return result;
  }
}
