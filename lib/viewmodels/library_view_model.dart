import 'package:flutter/foundation.dart';

import '../data/repositories/deck_repository.dart';
import '../models/deck.dart';

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel(this._deckRepository) {
    _deckRepository.addListener(notifyListeners);
  }

  final DeckRepository _deckRepository;

  List<Deck> get decks => _deckRepository.decks;

  String? get loadError => _deckRepository.loadError;
  Future<void> retry() => _deckRepository.fetchDecks();

  Future<void> deleteDeck(String deckId) => _deckRepository.deleteDeck(deckId);

  @override
  void dispose() {
    _deckRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
