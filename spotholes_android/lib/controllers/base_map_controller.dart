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
  BaseMapController._();
  static BaseMapController _instance = BaseMapController._();
  static BaseMapController get instance => _instance;

  static void resetInstance() {
    _instance = BaseMapController._();
  }

  Function? _dispose;

  final LocationService _locationService = LocationService.instance;
  late final Signal<LocationData?> _currentLocationSignal =
      _locationService.currentLocationSignal;

  final databaseReference = getIt<DatabaseReference>();
  late final dataBaseSpotholesRef = databaseReference.child('spotholes');

  GoogleMapController? _googleMapController;
  final _googleMapControllerCompleter = Completer();
  final _customInfoWindowControllerSignal =
      Signal<CustomInfoWindowController>(CustomInfoWindowController());
  SpotholeService? spotholeService;
  final _textEditingController = TextEditingController();
  final _searchBarFocusNode = FocusNode();

  late Signal draggableScrollableSheetSignal = signal(
    DraggableScrollableSheetTypes.initial.widget,
  );

  final _geocodingService = GeocodingService.instance;

  final _markersSignal = Signal<Map<String, Marker>>({});

  get markersSignal => _markersSignal;
  get currentLocationSignal => _currentLocationSignal;
  get textEditingController => _textEditingController;
  get searchBarFocusNode => _searchBarFocusNode;
  get customInfoWindowControllerSignal => _customInfoWindowControllerSignal;
  get currentLocationLatLng => LatLng(_currentLocationSignal.value!.latitude!,
      _currentLocationSignal.value!.longitude!);

  void onMapCreated(mapController, context) {
    _googleMapControllerCompleter.complete(mapController);
    _customInfoWindowControllerSignal.value.googleMapController = mapController;
    spotholeService = SpotholeService(
      _markersSignal,
      _customInfoWindowControllerSignal,
    );
    spotholeService!.loadSpotholeMarkers(context);
  }

  void updateCameraGoogleMapsController(position, [zoom = defaultZoomMap]) {
    _googleMapController!.animateCamera(
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

  void loadCurrentLocation() async {
    _googleMapController = await _googleMapControllerCompleter.future;
    centerView();
    listenCurrentLocation();
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
      },
    );
  }

  changeDraggableSheet(DraggableScrollableSheetType type) {
    draggableScrollableSheetSignal.value = type.widget;
  }

  void closeDraggableSheet(String key) {
    _customInfoWindowControllerSignal.value.hideInfoWindow!();
    removeMarkerByKey(key);
    changeDraggableSheet(DraggableScrollableSheetTypes.initial);
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
                  'Latitude: ${placeLocation.lat!}\rLongitude: ${placeLocation.lng!}'),
          position),
    );
    updateCameraGoogleMapsController(position);
    changeDraggableSheet(DraggableScrollableSheetTypes.place(
        placeDetails: placeDetails, position: position));
  }

  void removeMarkerByKey(key) {
    markersSignal.value.remove(key);
  }

  void loadSpotholeMarkers(context) {
    spotholeService!.loadSpotholeMarkers(context);
  }

  void registerSpotholeModal(context, {LatLng? position}) {
    final latLng = position ?? currentLocationLatLng;
    spotholeService!.registerSpotholeModal(context, latLng);
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
                  'Não foi possível carregar informações, verifique a conexão com a internet');
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
          position),
    );
    changeDraggableSheet(
      DraggableScrollableSheetTypes.location(
        position: position,
        formattedPlacemark: formattedPlacemark,
        onRegister: () =>
            spotholeService!.registerSpotholeModal(context, position),
      ),
    );
  }

  dispose() {
    _dispose!();
  }
}
