import 'package:flutter/material.dart';

class AppNotification {
  AppNotification({
    required this.id,
    this.icon = Icons.notifications,
    required this.title,
    required this.body,
    required this.when,
    this.unread = false,
    this.scheduledAt,
    this.pushStatus = 'pending',
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? ''),
      pushStatus: json['pushStatus'] as String? ?? 'pending',
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      when: json['when'] as String? ?? '',
      unread: json['unread'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'when': when,
      'unread': unread,
    };
  }

  final DateTime? scheduledAt;
  final String pushStatus;
  bool get scheduled => scheduledAt?.isAfter(DateTime.now()) ?? false;
  final String id;
  final IconData icon;
  final String title;
  final String body;
  final String when;
  bool unread;
}
