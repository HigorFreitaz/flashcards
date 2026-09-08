import '../../models/app_user.dart';

/// Simula um serviço de autenticação externo. Sem I/O real: reconhece um
/// único usuário de teste, só para o fluxo de login/cadastro funcionar.
class AuthService {
  AppUser? login(AppUser credentials) {
    if (credentials.email == 'thomas.vaz@gmail.com' && credentials.password == 'thomas34') {
      return AppUser(name: 'Thomas Jefersson Vaz', email: 'thomas.vaz@gmail.com', password: 'thomas34');
    }
    return null;
  }

  AppUser? signup(AppUser user) {
    if (user.email == 'thomas.vaz@gmail.com') return null;
    return AppUser(name: user.name, email: user.email, password: user.password);
  }
}
