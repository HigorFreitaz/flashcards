import 'package:flutter/material.dart';

import '../theme/lume_colors.dart';
import '../theme/lume_metrics.dart';

/// Campo de texto com rótulo em overline acima — o padrão de formulário
/// usado em login, cadastro e nos formulários de baralho e cartão.
class LumeTextField extends StatelessWidget {
  const LumeTextField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.trailing,
    this.minLines,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final int? minLines;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.lume.inkMuted,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: LumeTouch.primaryAction - 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: context.lume.background,
            border: Border.all(color: context.lume.outline),
            borderRadius: BorderRadius.circular(LumeRadii.field),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  minLines: minLines,
                  maxLines: maxLines,
                  autofocus: autofocus,
                  style: TextStyle(fontFamily: fontFamily, fontSize: 16, color: context.lume.ink),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: placeholder,
                    hintStyle: TextStyle(fontFamily: fontFamily, fontSize: 16, color: context.lume.inkMuted),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}

/// Rótulo em overline reutilizado fora de um campo de texto (seções de
/// formulário, cabeçalhos de grupo).
class LumeFieldLabel extends StatelessWidget {
  const LumeFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: context.lume.inkMuted,
        ),
      ),
    );
  }
}
