import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as fpp;
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/package/extensions/directions_result_extension.dart';

import '../config/environment_config.dart';
import '../models/spothole.dart';
import '../package/custom_info_window.dart';
import '../services/service_locator.dart';
import '../services/spothole_service.dart';
import '../utilities/constants.dart';
import '../utilities/custom_icons.dart';
import '../utilities/maneuver_arrow_polyline.dart';
import '../utilities/map_utils.dart';
import '../widgets/info_window/marker_info_window.dart';

class RoutePointsData {
  List<LatLng> points;
  List<int> stepsIndexes;
  RoutePointsData(this.points, this.stepsIndexes);
}

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
  get googleMapController => _googleMapController;
  set googleMapController(mapController) =>
      _googleMapController = mapController;

  final _googleMapControllerCompleter = Completer();
  get googleMapControllerCompleter => _googleMapControllerCompleter;

  final _customInfoWindowControllerSignal =
      Signal<CustomInfoWindowController>(CustomInfoWindowController());
  get customInfoWindowControllerSignal => _customInfoWindowControllerSignal;

  SpotholeService? _spotholeService;

  final _markersSignal = Signal<Map<String, Marker>>({});
  // Store all polyline points
  final _routePolylineCoordinatesSignal = Signal<List<LatLng>>([]);
  // Store all polylines
  final _polylinesSignal = Signal<Map<String, Polyline>>({});
  // Store a result from a request for a route on Google Directions API
  final _directionResult = Signal<DirectionsResult>(const DirectionsResult());
  final Signal<List<Step>> _routeStepsLatLng = Signal<List<Step>>([]);
  Signal<List<Step>> get routeStepsLatLng => _routeStepsLatLng;

  // Store steps' start indexes inside a route polyline
  List<int> _stepsIndexes = [];
  get stepsIndexes => _stepsIndexes;

  Signal<List<Spothole>> get spotholesInRouteList => _spotholesInRouteList;
  Signal<Map<String, Marker>> get markersSignal => _markersSignal;
  Signal<List<LatLng>> get routePolylineCoordinatesSignal =>
      _routePolylineCoordinatesSignal;
  Signal<Map<String, Polyline>> get polylinesSignal => _polylinesSignal;
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
    _spotholeService =
        SpotholeService(_markersSignal, _customInfoWindowControllerSignal);
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

  List<LatLng> decodePolyline(String encoded) {
    return fpp.PolylinePoints()
        .decodePolyline(encoded)
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  RoutePointsData decodePointsFromSteps(List<Step> steps) {
    List<LatLng> routePoints = [];
    List<LatLng> stepPoints = [];
    List<int> stepsIndexes = [];
    int currentIndex = 0;
    for (var step in steps) {
      var polyline = step.polyline!.points;
      stepPoints = decodePolyline(polyline!);
      routePoints.addAll(stepPoints);
      stepsIndexes.add(currentIndex);
      currentIndex += stepPoints.length;
    }
    return RoutePointsData(routePoints, stepsIndexes);
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
          _routeStepsLatLng.value = response.routes!.first.legs!.first.steps!;
          final routePointsData =
              decodePointsFromSteps(_routeStepsLatLng.value);
          _routePolylineCoordinatesSignal.value = routePointsData.points;
          _stepsIndexes = routePointsData.stepsIndexes;
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
    _spotholesInRouteList.value = _spotholeService!
        .loadSpotholesInRoute(context, routePolylineCoordinatesSignal.value);
  }

  void setupStepsPageView(int initialPage, String type) {
    _pageControllerSignal.value = PageController(initialPage: initialPage);
    _showStepsPageSignal.value = true;
    _pageViewTypeSignal.value = type;
  }

  void plotManeuverPolyline(int stepIndex, {bool updateCamera = true}) {
    final steps = _routeStepsLatLng.value;
    final step = steps[stepIndex];
    final maneuver = step.maneuver ?? 'straight';
    List<LatLng> maneuverPoints = [];
    List<LatLng> arrowPoints = [];
    int? midpointIndex;

    final sourceLocation = markersSignal.value['sourceRouteMarker']!.position;

    maneuverPoints = decodePolyline(step.polyline!.points!);

    if (maneuver == 'straight') {
      if (updateCamera) newCameraLatLngBoundsFromStep(step);
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
      if (updateCamera) updateCameraGeoCoord(step.startLocation!);
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

  void clearManeuverPolyline() {
    polylinesSignal.value.remove('maneuverArrow');
    polylinesSignal.value.remove('straightPath');
    polylinesSignal.value = {...polylinesSignal.value};
  }

  RouteController isolatedCopy() {
    var copy = RouteController._();
    copy._spotholesInRouteList.value = List.from(_spotholesInRouteList.value);
    copy._markersSignal.value = Map.from(_markersSignal.value);
    copy._polylinesSignal.value = Map.from(_polylinesSignal.value);
    copy._routePolylineCoordinatesSignal.value =
        List.from(_routePolylineCoordinatesSignal.value);
    // Dica: Em tipos complexos, a nova instância do tipo pai, por si só não resolve pois as partes internas vão ser cópias por referência, a não ser que crie toda a estrutura interna até chegar nos objetos que precisa fazer a cópia por passagem, em vez de referência
    copy._directionResult.value = _directionResult.value.copyWith();
    copy._stepsIndexes = List.of(_stepsIndexes);
    copy._routeStepsLatLng.value = List.from(_routeStepsLatLng.value);
    copy._pageControllerSignal.value = PageController(initialPage: 1);
    // Removi todos os casos de valores que são inicializados nulo no RouteController, assim eles são reinicializados e não retorna erro por duplicidade, como no caso
    return copy;
  }

  RouteController copy() {
    var copy = RouteController._();
    copy._spotholesInRouteList.value = _spotholesInRouteList.value;
    copy._markersSignal.value = _markersSignal.value;
    copy._polylinesSignal.value = _polylinesSignal.value;
    copy._routePolylineCoordinatesSignal.value =
        _routePolylineCoordinatesSignal.value;
    copy._directionResult.value = _directionResult.value;
    copy._stepsIndexes = _stepsIndexes;
    copy._routeStepsLatLng.value = _routeStepsLatLng.value;
    // Removi todos os casos de valores que são inicializados nulo no RouteController, assim eles são reinicializados e não retorna erro por duplicidade, como no caso de widgets que precisam de controladores únicos
    // copy._pageControllerSignal.value = PageController(initialPage: 1);
    // copy._routeAndStepsListSignal.value =
    //     List.from(_routeAndStepsListSignal.value);
    // copy._googleMapController = null;
    // copy._customInfoWindowControllerSignal.value =
    //     _customInfoWindowControllerSignal.value;
    // copy._spotholeService = _spotholeService;
    // copy._showStepsPageSignal.value = _showStepsPageSignal.value;
    // copy._pageViewTypeSignal.value = _pageViewTypeSignal.value;
    // Torno null para não utilizar o msm controller em duas PageView diferentes
    return copy;
  }

  static RouteController getCopy() {
    return instance.copy();
  }

  // // TODO just for dev tests!
  // List<String> routeToString(DirectionsResult response) {
  //   List<String> strSteps = [];
  //   String strRoute = '';
  //   LatLng northeastBound =
  //       geoCoordToLatLng(response.routes![0].bounds!.northeast);
  //   LatLng southwestBound =
  //       geoCoordToLatLng(response.routes![0].bounds!.southwest);
  //   //BOUNDS
  //   strRoute += 'northeastBound: ${latLngToString(northeastBound)}\n'
  //       'southwestBound: ${latLngToString(southwestBound)}\n';
  //   //SUMARY
  //   strRoute += 'summary: ${response.routes![0].summary}\n';
  //   //OVERVIEW PATH
  //   List<GeoCoord> points = response.routes![0].overviewPath!;
  //   strRoute += 'overviewPath: ';
  //   for (GeoCoord geoCoord in points) {
  //     strRoute += '${geoCoordToString(geoCoord)}, ';
  //   }
  //   strRoute += '\n';
  //   //WARNINGS
  //   final warnings = response.routes![0].warnings;
  //   strRoute += 'Warnings:';
  //   if (warnings != null) {
  //     for (String? warning in warnings) {
  //       strRoute += '${warning!}, ';
  //     }
  //   }
  //   strRoute += '\n';
  //   strSteps.add(strRoute);
  //   //STEPS
  //   List<Step> steps = response.routes![0].legs![0].steps!;
  //   for (Step step in steps) {
  //     strSteps.add('Distância: ${step.distance}\n'
  //         'Duração: ${step.duration!.text}\n'
  //         'Start Location: ${geoCoordToString(step.startLocation!)}\n'
  //         'End Location: ${geoCoordToString(step.endLocation!)}\n'
  //         'Instructions: ${step.instructions}\n'
  //         'Maneuver: ${step.maneuver}\n'
  //         'Transit: ${step.transit}\n'
  //         'Travel Mode: ${step.travelMode}\n');
  //   }
  //   //Update da string de ROTA e STEPS
  //   _routeAndStepsListSignal.value = strSteps;
  //   return strSteps;
  // }

  // // TODO just for dev tests!
  // void showOverViewPathPoints(List<LatLng> points) {
  //   Map<String, Marker> markers = {};
  //   for (LatLng point in points) {
  //     String strPoint = latLngToString(point);
  //     markers[strPoint] = Marker(
  //       markerId: MarkerId(strPoint),
  //       position: point,
  //     );
  //   }
  //   _markersSignal.value = {
  //     ..._markersSignal.value,
  //     ...markers,
  //   };
  // }
}
