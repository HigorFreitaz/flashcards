import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/lume_colors.dart';
import '../../theme/lume_metrics.dart';
import '../../widgets/lume_button.dart';
import '../../widgets/lume_logo.dart';
import '../../widgets/lume_segmented_tabs.dart';
import '../../widgets/lume_text_field.dart';
import '../onboarding/onboarding_screen.dart';
import '../root/root_shell.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthMode _mode = _AuthMode.signIn;
  bool _showPassword = false;

  final _nameController = TextEditingController(text: 'Ana Ribeiro');
  final _emailController = TextEditingController(text: 'ana.ribeiro@exemplo.com');
  final _passwordController = TextEditingController(text: 'segredo123');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_mode == _AuthMode.signUp) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _mode == _AuthMode.signUp;
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              const LumeWordmark(markSize: 50, fontSize: 30),
              const SizedBox(height: 34),
              LumeSegmentedTabs<_AuthMode>(
                options: const [_AuthMode.signIn, _AuthMode.signUp],
                labels: const ['Entrar', 'Criar conta'],
                value: _mode,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
              const SizedBox(height: 26),
              Text(
                isSignUp ? 'Criar sua conta' : 'Entrar na sua conta',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: context.lume.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSignUp
                    ? 'Leva menos de um minuto. Você começa a estudar em seguida.'
                    : 'Seus baralhos e sua sequência sincronizam em todos os aparelhos.',
                style: TextStyle(fontFamily: fontFamily, fontSize: 15, height: 1.5, color: context.lume.inkMuted),
              ),
              const SizedBox(height: 26),
              if (isSignUp) ...[
                LumeTextField(
                  label: 'Nome',
                  controller: _nameController,
                  placeholder: 'Ana Ribeiro',
                ),
                const SizedBox(height: 14),
              ],
              LumeTextField(
                label: 'E-mail',
                controller: _emailController,
                placeholder: 'ana@exemplo.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              LumeTextField(
                label: 'Senha',
                controller: _passwordController,
                placeholder: 'mínimo 8 caracteres',
                obscureText: !_showPassword,
                trailing: TextButton(
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                  style: TextButton.styleFrom(minimumSize: const Size(0, LumeTouch.minimum)),
                  child: Text(
                    _showPassword ? 'Ocultar' : 'Mostrar',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.lume.primary,
                    ),
                  ),
                ),
              ),
              if (!isSignUp) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      final app = context.read<AppState>();
                      app.showToast('Enviamos um link de acesso para seu e-mail');
                    },
                    style: TextButton.styleFrom(minimumSize: const Size(0, LumeTouch.minimum)),
                    child: Text(
                      'Esqueci minha senha',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.lume.primary,
                      ),
                    ),
                  ),
                ),
              ],
              if (isSignUp) ...[
                const SizedBox(height: 14),
                Text(
                  'Ao criar sua conta você aceita os Termos e a Política de privacidade.',
                  style: TextStyle(fontFamily: fontFamily, fontSize: 13, height: 1.5, color: context.lume.inkMuted),
                ),
              ],
              const SizedBox(height: 30),
              LumeButton(
                label: isSignUp ? 'Criar conta' : 'Entrar',
                onPressed: _submit,
              ),
              const SizedBox(height: 14),
              Text(
                isSignUp
                    ? 'Seus dados são tratados conforme a LGPD (Lei 13.709/2018).'
                    : 'Protegemos seus dados conforme a LGPD.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: fontFamily, fontSize: 12, height: 1.5, color: context.lume.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
