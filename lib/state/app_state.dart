import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/challenge_history_entry.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../utils/database_helper.dart';

/// Estado compartilhado do app: os baralhos e cartões do usuário, sua
/// sequência de estudo e as notificações. Tudo vive em memória — não há
/// backend nem persistência entre sessões, só o que basta para a interface
/// reagir e parecer viva.
class AppState extends ChangeNotifier {
  AppState() {
    // decks.addAll(_seedDecks());
    // notifications.addAll(_seedNotifications());
    // challengeHistory.addAll(_seedChallengeHistory());
  }

  final List<Deck> decks = [];
  final List<AppNotification> notifications = [];
  final List<ChallengeHistoryEntry> challengeHistory = [];

  final db = DatabaseHelper();
  AppUser? currentUser;


  ThemeMode themeMode = ThemeMode.light;
  bool get isDarkMode => themeMode == ThemeMode.dark;

  bool biometricLockEnabled = false;

  final int streakDays = 12;
  final int level = 7;
  final int totalXp = 1240;
  final int xpToNextLevel = 360;
  final double weeklyAccuracy = 0.94;
  final int minutesStudiedToday = 18;

  /// Um marcador por dia da semana (seg. a dom.), true onde já houve estudo.
  final List<bool> weekProgress = [true, true, false, false, false, false, false];

  bool challengeJoined = false;

  String? _toastMessage;
  Timer? _toastTimer;
  String? get toastMessage => _toastMessage;

  int get dueToday => decks.fold(0, (sum, d) => sum + d.dueCount);

  int get unreadNotificationCount => notifications.where((n) => n.unread).length;

  Deck? findDeck(String id) {
    for (final deck in decks) {
      if (deck.id == id) return deck;
    }
    return null;
  }

