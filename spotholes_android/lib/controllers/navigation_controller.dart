import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/services/navigation_service.dart';

import '../services/location_service.dart';
import '../utilities/constants.dart';
import 'route_controller.dart';

class NavigationController {
  final RouteController _routeController;
  NavigationController(this._routeController);

  final LocationService _locationService = LocationService.instance;
  late final Signal<LocationData?> _currentLocationSignal =
      _locationService.currentLocationSignal;

  static Function? _dispose;

  final _pageController = PageController(initialPage: 1);
  get pageController => _pageController;

  final isTrackingLocation = signal(true);
  final isProgrammaticMove = signal(true);
  final isPageViewMoveCamera = signal(true);

  late final _navigationService = NavigationService(_routeController,
      _pageController, isTrackingLocation, isPageViewMoveCamera);
  get navigationService => _navigationService;

  void goToCurrentStepPageView() {
    if (_pageController.page != 1) {
      isPageViewMoveCamera.value = false;
      _pageController.jumpToPage(1);
    }
  }

  void onTrackLocation() {
    // Alterna a ação entre rastrear e não rastrear
    if (isTrackingLocation.value) {
      isTrackingLocation.value = false;
    } else {
      isTrackingLocation.value = true;
      goToCurrentStepPageView();
      centerCurrentLocation();
    }
  }

  void onMapCreated(mapController) {
    mapController.setMapStyle(mapStyle2D);
    _routeController.onMapCreated(mapController);
    listenCurrentLocation();
    _routeController.updateAllRouteMarkers();
  }

  void listenCurrentLocation() async {
    _dispose = effect(
      () {
        if (_currentLocationSignal.value != null) {
          final LatLng currentLocation = _locationService.currentLocationLatLng;
          final double heading = _currentLocationSignal.value!.heading!;
          untracked(
            () {
              _navigationService.updateRouteStatus(currentLocation);
            },
          );
          if (isTrackingLocation.value) {
            _updateNavigationCamera(currentLocation, heading);
          }
        }
      },
    );
  }

  void _updateNavigationCamera(LatLng position, double heading) async {
    final CameraPosition newCameraPosition = CameraPosition(
      target: position,
      zoom: defaultZoomMap,
      bearing: heading,
      tilt: defaultNavigationTilt,
    );
    final mapController = await _routeController.getGoogleMapController;
    isProgrammaticMove.value = true;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
    );
  }

  void centerCurrentLocation() {
    isProgrammaticMove.value = true;
    _routeController.updateCameraLatLng(_locationService.currentLocationLatLng);
  }

  void registerSpotholeModal({LatLng? position}) {
    LatLng registerPosition =
        position ?? _locationService.currentLocationLatLng;
    _routeController.registerSpotholeModal(registerPosition);
  }

  // TODO Limitar o número de requisições por minuto para evitar uso indevido, talvez um debaunce
  void recalculateRoute() {
    _routeController.recalculateRoute(_locationService.currentLocationLatLng);
    _locationService.loadCurrentLocationMark(
      _routeController.markersSignal,
      _routeController.customInfoWindowControllerSignal,
    );
  }

  static dispose() {
    // _navigationService.dispose();
    _dispose!();
  }
}
