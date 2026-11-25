import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/biometric_service.dart';
import 'biometric_lock_screen.dart';

/// Envolve a aplicação e gerencia o estado de bloqueio biométrico global.
/// Quando o bloqueio está ativo e o usuário retorna ao app do segundo plano,
/// ou na inicialização com sessão ativa, apresenta a tela de bloqueio e solicita
/// autenticação biométrica.
class BiometricLockWrapper extends StatefulWidget {
  const BiometricLockWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<BiometricLockWrapper> createState() => _BiometricLockWrapperState();
}

class _BiometricLockWrapperState extends State<BiometricLockWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;
  String? _errorMessage;
  String? _knownUserId;
  bool _coldStartEvaluated = false;
  bool _wasBackgrounded = false;

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

    // Se estiver em processo de autenticação biométrica, qualquer transição
    // de ciclo de vida (como o diálogo do sistema sobrepondo o app) não deve
    // ser tratada como envio do app para segundo plano.
    if (_isAuthenticating) return;

    final userRepo = context.read<UserRepository>();
    final settingsRepo = context.read<SettingsRepository>();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (userRepo.currentUser != null && settingsRepo.biometricLockEnabled) {
        _wasBackgrounded = true;
        setState(() {
          _isLocked = true;
          _errorMessage = null;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasBackgrounded &&
          userRepo.currentUser != null &&
          settingsRepo.biometricLockEnabled) {
        _wasBackgrounded = false;
        if (_isLocked && !_isAuthenticating) {
          _promptAuthentication();
        }
      }
    }
  }

  Future<void> _promptAuthentication() async {
    if (_isAuthenticating || !_isLocked || !mounted) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final biometricService = context.read<BiometricService>();
    final success = await biometricService.authenticate(
      localizedReason: 'Confirme sua identidade para acessar o Lume',
    );

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
      if (success) {
        _isLocked = false;
        _errorMessage = null;
        _wasBackgrounded = false;
      } else {
        _errorMessage =
            'Não foi possível autenticar. Toque em Desbloquear para tentar novamente.';
      }
    });
  }

  void _logout() {
    setState(() {
      _isLocked = false;
      _errorMessage = null;
      _coldStartEvaluated = false;
      _knownUserId = null;
      _wasBackgrounded = false;
    });
    context.read<UserRepository>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final userRepo = context.watch<UserRepository>();
    final settingsRepo = context.watch<SettingsRepository>();
    final currentUserId = userRepo.currentUser?.id;

    // Se o usuário deslogou ou não está logado, remove o bloqueio.
    if (currentUserId == null) {
      if (_isLocked) {
        _isLocked = false;
      }
      _knownUserId = null;
      _coldStartEvaluated = false;
      _wasBackgrounded = false;
    } else {
      // Se a preferência de bloqueio foi desmarcada, destrava imediatamente.
      if (!settingsRepo.biometricLockEnabled && _isLocked) {
        _isLocked = false;
        _errorMessage = null;
        _wasBackgrounded = false;
      }

      // Verificação de inicialização (cold-start com sessão restaurada).
      if (!_coldStartEvaluated && !userRepo.restoring && settingsRepo.loaded) {
        _coldStartEvaluated = true;
        if (_knownUserId == null && settingsRepo.biometricLockEnabled) {
          _isLocked = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isLocked) {
              _promptAuthentication();
            }
          });
        }
        _knownUserId = currentUserId;
      } else if (_knownUserId != currentUserId && settingsRepo.loaded) {
        _knownUserId = currentUserId;
      }
    }

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        IgnorePointer(
          ignoring: _isLocked,
          child: ExcludeSemantics(
            excluding: _isLocked,
            child: widget.child,
          ),
        ),
        if (_isLocked)
          BiometricLockScreen(
            onUnlock: _promptAuthentication,
            onLogout: _logout,
            errorMessage: _errorMessage,
            isAuthenticating: _isAuthenticating,
          ),
      ],
    );
  }
}
