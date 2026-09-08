import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/challenge_repository.dart';
import '../../data/repositories/deck_repository.dart';
import '../../models/deck.dart';
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
      create: (ctx) => ChallengeViewModel(ctx.read<DeckRepository>(), ctx.read<ChallengeRepository>()),
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

  void _startChallenge(ChallengeViewModel viewModel) {
    viewModel.joinChallenge();
    final decks = viewModel.decks.where((d) => d.aiAssisted).toList();
    final source = decks.isEmpty ? viewModel.decks : decks;
    final queue = StudyQueueItem.fromDecks(source);
    if (queue.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StudyScreen(
          queue: queue, sessionTitle: 'Desafio da semana', isChallenge: true),
    ));
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
                  const SizedBox(height: 18),
                  LumeSegmentedTabs<_ChallengeTab>(
                    options: const [_ChallengeTab.fromAI, _ChallengeTab.own],
                    labels: const ['Da IA', 'Criar meu'],
                    value: _tab,
                    onChanged: (t) => setState(() => _tab = t),
                  ),
                  const SizedBox(height: 20),
                  if (_tab == _ChallengeTab.fromAI)
                    _AiChallengeTab(viewModel: viewModel, fontFamily: fontFamily)
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
                      onQuestionCountChanged: (v) => setState(() => _questionCount = v),
                      deadline: _deadline,
                      onDeadlineChanged: (d) => setState(() => _deadline = d),
                      weakCardsOnly: _weakCardsOnly,
                      onWeakCardsOnlyChanged: (v) => setState(() => _weakCardsOnly = v),
                    ),
                ],
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              top: false,
              child: _tab == _ChallengeTab.fromAI
                  ? LumeButton(
                      label: viewModel.challengeJoined
                          ? 'Continuar desafio · 11 de 15'
                          : 'Aceitar desafio da semana',
                      variant: viewModel.challengeJoined
                          ? LumeButtonVariant.secondary
                          : LumeButtonVariant.primary,
                      onPressed: () => _startChallenge(viewModel),
                    )
                  : LumeButton(
                      label: 'Criar desafio com $_questionCount perguntas',
                      onPressed: () {
                        setState(() => _tab = _ChallengeTab.fromAI);
                        showLumeToast(context, 'Desafio criado e agendado');
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

}

class _AiChallengeTab extends StatelessWidget {
  const _AiChallengeTab({required this.viewModel, required this.fontFamily});

  final ChallengeViewModel viewModel;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
      Container(
        padding: const EdgeInsets.all(LumeSpacing.cardPadding),
        decoration: BoxDecoration(
            color: context.lume.primary,
            borderRadius: BorderRadius.circular(LumeRadii.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GERADO PARA VOCÊ · SEMANA 34',
                style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: context.lume.background.withValues(alpha: 0.8))),
            const SizedBox(height: 10),
            Text('Mistura geral: 15 perguntas dos seus 4 baralhos',
                style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.2,
                    color: context.lume.background)),
            const SizedBox(height: 14),
            Text(
                'A IA escolheu os cartões que você mais erra. Uma tentativa por pergunta, sem consultar o verso.',
                style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14,
                    height: 1.5,
                    color: context.lume.background.withValues(alpha: 0.85))),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: viewModel.decks
                  .take(4)
                  .map((d) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color:
                                context.lume.background.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                            '${d.shortName} · ${d.dueCount + d.newCount}',
                            style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.lume.background)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(top: 18),
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: context.lume.background
                              .withValues(alpha: 0.22)))),
              child: Row(
                children: [
                  _HighlightStat(
                      value: '2 dias',
                      label: 'restantes',
                      fontFamily: fontFamily),
                  const SizedBox(width: 22),
                  _HighlightStat(
                      value: '+250', label: 'XP', fontFamily: fontFamily),
                  const SizedBox(width: 22),
                  _HighlightStat(
                      value: viewModel.challengeJoined ? '11/15' : '0/15',
                      label: 'respondidas',
                      fontFamily: fontFamily),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Seu histórico',
              style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: context.lume.ink)),
          Text('${viewModel.challengeHistory.length} semanas',
              style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 13,
                  color: context.lume.inkMuted)),
        ],
      ),
      const SizedBox(height: 12),
      ...viewModel.challengeHistory.map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.lume.background,
                border: Border.all(color: context.lume.outline),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: context.lume.surface,
                        borderRadius: BorderRadius.circular(13)),
                    alignment: Alignment.center,
                    child: Text(h.week,
                        style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.lume.primary)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.title,
                            style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.lume.ink)),
                        const SizedBox(height: 3),
                        Text(h.detail,
                            style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 13,
                                color: context.lume.inkMuted)),
                      ],
                    ),
                  ),
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    decoration: BoxDecoration(
                      color: h.success
                          ? context.lume.primary
                          : context.lume.surface,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Text('${h.scorePercent}%',
                        style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: h.success
                                ? context.lume.background
                                : context.lume.inkMuted)),
                  ),
                ],
              ),
            ),
          )),
      ],
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
                  Text('A IA prioriza acertos abaixo de 70%',
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

class _HighlightStat extends StatelessWidget {
  const _HighlightStat(
      {required this.value, required this.label, required this.fontFamily});

  final String value;
  final String label;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.lume.background)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 12,
                color: context.lume.background.withValues(alpha: 0.8))),
      ],
    );
  }
}
