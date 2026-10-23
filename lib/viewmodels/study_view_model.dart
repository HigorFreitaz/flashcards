import 'package:flutter/foundation.dart';
import '../data/repositories/deck_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/challenge_repository.dart';
import '../data/repositories/notification_repository.dart';

class StudyViewModel extends ChangeNotifier {
  StudyViewModel(this._decks, this._progress, this._challenges,
      [this._notifications]);
  final NotificationRepository? _notifications;
  final DeckRepository _decks;
  final ProgressRepository _progress;
  final ChallengeRepository _challenges;
  Future<void> markCardReviewed(String deckId, String cardId,
      {bool? correct, int durationSeconds = 0, String? challengeId}) async {
    await _decks.markCardReviewed(deckId, cardId,
        correct: correct,
        durationSeconds: durationSeconds,
        challengeId: challengeId);
    await Future.wait([
      _progress.fetchProgress(),
      _challenges.fetchChallenges(),
      if (_notifications != null) _notifications.fetchNotifications()
    ]);
  }
}
