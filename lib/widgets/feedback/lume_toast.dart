import 'package:flutter/material.dart';

import '../../theme/lume_colors.dart';

void showLumeToast(BuildContext context, String message) {
  final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        content: Row(
          children: [
            Icon(Icons.check_rounded, size: 18, color: context.lume.background),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontFamily: fontFamily, fontSize: 14, color: context.lume.background),
              ),
            ),
          ],
        ),
      ),
    );
}
