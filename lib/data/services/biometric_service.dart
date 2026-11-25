import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricService {
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Verifica se o dispositivo possui suporte a biometria ou bloqueio de tela.
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('Erro ao verificar suporte a biometria: $e');
      return false;
    }
  }

  /// Verifica se o hardware pode checar biometrias cadastradas.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Erro ao verificar biometria disponível: $e');
      return false;
    }
  }

  /// Retorna true se qualquer forma de autenticação local (biometria ou credencial) puder ser usada.
  Future<bool> canAuthenticate() async {
    final supported = await isDeviceSupported();
    final canCheck = await canCheckBiometrics();
    return supported || canCheck;
  }

  /// Lista os tipos de biometria disponíveis no aparelho (digital, rosto, etc.).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Erro ao buscar biometrias disponíveis: $e');
      return const [];
    }
  }

  /// Solicita autenticação biométrica ou credencial do dispositivo.
  Future<bool> authenticate({
    String localizedReason = 'Confirme sua identidade para acessar o Lume',
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Autenticação necessária',
            signInHint: 'Toque no sensor de impressão digital',
            cancelButton: 'Cancelar',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancelar',
          ),
        ],
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Erro ao autenticar biometricamente: $e');
      return false;
    }
  }

  /// Interrompe qualquer solicitação de autenticação em andamento.
  Future<bool> stopAuthentication() async {
    try {
      return await _auth.stopAuthentication();
    } catch (e) {
      debugPrint('Erro ao cancelar autenticação: $e');
      return false;
    }
  }
}
