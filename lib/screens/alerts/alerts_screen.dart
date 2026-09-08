import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/notification_repository.dart';
import '../../models/app_notification.dart';
import '../../theme/lume_colors.dart';
import '../../viewmodels/alerts_view_model.dart';
import '../../widgets/buttons/lume_button.dart';
import '../../widgets/feedback/lume_toast.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AlertsViewModel(ctx.read<NotificationRepository>()),
      child: const _AlertsView(),
    );
  }
}

class _AlertsView extends StatelessWidget {
  const _AlertsView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AlertsViewModel>();
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final today = viewModel.notifications.where((n) => n.when == 'agora' || n.when.endsWith('h')).toList();
    final week = viewModel.notifications.where((n) => !today.contains(n)).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Row(
              children: [
                LumeIconButton(icon: Icons.chevron_left_rounded, onPressed: () => Navigator.of(context).pop(), semanticLabel: 'Voltar'),
                const SizedBox(width: 6),
                Text('Início', style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: context.lume.inkMuted)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificações',
                  style: TextStyle(fontFamily: fontFamily, fontSize: 28, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: context.lume.ink),
                ),
                TextButton(
                  onPressed: () {
                    viewModel.markAllRead();
                    showLumeToast(context, 'Todos os avisos marcados como lidos');
                  },
                  child: Text('Marcar lidos', style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: context.lume.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (today.isNotEmpty) _NotificationSection(title: 'HOJE', items: today, fontFamily: fontFamily),
            if (week.isNotEmpty) _NotificationSection(title: 'ESTA SEMANA', items: week, fontFamily: fontFamily),
          ],
        ),
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({required this.title, required this.items, required this.fontFamily});

  final String title;
  final List<AppNotification> items;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
          child: Text(title, style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: context.lume.inkMuted)),
        ),
        ...items.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NotificationRow(notification: n, fontFamily: fontFamily),
            )),
      ],
    );
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
        color: context.lume.background,
        border: Border.all(color: notification.unread ? context.lume.accent : context.lume.outline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(13)),
            alignment: Alignment.center,
            child: Icon(notification.icon, size: 18, color: context.lume.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35, color: context.lume.ink)),
                const SizedBox(height: 3),
                Text(notification.body, style: TextStyle(fontFamily: fontFamily, fontSize: 13, height: 1.4, color: context.lume.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(notification.when, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: context.lume.inkMuted)),
              if (notification.unread) ...[
                const SizedBox(height: 7),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: context.lume.primary, shape: BoxShape.circle)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
