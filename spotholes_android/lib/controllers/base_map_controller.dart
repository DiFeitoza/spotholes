import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/widgets/spothole_info_window.dart';

import '../config/environment_config.dart';
import '../models/spothole.dart';
import '../package/custom_info_windows.dart';
import '../services/service_locator.dart';
import '../utilities/custom_icons.dart';
import '../widgets/delete_spothole_alert_dialog.dart';
import '../widgets/location_marker_modal.dart';
import '../widgets/register_spothole_modal.dart';

class BaseMapController {
  final databaseReference = getIt<DatabaseReference>();

  GoogleMapController? _googleMapController;
  final _googleMapControllerCompleter = Completer();
  final _customInfoWindowControllerSignal =
      Signal<CustomInfoWindowController>(CustomInfoWindowController());

  final _location = Location();

  final _markersSignal = Signal<Map<String, Marker>>({});
  final _currentLocationSignal = Signal<LocationData?>(null);
  final _routePolylineCoordinates = Signal<List<LatLng>>([]);

  get markersSignal => _markersSignal;
  get currentLocationSignal => _currentLocationSignal;
  get routePolylineCoordinates => _routePolylineCoordinates;
  get customInfoWindowControllerSignal => _customInfoWindowControllerSignal;
  get currentLocationLatLng => LatLng(_currentLocationSignal.value!.latitude!,
      _currentLocationSignal.value!.longitude!);

  Future loadCurrentLocation() async {
    _currentLocationSignal.value = await _location.getLocation();
    loadCurrentLocationMark(_currentLocationSignal.value);

    _location.onLocationChanged.listen((newLoc) {
      _currentLocationSignal.value = newLoc;
      loadCurrentLocationMark(newLoc);
    });

    _googleMapController = await _googleMapControllerCompleter.future;
    _googleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: 18.5,
          target: currentLocationLatLng,
        ),
      ),
    );
  }

  void loadCurrentLocationMark(newLoc) async {
    Marker newMarker = Marker(
      markerId: const MarkerId("currentLocation"),
      icon: CustomIcons.currentLocationIcon,
      position: currentLocationLatLng,
    );
    _markersSignal.value['currentLocationMarker'] = newMarker;
  }

  void onMapCreated(mapController) {
    _googleMapControllerCompleter.complete(mapController);
    _customInfoWindowControllerSignal.value.googleMapController = mapController;
  }

  Future centerView() async {
    await _googleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentLocationLatLng,
          zoom: 18.5,
        ),
      ),
    );
  }

  //ROUTE
  Future loadRoute(sourceLocation, destinationLocation) async {
    PolylinePoints polylinePoints = PolylinePoints();

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
          for (var point in response.points) {
            _routePolylineCoordinates.value.add(
              LatLng(point.latitude, point.longitude),
            );
          }
          loadRouteMarkers(sourceLocation, destinationLocation);
        }
        // TODO: adicionar a exceção caso não encontre uma rota!
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

  //SPOTHOLE MARKERS
  void editSpothole(String key) {}

  void deleteSpothole(String spotholeId) {
    final DatabaseReference databaseReference = GetIt.I<DatabaseReference>();
    DatabaseReference spotholeRef = databaseReference.child('spotholes');
    spotholeRef.child(spotholeId).remove();
    _customInfoWindowControllerSignal.value.hideInfoWindow!();
    markersSignal.value.remove(spotholeId);
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
            editSpothole: () => editSpothole(key),
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
    final DatabaseReference databaseReference = GetIt.I<DatabaseReference>();
    DatabaseReference spotholeRef = databaseReference.child('spotholes');
    Spothole newSpothole = Spothole(DateTime.now().toUtc(),
        DateTime.now().toUtc(), position, category, type);
    final newSpotHoleRef = spotholeRef.push();
    newSpotHoleRef.set(newSpothole.toJson());
    addSpotholeMarker(context, newSpotHoleRef.key!, newSpothole);
  }

  void registerSpotholeModal(context, position) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return RegisterSpotholeModal(
          onRegister: (riskCategory, type) =>
              registerSpothole(context, position, riskCategory, type),
        );
      },
    );
  }

  void onLongPress(BuildContext context, LatLng position) {
    _markersSignal.value['longPressed'] = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
    );
    _googleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(zoom: 18.5, target: position),
      ),
    );
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return LocationMarkerModal(
          position: position,
          onRegister: () => registerSpotholeModal(context, position),
        );
      },
    );
  }
}
