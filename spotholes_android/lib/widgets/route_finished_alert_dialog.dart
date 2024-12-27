import 'package:flutter/material.dart';

import 'button/auto_press_button.dart';

class RouteFinishedAlertDialogs extends StatelessWidget {
  final VoidCallback onConfirm;

  const RouteFinishedAlertDialogs({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmação'),
      content: const Text('Trajeto concluído com sucesso!'),
      actions: [
        AutoPressButton(
          textOnRegisterButton: 'Concluir',
          onPressButton: onConfirm,
        )
      ],
    );
  }
}
