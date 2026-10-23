class StudyHistoryEntry {
  StudyHistoryEntry.fromJson(Map<String, dynamic> json)
      : deckName = json['deckName'] as String? ?? 'Baralho excluído',
        cardFront = json['cardFront'] as String? ?? 'Cartão excluído',
        correct = json['correct'] as bool?,
        durationSeconds = json['durationSeconds'] as int? ?? 0,
        createdAt = DateTime.parse(json['createdAt'].toString());
  final String deckName, cardFront;
  final bool? correct;
  final int durationSeconds;
  final DateTime createdAt;
}
