import 'package:flutter/material.dart';

import 'triangle_clipper.dart';

class MarkerInfoWindow extends StatefulWidget {
  const MarkerInfoWindow({
    super.key,
    required this.textContent,
    required this.title,
  });

  final String? textContent;
  final String title;

  @override
  State<MarkerInfoWindow> createState() => _MarkerInfoWindowState();
}

class _MarkerInfoWindowState extends State<MarkerInfoWindow> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.textContent != null ? widget.textContent! : "Marcador",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        ClipPath(
          clipper: TriangleClipper(),
          child: Container(
            color: Colors.blue,
            height: 10,
            width: 20,
          ),
        ),
      ],
    );
  }
}
