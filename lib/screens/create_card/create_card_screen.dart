import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../state/app_state.dart';
import '../../theme/lume_colors.dart';
import '../../theme/lume_metrics.dart';
import '../../widgets/feedback/lume_bottom_sheet.dart';
import '../../widgets/buttons/lume_button.dart';
import '../../widgets/navigation/lume_segmented_tabs.dart';
import '../../widgets/inputs/lume_text_field.dart';
import '../../widgets/feedback/lume_toast.dart';
import '../deck/deck_form_screen.dart';

enum _EntryMode { type, ai }

enum _ResponseType { texto, duasOpcoes, quatroOpcoes }

enum _AiState { idle, loading, done }

class _AttachSource {
  const _AttachSource(
      {required this.id,
      required this.icon,
      required this.label,
      required this.file,
      required this.size});

  final String id;
  final IconData icon;
  final String label;
  final String file;
  final String size;
}

const _sources = [
  _AttachSource(
      id: 'foto',
      icon: Icons.photo_camera_outlined,
      label: 'Foto',
      file: 'caderno-aula-12.heic',
      size: 'Imagem · 2,4 MB'),
  _AttachSource(
      id: 'audio',
      icon: Icons.mic_none_rounded,
      label: 'Áudio',
      file: 'aula-neuro.m4a',
      size: 'Áudio · 42 min'),
  _AttachSource(
      id: 'video',
      icon: Icons.videocam_outlined,
      label: 'Vídeo',
      file: 'revisao.mp4',
      size: 'Vídeo · 8 min'),
  _AttachSource(
      id: 'pdf',
      icon: Icons.picture_as_pdf_outlined,
      label: 'PDF',
      file: 'apostila-cap3.pdf',
      size: 'PDF · 18 páginas'),
];

class _GeneratedCard {
  _GeneratedCard(
      {required this.tag,
      required this.front,
      required this.back,
      this.type = CardType.text,
      this.audioSeconds = 8,
      this.mediaCaption});

  final String tag;
  final String front;
  final String back;
  final CardType type;
  final int audioSeconds;
  final String? mediaCaption;
}

final _fixedGenerated = [
  _GeneratedCard(
      tag: 'TEXTO',
      front: 'O que é a barreira hematoencefálica?',
      back: 'Filtro seletivo entre sangue e tecido nervoso.'),
  _GeneratedCard(
      tag: 'TEXTO',
      front: 'Qual a função do cerebelo?',
      back: 'Coordenação motora fina e equilíbrio.'),
];

final _sourceGenerated = {
  'audio': _GeneratedCard(
      tag: 'ÁUDIO',
      front: 'Ouça e diga o que foi falado',
      back: '"She takes after her mother."',
      type: CardType.audio,
      audioSeconds: 8),
  'video': _GeneratedCard(
      tag: 'TRECHO DE VÍDEO',
      front: 'Complete a frase do trecho',
      back: '"...o potencial de ação se propaga."',
      type: CardType.audio,
      audioSeconds: 14),
  'pdf': _GeneratedCard(
      tag: 'FIGURA DO PDF',
      front: 'Nomeie a estrutura destacada na figura',
      back: 'Corpo caloso',
      type: CardType.image,
      mediaCaption: 'apostila-cap3.pdf · pág. 12'),
  'foto': _GeneratedCard(
      tag: 'FOTO DO CADERNO',
      front: 'Qual etapa está circulada no esquema?',
      back: 'Recaptação da acetilcolina',
      type: CardType.image,
      mediaCaption: 'caderno-aula-12.heic · trecho 2'),
};

/// Cria um cartão novo (digitado ou gerado por IA), ou edita um existente
/// quando [editingCardId] é informado.
class CreateCardScreen extends StatefulWidget {
  const CreateCardScreen({super.key, required this.deckId, this.editingCardId});

  final String deckId;
  final String? editingCardId;

