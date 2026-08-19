import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'lume_colors.dart';
import 'lume_metrics.dart';
import 'lume_text.dart';

/// Fonte do sistema em cada plataforma — mantém o app parecendo nativo e
/// evita carregar arquivos de fonte.
String lumeFontFamily(TargetPlatform platform) {
  return platform == TargetPlatform.iOS ? '.SF Pro Text' : 'Roboto';
}

ThemeData buildLumeTheme({TargetPlatform? platform, Brightness brightness = Brightness.light}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  final fontFamily = lumeFontFamily(resolvedPlatform);
  final palette = brightness == Brightness.dark ? LumeColors.dark : LumeColors.light;

  final textTheme = TextTheme(
    displaySmall: LumeText.display(fontFamily, palette),
    titleLarge: LumeText.titleLarge(fontFamily, palette),
    titleMedium: LumeText.titleMedium(fontFamily, palette),
    bodyLarge: LumeText.bodyLarge(fontFamily, palette),
    bodyMedium: LumeText.body(fontFamily, palette),
    labelLarge: LumeText.label(fontFamily, palette),
    labelSmall: LumeText.overline(fontFamily, palette),
  );

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.primary,
    onPrimary: palette.onPrimary,
    secondary: palette.accent,
    onSecondary: palette.onPrimary,
    surface: palette.background,
    onSurface: palette.ink,
    surfaceContainerHighest: palette.surface,
    outlineVariant: palette.outline,
    error: const Color(0xFFB3261E),
    onError: palette.onPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    platform: resolvedPlatform,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.background,
    fontFamily: fontFamily,
    textTheme: textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    iconTheme: IconThemeData(size: 22, color: palette.ink),
    dividerColor: palette.outline,
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: palette.ink,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LumeRadii.sheet)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.ink,
      contentTextStyle: LumeText.body(fontFamily, palette).copyWith(color: palette.background),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumeRadii.field)),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: LumeSpacing.screenMargin,
        vertical: LumeSpacing.screenMargin,
      ),
    ),
  );
}
