import '../data/repositories/deck_repository.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/settings_repository.dart';

class RootShellViewModel extends ChangeNotifier {
  RootShellViewModel(this._settingsRepository, this._decks) {
    _settingsRepository.addListener(notifyListeners);
    _decks.addListener(notifyListeners);
  }

  final SettingsRepository _settingsRepository;
  final DeckRepository _decks;
  bool get syncConflict => _decks.syncStatus?.conflict ?? false;
  bool get syncing => _decks.syncStatus?.syncing ?? false;
  String? get syncMessage {
    final status = _decks.syncStatus;
    if (status == null) return null;
    if (status.error != null) return status.error;
    if (status.pending > 0) {
      return '${status.pending} alterações salvas no aparelho, aguardando sincronização.';
    }
    if (status.offline) {
      return 'Sem conexão. Exibindo os últimos dados salvos no aparelho.';
    }
    return null;
  }

  Future<void> synchronize() => _decks.synchronize();
  Future<void> discardPending() => _decks.discardPending();

  bool get biometricLockEnabled => _settingsRepository.biometricLockEnabled;

  @override
  void dispose() {
    _settingsRepository.removeListener(notifyListeners);
    _decks.removeListener(notifyListeners);
    super.dispose();
  }
}
