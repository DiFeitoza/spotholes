import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:spotholes_android/utilities/app_routes.dart';

import '../config/environment_config.dart';
import '../services/service_locator.dart';
import '../utilities/custom_icons.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await EnvironmentConfig.loadEnvVariables();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupDependencies();
  CustomIcons.setupCustomIcons();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Creates a global key for the Navigator, allowing the global context to be accessed outside the widget tree (solution for controllers).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /// Implements the AppNavigatorObserver to handle all route changes
      // navigatorObservers: [AppNavigatorObserver()],
      navigatorObservers: [routeObserver],
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Spotholes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: AppRoutes.baseMap,
      routes: AppRoutes.routes,
    );
  }
}
