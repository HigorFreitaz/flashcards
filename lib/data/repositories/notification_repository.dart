import 'package:flutter/foundation.dart';

import '../../models/app_notification.dart';

/// Fonte única da verdade para as notificações do usuário.
class NotificationRepository extends ChangeNotifier {
  final List<AppNotification> notifications = [];

  int get unreadCount => notifications.where((n) => n.unread).length;

  void markAllRead() {
    for (final n in notifications) {
      n.unread = false;
    }
    notifyListeners();
  }
}
