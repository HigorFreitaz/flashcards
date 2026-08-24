import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/buttons/lume_button.dart';
import '../challenge/challenge_screen.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';

/// Casca com a navegação inferior — Início, Baralhos, Desafios e Ajustes.
/// As telas de detalhe (baralho, estudo, criação, avisos) são empurradas
/// por cima, escondendo esta barra, como convém a uma tela de imersão total.
class RootShell extends StatefulWidget {
  const RootShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  late int _index = widget.initialTab;
  bool _locked = false;

  void _goToTab(int index) => setState(() => _index = index);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed && context.read<AppState>().biometricLockEnabled) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa o AppState aqui para que qualquer troca de tema/segurança
    // reconstrua toda a casca de uma vez, barra inferior incluída.
    context.watch<AppState>();

    final tabs = [
      HomeScreen(onGoToChallengeTab: () => _goToTab(2), onGoToLibraryTab: () => _goToTab(1)),
      const LibraryScreen(),
      const ChallengeScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: tabs),
          if (_locked) _BiometricLockScreen(onUnlock: () => setState(() => _locked = false)),
        ],
      ),
      bottomNavigationBar: _LumeNavBar(index: _index, onChanged: _goToTab),
    );
  }
}

class _BiometricLockScreen extends StatelessWidget {
  const _BiometricLockScreen({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Positioned.fill(
      child: ColoredBox(
        color: context.lume.background,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(28)),
                    alignment: Alignment.center,
                    child: Icon(Icons.fingerprint, size: 42, color: context.lume.primary),
                  ),
                  Text(
                    'Lume bloqueado',
                    style: TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: context.lume.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use sua digital ou Face ID para continuar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: fontFamily, fontSize: 14, height: 1.4, color: context.lume.inkMuted),
                  ),
                  const SizedBox(height: 30),
                  LumeButton(
                    label: 'Desbloquear',
                    icon: Icons.fingerprint,
                    expand: false,
                    onPressed: onUnlock,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    (icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      padding: EdgeInsets.only(top: 10, left: 12, right: 12, bottom: MediaQuery.of(context).padding.bottom + 8),
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
                    color: selected ? context.lume.primary : context.lume.inkMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? context.lume.primary : context.lume.inkMuted,
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
