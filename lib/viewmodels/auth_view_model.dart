import 'package:flutter/foundation.dart';

import '../data/repositories/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._userRepository);

  final UserRepository _userRepository;

  Future<bool> login(String email, String password) =>
      _userRepository.login(email, password);

  Future<bool> signup(String name, String email, String password) =>
      _userRepository.signup(name, email, password);
  String? get restoreError => _userRepository.restoreError;
  Future<void> restore() => _userRepository.restore();
  Future<void> requestReset(String email) =>
      _userRepository.requestReset(email);
  Future<void> resetPassword(String token, String password) =>
      _userRepository.resetPassword(token, password);
}
