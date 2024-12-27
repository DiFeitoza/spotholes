import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as fpp;
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../config/environment_config.dart';
import '../models/spothole.dart';
import '../package/custom_info_window.dart';
import '../services/location_service.dart';
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
  final databaseReference = getIt<DatabaseReference>();
  late final dataBaseSpotholesRef = databaseReference.child('spotholes');

  final _googleMapControllerCompleter = Completer<GoogleMapController>();
  Future<GoogleMapController> get getGoogleMapController async =>
      await _googleMapControllerCompleter.future;

  final _customInfoWindowControllerSignal =
      Signal<CustomInfoWindowController>(CustomInfoWindowController());
  Signal<CustomInfoWindowController> get customInfoWindowControllerSignal =>
      _customInfoWindowControllerSignal;

  late final _spotholeService = SpotholeService(
    _markersSignal,
    _customInfoWindowControllerSignal,
  );

  // Store all markers
  var _markersSignal = Signal<Map<String, Marker>>({});
  Signal<Map<String, Marker>> get markersSignal => _markersSignal;

  // Store all spotholes in route
  var _spotholesInRouteList = Signal<List<Spothole>>([]);
  Signal<List<Spothole>> get spotholesInRouteList => _spotholesInRouteList;

  // Store all polylines
  var _polylinesSignal = Signal<Map<String, Polyline>>({});
  Signal<Map<String, Polyline>> get polylinesSignal => _polylinesSignal;

  // Store all route polyline points
  var _routePolylineCoordinatesSignal = Signal<List<LatLng>>([]);
  Signal<List<LatLng>> get routePolylineCoordinatesSignal =>
      _routePolylineCoordinatesSignal;

  // Store a result from a request for a route on Google Directions API
  var _directionResult = Signal<DirectionsResult>(const DirectionsResult());
  Signal<DirectionsResult> get directionResult => _directionResult;

  // Common computed signal route variables
  late final _route = computed(() => _directionResult.value.routes![0]);
  Computed<DirectionsRoute> get route => _route;
  late final _leg = computed(() => _route.value.legs![0]);
  Computed<Leg> get leg => _leg;
  late final _startLocation = computed(() => _leg.value.startLocation);
  Computed<GeoCoord?> get startLocation => _startLocation;
  late final _endLocation = computed(() => _leg.value.endLocation);
  Computed<GeoCoord?> get endLocation => _endLocation;

  late final _startLocationLatLng =
      computed(() => geoCoordToLatLng(_startLocation.value!));
  Computed<LatLng> get startLocationLatLng => _startLocationLatLng;
  late final _endLocationLatLng =
      computed(() => geoCoordToLatLng(_endLocation.value!));

  // This variable cannot be computed because it needs to be reactive as a List
  var _routeStepsLatLng = Signal<List<Step>>([]);
  Signal<List<Step>> get routeStepsLatLng => _routeStepsLatLng;
  // This variable is just an independent copy of the routeStepsLatLng to mantain the original data
  var _auxRouteStepsLatLng = Signal<List<Step>>([]);

  // Store steps' start indexes inside a route polyline
  var _stepsIndexes = <int>[];
  List<int> get stepsIndexes => _stepsIndexes;

  final _showStepsPageSignal = signal(false);
  Signal<bool> get showStepsPageSignal => _showStepsPageSignal;

  final _pageViewTypeSignal = signal('');
  Signal<String> get pageViewTypeSignal => _pageViewTypeSignal;

  final _pageControllerSignal = Signal(PageController());
  Signal<PageController> get pageControllerSignal => _pageControllerSignal;

  final LocationService _locationService = LocationService.instance;
  late final _currentLocationSignal = _locationService.currentLocationSignal;

  static Function? _dispose;

  void listenCurrentLocation() async {
    _dispose = effect(() {
      if (_currentLocationSignal.value != null) {
        untracked(() {
          _locationService.loadCurrentLocationMark(
            markersSignal,
            customInfoWindowControllerSignal,
          );
        });
      }
    });
  }

  void onMapCreated(mapController) {
    _customInfoWindowControllerSignal.value.googleMapController = mapController;
    _googleMapControllerCompleter.complete(mapController);
    listenCurrentLocation();
  }

  GeoCoord latLngToGeoCoord(LatLng latLng) =>
      GeoCoord(latLng.latitude, latLng.longitude);

  String latLngToString(LatLng latLng) =>
      '${latLng.latitude},${latLng.longitude}';

  LatLng geoCoordToLatLng(GeoCoord geoCoord) =>
      LatLng(geoCoord.latitude, geoCoord.longitude);

  String geoCoordToString(GeoCoord geoCoord) =>
      '${geoCoord.latitude},${geoCoord.longitude}';

  void updateCameraGeoCoord(GeoCoord target, [zoom = defaultZoomMap]) async {
    final mapController = await getGoogleMapController;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: zoom,
          target: geoCoordToLatLng(target),
        ),
      ),
    );
  }

  void updateCameraLatLng(LatLng target, [zoom = defaultZoomMap]) async {
    final mapController = await getGoogleMapController;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: zoom,
          target: target,
        ),
      ),
    );
  }

  void centerViewRoute() {
    // TODO criar snackbar ou desativar o botão quando houver menos de 2 pontos na polyline da rota
    if (_routePolylineCoordinatesSignal.value.length > 1) {
      newCameraLatLngBounds(_routePolylineCoordinatesSignal.value);
    }
  }

  void newCameraLatLngBoundsFromStep(Step currentStep) {
    final startLocationStepLatLng =
        geoCoordToLatLng(currentStep.startLocation!);
    final endLocationStepLatLng = geoCoordToLatLng(currentStep.endLocation!);
    newCameraLatLngBounds([startLocationStepLatLng, endLocationStepLatLng]);
  }

  void newCameraLatLngBounds(List<LatLng> polylineCoordinates) async {
    final mapController = await getGoogleMapController;
    mapController.animateCamera(
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
    for (var currentStep in steps) {
      var polyline = currentStep.polyline!.points;
      stepPoints = decodePolyline(polyline!);
      routePoints.addAll(stepPoints);
      stepsIndexes.add(currentIndex);
      currentIndex += stepPoints.length;
    }
    return RoutePointsData(routePoints, stepsIndexes);
  }

  void recalculateRoute(LatLng currentLocation) {
    LatLng destination = _routePolylineCoordinatesSignal.value.last;
    _markersSignal.value.clear();
    clearManeuverPolyline();
    loadRouteWithLegsAndSteps(currentLocation, destination);
  }

  Future<void> loadRouteWithLegsAndSteps(
      LatLng sourceLocation, LatLng destinationLocation) async {
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
      (DirectionsResult response, DirectionsStatus? status) {
        if (status == DirectionsStatus.ok) {
          _directionResult.value = response;
          _routeStepsLatLng.value = response.routes!.first.legs!.first.steps!;
          _auxRouteStepsLatLng.value = [..._routeStepsLatLng.value];
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
          centerViewRoute();
          _spotholeService.loadSpotholesInRoute(
              routePolylineCoordinatesSignal.value, _spotholesInRouteList);
        } else {
          // do something with error response
        }
      },
    );
  }

  void loadRouteMarkers(LatLng startLocation, LatLng endLocation) {
    Marker sourceRouteMarker = Marker(
      markerId: const MarkerId("sourceRoute"),
      icon: CustomIcons.sourceIcon,
      position: startLocation,
      onTap: () => _customInfoWindowControllerSignal.value.addInfoWindow!(
        const MarkerInfoWindow(
          title: 'Rota',
          textContent: 'Início da Rota',
        ),
        startLocation,
      ),
    );

    Marker destinationRouteMarker = Marker(
      markerId: const MarkerId("destinationRoute"),
      icon: CustomIcons.destinationIcon,
      position: endLocation,
      onTap: () => _customInfoWindowControllerSignal.value.addInfoWindow!(
        const MarkerInfoWindow(
          title: 'Rota',
          textContent: 'Destino da Rota',
        ),
        endLocation,
      ),
    );

    _markersSignal.value = {
      ..._markersSignal.value,
      'sourceRouteMarker': sourceRouteMarker,
      'destinationRouteMarker': destinationRouteMarker
    };
  }

  // Update context and controllers related to the markers
  void updateAllRouteMarkers() {
    listenCurrentLocation();
    loadRouteMarkers(_startLocationLatLng.value, _endLocationLatLng.value);
    _spotholeService.addSpotholeMarkers(spotholesInRouteList);
  }

  void setupStepsPageView(int initialPage, String type) {
    _pageControllerSignal.value = PageController(initialPage: initialPage);
    _showStepsPageSignal.value = true;
    _pageViewTypeSignal.value = type;
  }

  void plotManeuverPolyline(int stepIndex, {bool updateCamera = true}) {
    final steps = _routeStepsLatLng.value;
    final currentStep = steps[stepIndex];
    final maneuver = currentStep.maneuver ?? 'straight';
    List<LatLng> maneuverPoints = [];
    List<LatLng> arrowPoints = [];
    int? midpointIndex;

    final sourceLocation = markersSignal.value['sourceRouteMarker']!.position;

    maneuverPoints = decodePolyline(currentStep.polyline!.points!);

    if (maneuver == 'straight') {
      if (updateCamera) newCameraLatLngBoundsFromStep(currentStep);
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
      if (updateCamera) updateCameraGeoCoord(currentStep.startLocation!);
      final previousStepIndex =
          _auxRouteStepsLatLng.value.indexOf(currentStep) - 1;
      if (previousStepIndex == 0) {
        maneuverPoints = [sourceLocation, ...maneuverPoints];
        midpointIndex = 1;
      } else {
        final previousStep = _auxRouteStepsLatLng.value[previousStepIndex];
        final beforeManeuverPoints =
            decodePolyline(previousStep.polyline!.points!);
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

  void updateRoutePolyline() {
    // Modifica a polyline da rota
    polylinesSignal.value['route'] = Polyline(
      polylineId: const PolylineId("route"),
      points: _routePolylineCoordinatesSignal.value,
      width: 6,
      color: primaryColor,
      geodesic: true,
      jointType: JointType.round,
    );
    // Força o update das polylines da rota
    polylinesSignal.value = {...polylinesSignal.value};
  }

  void registerSpotholeModal(LatLng registerPosition) {
    _spotholeService.registerSpotholeModal(registerPosition);
  }

  RouteController getCopy() {
    var copy = RouteController();
    // Share the signals variables that need to be reactives between the RouteController instances
    copy._markersSignal = _markersSignal;
    copy._spotholesInRouteList = _spotholesInRouteList;
    copy._polylinesSignal = _polylinesSignal;
    copy._routePolylineCoordinatesSignal = _routePolylineCoordinatesSignal;
    copy._directionResult = _directionResult;
    copy._routeStepsLatLng = _routeStepsLatLng;
    copy._auxRouteStepsLatLng = _auxRouteStepsLatLng;
    copy._stepsIndexes = _stepsIndexes;
    // Removi todos os casos de valores que são inicializados nulo no RouteController
    // Principalmente controlladores, pois cada página precisa de um único por widget evitando erros por duplicidade.
    // copy._pageControllerSignal.value = PageController(initialPage: 1);
    // copy._googleMapController = null;
    // copy._customInfoWindowControllerSignal.value =
    //     _customInfoWindowControllerSignal.value;
    // copy._spotholeService = _spotholeService;
    // copy._showStepsPageSignal.value = _showStepsPageSignal.value;
    // copy._pageViewTypeSignal.value = _pageViewTypeSignal.value;
    return copy;
  }

  static dispose() {
    _dispose!();
  }
}
