import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../state/app_state.dart';
import '../../theme/lume_colors.dart';
import '../../theme/lume_metrics.dart';
import '../../theme/lume_motion.dart';
import '../../widgets/buttons/lume_button.dart';

/// Um cartão amarrado ao baralho de origem — para que a resposta seja
/// registrada no lugar certo mesmo numa sessão que mistura vários baralhos.
class StudyQueueItem {
  const StudyQueueItem({required this.deckId, required this.deckName, required this.card});

  final String deckId;
  final String deckName;
  final Flashcard card;

  static List<StudyQueueItem> fromDecks(Iterable<Deck> decks) {
    return decks
        .expand((deck) => deck.studyQueue.map((card) => StudyQueueItem(deckId: deck.id, deckName: deck.name, card: card)))
        .toList();
  }

  static List<StudyQueueItem> fromDeck(Deck deck) {
    return deck.studyQueue.map((card) => StudyQueueItem(deckId: deck.id, deckName: deck.name, card: card)).toList();
  }
}

const _wave = <double>[
  10, 18, 26, 14, 30, 22, 12, 26, 34, 20, 14, 24, 30, 16, 10, 22, 28, 18, 12, 26, 20, 14,
];

class StudyScreen extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.queue,
    required this.sessionTitle,
    this.isChallenge = false,
  });

  final List<StudyQueueItem> queue;
  final String sessionTitle;
  final bool isChallenge;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  int _index = 0;
  bool _flipped = false;
  int? _chosen;
  bool _playing = false;
  double _elapsedSeconds = 0;
  Timer? _audioTimer;

  bool get _done => _index >= widget.queue.length;

  StudyQueueItem get _current => widget.queue[math.min(_index, widget.queue.length - 1)];

  @override
  void dispose() {
    _audioTimer?.cancel();
    super.dispose();
  }

  void _toggleAudio() {
    final seconds = _current.card.audioSeconds;
    if (_playing) {
      _audioTimer?.cancel();
      setState(() => _playing = false);
      return;
    }
    setState(() {
      _playing = true;
      if (_elapsedSeconds >= seconds) _elapsedSeconds = 0;
    });
    _audioTimer?.cancel();
    _audioTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() => _elapsedSeconds += 0.1);
      if (_elapsedSeconds >= seconds) {
        timer.cancel();
        setState(() {
          _elapsedSeconds = seconds.toDouble();
          _playing = false;
        });
      }
    });
  }

  void _flip() {
    if (_current.card.hasOptions) return;
    setState(() => _flipped = !_flipped);
  }

  void _pickChoice(int i) {
    if (_chosen != null) return;
    setState(() => _chosen = i);
    final card = _current.card;
    final correct = i == card.correctIndex;
    context.read<AppState>().markCardReviewed(_current.deckId, card.id, correct: correct);
  }

  void _next() {
    _audioTimer?.cancel();
    final card = _current.card;
    if (!card.hasOptions) {
      context.read<AppState>().markCardReviewed(_current.deckId, card.id);
    }
    setState(() {
      _index += 1;
      _flipped = false;
      _chosen = null;
      _playing = false;
      _elapsedSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final total = widget.queue.length;
    final progress = total == 0 ? 1.0 : math.min(_index, total) / total;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  LumeIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                    semanticLabel: 'Fechar sessão',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: LumeMotion.enter,
                        curve: LumeMotion.curve,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: context.lume.surface,
                          color: context.lume.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${math.min(_index + 1, total)}/$total',
                    style: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: context.lume.inkMuted),
                  ),
                ],
              ),
              Expanded(
                child: _done
                    ? _CompletionView(sessionTitle: widget.sessionTitle, isChallenge: widget.isChallenge, total: total)
                    : _ActiveCard(
                        card: _current.card,
                        fontFamily: fontFamily,
                        flipped: _flipped,
                        onFlip: _flip,
                        elapsedSeconds: _elapsedSeconds,
                        playing: _playing,
                        onToggleAudio: _toggleAudio,
                        chosen: _chosen,
                        onChoicePicked: _pickChoice,
                        nextLabel: _nextLabel,
                        onNext: _next,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _nextLabel => _index + 1 >= widget.queue.length ? 'Ver resultado' : 'Próximo cartão';
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    required this.card,
    required this.fontFamily,
    required this.flipped,
    required this.onFlip,
    required this.elapsedSeconds,
    required this.playing,
    required this.onToggleAudio,
    required this.chosen,
    required this.onChoicePicked,
    required this.nextLabel,
    required this.onNext,
  });

  final Flashcard card;
  final String? fontFamily;
  final bool flipped;
  final VoidCallback onFlip;
  final double elapsedSeconds;
  final bool playing;
  final VoidCallback onToggleAudio;
  final int? chosen;
  final ValueChanged<int> onChoicePicked;
  final String nextLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: onFlip,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: flipped ? 1 : 0),
                duration: LumeMotion.flip,
                curve: LumeMotion.curve,
                builder: (context, value, _) {
                  final angle = value * math.pi;
                  final showFront = angle <= math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: showFront
                        ? _CardFace(card: card, fontFamily: fontFamily, elapsed: elapsedSeconds, playing: playing, onPlay: onToggleAudio)
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _CardBack(card: card, fontFamily: fontFamily),
                          ),
                  );
                },
              ),
            ),
          ),
        ),
        _ActionArea(
          card: card,
          fontFamily: fontFamily,
          chosen: chosen,
          onChoicePicked: onChoicePicked,
          flipped: flipped,
          onFlip: onFlip,
          nextLabel: nextLabel,
          onNext: onNext,
        ),
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.fontFamily,
    required this.elapsed,
    required this.playing,
    required this.onPlay,
  });

  final Flashcard card;
  final String? fontFamily;
  final double elapsed;
  final bool playing;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: context.lume.background,
        border: Border.all(color: context.lume.outline),
        borderRadius: BorderRadius.circular(LumeRadii.card),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(card.kindLabel,
                  style: TextStyle(fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: context.lume.inkMuted)),
              if (card.aiGenerated) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(5)),
                  child: Text('IA', style: TextStyle(fontFamily: fontFamily, fontSize: 9, fontWeight: FontWeight.w700, color: context.lume.primary)),
                ),
              ],
            ],
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.front,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: fontFamily, fontSize: 20, height: 1.3, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: context.lume.ink),
                  ),
                  if (card.type == CardType.audio) ...[
                    const SizedBox(height: 14),
                    _AudioPlayer(card: card, elapsed: elapsed, playing: playing, onPlay: onPlay, fontFamily: fontFamily),
                  ],
                  if (card.type == CardType.image) ...[
                    const SizedBox(height: 14),
                    _ImagePlaceholder(caption: card.mediaCaption, fontFamily: fontFamily),
                  ],
                ],
              ),
            ),
          ),
          Text(
            card.type == CardType.audio
                ? 'Ouça quantas vezes quiser'
                : (card.hasOptions ? 'Escolha a alternativa correta' : 'Toque no cartão para revelar'),
            style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: context.lume.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.card, required this.fontFamily});

  final Flashcard card;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: context.lume.primary, borderRadius: BorderRadius.circular(LumeRadii.card)),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('RESPOSTA', style: TextStyle(fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: context.lume.background.withValues(alpha: 0.75))),
          const SizedBox(height: 14),
          Text(card.back,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: fontFamily, fontSize: 20, height: 1.35, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: context.lume.background)),
          if (card.hint != null) ...[
            const SizedBox(height: 16),
            Text(card.hint!, style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: context.lume.background.withValues(alpha: 0.75))),
          ],
        ],
      ),
    );
  }
}

