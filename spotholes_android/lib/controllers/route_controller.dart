import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../config/environment_config.dart';
import '../utilities/custom_icons.dart';

class RouteController {
  RouteController._();
  static RouteController? _instance;
  static RouteController get instance => _instance ??= RouteController._();

  final _markersSignal = Signal<Map<String, Marker>>({});
  final _routePolylineCoordinatesSignal = Signal<List<LatLng>>([]);
  final _polylineResponseSignal = Signal<PolylineResult>(PolylineResult());

  Signal<Map<String, Marker>> get markersSignal => _markersSignal;
  Signal<List<LatLng>> get routePolylineCoordinatesSignal =>
      _routePolylineCoordinatesSignal;
  Signal<PolylineResult> get polylineResponseSignal => _polylineResponseSignal;

  Future loadRoute(sourceLocation, destinationLocation) async {
    final polylinePoints = PolylinePoints();

    await polylinePoints
        .getRouteBetweenCoordinates(
            EnvironmentConfig.googleApiKey!,
            PointLatLng(sourceLocation!.latitude!, sourceLocation!.longitude!),
            PointLatLng(destinationLocation!.latitude!,
                destinationLocation!.longitude!),
            travelMode: TravelMode.bicycling)
        .then(
      (response) {
        if (response.points.isNotEmpty) {
          _polylineResponseSignal.value = response;
          final newList = response.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
          _routePolylineCoordinatesSignal.value = newList;
          loadRouteMarkers(_routePolylineCoordinatesSignal.value.first,
              _routePolylineCoordinatesSignal.value.last);
        }
      },
    );
  }

  void loadRouteMarkers(sourceLocation, destinationLocation) {
    Marker sourceRouteMarker = Marker(
      markerId: const MarkerId("sourceRoute"),
      icon: CustomIcons.sourceIcon,
      position: sourceLocation,
    );

    Marker destinationRouteMarker = Marker(
      markerId: const MarkerId("destinationRoute"),
      icon: CustomIcons.destinationIcon,
      position: destinationLocation,
    );

    _markersSignal.value = {
      ..._markersSignal.value,
      'sourceRouteMarker': sourceRouteMarker,
      'destinationRouteMarker': destinationRouteMarker
    };
  }
}
