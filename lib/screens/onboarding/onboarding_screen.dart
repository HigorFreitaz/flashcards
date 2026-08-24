import 'package:flutter/material.dart';

import '../../theme/lume_colors.dart';
import '../../widgets/buttons/lume_button.dart';
import '../../widgets/branding/lume_logo.dart';
import '../root/root_shell.dart';

class _OnboardingStep {
  const _OnboardingStep({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

const _steps = [
  _OnboardingStep(
    icon: Icons.auto_awesome_rounded,
    title: 'Gere a partir de qualquer coisa',
    body: 'Anexe uma foto do caderno, o áudio da aula, um vídeo ou um PDF. '
        'A IA transforma o material em cartões prontos para revisar.',
  ),
  _OnboardingStep(
    icon: Icons.update_rounded,
    title: 'Revisão no tempo certo',
    body: 'Cada cartão volta no intervalo ideal para a sua memória. '
        'Você só responde o que está prestes a esquecer.',
  ),
  _OnboardingStep(
    icon: Icons.wifi_off_rounded,
    title: 'Funciona offline',
    body: 'Estude no metrô, na fila, sem sinal. O app guarda tudo no '
        'aparelho e sincroniza quando a conexão voltar.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootShell()),
    );
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step += 1);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final step = _steps[_step];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              const LumeWordmark(markSize: 38, fontSize: 22),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey(_step),
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        margin: const EdgeInsets.only(bottom: 28),
                        decoration: BoxDecoration(
                          color: context.lume.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Icon(step.icon, size: 34, color: context.lume.primary),
                      ),
                      Text(
                        'PASSO ${_step + 1} DE ${_steps.length}',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: context.lume.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        step.title,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 32,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.9,
                          color: context.lume.ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        step.body,
                        style: TextStyle(fontFamily: fontFamily, fontSize: 16, height: 1.55, color: context.lume.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    final active = i == _step;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                      width: active ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? context.lume.primary : context.lume.outline,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
              Row(
                children: [
                  if (_step > 0) ...[
                    LumeIconButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: _back,
                      semanticLabel: 'Voltar',
                      filled: true,
                      size: 56,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: LumeButton(
                      label: _step < _steps.length - 1 ? 'Continuar' : 'Começar a estudar',
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Pular apresentação',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.lume.inkMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
