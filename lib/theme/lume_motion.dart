import 'package:flutter/material.dart';

/// Uma curva só para quase tudo. Toque responde rápido; nada passa de 800ms.
class LumeMotion {
  LumeMotion._();

  static const curve = Curves.easeOutCubic;

  static const tap = Duration(milliseconds: 160);
  static const enter = Duration(milliseconds: 280);
  static const flip = Duration(milliseconds: 500);
  static const progress = Duration(milliseconds: 750);
}
