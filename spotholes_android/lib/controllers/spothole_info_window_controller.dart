import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals.dart';
import 'package:spotholes_android/package/custom_info_window.dart';

import '../main.dart';
import '../models/spothole.dart';
import '../services/service_locator.dart';
import '../utilities/constants.dart';
import '../utilities/custom_icons.dart';
import '../widgets/delete_spothole_alert_dialog.dart';
import '../widgets/info_window/spothole_info_window.dart';
import '../widgets/modal/register_spothole_modal.dart';

class SpotholeInfoWindowController {
  final Signal<CustomInfoWindowController> _customInfoWindowControllerSignal;
  final Signal<Map<String, Marker>> _markersSignal;

  final databaseReference = getIt<DatabaseReference>();
  late final dataBaseSpotholesRef = databaseReference.child('spotholes');

  SpotholeInfoWindowController(
    this._customInfoWindowControllerSignal,
    this._markersSignal,
  );

  void updateCameraGoogleMapsController(position, [zoom = defaultZoomMap]) {
    _customInfoWindowControllerSignal.value.googleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: zoom,
          target: position,
        ),
      ),
    );
  }

  void addSpotholeMarker(Spothole spothole) {
    final context = MyApp.navigatorKey.currentContext;
    final marker = Marker(
      markerId: MarkerId(spothole.id!),
      icon: spothole.type == Type.deepHole
          ? CustomIcons.potholeRedSignIcon
          : CustomIcons.potholeSignIcon,
      position: spothole.position,
      onTap: () {
        _customInfoWindowControllerSignal.value.addInfoWindow!(
          SpotholeInfoWindow(
            editSpothole: () => editSpotholeModal(
                context, spothole.id!, spothole.category, spothole.type),
            showDeleteSpotholeAlertDialog: () =>
                showDeleteSpotholeAlertDialog(context, spothole.id!),
            spothole: spothole,
          ),
          spothole.position,
        );
      },
    );
    _markersSignal.value[spothole.id!] = marker;
  }

  void editSpothole(context, spotholeId, riskCategory, type) async {
    final dateOfUpdate = DateTime.now().toUtc();
    final spotholeRef = databaseReference.ref.child('spotholes/$spotholeId');
    final event = await spotholeRef.once();
    final spotholeJson = Map<String, dynamic>.from(event.snapshot.value as Map);
    final spothole = Spothole.fromJson(spotholeJson);
    spothole.dateOfUpdate = dateOfUpdate;
    spothole.category = riskCategory;
    spothole.type = type;
    spothole.id = spotholeId;
    addSpotholeMarker(spothole);
    _markersSignal.value = {..._markersSignal.value};
    _markersSignal.value[spotholeId]!.onTap!();
    updateCameraGoogleMapsController(spothole.position);
    spotholeRef.set(spothole.toJson());
  }

  void editSpotholeModal(context, spotholeId, riskCategory, riskType) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return RegisterSpotholeModal(
          title: "Para editar um risco, selecione:",
          textOnRegisterButton: "Editar",
          isCountdown: false,
          onRegister: (riskCategory, type) =>
              editSpothole(context, spotholeId, riskCategory, type),
          riskCategory: riskCategory,
          riskType: riskType,
        );
      },
    );
  }

  void showDeleteSpotholeAlertDialog(context, String spotholeId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DeleteSpotholeAlertDialog(
          onConfirm: () {
            deleteSpothole(spotholeId);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void deleteSpothole(String spotholeId) {
    dataBaseSpotholesRef.child(spotholeId).remove();
    _customInfoWindowControllerSignal.value.hideInfoWindow!();
    removeMarkerByid(spotholeId);
  }

  void removeMarkerByid(spotholeId) {
    _markersSignal.value.remove(spotholeId);
    _markersSignal.value = {..._markersSignal.value};
  }
}
