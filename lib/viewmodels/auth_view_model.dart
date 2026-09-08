import 'package:flutter/foundation.dart';

import '../data/repositories/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._userRepository);

  final UserRepository _userRepository;

  bool login(String email, String password) => _userRepository.login(email, password);

  bool signup(String name, String email, String password) => _userRepository.signup(name, email, password);
}
