import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/controllers/spothole_info_window_controller.dart';
import 'package:spotholes_android/services/service_locator.dart';

import '../main.dart';
import '../models/spothole.dart';
import '../package/custom_info_window.dart';
import '../utilities/point_on_route_haversine.dart';
import '../widgets/modal/register_spothole_modal.dart';

class SpotholeService {
  final DatabaseReference databaseReference = getIt<DatabaseReference>();
  late final DatabaseReference dataBaseSpotholesRef =
      databaseReference.child('spotholes');
  final Signal<Map<String, Marker>> _markersSignal;
  final Signal<CustomInfoWindowController> _customInfoWindowControllerSignal;

  late final _spotholeInfoWindowController = SpotholeInfoWindowController(
    _customInfoWindowControllerSignal,
    _markersSignal,
  );

  SpotholeService(this._markersSignal, this._customInfoWindowControllerSignal);

  void loadSpotholeMarkers() {
    databaseReference.child('spotholes').once().then(
      (DatabaseEvent event) {
        final spotholesMap = event.snapshot.value as Map?;
        if (spotholesMap != null) {
          spotholesMap.forEach(
            (key, value) {
              final spothole =
                  Spothole.fromJson(Map<String, dynamic>.from(value as Map));
              spothole.id = key;
              _spotholeInfoWindowController.addSpotholeMarker(
                spothole,
              );
            },
          );
          _markersSignal.value = {..._markersSignal.value};
        }
      },
    );
  }

  void loadSpotholesInRoute(routePolylineCoordinates, spotholesInRouteList) {
    databaseReference.child('spotholes').once().then(
      (DatabaseEvent event) {
        final spotholesMap = event.snapshot.value as Map?;
        if (spotholesMap != null) {
          final spotholeList = spotholesMap.entries.map((entry) {
            final spothole = Spothole.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            );
            spothole.id = entry.key;
            return spothole;
          }).toList();
          spotholesInRouteList.value = checkPointsAndStoreAccumulatedDistances(
            spotholeList,
            routePolylineCoordinates,
          );
          addSpotholeMarkers(spotholesInRouteList);
        }
      },
    );
  }

  void addSpotholeMarkers(spotholesInRouteList) {
    for (Spothole spothole in spotholesInRouteList.value) {
      _spotholeInfoWindowController.addSpotholeMarker(spothole);
    }
    _markersSignal.value = {..._markersSignal.value};
  }

  void registerSpothole(LatLng position, Category category, Type type) {
    final newSpotHoleRef = dataBaseSpotholesRef.push();
    final newSpothole = Spothole(
      DateTime.now().toUtc(),
      DateTime.now().toUtc(),
      position,
      category,
      type,
      null,
      newSpotHoleRef.key,
    );
    newSpotHoleRef.set(newSpothole.toJson());
    _spotholeInfoWindowController.addSpotholeMarker(newSpothole);
    _markersSignal.value = {..._markersSignal.value};
  }

  void registerSpotholeModal(LatLng position) {
    final context = MyApp.navigatorKey.currentContext;
    showModalBottomSheet(
      context: context!,
      builder: (builder) {
        return RegisterSpotholeModal(
          title: "Para alertar um risco, selecione:",
          textOnRegisterButton: "Adicionar",
          onRegister: (
              [Category riskCategory = Category.unitary,
              Type type = Type.pothole]) {
            registerSpothole(position, riskCategory, type);
          },
        );
      },
    );
  }
}
