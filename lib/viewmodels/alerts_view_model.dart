import 'package:flutter/foundation.dart';

import '../data/repositories/notification_repository.dart';
import '../models/app_notification.dart';

class AlertsViewModel extends ChangeNotifier {
  AlertsViewModel(this._notificationRepository) {
    _notificationRepository.addListener(notifyListeners);
  }

  final NotificationRepository _notificationRepository;

  List<AppNotification> get notifications => _notificationRepository.notifications;

  void markAllRead() => _notificationRepository.markAllRead();

  @override
  void dispose() {
    _notificationRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