  @override
  State<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends State<CreateCardScreen> {
  late String _targetDeckId = widget.deckId;
  late _EntryMode _mode =
      widget.editingCardId != null ? _EntryMode.type : _EntryMode.ai;

  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  _ResponseType _responseType = _ResponseType.texto;
  final List<TextEditingController> _altControllers =
      List.generate(4, (_) => TextEditingController());
  int _correctIndex = 0;

  final Set<String> _attachSources = {'foto', 'audio'};
  final _focusController = TextEditingController();
  _AiState _aiState = _AiState.idle;
  List<_GeneratedCard> _generated = [];
  Set<int> _picked = {};
  Timer? _generateTimer;

  Flashcard? get _editingCard {
    if (widget.editingCardId == null) return null;
    return context.read<AppState>().findDeck(widget.deckId)?.cards.firstWhere(
        (c) => c.id == widget.editingCardId,
        orElse: () => Flashcard(id: '', front: '', back: ''));
  }

  @override
  void initState() {
    super.initState();
    final card = _editingCard;
    if (card != null && card.id.isNotEmpty) {
      _frontController.text = card.front;
      if (card.hasOptions) {
        _responseType = card.options!.length == 2
            ? _ResponseType.duasOpcoes
            : _ResponseType.quatroOpcoes;
        for (var i = 0; i < card.options!.length; i++) {
          _altControllers[i].text = card.options![i];
        }
        _correctIndex = card.correctIndex ?? 0;
      } else {
        _backController.text = card.back;
      }
    } else {
      _frontController.text =
          'Qual neurotransmissor atua na junção neuromuscular?';
      _backController.text = '';
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _focusController.dispose();
    for (final c in _altControllers) {
      c.dispose();
    }
    _generateTimer?.cancel();
    super.dispose();
  }

  Future<void> _openDeckPicker(AppState app) async {
    final decks = app.decks;
    final choice = await showLumeActionSheet(
      context,
      title: 'Salvar em',
      actions: [
        ...decks.map((d) =>
            LumeSheetAction(label: d.name, checked: d.id == _targetDeckId)),
        const LumeSheetAction(label: '+ Criar novo baralho'),
      ],
    );
    if (choice == null || !mounted) return;
    if (choice == decks.length) {
      final newId = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const DeckFormScreen()));
      if (newId != null && mounted) setState(() => _targetDeckId = newId);
    } else {
      setState(() => _targetDeckId = decks[choice].id);
      showLumeToast(context, 'Salvando em ${decks[choice].shortName}');
    }
  }

