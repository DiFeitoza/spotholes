/// A widget based custom info window for google_maps_flutter package.
library custom_info_window;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Controller to add, update and control the custom info window.
class CustomInfoWindowController {
  /// Add custom [Widget] and [Marker]'s [LatLng] to [CustomInfoWindow] and make it visible.
  Function(Widget, LatLng)? addInfoWindow;

  /// Notifies [CustomInfoWindow] to redraw as per change in position.
  VoidCallback? onCameraMove;

  /// Hides [CustomInfoWindow].
  VoidCallback? hideInfoWindow;

  /// Holds [GoogleMapController] for calculating [CustomInfoWindow] position.
  GoogleMapController? googleMapController;

  void dispose() {
    addInfoWindow = null;
    onCameraMove = null;
    hideInfoWindow = null;
    googleMapController = null;
  }
}

/// A stateful widget responsible to create widget based custom info window.
class CustomInfoWindow extends StatefulWidget {
  /// A [CustomInfoWindowController] to manipulate [CustomInfoWindow] state.
  final CustomInfoWindowController controller;

  /// Offset to maintain space between [Marker] and [CustomInfoWindow].
  final double offset;

  /// Height of [CustomInfoWindow].
  final double maxHeight;

  /// Width of [CustomInfoWindow].
  final double maxWidth;

  final double minWidth;
  final double minHeight;

  const CustomInfoWindow({
    super.key,
    required this.controller,
    this.offset = 40,
    this.minWidth = 100,
    this.minHeight = 100,
    this.maxHeight = 300,
    this.maxWidth = 300,
  });

  @override
  CustomInfoWindowState createState() => CustomInfoWindowState();
}

class CustomInfoWindowState extends State<CustomInfoWindow> {
  bool _showNow = false;
  double _leftMargin = 0;
  double _topMargin = 0;
  Widget? _child;
  LatLng? _latLng;
  Size? _size;

  @override
  void initState() {
    super.initState();
    widget.controller.addInfoWindow = _addInfoWindow;
    widget.controller.onCameraMove = _onCameraMove;
    widget.controller.hideInfoWindow = _hideInfoWindow;
  }

  /// Calculate the position on [CustomInfoWindow] and redraw on screen.
  void _updateInfoWindow() async {
    if (_latLng == null ||
        _child == null ||
        widget.controller.googleMapController == null) {
      return;
    }

    if (_size == null) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      _size = renderBox.size;
    }

    ScreenCoordinate screenCoordinate = await widget
        .controller.googleMapController!
        .getScreenCoordinate(_latLng!);
    double devicePixelRatio =
        Platform.isAndroid ? MediaQuery.of(context).devicePixelRatio : 1.0;
    double left =
        (screenCoordinate.x.toDouble() / devicePixelRatio) - (_size!.width / 2);
    double top = (screenCoordinate.y.toDouble() / devicePixelRatio) -
        (widget.offset + _size!.height);

    setState(() {
      _showNow = true;
      _leftMargin = left;
      _topMargin = top;
    });
  }

  /// Assign the [Widget] and [Marker]'s [LatLng].
  void _addInfoWindow(Widget child, LatLng latLng) {
    _child = child;
    _latLng = latLng;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      _size = renderBox.size;
    });
    _updateInfoWindow();
  }

  /// Notifies camera movements on [GoogleMap].
  void _onCameraMove() {
    if (!_showNow) return;
    _updateInfoWindow();
  }

  /// Disables [CustomInfoWindow] visibility.
  void _hideInfoWindow() {
    setState(() {
      _showNow = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _leftMargin,
      top: _topMargin,
      child: Visibility(
        visible: (_showNow == false ||
                (_leftMargin == 0 && _topMargin == 0) ||
                _child == null ||
                _latLng == null)
            ? false
            : true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minWidth,
            minHeight: widget.minHeight,
            maxWidth: widget.maxHeight,
            maxHeight: widget.maxHeight,
          ),
          child: Container(
            child: _child,
          ),
        ),
      ),
    );
  }
}
