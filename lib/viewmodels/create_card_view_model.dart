import 'package:flutter/foundation.dart';

import '../data/repositories/deck_repository.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

class CreateCardViewModel extends ChangeNotifier {
  CreateCardViewModel(this._deckRepository, {required this.editingCardId}) {
    _deckRepository.addListener(notifyListeners);
  }

  final DeckRepository _deckRepository;
  final String? editingCardId;

  List<Deck> get decks => _deckRepository.decks;

  Deck? findDeck(String id) => _deckRepository.findDeck(id);

  Flashcard? editingCard(String deckId) {
    if (editingCardId == null) return null;
    return findDeck(deckId)?.cards.firstWhere(
        (c) => c.id == editingCardId,
        orElse: () => Flashcard(id: '', front: '', back: ''));
  }

  void saveTypedCard(String targetDeckId, Flashcard card) {
    if (editingCardId != null && editingCardId!.isNotEmpty) {
      _deckRepository.updateCard(targetDeckId, card);
    } else {
      _deckRepository.addCard(targetDeckId, card);
    }
  }

  void saveGeneratedCards(String targetDeckId, List<Flashcard> cards) {
    for (final card in cards) {
      _deckRepository.addCard(targetDeckId, card);
    }
  }

  @override
  void dispose() {
    _deckRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
