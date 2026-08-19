class ChallengeHistoryEntry {
  const ChallengeHistoryEntry({
    required this.week,
    required this.title,
    required this.detail,
    required this.scorePercent,
    required this.success,
  });

  final String week;
  final String title;
  final String detail;
  final int scorePercent;
  final bool success;
}
