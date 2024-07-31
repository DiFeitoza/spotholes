import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../controllers/base_map_controller.dart';
import '../package/custom_info_window.dart';
import '../utilities/constants.dart';
import '../widgets/button/custom_fab_list.dart';
import '../widgets/search_bar.dart';

class BaseMapPage extends StatefulWidget {
  const BaseMapPage({super.key});
  @override
  State<BaseMapPage> createState() => BaseMapPageState();
}

class BaseMapPageState extends State<BaseMapPage> {
  final _baseMapController = BaseMapController.instance;
  late final _customInfoWindowControllerSignal =
      _baseMapController.customInfoWindowControllerSignal;
  late final _markersSignal = _baseMapController.markersSignal;
  late final _currentLocationSignal = _baseMapController.currentLocationSignal;
  late final _draggableScrollableSheetSignal =
      _baseMapController.draggableScrollableSheetSignal;

  void _onMapCreated(mapController) {
    _baseMapController.onMapCreated(mapController);
  }

  void _onLongPress(LatLng position) {
    _baseMapController.onLongPress(context, position);
  }

  @override
  void initState() {
    _baseMapController.loadCurrentLocation();
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
                  onCameraIdle: () =>
                      _customInfoWindowControllerSignal.value.onCameraMove!(),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId("route"),
                      points: _baseMapController.routePolylineCoordinates,
                      color: primaryColor,
                      width: 6,
                    ),
                  },
                  markers: _markersSignal.value.values.toSet(),
                  onLongPress: _onLongPress,
                  zoomControlsEnabled: false,
                  onTap: (position) =>
                      _customInfoWindowControllerSignal.value.hideInfoWindow!(),
                  onCameraMove: (position) =>
                      _customInfoWindowControllerSignal.value.onCameraMove!(),
                ),
                CustomInfoWindow(
                  controller: _customInfoWindowControllerSignal.value,
                ),
                CustomFABList(),
                const CustomHeader(),
                _draggableScrollableSheetSignal.value,
              ],
            ),
    );
  }
}
