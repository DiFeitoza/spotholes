import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:signals/signals_flutter.dart';

import '../package/custom_info_window.dart';
import '../package/google_places_flutter/model/place_details.dart'
    hide Location;
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/service_locator.dart';
import '../services/spothole_service.dart';
import '../utilities/constants.dart';
import '../utilities/custom_snackbar.dart';
import '../widgets/draggable_scrollable_sheet/draggable_scrollable_sheet_type.dart';
import '../widgets/info_window/marker_info_window.dart';

class BaseMapController {
  Function? _dispose;

  final LocationService _locationService = LocationService.instance;

  late final _currentLocationSignal = _locationService.currentLocationSignal;
  Signal<LocationData?> get currentLocationSignal => _currentLocationSignal;

  LatLng get currentLocationLatLng => LatLng(
      _currentLocationSignal.value!.latitude!,
      _currentLocationSignal.value!.longitude!);

  final databaseReference = getIt<DatabaseReference>();
  late final dataBaseSpotholesRef = databaseReference.child('spotholes');

  final _googleMapControllerCompleter = Completer<GoogleMapController>();
  Future<GoogleMapController> get getGoogleMapController async =>
      await _googleMapControllerCompleter.future;

  final _customInfoWindowControllerSignal =
      Signal<CustomInfoWindowController>(CustomInfoWindowController());
  Signal<CustomInfoWindowController> get customInfoWindowControllerSignal =>
      _customInfoWindowControllerSignal;

  final _markersSignal = Signal<Map<String, Marker>>({});
  Signal<Map<String, Marker>> get markersSignal => _markersSignal;

  late final _spotholeService = SpotholeService(
    _markersSignal,
    _customInfoWindowControllerSignal,
  );

  final _textEditingController = TextEditingController();
  TextEditingController get textEditingController => _textEditingController;

  final _searchBarFocusNode = FocusNode();
  FocusNode get searchBarFocusNode => _searchBarFocusNode;

  late final _draggableScrollableSheetTypes =
      DraggableScrollableSheetTypes(baseMapController: this);

  late final _draggableScrollableSheetSignal = signal(
    _draggableScrollableSheetTypes.initial.widget,
  );
  Signal<Widget> get draggableScrollableSheetSignal =>
      _draggableScrollableSheetSignal;

  final _geocodingService = GeocodingService.instance;
  final isTrackingLocation = signal(true);
  final isProgrammaticMove = signal(true);

  void onMapCreated(mapController) {
    _customInfoWindowControllerSignal.value.googleMapController = mapController;
    _googleMapControllerCompleter.complete(mapController);
    listenCurrentLocation();
    _spotholeService.loadSpotholeMarkers();
  }

  void trackLocation() {
    if (isTrackingLocation.value) {
      isTrackingLocation.value = false;
    } else {
      isTrackingLocation.value = true;
      centerView();
    }
  }

  void updateCameraGoogleMapsController(position,
      [zoom = defaultZoomMap]) async {
    final mapController = await getGoogleMapController;
    isProgrammaticMove.value = true;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: zoom,
          target: position,
        ),
      ),
    );
  }

  void centerView() {
    updateCameraGoogleMapsController(currentLocationLatLng);
  }

  void listenCurrentLocation() async {
    _dispose = effect(
      () {
        if (_currentLocationSignal.value != null) {
          untracked(
            () => _locationService.loadCurrentLocationMark(
              _markersSignal,
              _customInfoWindowControllerSignal,
            ),
          );
        }
        if (isTrackingLocation.value) {
          centerView();
        }
      },
    );
  }

  changeDraggableSheet(DraggableScrollableSheetType type) {
    draggableScrollableSheetSignal.value = type.widget;
  }

  void closeDraggableSheet(String key) {
    _customInfoWindowControllerSignal.value.hideInfoWindow!();
    removeMarkerByKey(key);
    changeDraggableSheet(_draggableScrollableSheetTypes.initial);
    isTrackingLocation.value = true;
    centerView();
  }

  void loadPlaceLocation(context, PlaceDetails placeDetails) {
    final placeLocation = placeDetails.result!.geometry!.location!;
    final position = LatLng(placeLocation.lat!, placeLocation.lng!);
    _markersSignal.value['selectedPlace'] = Marker(
      markerId: MarkerId(position.toString()),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      position: position,
      onTap: () => _customInfoWindowControllerSignal.value.addInfoWindow!(
        MarkerInfoWindow(
          title: 'Resultado da Busca',
          textContent: placeDetails.result!.name ??
              'Latitude: ${placeLocation.lat!}\rLongitude: ${placeLocation.lng!}',
        ),
        position,
      ),
    );
    updateCameraGoogleMapsController(position);
    changeDraggableSheet(DraggableScrollableSheetTypes.place(
      placeDetails: placeDetails,
      position: position,
      baseMapController: this,
    ));
  }

  void removeMarkerByKey(key) {
    markersSignal.value.remove(key);
  }

  void loadSpotholeMarkers() {
    _spotholeService.loadSpotholeMarkers();
  }

  void registerSpotholeModal({LatLng? position}) {
    final registerPosition = position ?? currentLocationLatLng;
    _spotholeService.registerSpotholeModal(registerPosition);
  }

  void onLongPress(BuildContext context, LatLng position) async {
    String windowInfo =
        'Latitude: ${position.latitude}\rLongitude: ${position.longitude}';
    String formattedPlacemark = '';
    _customInfoWindowControllerSignal.value.hideInfoWindow!();
    updateCameraGoogleMapsController(position);
    try {
      windowInfo = await _geocodingService
          .getFirstPlacemarkFormattedFromLatLng(position);
      formattedPlacemark = 'Próximo de $windowInfo';
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          CustomSnackbar.show(
            context: context,
            message:
                'Não foi possível carregar informações, verifique a conexão com a internet',
          );
        },
      );
    }
    _markersSignal.value['longPressed'] = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      onTap: () => _customInfoWindowControllerSignal.value.addInfoWindow!(
        MarkerInfoWindow(
          title: 'Local Aproximado',
          textContent: windowInfo,
        ),
        position,
      ),
    );
    changeDraggableSheet(
      DraggableScrollableSheetTypes.location(
        position: position,
        formattedPlacemark: formattedPlacemark,
        baseMapController: this,
      ),
    );
  }

  dispose() {
    _dispose!();
  }
}
