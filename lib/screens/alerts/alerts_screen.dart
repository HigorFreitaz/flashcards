import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/notification_repository.dart';
import '../../models/app_notification.dart';
import '../../viewmodels/alerts_view_model.dart';
import '../../widgets/buttons/lume_button.dart';
import '../../widgets/inputs/lume_text_field.dart';
import '../../widgets/feedback/lume_toast.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (ctx) => AlertsViewModel(ctx.read<NotificationRepository>()),
      child: const _AlertsView());
}

class _AlertsView extends StatelessWidget {
  const _AlertsView();
  Future<void> _action(
      BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) showLumeToast(context, error.toString());
    }
  }

  void _edit(BuildContext context, [AppNotification? item]) {
    final vm = context.read<AlertsViewModel>();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
                value: vm, child: _NotificationForm(item: item))));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AlertsViewModel>();
    return Scaffold(
        appBar: AppBar(title: const Text('Notificações'), actions: [
          IconButton(
              tooltip: 'Marcar todas como lidas',
              icon: const Icon(Icons.done_all),
              onPressed: () => _action(context, vm.markAllRead)),
        ]),
        floatingActionButton: FloatingActionButton(
            onPressed: () => _edit(context), child: const Icon(Icons.add)),
        body: RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              if (vm.error != null)
                ListTile(
                    title: Text(vm.error!),
                    trailing: TextButton(
                        onPressed: vm.refresh,
                        child: const Text('Tentar novamente'))),
              if (vm.notifications.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                        'Nenhuma notificação. Adicione um lembrete ou estude para receber avisos.')),
              ...vm.notifications.map((item) => Card(
                      child: ListTile(
                    leading: Icon(item.scheduled
                        ? Icons.schedule
                        : item.unread
                            ? Icons.mark_email_unread_outlined
                            : Icons.drafts_outlined),
                    title: Text(item.title),
                    subtitle: Text(
                        '${item.body}\n${item.scheduled ? 'Agendada: ' : ''}${item.scheduledAt?.toLocal().toString().substring(0, 16) ?? item.when}${item.pushStatus == 'failed' ? '\nFalha ao enviar push. O aviso está disponível aqui.' : ''}'),
                    onTap: () => _edit(context, item),
                    trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            _edit(context, item);
                            return;
                          }
                          if (action == 'delete') {
                            final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                        title:
                                            const Text('Excluir notificação?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Voltar')),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Excluir'))
                                        ]));
                            if (confirmed != true || !context.mounted) return;
                          }
                          if (!context.mounted) return;
                          await _action(
                              context,
                              () => action == 'delete'
                                  ? vm.delete(item.id)
                                  : action == 'retry'
                                      ? vm.retryPush(item.id)
                                      : vm.toggleRead(item));
                        },
                        itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('Editar')),
                              if (!item.scheduled)
                                PopupMenuItem(
                                    value: 'read',
                                    child: Text(item.unread
                                        ? 'Marcar como lida'
                                        : 'Marcar como não lida')),
                              if (item.pushStatus == 'failed')
                                const PopupMenuItem(
                                    value: 'retry',
                                    child: Text('Tentar push novamente')),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Excluir')),
                            ]),
                  ))),
              const SizedBox(height: 80),
            ])));
  }
}

class _NotificationForm extends StatefulWidget {
  const _NotificationForm({this.item});
  final AppNotification? item;
  @override
  State<_NotificationForm> createState() => _NotificationFormState();
}

class _NotificationFormState extends State<_NotificationForm> {
  late final _title = TextEditingController(text: widget.item?.title ?? '');
  late final _body = TextEditingController(text: widget.item?.body ?? '');
  late DateTime _date = widget.item?.scheduledAt?.toLocal() ?? DateTime.now();
  bool _busy = false;
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: _date.isBefore(now) ? now : _date,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: now.add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (time != null && mounted) {
      setState(() => _date =
          DateTime(date.year, date.month, date.day, time.hour, time.minute));
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<AlertsViewModel>().save(
          id: widget.item?.id,
          title: _title.text,
          body: _body.text,
          scheduledAt: _date);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showLumeToast(context, error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(
              widget.item == null ? 'Novo lembrete' : 'Editar notificação')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        LumeTextField(label: 'Título', controller: _title),
        const SizedBox(height: 16),
        LumeTextField(label: 'Mensagem', controller: _body),
        const SizedBox(height: 16),
        ListTile(
            title: const Text('Horário'),
            subtitle: Text(_date.toString().substring(0, 16)),
            trailing: const Icon(Icons.calendar_month),
            onTap: _pickDate),
        const SizedBox(height: 20),
        LumeButton(label: 'Salvar', loading: _busy, onPressed: _save),
      ]));
}
