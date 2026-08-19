import 'package:flutter/material.dart';

import '../theme/lume_colors.dart';

const List<String> weekDayLabels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

/// Fileira de sete dias mostrando a sequência de estudo da semana.
class WeekStreakRow extends StatelessWidget {
  const WeekStreakRow({super.key, required this.progress, this.today});

  final List<bool> progress;
  final int? today;

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final done = progress[i];
        final isToday = today == i;
        return Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: done ? LumeColors.primary : LumeColors.surface,
                shape: BoxShape.circle,
                border: isToday ? Border.all(color: LumeColors.accent, width: 2) : null,
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: LumeColors.background)
                  : null,
            ),
            const SizedBox(height: 7),
            Text(
              weekDayLabels[i],
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: LumeColors.inkMuted,
              ),
            ),
          ],
        );
      }),
    );
  }
}
