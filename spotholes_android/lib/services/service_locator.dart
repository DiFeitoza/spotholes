import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:signals/signals.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/package/custom_info_windows.dart'; //local package

final getIt = GetIt.instance;

void setupDependencies() {
  // Setup Firebase
  getIt.registerLazySingleton<DatabaseReference>(() {
    return FirebaseDatabase.instance.ref();
  });

  // Setup Locator
  getIt.registerSingleton<Signal<LocationData?>>(Signal<LocationData?>(null));

  // Setup Map Assets
  getIt.registerSingleton<Signal<Map<String, Marker>>>(
      Signal<Map<String, Marker>>({}));

  getIt.registerSingleton<CustomInfoWindowController>(
      CustomInfoWindowController());
}
