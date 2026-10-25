import 'data/services/offline_api_service.dart';
import 'data/services/offline_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/challenge_repository.dart';
import 'data/repositories/deck_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/services/api_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/session_store.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/root/root_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'theme/lume_theme.dart';

class LumeApp extends StatelessWidget {
  const LumeApp(
      {super.key, this.apiService, this.sessionStore, this.offlineStore});
  final OfflineStore? offlineStore;
  final SessionStore? sessionStore;

  final ApiService? apiService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<OfflineStore>(
            create: (_) =>
                offlineStore ??
                (apiService == null
                    ? SqliteOfflineStore()
                    : MemoryOfflineStore())),
        Provider<ApiService>(create: (_) => apiService ?? ApiService()),
        Provider(
            create: (ctx) => AuthService(ctx.read<ApiService>(),
                sessionStore: sessionStore ??
                    (apiService == null
                        ? SqliteSessionStore()
                        : MemorySessionStore()))),
        ChangeNotifierProvider(
            create: (ctx) =>
                UserRepository(ctx.read<AuthService>())..restore()),
      ],
      child: _AccountScope(
          offlineEnabled: apiService == null || offlineStore != null),
    );
  }
}

class _AccountScope extends StatelessWidget {
  const _AccountScope({required this.offlineEnabled});
  final bool offlineEnabled;
  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserRepository>().currentUser?.id;
    return MultiProvider(
      key: ValueKey(userId),
      providers: [
        if (offlineEnabled && userId != null)
          Provider<ApiService>(
            create: (ctx) => OfflineApiService(context.read<ApiService>(),
                context.read<OfflineStore>(), userId),
            dispose: (_, api) => (api as OfflineApiService).dispose(),
          ),
        ChangeNotifierProvider(
            create: (ctx) => DeckRepository(ctx.read<ApiService>())),
        ChangeNotifierProvider(
            create: (ctx) => NotificationRepository(ctx.read<ApiService>())),
        ChangeNotifierProvider(
            create: (ctx) => ChallengeRepository(ctx.read<ApiService>())),
        ChangeNotifierProvider(
            create: (ctx) => SettingsRepository(ctx.read<ApiService>())),
        ChangeNotifierProvider(
            create: (ctx) => ProgressRepository(ctx.read<ApiService>())),
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
      home: context.watch<UserRepository>().restoring
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : context.watch<UserRepository>().currentUser == null
              ? const AuthScreen()
              : context.read<UserRepository>().newlyRegistered
                  ? const OnboardingScreen()
                  : const RootShell(),
    );
  }
}
