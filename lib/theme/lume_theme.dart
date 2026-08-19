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

ThemeData buildLumeTheme([TargetPlatform? platform]) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  final fontFamily = lumeFontFamily(resolvedPlatform);
  final textTheme = TextTheme(
    displaySmall: LumeText.display(fontFamily),
    titleLarge: LumeText.titleLarge(fontFamily),
    titleMedium: LumeText.titleMedium(fontFamily),
    bodyLarge: LumeText.bodyLarge(fontFamily),
    bodyMedium: LumeText.body(fontFamily),
    labelLarge: LumeText.label(fontFamily),
    labelSmall: LumeText.overline(fontFamily),
  );

  final colorScheme = const ColorScheme.light(
    primary: LumeColors.primary,
    onPrimary: LumeColors.onPrimary,
    secondary: LumeColors.accent,
    onSecondary: LumeColors.onPrimary,
    surface: LumeColors.background,
    onSurface: LumeColors.ink,
    surfaceContainerHighest: LumeColors.surface,
    outlineVariant: LumeColors.outline,
    error: Color(0xFFB3261E),
  );

  return ThemeData(
    useMaterial3: true,
    platform: resolvedPlatform,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: LumeColors.background,
    fontFamily: fontFamily,
    textTheme: textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    iconTheme: const IconThemeData(size: 22, color: LumeColors.ink),
    dividerColor: LumeColors.outline,
    appBarTheme: const AppBarTheme(
      backgroundColor: LumeColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: LumeColors.ink,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LumeColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LumeRadii.sheet)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LumeColors.ink,
      contentTextStyle: LumeText.body(fontFamily).copyWith(color: LumeColors.background),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumeRadii.field)),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: LumeSpacing.screenMargin,
        vertical: LumeSpacing.screenMargin,
      ),
    ),
  );
}
