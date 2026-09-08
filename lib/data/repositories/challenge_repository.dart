import 'package:flutter/foundation.dart';

import '../../models/challenge_history_entry.dart';

/// Fonte única da verdade para o desafio semanal e seu histórico.
class ChallengeRepository extends ChangeNotifier {
  final List<ChallengeHistoryEntry> history = [];

  bool joined = false;

  void join() {
    joined = true;
    notifyListeners();
  }
}
