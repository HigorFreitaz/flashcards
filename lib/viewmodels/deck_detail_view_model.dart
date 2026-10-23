import 'package:flutter/foundation.dart';

import '../data/repositories/deck_repository.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

class DeckDetailViewModel extends ChangeNotifier {
  DeckDetailViewModel(this._deckRepository, this.deckId) {
    _deckRepository.addListener(notifyListeners);
  }

  final DeckRepository _deckRepository;
  final String deckId;

  Deck? get deck => _deckRepository.findDeck(deckId);

  Future<void> deleteDeck() => _deckRepository.deleteDeck(deckId);

  Future<void> deleteCard(String cardId) =>
      _deckRepository.deleteCard(deckId, cardId);

  Future<void> toggleSuspended(Flashcard card) =>
      _deckRepository.setSuspended(deckId, card, !card.suspended);
  @override
  void dispose() {
    _deckRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
