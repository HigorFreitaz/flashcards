import 'package:flutter/foundation.dart';

import '../data/repositories/challenge_repository.dart';
import '../data/repositories/deck_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/user_repository.dart';
import '../models/app_user.dart';
import '../models/deck.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(
    this._deckRepository,
    this._userRepository,
    this._notificationRepository,
    this._progressRepository,
    this._challengeRepository,
  ) {
    _deckRepository.addListener(notifyListeners);
    _userRepository.addListener(notifyListeners);
    _notificationRepository.addListener(notifyListeners);
    _progressRepository.addListener(notifyListeners);
    _challengeRepository.addListener(notifyListeners);
  }

  final DeckRepository _deckRepository;
  final UserRepository _userRepository;
  final NotificationRepository _notificationRepository;
  final ProgressRepository _progressRepository;
  final ChallengeRepository _challengeRepository;

  List<Deck> get decks => _deckRepository.decks;
  int get dueToday => _deckRepository.dueToday;
  AppUser get currentUser =>
      _userRepository.currentUser ??
      AppUser(name: 'Usuário', email: '', password: '');
  int get unreadNotificationCount => _notificationRepository.unreadCount;

  int get streakDays => _progressRepository.streakDays;
  int get level => _progressRepository.level;
  int get totalXp => _progressRepository.totalXp;
  int get xpToNextLevel => _progressRepository.xpToNextLevel;
  double get weeklyAccuracy => _progressRepository.weeklyAccuracy;
  double get dailyPercent {
    final goal = decks.fold<int>(0, (sum, deck) => sum + deck.dailyGoal);
    return goal == 0
        ? 0
        : (_progressRepository.reviewedToday / goal).clamp(0.0, 1.0);
  }

  int get minutesStudiedToday => _progressRepository.minutesStudiedToday;
  List<bool> get weekProgress => _progressRepository.weekProgress;
  int get weeklyAnswered => _challengeRepository.weeklyAnswered;

  @override
  void dispose() {
    _deckRepository.removeListener(notifyListeners);
    _userRepository.removeListener(notifyListeners);
    _notificationRepository.removeListener(notifyListeners);
    _progressRepository.removeListener(notifyListeners);
    _challengeRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
