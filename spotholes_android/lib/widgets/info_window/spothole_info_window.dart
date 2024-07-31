import 'package:flutter/material.dart';

import '../../models/spothole.dart';
import '../triangle_clipper.dart';

class SpotholeInfoWindow extends StatefulWidget {
  const SpotholeInfoWindow(
      {super.key,
      required this.editSpothole,
      required this.showDeleteSpotholeAlertDialog,
      required this.spothole});

  final Spothole spothole;
  final Function editSpothole;
  final Function showDeleteSpotholeAlertDialog;

  @override
  State<SpotholeInfoWindow> createState() => _SpotholeInfoWindowState();
}

class _SpotholeInfoWindowState extends State<SpotholeInfoWindow> {
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
                Spothole.getImageRiskByType(widget.spothole.type),
                const SizedBox(height: 8.0),
                Text(
                  widget.spothole.type.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.update, color: Colors.white),
                    const SizedBox(width: 4.0),
                    FittedBox(
                      child: Text(
                        Spothole.getFormattedTimeFromLastUpdate(
                            widget.spothole.dateOfUpdate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  color: Colors.blue,
                  onSelected: (value) {
                    value == 'edit'
                        ? widget.editSpothole()
                        : widget.showDeleteSpotholeAlertDialog();
                  },
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Editar',
                              style: TextStyle(color: Colors.white),
                            ),
                            Icon(
                              Icons.edit,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Excluir',
                              style: TextStyle(color: Colors.white),
                            ),
                            Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.0,
                      ),
                    ),
                    child: const Text(
                      'Mais',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
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
