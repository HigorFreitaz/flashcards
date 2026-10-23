class ChallengeHistoryEntry {
  const ChallengeHistoryEntry({
    required this.week,
    required this.title,
    required this.detail,
    required this.scorePercent,
    required this.success,
    this.id = '',
    this.kind = 'weekly',
    this.status = 'active',
    this.targetCount = 15,
    this.answered = 0,
    this.deckIds = const [],
    this.weakOnly = false,
    this.endsAt,
  });

  factory ChallengeHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ChallengeHistoryEntry(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'weekly',
      status: json['status'] as String? ?? 'active',
      targetCount: json['targetCount'] as int? ?? 15,
      answered: json['answered'] as int? ?? 0,
      deckIds: (json['deckIds'] as List? ?? []).cast<String>(),
      weakOnly: json['weakOnly'] == true,
      endsAt: DateTime.tryParse(json['endsAt']?.toString() ?? ''),
      week: json['week'] as String? ?? '',
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      scorePercent: json['scorePercent'] as int? ?? 0,
      success: json['success'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week': week,
      'title': title,
      'detail': detail,
      'scorePercent': scorePercent,
      'success': success,
    };
  }

  final String id, kind, status;
  final int targetCount, answered;
  final List<String> deckIds;
  final bool weakOnly;
  final DateTime? endsAt;
  bool get active => status == 'active';
  final String week;
  final String title;
  final String detail;
  final int scorePercent;
  final bool success;
}
