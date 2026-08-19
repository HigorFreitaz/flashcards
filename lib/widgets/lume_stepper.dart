import 'package:flutter/material.dart';

import '../theme/lume_colors.dart';
import '../theme/lume_metrics.dart';
import 'lume_button.dart';

/// Controle "− valor +" usado para cartões por dia, número de perguntas etc.
class LumeStepper extends StatelessWidget {
  const LumeStepper({
    super.key,
    required this.value,
    required this.caption,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int value;
  final String caption;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.lume.background,
        border: Border.all(color: context.lume.outline),
        borderRadius: BorderRadius.circular(LumeRadii.field),
      ),
      child: Row(
        children: [
          LumeIconButton(
            icon: Icons.remove_rounded,
            onPressed: onDecrement,
            semanticLabel: 'Diminuir',
            filled: true,
            size: 48,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: context.lume.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: TextStyle(fontFamily: fontFamily, fontSize: 12, color: context.lume.inkMuted),
                ),
              ],
            ),
          ),
          LumeIconButton(
            icon: Icons.add_rounded,
            onPressed: onIncrement,
            semanticLabel: 'Aumentar',
            filled: true,
            size: 48,
          ),
        ],
      ),
    );
  }
}
