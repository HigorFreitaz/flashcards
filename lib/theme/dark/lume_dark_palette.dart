import 'package:flutter/material.dart';

/// Valores brutos da paleta escura. Revisados na issue #4: a primeira versão
/// tingia background/surface/outline no mesmo verde-petróleo do primary, o
/// que deixava tudo "abafado" dentro do app. Agora os neutros seguem a mesma
/// ideia da paleta clara — cinzas sem matiz — e o teal fica reservado só
/// para ação (primary/accent), o que dá mais contraste e respiro nas telas.
class LumeDarkPalette {
  static const primary = Color(0xFF2FBFBA);
  static const accent = Color(0xFF57D6D1);
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const outline = Color(0xFF333333);
  static const ink = Color(0xFFF2F2F2);
  static const inkMuted = Color(0xFFA0A0A0);
  static const onPrimary = Color(0xFF0D1B1A);
}
