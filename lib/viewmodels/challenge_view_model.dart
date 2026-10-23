import 'package:flutter/foundation.dart';

import '../data/repositories/challenge_repository.dart';
import '../data/repositories/deck_repository.dart';
import '../models/challenge_history_entry.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../models/study_queue_item.dart';

class ChallengeViewModel extends ChangeNotifier {
  ChallengeViewModel(this._deckRepository, this._challengeRepository) {
    _deckRepository.addListener(notifyListeners);
    _challengeRepository.addListener(notifyListeners);
  }

  final DeckRepository _deckRepository;
  final ChallengeRepository _challengeRepository;

  List<Deck> get decks => _deckRepository.decks;
  List<ChallengeHistoryEntry> get challengeHistory =>
      _challengeRepository.history;
  bool get challengeJoined => _challengeRepository.joined;

  Future<ChallengeHistoryEntry> joinChallenge() => _challengeRepository.join();

  String? get error => _challengeRepository.error;
  Future<void> refresh() => _challengeRepository.fetchChallenges();
  Future<void> saveChallenge(
          {String? id,
          required String title,
          required int targetCount,
          required List<String> deckIds,
          required int durationDays,
          required bool weakOnly}) =>
      _challengeRepository.save({
        'title': title,
        'targetCount': targetCount,
        'deckIds': deckIds,
        'durationDays': durationDays,
        'weakOnly': weakOnly,
      }, id: id);
  Future<void> cancel(String id) => _challengeRepository.cancel(id);
  Future<void> delete(String id) => _challengeRepository.delete(id);
  int get weeklyAnswered => _challengeRepository.weeklyAnswered;
  ChallengeHistoryEntry? get currentWeekly => challengeHistory
      .where((entry) =>
          entry.kind == 'weekly' &&
          entry.endsAt != null &&
          entry.endsAt!.isAfter(DateTime.now()))
      .firstOrNull;
  List<StudyQueueItem> queueFor(ChallengeHistoryEntry challenge) {
    final source = decks.where((deck) =>
        challenge.kind == 'weekly' || challenge.deckIds.contains(deck.id));
    return source
        .expand((deck) => deck.cards
            .where((card) =>
                !card.suspended &&
                (!challenge.weakOnly || card.status == CardStatus.aRevisar))
            .map((card) => StudyQueueItem(
                deckId: deck.id, deckName: deck.name, card: card)))
        .take((challenge.targetCount - challenge.answered).clamp(0, 1000))
        .toList();
  }

  @override
  void dispose() {
    _deckRepository.removeListener(notifyListeners);
    _challengeRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
