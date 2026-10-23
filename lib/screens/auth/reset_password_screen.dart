import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/buttons/lume_button.dart';
import '../../widgets/inputs/lume_text_field.dart';
import '../../widgets/feedback/lume_toast.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _email = TextEditingController(),
      _token = TextEditingController(),
      _password = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(bool reset) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final vm = context.read<AuthViewModel>();
      if (reset) {
        await vm.resetPassword(_token.text.trim(), _password.text);
      } else {
        await vm.requestReset(_email.text.trim());
      }
      if (!mounted) return;
      showLumeToast(
          context,
          reset
              ? 'Senha alterada. Entre com a nova senha.'
              : 'Se o e-mail estiver cadastrado, você receberá um código.');
      if (reset) Navigator.pop(context);
    } catch (error) {
      if (mounted) showLumeToast(context, error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Recuperar senha')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          LumeTextField(
              label: 'E-mail',
              controller: _email,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          LumeButton(
              label: 'Enviar código',
              loading: _busy,
              onPressed: () => _run(false)),
          const SizedBox(height: 32),
          LumeTextField(
              label: 'Código recebido por e-mail', controller: _token),
          const SizedBox(height: 16),
          LumeTextField(
              label: 'Nova senha (mínimo 8 caracteres)',
              controller: _password,
              obscureText: true),
          const SizedBox(height: 16),
          LumeButton(
              label: 'Redefinir senha',
              loading: _busy,
              onPressed: () => _run(true)),
        ]),
      );
}
