import '../services/offline_api_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/app_notification.dart';
import '../services/api_service.dart';

/// Fonte única da verdade para as notificações integradas à API REST.
class NotificationRepository extends ChangeNotifier {
  NotificationRepository([ApiService? apiService]) : _apiService = apiService {
    if (apiService is OfflineApiService) apiService.status.addListener(_afterSync);
    if (_apiService?.authToken != null) {
      fetchNotifications();
      _timer = Timer.periodic(
          const Duration(seconds: 60), (_) => fetchNotifications());
    }
  }

  Timer? _timer;
  String? error;
  int _syncRevision = 0;
  void _afterSync() {
    final status = (_apiService as OfflineApiService).status;
    if (status.revision != _syncRevision) {
      _syncRevision = status.revision;
      fetchNotifications();
    }
  }
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_apiService is OfflineApiService) (_apiService).status.removeListener(_afterSync);
    _disposed = true;
    super.dispose();
  }

  final ApiService? _apiService;
  final List<AppNotification> notifications = [];

  int get unreadCount =>
      notifications.where((n) => n.unread && !n.scheduled).length;

  Future<void> fetchNotifications() async {
    if (_apiService == null) return;
    try {
      final res = await _apiService.get('/notifications');
      if (res is List) {
        notifications.clear();
        for (final item in res) {
          notifications
              .add(AppNotification.fromJson(item as Map<String, dynamic>));
        }
        error = null;
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (_apiService == null) throw StateError('API indisponível.');
    await _apiService.put('/notifications/read-all', {});
    for (final n in notifications) {
      if (!n.scheduled) n.unread = false;
    }
    notifyListeners();
  }

  Future<void> save(
      {String? id,
      required String title,
      required String body,
      required DateTime scheduledAt}) async {
    final payload = {
      'title': title,
      'body': body,
      'scheduledAt': scheduledAt.toUtc().toIso8601String()
    };
    if (id == null) {
      await _apiService!.post('/notifications', payload);
    } else {
      await _apiService!.put('/notifications/$id', payload);
    }
    await fetchNotifications();
  }

  Future<void> update(String id, Map<String, dynamic> changes) async {
    await _apiService!.put('/notifications/$id', changes);
    await fetchNotifications();
  }

  Future<void> delete(String id) async {
    await _apiService!.delete('/notifications/$id');
    await fetchNotifications();
  }

  Future<void> registerDevice(String token, String platform) async {
    await _apiService!
        .post('/notifications/devices', {'token': token, 'platform': platform});
  }
}
