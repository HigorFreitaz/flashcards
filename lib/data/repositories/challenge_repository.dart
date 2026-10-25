import '../services/offline_api_service.dart';
import 'package:flutter/foundation.dart';

import '../../models/challenge_history_entry.dart';
import '../services/api_service.dart';

/// Fonte única da verdade para o desafio semanal e seu histórico integrado à API REST.
class ChallengeRepository extends ChangeNotifier {
  ChallengeRepository([ApiService? apiService]) : _apiService = apiService {
    if (apiService is OfflineApiService) apiService.status.addListener(_afterSync);
    if (_apiService?.authToken != null) {
      fetchChallenges();
    }
  }

  int _syncRevision = 0;
  void _afterSync() {
    final status = (_apiService as OfflineApiService).status;
    if (status.revision != _syncRevision) {
      _syncRevision = status.revision;
      fetchChallenges();
    }
  }
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    if (_apiService is OfflineApiService) (_apiService).status.removeListener(_afterSync);
    _disposed = true;
    super.dispose();
  }

  final ApiService? _apiService;
  final List<ChallengeHistoryEntry> history = [];

  String? error;
  bool joined = false;
  int weeklyAnswered = 0;

  Future<void> fetchChallenges() async {
    if (_apiService == null) return;
    try {
      final res = await _apiService.get('/challenges');
      if (res is Map<String, dynamic>) {
        joined = res['joined'] as bool? ?? false;
        weeklyAnswered = res['weeklyAnswered'] as int? ?? 0;
        if (res['history'] is List) {
          history.clear();
          for (final item in res['history']) {
            history.add(
                ChallengeHistoryEntry.fromJson(item as Map<String, dynamic>));
          }
        }
        error = null;
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<ChallengeHistoryEntry> join() async {
    if (_apiService == null) throw StateError('API indisponível.');
    final result = await _apiService.post('/challenges/join', {});
    await fetchChallenges();
    final id = result['challenge']['id'];
    return history.firstWhere((entry) => entry.id == id);
  }

  Future<void> save(Map<String, dynamic> body, {String? id}) async {
    if (id == null) {
      await _apiService!.post('/challenges', body);
    } else {
      await _apiService!.put('/challenges/$id', body);
    }
    await fetchChallenges();
  }

  Future<void> cancel(String id) async {
    await _apiService!.put('/challenges/$id', {'status': 'cancelled'});
    await fetchChallenges();
  }

  Future<void> delete(String id) async {
    await _apiService!.delete('/challenges/$id');
    await fetchChallenges();
  }
}
