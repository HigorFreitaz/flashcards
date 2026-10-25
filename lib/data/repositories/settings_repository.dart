import '../services/offline_api_service.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Guarda as preferências do app integradas à API REST.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository([ApiService? apiService]) : _apiService = apiService {
    if (apiService is OfflineApiService) apiService.status.addListener(_afterSync);
    if (_apiService?.authToken != null) {
      fetchSettings();
    }
  }

  int _syncRevision = 0;
  void _afterSync() {
    final status = (_apiService as OfflineApiService).status;
    if (status.revision != _syncRevision) {
      _syncRevision = status.revision;
      fetchSettings();
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

  ThemeMode themeMode = ThemeMode.light;
  bool get isDarkMode => themeMode == ThemeMode.dark;

  bool biometricLockEnabled = false;
  String timeZone = 'America/Sao_Paulo';

  Future<void> fetchSettings() async {
    if (_apiService == null) return;
    try {
      final res = await _apiService.get('/settings');
      if (res is Map<String, dynamic>) {
        timeZone = res['timeZone'] as String? ?? 'America/Sao_Paulo';
        final mode = res['themeMode'] as String?;
        if (mode == 'dark') {
          themeMode = ThemeMode.dark;
        } else if (mode == 'system') {
          themeMode = ThemeMode.system;
        } else {
          themeMode = ThemeMode.light;
        }
        biometricLockEnabled =
            res['biometricLockEnabled'] as bool? ?? biometricLockEnabled;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao buscar configurações via API: $e');
    }
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    final previous = themeMode;
    themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      await _syncSettings();
    } catch (_) {
      themeMode = previous;
      notifyListeners();
      rethrow;
    }
  }

  void setBiometricLockEnabled(bool enabled) {
    biometricLockEnabled = enabled;
    notifyListeners();
    _syncSettings().catchError((Object error) {
      debugPrint(error.toString());
    });
  }

  Future<void> _syncSettings() async {
    if (_apiService == null) return;
    try {
      await _apiService.put('/settings', {
        'themeMode': themeMode == ThemeMode.dark
            ? 'dark'
            : (themeMode == ThemeMode.system ? 'system' : 'light'),
        'biometricLockEnabled': biometricLockEnabled,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reset() async {
    await _apiService!.delete('/settings');
    themeMode = ThemeMode.light;
    biometricLockEnabled = false;
    timeZone = 'America/Sao_Paulo';
    notifyListeners();
  }

  Future<void> setTimeZone(String zone) async {
    await _apiService!.put('/settings', {'timeZone': zone});
    timeZone = zone;
    notifyListeners();
  }
}
