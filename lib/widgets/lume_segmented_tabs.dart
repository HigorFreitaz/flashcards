import 'package:flutter/material.dart';

import '../theme/lume_colors.dart';
import '../theme/lume_metrics.dart';
import '../theme/lume_motion.dart';

/// Alternador de duas ou três opções em pílula — usado em Entrar/Criar
/// conta, Digitar/Gerar com IA, tipo de resposta etc.
class LumeSegmentedTabs<T> extends StatelessWidget {
  const LumeSegmentedTabs({
    super.key,
    required this.options,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  final List<T> options;
  final List<String> labels;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LumeColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final selected = options[i] == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(options[i]),
              child: AnimatedContainer(
                duration: LumeMotion.tap,
                curve: LumeMotion.curve,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? LumeColors.background : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: LumeColors.ink.withValues(alpha: 0.12),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? LumeColors.primary : LumeColors.inkMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
