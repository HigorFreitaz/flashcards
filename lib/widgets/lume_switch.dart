import 'package:flutter/material.dart';

import '../theme/lume_colors.dart';
import '../theme/lume_motion.dart';

/// Interruptor 56×32 do kit de design — trilha colorida, disco branco.
class LumeSwitch extends StatelessWidget {
  const LumeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      toggled: value,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: LumeMotion.tap,
          curve: LumeMotion.curve,
          width: 56,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? LumeColors.primary : LumeColors.outline,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: LumeColors.background,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
