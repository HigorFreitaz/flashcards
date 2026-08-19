import 'package:flutter/material.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
    required this.when,
    this.unread = false,
  });

  final String id;
  final IconData icon;
  final String title;
  final String body;
  final String when;
  bool unread;
}
