import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';
import '../services/auth_service.dart';

/// Fonte única da verdade para os dados do usuário autenticado.
class UserRepository extends ChangeNotifier {
  UserRepository(this._authService);

  final AuthService _authService;

  AppUser? currentUser;

  bool login(String email, String password) {
    final user = _authService.login(AppUser.login(email: email, password: password));
    if (user == null) return false;
    currentUser = user;
    notifyListeners();
    return true;
  }

  bool signup(String name, String email, String password) {
    final user = _authService.signup(AppUser(name: name, email: email, password: password));
    if (user == null) return false;
    currentUser = user;
    notifyListeners();
    return true;
  }

  void updateProfile({String? name, String? email}) {
    if (name != null && name.trim().isNotEmpty) currentUser?.name = name.trim();
    if (email != null && email.trim().isNotEmpty) currentUser?.email = email.trim();
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  void deleteAccount() {
    currentUser = null;
    notifyListeners();
  }
}