  bool login(String email, String password){
    final user = db.login(AppUser.login(email: email, password: password));
    if (user != null){
      currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool signup(String name,String email, String password){
    final user = db.signup(AppUser(name: name, email: email, password: password));
    if (user != null){
      currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void showToast(String message) {
    _toastMessage = message;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2800), () {
      _toastMessage = null;
      notifyListeners();
    });
  }

  void setDarkModeEnabled(bool enabled) {
    themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setBiometricLockEnabled(bool enabled) {
    biometricLockEnabled = enabled;
    notifyListeners();
  }

  void updateProfile({String? name, String? email}) {
    if (name != null && name.trim().isNotEmpty) currentUser?.name = name.trim();
    if (email != null && email.trim().isNotEmpty) currentUser?.email = email.trim();
    notifyListeners();
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

  /// Avança o estágio de memorização de um cartão depois de revisado.
  /// Sem nota manual: cartões novos passam a "a revisar"; cartões "a
  /// revisar" respondidos certo tornam-se "dominados". Uma resposta errada
  /// mantém o cartão na fila de revisão.
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

  void markAllNotificationsRead() {
    for (final n in notifications) {
      n.unread = false;
    }
    notifyListeners();
  }

  void joinChallenge() {
    challengeJoined = true;
    notifyListeners();
  }

  /// Apaga a conta: some com os baralhos, cartões e progresso, e devolve o
  /// app ao estado de uma instalação nova.
  void deleteAccount() {
    // decks
    //   ..clear()
    //   ..addAll(_seedDecks());
    // notifications
    //   ..clear()
    //   ..addAll(_seedNotifications());
    // challengeHistory
    //   ..clear()
    //   ..addAll(_seedChallengeHistory());
    // currentUser = AppUser(name: 'Ana Ribeiro', email: 'ana.ribeiro@exemplo.com');
    // themeMode = ThemeMode.light;
    // biometricLockEnabled = false;
    // challengeJoined = false;
    showToast('Conta Deletada');
    // notifyListeners();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  // static List<Deck> _seedDecks() {
  //   return [
  //     Deck(
  //       id: 'ana',
  //       name: 'Anatomia — Sistema Nervoso',
  //       description: 'Estruturas, nervos cranianos e vias de condução.',
  //       dailyGoal: 20,
  //       updatedAt: DateTime.now().subtract(const Duration(days: 2)),
  //       cards: [
  //         Flashcard(
  //           id: 'ana-1',
  //           front: 'Qual neurotransmissor atua na junção neuromuscular?',
  //           back: 'Acetilcolina, liberada nas vesículas pré-sinápticas.',
  //           hint: 'Visto 4 vezes · acerto 75%',
  //           status: CardStatus.aRevisar,
  //         ),
  //         Flashcard(
  //           id: 'ana-2',
  //           front: 'Quantos pares de nervos cranianos existem?',
  //           back: 'Doze pares, de I a XII.',
  //           status: CardStatus.aRevisar,
  //         ),
  //         Flashcard(
  //           id: 'ana-3',
  //           front: 'Que estrutura está destacada na figura?',
  //           back: 'O corpo caloso, formado por fibras comissurais.',
  //           type: CardType.image,
  //           mediaCaption: 'Gerado da apostila · cap. 3, pág. 12',
  //           options: const ['Corpo caloso', 'Tálamo', 'Ponte', 'Hipocampo'],
  //           correctIndex: 0,
  //           aiGenerated: true,
  //           status: CardStatus.novo,
  //         ),
  //         Flashcard(
  //           id: 'ana-4',
  //           front: 'O que é a bainha de mielina?',
  //           back: 'Camada lipídica que acelera a condução do impulso.',
  //           status: CardStatus.dominado,
  //         ),
  //         Flashcard(
  //           id: 'ana-5',
  //           front: 'Qual estrutura conecta os hemisférios cerebrais?',
  //           back: 'O corpo caloso.',
  //           status: CardStatus.novo,
  //         ),
  //         Flashcard(
  //           id: 'ana-6',
  //           front: 'O que é a barreira hematoencefálica?',
  //           back: 'Filtro seletivo entre sangue e tecido nervoso.',
  //           status: CardStatus.novo,
  //         ),
  //         Flashcard(
  //           id: 'ana-7',
  //           front: 'Qual a função do cerebelo?',
  //           back: 'Coordenação motora fina, postura e equilíbrio.',
  //           status: CardStatus.dominado,
  //         ),
  //         Flashcard(
  //           id: 'ana-8',
  //           front: 'Onde ficam os corpos dos neurônios sensitivos?',
  //           back: 'No gânglio da raiz dorsal.',
  //           status: CardStatus.novo,
  //         ),
  //       ],
  //     ),
  //     Deck(
  //       id: 'far',
  //       name: 'Farmacologia Básica',
  //       description: 'Farmacocinética e farmacodinâmica essenciais.',
  //       dailyGoal: 15,
  //       updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  //       cards: [
  //         Flashcard(
  //           id: 'far-1',
  //           front: 'O que é biodisponibilidade de um fármaco?',
  //           back: 'A fração da dose que atinge a circulação sistêmica inalterada.',
  //           status: CardStatus.aRevisar,
  //         ),
  //         Flashcard(
  //           id: 'far-2',
  //           front: 'Qual a diferença entre agonista e antagonista?',
  //           back: 'O agonista ativa o receptor; o antagonista bloqueia sua ativação.',
  //           status: CardStatus.aRevisar,
  //         ),
  //         Flashcard(
  //           id: 'far-3',
  //           front: 'O que é meia-vida plasmática?',
  //           back: 'Tempo para a concentração do fármaco no plasma cair à metade.',
  //           status: CardStatus.novo,
  //         ),
  //         Flashcard(
  //           id: 'far-4',
  //           front: 'O que é efeito de primeira passagem?',
  //           back: 'Metabolização do fármaco no fígado antes de chegar à circulação.',
  //           status: CardStatus.dominado,
  //         ),
  //         Flashcard(
  //           id: 'far-5',
  //           front: 'Qual a via de administração mais rápida?',
  //           back: 'Intravenosa.',
  //           status: CardStatus.novo,
  //         ),
  //       ],
  //     ),
  //     Deck(
  //       id: 'ing',
  //       name: 'Inglês — Phrasal Verbs',
  //       description: 'Expressões comuns em conversação e listening.',
  //       dailyGoal: 10,
  //       remindersEnabled: false,
  //       updatedAt: DateTime.now().subtract(const Duration(days: 5)),
  //       cards: [
  //         Flashcard(
  //           id: 'ing-1',
  //           front: 'Qual expressão você ouviu?',
  //           back: '"She takes after her mother." — Ela puxou à mãe.',
  //           hint: 'Gerado do áudio da aula de inglês',
  //           type: CardType.audio,
  //           options: const ['takes after', 'looks after', 'takes over', 'talks about'],
  //           correctIndex: 0,
  //           audioSeconds: 8,
  //           aiGenerated: true,
  //           status: CardStatus.dominado,
  //         ),
  //         Flashcard(
  //           id: 'ing-2',
  //           front: 'O que significa "give up"?',
  //           back: 'Desistir de algo.',
  //           status: CardStatus.dominado,
  //         ),
  //         Flashcard(
  //           id: 'ing-3',
  //           front: 'O que significa "look forward to"?',
  //           back: 'Estar animado, ansioso por algo.',
  //           status: CardStatus.dominado,
  //         ),
  //         Flashcard(
  //           id: 'ing-4',
  //           front: 'O que significa "run into"?',
  //           back: 'Encontrar alguém por acaso.',
  //           status: CardStatus.aRevisar,
  //         ),
  //         Flashcard(
  //           id: 'ing-5',
  //           front: 'O que significa "come across"?',
  //           back: 'Encontrar ou se deparar com algo por acaso.',
  //           status: CardStatus.novo,
  //         ),
  //       ],
  //     ),
  //     Deck(
  //       id: 'dir',
  //       name: 'Direito Constitucional',
  //       description: 'Princípios e organização dos poderes.',
  //       dailyGoal: 20,
  //       updatedAt: DateTime.now(),
  //       cards: [
  //         Flashcard(
  //           id: 'dir-1',
  //           front: 'Quantos artigos tem a parte permanente da Constituição de 1988?',
  //           back: '250 artigos.',
  //           status: CardStatus.aRevisar,
  //         ),
  //         Flashcard(
  //           id: 'dir-2',
  //           front: 'O que são cláusulas pétreas?',
  //           back: 'Dispositivos que não podem ser abolidos por emenda constitucional.',
  //           status: CardStatus.aRevisar,
  //         ),
  //         Flashcard(
  //           id: 'dir-3',
  //           front: 'Quais os três Poderes da República?',
  //           back: 'Executivo, Legislativo e Judiciário.',
  //           status: CardStatus.novo,
  //         ),
  //         Flashcard(
  //           id: 'dir-4',
  //           front: 'O que é o princípio da legalidade?',
  //           back: 'Ninguém é obrigado a fazer ou deixar de fazer algo senão em virtude de lei.',
  //           status: CardStatus.novo,
  //         ),
  //       ],
  //     ),
  //     Deck(
  //       id: 'qui',
  //       name: 'Química Orgânica',
  //       description: 'Estrutura, isomeria e grupos funcionais.',
  //       dailyGoal: 15,
  //       updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
  //       cards: [
  //         Flashcard(
  //           id: 'qui-1',
  //           front: 'O que caracteriza um carbono quiral?',
  //           back: 'Um carbono ligado a quatro substituintes diferentes.',
  //           aiGenerated: true,
  //           status: CardStatus.novo,
  //         ),
  //         Flashcard(
  //           id: 'qui-2',
  //           front: 'Qual a diferença entre alcano e alceno?',
  //           back: 'O alceno tem ao menos uma ligação dupla entre carbonos.',
  //           status: CardStatus.aRevisar,
  //         ),
  //         Flashcard(
  //           id: 'qui-3',
  //           front: 'O que é isomeria?',
  //           back: 'Compostos com a mesma fórmula molecular e estruturas diferentes.',
  //           status: CardStatus.novo,
  //         ),
  //         Flashcard(
  //           id: 'qui-4',
  //           front: 'O que é um grupo funcional?',
  //           back: 'Um arranjo de átomos responsável pelas propriedades características da molécula.',
  //           status: CardStatus.dominado,
  //         ),
  //       ],
  //     ),
  //   ];
  // }
  //
  // static List<AppNotification> _seedNotifications() {
  //   return [
  //     AppNotification(
  //       id: 'n1',
  //       icon: Icons.donut_large_rounded,
  //       title: '24 cartões esperando por você',
  //       body: 'Anatomia — 8 minutos e a meta de hoje fecha',
  //       when: 'agora',
  //       unread: true,
  //     ),
  //     AppNotification(
  //       id: 'n2',
  //       icon: Icons.diamond_outlined,
  //       title: 'Faltam 4 perguntas no desafio',
  //       body: 'Termina em 2 dias · +250 XP',
  //       when: '2 h',
  //       unread: true,
  //     ),
  //     AppNotification(
  //       id: 'n3',
  //       icon: Icons.trending_up_rounded,
  //       title: 'Sequência de 12 dias mantida',
  //       body: 'Seu melhor mês até agora',
  //       when: 'ontem',
  //       unread: false,
  //     ),
  //     AppNotification(
  //       id: 'n4',
  //       icon: Icons.graphic_eq_rounded,
  //       title: 'Seus áudios viraram 8 cartões',
  //       body: 'Aula de inglês · prontos para revisar',
  //       when: 'seg',
  //       unread: false,
  //     ),
  //   ];
  // }
  //
  // static List<ChallengeHistoryEntry> _seedChallengeHistory() {
  //   return const [
  //     ChallengeHistoryEntry(
  //       week: 'S33',
  //       title: 'Mistura geral · 15 perguntas',
  //       detail: '13 acertos · +230 XP',
  //       scorePercent: 87,
  //       success: true,
  //     ),
  //     ChallengeHistoryEntry(
  //       week: 'S32',
  //       title: 'Só Farmacologia · 10 perguntas',
  //       detail: '6 acertos · +90 XP',
  //       scorePercent: 60,
  //       success: false,
  //     ),
  //     ChallengeHistoryEntry(
  //       week: 'S31',
  //       title: 'Mistura geral · 12 perguntas',
  //       detail: '11 acertos · +210 XP',
  //       scorePercent: 92,
  //       success: true,
  //     ),
  //     ChallengeHistoryEntry(
  //       week: 'S30',
  //       title: 'Sprint de véspera · 20 perguntas',
  //       detail: '17 acertos · +300 XP',
  //       scorePercent: 85,
  //       success: true,
  //     ),
  //   ];
  // }
}
