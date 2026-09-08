import 'package:flutter/material.dart';

import '../../theme/lume_colors.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

SnackBar _lumeSnackBar(BuildContext context, String message) {
  final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
  return SnackBar(
    duration: const Duration(milliseconds: 1500),
    content: Row(
      children: [
        Icon(Icons.check_rounded, size: 18, color: context.lume.background),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontFamily: fontFamily, fontSize: 14, color: context.lume.background),
          ),
        ),
      ],
    ),
  );
}

void showLumeToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(_lumeSnackBar(context, message));
}

/// Mesmo visual do [showLumeToast], mas sem depender de um [BuildContext]
/// local — usa a chave global do app. Necessário para avisos disparados
/// fora da árvore de widgets (ex. [AppState]) ou logo após uma navegação
/// que substitui a tela atual.
void showGlobalLumeToast(String message) {
  final messengerState = scaffoldMessengerKey.currentState;
  if (messengerState == null) return;
  messengerState
    ..clearSnackBars()
    ..showSnackBar(_lumeSnackBar(messengerState.context, message));
}
