import 'package:flutter/material.dart';

import '../theme/lume_colors.dart';
import '../theme/lume_motion.dart';

/// Anel de progresso circular — usado na meta diária e nos widgets de tela
/// de início. Anima suavemente quando o percentual muda.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.percent,
    required this.size,
    this.strokeWidth = 7,
    this.trackColor = LumeColors.surface,
    this.progressColor = LumeColors.primary,
    this.child,
  });

  final double percent;
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent.clamp(0, 1).toDouble()),
      duration: LumeMotion.progress,
      curve: LumeMotion.curve,
      builder: (context, animatedPercent, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  percent: animatedPercent,
                  strokeWidth: strokeWidth,
                  trackColor: trackColor,
                  progressColor: progressColor,
                ),
              ),
              if (child != null) child!,
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.percent,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  final double percent;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 6.2832, false, track);

    final progress = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const start = -1.5708; // topo (-90°)
    final sweep = 6.2832 * percent;
    canvas.drawArc(rect, start, sweep, false, progress);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
