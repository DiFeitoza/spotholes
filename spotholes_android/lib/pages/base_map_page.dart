import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:spotholes_android/utilities/constants.dart';
import 'package:spotholes_android/database/mock_json_db.dart';
import 'package:spotholes_android/config/environment_config.dart';
import 'package:spotholes_android/utilities/image_size_adjust.dart';

class BaseMapPage extends StatefulWidget {
  const BaseMapPage({super.key});
  @override
  State<BaseMapPage> createState() => BaseMapPageState();
}

class BaseMapPageState extends State<BaseMapPage> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng sourceLocation =
      LatLng(-4.9712212645114935, -39.01834056864541);
  static const LatLng destination =
      LatLng(-4.971373575301382, -39.018458585833024);

  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor potholeIcon = BitmapDescriptor.defaultMarker;

  final Map<String, Marker> markers = {};
  final Map<String, Marker> baseLocations = {};

  var indexRoute = 0;

  void getCurrentLocation() async {
    Location location = Location();

    location.getLocation().then(
      (location) {
        currentLocation = location;
      },
    ).then((location) => generateMarkers());

    GoogleMapController googleMapController = await _controller.future;

    location.onLocationChanged.listen((newLoc) {
      currentLocation = newLoc;
      updateMarkCurrentLocation(newLoc);
      googleMapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              zoom: 18.5,
              target: LatLng(newLoc.latitude!, newLoc.longitude!))));
    });
  }

  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    await polylinePoints
        .getRouteBetweenCoordinates(
      EnvironmentConfig.googleApiKey!,
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    )
        .then((response) {
      if (response.points.isNotEmpty) {
        for (var point in response.points) {
          polylineCoordinates.add(
            LatLng(point.latitude, point.longitude),
          );
        }
        setState(() {});
      }
    });
  }

  void generateMarkers() async {
    markers.clear();
    for (final pothole in data) {
      final marker = Marker(
        markerId: MarkerId(pothole['id']),
        icon: potholeIcon,
        position: pothole['position'],
        infoWindow: InfoWindow(
          title: pothole['label'],
          snippet: pothole['location']['road'],
        ),
      );
      markers[pothole['id']] = marker;
    }

    baseLocations['currentLocation'] = Marker(
        markerId: const MarkerId("currentLocation"),
        icon: currentLocationIcon,
        position:
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!));

    baseLocations['source'] = Marker(
      markerId: const MarkerId("source"),
      icon: sourceIcon,
      position: sourceLocation,
    );

    baseLocations['destination'] = Marker(
      markerId: const MarkerId("destination"),
      icon: destinationIcon,
      position: destination,
    );

    markers.addAll(baseLocations);
    setState(() {});
  }

  void updateMarkCurrentLocation(newLoc) async {
    Marker newMarker = Marker(
        markerId: const MarkerId("currentLocation"),
        icon: currentLocationIcon,
        position:
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!));
    markers['currentLocation'] = newMarker;
    setState(() {});
  }

  // TODO automatizar ajuste de tamanho de ícones com base no tamanho de tela ou componentes do google maps, em vez de fazer ajuste em hardcode, gerar assets com tamanhos corretos para teste.
  void setCustomMakerIcon() {
    ImageSizeAdjust.getCustomIcon('assets/images/mark_location_blue.png', 80)
        .then((icon) {
      sourceIcon = icon;
    });

    ImageSizeAdjust.getCustomIcon(
            'assets/images/pin_destination_contrast_shadow_blue.png', 90)
        .then((icon) {
      destinationIcon = icon;
    });

    ImageSizeAdjust.getCustomIcon("assets/images/badge_red.png", 150)
        .then((icon) {
      currentLocationIcon = icon;
    });

    ImageSizeAdjust.getCustomIcon('assets/images/pothole_sign.png', 80)
        .then((icon) {
      potholeIcon = icon;
    });
  }

  @override
  void initState() {
    getCurrentLocation();
    setCustomMakerIcon();
    getPolyPoints();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Track order",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: currentLocation == null
          ? const Center(child: Text("Loading"))
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!),
                zoom: 18.5,
              ),
              polylines: {
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: polylineCoordinates,
                  color: primaryColor,
                  width: 6,
                ),
              },
              markers: markers.values.toSet(),
              onMapCreated: (mapController) {
                _controller.complete(mapController);
              }),
    );
  }
}