import 'package:flutter/material.dart';

import '../theme/lume_colors.dart';
import '../theme/lume_metrics.dart';
import '../theme/lume_motion.dart';

/// Chip de seleção em pílula — ativo em primary, inativo em background.
class LumeChip extends StatelessWidget {
  const LumeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: LumeMotion.tap,
        curve: LumeMotion.curve,
        height: LumeTouch.minimum,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? context.lume.primary : context.lume.background,
          borderRadius: BorderRadius.circular(LumeRadii.pill),
          border: Border.all(color: selected ? context.lume.primary : context.lume.outline),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? context.lume.background : context.lume.ink,
          ),
        ),
      ),
    );
  }
}

/// Selo pequeno, como o marcador "IA" ou a contagem de cartões a revisar.
class LumeBadge extends StatelessWidget {
  const LumeBadge({super.key, required this.label, this.emphasis = false});

  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: emphasis ? context.lume.primary : context.lume.surface,
        borderRadius: BorderRadius.circular(LumeRadii.badge + 6),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: emphasis ? context.lume.background : context.lume.inkMuted,
        ),
      ),
    );
  }
}
