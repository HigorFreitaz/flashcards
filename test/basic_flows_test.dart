import 'package:lume/screens/challenge/challenge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lume/app.dart';
import 'package:lume/data/services/session_store.dart';
import 'package:lume/screens/deck/deck_detail_screen.dart';
import 'package:lume/screens/create_card/create_card_screen.dart';
import 'package:lume/screens/study/study_screen.dart';
import 'package:lume/theme/lume_theme.dart';
import 'package:lume/widgets/buttons/lume_button.dart';
import 'package:lume/data/services/api_service.dart';
import 'package:lume/data/services/auth_service.dart';
import 'package:lume/data/repositories/deck_repository.dart';
import 'package:lume/data/repositories/user_repository.dart';
import 'package:lume/data/repositories/progress_repository.dart';
import 'package:lume/data/repositories/challenge_repository.dart';
import 'package:lume/models/deck.dart';
import 'package:lume/models/flashcard.dart';
import 'package:lume/viewmodels/study_view_model.dart';

class FakeApi extends ApiService {
  bool fail = false;
  final writes = <String>[];
  final reads = <String>[];
  Map<String, dynamic>? lastPut;
  Map<String, dynamic>? lastReview;
  bool expired = false;
  final deckData = {'id': 'deck-1', 'name': 'Biology', 'cards': <dynamic>[]};
  void check() {
    if (fail) throw Exception('Servidor indisponível');
  }

  @override
  Future<dynamic> get(String endpoint) async {
    check();
    reads.add(endpoint);
    if (endpoint == '/auth/me') {
      if (expired) throw ApiException(401, 'Expired');
      return {
        'user': {'id': authToken, 'name': authToken, 'email': authToken}
      };
    }
    switch (endpoint) {
      case '/decks':
        return [
          {...deckData, 'name': authToken ?? 'Biology'}
        ];
      case '/progress':
        return {'totalXp': 10, 'reviewedToday': 1};
      case '/challenges':
        return {'weeklyAnswered': 1};
      case '/notifications':
        return [];
      case '/settings':
        return {'themeMode': 'light'};
      default:
        throw StateError(endpoint);
    }
  }

  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    check();
    writes.add(endpoint);
    if (endpoint == '/auth/login') {
      return {
        'token': body['email'],
        'user': {
          'id': body['email'],
          'name': body['email'],
          'email': body['email']
        },
      };
    }
    if (endpoint == '/auth/logout') return null;
    if (endpoint == '/decks') return {...deckData, ...body};
    if (endpoint.endsWith('/review')) {
      lastReview = body;
      return {'id': 'card-1', 'status': 'aRevisar'};
    }
    if (endpoint.endsWith('/cards')) return {...body, 'id': 'server-card'};
    throw StateError(endpoint);
  }

  @override
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    check();
    lastPut = body;
    return body;
  }

  @override
  Future<dynamic> delete(String endpoint) async {
    check();
    return null;
  }
}

class EmptyAccountApi extends FakeApi {
  @override
  Future<dynamic> get(String endpoint) async {
    if (endpoint == '/decks') return <dynamic>[];
    if (endpoint == '/progress') {
      return {
        'streakDays': 0,
        'totalXp': 0,
        'reviewedToday': 0,
        'weekProgress': List<bool>.filled(7, false)
      };
    }
    if (endpoint == '/challenges') return {'weeklyAnswered': 0};
    return super.get(endpoint);
  }
}

