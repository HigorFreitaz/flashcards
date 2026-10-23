enum CardType { text, audio, image }

enum CardStatus { novo, aRevisar, dominado }

class Flashcard {
  Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.type = CardType.text,
    this.status = CardStatus.novo,
    this.hint,
    this.options,
    this.correctIndex,
    this.audioSeconds = 8,
    this.aiGenerated = false,
    this.mediaCaption,
    this.suspended = false,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    CardType parseType(String? val) {
      switch (val) {
        case 'audio':
          return CardType.audio;
        case 'image':
          return CardType.image;
        default:
          return CardType.text;
      }
    }

    CardStatus parseStatus(String? val) {
      switch (val) {
        case 'aRevisar':
          return CardStatus.aRevisar;
        case 'dominado':
          return CardStatus.dominado;
        default:
          return CardStatus.novo;
      }
    }

    return Flashcard(
      suspended: json['suspended'] as bool? ?? false,
      id: json['id'] as String? ?? '',
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      type: parseType(json['type'] as String?),
      status: parseStatus(json['status'] as String?),
      hint: json['hint'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      correctIndex: json['correctIndex'] as int?,
      audioSeconds: json['audioSeconds'] as int? ?? 8,
      aiGenerated: json['aiGenerated'] as bool? ?? false,
      mediaCaption: json['mediaCaption'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suspended': suspended,
      'id': id,
      'front': front,
      'back': back,
      'type': type.name,
      'status': status.name,
      'hint': hint,
      'options': options,
      'correctIndex': correctIndex,
      'audioSeconds': audioSeconds,
      'aiGenerated': aiGenerated,
      'mediaCaption': mediaCaption,
    };
  }

  bool suspended;
  final String id;
  String front;
  String back;
  CardType type;
  CardStatus status;
  String? hint;
  List<String>? options;
  int? correctIndex;
  int audioSeconds;
  bool aiGenerated;

  /// Legenda da mídia anexada (ex.: "apostila-cap3.pdf · pág. 12").
  String? mediaCaption;

  bool get hasOptions => options != null && options!.isNotEmpty;

  String get kindLabel {
    switch (type) {
      case CardType.audio:
        return 'OUÇA E RESPONDA';
      case CardType.image:
        return 'OBSERVE A FIGURA';
      case CardType.text:
        return hasOptions ? 'ESCOLHA A ALTERNATIVA' : 'PERGUNTA';
    }
  }
}
