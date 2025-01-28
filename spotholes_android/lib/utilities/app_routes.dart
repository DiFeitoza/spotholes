import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotholes_android/pages/base_map_page.dart';
import 'package:spotholes_android/pages/route_page.dart';

import '../controllers/route_controller.dart';
import '../pages/navigation_page.dart';

abstract class AppRoutes {
  static const baseMap = '/';
  static const route = '/route';
  static const navigation = '/navigation';

  static Map<String, Widget Function(BuildContext)> get routes => {
        baseMap: (context) {
          return const BaseMapPage();
        },
        route: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as List;
          final LatLng sourceLocation = args[0];
          final LatLng destinationLocation = args[1];
          return RoutePage(
            sourceLocation: sourceLocation,
            destinationLocation: destinationLocation,
          );
        },
        navigation: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as List;
          final RouteController routeController = args[0];
          return NavigationPage(routeController: routeController);
        }
      };
}
