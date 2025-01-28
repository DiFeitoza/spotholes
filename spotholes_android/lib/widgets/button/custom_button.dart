import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final Color fgColor;
  final Color bgColor;
  final VoidCallback onPressed;

  const CustomButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.bgColor = Colors.white,
      this.fgColor = Colors.black});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: fgColor,
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
