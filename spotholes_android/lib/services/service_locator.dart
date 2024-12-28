import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  /// Setup Firebase
  getIt.registerLazySingleton<DatabaseReference>(() {
    return FirebaseDatabase.instance.ref();
  });
}
