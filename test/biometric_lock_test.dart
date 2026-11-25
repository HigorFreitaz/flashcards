import 'package:lume/app.dart';
import 'package:lume/data/services/api_service.dart';
import 'package:lume/data/services/biometric_service.dart';
import 'package:lume/data/services/session_store.dart';
import 'package:lume/screens/auth/biometric_lock_screen.dart';
import 'package:lume/widgets/inputs/lume_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBiometricService extends BiometricService {
  FakeBiometricService({
    this.canAuth = true,
    this.authResult = true,
  });

  bool canAuth;
  bool authResult;
  int authAttempts = 0;

  @override
  Future<bool> isDeviceSupported() async => canAuth;

  @override
  Future<bool> canCheckBiometrics() async => canAuth;

  @override
  Future<bool> canAuthenticate() async => canAuth;

  @override
  Future<bool> authenticate({
    String localizedReason = 'Confirme sua identidade para acessar o Lume',
    bool biometricOnly = false,
  }) async {
    authAttempts++;
    return authResult;
  }
}

class TestAuthApi extends ApiService {
  TestAuthApi({this.biometricEnabled = false});

  bool biometricEnabled;

  @override
  String? get authToken => 'test-token';

  @override
  Future<dynamic> get(String path) async {
    if (path == '/auth/me') {
      return {
        'user': {'id': 'user-1', 'name': 'Teste', 'email': 'teste@lume.app'},
      };
    }
    if (path == '/settings') {
      return {
        'themeMode': 'light',
        'biometricLockEnabled': biometricEnabled,
        'timeZone': 'America/Sao_Paulo',
      };
    }
    if (path == '/decks') return <dynamic>[];
    if (path == '/challenges/active') return <dynamic>[];
    if (path == '/notifications') return <dynamic>[];
    if (path == '/study/progress') {
      return {'streak': 0, 'cardsLearned': 0, 'todayStudied': 0};
    }
    return {};
  }

  @override
  Future<dynamic> put(String path, dynamic body) async {
    if (path == '/settings' && body is Map) {
      if (body.containsKey('biometricLockEnabled')) {
        biometricEnabled = body['biometricLockEnabled'] as bool;
      }
      return {
        'themeMode': 'light',
        'biometricLockEnabled': biometricEnabled,
        'timeZone': 'America/Sao_Paulo',
      };
    }
    return {};
  }

  @override
  Future<dynamic> post(String path, dynamic body) async {
    if (path == '/auth/logout') {
      return {'ok': true};
    }
    return {};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Settings toggle verifies biometric capability before enabling',
      (tester) async {
    final fakeBiometric = FakeBiometricService(canAuth: false);
    final api = TestAuthApi(biometricEnabled: false);
    final session = MemorySessionStore()..token = 'test-token';

    await tester.pumpWidget(LumeApp(
      apiService: api,
      sessionStore: session,
      biometricService: fakeBiometric,
    ));
    await tester.pumpAndSettle();

    // Navega para a aba de Ajustes (ícone de índice 3 na barra inferior)
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    // Encontra o switch de bloqueio biométrico
    final switchFinder = find.byWidgetPredicate(
        (w) => w is LumeSwitch && w.semanticLabel == 'Bloqueio por biometria');
    expect(switchFinder, findsOneWidget);

    // Tenta ativar o switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Não deve ter ativado pois o aparelho não suporta
    expect(api.biometricEnabled, isFalse);
    expect(find.text('Biometria ou bloqueio de tela não disponível neste aparelho'),
        findsOneWidget);
  });

  testWidgets(
      'Settings toggle prompts authentication and enables on success',
      (tester) async {
    final fakeBiometric = FakeBiometricService(canAuth: true, authResult: true);
    final api = TestAuthApi(biometricEnabled: false);
    final session = MemorySessionStore()..token = 'test-token';

    await tester.pumpWidget(LumeApp(
      apiService: api,
      sessionStore: session,
      biometricService: fakeBiometric,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    final switchFinder = find.byWidgetPredicate(
        (w) => w is LumeSwitch && w.semanticLabel == 'Bloqueio por biometria');
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(fakeBiometric.authAttempts, 1);
    expect(api.biometricEnabled, isTrue);
    expect(find.text('Bloqueio por biometria ativado'), findsOneWidget);
  });

  testWidgets(
      'App locks when returning from background if biometricLockEnabled is true and unlocks on success',
      (tester) async {
    final fakeBiometric = FakeBiometricService(canAuth: true, authResult: true);
    final api = TestAuthApi(biometricEnabled: true);
    final session = MemorySessionStore()..token = 'test-token';

    await tester.pumpWidget(LumeApp(
      apiService: api,
      sessionStore: session,
      biometricService: fakeBiometric,
    ));
    // Espera cold-start avaliar e autenticar
    await tester.pumpAndSettle();

    expect(find.byType(BiometricLockScreen), findsNothing);

    // Simula app indo para o segundo plano
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    // Simula retorno ao primeiro plano com falha inicial para verificar tela de bloqueio
    fakeBiometric.authResult = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // App agora está bloqueado exibindo a tela de bloqueio
    expect(find.byType(BiometricLockScreen), findsOneWidget);
    expect(find.text('Lume bloqueado'), findsOneWidget);

    // Agora usuário autentica com sucesso ao tocar em Desbloquear
    fakeBiometric.authResult = true;
    await tester.tap(find.text('Desbloquear'));
    await tester.pumpAndSettle();

    // Autenticação bem-sucedida destrava o app
    expect(find.byType(BiometricLockScreen), findsNothing);
  });

  testWidgets(
      'Lock screen displays error when authentication fails and retries on button tap',
      (tester) async {
    final fakeBiometric = FakeBiometricService(canAuth: true, authResult: false);
    final api = TestAuthApi(biometricEnabled: true);
    final session = MemorySessionStore()..token = 'test-token';

    await tester.pumpWidget(LumeApp(
      apiService: api,
      sessionStore: session,
      biometricService: fakeBiometric,
    ));
    await tester.pumpAndSettle();

    // Falhou no cold start, então tela de bloqueio está visível
    expect(find.byType(BiometricLockScreen), findsOneWidget);
    expect(find.text('Não foi possível autenticar. Toque em Desbloquear para tentar novamente.'),
        findsOneWidget);

    // Usuário permite sucesso na próxima tentativa
    fakeBiometric.authResult = true;

    // Toca no botão Desbloquear
    await tester.tap(find.text('Desbloquear'));
    await tester.pumpAndSettle();

    // Agora destravou
    expect(find.byType(BiometricLockScreen), findsNothing);
  });

  testWidgets('Lock screen allows logout', (tester) async {
    final fakeBiometric = FakeBiometricService(canAuth: true, authResult: false);
    final api = TestAuthApi(biometricEnabled: true);
    final session = MemorySessionStore()..token = 'test-token';

    await tester.pumpWidget(LumeApp(
      apiService: api,
      sessionStore: session,
      biometricService: fakeBiometric,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(BiometricLockScreen), findsOneWidget);

    // Toca em Sair da conta
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    // Deve voltar para a tela de autenticação / login
    expect(find.byType(BiometricLockScreen), findsNothing);
    expect(find.text('Criar conta'), findsOneWidget);
  });
}
