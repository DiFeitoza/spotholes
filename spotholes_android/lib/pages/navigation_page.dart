import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/utilities/dark_mode_context_extension.dart';
import 'package:spotholes_android/utilities/vibration_manager.dart';

import '../controllers/navigation_controller.dart';
import '../controllers/route_controller.dart';
import '../models/spothole.dart';
import '../package/custom_info_window.dart';
import '../utilities/constants.dart';
import '../utilities/custom_icons.dart';
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
  late final _startLocationLatLng = _routeController.startLocationLatLng;
  late final _spotholesInRoute = _routeController.spotholesInRouteList;

  late final _currentSpotholeIndex = _routeController.currentSpotholeIndex;
  late final _currentSpotholeDistance =
      _routeController.currentSpotholeDistance;

  late final _navigationController = NavigationController(_routeController);

  late final _customInfoWindowControllerSignal =
      _routeController.customInfoWindowControllerSignal;

  late final _isTrackingLocation = _navigationController.isTrackingLocation;
  late final _isProgrammaticMove = _navigationController.isProgrammaticMove;
  late final _isPageViewUpdateCamera =
      _navigationController.isPageViewMoveCamera;

  void onTrackLocation() {
    _navigationController.onTrackLocation();
  }

  late final isDeephole = computed(
    () => _currentSpotholeIndex.value < _spotholesInRoute.value.length
        ? _spotholesInRoute.value[_currentSpotholeIndex.value].type ==
            Type.deepHole
        : false,
  );

  late final spotholeFomattedDistance = computed(() {
    if (_currentSpotholeDistance.value > 1000) {
      final kilometerDistance = _currentSpotholeDistance.value / 1000;
      return 'a ${kilometerDistance.toStringAsFixed(1)} Km';
    } else {
      final formattedMeter =
          _currentSpotholeDistance.value == 1 ? 'metro' : 'metros';
      return '${_currentSpotholeDistance.value.truncate()} $formattedMeter';
    }
  });

  late final countSpotholesInRoute = computed(
      () => _spotholesInRoute.value.length - _currentSpotholeIndex.value);

  @override
  void dispose() {
    NavigationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch(
      (context) => PopScope(
        // TODO definir ação do popScope para gerar o alertDialog!
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
                  if (_spotholesInRoute.value.isNotEmpty &&
                      _currentSpotholeDistance.value != double.infinity)
                    Stack(
                      children: [
                        if (_currentSpotholeDistance.value < 500)
                          Container(
                            width: double.infinity,
                            color: isDeephole.value
                                ? redSecundaryColor
                                : Colors.yellow,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                isDeephole.value
                                    ? CustomIcons.potholeRedSignImageSmall
                                    : CustomIcons.potholeSignImageSmall,
                                const SizedBox(width: 10),
                                Text(
                                  '$spotholeFomattedDistance',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .copyWith(
                                        color: isDeephole.value
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 0.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        countSpotholesInRoute.value == 1
                                            ? '$countSpotholesInRoute alerta'
                                            : '$countSpotholesInRoute alertas',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 0.5),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          isDeephole.value
                                              ? CustomIcons
                                                  .potholeRedSignImageSmall
                                              : CustomIcons
                                                  .potholeSignImageSmall,
                                          const SizedBox(width: 10),
                                          Text(
                                            '$spotholeFomattedDistance',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                      ],
                    ),
                  Watch(
                    (_) => NavRouteStepsPageView(
                      routeController: _routeController,
                      pageController: _navigationController.pageController,
                      isPageViewUpdateCamera: _isPageViewUpdateCamera,
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
                                    target: _startLocationLatLng.value,
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
                        Positioned(
                          top: 0,
                          left: 8,
                          child: Tooltip(
                            message: VibrationManager.isVibrationActive.value
                                ? 'Desativar alerta por vibração'
                                : 'Ativar alerta por vibração',
                            child: ElevatedButton(
                              onPressed: () =>
                                  VibrationManager.toggleVibrationAlert(),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                minimumSize: const Size(4, 4),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(width: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: VibrationManager.isVibrationActive.value
                                  ? const Icon(Icons.vibration,
                                      color: Colors.black)
                                  : const Stack(
                                      // alignment: Alignment.center,
                                      children: [
                                        Icon(Icons.phone_android,
                                            color: Colors.black),
                                        Icon(Icons.close, color: Colors.black),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        NavigationDraggableSheet(
                          routeController: _routeController,
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
                                    tooltip: "Adicionar um risco",
                                    onPressed: () => _navigationController
                                        .registerSpotholeModal(),
                                    icon: CustomIcons.potholeAddIcon),
                                const SizedBox(height: 10),
                                CustomFloatingActionButton(
                                  tooltip: "Atualizar rota e marcadores",
                                  onPressed: () =>
                                      _navigationController.recalculateRoute(),
                                  icon: const Icon(Icons.autorenew),
                                ),
                                const SizedBox(height: 10),
                                CustomFloatingActionButton(
                                  tooltip: _isTrackingLocation.value
                                      ? "Desativar centralização de câmera"
                                      : "Ativar centralização de câmera",
                                  onPressed: () => onTrackLocation(),
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
