import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/models/spothole.dart';
import 'package:spotholes_android/services/service_locator.dart';
import 'package:spotholes_android/widgets/register_spothole_modal.dart';

import '../utilities/custom_icons.dart';

mixin RegisterSpothole {
  final markersSignal = getIt<Signal<Map<String, Marker>>>();
  final DatabaseReference databaseReference = GetIt.I<DatabaseReference>();

  void loadSpotholeMarkers() {
    databaseReference.child('spotholes').once().then((DatabaseEvent event) {
      final spotholesMap = event.snapshot.value as Map?;
      if (spotholesMap != null) {
        spotholesMap.forEach((key, value) {
          final spothole =
              Spothole.fromJson(Map<String, dynamic>.from(value as Map));
          final marker = Marker(
            markerId: MarkerId(key),
            icon: CustomIcons.potholeIcon,
            position: spothole.position,
            infoWindow: InfoWindow(
              title: 'Categoria: ${spothole.category.text}',
              snippet: '''
                Risco: ${spothole.type.text}
                \nData de registro${spothole.dateOfRegister}
                \nÚtimma Atualização:${spothole.dateOfUpdate}''',
            ),
          );
          markersSignal.value[key] = marker;
        });
      }
    });
  }

  void addSpotholeMarker(String key, Spothole spothole) {
    final marker = Marker(
      markerId: MarkerId(key),
      icon: CustomIcons.potholeIcon,
      position: spothole.position,
      infoWindow: InfoWindow(
        title: 'Categoria: ${spothole.category.text}',
        snippet: '''
          Risco: ${spothole.type.text}
          \nData de registro${spothole.dateOfRegister}
          \nÚtimma Atualização:${spothole.dateOfUpdate}''',
      ),
    );
    markersSignal.value[key] = marker;
  }

  void registerSpothole(position, category, type) {
    final DatabaseReference databaseReference = GetIt.I<DatabaseReference>();
    DatabaseReference spotholeRef = databaseReference.child('spotholes');
    Spothole newSpothole = Spothole(DateTime.now().toUtc(),
        DateTime.now().toUtc(), position, category, type);
    final newSpotHoleRef = spotholeRef.push();
    newSpotHoleRef.set(newSpothole.toJson());
    addSpotholeMarker(newSpotHoleRef.key!, newSpothole);
  }

  void registerSpotholeModal(context, position) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return RegisterSpotholeModal(
          latLng: LatLng(position!.latitude!, position!.longitude!),
        );
      },
    );
  }
}
