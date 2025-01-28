import 'package:flutter/material.dart';

class DeleteSpotholeAlertDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeleteSpotholeAlertDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmação'),
      content:
          const Text('Tem certeza de que deseja excluir este alerta de risco?'),
      actions: [
        TextButton(
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text('Excluir'),
        ),
      ],
    );
  }
}
