import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/widgets/spotholes_page_view.dart';

import '../controllers/route_controller.dart';
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

class _RoutePageState extends State<RoutePage> {
  final _routeController = RouteController.instance;
  late final _markers = _routeController.markersSignal;

  late final _directionResult = _routeController.directionResult;
  late final _route = _directionResult.value.routes![0];
  late final _leg = _route.legs![0];

  late final _customInfoWindowControllerSignal =
      _routeController.customInfoWindowControllerSignal;

  bool _isLoading = true;

  late final _pageViewTypeSignal = _routeController.pageViewTypeSignal;

  late final _showStepsPageSignal = _routeController.showStepsPageSignal;
  late final Signal<PageController> _pageControllerSignal =
      _routeController.pageControllerSignal;

  void _toggleWidgets() {
    _showStepsPageSignal.value = !_showStepsPageSignal.value;
  }

  List<Widget> _horizontalListButtons(BuildContext context, position) {
    return [
      CustomButton(
        label: 'Iniciar viagem',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => Navigator.of(context).pushNamed(
          AppRoutes.navigation,
          arguments: [RouteController.getCopy()],
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
  void dispose() {
    RouteController.resetInstance();
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
                          "Seu local ➞ Destino",
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
                        if (_showStepsPageSignal.value &&
                            _pageViewTypeSignal.value == 'route')
                          RouteStepsPageView(
                            pageController: _pageControllerSignal.value,
                            route: _route,
                          ),
                        if (_showStepsPageSignal.value &&
                            _pageViewTypeSignal.value == 'spothole')
                          SpotholesPageView(
                              pageController: _pageControllerSignal.value),
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
                                  controller: RouteDraggableSheetController(),
                                  destinationLocation:
                                      widget.destinationLocation,
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
                                children: _horizontalListButtons(
                                  context,
                                  widget.destinationLocation,
                                ),
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
