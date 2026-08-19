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
  });

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
