import 'package:flutter/foundation.dart';

import '../data/repositories/settings_repository.dart';
import '../data/repositories/user_repository.dart';
import '../models/app_user.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/challenge_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._userRepository, this._settingsRepository,
      this._progress, this._challenges) {
    _userRepository.addListener(notifyListeners);
    _settingsRepository.addListener(notifyListeners);
  }

  final ProgressRepository _progress;
  final ChallengeRepository _challenges;
  final UserRepository _userRepository;
  final SettingsRepository _settingsRepository;

  AppUser get currentUser => _userRepository.currentUser!;
  bool get biometricLockEnabled => _settingsRepository.biometricLockEnabled;
  bool get isDarkMode => _settingsRepository.isDarkMode;

  void setBiometricLockEnabled(bool enabled) =>
      _settingsRepository.setBiometricLockEnabled(enabled);

  Future<void> setDarkModeEnabled(bool enabled) =>
      _settingsRepository.setDarkModeEnabled(enabled);

  Future<void> logout() => _userRepository.logout();

  String get timeZone => _settingsRepository.timeZone;
  Future<void> setTimeZone(String zone) async {
    await _settingsRepository.setTimeZone(zone);
    await Future.wait(
        [_progress.fetchProgress(), _challenges.fetchChallenges()]);
  }

  Future<void> resetSettings() async {
    await _settingsRepository.reset();
    await Future.wait(
        [_progress.fetchProgress(), _challenges.fetchChallenges()]);
  }

  @override
  void dispose() {
    _userRepository.removeListener(notifyListeners);
    _settingsRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
