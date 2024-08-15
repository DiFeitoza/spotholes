import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals.dart';
import 'package:spotholes_android/package/custom_info_window.dart';

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

  void addSpotholeMarker(context, String key, Spothole spothole) {
    final marker = Marker(
      markerId: MarkerId(key),
      icon: CustomIcons.potholeSignIcon,
      position: spothole.position,
      onTap: () {
        _customInfoWindowControllerSignal.value.addInfoWindow!(
          SpotholeInfoWindow(
            editSpothole: () => editSpotholeModal(
                context, key, spothole.category, spothole.type),
            showDeleteSpotholeAlertDialog: () =>
                showDeleteSpotholeAlertDialog(context, key),
            spothole: spothole,
          ),
          spothole.position,
        );
      },
    );
    _markersSignal.value[key] = marker;
  }

  void editSpothole(context, key, riskCategory, type) async {
    final dateOfUpdate = DateTime.now().toUtc();
    final spotholeRef = databaseReference.ref.child('spotholes/$key');
    final event = await spotholeRef.once();
    final spotholeJson = Map<String, dynamic>.from(event.snapshot.value as Map);
    final spothole = Spothole.fromJson(spotholeJson);
    spothole.dateOfUpdate = dateOfUpdate;
    spothole.category = riskCategory;
    spothole.type = type;
    addSpotholeMarker(context, key, spothole);
    _markersSignal.value[key]!.onTap!();
    updateCameraGoogleMapsController(spothole.position);
    spotholeRef.set(spothole.toJson());
  }

  void editSpotholeModal(context, key, riskCategory, riskType) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return RegisterSpotholeModal(
          title: "Para editar um risco, selecione:",
          textOnRegisterButton: "Editar",
          isCountdown: false,
          onRegister: (riskCategory, type) =>
              editSpothole(context, key, riskCategory, type),
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
    removeMarkerByKey(spotholeId);
  }

  void removeMarkerByKey(key) {
    _markersSignal.value.remove(key);
  }
}
