import 'package:flutter/material.dart';

/// Guarda as preferências do app (tema e bloqueio por biometria). É a única
/// camada de dados que depende de um tipo do Flutter ([ThemeMode]) — ele
/// representa a própria preferência armazenada, não uma construção de UI.
class SettingsRepository extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  bool get isDarkMode => themeMode == ThemeMode.dark;

  bool biometricLockEnabled = false;

  void setDarkModeEnabled(bool enabled) {
    themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setBiometricLockEnabled(bool enabled) {
    biometricLockEnabled = enabled;
    notifyListeners();
  }
}
