import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:signals/signals_flutter.dart';

import '../utilities/custom_icons.dart';
import '../widgets/info_window/marker_info_window.dart';

class LocationService {
  LocationService._() {
    _startLocationMonitoring();
  }

  static final LocationService _instance = LocationService._();
  static LocationService get instance => _instance;

  final _location = Location();

  final _currentLocationSignal = Signal<LocationData?>(null);
  get currentLocationSignal => _currentLocationSignal;
  get currentLocationLatLng => LatLng(_currentLocationSignal.value!.latitude!,
      _currentLocationSignal.value!.longitude!);

  String currentLocationLatLngURLPattern() =>
      "${_currentLocationSignal.value!.latitude!.toString()}"
      "%2C${_currentLocationSignal.value!.longitude!.toString()}";

  void loadCurrentLocationMark(Signal<Map<String, Marker>> markersSignal,
      final customInfoWindowControllerSignal) {
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

  void _startLocationMonitoring() async {
    _location.changeSettings(
      interval: 100,
      distanceFilter: 5,
    );
    _currentLocationSignal.value = await _location.getLocation();
    //TODO Implementar Snackbar alertando que o GPS está fora. Pode ser um signal que exibe o snackbar na tela com o ícone de GPS fora
    _location.onLocationChanged.listen(
      (newLoc) {
        _currentLocationSignal.value = newLoc;
      },
    );
  }
}
