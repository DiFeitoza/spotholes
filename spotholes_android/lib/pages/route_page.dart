import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/widgets/spotholes_page_view.dart';

import '../controllers/route_controller.dart';
import '../main.dart';
import '../package/custom_info_window.dart';
import '../utilities/app_routes.dart';
import '../utilities/constants.dart';
import '../utilities/dark_mode_context_extension.dart';
import '../widgets/button/custom_button.dart';
import '../widgets/draggable_scrollable_sheet/route_draggable_sheet.dart';
import '../widgets/route_steps_page_view.dart';

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

class _RoutePageState extends State<RoutePage> with RouteAware {
  final _routeController = RouteController();
  late final _markers = _routeController.markersSignal;
  late final _route = _routeController.route;
  late final _leg = _routeController.leg;

  late final _customInfoWindowControllerSignal =
      _routeController.customInfoWindowControllerSignal;

  late final _pageControllerSignal = _routeController.pageControllerSignal;
  late final _pageViewTypeSignal = _routeController.pageViewTypeSignal;
  late final _showStepsPageSignal = _routeController.showStepsPageSignal;
  bool _isLoading = true;

  void _toggleWidgets() {
    _showStepsPageSignal.value = !_showStepsPageSignal.value;
  }

  List<Widget> _horizontalListButtons() {
    return [
      CustomButton(
        label: 'Iniciar viagem',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => MyApp.navigatorKey.currentState?.pushNamed(
          AppRoutes.navigation,
          arguments: [_routeController.getCopy()],
        ),
      ),
      CustomButton(
        label: 'Centralizar',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => {
          _routeController.centerViewRoute(),
          // changeSizeDraggableScrollableSheet(_minDraggableChildSize),
        },
      ),
    ];
  }

  Future<void> _loadRoute() async {
    await _routeController.loadRouteWithLegsAndSteps(
        widget.sourceLocation, widget.destinationLocation);
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
  void didPopNext() {
    _routeController.centerViewRoute();

    /// Avoid exception when the user returns from the navigation page and try access the info window
    _customInfoWindowControllerSignal.value.hideInfoWindow!();

    /// Update markers when the user returns from the navigation page changing the customInfoWindowController with the new mapController
    _routeController.updateAllRouteMarkers();
  }

  @override
  void didChangeDependencies() {
    MyApp.routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    MyApp.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading == true
        ? Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Watch(
            (context) => PopScope(
              canPop: !_showStepsPageSignal.value,
              onPopInvoked: (didPop) {
                if (_showStepsPageSignal.value) {
                  _toggleWidgets();
                }
              },
              child: Scaffold(
                backgroundColor:
                    context.isDarkMode ? Colors.black : Colors.white,
                appBar: AppBar(
                  backgroundColor: Theme.of(context).canvasColor,
                  centerTitle: true,
                  title: !_showStepsPageSignal.value
                      ? Text(
                          "Rota",
                          style: Theme.of(context).textTheme.titleLarge,
                        )
                      : Text(
                          "Detalhes da rota",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
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
                              if (_route.value.summary!.isNotEmpty)
                                Text(
                                  'Via: ${_route.value.summary!}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.two_wheeler),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    '${_leg.value.distance!.text} (${_leg.value.duration!.text})',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        if (_showStepsPageSignal.value &&
                            _pageViewTypeSignal.value == 'route')
                          RouteStepsPageView(
                            routeController: _routeController,
                          ),
                        if (_showStepsPageSignal.value &&
                            _pageViewTypeSignal.value == 'spothole')
                          SpotholesPageView(
                            routeController: _routeController,
                          ),
                        Expanded(
                          child: Stack(
                            children: [
                              LayoutBuilder(
                                builder: (BuildContext context,
                                    BoxConstraints constraints) {
                                  return SizedBox(
                                    height: _showStepsPageSignal.value
                                        ? constraints.maxHeight
                                        : constraints.maxHeight / 1.50,
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
                                      ),
                                    ),
                                  );
                                },
                              ),
                              CustomInfoWindow(
                                controller:
                                    _customInfoWindowControllerSignal.value,
                              ),
                              Visibility(
                                visible: !_showStepsPageSignal.value,
                                maintainState: true,
                                child: RouteDraggableSheet(
                                  routeController: _routeController,
                                ),
                              ),
                              if (_showStepsPageSignal.value)
                                Positioned(
                                  bottom: 24,
                                  right: 36,
                                  child: Row(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          surfaceTintColor: Colors.white,
                                          minimumSize: const Size.square(48),
                                          shape: RoundedRectangleBorder(
                                            side: const BorderSide(width: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                        onPressed: () {
                                          _pageControllerSignal.value
                                              .previousPage(
                                                  duration: Durations.medium1,
                                                  curve: Curves.easeInOutExpo);
                                        },
                                        child: const Icon(
                                          Icons.arrow_left,
                                          size: 32,
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          surfaceTintColor: Colors.white,
                                          minimumSize: const Size.square(48),
                                          shape: RoundedRectangleBorder(
                                            side: const BorderSide(width: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                        onPressed: () {
                                          _pageControllerSignal.value.nextPage(
                                              duration: Durations.medium1,
                                              curve: Curves.easeInOutExpo);
                                        },
                                        child: const Icon(
                                          Icons.arrow_right,
                                          size: 32,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: _showStepsPageSignal.value,
                          maintainState: true,
                          child: Container(
                            color: Colors.white,
                            child: SizedBox(
                              height: 60.0,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: _horizontalListButtons(),
                              ),
                            ),
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
