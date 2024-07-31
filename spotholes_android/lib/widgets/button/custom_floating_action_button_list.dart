import 'package:flutter/material.dart';
import 'package:spotholes_android/controllers/base_map_controller.dart';

import '../../utilities/custom_icons.dart';
import 'custom_floating_action_button.dart';

class CustomFloatingActionButtonList extends StatelessWidget {
  CustomFloatingActionButtonList({super.key});
  final _baseMapController = BaseMapController.instance;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 220,
      right: 10,
      left: 0,
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            CustomFloatingActionButton(
                tooltip: "Adicionar um risco",
                onPressed: () =>
                    _baseMapController.registerSpotholeModal(context),
                icon: CustomIcons.potholeAddIcon),
            const SizedBox(height: 10),
            CustomFloatingActionButton(
                tooltip: "Sincronizar os riscos",
                onPressed: () =>
                    _baseMapController.loadSpotholeMarkers(context),
                icon: const Icon(Icons.sync)),
            const SizedBox(height: 10),
            CustomFloatingActionButton(
              tooltip: "Centralizar a câmera",
              onPressed: _baseMapController.centerView,
              icon: const Icon(Icons.location_searching),
            ),
          ],
        ),
      ),
    );
  }
}
