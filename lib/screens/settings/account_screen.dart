import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user_repository.dart';
import '../../viewmodels/account_view_model.dart';
import '../../widgets/feedback/lume_bottom_sheet.dart';
import '../../widgets/buttons/lume_button.dart';
import '../../widgets/inputs/lume_text_field.dart';
import '../../widgets/feedback/lume_toast.dart';
import '../auth/auth_screen.dart';
import '../../theme/lume_theme.dart';

/// Gerenciamento da conta — nome, e-mail, senha e a exclusão da conta.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AccountViewModel(ctx.read<UserRepository>()),
      child: const _AccountView(),
    );
  }
}

class _AccountView extends StatefulWidget {
  const _AccountView();

  @override
  State<_AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<_AccountView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AccountViewModel>().currentUser;
    _nameController.text = user.name;
    _emailController.text = user.email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _save() {
    final newPassword = _newPasswordController.text;
    if (newPassword.isNotEmpty && newPassword != _confirmPasswordController.text) {
      showLumeToast(context, 'As senhas não coincidem');
      return;
    }
    context.read<AccountViewModel>().updateProfile(name: _nameController.text, email: _emailController.text);
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    showLumeToast(context, 'Perfil atualizado');
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final choice = await showLumeActionSheet(
      context,
      title: 'Excluir conta',
      actions: const [LumeSheetAction(label: 'Excluir minha conta permanentemente', danger: true)],
    );
    if (choice != 0 || !mounted) return;
    context.read<AccountViewModel>().deleteAccount();
    showLumeToast(context, 'Conta Deletada');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Voltar', style: TextStyle(fontFamily: fontFamily, fontSize: 16, color: context.lume.primary)),
                  ),
                  Text('Minha conta', style: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: context.lume.ink)),
                  const SizedBox(width: 62),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LumeTextField(label: 'Nome', controller: _nameController),
                    const SizedBox(height: 14),
                    LumeTextField(label: 'E-mail', controller: _emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 22),
                    const LumeFieldLabel('Alterar senha'),
                    LumeTextField(label: 'Nova senha', controller: _newPasswordController, placeholder: 'mínimo 8 caracteres', obscureText: true),
                    const SizedBox(height: 14),
                    LumeTextField(label: 'Confirmar nova senha', controller: _confirmPasswordController, obscureText: true),
                    const SizedBox(height: 30),
                    LumeButton(label: 'Salvar alterações', onPressed: _save),
                    const SizedBox(height: 34),
                    Container(height: 1, color: context.lume.outline),
                    const SizedBox(height: 26),
                    Text(
                      'Zona de risco',
                      style: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: context.lume.inkMuted),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Excluir sua conta remove seus baralhos, cartões e sua sequência de estudo. Essa ação não pode ser desfeita.',
                      style: TextStyle(fontFamily: fontFamily, fontSize: 13, height: 1.45, color: context.lume.inkMuted),
                    ),
                    const SizedBox(height: 16),
                    LumeButton(label: 'Excluir conta', variant: LumeButtonVariant.danger, onPressed: _confirmDelete),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
