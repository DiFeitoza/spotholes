import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:signals/signals_flutter.dart';

import '../config/environment_config.dart';
import '../models/spothole.dart';
import '../package/custom_info_window.dart';
import '../package/google_places_flutter/model/place_details.dart'
    hide Location;
import '../services/geocoding_service.dart';
import '../services/service_locator.dart';
import '../utilities/constants.dart';
import '../utilities/custom_icons.dart';
import '../utilities/custom_snackbar.dart';
import '../widgets/delete_spothole_alert_dialog.dart';
import '../widgets/draggable_scrollable_sheet/draggable_scrollable_sheet_type.dart';
import '../widgets/marker_info_window.dart';
import '../widgets/modal/register_spothole_modal.dart';
import '../widgets/spothole_info_window.dart';

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
  final _textEditingController = TextEditingController();
  final _searchBarFocusNode = FocusNode();

  late Signal draggableScrollableSheetSignal = signal(
    DraggableScrollableSheetTypes.initial.widget,
  );

  final _geocodingService = GeocodingService.instance;

  final _location = Location();

  final _markersSignal = Signal<Map<String, Marker>>({});
  final _currentLocationSignal = Signal<LocationData?>(null);
  final _routePolylineCoordinates = Signal<List<LatLng>>([]);

  get markersSignal => _markersSignal;
  get currentLocationSignal => _currentLocationSignal;
  get routePolylineCoordinates => _routePolylineCoordinates.value;
  get textEditingController => _textEditingController;
  get searchBarFocusNode => _searchBarFocusNode;
  get customInfoWindowControllerSignal => _customInfoWindowControllerSignal;
  get currentLocationLatLng => LatLng(_currentLocationSignal.value!.latitude!,
      _currentLocationSignal.value!.longitude!);

  String currentLocationLatLngURLPattern() =>
      "${_currentLocationSignal.value!.latitude!.toString()}"
      "%2C${_currentLocationSignal.value!.longitude!.toString()}";

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

  void loadCurrentLocation() async {
    _currentLocationSignal.value = await _location.getLocation();
    loadCurrentLocationMark();
    _location.onLocationChanged.listen((newLoc) {
      _currentLocationSignal.value = newLoc;
      loadCurrentLocationMark();
    });
    _googleMapController = await _googleMapControllerCompleter.future;
    updateCameraGoogleMapsController(currentLocationLatLng);
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

  void onMapCreated(mapController) {
    _googleMapControllerCompleter.complete(mapController);
    _customInfoWindowControllerSignal.value.googleMapController = mapController;
  }

  void centerView() {
    updateCameraGoogleMapsController(currentLocationLatLng);
  }

  changeDraggableSheet(DraggableScrollableSheetType type) {
    draggableScrollableSheetSignal.value = type.widget;
  }

  void loadPlaceLocation(context, PlaceDetails placeDetails) {
    final placeLocation = placeDetails.result!.geometry!.location!;
    final position = LatLng(placeLocation.lat!, placeLocation.lng!);

    _markersSignal.value['selectedPlace'] = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      onTap: () => _customInfoWindowControllerSignal.value.addInfoWindow!(
          MarkerInfoWindow(
              title: 'Resultado da Busca',
              textContent: placeDetails.result!.name),
          position),
    );
    updateCameraGoogleMapsController(position);
    changeDraggableSheet(DraggableScrollableSheetTypes.place(
        placeDetails: placeDetails, position: position));
  }

  void removeMarkerByKey(key) {
    markersSignal.value.remove(key);
  }

  void closeDraggableSheet(String key) {
    _customInfoWindowControllerSignal.value.hideInfoWindow!();
    removeMarkerByKey(key);
    changeDraggableSheet(DraggableScrollableSheetTypes.initial);
    centerView();
  }

  Future loadRoute(destinationLocation, {sourceLocation}) async {
    sourceLocation ??= currentLocationLatLng;
    final polylinePoints = PolylinePoints();

    await polylinePoints
        .getRouteBetweenCoordinates(
      EnvironmentConfig.googleApiKey!,
      PointLatLng(sourceLocation!.latitude!, sourceLocation!.longitude!),
      PointLatLng(
          destinationLocation!.latitude!, destinationLocation!.longitude!),
    )
        .then(
      (response) {
        if (response.points.isNotEmpty) {
          final newList = response.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
          _routePolylineCoordinates.value = newList;
          loadRouteMarkers(sourceLocation, destinationLocation);
        }
      },
    );
  }

  void loadRouteMarkers(sourceLocation, destinationLocation) {
    Marker sourceRouteMarker = Marker(
      markerId: const MarkerId("sourceRoute"),
      icon: CustomIcons.sourceIcon,
      position: sourceLocation,
    );

    Marker destinationRouteMarker = Marker(
      markerId: const MarkerId("destinationRoute"),
      icon: CustomIcons.destinationIcon,
      position: destinationLocation,
    );

    _markersSignal.value["sourceRouteMarker"] = sourceRouteMarker;
    _markersSignal.value['destinationRouteMarker'] = destinationRouteMarker;
  }

  void deleteSpothole(String spotholeId) {
    dataBaseSpotholesRef.child(spotholeId).remove();
    _customInfoWindowControllerSignal.value.hideInfoWindow!();
    removeMarkerByKey(spotholeId);
  }

  void showDeleteSpotholeAlertDialog(context, String spotholeId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return DeleteSpotholeAlertDialog(
          onConfirm: () {
            deleteSpothole(spotholeId);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void addSpotholeMarker(context, String key, Spothole spothole) {
    final marker = Marker(
      markerId: MarkerId(key),
      icon: CustomIcons.potholeSignIcon,
      position: spothole.position,
      onTap: () {
        _customInfoWindowControllerSignal.value.addInfoWindow!(
          SpotholeInfoWindow(
            editSpothole: () => editSpotholeModal(
                context, key, spothole.category, spothole.type),
            showDeleteSpotholeAlertDialog: () =>
                showDeleteSpotholeAlertDialog(context, key),
            spothole: spothole,
          ),
          spothole.position,
        );
      },
    );
    markersSignal.value[key] = marker;
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
              addSpotholeMarker(context, key, spothole);
            },
          );
        }
      },
    );
  }

  void registerSpothole(context, position, category, type) {
    final newSpothole = Spothole(DateTime.now().toUtc(), DateTime.now().toUtc(),
        position, category, type);
    final newSpotHoleRef = dataBaseSpotholesRef.push();
    newSpotHoleRef.set(newSpothole.toJson());
    addSpotholeMarker(context, newSpotHoleRef.key!, newSpothole);
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

  void editSpothole(context, key, riskCategory, type) async {
    final dateOfUpdate = DateTime.now().toUtc();
    final spotholeRef = databaseReference.ref.child('spotholes/$key');
    final event = await spotholeRef.once();
    final spotholeJson = Map<String, dynamic>.from(event.snapshot.value as Map);
    final spothole = Spothole.fromJson(spotholeJson);
    spothole.dateOfUpdate = dateOfUpdate;
    spothole.category = riskCategory;
    spothole.type = type;
    addSpotholeMarker(context, key, spothole);
    markersSignal.value[key].onTap!();
    final zoom = await _googleMapController!.getZoomLevel();
    updateCameraGoogleMapsController(spothole.position, zoom);
    spotholeRef.set(spothole.toJson());
  }

  void editSpotholeModal(context, key, riskCategory, riskType) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return RegisterSpotholeModal(
          title: "Para editar um risco, selecione:",
          textOnRegisterButton: "Editar",
          isCountdown: false,
          onRegister: (riskCategory, type) =>
              editSpothole(context, key, riskCategory, type),
          riskCategory: riskCategory,
          riskType: riskType,
        );
      },
    );
  }

  void onLongPress(BuildContext context, LatLng position) async {
    String windowInfo = 'Alfinete inserido';
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
