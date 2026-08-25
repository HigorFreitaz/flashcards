import 'package:flutter/material.dart';
import 'package:lume/widgets/feedback/lume_toast.dart';
import 'package:provider/provider.dart';

import 'screens/auth/auth_screen.dart';
import 'state/app_state.dart';
import 'theme/lume_theme.dart';

class LumeApp extends StatelessWidget {
  const LumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const _LumeMaterialApp(),
    );
  }
}

/// Separado do [LumeApp] só para que o `MaterialApp` consiga observar o
/// [AppState] (o `Provider` só fica visível para os widgets abaixo dele).
class _LumeMaterialApp extends StatelessWidget {
  const _LumeMaterialApp();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppState>().themeMode;
    return MaterialApp(
      title: 'Lume',
      debugShowCheckedModeBanner: false,
      theme: buildLumeTheme(brightness: Brightness.light),
      darkTheme: buildLumeTheme(brightness: Brightness.dark),
      themeMode: themeMode,
      home: const AuthScreen(),
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}
