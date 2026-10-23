import 'package:flutter/foundation.dart';

import '../data/repositories/deck_repository.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

class CreateCardViewModel extends ChangeNotifier {
  CreateCardViewModel(this._deckRepository,
      {required this.editingCardId, required this.originalDeckId}) {
    _deckRepository.addListener(notifyListeners);
  }

  final DeckRepository _deckRepository;
  final String? editingCardId;
  final String originalDeckId;

  List<Deck> get decks => _deckRepository.decks;

  Deck? findDeck(String id) => _deckRepository.findDeck(id);

  Flashcard? editingCard(String deckId) {
    if (editingCardId == null) return null;
    return findDeck(deckId)?.cards.firstWhere((c) => c.id == editingCardId,
        orElse: () => Flashcard(id: '', front: '', back: ''));
  }

  Future<void> saveTypedCard(String targetDeckId, Flashcard card) async {
    if (editingCardId != null && editingCardId!.isNotEmpty) {
      await _deckRepository.updateCard(originalDeckId, card,
          targetDeckId: targetDeckId);
    } else {
      await _deckRepository.addCard(targetDeckId, card);
    }
  }

  Future<void> saveGeneratedCards(
      String targetDeckId, List<Flashcard> cards) async {
    await _deckRepository.addGeneratedCards(targetDeckId, cards);
  }

  @override
  void dispose() {
    _deckRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
