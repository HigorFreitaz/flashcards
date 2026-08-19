import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../state/app_state.dart';
import '../../theme/lume_colors.dart';
import '../../widgets/lume_button.dart';
import '../../widgets/lume_toast.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final today = app.notifications.where((n) => n.when == 'agora' || n.when.endsWith('h')).toList();
    final week = app.notifications.where((n) => !today.contains(n)).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Row(
              children: [
                LumeIconButton(icon: Icons.chevron_left_rounded, onPressed: () => Navigator.of(context).pop(), semanticLabel: 'Voltar'),
                const SizedBox(width: 6),
                Text('Início', style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: LumeColors.inkMuted)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificações',
                  style: TextStyle(fontFamily: fontFamily, fontSize: 28, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: LumeColors.ink),
                ),
                TextButton(
                  onPressed: () {
                    context.read<AppState>().markAllNotificationsRead();
                    showLumeToast(context, 'Todos os avisos marcados como lidos');
                  },
                  child: Text('Marcar lidos', style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: LumeColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (today.isNotEmpty) ..._buildSection('HOJE', today, fontFamily),
            if (week.isNotEmpty) ..._buildSection('ESTA SEMANA', week, fontFamily),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSection(String title, List<AppNotification> items, String? fontFamily) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
        child: Text(title, style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: LumeColors.inkMuted)),
      ),
      ...items.map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NotificationRow(notification: n, fontFamily: fontFamily),
          )),
    ];
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.fontFamily});

  final AppNotification notification;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: LumeColors.background,
        border: Border.all(color: notification.unread ? LumeColors.accent : LumeColors.outline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: LumeColors.surface, borderRadius: BorderRadius.circular(13)),
            alignment: Alignment.center,
            child: Icon(notification.icon, size: 18, color: LumeColors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35, color: LumeColors.ink)),
                const SizedBox(height: 3),
                Text(notification.body, style: TextStyle(fontFamily: fontFamily, fontSize: 13, height: 1.4, color: LumeColors.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(notification.when, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: LumeColors.inkMuted)),
              if (notification.unread) ...[
                const SizedBox(height: 7),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: LumeColors.primary, shape: BoxShape.circle)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
