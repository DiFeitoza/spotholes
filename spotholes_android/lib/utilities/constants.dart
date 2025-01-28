import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF7B61FF);
const Color redPrimaryColor = Color(0xFFFF7070);
const Color redSecundaryColor = Color.fromARGB(255, 255, 74, 74);
const double defaultPadding = 16.0;

// Google Maps
const double defaultZoomMap = 18.5;
const double defaultNavigationTilt = 90;
const String mapStyle2D = '''[
      {
        "featureType": "landscape.man_made",
        "elementType": "geometry",
        "stylers": [{"visibility": "off"}]
      }
    ]''';

// Navigation
const double routeDeviationTolerance = 12;
