import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';
import '../services/auth_service.dart';

/// Fonte única da verdade para os dados do usuário autenticado.
class UserRepository extends ChangeNotifier {
  UserRepository(this._authService);

  final AuthService _authService;
  bool _disposed = false;
  int _sessionVersion = 0;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  AppUser? currentUser;
  bool newlyRegistered = false;
  bool restoring = true;
  String? restoreError;
  Future<void> restore() async {
    final version = ++_sessionVersion;
    restoring = true;
    try {
      final cached = await _authService.restoreCached();
      if (version != _sessionVersion || _disposed) return;
      currentUser = cached;
      if (cached != null) {
        restoring = false;
        restoreError = null;
        notifyListeners();
      }
      final validated = await _authService.restore();
      if (version != _sessionVersion || _disposed) return;
      currentUser = validated;
      restoreError = null;
    } catch (_) {
      if (version != _sessionVersion || _disposed) return;
      restoreError =
          'Não foi possível restaurar a sessão. Verifique sua conexão.';
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> requestReset(String email) => _authService.requestReset(email);
  Future<void> resetPassword(String token, String password) =>
      _authService.resetPassword(token, password);

  Future<bool> login(String email, String password) async {
    _sessionVersion++;
    final user = await _authService
        .login(AppUser.login(email: email, password: password));
    if (user == null) return false;
    newlyRegistered = false;
    currentUser = user;
    notifyListeners();
    return true;
  }

  Future<bool> signup(String name, String email, String password) async {
    _sessionVersion++;
    final user = await _authService
        .signup(AppUser(name: name, email: email, password: password));
    if (user == null) return false;
    newlyRegistered = true;
    currentUser = user;
    notifyListeners();
    return true;
  }

  Future<void> updateProfile(
      {String? name, String? email, String? password}) async {
    if (currentUser == null) throw StateError('Entre na sua conta.');
    final updated = await _authService.updateProfile(currentUser!.id!,
        name: name, email: email, password: password);
    if (updated == null) {
      throw StateError('Não foi possível atualizar o perfil.');
    }
    currentUser = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    _sessionVersion++;
    await _authService.logout();
    currentUser = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
    await logout();
  }
}
