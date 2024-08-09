import 'dart:async';

import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../config/environment_config.dart';
import '../utilities/constants.dart';
import '../utilities/custom_icons.dart';
import '../utilities/map_utils.dart';

class RouteController {
  RouteController._();
  static RouteController? _instance;
  static RouteController get instance => _instance ??= RouteController._();

  GoogleMapController? _googleMapController;
  Completer _googleMapControllerCompleter = Completer();

  final _markersSignal = Signal<Map<String, Marker>>({});
  final _routePolylineCoordinatesSignal = Signal<List<LatLng>>([]);
  final _directionResult = Signal<DirectionsResult>(const DirectionsResult());

  final _routeAndStepsListSignal = Signal<List<String>>([]);

  Signal<Map<String, Marker>> get markersSignal => _markersSignal;
  Signal<List<LatLng>> get routePolylineCoordinatesSignal =>
      _routePolylineCoordinatesSignal;
  Signal<List<String>> get routeAndStepsListSignal => _routeAndStepsListSignal;
  Signal<DirectionsResult> get directionResult => _directionResult;

  void onMapCreated(mapController) {
    _googleMapControllerCompleter.complete(mapController);
  }

  GeoCoord latLngToGeoCoord(LatLng latLng) =>
      GeoCoord(latLng.latitude, latLng.longitude);

  String latLngToString(LatLng latLng) =>
      '${latLng.latitude},${latLng.longitude}';

  LatLng geoCoordToLatLng(GeoCoord geoCoord) =>
      LatLng(geoCoord.latitude, geoCoord.longitude);

  String geoCoordToString(GeoCoord geoCoord) =>
      '${geoCoord.latitude},${geoCoord.longitude}';

  void updateCamera(GeoCoord target, [zoom = defaultZoomMap]) {
    _googleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: zoom,
          target: geoCoordToLatLng(target),
        ),
      ),
    );
  }

  void centerViewRoute() {
    newCameraLatLngBounds(_routePolylineCoordinatesSignal.value);
  }

  void newCameraLatLngBoundsFromStep(Step step) {
    final startLocationLatLng = geoCoordToLatLng(step.startLocation!);
    final endLocationLatLng = geoCoordToLatLng(step.endLocation!);
    newCameraLatLngBounds([startLocationLatLng, endLocationLatLng]);
  }

  void newCameraLatLngBounds(List<LatLng> polylineCoordinates) {
    _googleMapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        MapUtils.boundsFromLatLngList(polylineCoordinates),
        70,
      ),
    );
  }

  Future<void> loadRouteWithLegsAndSteps(
      LatLng sourceLocation, LatLng destinationLocation) async {
    DirectionsService.init(EnvironmentConfig.googleApiKey!);
    final directionsService = DirectionsService();

    List<String> strSteps = [];
    String strRoute = '';

    final request = DirectionsRequest(
      origin: latLngToString(sourceLocation),
      destination: latLngToString(destinationLocation),
      travelMode: TravelMode.driving,
      language: 'pt-BR',
      region: 'BR',
    );

    await directionsService.route(
      request,
      (DirectionsResult response, DirectionsStatus? status) async {
        if (status == DirectionsStatus.ok) {
          _directionResult.value = response;
          // do something with successful response
          LatLng northeastBound =
              geoCoordToLatLng(response.routes![0].bounds!.northeast);
          LatLng southwestBound =
              geoCoordToLatLng(response.routes![0].bounds!.southwest);

          //BOUNDS
          strRoute += 'northeastBound: ${latLngToString(northeastBound)}\n'
              'southwestBound: ${latLngToString(southwestBound)}\n';

          //SUMARY
          strRoute += 'summary: ${response.routes![0].summary}\n';

          //OVERVIEW PATH
          List<GeoCoord> overViewPath = response.routes![0].overviewPath!;

          strRoute += 'overviewPath: ';
          for (GeoCoord geoCoord in overViewPath) {
            strRoute += '${geoCoordToString(geoCoord)}, ';
          }
          strRoute += '\n';

          //WARNINGS
          final warnings = response.routes![0].warnings;
          strRoute += 'Warnings:';
          if (warnings != null) {
            for (String? warning in warnings) {
              strRoute += '${warning!}, ';
            }
          }
          strRoute += '\n';

          strSteps.add(strRoute);

          //STEPS
          List<Step> steps = response.routes![0].legs![0].steps!;
          for (Step step in steps) {
            strSteps.add('Distância: ${step.distance}\n'
                'Duração: ${step.duration!.text}\n'
                'Start Location: ${geoCoordToString(step.startLocation!)}\n'
                'End Location: ${geoCoordToString(step.endLocation!)}\n'
                'Instructions: ${step.instructions}\n'
                'Maneuver: ${step.maneuver}\n'
                'Transit: ${step.transit}\n'
                'Travel Mode: ${step.travelMode}\n');
          }

          //Update da string de ROTA e STEPS
          _routeAndStepsListSignal.value = strSteps;

          //Plot da ROTA e dos MARCADORES de ROTA
          if (overViewPath.isNotEmpty) {
            final newList =
                overViewPath.map((point) => geoCoordToLatLng(point)).toList();
            _routePolylineCoordinatesSignal.value = newList;
            loadRouteMarkers(_routePolylineCoordinatesSignal.value.first,
                _routePolylineCoordinatesSignal.value.last);
          }

          _googleMapController = await _googleMapControllerCompleter.future;
          centerViewRoute();

          // REGISTRA OS PONTOS DA POLYLINE PARA TESTE
          // Map<String, Marker> markers = {};
          // for (GeoCoord geoCoord in overViewPath) {
          //   markers[geoCoordToString(geoCoord)] = Marker(
          //     markerId: MarkerId(geoCoordToString(geoCoord)),
          //     position: geoCoordToLatLng(geoCoord),
          //   );
          // }

          // _markersSignal.value = {
          //   ..._markersSignal.value,
          //   ...markers,
          // };
        } else {
          // do something with error response
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

  dispose() {
    _markersSignal.value = {};
    _routePolylineCoordinatesSignal.value = [];
    _directionResult.value = const DirectionsResult();
    _routeAndStepsListSignal.value = [];
    _googleMapController = null;
    _googleMapControllerCompleter = Completer();
  }
}
