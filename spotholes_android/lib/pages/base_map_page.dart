import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/config/environment_config.dart';
import 'package:spotholes_android/mixins/spothole_mixin.dart';
import 'package:spotholes_android/package/custom_info_windows.dart';
import 'package:spotholes_android/services/service_locator.dart';
import 'package:spotholes_android/utilities/constants.dart';
import 'package:spotholes_android/widgets/delete_spothole_alert_dialog.dart';
import 'package:spotholes_android/widgets/location_marker_modal.dart';
import 'package:spotholes_android/widgets/main_draggable_sheet.dart';

import '../utilities/custom_icons.dart';

class BaseMapPage extends StatefulWidget {
  const BaseMapPage({super.key});
  @override
  State<BaseMapPage> createState() => BaseMapPageState();
}

class BaseMapPageState extends State<BaseMapPage> with RegisterSpothole {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? googleMapController;
  final Map<String, Marker> baseLocations = {};

  Location location = Location();
  final Signal<LocationData?> currentLocationSignal =
      getIt<Signal<LocationData?>>();

  List<LatLng> routePolylineCoordinates = [];

  static const LatLng sourceRouteLocation =
      LatLng(-4.9712212645114935, -39.01834056864541);
  static const LatLng destinationRouteLocation =
      LatLng(-4.971373575301382, -39.018458585833024);

  var indexRoute = 0;

  void _loadCurrentLocation() async {
    currentLocationSignal.value = await location.getLocation();
    _loadCurrentLocationMark(currentLocationSignal.value);

    location.onLocationChanged.listen((newLoc) {
      currentLocationSignal.value = newLoc;
      _loadCurrentLocationMark(newLoc);
    });

    // TODO entender e melhorar esse trecho de código
    googleMapController = await _controller.future;

    googleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: 18.5,
          target: LatLng(currentLocationSignal.value!.latitude!,
              currentLocationSignal.value!.longitude!),
        ),
      ),
    );
  }

  void _centerView() async {
    googleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentLocationSignal.value!.latitude!,
              currentLocationSignal.value!.longitude!),
          zoom: 18.5,
        ),
      ),
    );
  }

  void _onMapCreated(mapController) {
    _controller.complete(mapController);
    customInfoWindowController.googleMapController = mapController;
  }

  void _loadRoute(sourceLocation, destinationLocation) async {
    PolylinePoints polylinePoints = PolylinePoints();

    await polylinePoints
        .getRouteBetweenCoordinates(
      EnvironmentConfig.googleApiKey!,
      PointLatLng(sourceLocation!.latitude!, sourceLocation!.longitude!),
      PointLatLng(
          destinationLocation!.latitude!, destinationLocation!.longitude!),
    )
        .then((response) {
      if (response.points.isNotEmpty) {
        for (var point in response.points) {
          routePolylineCoordinates.add(
            LatLng(point.latitude, point.longitude),
          );
        }
        _loadRouteMarkers(sourceLocation, destinationLocation);
        setState(() {});
      }
      // TODO: adicionar a exceção de não haver uma rota!
    });
  }

  void _loadRouteMarkers(sourceLocation, destinationLocation) {
    Marker sourceRouteMarker = Marker(
      markerId: const MarkerId("sourceRoute"),
      icon: CustomIcons.sourceIcon,
      position: sourceRouteLocation,
    );

    Marker destinationRouteMarker = Marker(
      markerId: const MarkerId("destinationRoute"),
      icon: CustomIcons.destinationIcon,
      position: destinationRouteLocation,
    );

    markersSignal.value["sourceRouteMarker"] = sourceRouteMarker;
    markersSignal.value['destinationRouteMarker'] = destinationRouteMarker;
    setState(() {});
  }

  void _loadCurrentLocationMark(newLoc) async {
    Marker newMarker = Marker(
      markerId: const MarkerId("currentLocation"),
      icon: CustomIcons.currentLocationIcon,
      position: LatLng(currentLocationSignal.value!.latitude!,
          currentLocationSignal.value!.longitude!),
    );
    markersSignal.value['currentLocationMarker'] = newMarker;
    setState(() {});
  }

  void _onLongPress(LatLng position) {
    markersSignal.value['longPressed'] = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
    );
    googleMapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(zoom: 18.5, target: position)));
    showModalBottomSheet(
        context: context,
        builder: (builder) {
          return LocationMarkerModal(position: position);
        });
    setState(() {});
  }

  Future<void> _registerPothole() async {
    registerSpotholeModal(context, currentLocationSignal.value);
    setState(() {});
  }

  void showDeleteSpotholeAlertDialog(String spotholeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteSpotholeAlertDialog(
          onConfirm: () {
            deleteSpothole(spotholeId);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  void initState() {
    _loadCurrentLocation();
    _loadRoute(sourceRouteLocation, destinationRouteLocation);
    loadSpotholeMarkers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "SpotHoles Android",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: currentLocationSignal.value == null
          ? const Center(child: Text("Carregando..."))
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(currentLocationSignal.value!.latitude!,
                        currentLocationSignal.value!.longitude!),
                    zoom: 18.5,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId("route"),
                      points: routePolylineCoordinates,
                      color: primaryColor,
                      width: 6,
                    ),
                  },
                  markers: markersSignal.value.values.toSet(),
                  onLongPress: _onLongPress,
                  zoomControlsEnabled: false,
                  onTap: (position) {
                    customInfoWindowController.hideInfoWindow!();
                  },
                  onCameraMove: (position) {
                    customInfoWindowController.onCameraMove!();
                  },
                ),
                CustomInfoWindow(
                  controller: customInfoWindowController,
                ),
                Positioned(
                  bottom: 150,
                  right: 10,
                  left: 0,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        FloatingActionButton(
                          onPressed: _registerPothole,
                          heroTag: null,
                          child: CustomIcons.potholeAddIcon,
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          onPressed: () {
                            loadSpotholeMarkers();
                          },
                          heroTag: null,
                          child: const Icon(Icons.sync),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          onPressed: _centerView,
                          heroTag: null,
                          child: const Icon(Icons.location_searching),
                        ),
                      ],
                    ),
                  ),
                ),
                const MainDraggableSheet(),
              ],
            ),
    );
  }
}
