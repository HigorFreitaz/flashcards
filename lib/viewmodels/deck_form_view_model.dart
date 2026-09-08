import 'package:flutter/foundation.dart';

import '../data/repositories/deck_repository.dart';
import '../models/deck.dart';

class DeckFormViewModel extends ChangeNotifier {
  DeckFormViewModel(this._deckRepository, this.deckId);

  final DeckRepository _deckRepository;
  final String? deckId;

  bool get isEditing => deckId != null;

  Deck? get existingDeck => deckId == null ? null : _deckRepository.findDeck(deckId!);

  /// Cria o baralho, ou atualiza um existente quando [deckId] foi informado.
  /// Retorna o baralho salvo.
  Deck save({
    required String name,
    required String description,
    required int dailyGoal,
    required bool remindersEnabled,
    required List<String> reminderTimes,
  }) {
    final resolvedName = name.isEmpty ? 'Sem título' : name;
    if (deckId != null) {
      _deckRepository.updateDeckMeta(
        deckId!,
        name: resolvedName,
        description: description,
        dailyGoal: dailyGoal,
        remindersEnabled: remindersEnabled,
        reminderTimes: reminderTimes,
      );
      return _deckRepository.findDeck(deckId!)!;
    }
    return _deckRepository.createDeck(
      name: resolvedName,
      description: description,
      dailyGoal: dailyGoal,
      remindersEnabled: remindersEnabled,
      reminderTimes: reminderTimes,
    );
  }
}
