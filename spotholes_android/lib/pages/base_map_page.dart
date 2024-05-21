import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:spotholes_android/config/environment_config.dart';
import 'package:spotholes_android/utilities/constants.dart';
import 'package:spotholes_android/utilities/image_size_adjust.dart';

class BaseMapPage extends StatefulWidget {
  const BaseMapPage({super.key});
  @override
  State<BaseMapPage> createState() => BaseMapPageState();
}

class BaseMapPageState extends State<BaseMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  final Map<String, Marker> markers = {};
  final Map<String, Marker> baseLocations = {};

  LocationData? currentLocation;

  List<LatLng> routePolylineCoordinates = [];

  static const LatLng sourceRouteLocation =
      LatLng(-4.9712212645114935, -39.01834056864541);
  static const LatLng destinationRouteLocation =
      LatLng(-4.971373575301382, -39.018458585833024);

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor potholeIcon = BitmapDescriptor.defaultMarker;

  var indexRoute = 0;

  void loadCurrentLocation() async {
    Location location = Location();

    currentLocation = await location.getLocation();
    loadCurrentLocationMark(currentLocation);

    // TODO Verificar o que a linha seguinte faz
    GoogleMapController googleMapController = await _controller.future;

    location.onLocationChanged.listen((newLoc) {
      currentLocation = newLoc;
      loadCurrentLocationMark(newLoc);
      googleMapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              zoom: 18.5,
              target: LatLng(newLoc.latitude!, newLoc.longitude!))));
    });
  }

  void loadRoute(sourceLocation, destinationLocation) async {
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
        loadRouteMarkers(sourceLocation, destinationLocation);
        setState(() {});
      }
      // TODO: adicionar a exceção de não haver uma rota!
    });
  }

  loadRouteMarkers(sourceLocation, destinationLocation) {
    Marker sourceRouteMarker = Marker(
      markerId: const MarkerId("sourceRoute"),
      icon: sourceIcon,
      position: sourceRouteLocation,
    );

    Marker destinationRouteMarker = Marker(
      markerId: const MarkerId("destinationRoute"),
      icon: destinationIcon,
      position: destinationRouteLocation,
    );

    markers["sourceRouteMarker"] = sourceRouteMarker;
    markers['destinationRouteMarker'] = destinationRouteMarker;
    setState(() {});
  }

  void loadCurrentLocationMark(newLoc) async {
    Marker newMarker = Marker(
        markerId: const MarkerId("currentLocation"),
        icon: currentLocationIcon,
        position:
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!));
    markers['currentLocation'] = newMarker;
    setState(() {});
  }

  void loadPotHoles() {
    databaseReference.child('potholes').once().then((DatabaseEvent event) {
      List<dynamic>? potholesList = event.snapshot.value as List<dynamic>?;
      for (final pothole in potholesList!) {
        final marker = Marker(
          markerId: MarkerId(pothole['id']),
          icon: potholeIcon,
          position: LatLng(
            pothole['position']['lat'] as double,
            pothole['position']['long'] as double,
          ),
          infoWindow: InfoWindow(
            title: pothole['label'],
            snippet: pothole['location']['road'],
          ),
        );
        markers[pothole['id']] = marker;
      }
    });
  }

  // TODO automatizar ajuste de tamanho de ícones com base no tamanho de tela ou componentes do google maps, em vez de fazer ajuste em hardcode, gerar assets com tamanhos corretos para teste.
  void setCustomMakerIcons() {
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
    setCustomMakerIcons();
    loadCurrentLocation();
    loadRoute(sourceRouteLocation, destinationRouteLocation);
    loadPotHoles();
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
      body: currentLocation == null
          ? const Center(child: Text("Loading..."))
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!),
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
              markers: markers.values.toSet(),
              onMapCreated: (mapController) {
                _controller.complete(mapController);
              }),
    );
  }
}
