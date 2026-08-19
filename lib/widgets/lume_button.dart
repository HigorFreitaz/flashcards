import 'package:flutter/material.dart';

import '../theme/lume_colors.dart';
import '../theme/lume_metrics.dart';
import '../theme/lume_motion.dart';

/// Botão pílula que encolhe sutilmente ao toque — o mesmo gesto usado em
/// todo o kit de design da Lume (escala 0,96–0,98 em 160ms).
class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.onTap, required this.child, this.scale = 0.98});

  final VoidCallback? onTap;
  final Widget child;
  final double scale;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: LumeMotion.tap,
        curve: LumeMotion.curve,
        child: widget.child,
      ),
    );
  }
}

enum LumeButtonVariant { primary, secondary, text }

class LumeButton extends StatelessWidget {
  const LumeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = LumeButtonVariant.primary,
    this.icon,
    this.expand = true,
    this.height = LumeTouch.primaryAction,
  });

  final String label;
  final VoidCallback? onPressed;
  final LumeButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final Color background;
    final Color foreground;
    final BoxBorder? border;

    switch (variant) {
      case LumeButtonVariant.primary:
        background = disabled ? LumeColors.outline : LumeColors.primary;
        foreground = LumeColors.background;
        border = null;
        break;
      case LumeButtonVariant.secondary:
        background = LumeColors.background;
        foreground = disabled ? LumeColors.inkMuted : LumeColors.primary;
        border = Border.all(color: LumeColors.outline);
        break;
      case LumeButtonVariant.text:
        background = Colors.transparent;
        foreground = disabled ? LumeColors.inkMuted : LumeColors.primary;
        border = null;
    }

    final content = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: background,
        border: border,
        borderRadius: BorderRadius.circular(LumeRadii.pill),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19, color: foreground),
            const SizedBox(width: 9),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );

    final button = _PressableScale(onTap: onPressed, child: content);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Botão circular usado para ações de ícone isoladas (voltar, fechar, mais).
class LumeIconButton extends StatelessWidget {
  const LumeIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.filled = false,
    this.size = LumeTouch.minimum,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onPressed,
      scale: 0.92,
      child: Semantics(
        label: semanticLabel,
        button: true,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: filled ? LumeColors.background : Colors.transparent,
            border: filled ? Border.all(color: LumeColors.outline) : null,
            borderRadius: BorderRadius.circular(size * 0.34),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 21, color: LumeColors.ink),
        ),
      ),
    );
  }
}