  void _generate() {
    setState(() => _aiState = _AiState.loading);
    _generateTimer?.cancel();
    _generateTimer = Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      final list = [
        ..._fixedGenerated,
        ..._attachSources
            .map((id) => _sourceGenerated[id])
            .whereType<_GeneratedCard>()
      ];
      setState(() {
        _generated = list;
        _picked = Set.of(List.generate(list.length, (i) => i));
        _aiState = _AiState.done;
      });
    });
  }

  void _save(AppState app, Deck targetDeck) {
    if (_mode == _EntryMode.ai) {
      final selected = _picked.toList()..sort();
      for (final i in selected) {
        final g = _generated[i];
        app.addCard(
            targetDeck.id,
            Flashcard(
              id: 'card-${DateTime.now().microsecondsSinceEpoch}-$i',
              front: g.front,
              back: g.back,
              type: g.type,
              audioSeconds: g.audioSeconds,
              mediaCaption: g.mediaCaption,
              aiGenerated: true,
            ));
      }
      Navigator.of(context).pop();
      showLumeToast(context,
          '${selected.length} cartões salvos em ${targetDeck.shortName}');
      return;
    }

    final options = _responseType == _ResponseType.texto
        ? null
        : _altControllers
            .take(_responseType == _ResponseType.duasOpcoes ? 2 : 4)
            .map((c) => c.text)
            .toList();
    final editing = _editingCard;
    final card = Flashcard(
      id: editing != null && editing.id.isNotEmpty
          ? editing.id
          : 'card-${DateTime.now().microsecondsSinceEpoch}',
      front: _frontController.text.trim(),
      back: options == null
          ? _backController.text.trim()
          : options[_correctIndex],
      options: options,
      correctIndex: options == null ? null : _correctIndex,
      status: editing?.status ?? CardStatus.novo,
      aiGenerated: editing?.aiGenerated ?? false,
    );

    if (editing != null && editing.id.isNotEmpty) {
      app.updateCard(targetDeck.id, card);
      Navigator.of(context).pop();
      showLumeToast(context, 'Cartão atualizado em ${targetDeck.shortName}');
    } else {
      app.addCard(targetDeck.id, card);
      Navigator.of(context).pop();
      showLumeToast(context, 'Cartão salvo em ${targetDeck.shortName}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final targetDeck = app.findDeck(_targetDeckId) ?? app.decks.first;
    final isEditing = widget.editingCardId != null;
    final showSaveAction =
        !(_mode == _EntryMode.ai && _aiState == _AiState.idle);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar',
                        style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            color: context.lume.primary)),
                  ),
                  Text(isEditing ? 'Editar cartão' : 'Novo cartão',
                      style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.lume.ink)),
                  const SizedBox(width: 62),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openDeckPicker(app),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        constraints: const BoxConstraints(minHeight: 60),
                        decoration: BoxDecoration(
                          color: context.lume.background,
                          border: Border.all(color: context.lume.outline),
                          borderRadius: BorderRadius.circular(LumeRadii.field),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                  color: context.lume.surface,
                                  borderRadius: BorderRadius.circular(13)),
                              alignment: Alignment.center,
                              child: Text(targetDeck.initials,
                                  style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: context.lume.primary)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SALVAR EM',
                                      style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.9,
                                          color: context.lume.inkMuted)),
                                  const SizedBox(height: 3),
                                  Text(targetDeck.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: context.lume.ink)),
                                ],
                              ),
                            ),
                            Text('Trocar',
                                style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.lume.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    LumeSegmentedTabs<_EntryMode>(
                      options: const [_EntryMode.type, _EntryMode.ai],
                      labels: const ['Digitar', 'Gerar com IA'],
                      value: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                    ),
                    const SizedBox(height: 22),
                    if (_mode == _EntryMode.type)
                      _TypeModeForm(
                        fontFamily: fontFamily,
                        frontController: _frontController,
                        backController: _backController,
                        responseType: _responseType,
                        onResponseTypeChanged: (t) =>
                            setState(() => _responseType = t),
                        altControllers: _altControllers,
                        correctIndex: _correctIndex,
                        onCorrectIndexChanged: (i) =>
                            setState(() => _correctIndex = i),
                      )
                    else
                      _AiModeForm(
                        fontFamily: fontFamily,
                        aiState: _aiState,
                        generated: _generated,
                        picked: _picked,
                        onTogglePicked: (i) => setState(
                            () => _picked.contains(i)
                                ? _picked.remove(i)
                                : _picked.add(i)),
                        onRegenerate: _generate,
                        attachSources: _attachSources,
                        onToggleSource: (id) => setState(() {
                          if (_attachSources.contains(id)) {
                            _attachSources.remove(id);
                          } else {
                            _attachSources.add(id);
                          }
                        }),
                        focusController: _focusController,
                      ),
                  ],
                ),
              ),
            ),
            if (showSaveAction)
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                top: false,
                child: LumeButton(
                  label: _mode == _EntryMode.ai
                      ? 'Salvar ${_picked.length} em ${targetDeck.shortName}'
                      : (isEditing
                          ? 'Salvar alterações'
                          : 'Salvar em ${targetDeck.shortName}'),
                  onPressed: () => _save(app, targetDeck),
                ),
              )
            else
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                top: false,
                child: LumeButton(
                    label: 'Gerar cartões',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: _generate),
              ),
          ],
        ),
      ),
    );
  }

}

class _AiModeForm extends StatelessWidget {
  const _AiModeForm({
    required this.fontFamily,
    required this.aiState,
    required this.generated,
    required this.picked,
    required this.onTogglePicked,
    required this.onRegenerate,
    required this.attachSources,
    required this.onToggleSource,
    required this.focusController,
  });

