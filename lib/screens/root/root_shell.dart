import 'package:flutter/material.dart';

import '../../theme/lume_colors.dart';
import '../challenge/challenge_screen.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';

/// Casca com a navegação inferior — Início, Baralhos e Desafios. As telas
/// de detalhe (baralho, estudo, criação, avisos) são empurradas por cima,
/// escondendo esta barra, como convém a uma tela de imersão total.
class RootShell extends StatefulWidget {
  const RootShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late int _index = widget.initialTab;

  void _goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(onGoToChallengeTab: () => _goToTab(2), onGoToLibraryTab: () => _goToTab(1)),
      const LibraryScreen(),
      const ChallengeScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: _LumeNavBar(index: _index, onChanged: _goToTab),
    );
  }
}

class _LumeNavBar extends StatelessWidget {
  const _LumeNavBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Início'),
    (icon: Icons.style_outlined, activeIcon: Icons.style_rounded, label: 'Baralhos'),
    (icon: Icons.diamond_outlined, activeIcon: Icons.diamond_rounded, label: 'Desafios'),
  ];

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      padding: EdgeInsets.only(top: 10, left: 12, right: 12, bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        color: LumeColors.background,
        border: Border(top: BorderSide(color: LumeColors.outline)),
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
                    color: selected ? LumeColors.primary : LumeColors.inkMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? LumeColors.primary : LumeColors.inkMuted,
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
