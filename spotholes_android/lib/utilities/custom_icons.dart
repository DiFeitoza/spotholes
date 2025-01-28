import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotholes_android/utilities/image_size_adjust.dart';

class CustomIcons {
  static BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  static BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  static BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  static BitmapDescriptor potholeSignIcon = BitmapDescriptor.defaultMarker;
  static BitmapDescriptor potholeRedSignIcon = BitmapDescriptor.defaultMarker;
  static BitmapDescriptor redHeadManeuverArrow = BitmapDescriptor.defaultMarker;

  static Image riskTypePothole = Image.asset(
      'assets/images/risks/buraco_na_pista.png',
      width: 70,
      height: 70);
  static Image riskTypeDeepHole = Image.asset(
      'assets/images/risks/buraco_acentuado_na_pista.png',
      width: 70,
      height: 70);
  static Image riskTypeJagged = Image.asset(
      'assets/images/risks/pista_irregular.png',
      width: 70,
      height: 70);
  static Image riskCategoryUnitary = Image.asset(
      'assets/images/risks/categoria_buraco.png',
      width: 70,
      height: 70);
  static Image riskCategoryStrech = Image.asset(
      'assets/images/risks/categoria_trecho_esburacado.png',
      width: 70,
      height: 70);
  static Image potholeAddIcon = Image.asset(
    'assets/images/pothole_add_icon.png',
  );
  static Image potholeRedSignImage =
      Image.asset('assets/images/pothole_red_sign.png', width: 40, height: 40);
  static Image potholeRedSignImageSmall =
      Image.asset('assets/images/pothole_red_sign.png', width: 25, height: 25);
  static Image potholeRedSignImageLarge =
      Image.asset('assets/images/pothole_red_sign.png', width: 55, height: 55);

  static Image potholeSignImage =
      Image.asset('assets/images/pothole_sign.png', width: 40, height: 40);
  static Image potholeSignImageSmall =
      Image.asset('assets/images/pothole_sign.png', width: 25, height: 25);
  static Image potholeSignImageLarge =
      Image.asset('assets/images/pothole_sign.png', width: 55, height: 55);

  static Image sourceIconAsset = Image.asset('assets/images/source_route.png');
  static Image destinationIconAsset =
      Image.asset('assets/images/end_route.png');

  static setupCustomIcons() {
    ImageSizeAdjust.getCustomIcon('assets/images/source_route.png', 110).then(
      (icon) {
        sourceIcon = icon;
      },
    );
    ImageSizeAdjust.getCustomIcon('assets/images/end_route.png', 110).then(
      (icon) {
        destinationIcon = icon;
      },
    );
    ImageSizeAdjust.getCustomIcon("assets/images/badge_red.png", 150).then(
      (icon) {
        currentLocationIcon = icon;
      },
    );
    ImageSizeAdjust.getCustomIcon('assets/images/pothole_sign.png', 100).then(
      (icon) {
        potholeSignIcon = icon;
      },
    );
    ImageSizeAdjust.getCustomIcon('assets/images/pothole_red_sign.png', 100)
        .then(
      (icon) {
        potholeRedSignIcon = icon;
      },
    );
    ImageSizeAdjust.getCustomIcon(
            'assets/images/red_head_maneuver_arrow.png', 40)
        .then(
      (icon) {
        redHeadManeuverArrow = icon;
      },
    );
  }
}
