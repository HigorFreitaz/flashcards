import 'package:flutter/foundation.dart';

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
  ) {
    _deckRepository.addListener(notifyListeners);
    _userRepository.addListener(notifyListeners);
    _notificationRepository.addListener(notifyListeners);
  }

  final DeckRepository _deckRepository;
  final UserRepository _userRepository;
  final NotificationRepository _notificationRepository;
  final ProgressRepository _progressRepository;

  List<Deck> get decks => _deckRepository.decks;
  int get dueToday => _deckRepository.dueToday;
  AppUser get currentUser => _userRepository.currentUser!;
  int get unreadNotificationCount => _notificationRepository.unreadCount;

  int get streakDays => _progressRepository.streakDays;
  int get level => _progressRepository.level;
  int get totalXp => _progressRepository.totalXp;
  int get xpToNextLevel => _progressRepository.xpToNextLevel;
  double get weeklyAccuracy => _progressRepository.weeklyAccuracy;
  int get minutesStudiedToday => _progressRepository.minutesStudiedToday;
  List<bool> get weekProgress => _progressRepository.weekProgress;

  @override
  void dispose() {
    _deckRepository.removeListener(notifyListeners);
    _userRepository.removeListener(notifyListeners);
    _notificationRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
