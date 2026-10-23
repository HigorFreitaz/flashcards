import 'flashcard.dart';

class Deck {
  Deck({
    required this.id,
    required this.name,
    this.description = '',
    this.dailyGoal = 20,
    this.remindersEnabled = true,
    List<String>? reminderTimes,
    List<Flashcard>? cards,
    DateTime? updatedAt,
  })  : reminderTimes = reminderTimes ?? ['20:00'],
        cards = cards ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dailyGoal: json['dailyGoal'] as int? ?? 20,
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      reminderTimes: (json['reminderTimes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      cards: (json['cards'] as List<dynamic>?)
          ?.map((c) => Flashcard.fromJson(c as Map<String, dynamic>))
          .toList(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dailyGoal': dailyGoal,
      'remindersEnabled': remindersEnabled,
      'reminderTimes': reminderTimes,
      'cards': cards.map((c) => c.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  final String id;
  String name;
  String description;
  int dailyGoal;
  bool remindersEnabled;
  List<String> reminderTimes;
  final List<Flashcard> cards;
  DateTime updatedAt;

  int get totalCount => cards.length;

  int get dueCount => cards
      .where((c) => !c.suspended && c.status == CardStatus.aRevisar)
      .length;

  int get newCount =>
      cards.where((c) => !c.suspended && c.status == CardStatus.novo).length;

  int get masteredCount =>
      cards.where((c) => c.status == CardStatus.dominado).length;

  double get masteryPercent => cards.isEmpty ? 0 : masteredCount / cards.length;

  bool get aiAssisted => cards.any((c) => c.aiGenerated);

  /// Fila de estudo: cartões a revisar entram primeiro, depois os novos.
  List<Flashcard> get studyQueue => [
        ...cards.where((c) => !c.suspended && c.status == CardStatus.aRevisar),
        ...cards.where((c) => !c.suspended && c.status == CardStatus.novo),
      ];

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '??';
    return trimmed.length >= 2
        ? trimmed.substring(0, 2).toUpperCase()
        : trimmed.toUpperCase();
  }

  String get shortName => name.split(' — ').first;
}
