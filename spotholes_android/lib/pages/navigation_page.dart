import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/utilities/dark_mode_context_extension.dart';

import '../controllers/navigation_controller.dart';
import '../controllers/route_controller.dart';
import '../package/custom_info_window.dart';
import '../utilities/constants.dart';
import '../widgets/button/custom_floating_action_button.dart';
import '../widgets/draggable_scrollable_sheet/navigation_draggable_sheet.dart';
import '../widgets/nav_route_steps_page_view.dart';

class NavigationPage extends StatefulWidget {
  final RouteController routeController;

  const NavigationPage({
    super.key,
    required this.routeController,
  });

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  late final _routeController = widget.routeController;

  late final _markers = _routeController.markersSignal;

  late final _directionResult = _routeController.directionResult;
  late final _route = _directionResult.value.routes![0];
  late final _leg = _route.legs![0];
  late final _sourceLocation =
      _routeController.geoCoordToLatLng(_leg.startLocation!);
  late final _destinationLocation =
      _routeController.geoCoordToLatLng(_leg.endLocation!);

  late final _routeSignal = signal(_route);

  late final _navigationController = NavigationController(_routeController);

  late final _customInfoWindowControllerSignal =
      _routeController.customInfoWindowControllerSignal;

  late final _isTrackingLocation = _navigationController.isTrackingLocation;
  late final _isProgrammaticMove = _navigationController.isProgrammaticMove;

  void trackLocation() {
    _navigationController.trackLocation();
  }

  @override
  void dispose() {
    NavigationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch(
      (context) => PopScope(
        //TODO definir ação do popScope para gerar o alertDialog!
        child: Scaffold(
          backgroundColor: context.isDarkMode ? Colors.black : Colors.white,
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
                          'Navegação',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Watch(
                    (_) => NavRouteStepsPageView(
                      routeController: _routeController,
                      pageController: _navigationController.pageController,
                      route: _routeSignal,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
                            return SizedBox(
                              height: constraints.maxHeight,
                              child: Watch(
                                (_) => GoogleMap(
                                  onMapCreated:
                                      (GoogleMapController controller) {
                                    _navigationController
                                        .onMapCreated(controller);
                                  },
                                  initialCameraPosition: CameraPosition(
                                    target: _sourceLocation,
                                    zoom: defaultZoomMap,
                                    tilt: 45,
                                  ),
                                  polylines: _routeController
                                      .polylinesSignal.value.values
                                      .toSet(),
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
                                  onCameraMoveStarted: () {
                                    if (!_isProgrammaticMove.value) {
                                      _isTrackingLocation.value = false;
                                    } else {
                                      _isProgrammaticMove.value = false;
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        CustomInfoWindow(
                          controller: _customInfoWindowControllerSignal.value,
                        ),
                        NavigationDraggableSheet(
                          routeController: _routeController,
                          destinationLocation: _destinationLocation,
                        ),
                        Positioned(
                          bottom: 220,
                          right: 10,
                          left: 0,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                CustomFloatingActionButton(
                                  tooltip: "Start Mock Location",
                                  onPressed: () => {},
                                  // _navigationController.startMockLocation(),
                                  icon: const Icon(Icons.play_arrow),
                                ),
                                const SizedBox(height: 10),
                                CustomFloatingActionButton(
                                  tooltip: "Stop Mock Location",
                                  onPressed: () => {},
                                  // _navigationController.stopMockLocation(),
                                  icon: const Icon(Icons.pause),
                                ),
                                const SizedBox(height: 10),
                                CustomFloatingActionButton(
                                  tooltip: "Centralizar a câmera",
                                  onPressed: () => trackLocation(),
                                  icon: _isTrackingLocation.value
                                      ? const Icon(Icons.my_location)
                                      : const Icon(Icons.location_searching),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
