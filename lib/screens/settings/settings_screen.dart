import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../state/app_state.dart';
import '../../theme/lume_metrics.dart';
import '../../theme/lume_theme.dart';
import '../../widgets/feedback/lume_bottom_sheet.dart';
import '../../widgets/buttons/lume_button.dart';
import '../../widgets/inputs/lume_switch.dart';
import '../../widgets/inputs/lume_text_field.dart';
import '../auth/auth_screen.dart';
import 'account_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final choice = await showLumeActionSheet(
      context,
      title: 'Sair da conta',
      actions: const [LumeSheetAction(label: 'Sair da conta', danger: true)],
    );
    if (choice != 0 || !context.mounted) return;
    final appState = context.read<AppState>();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
    );
    appState.currentUser = null;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
            child: Text(
              'Ajustes',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                color: context.lume.ink,
              ),
            ),
          ),
          const LumeFieldLabel('Conta'),
          _AccountRow(
            user: app.currentUser!,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
          const SizedBox(height: LumeSpacing.section),
          const LumeFieldLabel('Segurança'),
          _ToggleRow(
            title: 'Bloqueio por biometria',
            subtitle: 'Peça digital ou Face ID toda vez que o app voltar do segundo plano.',
            value: app.biometricLockEnabled,
            onChanged: (v) {
              context.read<AppState>().setBiometricLockEnabled(v);
              context.read<AppState>().showToast(v ? 'Bloqueio por biometria ativado' : 'Bloqueio por biometria desativado');
            },
          ),
          const SizedBox(height: LumeSpacing.section),
          const LumeFieldLabel('Aparência'),
          _ToggleRow(
            title: 'Tema escuro',
            subtitle: 'Troca a paleta clara pela escura em todo o app.',
            value: app.isDarkMode,
            onChanged: (v) => context.read<AppState>().setDarkModeEnabled(v),
          ),
          const SizedBox(height: LumeSpacing.section),
          LumeButton(
            label: 'Sair da conta',
            variant: LumeButtonVariant.danger,
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.user, required this.onTap});

  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Material(
      color: context.lume.background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: context.lume.outline),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: Text(
                  user.initials,
                  style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: context.lume.primary),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: context.lume.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: fontFamily, fontSize: 13, color: context.lume.inkMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.lume.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.title, required this.subtitle, required this.value, required this.onChanged});

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: context.lume.ink)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontFamily: fontFamily, fontSize: 13, height: 1.4, color: context.lume.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          LumeSwitch(value: value, semanticLabel: title, onChanged: onChanged),
        ],
      ),
    );
  }
}