import 'api_service.dart';
import 'session_store.dart';
import '../../models/app_user.dart';

class AuthService {
  AuthService(this._api, {SessionStore? sessionStore})
      : _store = sessionStore ?? MemorySessionStore();
  final ApiService _api;
  final SessionStore _store;
  Future<AppUser?> _authenticate(
      String path, Map<String, dynamic> payload) async {
    final response = await _api.post(path, payload);
    final token = response['token'] as String;
    await _store.save(token);
    _api.authToken = token;
    await _cacheUser(response['user'] as Map<String, dynamic>);
    return AppUser.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<AppUser?> login(AppUser user) => _authenticate(
      '/auth/login', {'email': user.email, 'password': user.password});
  Future<AppUser?> signup(AppUser user) => _authenticate('/auth/signup',
      {'name': user.name, 'email': user.email, 'password': user.password});
  Future<void> _cacheUser(Map<String, dynamic> user) async {
    final previous = await _store.readUser();
    await _store.saveUser({
      'user': user,
      'offlineUntil': previous?['offlineUntil'] ??
          DateTime.now().toUtc().add(const Duration(days: 29)).toIso8601String()
    });
  }

  Future<AppUser?> restore() async {
    _api.authToken = await _store.read();
    if (_api.authToken == null) return null;
    try {
      final response = await _api.get('/auth/me');
      await _cacheUser(response['user'] as Map<String, dynamic>);
      return AppUser.fromJson(response['user'] as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      _api.authToken = null;
      await _store.clear();
      return null;
    } catch (error) {
      if (!isConnectionFailure(error)) rethrow;
      final cached = await _store.readUser();
      final until = DateTime.tryParse(cached?['offlineUntil'] ?? '');
      if (until != null && until.isAfter(DateTime.now())) {
        return AppUser.fromJson(Map<String, dynamic>.from(cached!['user']));
      }
      rethrow;
    }
  }

  Future<AppUser?> updateProfile(String id,
      {String? name, String? email, String? password}) async {
    final response = await _api.put('/auth/profile', {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return AppUser.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<void> requestReset(String email) async {
    await _api.post('/auth/forgot-password', {'email': email});
  }

  Future<void> resetPassword(String token, String password) async {
    await _api
        .post('/auth/reset-password', {'token': token, 'password': password});
  }

  Future<void> deleteAccount() async {
    await _api.delete('/auth/account');
  }

  Future<void> logout() async {
    // Clear persistence before allowing the UI to report a successful logout.
    await _store.clear();
    final request = _api.post('/auth/logout', {});
    _api.authToken = null;
    await request.catchError((_) => null);
  }
}
