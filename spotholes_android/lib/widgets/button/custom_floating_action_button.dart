import 'package:flutter/material.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final String tooltip;
  final Function onPressed;
  final Widget icon;

  const CustomFloatingActionButton(
      {super.key,
      required this.tooltip,
      required this.onPressed,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: tooltip,
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.grey.shade100,
      onPressed: () => onPressed(),
      heroTag: null,
      child: icon,
    );
  }
}
