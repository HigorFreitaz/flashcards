import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../state/app_state.dart';
import '../../theme/lume_colors.dart';
import '../../widgets/lume_bottom_sheet.dart';
import '../../widgets/lume_button.dart';
import '../../widgets/lume_chip.dart';
import '../../widgets/lume_toast.dart';
import '../deck/deck_detail_screen.dart';
import '../deck/deck_form_screen.dart';

enum _LibraryFilter { todos, aRevisar, novos, porIA }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  _LibraryFilter _filter = _LibraryFilter.todos;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openDeckMenu(Deck deck) async {
    final choice = await showLumeActionSheet(
      context,
      title: deck.name.toUpperCase(),
      actions: const [
        LumeSheetAction(label: 'Editar baralho'),
        LumeSheetAction(label: 'Excluir baralho', danger: true),
      ],
    );
    if (!mounted || choice == null) return;
    if (choice == 0) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeckFormScreen(deckId: deck.id)));
    } else if (choice == 1) {
      final name = deck.shortName;
      context.read<AppState>().deleteDeck(deck.id);
      if (mounted) showLumeToast(context, 'Baralho "$name" excluído');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final query = _searchController.text.trim().toLowerCase();

    var decks = app.decks.where((d) => d.name.toLowerCase().contains(query)).toList();
    switch (_filter) {
      case _LibraryFilter.aRevisar:
        decks = decks.where((d) => d.dueCount > 0).toList();
        break;
      case _LibraryFilter.novos:
        decks = decks.where((d) => d.masteryPercent < 0.5).toList();
        break;
      case _LibraryFilter.porIA:
        decks = decks.where((d) => d.aiAssisted).toList();
        break;
      case _LibraryFilter.todos:
        break;
    }

    final libraryEmpty = app.decks.isEmpty;
    final noResults = !libraryEmpty && decks.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
              child: Text(
                'Baralhos',
                style: TextStyle(fontFamily: fontFamily, fontSize: 28, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: LumeColors.ink),
              ),
            ),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: LumeColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 19, color: LumeColors.inkMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(fontFamily: fontFamily, fontSize: 16, color: LumeColors.ink),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Buscar baralhos e cartões',
                        hintStyle: TextStyle(fontFamily: fontFamily, fontSize: 16, color: LumeColors.inkMuted),
                      ),
                    ),
                  ),
                  if (query.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _searchController.clear()),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: LumeColors.outline, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Icon(Icons.close_rounded, size: 16, color: LumeColors.ink),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                LumeChip(label: 'Todos', selected: _filter == _LibraryFilter.todos, onTap: () => setState(() => _filter = _LibraryFilter.todos)),
                LumeChip(label: 'A revisar', selected: _filter == _LibraryFilter.aRevisar, onTap: () => setState(() => _filter = _LibraryFilter.aRevisar)),
                LumeChip(label: 'Novos', selected: _filter == _LibraryFilter.novos, onTap: () => setState(() => _filter = _LibraryFilter.novos)),
                LumeChip(label: 'Por IA', selected: _filter == _LibraryFilter.porIA, onTap: () => setState(() => _filter = _LibraryFilter.porIA)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${libraryEmpty ? 0 : decks.length} de ${app.decks.length} baralhos',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: LumeColors.inkMuted),
            ),
            const SizedBox(height: 14),
            if (libraryEmpty) _EmptyLibrary(fontFamily: fontFamily, onCreate: () => _createDeck(context)),
            if (noResults)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Text('Nada encontrado', style: TextStyle(fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w600, color: LumeColors.ink)),
                    const SizedBox(height: 8),
                    Text('Nenhum baralho corresponde a "${_searchController.text}".',
                        textAlign: TextAlign.center, style: TextStyle(fontFamily: fontFamily, fontSize: 14, color: LumeColors.inkMuted)),
                  ],
                ),
              ),
            ...decks.map((deck) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DeckRow(
                    deck: deck,
                    fontFamily: fontFamily,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeckDetailScreen(deckId: deck.id))),
                    onMenu: () => _openDeckMenu(deck),
                  ),
                )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createDeck(context),
        backgroundColor: LumeColors.primary,
        foregroundColor: LumeColors.background,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo baralho'),
      ),
    );
  }

  void _createDeck(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeckFormScreen()));
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.fontFamily, required this.onCreate});

  final String? fontFamily;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: LumeColors.surface, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.style_outlined, size: 28, color: LumeColors.inkMuted),
          ),
          Text('Sua biblioteca está vazia', style: TextStyle(fontFamily: fontFamily, fontSize: 19, fontWeight: FontWeight.w700, color: LumeColors.ink)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Crie um baralho e depois adicione cartões digitando ou gerando com IA.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: fontFamily, fontSize: 15, height: 1.5, color: LumeColors.inkMuted),
            ),
          ),
          const SizedBox(height: 24),
          LumeButton(label: 'Criar primeiro baralho', onPressed: onCreate, expand: false, height: 48),
        ],
      ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck, required this.fontFamily, required this.onTap, required this.onMenu});

  final Deck deck;
  final String? fontFamily;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LumeColors.background,
        border: Border.all(color: LumeColors.outline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: LumeColors.surface, borderRadius: BorderRadius.circular(15)),
                      alignment: Alignment.center,
                      child: Text(deck.initials, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: LumeColors.primary)),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deck.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: LumeColors.ink),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 7,
                            runSpacing: 4,
                            children: [
                              Container(
                                height: 24,
                                padding: const EdgeInsets.symmetric(horizontal: 9),
                                decoration: BoxDecoration(
                                  color: deck.dueCount > 0 ? LumeColors.primary : LumeColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  deck.dueCount > 0 ? '${deck.dueCount} a revisar' : 'em dia',
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: deck.dueCount > 0 ? LumeColors.background : LumeColors.inkMuted,
                                  ),
                                ),
                              ),
                              if (deck.aiAssisted)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(color: LumeColors.surface, borderRadius: BorderRadius.circular(6)),
                                  child: Text('IA', style: TextStyle(fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: LumeColors.primary)),
                                ),
                              Text('${deck.totalCount} cartões', style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: LumeColors.inkMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: LumeColors.inkMuted),
            tooltip: 'Opções do baralho',
          ),
        ],
      ),
    );
  }
}
