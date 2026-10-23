import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/challenge_repository.dart';
import '../../data/repositories/deck_repository.dart';
import '../../models/deck.dart';
import '../../models/challenge_history_entry.dart';
import '../../theme/lume_colors.dart';
import '../../theme/lume_metrics.dart';
import '../../viewmodels/challenge_view_model.dart';
import '../../widgets/buttons/lume_button.dart';
import '../../widgets/chips/lume_chip.dart';
import '../../widgets/navigation/lume_segmented_tabs.dart';
import '../../widgets/inputs/lume_switch.dart';
import '../../widgets/inputs/lume_text_field.dart';
import '../../widgets/feedback/lume_toast.dart';
import '../study/study_screen.dart';

enum _ChallengeTab { fromAI, own }

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ChallengeViewModel(
          ctx.read<DeckRepository>(), ctx.read<ChallengeRepository>()),
      child: const _ChallengeView(),
    );
  }
}

class _ChallengeView extends StatefulWidget {
  const _ChallengeView();

  @override
  State<_ChallengeView> createState() => _ChallengeViewState();
}

class _ChallengeViewState extends State<_ChallengeView> {
  _ChallengeTab _tab = _ChallengeTab.fromAI;
  final _nameController =
      TextEditingController(text: 'Sprint de véspera de prova');
  final Set<String> _selectedDecks = {};
  int _questionCount = 15;
  String _deadline = '1 semana';
  bool _weakCardsOnly = true;
  bool _busy = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    final decks = context.read<ChallengeViewModel>().decks;
    _selectedDecks.addAll(decks.take(3).map((d) => d.id));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startChallenge(
      ChallengeViewModel vm, ChallengeHistoryEntry entry) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final challenge = entry;
      if (!mounted) return;
      if (!challenge.active) {
        showLumeToast(context, 'Este desafio já foi encerrado.');
        return;
      }
      final queue = vm.queueFor(challenge);
      if (queue.isEmpty) {
        showLumeToast(context, 'Nenhum cartão disponível para este desafio.');
        return;
      }
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StudyScreen(
              queue: queue,
              sessionTitle: challenge.title,
              isChallenge: true,
              challengeId: challenge.id)));
    } catch (error) {
      if (mounted) showLumeToast(context, error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveChallenge(ChallengeViewModel vm) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await vm.saveChallenge(
          id: _editingId,
          title: _nameController.text,
          targetCount: _questionCount,
          deckIds: _selectedDecks.toList(),
          durationDays: _deadline == '3 dias'
              ? 3
              : _deadline == '1 mês'
                  ? 30
                  : 7,
          weakOnly: _weakCardsOnly);
      if (!mounted) return;
      setState(() {
        _editingId = null;
        _tab = _ChallengeTab.fromAI;
      });
      showLumeToast(context, 'Desafio salvo');
    } catch (error) {
      if (mounted) showLumeToast(context, error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manage(
      ChallengeViewModel vm, ChallengeHistoryEntry entry, String action) async {
    if (action == 'edit') {
      setState(() {
        _editingId = entry.id;
        _nameController.text = entry.title;
        _selectedDecks
          ..clear()
          ..addAll(entry.deckIds);
        _questionCount = entry.targetCount;
        _weakCardsOnly = entry.weakOnly;
        _tab = _ChallengeTab.own;
      });
      return;
    }
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(action == 'delete'
                    ? 'Excluir desafio?'
                    : 'Cancelar desafio?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Voltar')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Confirmar'))
                ]));
    if (confirmed != true || !mounted) return;
    try {
      if (action == 'delete') {
        await vm.delete(entry.id);
      } else {
        await vm.cancel(entry.id);
      }
    } catch (error) {
      if (mounted) showLumeToast(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChallengeViewModel>();
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    'Desafios',
                    style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: context.lume.ink),
                  ),
                  if (viewModel.error != null)
                    ListTile(
                        title: Text(viewModel.error!),
                        trailing: TextButton(
                            onPressed: viewModel.refresh,
                            child: const Text('Tentar novamente'))),
                  ...viewModel.challengeHistory.map((entry) => Card(
                          child: ListTile(
                        title: Text(entry.title),
                        subtitle: Text(
                            '${entry.answered}/${entry.targetCount} · ${entry.status} · ${entry.scorePercent}%'),
                        onTap: entry.active
                            ? () => _startChallenge(viewModel, entry)
                            : null,
                        trailing: PopupMenuButton<String>(
                            onSelected: (action) =>
                                _manage(viewModel, entry, action),
                            itemBuilder: (_) => [
                                  if (entry.active && entry.kind == 'custom')
                                    const PopupMenuItem(
                                        value: 'edit', child: Text('Editar')),
                                  if (entry.active)
                                    const PopupMenuItem(
                                        value: 'cancel',
                                        child: Text('Cancelar')),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Excluir')),
                                ]),
                      ))),
                  const SizedBox(height: 18),
                  LumeSegmentedTabs<_ChallengeTab>(
                    options: const [_ChallengeTab.fromAI, _ChallengeTab.own],
                    labels: const ['IA (protótipo)', 'Criar meu'],
                    value: _tab,
                    onChanged: (t) => setState(() => _tab = t),
                  ),
                  const SizedBox(height: 20),
                  if (_tab == _ChallengeTab.fromAI)
                    _AiChallengeTab(fontFamily: fontFamily)
                  else
                    _OwnChallengeTab(
                      fontFamily: fontFamily,
                      nameController: _nameController,
                      decks: viewModel.decks,
                      selectedDecks: _selectedDecks,
                      onToggleDeck: (id) => setState(() {
                        if (_selectedDecks.contains(id)) {
                          _selectedDecks.remove(id);
                        } else {
                          _selectedDecks.add(id);
                        }
                      }),
                      questionCount: _questionCount,
                      onQuestionCountChanged: (v) =>
                          setState(() => _questionCount = v),
                      deadline: _deadline,
                      onDeadlineChanged: (d) => setState(() => _deadline = d),
                      weakCardsOnly: _weakCardsOnly,
                      onWeakCardsOnlyChanged: (v) =>
                          setState(() => _weakCardsOnly = v),
                    ),
                ],
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              top: false,
              child: _tab == _ChallengeTab.fromAI
                  ? const LumeButton(
                      label: 'IA ainda não integrada',
                      onPressed: null,
                    )
                  : LumeButton(
                      label: _editingId == null
                          ? 'Criar desafio com $_questionCount perguntas'
                          : 'Salvar desafio',
                      loading: _busy,
                      onPressed: () => _saveChallenge(viewModel),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiChallengeTab extends StatelessWidget {
  const _AiChallengeTab({required this.fontFamily});
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LumeSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.lume.primary,
        borderRadius: BorderRadius.circular(LumeRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROTÓTIPO · SEM INTEGRAÇÃO COM IA',
              style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.lume.background)),
          const SizedBox(height: 14),
          Text('Desafios com IA',
              style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: context.lume.background)),
          const SizedBox(height: 14),
          Text(
              'Esta função ainda não gera desafios, seleciona cartões ou registra progresso. '
              'Para estudar agora, use a aba Criar meu e escolha seus baralhos.',
              style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 14,
                  height: 1.5,
                  color: context.lume.background)),
        ],
      ),
    );
  }
}

