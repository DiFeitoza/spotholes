import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotholes_android/package/google_places_flutter/model/place_details.dart';
import 'package:spotholes_android/widgets/draggable_scrollable_sheet/route_draggable_sheet.dart';

import 'location_draggable_sheet.dart';
import 'main_draggable_sheet.dart';
import 'place_draggable_sheet.dart';

class DraggableScrollableSheetType {
  final Widget widget;

  const DraggableScrollableSheetType({required this.widget});
}

class DraggableScrollableSheetTypes {
  static final initial = DraggableScrollableSheetType(
    widget: MainDraggableSheet(controller: MainDraggableSheetController()),
  );

  static DraggableScrollableSheetType place(
      {required PlaceDetails placeDetails, required LatLng position}) {
    return DraggableScrollableSheetType(
      widget: PlaceDraggableSheet(
        placeDetails: placeDetails,
        controller: PlaceDraggableSheetController(),
        position: position,
      ),
    );
  }

  static DraggableScrollableSheetType location(
      {required Function onRegister, required LatLng position}) {
    return DraggableScrollableSheetType(
      widget: LocationDraggableSheet(
        controller: LocationDraggableSheetController(),
        onRegister: onRegister,
        position: position,
      ),
    );
  }

  static DraggableScrollableSheetType route(
      {required LatLng destinationLocation}) {
    return DraggableScrollableSheetType(
      widget: RouteDraggableSheet(
        controller: RouteDraggableSheetController(),
        destinationLocation: destinationLocation,
      ),
    );
  }
}
