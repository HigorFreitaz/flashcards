import 'package:flutter/material.dart';
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
      child: MaterialApp(
        title: 'Lume',
        debugShowCheckedModeBanner: false,
        theme: buildLumeTheme(),
        home: const AuthScreen(),
      ),
    );
  }
}
