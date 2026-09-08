import 'package:flutter/foundation.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';

/// Fonte única da verdade para baralhos e cartões.
class DeckRepository extends ChangeNotifier {
  final List<Deck> decks = [];

  int get dueToday => decks.fold(0, (sum, d) => sum + d.dueCount);

  Deck? findDeck(String id) {
    for (final deck in decks) {
      if (deck.id == id) return deck;
    }
    return null;
  }

  Deck createDeck({
    required String name,
    String description = '',
    int dailyGoal = 20,
    bool remindersEnabled = true,
    List<String>? reminderTimes,
  }) {
    final deck = Deck(
      id: 'deck-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      description: description,
      dailyGoal: dailyGoal,
      remindersEnabled: remindersEnabled,
      reminderTimes: reminderTimes,
    );
    decks.add(deck);
    notifyListeners();
    return deck;
  }

  void updateDeckMeta(
    String deckId, {
    String? name,
    String? description,
    int? dailyGoal,
    bool? remindersEnabled,
    List<String>? reminderTimes,
  }) {
    final deck = findDeck(deckId);
    if (deck == null) return;
    if (name != null) deck.name = name;
    if (description != null) deck.description = description;
    if (dailyGoal != null) deck.dailyGoal = dailyGoal;
    if (remindersEnabled != null) deck.remindersEnabled = remindersEnabled;
    if (reminderTimes != null) deck.reminderTimes = reminderTimes;
    deck.updatedAt = DateTime.now();
    notifyListeners();
  }

  void deleteDeck(String deckId) {
    decks.removeWhere((d) => d.id == deckId);
    notifyListeners();
  }

  void addCard(String deckId, Flashcard card) {
    findDeck(deckId)?.cards.add(card);
    notifyListeners();
  }

  void updateCard(String deckId, Flashcard updated) {
    final deck = findDeck(deckId);
    if (deck == null) return;
    final index = deck.cards.indexWhere((c) => c.id == updated.id);
    if (index != -1) deck.cards[index] = updated;
    notifyListeners();
  }

  void deleteCard(String deckId, String cardId) {
    findDeck(deckId)?.cards.removeWhere((c) => c.id == cardId);
    notifyListeners();
  }

  void markCardReviewed(String deckId, String cardId, {bool? correct}) {
    final deck = findDeck(deckId);
    if (deck == null) return;
    final card = deck.cards.firstWhere((c) => c.id == cardId, orElse: () => throw StateError('cartão não encontrado'));
    if (correct == false) {
      card.status = CardStatus.aRevisar;
    } else if (card.status == CardStatus.novo) {
      card.status = CardStatus.aRevisar;
    } else {
      card.status = CardStatus.dominado;
    }
    notifyListeners();
  }
}
