import 'package:flutter/foundation.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/deck_repository.dart';
import '../data/repositories/challenge_repository.dart';
import '../models/study_history_entry.dart';

class ProgressHistoryViewModel extends ChangeNotifier {
  ProgressHistoryViewModel(this._progress, this._decks, this._challenges) {
    load();
  }
  final ProgressRepository _progress;
  final DeckRepository _decks;
  final ChallengeRepository _challenges;
  final List<StudyHistoryEntry> entries = [];
  bool busy = false, hasMore = true, _disposed = false;
  String? error;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load({bool restart = false}) async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      final result =
          await _progress.history(offset: restart ? 0 : entries.length);
      if (restart) entries.clear();
      entries.addAll(result);
      hasMore = result.length == 50;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> reset() async {
    await _progress.reset();
    await Future.wait([_decks.fetchDecks(), _challenges.fetchChallenges()]);
    await load(restart: true);
  }
}
