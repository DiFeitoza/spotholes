import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/base_map_controller.dart';
import '../../package/google_places_flutter/model/place_details.dart';
import 'location_draggable_sheet.dart';
import 'main_draggable_sheet.dart';
import 'place_draggable_sheet.dart';

class DraggableScrollableSheetType {
  final Widget widget;
  const DraggableScrollableSheetType({required this.widget});
}

class DraggableScrollableSheetTypes {
  final BaseMapController baseMapController;
  DraggableScrollableSheetTypes({required this.baseMapController});

  DraggableScrollableSheetType get initial => DraggableScrollableSheetType(
        widget: MainDraggableSheet(
          controller: MainDraggableSheetController(),
          baseMapController: baseMapController,
        ),
      );

  static DraggableScrollableSheetType place(
      {required PlaceDetails placeDetails,
      required LatLng position,
      required BaseMapController baseMapController}) {
    return DraggableScrollableSheetType(
      widget: PlaceDraggableSheet(
        placeDetails: placeDetails,
        position: position,
        baseMapController: baseMapController,
      ),
    );
  }

  static DraggableScrollableSheetType location(
      {required LatLng position,
      required formattedPlacemark,
      required BaseMapController baseMapController}) {
    return DraggableScrollableSheetType(
      widget: LocationDraggableSheet(
        position: position,
        formattedPlacemark: formattedPlacemark,
        baseMapController: baseMapController,
      ),
    );
  }
}
