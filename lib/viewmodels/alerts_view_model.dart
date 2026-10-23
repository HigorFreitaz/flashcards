import 'package:flutter/foundation.dart';

import '../data/repositories/notification_repository.dart';
import '../models/app_notification.dart';

class AlertsViewModel extends ChangeNotifier {
  AlertsViewModel(this._notificationRepository) {
    _notificationRepository.addListener(notifyListeners);
  }

  final NotificationRepository _notificationRepository;

  List<AppNotification> get notifications =>
      _notificationRepository.notifications;

  Future<void> markAllRead() => _notificationRepository.markAllRead();

  String? get error => _notificationRepository.error;
  Future<void> refresh() => _notificationRepository.fetchNotifications();
  Future<void> save(
          {String? id,
          required String title,
          required String body,
          required DateTime scheduledAt}) =>
      _notificationRepository.save(
          id: id, title: title, body: body, scheduledAt: scheduledAt);
  Future<void> toggleRead(AppNotification item) =>
      _notificationRepository.update(item.id, {'unread': !item.unread});
  Future<void> retryPush(String id) =>
      _notificationRepository.update(id, {'retryPush': true});
  Future<void> delete(String id) => _notificationRepository.delete(id);
  @override
  void dispose() {
    _notificationRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
