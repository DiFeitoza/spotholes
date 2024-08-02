import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/controllers/route_controller.dart';
import 'package:spotholes_android/utilities/dark_mode_context_extension.dart';
import 'package:spotholes_android/widgets/draggable_scrollable_sheet/route_draggable_sheet.dart';

import '../utilities/constants.dart';
import '../utilities/map_utils.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({
    super.key,
    required this.sourceLocation,
    required this.destinationLocation,
  });

  final LatLng sourceLocation;
  final LatLng destinationLocation;

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  final _routeMapController = RouteController.instance;
  late final _markers = _routeMapController.markersSignal;
  late final _routePolylineCoordinates =
      _routeMapController.routePolylineCoordinatesSignal;

  void _newCameraLatLngBounds(mapController) {
    Future.delayed(
      const Duration(milliseconds: 200),
      () => mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          MapUtils.boundsFromLatLngList(_routePolylineCoordinates.value),
          //TODO analisar otimização em usar somente início e fim da rota, ou todos os pontos [widget.sourceLocation, widget.destinationLocation].
          70,
        ),
      ),
    );
  }

  void _loadRoute() {
    _routeMapController.loadRoute(
        widget.sourceLocation, widget.destinationLocation);
    setState(() {});
  }

  @override
  void initState() {
    _loadRoute();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        centerTitle: true,
        title: Text("Seu local ➞ Destino",
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: SafeArea(
        child: Container(
          color: context.isDarkMode ? Colors.white : Colors.black,
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SizedBox(
                    height: constraints.maxHeight / 1.35,
                    child: Watch(
                      (context) => GoogleMap(
                        onMapCreated: (GoogleMapController controller) =>
                            _newCameraLatLngBounds(controller),
                        initialCameraPosition: CameraPosition(
                          target: widget.sourceLocation,
                          zoom: defaultZoomMap,
                        ),
                        polylines: {
                          Polyline(
                            polylineId: const PolylineId("route"),
                            points: _routePolylineCoordinates.value,
                            color: primaryColor,
                            width: 6,
                          ),
                        },
                        markers: _markers.value.values.toSet(),
                        zoomControlsEnabled: false,
                      ),
                    ),
                  );
                },
              ),
              RouteDraggableSheet(
                controller: RouteDraggableSheetController(),
                destinationLocation: widget.destinationLocation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
