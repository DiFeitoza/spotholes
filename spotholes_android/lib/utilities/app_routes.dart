import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotholes_android/pages/base_map_page.dart';
import 'package:spotholes_android/pages/route_page.dart';

abstract class AppRoutes {
  static const baseMap = '/';
  static const route = '/route';

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
        }
      };
}
