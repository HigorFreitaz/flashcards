import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/challenge_repository.dart';
import 'data/repositories/deck_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/services/auth_service.dart';
import 'screens/auth/auth_screen.dart';
import 'theme/lume_theme.dart';

class LumeApp extends StatelessWidget {
  const LumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (ctx) => UserRepository(ctx.read<AuthService>())),
        ChangeNotifierProvider(create: (_) => DeckRepository()),
        ChangeNotifierProvider(create: (_) => NotificationRepository()),
        ChangeNotifierProvider(create: (_) => ChallengeRepository()),
        ChangeNotifierProvider(create: (_) => SettingsRepository()),
        Provider(create: (_) => ProgressRepository()),
      ],
      child: const _LumeMaterialApp(),
    );
  }
}

/// Separado do [LumeApp] só para que o `MaterialApp` consiga observar o
/// [SettingsRepository] (o `Provider` só fica visível para os widgets abaixo dele).
class _LumeMaterialApp extends StatelessWidget {
  const _LumeMaterialApp();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<SettingsRepository>().themeMode;
    return MaterialApp(
      title: 'Lume',
      debugShowCheckedModeBanner: false,
      theme: buildLumeTheme(brightness: Brightness.light),
      darkTheme: buildLumeTheme(brightness: Brightness.dark),
      themeMode: themeMode,
      home: const AuthScreen(),
    );
  }
}
