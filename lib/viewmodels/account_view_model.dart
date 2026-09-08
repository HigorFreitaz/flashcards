import 'package:flutter/foundation.dart';

import '../data/repositories/user_repository.dart';
import '../models/app_user.dart';

class AccountViewModel extends ChangeNotifier {
  AccountViewModel(this._userRepository);

  final UserRepository _userRepository;

  AppUser get currentUser => _userRepository.currentUser!;

  void updateProfile({String? name, String? email}) => _userRepository.updateProfile(name: name, email: email);

  void deleteAccount() => _userRepository.deleteAccount();
}
