import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../controllers/base_map_controller.dart';
import '../package/custom_info_window.dart';
import '../utilities/constants.dart';
import '../utilities/custom_icons.dart';
import '../widgets/main_draggable_sheet.dart';
import '../widgets/search_bar.dart';

class BaseMapPage extends StatefulWidget {
  const BaseMapPage({super.key});
  @override
  State<BaseMapPage> createState() => BaseMapPageState();
}

class BaseMapPageState extends State<BaseMapPage> {
  final _baseMapController = BaseMapController();
  late final _customInfoWindowControllerSignal =
      _baseMapController.customInfoWindowControllerSignal;
  late final _markersSignal = _baseMapController.markersSignal;
  late final _currentLocationSignal = _baseMapController.currentLocationSignal;

  static const LatLng sourceRouteLocation =
      LatLng(-4.9712212645114935, -39.01834056864541);
  static const LatLng destinationRouteLocation =
      LatLng(-4.971373575301382, -39.018458585833024);

  void _loadCurrentLocation() {
    _baseMapController.loadCurrentLocation();
    setState(() {});
  }

  void _centerView() {
    _baseMapController.centerView();
  }

  void _onMapCreated(mapController) {
    _baseMapController.onMapCreated(mapController);
  }

  void _loadRoute(sourceLocation, destinationLocation) {
    _baseMapController.loadRoute(sourceLocation, destinationLocation);
    setState(() {});
  }

  void _onLongPress(LatLng position) {
    _baseMapController.onLongPress(context, position);
    setState(() {});
  }

  void _registerPotholeCurrentLocation() {
    LatLng position = LatLng(_currentLocationSignal.value!.latitude!,
        _currentLocationSignal.value!.longitude!);
    _baseMapController.registerSpotholeModal(context, position);
    setState(() {});
  }

  @override
  void initState() {
    _loadCurrentLocation();
    _loadRoute(sourceRouteLocation, destinationRouteLocation);
    _baseMapController.loadSpotholeMarkers(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Watch(
      (_) => _currentLocationSignal.value == null
          ? const Center(
              child: Text("Carregando..."),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentLocationSignal.value!.latitude!,
                        _currentLocationSignal.value!.longitude!),
                    zoom: defaultZoomMap,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId("route"),
                      points: _baseMapController.routePolylineCoordinates.value,
                      color: primaryColor,
                      width: 6,
                    ),
                  },
                  markers: _markersSignal.value.values.toSet(),
                  onLongPress: _onLongPress,
                  zoomControlsEnabled: false,
                  onTap: (position) {
                    _customInfoWindowControllerSignal.value.hideInfoWindow!();
                  },
                  onCameraMove: (position) {
                    _customInfoWindowControllerSignal.value.onCameraMove!();
                  },
                ),
                CustomInfoWindow(
                  controller: _customInfoWindowControllerSignal.value,
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
                          onPressed: _registerPotholeCurrentLocation,
                          heroTag: null,
                          child: CustomIcons.potholeAddIcon,
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          onPressed: () {
                            _baseMapController.loadSpotholeMarkers(context);
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
                const CustomHeader(),
                MainDraggableSheet(
                  registerPotholeCurrentLocation: () =>
                      _registerPotholeCurrentLocation(),
                ),
              ],
            ),
    );
  }
}
