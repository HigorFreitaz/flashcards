import 'package:flutter/foundation.dart';

import '../data/repositories/deck_repository.dart';
import '../models/deck.dart';

class DeckDetailViewModel extends ChangeNotifier {
  DeckDetailViewModel(this._deckRepository, this.deckId) {
    _deckRepository.addListener(notifyListeners);
  }

  final DeckRepository _deckRepository;
  final String deckId;

  Deck? get deck => _deckRepository.findDeck(deckId);

  void deleteDeck() => _deckRepository.deleteDeck(deckId);

  void deleteCard(String cardId) => _deckRepository.deleteCard(deckId, cardId);

  @override
  void dispose() {
    _deckRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
