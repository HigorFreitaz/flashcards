import '../services/offline_api_service.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../../models/study_history_entry.dart';

/// Estatísticas de progresso e gamificação do usuário integradas à API REST.
class ProgressRepository extends ChangeNotifier {
  ProgressRepository([ApiService? apiService]) : _apiService = apiService {
    if (apiService is OfflineApiService) apiService.status.addListener(_afterSync);
    if (_apiService?.authToken != null) {
      fetchProgress();
    }
  }

  int _syncRevision = 0;
  void _afterSync() {
    final status = (_apiService as OfflineApiService).status;
    if (status.revision != _syncRevision) {
      _syncRevision = status.revision;
      fetchProgress();
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

  int streakDays = 0;
  int level = 1;
  int totalXp = 0;
  int xpToNextLevel = 200;
  double weeklyAccuracy = 0.0;
  int minutesStudiedToday = 0;
  int reviewedToday = 0;
  List<bool> weekProgress = [false, false, false, false, false, false, false];

  Future<void> fetchProgress() async {
    if (_apiService == null) return;
    try {
      final res = await _apiService.get('/progress');
      if (res is Map<String, dynamic>) {
        streakDays = res['streakDays'] as int? ?? 0;
        level = res['level'] as int? ?? 1;
        totalXp = res['totalXp'] as int? ?? 0;
        xpToNextLevel = res['xpToNextLevel'] as int? ?? 200;
        weeklyAccuracy = (res['weeklyAccuracy'] as num?)?.toDouble() ?? 0.0;
        minutesStudiedToday = res['minutesStudiedToday'] as int? ?? 0;
        reviewedToday = res['reviewedToday'] as int? ?? 0;
        if (res['weekProgress'] is List) {
          weekProgress =
              (res['weekProgress'] as List).map((e) => e == true).toList();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao buscar progresso via API: $e');
    }
  }

  Future<List<StudyHistoryEntry>> history({int offset = 0}) async {
    final response =
        await _apiService!.get('/progress/history?offset=$offset') as List;
    return response
        .map((item) => StudyHistoryEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> reset() async {
    await _apiService!.delete('/progress');
    await fetchProgress();
  }
}
