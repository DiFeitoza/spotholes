import 'package:custom_info_window/custom_info_window.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/models/spothole.dart';
// import 'package:spotholes_android/package/custom_info_windows.dart'; //local package
import 'package:spotholes_android/services/service_locator.dart';
import 'package:spotholes_android/widgets/register_spothole_modal.dart';

import '../utilities/custom_icons.dart';

mixin RegisterSpothole {
  final markersSignal = getIt<Signal<Map<String, Marker>>>();
  final DatabaseReference databaseReference = GetIt.I<DatabaseReference>();
  final CustomInfoWindowController customInfoWindowController =
      GetIt.I<CustomInfoWindowController>();

  void addSpotholeMarker(String key, Spothole spothole) {
    final marker = Marker(
      markerId: MarkerId(key),
      icon: CustomIcons.potholeSignIcon,
      position: spothole.position,
      onTap: () {
        customInfoWindowController.addInfoWindow!(
          Column(
            children: [
              Expanded(
                child: Container(
                  // Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Spothole.getImageRiskByType(spothole.type),
                        const SizedBox(height: 8.0),
                        Text(
                          spothole.type.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.update, color: Colors.white),
                            const SizedBox(width: 4.0),
                            FittedBox(
                                child: Text(
                              Spothole.getFormattedTimeFromLastUpdate(
                                  spothole.dateOfUpdate),
                              style: const TextStyle(
                                color: Colors.white,
                                // fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          spothole.position,
        );
      },
    );
    markersSignal.value[key] = marker;
  }

  void loadSpotholeMarkers() {
    databaseReference.child('spotholes').once().then((DatabaseEvent event) {
      final spotholesMap = event.snapshot.value as Map?;
      if (spotholesMap != null) {
        spotholesMap.forEach((key, value) {
          final spothole =
              Spothole.fromJson(Map<String, dynamic>.from(value as Map));
          addSpotholeMarker(key, spothole);
        });
      }
    });
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
