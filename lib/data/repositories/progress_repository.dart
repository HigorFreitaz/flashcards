/// Estatísticas de progresso e gamificação do usuário. Hoje são valores
/// fixos (não há telemetria real de estudo); por isso é uma classe simples,
/// sem [ChangeNotifier] — não existe mutação para propagar.
class ProgressRepository {
  final int streakDays = 12;
  final int level = 7;
  final int totalXp = 1240;
  final int xpToNextLevel = 360;
  final double weeklyAccuracy = 0.94;
  final int minutesStudiedToday = 18;

  /// Um marcador por dia da semana (seg. a dom.), true onde já houve estudo.
  final List<bool> weekProgress = [true, true, false, false, false, false, false];
}
