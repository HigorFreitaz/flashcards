import 'package:flutter/material.dart';

import 'dark/lume_dark_palette.dart';
import 'light/lume_light_palette.dart';

/// Paleta da Lume: um verde-petróleo carrega toda a ação, os cinzas fazem a
/// hierarquia. Sem gradientes, sem cores de alerta decorativas.
///
/// É um [ThemeExtension] para que o app troque de paleta (claro/escuro) sem
/// que cada tela precise saber qual delas está ativa — basta ler
/// `context.lume` em vez de uma constante fixa. Os valores de cada paleta
/// vivem em [LumeLightPalette]/[LumeDarkPalette]; esta classe só descreve o
/// formato compartilhado entre elas.
@immutable
class LumeColors extends ThemeExtension<LumeColors> {
  const LumeColors({
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.outline,
    required this.ink,
    required this.inkMuted,
    required this.onPrimary,
  });

  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color outline;
  final Color ink;
  final Color inkMuted;
  final Color onPrimary;

  static const light = LumeColors(
    primary: LumeLightPalette.primary,
    accent: LumeLightPalette.accent,
    background: LumeLightPalette.background,
    surface: LumeLightPalette.surface,
    outline: LumeLightPalette.outline,
    ink: LumeLightPalette.ink,
    inkMuted: LumeLightPalette.inkMuted,
    onPrimary: LumeLightPalette.onPrimary,
  );

  static const dark = LumeColors(
    primary: LumeDarkPalette.primary,
    accent: LumeDarkPalette.accent,
    background: LumeDarkPalette.background,
    surface: LumeDarkPalette.surface,
    outline: LumeDarkPalette.outline,
    ink: LumeDarkPalette.ink,
    inkMuted: LumeDarkPalette.inkMuted,
    onPrimary: LumeDarkPalette.onPrimary,
  );

  @override
  LumeColors copyWith({
    Color? primary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? outline,
    Color? ink,
    Color? inkMuted,
    Color? onPrimary,
  }) {
    return LumeColors(
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      outline: outline ?? this.outline,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      onPrimary: onPrimary ?? this.onPrimary,
    );
  }

  @override
  LumeColors lerp(ThemeExtension<LumeColors>? other, double t) {
    if (other is! LumeColors) return this;
    return LumeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
    );
  }
}

/// Acesso ergonômico à paleta ativa: `context.lume.primary`.
extension LumeColorsContext on BuildContext {
  LumeColors get lume => Theme.of(this).extension<LumeColors>() ?? LumeColors.light;
}
