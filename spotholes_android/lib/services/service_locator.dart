import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
// import 'services/firebase_service.dart';
// import 'services/api_service.dart';

final getIt = GetIt.instance;

void setupDependencies() { 
  getIt.registerLazySingleton<DatabaseReference>(() {
    return FirebaseDatabase.instance.ref();
  });
}

