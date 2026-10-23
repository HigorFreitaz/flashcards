import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/challenge_repository.dart';
import '../../viewmodels/progress_history_view_model.dart';
import '../../widgets/feedback/lume_toast.dart';

class ProgressHistoryScreen extends StatelessWidget {
  const ProgressHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (ctx) => ProgressHistoryViewModel(ctx.read<ProgressRepository>(),
          ctx.read<DeckRepository>(), ctx.read<ChallengeRepository>()),
      child: const _HistoryView());
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();
  Future<void> _reset(BuildContext context) async {
    final vm = context.read<ProgressHistoryViewModel>();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Zerar progresso?'),
                content: const Text(
                    'Remove histórico, XP e sequência, reinicia os cartões e cancela desafios ativos. Seus baralhos e cartões serão mantidos.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Voltar')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Zerar'))
                ]));
    if (confirmed != true || !context.mounted) return;
    try {
      await vm.reset();
    } catch (error) {
      if (context.mounted) showLumeToast(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProgressHistoryViewModel>();
    return Scaffold(
        appBar: AppBar(title: const Text('Histórico de estudo'), actions: [
          IconButton(
              tooltip: 'Zerar progresso',
              onPressed: vm.busy ? null : () => _reset(context),
              icon: const Icon(Icons.restart_alt))
        ]),
        body: RefreshIndicator(
            onRefresh: () => vm.load(restart: true),
            child: ListView(children: [
              if (vm.error != null)
                ListTile(
                    title: Text(vm.error!),
                    trailing: TextButton(
                        onPressed: () => vm.load(restart: true),
                        child: const Text('Tentar novamente'))),
              if (vm.entries.isEmpty && !vm.busy)
                const ListTile(title: Text('Nenhuma revisão registrada.')),
              ...vm.entries.map((entry) => ListTile(
                  title: Text(entry.cardFront),
                  subtitle: Text(
                      '${entry.deckName} · ${entry.createdAt.toLocal().toString().substring(0, 16)} · ${entry.durationSeconds}s'),
                  leading: Icon(entry.correct == null
                      ? Icons.help_outline
                      : entry.correct!
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined))),
              if (vm.busy) const Center(child: CircularProgressIndicator()),
              if (vm.hasMore && !vm.busy)
                TextButton(
                    onPressed: vm.load, child: const Text('Carregar mais')),
            ])));
  }
}
