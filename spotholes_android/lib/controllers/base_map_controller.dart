import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:signals/signals_flutter.dart';

import '../models/spothole.dart';
import '../package/custom_info_window.dart';
import '../package/google_places_flutter/model/place_details.dart'
    hide Location;
import '../services/geocoding_service.dart';
import '../services/service_locator.dart';
import '../utilities/constants.dart';
import '../utilities/custom_icons.dart';
import '../utilities/custom_snackbar.dart';
import '../widgets/draggable_scrollable_sheet/draggable_scrollable_sheet_type.dart';
import '../widgets/info_window/marker_info_window.dart';
import '../widgets/modal/register_spothole_modal.dart';
import 'spothole_info_window_controller.dart';

class BaseMapController {
  BaseMapController._();
  static final BaseMapController _instance = BaseMapController._();
  static BaseMapController get instance => _instance;

  final databaseReference = getIt<DatabaseReference>();
  late final dataBaseSpotholesRef = databaseReference.child('spotholes');

  GoogleMapController? _googleMapController;
  final _googleMapControllerCompleter = Completer();
  final _customInfoWindowControllerSignal =
      Signal<CustomInfoWindowController>(CustomInfoWindowController());
  SpotholeInfoWindowController? spotholeInfoWindowController;
  final _textEditingController = TextEditingController();
  final _searchBarFocusNode = FocusNode();

  late Signal draggableScrollableSheetSignal = signal(
    DraggableScrollableSheetTypes.initial.widget,
  );

  final _geocodingService = GeocodingService.instance;

  final _location = Location();

  final _markersSignal = Signal<Map<String, Marker>>({});
  final _currentLocationSignal = Signal<LocationData?>(null);

  get markersSignal => _markersSignal;
  get currentLocationSignal => _currentLocationSignal;
  get textEditingController => _textEditingController;
  get searchBarFocusNode => _searchBarFocusNode;
  get customInfoWindowControllerSignal => _customInfoWindowControllerSignal;
  get currentLocationLatLng => LatLng(_currentLocationSignal.value!.latitude!,
      _currentLocationSignal.value!.longitude!);

  String currentLocationLatLngURLPattern() =>
      "${_currentLocationSignal.value!.latitude!.toString()}"
      "%2C${_currentLocationSignal.value!.longitude!.toString()}";

  void onMapCreated(mapController, context) {
    _googleMapControllerCompleter.complete(mapController);
    _customInfoWindowControllerSignal.value.googleMapController = mapController;
    spotholeInfoWindowController = SpotholeInfoWindowController(
        _customInfoWindowControllerSignal, _markersSignal);
    loadSpotholeMarkers(context);
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
    _currentLocationSignal.value = await _location.getLocation();
    loadCurrentLocationMark();
    _location.onLocationChanged.listen((newLoc) {
      _currentLocationSignal.value = newLoc;
      loadCurrentLocationMark();
    });
    _googleMapController = await _googleMapControllerCompleter.future;
    centerView();
  }

  void loadCurrentLocationMark() {
    final newMarker = Marker(
      markerId: const MarkerId("currentLocation"),
      icon: CustomIcons.currentLocationIcon,
      position: currentLocationLatLng,
      onTap: () => _customInfoWindowControllerSignal.value.addInfoWindow!(
          const MarkerInfoWindow(
              title: 'Localização', textContent: 'Você está aqui!'),
          currentLocationLatLng),
    );
    _markersSignal.value['currentLocationMarker'] = newMarker;
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
    databaseReference.child('spotholes').once().then(
      (DatabaseEvent event) {
        final spotholesMap = event.snapshot.value as Map?;
        if (spotholesMap != null) {
          spotholesMap.forEach(
            (key, value) {
              final spothole =
                  Spothole.fromJson(Map<String, dynamic>.from(value as Map));
              spothole.id = key;
              spotholeInfoWindowController!
                  .addSpotholeMarker(context, spothole);
            },
          );
        }
      },
    );
  }

  void registerSpothole(context, position, category, type) {
    final newSpotHoleRef = dataBaseSpotholesRef.push();
    final newSpothole = Spothole(DateTime.now().toUtc(), DateTime.now().toUtc(),
        position, category, type, null, newSpotHoleRef.key);
    newSpotHoleRef.set(newSpothole.toJson());
    spotholeInfoWindowController!.addSpotholeMarker(context, newSpothole);
  }

  void registerSpotholeModal(context, {LatLng? position}) {
    final latLng = position ?? currentLocationLatLng;
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return RegisterSpotholeModal(
          title: "Para alertar um risco, selecione:",
          textOnRegisterButton: "Adicionar",
          onRegister: (riskCategory, type) =>
              registerSpothole(context, latLng, riskCategory, type),
        );
      },
    );
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
        onRegister: () => registerSpotholeModal(context, position: position),
      ),
    );
  }
}
