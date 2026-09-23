import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/deck_repository.dart';
import '../../theme/lume_colors.dart';
import '../../theme/lume_metrics.dart';
import '../../viewmodels/deck_form_view_model.dart';
import '../../widgets/buttons/lume_button.dart';
import '../../widgets/chips/lume_chip.dart';
import '../../widgets/inputs/lume_stepper.dart';
import '../../widgets/inputs/lume_switch.dart';
import '../../widgets/inputs/lume_text_field.dart';
import '../../widgets/feedback/lume_toast.dart';

/// Cria um baralho novo, ou edita um existente quando [deckId] é informado.
class DeckFormScreen extends StatelessWidget {
  const DeckFormScreen({super.key, this.deckId});

  final String? deckId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => DeckFormViewModel(ctx.read<DeckRepository>(), deckId),
      child: const _DeckFormView(),
    );
  }
}

class _DeckFormView extends StatefulWidget {
  const _DeckFormView();

  @override
  State<_DeckFormView> createState() => _DeckFormViewState();
}

class _DeckFormViewState extends State<_DeckFormView> {
  late final _nameController = TextEditingController();
  late final _descriptionController = TextEditingController();
  int _goal = 20;
  bool _remindersEnabled = true;
  List<String> _reminderTimes = ['20:00'];
  bool _initialized = false;

  void _initFromDeck(DeckFormViewModel viewModel) {
    if (_initialized) return;
    final deck = viewModel.existingDeck;
    if (deck != null) {
      _nameController.text = deck.name;
      _descriptionController.text = deck.description;
      _goal = deck.dailyGoal;
      _remindersEnabled = deck.remindersEnabled;
      _reminderTimes = List.of(deck.reminderTimes);
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _reminderTag(String time) {
    if (time.compareTo('12:00') < 0) return 'manhã';
    if (time.compareTo('18:00') < 0) return 'tarde';
    return 'noite';
  }

  Future<void> _openTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Adicionar horário',
    );
    if (picked == null || !mounted) return;
    final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (_reminderTimes.contains(formatted)) return;
    setState(() {
      _reminderTimes = [..._reminderTimes, formatted]..sort();
      _remindersEnabled = true;
    });
    showLumeToast(context, 'Lembrete adicionado às $formatted');
  }

  void _removeReminder(String time) {
    if (_reminderTimes.length == 1) {
      setState(() => _remindersEnabled = false);
      showLumeToast(context, 'Lembretes desativados');
      return;
    }
    setState(
        () => _reminderTimes = _reminderTimes.where((t) => t != time).toList());
  }

  void _save() {
    final viewModel = context.read<DeckFormViewModel>();
    final isEditing = viewModel.isEditing;
    final deck = viewModel.save(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      dailyGoal: _goal,
      remindersEnabled: _remindersEnabled,
      reminderTimes: _reminderTimes,
    );
    Navigator.of(context).pop(deck.id);
    showLumeToast(context, isEditing ? 'Baralho atualizado' : 'Baralho "${deck.shortName}" criado');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DeckFormViewModel>();
    _initFromDeck(viewModel);
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Center(
                child: Text(
                  viewModel.isEditing ? 'Editar baralho' : 'Novo baralho',
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.lume.ink),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LumeTextField(
                        label: 'Nome do baralho',
                        controller: _nameController,
                        placeholder: 'Ex. Bioquímica — Enzimas'),
                    const SizedBox(height: 20),
                    const LumeFieldLabel('Descrição (opcional)'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: context.lume.background,
                        border: Border.all(color: context.lume.outline),
                        borderRadius: BorderRadius.circular(LumeRadii.field),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        minLines: 2,
                        maxLines: 4,
                        style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            height: 1.45,
                            color: context.lume.ink),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Para que serve este baralho?',
                          hintStyle: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 16,
                              height: 1.45,
                              color: context.lume.inkMuted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const LumeFieldLabel('Cartões por dia'),
                    LumeStepper(
                      value: _goal,
                      caption:
                          'cartões · ≈ ${(_goal * 0.75).round().clamp(3, 999)} min',
                      onDecrement: () => setState(
                          () => _goal = (_goal - 5).clamp(5, 100).toInt()),
                      onIncrement: () => setState(
                          () => _goal = (_goal + 5).clamp(5, 100).toInt()),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [10, 20, 40]
                          .map((g) => LumeChip(
                              label: '$g cartões',
                              selected: _goal == g,
                              onTap: () => setState(() => _goal = g)))
                          .toList(),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      decoration: BoxDecoration(
                          color: context.lume.surface,
                          borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Lembretes',
                                          style: TextStyle(
                                              fontFamily: fontFamily,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: context.lume.ink)),
                                      const SizedBox(height: 3),
                                      Text(
                                        _remindersEnabled
                                            ? (_reminderTimes.length == 1
                                                ? '1 horário por dia'
                                                : '${_reminderTimes.length} horários por dia')
                                            : 'Desativado',
                                        style: TextStyle(
                                            fontFamily: fontFamily,
                                            fontSize: 13,
                                            color: context.lume.inkMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                LumeSwitch(
                                  value: _remindersEnabled,
                                  semanticLabel: 'Lembretes',
                                  onChanged: (v) =>
                                      setState(() => _remindersEnabled = v),
                                ),
                              ],
                            ),
                          ),
                          if (_remindersEnabled)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  border: Border(
                                      top: BorderSide(
                                          color: context.lume.outline))),
                              child: Column(
                                children: [
                                  ..._reminderTimes.map((time) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Container(
                                          padding: const EdgeInsets.only(
                                              left: 14, right: 4),
                                          constraints: const BoxConstraints(
                                              minHeight: 54),
                                          decoration: BoxDecoration(
                                              color: context.lume.background,
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          child: Row(
                                            children: [
                                              Icon(Icons.schedule_rounded,
                                                  size: 17,
                                                  color: context.lume.primary),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(time,
                                                    style: TextStyle(
                                                        fontFamily: fontFamily,
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            context.lume.ink)),
                                              ),
                                              Text(_reminderTag(time),
                                                  style: TextStyle(
                                                      fontFamily: fontFamily,
                                                      fontSize: 12,
                                                      color: context
                                                          .lume.inkMuted)),
                                              IconButton(
                                                onPressed: () =>
                                                    _removeReminder(time),
                                                icon: Icon(Icons.close_rounded,
                                                    size: 18,
                                                    color:
                                                        context.lume.inkMuted),
                                                tooltip: 'Remover lembrete',
                                              ),
                                            ],
                                          ),
                                        ),
                                      )),
                                  OutlinedButton(
                                    onPressed: _openTimePicker,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(50),
                                      side: BorderSide(
                                          color: context.lume.outline),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                    ),
                                    child: Text(
                                      '+ Adicionar horário',
                                      style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: context.lume.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              top: false,
              child: Row(
                children: [
                  LumeButton(
                    label: 'Cancelar',
                    variant: LumeButtonVariant.secondary,
                    expand: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LumeButton(
                        label: viewModel.isEditing ? 'Salvar alterações' : 'Criar baralho',
                        onPressed: _save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
