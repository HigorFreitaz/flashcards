import 'deck.dart';
import 'flashcard.dart';

/// Um cartão amarrado ao baralho de origem — para que a resposta seja
/// registrada no lugar certo mesmo numa sessão que mistura vários baralhos.
class StudyQueueItem {
  const StudyQueueItem(
      {required this.deckId, required this.deckName, required this.card});

  final String deckId;
  final String deckName;
  final Flashcard card;

  static List<StudyQueueItem> fromDecks(Iterable<Deck> decks) {
    return decks
        .expand((deck) => deck.studyQueue.map((card) =>
            StudyQueueItem(deckId: deck.id, deckName: deck.name, card: card)))
        .toList();
  }

  static List<StudyQueueItem> fromDeck(Deck deck) {
    return deck.studyQueue
        .map((card) =>
            StudyQueueItem(deckId: deck.id, deckName: deck.name, card: card))
        .toList();
  }
}
