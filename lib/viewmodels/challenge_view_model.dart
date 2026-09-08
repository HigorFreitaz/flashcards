import 'package:flutter/foundation.dart';

import '../data/repositories/challenge_repository.dart';
import '../data/repositories/deck_repository.dart';
import '../models/challenge_history_entry.dart';
import '../models/deck.dart';

class ChallengeViewModel extends ChangeNotifier {
  ChallengeViewModel(this._deckRepository, this._challengeRepository) {
    _deckRepository.addListener(notifyListeners);
    _challengeRepository.addListener(notifyListeners);
  }

  final DeckRepository _deckRepository;
  final ChallengeRepository _challengeRepository;

  List<Deck> get decks => _deckRepository.decks;
  List<ChallengeHistoryEntry> get challengeHistory => _challengeRepository.history;
  bool get challengeJoined => _challengeRepository.joined;

  void joinChallenge() => _challengeRepository.join();

  @override
  void dispose() {
    _deckRepository.removeListener(notifyListeners);
    _challengeRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
