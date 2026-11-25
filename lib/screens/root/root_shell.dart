import '../../data/repositories/deck_repository.dart';
import '../../widgets/feedback/lume_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/settings_repository.dart';
import '../../viewmodels/root_shell_view_model.dart';
import '../challenge/challenge_screen.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../../theme/lume_theme.dart';

/// Casca com a navegação inferior — Início, Baralhos, Desafios e Ajustes.
/// As telas de detalhe (baralho, estudo, criação, avisos) são empurradas
/// por cima, escondendo esta barra, como convém a uma tela de imersão total.
class RootShell extends StatelessWidget {
  const RootShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => RootShellViewModel(
          ctx.read<SettingsRepository>(), ctx.read<DeckRepository>()),
      child: _RootShellView(initialTab: initialTab),
    );
  }
}

class _RootShellView extends StatefulWidget {
  const _RootShellView({required this.initialTab});

  final int initialTab;

  @override
  State<_RootShellView> createState() => _RootShellViewState();
}

class _RootShellViewState extends State<_RootShellView> {
  late int _index = widget.initialTab;

  void _goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    // Observa a ViewModel aqui para que qualquer troca de tema/segurança
    // reconstrua toda a casca de uma vez, barra inferior incluída.
    final viewModel = context.watch<RootShellViewModel>();

    final tabs = [
      HomeScreen(
          onGoToChallengeTab: () => _goToTab(2),
          onGoToLibraryTab: () => _goToTab(1)),
      const LibraryScreen(),
      const ChallengeScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Column(children: [
        if (viewModel.syncMessage != null)
              SafeArea(
                  bottom: false,
                  child: MaterialBanner(
                    content: Text(viewModel.syncMessage!),
                    actions: [
                      TextButton(
                          onPressed:
                              viewModel.syncing ? null : viewModel.synchronize,
                          child: const Text('Sincronizar')),
                      if (viewModel.syncConflict)
                        TextButton(
                            onPressed: () async {
                              final discard = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                        title: const Text(
                                            'Usar dados do servidor?'),
                                        content: const Text(
                                            'As alterações ainda não sincronizadas deste aparelho serão descartadas. Esta ação não pode ser desfeita.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text(
                                                  'Manter alterações')),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text(
                                                  'Descartar e atualizar')),
                                        ],
                                      ));
                              if (discard != true) return;
                              try {
                                await viewModel.discardPending();
                              } catch (error) {
                                if (context.mounted) {
                                  showLumeToast(context, error.toString());
                                }
                              }
                            },
                            child: const Text('Resolver')),
                    ],
                  )),
            Expanded(child: IndexedStack(index: _index, children: tabs)),
          ]),
      bottomNavigationBar: _LumeNavBar(index: _index, onChanged: _goToTab),
    );
  }
}

class _LumeNavBar extends StatelessWidget {
  const _LumeNavBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Início'
    ),
    (
      icon: Icons.style_outlined,
      activeIcon: Icons.style_rounded,
      label: 'Baralhos'
    ),
    (
      icon: Icons.diamond_outlined,
      activeIcon: Icons.diamond_rounded,
      label: 'Desafios'
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Ajustes'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      padding: EdgeInsets.only(
          top: 10,
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: context.lume.background,
        border: Border(top: BorderSide(color: context.lume.outline)),
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 22,
                    color:
                        selected ? context.lume.primary : context.lume.inkMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? context.lume.primary
                          : context.lume.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
