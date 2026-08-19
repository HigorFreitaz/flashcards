import 'package:flutter/material.dart';
import 'lume_colors.dart';

/// Escala de texto da Lume — oito níveis, do display ao overline.
/// A fonte em si é resolvida pela plataforma em [lumeFontFamily]; aqui só
/// fixamos tamanho, altura de linha e peso, como no kit de design.
class LumeText {
  LumeText._();

  static TextStyle display(String fontFamily) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 34,
        height: 1.10,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: LumeColors.ink,
      );

  static TextStyle titleLarge(String fontFamily) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: LumeColors.ink,
      );

  static TextStyle titleMedium(String fontFamily) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        height: 1.30,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: LumeColors.ink,
      );

  static TextStyle bodyLarge(String fontFamily) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: LumeColors.ink,
      );

  static TextStyle body(String fontFamily) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        height: 1.50,
        fontWeight: FontWeight.w400,
        color: LumeColors.ink,
      );

  static TextStyle label(String fontFamily) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: LumeColors.inkMuted,
      );

  static TextStyle caption(String fontFamily) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: LumeColors.inkMuted,
      );

  static TextStyle overline(String fontFamily) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: LumeColors.inkMuted,
      );
}
