import 'package:flutter/foundation.dart';

import '../data/repositories/settings_repository.dart';

class RootShellViewModel extends ChangeNotifier {
  RootShellViewModel(this._settingsRepository) {
    _settingsRepository.addListener(notifyListeners);
  }

  final SettingsRepository _settingsRepository;

  bool get biometricLockEnabled => _settingsRepository.biometricLockEnabled;

  @override
  void dispose() {
    _settingsRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
