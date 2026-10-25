import '../services/offline_api_service.dart';
import 'package:flutter/foundation.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../services/api_service.dart';

class DeckRepository extends ChangeNotifier {
  DeckRepository([ApiService? apiService]) : _apiService = apiService {
    if (apiService is OfflineApiService) apiService.status.addListener(_onSync);
    if (_apiService?.authToken != null) fetchDecks();
  }
  final ApiService? _apiService;
  final List<Deck> decks = [];
  String? loadError;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    if (_apiService is OfflineApiService) {
      (_apiService).status.removeListener(_onSync);
    }
    _disposed = true;
    super.dispose();
  }

  SyncStatus? get syncStatus =>
      _apiService is OfflineApiService ? (_apiService).status : null;
  Future<void> synchronize() async {
    if (_apiService is OfflineApiService) await (_apiService).synchronize();
  }

  Future<void> discardPending() async {
    if (_apiService is OfflineApiService) await (_apiService).discardPending();
  }

  void _onSync() {
    if (syncStatus?.syncing == false) _reloadCache();
    notifyListeners();
  }

  Future<void> _reloadCache() async {
    final data = await (_apiService as OfflineApiService).cachedDecks();
    if (_disposed) return;
    decks
      ..clear()
      ..addAll(data.map((item) => Deck.fromJson(item as Map<String, dynamic>)));
    notifyListeners();
  }

  ApiService get _api => _apiService ?? (throw StateError('API indisponível.'));
  int get dueToday => decks.fold(0, (sum, d) => sum + d.studyQueue.length);
  Deck? findDeck(String id) {
    for (final deck in decks) {
      if (deck.id == id) return deck;
    }
    return null;
  }

  Future<void> fetchDecks() async {
    try {
      final response = await _api.get('/decks') as List;
      decks
        ..clear()
        ..addAll(response
            .map((item) => Deck.fromJson(item as Map<String, dynamic>)));
      loadError = null;
    } catch (error) {
      loadError = error.toString();
    }
    notifyListeners();
  }

  Future<Deck> createDeck(
      {required String name,
      String description = '',
      int dailyGoal = 20,
      bool remindersEnabled = true,
      List<String>? reminderTimes}) async {
    final response = await _api.post('/decks', {
      'name': name,
      'description': description,
      'dailyGoal': dailyGoal,
      'remindersEnabled': remindersEnabled,
      'reminderTimes': reminderTimes ?? ['20:00'],
    });
    final deck = Deck.fromJson(response as Map<String, dynamic>);
    decks.add(deck);
    notifyListeners();
    return deck;
  }

  Future<void> updateDeckMeta(String deckId,
      {String? name,
      String? description,
      int? dailyGoal,
      bool? remindersEnabled,
      List<String>? reminderTimes}) async {
    await _api.put('/decks/$deckId', {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (dailyGoal != null) 'dailyGoal': dailyGoal,
      if (remindersEnabled != null) 'remindersEnabled': remindersEnabled,
      if (reminderTimes != null) 'reminderTimes': reminderTimes,
    });
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

  Future<void> deleteDeck(String deckId) async {
    await _api.delete('/decks/$deckId');
    decks.removeWhere((d) => d.id == deckId);
    notifyListeners();
  }

  Future<void> addCard(String deckId, Flashcard card) async {
    final response = await _api.post('/decks/$deckId/cards', card.toJson());
    findDeck(deckId)
        ?.cards
        .add(Flashcard.fromJson(response as Map<String, dynamic>));
    notifyListeners();
  }

  Future<void> addGeneratedCards(String deckId, List<Flashcard> cards) async {
    final response = await _api.post('/decks/$deckId/cards/batch', {
      'cards': cards.map((card) => card.toJson()).toList(),
    }) as List;
    findDeck(deckId)?.cards.addAll(response
        .map((card) => Flashcard.fromJson(card as Map<String, dynamic>)));
    notifyListeners();
  }

  Future<void> updateCard(String deckId, Flashcard card,
      {String? targetDeckId}) async {
    final response = await _api.put('/decks/$deckId/cards/${card.id}', {
      ...card.toJson(),
      if (targetDeckId != null) 'targetDeckId': targetDeckId
    });
    final deck = findDeck(deckId);
    final saved = Flashcard.fromJson(response as Map<String, dynamic>);
    if (targetDeckId != null && targetDeckId != deckId) {
      deck?.cards.removeWhere((c) => c.id == card.id);
      findDeck(targetDeckId)?.cards.add(saved);
    } else {
      final index = deck?.cards.indexWhere((c) => c.id == card.id) ?? -1;
      if (index >= 0) deck!.cards[index] = saved;
    }
    notifyListeners();
  }

  Future<void> setSuspended(
      String deckId, Flashcard card, bool suspended) async {
    await _api.put('/decks/$deckId/cards/${card.id}', {'suspended': suspended});
    card.suspended = suspended;
    notifyListeners();
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    await _api.delete('/decks/$deckId/cards/$cardId');
    findDeck(deckId)?.cards.removeWhere((c) => c.id == cardId);
    notifyListeners();
  }

  Future<void> markCardReviewed(String deckId, String cardId,
      {bool? correct, int durationSeconds = 0, String? challengeId}) async {
    final response = await _api.post('/decks/$deckId/cards/$cardId/review', {
      'correct': correct,
      'durationSeconds': durationSeconds,
      if (challengeId != null) 'challengeId': challengeId
    });
    final card =
        findDeck(deckId)?.cards.where((c) => c.id == cardId).firstOrNull;
    if (card != null) {
      card.status = Flashcard.fromJson(response as Map<String, dynamic>).status;
    }
    notifyListeners();
  }
}
