import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as fpp;
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../config/environment_config.dart';
import '../controllers/spothole_info_window_controller.dart';
import '../models/spothole.dart';
import '../package/custom_info_window.dart';
import '../services/service_locator.dart';
import '../utilities/constants.dart';
import '../utilities/custom_icons.dart';
import '../utilities/maneuver_arrow_polyline.dart';
import '../utilities/map_utils.dart';
import '../utilities/point_on_route_haversine.dart';
import '../widgets/info_window/marker_info_window.dart';

class RouteController {
  RouteController._();
  static RouteController? _instance;
  static RouteController get instance => _instance ??= RouteController._();

  static void resetInstance() {
    _instance = null;
  }

  final databaseReference = getIt<DatabaseReference>();
  late final dataBaseSpotholesRef = databaseReference.child('spotholes');
  final _spotholesInRouteList = Signal<List<Spothole>>([]);

  GoogleMapController? _googleMapController;
  final _googleMapControllerCompleter = Completer();

  final _customInfoWindowControllerSignal =
      Signal<CustomInfoWindowController>(CustomInfoWindowController());
  get customInfoWindowControllerSignal => _customInfoWindowControllerSignal;

  SpotholeInfoWindowController? spotholeInfoWindowController;

  final _markersSignal = Signal<Map<String, Marker>>({});
  final _routePolylineCoordinatesSignal = Signal<List<LatLng>>([]);
  final _polylinesSignal = Signal<Map<String, Polyline>>({});
  final _routePolyline =
      Signal<Polyline>(const Polyline(polylineId: PolylineId('null')));
  final _directionResult = Signal<DirectionsResult>(const DirectionsResult());

  final _routeAndStepsListSignal = Signal<List<String>>([]);

  Signal<List<Spothole>> get spotholesInRouteList => _spotholesInRouteList;
  Signal<Map<String, Marker>> get markersSignal => _markersSignal;
  Signal<List<LatLng>> get routePolylineCoordinatesSignal =>
      _routePolylineCoordinatesSignal;
  Signal<Map<String, Polyline>> get polylinesSignal => _polylinesSignal;
  Signal<Polyline> get routePolyline => _routePolyline;
  Signal<List<String>> get routeAndStepsListSignal => _routeAndStepsListSignal;
  Signal<DirectionsResult> get directionResult => _directionResult;

  final _showStepsPageSignal = signal(false);
  get showStepsPageSignal => _showStepsPageSignal;

  final _pageViewTypeSignal = signal('');
  get pageViewTypeSignal => _pageViewTypeSignal;

  final _pageControllerSignal = Signal(PageController());
  get pageControllerSignal => _pageControllerSignal;

  void onMapCreated(mapController) {
    _googleMapControllerCompleter.complete(mapController);
    _customInfoWindowControllerSignal.value.googleMapController = mapController;
    spotholeInfoWindowController = SpotholeInfoWindowController(
        _customInfoWindowControllerSignal, _markersSignal);
  }

  GeoCoord latLngToGeoCoord(LatLng latLng) =>
      GeoCoord(latLng.latitude, latLng.longitude);

  String latLngToString(LatLng latLng) =>
      '${latLng.latitude},${latLng.longitude}';

  LatLng geoCoordToLatLng(GeoCoord geoCoord) =>
      LatLng(geoCoord.latitude, geoCoord.longitude);

  String geoCoordToString(GeoCoord geoCoord) =>
      '${geoCoord.latitude},${geoCoord.longitude}';

