import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotholes_android/models/spothole.dart';
import 'package:spotholes_android/widgets/register_spothole_modal.dart';

mixin RegisterSpothole {
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

  Spothole registerSpothole(position, category, type) {
    final DatabaseReference databaseReference = GetIt.I<DatabaseReference>();
    DatabaseReference spotholeRef = databaseReference.child('spotholes');
    Spothole newSpothole = Spothole(DateTime.now().toUtc(),
        DateTime.now().toUtc(), position, category, type);
    final newSpotHoleRef = spotholeRef.push();
    newSpotHoleRef.set(newSpothole.toJson());
    return newSpothole;
  }
}