  final String? fontFamily;
  final _AiState aiState;
  final List<_GeneratedCard> generated;
  final Set<int> picked;
  final ValueChanged<int> onTogglePicked;
  final VoidCallback onRegenerate;
  final Set<String> attachSources;
  final ValueChanged<String> onToggleSource;
  final TextEditingController focusController;

  @override
  Widget build(BuildContext context) {
    if (aiState == _AiState.loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _PulsingDot(),
              const SizedBox(width: 10),
              Text('Lendo seu material…',
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.lume.primary)),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(
              3,
              (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child:
                        _ShimmerBlock(delay: Duration(milliseconds: i * 150)),
                  )),
        ],
      );
    }

    if (aiState == _AiState.done) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${generated.length} cartões gerados',
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.lume.ink)),
              TextButton(
                onPressed: onRegenerate,
                child: Text('Refazer',
                    style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.lume.primary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...List.generate(generated.length, (i) {
            final g = generated[i];
            final isPicked = picked.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onTogglePicked(i),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: context.lume.background,
                    border: Border.all(
                        color: isPicked
                            ? context.lume.accent
                            : context.lume.outline),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(top: 2, right: 12),
                            decoration: BoxDecoration(
                              color: isPicked
                                  ? context.lume.primary
                                  : Colors.transparent,
                              border: Border.all(
                                  color: isPicked
                                      ? context.lume.primary
                                      : context.lume.outline,
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: isPicked
                                ? Icon(Icons.check_rounded,
                                    size: 14, color: context.lume.background)
                                : null,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.tag,
                                    style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.9,
                                        color: g.type == CardType.text
                                            ? context.lume.inkMuted
                                            : context.lume.primary)),
                                const SizedBox(height: 6),
                                Text(g.front,
                                    style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                        color: context.lume.ink)),
                                const SizedBox(height: 4),
                                Text(g.back,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontSize: 13,
                                        color: context.lume.inkMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (g.type == CardType.audio) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                              color: context.lume.surface,
                              borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => showLumeToast(
                                    context, 'Tocando o trecho de áudio'),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                      color: context.lume.primary,
                                      shape: BoxShape.circle),
                                  child: Icon(Icons.play_arrow_rounded,
                                      size: 14,
                                      color: context.lume.background),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(
                                      '0:${g.audioSeconds.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: context.lume.inkMuted))),
                            ],
                          ),
                        ),
                      ],
                      if (g.type == CardType.image) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: context.lume.surface,
                              borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            children: [
                              Icon(Icons.image_outlined,
                                  size: 22, color: context.lume.inkMuted),
                              const SizedBox(height: 6),
                              Text(g.mediaCaption ?? '',
                                  style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 11,
                                      color: context.lume.inkMuted)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: context.lume.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anexe seu material',
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.lume.ink)),
              const SizedBox(height: 4),
              Text('Foto do caderno, áudio da aula, vídeo ou PDF.',
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 13,
                      height: 1.45,
                      color: context.lume.inkMuted)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
                children: _sources.map((src) {
                  final on = attachSources.contains(src.id);
                  return GestureDetector(
                    onTap: () => onToggleSource(src.id),
                    child: Container(
                      decoration: BoxDecoration(
                          color: on
                              ? context.lume.primary
                              : context.lume.background,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(src.icon,
                              size: 20,
                              color: on
                                  ? context.lume.background
                                  : context.lume.ink),
                          const SizedBox(height: 5),
                          Text(src.label,
                              style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: on
                                      ? context.lume.background
                                      : context.lume.ink)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        if (attachSources.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._sources.where((s) => attachSources.contains(s.id)).map((src) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: context.lume.surface,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: context.lume.background,
                            borderRadius: BorderRadius.circular(11)),
                        alignment: Alignment.center,
                        child:
                            Icon(src.icon, size: 16, color: context.lume.ink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(src.file,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.lume.ink)),
                            const SizedBox(height: 2),
                            Text(src.size,
                                style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 12,
                                    color: context.lume.inkMuted)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => onToggleSource(src.id),
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: context.lume.inkMuted),
                        tooltip: 'Remover anexo',
                      ),
                    ],
                  ),
                ),
              )),
        ],
        const SizedBox(height: 12),
        _MultilineBox(
            controller: focusController,
            minHeight: 76,
            fontFamily: fontFamily,
            placeholder:
                'Opcional: descreva o foco. Ex. "só os pares cranianos".'),
      ],
    );
  }
}

