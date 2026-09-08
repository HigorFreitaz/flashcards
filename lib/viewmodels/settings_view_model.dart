import 'package:flutter/foundation.dart';

import '../data/repositories/settings_repository.dart';
import '../data/repositories/user_repository.dart';
import '../models/app_user.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._userRepository, this._settingsRepository) {
    _userRepository.addListener(notifyListeners);
    _settingsRepository.addListener(notifyListeners);
  }

  final UserRepository _userRepository;
  final SettingsRepository _settingsRepository;

  AppUser get currentUser => _userRepository.currentUser!;
  bool get biometricLockEnabled => _settingsRepository.biometricLockEnabled;
  bool get isDarkMode => _settingsRepository.isDarkMode;

  void setBiometricLockEnabled(bool enabled) => _settingsRepository.setBiometricLockEnabled(enabled);

  void setDarkModeEnabled(bool enabled) => _settingsRepository.setDarkModeEnabled(enabled);

  void logout() => _userRepository.logout();

  @override
  void dispose() {
    _userRepository.removeListener(notifyListeners);
    _settingsRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
