import 'package:flutter/foundation.dart';

import '../data/repositories/deck_repository.dart';

class StudyViewModel extends ChangeNotifier {
  StudyViewModel(this._deckRepository);

  final DeckRepository _deckRepository;

  void markCardReviewed(String deckId, String cardId, {bool? correct}) {
    _deckRepository.markCardReviewed(deckId, cardId, correct: correct);
  }
}