class _OwnChallengeTab extends StatelessWidget {
  const _OwnChallengeTab({
    required this.fontFamily,
    required this.nameController,
    required this.decks,
    required this.selectedDecks,
    required this.onToggleDeck,
    required this.questionCount,
    required this.onQuestionCountChanged,
    required this.deadline,
    required this.onDeadlineChanged,
    required this.weakCardsOnly,
    required this.onWeakCardsOnlyChanged,
  });

  final String? fontFamily;
  final TextEditingController nameController;
  final List<Deck> decks;
  final Set<String> selectedDecks;
  final ValueChanged<String> onToggleDeck;
  final int questionCount;
  final ValueChanged<int> onQuestionCountChanged;
  final String deadline;
  final ValueChanged<String> onDeadlineChanged;
  final bool weakCardsOnly;
  final ValueChanged<bool> onWeakCardsOnlyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LumeTextField(label: 'Nome do desafio', controller: nameController),
        const SizedBox(height: 22),
        const LumeFieldLabel('Baralhos incluídos'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: decks
              .map((d) => LumeChip(
                    label: d.shortName,
                    selected: selectedDecks.contains(d.id),
                    onTap: () => onToggleDeck(d.id),
                  ))
              .toList(),
        ),
        const SizedBox(height: 22),
        const LumeFieldLabel('Perguntas'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: context.lume.background,
            border: Border.all(color: context.lume.outline),
            borderRadius: BorderRadius.circular(LumeRadii.field),
          ),
          constraints: const BoxConstraints(minHeight: 62),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$questionCount',
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: context.lume.ink)),
              Row(
                children: [
                  LumeIconButton(
                      icon: Icons.remove_rounded,
                      semanticLabel: 'Menos perguntas',
                      filled: true,
                      size: 46,
                      onPressed: () => onQuestionCountChanged(
                          (questionCount - 5).clamp(5, 40).toInt())),
                  const SizedBox(width: 8),
                  LumeIconButton(
                      icon: Icons.add_rounded,
                      semanticLabel: 'Mais perguntas',
                      filled: true,
                      size: 46,
                      onPressed: () => onQuestionCountChanged(
                          (questionCount + 5).clamp(5, 40).toInt())),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const LumeFieldLabel('Prazo'),
        Wrap(
          spacing: 8,
          children: ['3 dias', '1 semana', '1 mês']
              .map((d) => LumeChip(
                  label: d,
                  selected: deadline == d,
                  onTap: () => onDeadlineChanged(d)))
              .toList(),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
              color: context.lume.surface,
              borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Só cartões que eu erro',
                        style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.lume.ink)),
                    const SizedBox(height: 3),
                    Text('Inclui somente cartões marcados para revisar',
                        style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 13,
                            color: context.lume.inkMuted)),
                  ],
                ),
              ),
              LumeSwitch(
                  value: weakCardsOnly,
                  semanticLabel: 'Só cartões que eu erro',
                  onChanged: onWeakCardsOnlyChanged),
            ],
          ),
        ),
      ],
    );
  }
}
