import 'package:flutter/material.dart';

/// Paleta da Lume: um verde-petróleo carrega toda a ação, os cinzas fazem a
/// hierarquia. Sem gradientes, sem cores de alerta decorativas.
///
/// É um [ThemeExtension] para que o app troque de paleta (claro/escuro) sem
/// que cada tela precise saber qual delas está ativa — basta ler
/// `context.lume` em vez de uma constante fixa.
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
    primary: Color(0xFF006666),
    accent: Color(0xFF008584),
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFE9E9E9),
    outline: Color(0xFFCCCCCC),
    ink: Color(0xFF0D1B1A),
    inkMuted: Color(0xFF5A6B69),
    onPrimary: Color(0xFFF5F5F5),
  );

  static const dark = LumeColors(
    primary: Color(0xFF2FBFB4),
    accent: Color(0xFF57D6CB),
    background: Color(0xFF0D1B1A),
    surface: Color(0xFF17302D),
    outline: Color(0xFF32504B),
    ink: Color(0xFFF5F5F5),
    inkMuted: Color(0xFF8FA6A3),
    onPrimary: Color(0xFF0D1B1A),
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
