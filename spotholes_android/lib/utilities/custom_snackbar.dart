import 'package:flutter/material.dart';

class CustomSnackbar {
  static show(
      {required BuildContext context,
      required String message,
      VoidCallbackAction? onActionPressed}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 500),
        // showCloseIcon: true,
        content: Text(message),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => onActionPressed,
        ),
      ),
    );
  }
}