void main() {
  testWidgets('AI prototype cannot create a real challenge', (tester) async {
    final api = EmptyAccountApi();
    final decks = DeckRepository(api);
    final challenges = ChallengeRepository(api);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: decks),
          ChangeNotifierProvider.value(value: challenges),
        ],
        child: MaterialApp(
            theme: buildLumeTheme(brightness: Brightness.light),
            home: const ChallengeScreen())));
    await tester.pumpAndSettle();
    expect(find.text('PROTÓTIPO · SEM INTEGRAÇÃO COM IA'), findsOneWidget);
    final button = tester.widget<LumeButton>(
        find.widgetWithText(LumeButton, 'IA ainda não integrada'));
    expect(button.onPressed, isNull);
    await tester.tap(find.text('IA ainda não integrada'));
    await tester.pumpAndSettle();
    expect(api.writes, isEmpty);
    expect(challenges.history, isEmpty);
    await tester.tap(find.text('Criar meu'));
    await tester.pumpAndSettle();
    expect(find.text('Criar desafio com 15 perguntas'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    decks.dispose();
    challenges.dispose();
  });

  testWidgets('fresh account shows no streak or invented study completion',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(LumeApp(apiService: EmptyAccountApi()));
    await tester.pumpAndSettle();
    final users =
        tester.element(find.byType(MaterialApp)).read<UserRepository>();
    await users.login('new-account', 'password');
    await tester.pumpAndSettle();
    expect(find.text('Sem sequência ainda'), findsOneWidget);
    expect(find.text('0 XP'), findsOneWidget);
    expect(find.text('Nenhum baralho criado ainda'), findsOneWidget);
    expect(find.text('Tudo revisado'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('failed saves and deletes preserve local state and propagate errors',
      () async {
    final api = FakeApi();
    final repository = DeckRepository(api);
    final card = Flashcard(id: 'card-1', front: 'Q', back: 'A');
    repository.decks.add(Deck(id: 'deck-1', name: 'Original', cards: [card]));
    api.fail = true;
    await expectLater(repository.createDeck(name: 'Unsaved'), throwsException);
    await expectLater(
        repository.updateDeckMeta('deck-1', name: 'Changed'), throwsException);
    await expectLater(repository.deleteDeck('deck-1'), throwsException);
    await expectLater(
        repository.addCard(
            'deck-1', Flashcard(id: 'new', front: 'Q', back: 'A')),
        throwsException);
    await expectLater(
        repository.deleteCard('deck-1', 'card-1'), throwsException);
    await expectLater(
        repository.markCardReviewed('deck-1', 'card-1'), throwsException);
    expect(repository.decks.length, 1);
    expect(repository.decks.single.name, 'Original');
    expect(repository.decks.single.cards, [card]);
    expect(card.status, CardStatus.novo);
    repository.dispose();
  });

  test('review refreshes statistics only after persistence succeeds', () async {
    final api = FakeApi();
    final decks = DeckRepository(api);
    decks.decks.add(Deck(
        id: 'deck-1',
        name: 'Biology',
        cards: [Flashcard(id: 'card-1', front: 'Q', back: 'A')]));
    final progress = ProgressRepository(api);
    final challenges = ChallengeRepository(api);
    final vm = StudyViewModel(decks, progress, challenges);
    api.fail = true;
    await expectLater(vm.markCardReviewed('deck-1', 'card-1'), throwsException);
    expect(api.reads, isEmpty);
    api.fail = false;
    await vm.markCardReviewed('deck-1', 'card-1', correct: true);
    expect(api.reads, containsAll(['/progress', '/challenges']));
    expect(progress.totalXp, 10);
    expect(challenges.weeklyAnswered, 1);
    expect(decks.decks.single.cards.single.status, CardStatus.aRevisar);
    vm.dispose();
    decks.dispose();
    progress.dispose();
    challenges.dispose();
  });

  test('failed account deletion retains the current user and session',
      () async {
    final api = FakeApi();
    final users = UserRepository(AuthService(api));
    await users.login('alice', 'password');
    api.fail = true;
    await expectLater(users.deleteAccount(), throwsException);
    expect(users.currentUser?.id, 'alice');
    expect(api.authToken, 'alice');
    api.fail = false;
    await users.deleteAccount();
    expect(users.currentUser, isNull);
    expect(api.authToken, isNull);
    users.dispose();
  });

  testWidgets('login and account switching rebuild scoped data and navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakeApi();
    await tester.pumpWidget(LumeApp(apiService: api));
    await tester.pumpAndSettle();
    final users =
        tester.element(find.byType(MaterialApp)).read<UserRepository>();
    await users.login('alice', 'password');
    await tester.pumpAndSettle();
    final aliceDecks =
        tester.element(find.byType(MaterialApp)).read<DeckRepository>();
    expect(aliceDecks.decks.single.name, 'alice');
    await users.logout();
    await tester.pumpAndSettle();
    expect(find.text('Entrar na sua conta'), findsOneWidget);
    await users.login('bob', 'password');
    await tester.pumpAndSettle();
    final bobDecks =
        tester.element(find.byType(MaterialApp)).read<DeckRepository>();
    expect(identical(aliceDecks, bobDecks), isFalse);
    expect(bobDecks.decks.single.name, 'bob');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('saved session restores after restart and expired sessions are cleared',
      () async {
    final store = MemorySessionStore();
    final first = UserRepository(AuthService(FakeApi(), sessionStore: store));
    await first.login('persisted@test.local', 'password123');
    final secondApi = FakeApi();
    final second = UserRepository(AuthService(secondApi, sessionStore: store));
    await second.restore();
    expect(second.currentUser?.email, 'persisted@test.local');
    expect(second.restoring, false);
    secondApi.expired = true;
    await second.restore();
    expect(second.currentUser, isNull);
    expect(await store.read(), isNull);
    first.dispose();
    second.dispose();
  });

  test('failed session restoration retains token for a later retry', () async {
    final store = MemorySessionStore();
    await store.save('remembered');
    final api = FakeApi()..fail = true;
    final users = UserRepository(AuthService(api, sessionStore: store));
    await users.restore();
    expect(await store.read(), 'remembered');
    expect(users.restoreError, isNotNull);
    api.fail = false;
    await users.restore();
    expect(users.currentUser?.id, 'remembered');
    expect(users.restoreError, isNull);
    users.dispose();
  });

  test('moving a card updates both local decks only after the API succeeds',
      () async {
    final api = FakeApi();
    final repo = DeckRepository(api);
    final card = Flashcard(id: 'c', front: 'Q', back: 'A');
    repo.decks.addAll([
      Deck(id: 'source', name: 'Source', cards: [card]),
      Deck(id: 'target', name: 'Target')
    ]);
    api.fail = true;
    await expectLater(repo.updateCard('source', card, targetDeckId: 'target'),
        throwsException);
    expect(repo.findDeck('source')!.cards.length, 1);
    expect(repo.findDeck('target')!.cards, isEmpty);
    api.fail = false;
    await repo.updateCard('source', card, targetDeckId: 'target');
    expect(repo.findDeck('source')!.cards, isEmpty);
    expect(repo.findDeck('target')!.cards.single.id, 'c');
    repo.dispose();
  });

  testWidgets('a deck containing only new cards has an enabled study button',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = DeckRepository(FakeApi());
    repo.decks.add(Deck(
        id: 'deck-1',
        name: 'New',
        cards: [Flashcard(id: 'c', front: 'Q', back: 'A')]));
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: repo,
        child: MaterialApp(
            theme: buildLumeTheme(brightness: Brightness.light),
            home: const DeckDetailScreen(deckId: 'deck-1'))));
    await tester.pumpAndSettle();
    final button = tester.widget<LumeButton>(
        find.widgetWithText(LumeButton, 'Estudar 1 cartões'));
    expect(button.onPressed, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.dispose();
  });

  testWidgets(
      'switching four choices to two resets an out-of-range correct answer',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakeApi();
    final actualRepo = DeckRepository(api);
    actualRepo.decks.add(Deck(id: 'deck-1', name: 'Choices', cards: [
      Flashcard(
          id: 'c',
          front: 'Q',
          back: 'D',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 3)
    ]));
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: actualRepo,
        child: MaterialApp(
            theme: buildLumeTheme(brightness: Brightness.light),
            home:
                const CreateCardScreen(deckId: 'deck-1', editingCardId: 'c'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 opções'));
    await tester.pumpAndSettle();
    final save = find.byWidgetPredicate((widget) =>
        widget is LumeButton && widget.label.toLowerCase().contains('salvar'));
    expect(save, findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(api.lastPut?['options'], ['A', 'B']);
    expect(api.lastPut?['correctIndex'], 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    actualRepo.dispose();
  });

  testWidgets(
      'text-card self-assessment records a wrong answer instead of an automatic correct answer',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakeApi();
    final decks = DeckRepository(api);
    final progress = ProgressRepository(api),
        challenges = ChallengeRepository(api);
    final deck = Deck(
        id: 'deck-1',
        name: 'Study',
        cards: [Flashcard(id: 'card-1', front: 'Q', back: 'A')]);
    decks.decks.add(deck);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: decks),
          ChangeNotifierProvider.value(value: progress),
          ChangeNotifierProvider.value(value: challenges)
        ],
        child: MaterialApp(
            theme: buildLumeTheme(brightness: Brightness.light),
            home: StudyScreen(
                queue: StudyQueueItem.fromDeck(deck), sessionTitle: 'Study'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar resposta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Errei'));
    await tester.pumpAndSettle();
    expect(api.lastReview?['correct'], false);
    expect(api.lastReview?['durationSeconds'], isA<int>());
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    decks.dispose();
    progress.dispose();
    challenges.dispose();
  });
}