class _TypeModeForm extends StatelessWidget {
  const _TypeModeForm({
    required this.fontFamily,
    required this.frontController,
    required this.backController,
    required this.responseType,
    required this.onResponseTypeChanged,
    required this.altControllers,
    required this.correctIndex,
    required this.onCorrectIndexChanged,
  });

  final String? fontFamily;
  final TextEditingController frontController;
  final TextEditingController backController;
  final _ResponseType responseType;
  final ValueChanged<_ResponseType> onResponseTypeChanged;
  final List<TextEditingController> altControllers;
  final int correctIndex;
  final ValueChanged<int> onCorrectIndexChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LumeFieldLabel('Frente'),
        _MultilineBox(
            controller: frontController, minHeight: 88, fontFamily: fontFamily),
        const SizedBox(height: 20),
        const LumeFieldLabel('Tipo de resposta'),
        LumeSegmentedTabs<_ResponseType>(
          options: const [
            _ResponseType.texto,
            _ResponseType.duasOpcoes,
            _ResponseType.quatroOpcoes
          ],
          labels: const ['Texto', '2 opções', '4 opções'],
          value: responseType,
          onChanged: onResponseTypeChanged,
        ),
        const SizedBox(height: 20),
        if (responseType == _ResponseType.texto) ...[
          const LumeFieldLabel('Verso'),
          _MultilineBox(
              controller: backController,
              minHeight: 88,
              fontFamily: fontFamily,
              placeholder: 'Toque para escrever a resposta'),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ALTERNATIVAS',
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: context.lume.inkMuted)),
              Text('toque para marcar a correta',
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      color: context.lume.inkMuted)),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(responseType == _ResponseType.duasOpcoes ? 2 : 4,
              (i) {
            final selected = correctIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onCorrectIndexChanged(i),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 58),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? context.lume.surface
                        : context.lume.background,
                    border: Border.all(
                        color: selected
                            ? context.lume.primary
                            : context.lume.outline,
                        width: selected ? 1.5 : 1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                            color: selected
                                ? context.lume.primary
                                : context.lume.surface,
                            borderRadius: BorderRadius.circular(9)),
                        alignment: Alignment.center,
                        child: Text(String.fromCharCode(65 + i),
                            style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? context.lume.background
                                    : context.lume.inkMuted)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: altControllers[i],
                          style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 16,
                              color: context.lume.ink),
                          decoration: const InputDecoration(
                              isCollapsed: true, border: InputBorder.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _MultilineBox extends StatelessWidget {
  const _MultilineBox(
      {required this.controller,
      required this.minHeight,
      required this.fontFamily,
      this.placeholder});

  final TextEditingController controller;
  final double minHeight;
  final String? fontFamily;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: context.lume.background,
        border: Border.all(color: context.lume.outline),
        borderRadius: BorderRadius.circular(LumeRadii.field),
      ),
      child: TextField(
        controller: controller,
        minLines: 2,
        maxLines: 6,
        style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 17,
            height: 1.45,
            color: context.lume.ink),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: placeholder,
          hintStyle: TextStyle(
              fontFamily: fontFamily,
              fontSize: 17,
              height: 1.45,
              color: context.lume.inkMuted),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.35).animate(_controller),
      child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: context.lume.primary, shape: BoxShape.circle)),
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({required this.delay});

  final Duration delay;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: [
                context.lume.surface,
                context.lume.background,
                context.lume.surface
              ],
            ),
          ),
        );
      },
    );
  }
}