  void updateCameraGeoCoord(GeoCoord target, [zoom = defaultZoomMap]) {
    _googleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: zoom,
          target: geoCoordToLatLng(target),
        ),
      ),
    );
  }

  void updateCameraLatLng(LatLng target, [zoom = defaultZoomMap]) {
    _googleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: zoom,
          target: target,
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

  // TODO just for dev tests!
  List<String> routeToString(DirectionsResult response) {
    List<String> strSteps = [];
    String strRoute = '';
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
    List<GeoCoord> points = response.routes![0].overviewPath!;
    strRoute += 'overviewPath: ';
    for (GeoCoord geoCoord in points) {
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
    return strSteps;
  }

  // TODO just for dev tests!
  void showOverViewPathPoints(List<LatLng> points) {
    Map<String, Marker> markers = {};
    for (LatLng point in points) {
      String strPoint = latLngToString(point);
      markers[strPoint] = Marker(
        markerId: MarkerId(strPoint),
        position: point,
      );
    }
    _markersSignal.value = {
      ..._markersSignal.value,
      ...markers,
    };
  }

  List<LatLng> decodePolyline(String encoded) {
    return fpp.PolylinePoints()
        .decodePolyline(encoded)
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  List<LatLng> extractPointsFromSteps(List<Step> steps) {
    List<LatLng> routePoints = [];
    for (var step in steps) {
      var polyline = step.polyline!.points;
      routePoints.addAll(decodePolyline(polyline!));
    }
    return routePoints;
  }

  Future<void> loadRouteWithLegsAndSteps(
      LatLng sourceLocation, LatLng destinationLocation, context) async {
    DirectionsService.init(EnvironmentConfig.googleApiKey!);
    final directionsService = DirectionsService();

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
          final steps = response.routes!.first.legs!.first.steps;
          final points = extractPointsFromSteps(steps!);
          _routePolylineCoordinatesSignal.value = points;
          _polylinesSignal.value['route'] = Polyline(
            polylineId: const PolylineId("route"),
            points: _routePolylineCoordinatesSignal.value,
            width: 6,
            color: primaryColor,
            geodesic: true,
            jointType: JointType.round,
          );
          loadRouteMarkers(_routePolylineCoordinatesSignal.value.first,
              _routePolylineCoordinatesSignal.value.last);
          _googleMapController = await _googleMapControllerCompleter.future;
          centerViewRoute();
          loadSpotholesInRoute(context);
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
      onTap: () => _customInfoWindowControllerSignal.value.addInfoWindow!(
          const MarkerInfoWindow(
            title: 'Rota',
            textContent: 'Início da Rota',
          ),
          sourceLocation),
    );

    Marker destinationRouteMarker = Marker(
      markerId: const MarkerId("destinationRoute"),
      icon: CustomIcons.destinationIcon,
      position: destinationLocation,
      onTap: () => _customInfoWindowControllerSignal.value.addInfoWindow!(
          const MarkerInfoWindow(
            title: 'Rota',
            textContent: 'Destino da Rota',
          ),
          destinationLocation),
    );

    _markersSignal.value = {
      ..._markersSignal.value,
      'sourceRouteMarker': sourceRouteMarker,
      'destinationRouteMarker': destinationRouteMarker
    };
  }

  void loadSpotholesInRoute(context) {
    _spotholesInRouteList.value = [];
    databaseReference.child('spotholes').once().then(
      (DatabaseEvent event) {
        final spotholesMap = event.snapshot.value as Map?;
        if (spotholesMap != null) {
          final spotholeList = spotholesMap.entries.map((entry) {
            final spothole = Spothole.fromJson(
                Map<String, dynamic>.from(entry.value as Map));
            spothole.id = entry.key;
            return spothole;
          }).toList();

          _spotholesInRouteList.value = checkPointsAndStoreAccumulatedDistances(
              spotholeList, _routePolylineCoordinatesSignal.value);

          for (Spothole spothole in _spotholesInRouteList.value) {
            spotholeInfoWindowController!.addSpotholeMarker(context, spothole);
          }

          _markersSignal.value = {
            ..._markersSignal.value,
          };
        }
      },
    );
  }

  void setupStepsPageView(int initialPage, String type) {
    _pageControllerSignal.value = PageController(initialPage: initialPage);
    _showStepsPageSignal.value = true;
    _pageViewTypeSignal.value = type;
  }

  void plotManeuver(int stepIndex) {
    final steps = _directionResult.value.routes![0].legs![0].steps;
    final step = steps![stepIndex];
    final maneuver = step.maneuver ?? 'straight';
    List<LatLng> maneuverPoints = [];
    List<LatLng> arrowPoints = [];
    int? midpointIndex;

    final sourceLocation = markersSignal.value['sourceRouteMarker']!.position;

    maneuverPoints = decodePolyline(step.polyline!.points!);

    if (maneuver == 'straight') {
      newCameraLatLngBoundsFromStep(step);
      polylinesSignal.value.addAll({
        'straightPath': Polyline(
          polylineId: const PolylineId('straightPath'),
          points: maneuverPoints,
          geodesic: true,
          width: 3,
          color: Colors.red.shade100,
          jointType: JointType.round,
          zIndex: 1,
        )
      });
    } else {
      updateCameraGeoCoord(step.startLocation!);
      if (stepIndex == 0) {
        maneuverPoints = [sourceLocation, ...maneuverPoints];
        midpointIndex = 1;
      } else {
        final beforeManeuverPoints =
            decodePolyline(steps[stepIndex - 1].polyline!.points!);
        midpointIndex = beforeManeuverPoints.length;
        maneuverPoints.insertAll(0, beforeManeuverPoints);
      }
    }

    arrowPoints = getSegmentAroundMidpoint(
      maneuverPoints,
      20,
      20,
      midpointIndex: midpointIndex,
    );

    polylinesSignal.value.addAll({
      'maneuverArrow': Polyline(
        polylineId: const PolylineId('maneuverArrow'),
        points: arrowPoints,
        geodesic: true,
        width: 8,
        color: Colors.red,
        jointType: JointType.round,
        endCap: Cap.customCapFromBitmap(CustomIcons.redHeadManeuverArrow),
        zIndex: 2,
      )
    });

    polylinesSignal.value = {...polylinesSignal.value};
  }
}
