import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../state/app_state.dart';
import '../../theme/lume_colors.dart';
import '../../theme/lume_metrics.dart';
import '../../widgets/lume_bottom_sheet.dart';
import '../../widgets/lume_button.dart';
import '../../widgets/lume_toast.dart';
import '../create_card/create_card_screen.dart';
import '../study/study_screen.dart';
import 'deck_form_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  CardStatus? _filter;

  Future<void> _openDeckMenu(Deck deck) async {
    final choice = await showLumeActionSheet(
      context,
      title: deck.name.toUpperCase(),
      actions: const [
        LumeSheetAction(label: 'Editar baralho'),
        LumeSheetAction(label: 'Estudar agora'),
        LumeSheetAction(label: 'Adicionar cartão'),
        LumeSheetAction(label: 'Excluir baralho', danger: true),
      ],
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 0:
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeckFormScreen(deckId: deck.id)));
        break;
      case 1:
        _startStudy(deck, useAllQueue: true);
        break;
      case 2:
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateCardScreen(deckId: deck.id)));
        break;
      case 3:
        final name = deck.shortName;
        context.read<AppState>().deleteDeck(deck.id);
        if (mounted) {
          Navigator.of(context).pop();
          showLumeToast(context, 'Baralho "$name" excluído');
        }
    }
  }

  Future<void> _openCardMenu(Deck deck, Flashcard card) async {
    final choice = await showLumeActionSheet(
      context,
      title: 'Cartão',
      actions: const [
        LumeSheetAction(label: 'Editar cartão'),
        LumeSheetAction(label: 'Suspender revisões'),
        LumeSheetAction(label: 'Excluir cartão', danger: true),
      ],
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 0:
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateCardScreen(deckId: deck.id, editingCardId: card.id)));
        break;
      case 1:
        showLumeToast(context, 'Cartão suspenso das revisões');
        break;
      case 2:
        context.read<AppState>().deleteCard(deck.id, card.id);
        if (mounted) showLumeToast(context, 'Cartão excluído');
    }
  }

  void _startStudy(Deck deck, {bool useAllQueue = false}) {
    final queue = useAllQueue
        ? StudyQueueItem.fromDeck(deck)
        : deck.cards
            .where((c) => c.status == CardStatus.aRevisar)
            .map((c) => StudyQueueItem(deckId: deck.id, deckName: deck.name, card: c))
            .toList();
    if (queue.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudyScreen(queue: queue, sessionTitle: deck.name)));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final deck = app.findDeck(widget.deckId);
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    if (deck == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final visibleCards = _filter == null ? deck.cards : deck.cards.where((c) => c.status == _filter).toList();
    final filterLabels = {
      null: 'Fila de revisão',
      CardStatus.novo: 'Cartões novos',
      CardStatus.aRevisar: 'A revisar hoje',
      CardStatus.dominado: 'Cartões dominados',
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  LumeIconButton(icon: Icons.chevron_left_rounded, onPressed: () => Navigator.of(context).pop(), semanticLabel: 'Voltar'),
                  const Spacer(),
                  LumeIconButton(icon: Icons.more_vert_rounded, onPressed: () => _openDeckMenu(deck), semanticLabel: 'Editar ou excluir baralho'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                deck.name,
                style: TextStyle(fontFamily: fontFamily, fontSize: 26, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: context.lume.ink),
              ),
              const SizedBox(height: 6),
              Text(
                '${deck.totalCount} cartões · atualizado ${_relativeUpdatedAt(deck.updatedAt)}',
                style: TextStyle(fontFamily: fontFamily, fontSize: 14, color: context.lume.inkMuted),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'novos',
                      value: deck.newCount,
                      selected: _filter == CardStatus.novo,
                      onTap: () => setState(() => _filter = _filter == CardStatus.novo ? null : CardStatus.novo),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      label: 'a revisar',
                      value: deck.dueCount,
                      emphasis: true,
                      selected: _filter == CardStatus.aRevisar,
                      onTap: () => setState(() => _filter = _filter == CardStatus.aRevisar ? null : CardStatus.aRevisar),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      label: 'dominados',
                      value: deck.masteredCount,
                      selected: _filter == CardStatus.dominado,
                      onTap: () => setState(() => _filter = _filter == CardStatus.dominado ? null : CardStatus.dominado),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    filterLabels[_filter]!,
                    style: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: context.lume.ink),
                  ),
                  if (_filter != null)
                    TextButton(
                      onPressed: () => setState(() => _filter = null),
                      child: Text('Ver todos', style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: context.lume.primary)),
                    )
                  else
                    Text('próximos ${visibleCards.length} de ${deck.totalCount}', style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: context.lume.inkMuted)),
                ],
              ),
              const SizedBox(height: 12),
              if (visibleCards.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 34),
                  decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      Text('Nenhum cartão aqui', style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700, color: context.lume.ink)),
                      const SizedBox(height: 7),
                      Text('Use o botão "Novo cartão" para começar.', style: TextStyle(fontFamily: fontFamily, fontSize: 14, color: context.lume.inkMuted)),
                    ],
                  ),
                )
              else
                ...visibleCards.map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CardRow(
                      card: card,
                      fontFamily: fontFamily,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateCardScreen(deckId: deck.id, editingCardId: card.id))),
                      onMenu: () => _openCardMenu(deck, card),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: LumeButton(
          label: deck.dueCount == 0 ? 'Tudo revisado por aqui' : 'Estudar ${deck.dueCount} cartões',
          onPressed: deck.dueCount == 0 ? null : () => _startStudy(deck),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateCardScreen(deckId: deck.id))),
        backgroundColor: context.lume.primary,
        foregroundColor: context.lume.background,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo cartão'),
      ),
    );
  }

  String _relativeUpdatedAt(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays == 1) return 'ontem';
    return 'há ${diff.inDays} dias';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.selected, required this.onTap, this.emphasis = false});

  final String label;
  final int value;
  final bool selected;
  final bool emphasis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final background = selected ? context.lume.primary : context.lume.surface;
    final foreground = selected ? context.lume.background : (emphasis ? context.lume.primary : context.lume.ink);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: context.lume.primary, width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: TextStyle(fontFamily: fontFamily, fontSize: 19, fontWeight: FontWeight.w700, color: foreground)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: selected ? context.lume.background : context.lume.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card, required this.fontFamily, required this.onTap, required this.onMenu});

  final Flashcard card;
  final String? fontFamily;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  Color _dotColor(BuildContext context) {
    switch (card.status) {
      case CardStatus.aRevisar:
        return context.lume.primary;
      case CardStatus.novo:
        return context.lume.outline;
      case CardStatus.dominado:
        return context.lume.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.lume.background,
        border: Border.all(color: context.lume.outline),
        borderRadius: BorderRadius.circular(LumeRadii.listRow),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(LumeRadii.listRow),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      decoration: BoxDecoration(color: _dotColor(context), shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.front,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35, color: context.lume.ink),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            card.back,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: context.lume.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          LumeIconButton(icon: Icons.more_vert_rounded, onPressed: onMenu, semanticLabel: 'Editar ou excluir cartão', size: 38),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
