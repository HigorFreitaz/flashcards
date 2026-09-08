import 'package:flutter/material.dart';

import '../../theme/lume_colors.dart';

/// O símbolo da marca: dois cartões deslocados — o da frente claro, o de
/// trás em accent — dentro de um quadrado de canto contínuo.
class LumeMark extends StatelessWidget {
  const LumeMark({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cardSize = Size(size * 0.4, size * 0.3);
    final offset = size * 0.1;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.lume.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: cardSize.width + offset,
        height: cardSize.height + offset,
        child: Stack(
          children: [
            Positioned(
              left: offset,
              top: offset,
              child: _MarkCard(cardSize: cardSize, color: context.lume.accent),
            ),
            _MarkCard(cardSize: cardSize, color: context.lume.background),
          ],
        ),
      ),
    );
  }
}

class _MarkCard extends StatelessWidget {
  const _MarkCard({required this.cardSize, required this.color});

  final Size cardSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardSize.width,
      height: cardSize.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Logo horizontal — marca + nome, usado em login e onboarding.
class LumeWordmark extends StatelessWidget {
  const LumeWordmark({super.key, this.markSize = 30, this.fontSize = 19});

  final double markSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LumeMark(size: markSize),
        SizedBox(width: markSize * 0.33),
        Text(
          'Lume.',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: context.lume.ink,
          ),
        ),
      ],
    );
  }
}
