import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:signals/signals_flutter.dart';

import '../utilities/custom_icons.dart';
import '../widgets/info_window/marker_info_window.dart';

class LocationServiceMock {
  LocationServiceMock._({this.simulationInterval = 2}) {
    // _startMockLocationMonitoring();
  }

  static LocationServiceMock create({int simulationInterval = 2}) =>
      LocationServiceMock._(simulationInterval: simulationInterval);

  // final List<Map<String, double>> _simulatedPoints;

  /// List of points for simulation (around home)
  List<Map<String, double>> simulatedPoints = [
    {"lat": -4.970759417, "lon": -39.018417578},
    {"lat": -4.970149456, "lon": -39.018437396},
    {"lat": -4.970161685, "lon": -39.019398226},
    {"lat": -4.970174385, "lon": -39.020446581},
    {"lat": -4.970180457, "lon": -39.021795791},
    {"lat": -4.969608889, "lon": -39.021805958},
    {"lat": -4.969126117, "lon": -39.021809682},
    {"lat": -4.968599344, "lon": -39.021816028},
    {"lat": -4.968595255, "lon": -39.021114206},
    {"lat": -4.968580179, "lon": -39.020130772},
    {"lat": -4.968564485, "lon": -39.019058312},
    {"lat": -4.968611291, "lon": -39.018002439},
    {"lat": -4.968595552, "lon": -39.016842749},
    {"lat": -4.968579119, "lon": -39.015583046},
    {"lat": -4.968582717, "lon": -39.014573231},
    {"lat": -4.968558842, "lon": -39.013127272},
    {"lat": -4.968514769, "lon": -39.011763115},
    {"lat": -4.968506611, "lon": -39.010432066},
    {"lat": -4.968486545, "lon": -39.009220177},
    {"lat": -4.96774864, "lon": -39.009247243},
    {"lat": -4.967359017, "lon": -39.009227059},
    {"lat": -4.967086967, "lon": -39.009124385},
    {"lat": -4.966844242, "lon": -39.008627418},
    {"lat": -4.966557347, "lon": -39.007373746},
    {"lat": -4.966318344, "lon": -39.00619485},
    {"lat": -4.96597276, "lon": -39.004459807},
    {"lat": -4.965631465, "lon": -39.002866202},
  ];


  final int simulationInterval; // Intervalo em segundos entre as atualizações
  final Signal<LocationData?> _currentLocationSignal = Signal<LocationData?>(null);
  Timer? _simulationTimer;

  Signal<LocationData?> get currentLocationSignal => _currentLocationSignal;

  LatLng get currentLocationLatLng => LatLng(
        _currentLocationSignal.value!.latitude!,
        _currentLocationSignal.value!.longitude!,
      );

  String currentLocationLatLngURLPattern() =>
      "${_currentLocationSignal.value!.latitude!.toString()}"
      "%2C${_currentLocationSignal.value!.longitude!.toString()}";

  void loadCurrentLocationMark(
      Signal<Map<String, Marker>> markersSignal, final customInfoWindowControllerSignal) {
    final newMarker = Marker(
      markerId: const MarkerId("currentLocationMarker"),
      icon: CustomIcons.currentLocationIcon,
      position: currentLocationLatLng,
      onTap: () => customInfoWindowControllerSignal.value.addInfoWindow!(
        const MarkerInfoWindow(
          title: 'Localização',
          textContent: 'Você está aqui!',
        ),
        currentLocationLatLng,
      ),
    );
    markersSignal.value = {
      ...markersSignal.value,
      'currentLocationMarker': newMarker,
    };
  }

  void startMockLocationMonitoring() {
    int currentIndex = 0;
    _simulationTimer = Timer.periodic(
      Duration(seconds: simulationInterval),
      (timer) {
        if (currentIndex < simulatedPoints.length) {
          final point = simulatedPoints[currentIndex];
          _currentLocationSignal.value = LocationData.fromMap({
            'latitude': point['lat'],
            'longitude': point['lon'],
            'accuracy': 5.0,
            'time': DateTime.now().millisecondsSinceEpoch,
          });
          currentIndex++;
        } else {
          stopMockLocationMonitoring();
        }
      },
    );
  }

  void stopMockLocationMonitoring() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void dispose() {
    stopMockLocationMonitoring();
  }
}
