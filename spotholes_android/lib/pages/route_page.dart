import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../controllers/route_controller.dart';
import '../utilities/constants.dart';
import '../package/custom_info_window.dart';
import '../utilities/dark_mode_context_extension.dart';
import '../widgets/draggable_scrollable_sheet/route_draggable_sheet.dart';

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
  final _routeController = RouteController.instance;
  late final _markers = _routeController.markersSignal;
  late final _routePolylineCoordinatesSignal =
      _routeController.routePolylineCoordinatesSignal;

  late final _directionResult = _routeController.directionResult;
  late final _route = _directionResult.value.routes![0];
  late final _leg = _route.legs![0];

  late final _customInfoWindowControllerSignal =
      _routeController.customInfoWindowControllerSignal;

  bool _isLoading = true;

  Future<void> _loadRoute() async {
    await _routeController.loadRouteWithLegsAndSteps(
        widget.sourceLocation, widget.destinationLocation, context);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading == true
        ? Container(
            //TODO criar tela de transição e lidar com o caso de erro!
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      color: Theme.of(context).focusColor,
                      child: Column(
                        children: [
                          Text(
                            'Via: ${_route.summary!}',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_leg.distance!.text} (${_leg.duration!.text})',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          LayoutBuilder(
                            builder: (BuildContext context,
                                BoxConstraints constraints) {
                              return SizedBox(
                                height: constraints.maxHeight / 1.50,
                                child: Watch(
                                  (context) => GoogleMap(
                                    onMapCreated:
                                        (GoogleMapController controller) =>
                                            _routeController
                                                .onMapCreated(controller),
                                    initialCameraPosition: CameraPosition(
                                      target: widget.sourceLocation,
                                      zoom: defaultZoomMap,
                                    ),
                                    polylines: {
                                      Polyline(
                                        polylineId: const PolylineId("route"),
                                        points: _routePolylineCoordinatesSignal
                                            .value,
                                        color: primaryColor,
                                        width: 6,
                                      ),
                                    },
                                    markers: _markers.value.values.toSet(),
                                    zoomControlsEnabled: false,
                                    onCameraIdle: () =>
                                        _customInfoWindowControllerSignal
                                            .value.onCameraMove!(),
                                    onTap: (position) =>
                                        _customInfoWindowControllerSignal
                                            .value.hideInfoWindow!(),
                                    onCameraMove: (position) =>
                                        _customInfoWindowControllerSignal
                                            .value.onCameraMove!(),
                                  ),
                                ),
                              );
                            },
                          ),
                          CustomInfoWindow(
                            controller: _customInfoWindowControllerSignal.value,
                          ),
                          RouteDraggableSheet(
                            controller: RouteDraggableSheetController(),
                            destinationLocation: widget.destinationLocation,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
