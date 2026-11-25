import 'package:flutter/material.dart';

import '../../theme/lume_theme.dart';
import '../../widgets/buttons/lume_button.dart';

/// Tela de bloqueio biométrico exibida quando o app é bloqueado por segurança.
class BiometricLockScreen extends StatelessWidget {
  const BiometricLockScreen({
    super.key,
    required this.onUnlock,
    required this.onLogout,
    this.errorMessage,
    this.isAuthenticating = false,
  });

  final VoidCallback onUnlock;
  final VoidCallback onLogout;
  final String? errorMessage;
  final bool isAuthenticating;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    return Positioned.fill(
      child: Material(
        color: context.lume.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: context.lume.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.lume.outline),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 46,
                      color: context.lume.primary,
                    ),
                  ),
                  Text(
                    'Lume bloqueado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: context.lume.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use sua digital ou Face ID para continuar seus estudos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 14,
                      height: 1.45,
                      color: context.lume.inkMuted,
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  LumeButton(
                    label: isAuthenticating ? 'Autenticando...' : 'Desbloquear',
                    icon: Icons.fingerprint_rounded,
                    loading: isAuthenticating,
                    expand: false,
                    onPressed: isAuthenticating ? null : onUnlock,
                  ),
                  const SizedBox(height: 14),
                  LumeButton(
                    label: 'Sair da conta',
                    variant: LumeButtonVariant.text,
                    expand: false,
                    onPressed: isAuthenticating ? null : onLogout,
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
