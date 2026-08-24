import 'package:flutter/material.dart';

import '../../theme/lume_colors.dart';
import '../../theme/lume_metrics.dart';

class LumeSheetAction {
  const LumeSheetAction({
    required this.label,
    this.danger = false,
    this.checked = false,
  });

  final String label;
  final bool danger;
  final bool checked;
}

/// Folha inferior de ações — alça de arraste, título em overline, linhas
/// de ação e um botão "Cancelar" fixo no rodapé.
Future<int?> showLumeActionSheet(
  BuildContext context, {
  required String title,
  required List<LumeSheetAction> actions,
}) {
  final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
  return showModalBottomSheet<int>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: context.lume.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      color: context.lume.inkMuted,
                    ),
                  ),
                ),
              ),
              ...List.generate(actions.length, (i) {
                final action = actions[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _SheetRow(
                    action: action,
                    fontFamily: fontFamily,
                    onTap: () => Navigator.of(sheetContext).pop(i),
                  ),
                );
              }),
              const SizedBox(height: 4),
              LumeSheetCancelButton(fontFamily: fontFamily),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.action, required this.fontFamily, required this.onTap});

  final LumeSheetAction action;
  final String? fontFamily;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.lume.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  action.label,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: action.danger ? const Color(0xFFB3261E) : context.lume.ink,
                  ),
                ),
              ),
              if (action.checked)
                Icon(Icons.check_rounded, size: 18, color: context.lume.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class LumeSheetCancelButton extends StatelessWidget {
  const LumeSheetCancelButton({super.key, this.fontFamily});

  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(LumeTouch.primaryAction - 2),
          side: BorderSide(color: context.lume.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumeRadii.pill)),
        ),
        child: Text(
          'Cancelar',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.lume.inkMuted,
          ),
        ),
      ),
    );
  }
}