class _AudioPlayer extends StatelessWidget {
  const _AudioPlayer({required this.card, required this.elapsed, required this.playing, required this.onPlay, required this.fontFamily});

  final Flashcard card;
  final double elapsed;
  final bool playing;
  final VoidCallback onPlay;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final seconds = card.audioSeconds;
    final progress = (elapsed / seconds).clamp(0.0, 1.0).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: context.lume.primary, shape: BoxShape.circle),
              child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20, color: context.lume.background),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 26,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_wave.length, (i) {
                      final played = (i + 1) / _wave.length <= progress;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: math.max(5, _wave[i] * 0.78),
                          decoration: BoxDecoration(
                            color: played ? context.lume.primary : context.lume.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: context.lume.outline, color: context.lume.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '0:${elapsed.floor().toString().padLeft(2, '0')} / 0:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w600, color: context.lume.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.caption, required this.fontFamily});

  final String? caption;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(Icons.image_outlined, size: 26, color: context.lume.inkMuted),
          const SizedBox(height: 8),
          Text('Figura do material anexado', style: TextStyle(fontFamily: fontFamily, fontSize: 11, color: context.lume.inkMuted)),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, style: TextStyle(fontFamily: fontFamily, fontSize: 11, color: context.lume.inkMuted)),
          ],
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.keyLabel, required this.onTap, required this.fontFamily});

  final String label;
  final String keyLabel;
  final VoidCallback onTap;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.lume.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: context.lume.outline), borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text(keyLabel, style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w700, color: context.lume.inkMuted)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: context.lume.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionArea extends StatelessWidget {
  const _ActionArea({
    required this.card,
    required this.fontFamily,
    required this.chosen,
    required this.onChoicePicked,
    required this.flipped,
    required this.onFlip,
    required this.nextLabel,
    required this.onNext,
  });

  final Flashcard card;
  final String? fontFamily;
  final int? chosen;
  final ValueChanged<int> onChoicePicked;
  final bool flipped;
  final VoidCallback onFlip;
  final String nextLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (card.hasOptions) {
      if (chosen == null) {
        final options = card.options!;
        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: options.length > 2 ? 2.6 : 3.6,
          children: List.generate(options.length, (i) {
            return _ChoiceButton(
              label: options[i],
              keyLabel: String.fromCharCode(65 + i),
              onTap: () => onChoicePicked(i),
              fontFamily: fontFamily,
            );
          }),
        );
      }
      final correctIndex = card.correctIndex ?? 0;
      final wasCorrect = chosen == correctIndex;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: context.lume.surface, borderRadius: BorderRadius.circular(14)),
            child: Text(
              wasCorrect ? '✓ Correto — ${card.back}' : '✕ Resposta certa: ${card.options![correctIndex]}',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: wasCorrect ? context.lume.primary : context.lume.ink,
              ),
            ),
          ),
          LumeButton(label: nextLabel, onPressed: onNext),
        ],
      );
    }

    if (!flipped) {
      return LumeButton(label: 'Mostrar resposta', onPressed: onFlip);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'O Lume reagenda pelo seu tempo de resposta — sem nota manual.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: context.lume.inkMuted),
        ),
        const SizedBox(height: 10),
        LumeButton(label: nextLabel, onPressed: onNext),
      ],
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.sessionTitle, required this.isChallenge, required this.total});

  final String sessionTitle;
  final bool isChallenge;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final minutes = math.max(1, (total * 0.4).round());
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: context.lume.primary, borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.check_rounded, size: 30, color: context.lume.background),
          ),
          Text(
            isChallenge ? 'Desafio concluído' : 'Sessão concluída',
            style: TextStyle(fontFamily: fontFamily, fontSize: 23, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: context.lume.ink),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              '$total cartões revisados em $minutes min. Próxima leva às 20:00.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: fontFamily, fontSize: 15, height: 1.5, color: context.lume.inkMuted),
            ),
          ),
          const SizedBox(height: 26),
          LumeButton(
            label: 'Voltar ao início',
            expand: false,
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
