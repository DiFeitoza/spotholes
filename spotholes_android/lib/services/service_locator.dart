import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:location/location.dart';
import 'package:signals/signals.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Setup Firebase
  getIt.registerLazySingleton<DatabaseReference>(() {
    return FirebaseDatabase.instance.ref();
  });

  // Setup Locator
  getIt.registerSingleton<Signal<LocationData?>>(Signal<LocationData?>(null));
}