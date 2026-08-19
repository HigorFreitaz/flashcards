import 'package:flutter/material.dart';
import 'lume_colors.dart';

/// Escala de texto da Lume — oito níveis, do display ao overline.
/// A fonte em si é resolvida pela plataforma em [lumeFontFamily]; a cor
/// vem da paleta ativa (`palette`), para que sirva tanto o tema claro
/// quanto o escuro. Tamanho, altura de linha e peso ficam fixos, como no
/// kit de design.
class LumeText {
  LumeText._();

  static TextStyle display(String fontFamily, LumeColors palette) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 34,
        height: 1.10,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: palette.ink,
      );

  static TextStyle titleLarge(String fontFamily, LumeColors palette) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: palette.ink,
      );

  static TextStyle titleMedium(String fontFamily, LumeColors palette) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        height: 1.30,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: palette.ink,
      );

  static TextStyle bodyLarge(String fontFamily, LumeColors palette) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: palette.ink,
      );

  static TextStyle body(String fontFamily, LumeColors palette) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        height: 1.50,
        fontWeight: FontWeight.w400,
        color: palette.ink,
      );

  static TextStyle label(String fontFamily, LumeColors palette) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: palette.inkMuted,
      );

  static TextStyle caption(String fontFamily, LumeColors palette) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: palette.inkMuted,
      );

  static TextStyle overline(String fontFamily, LumeColors palette) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: palette.inkMuted,
      );
}
