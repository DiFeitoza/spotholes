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

  GoogleMapController? _mapController;
  static Function? _dispose;

  final _pageController = PageController(initialPage: 1);
  get pageController => _pageController;

  late final _navigationService =
      NavigationService(_routeController, _pageController);
  get navigationService => _navigationService;

  /*Tentativa de Mock do serviço de localização
  final _locationService = LocationServiceMock.create();
  late final Signal<LocationData?> _currentLocationSignal =
      _locationService.currentLocationSignal;
  void startMockLocation(){
    _locationService.startMockLocationMonitoring();
  }
  void stopMockLocation(){
    _locationService.stopMockLocationMonitoring();
  } */

  void onMapCreated(mapController) {
    _mapController = mapController;
    _routeController.googleMapController = _mapController;
    _routeController.onMapCreated(_mapController);
    listenCurrentLocation();
    // _navigationService.startNavigation();
  }

  void listenCurrentLocation() async {
    _dispose = effect(
      () {
        if (_currentLocationSignal.value != null) {
          final LatLng currentLocation = _locationService.currentLocationLatLng;
          final double heading = _currentLocationSignal.value!.heading!;
          untracked(
            () {
              _locationService.loadCurrentLocationMark(
                _routeController.markersSignal,
                _routeController.customInfoWindowControllerSignal,
              );
              _navigationService.updateRouteStatus(currentLocation);
            },
          );
          _updateNavigationCamera(currentLocation, heading);
        }
      },
    );
  }

  void _updateNavigationCamera(LatLng position, double heading) {
    final CameraPosition newCameraPosition = CameraPosition(
      target: position,
      zoom: defaultZoomMap,
      bearing: heading,
      tilt: defaultNavigationTilt,
    );
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
    );
  }

  void centerCurrentLocation() {
    _routeController.updateCameraLatLng(_locationService.currentLocationLatLng);
  }

  static dispose() {
    // _navigationService.dispose();
    _dispose!();
  }
}
