import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

double haversineDistance(LatLng point1, LatLng point2) {
  const double earthRadius = 6371000; // Earth's radius in meters
  double dLat = (point2.latitude - point1.latitude) * pi / 180;
  double dLng = (point2.longitude - point1.longitude) * pi / 180;

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(point1.latitude * pi / 180) *
          cos(point2.latitude * pi / 180) *
          sin(dLng / 2) *
          sin(dLng / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

LatLng interpolate(LatLng point1, LatLng point2, double fraction) {
  return LatLng(
    point1.latitude + fraction * (point2.latitude - point1.latitude),
    point1.longitude + fraction * (point2.longitude - point1.longitude),
  );
}

int findAndInsertMidpoint(List<LatLng> points) {
  if (points.isEmpty) {
    throw ArgumentError('A lista de pontos não pode estar vazia');
  }

  double totalDistance = 0;
  List<double> segmentDistances = [];
  for (int i = 0; i < points.length - 1; i++) {
    double segmentDistance = haversineDistance(points[i], points[i + 1]);
    segmentDistances.add(segmentDistance);
    totalDistance += segmentDistance;
  }

  double halfDistance = totalDistance / 2;
  double accumulatedDistance = 0;

  for (int i = 0; i < points.length - 1; i++) {
    double segmentDistance = segmentDistances[i];
    if (accumulatedDistance + segmentDistance >= halfDistance) {
      double remainingDistance = halfDistance - accumulatedDistance;
      double fraction = remainingDistance / segmentDistance;
      LatLng midpoint = interpolate(points[i], points[i + 1], fraction);

      // Insert midpoint into list
      points.insert(i + 1, midpoint);

      // Return the midpoint index
      return i + 1;
    }
    accumulatedDistance += segmentDistance;
  }

  return points.length - 1; // If the accumulated distance is exactly half
}

List<LatLng> getSegmentAroundMidpoint(
    List<LatLng> points, double distanceBefore, double distanceAfter,
    {int? midpointIndex}) {
  if (points.isEmpty) {
    throw ArgumentError('A lista de pontos não pode estar vazia');
  }

  if (points.length == 1) {
    throw ArgumentError('A lista de pontos deve conter pelo menos 2 pontos');
  }

  LatLng midpoint;
  if (midpointIndex == null) {
    midpointIndex = findAndInsertMidpoint(points);
    midpoint = points[midpointIndex];
  } else {
    midpoint = points[midpointIndex];
  }

  List<LatLng> segment = [];

  // If the accumulated distance is exactly half
  double remainingDistanceBefore = distanceBefore;
  for (int i = midpointIndex; i > 0; i--) {
    double segmentDistance = haversineDistance(points[i], points[i - 1]);
    if (remainingDistanceBefore <= segmentDistance) {
      double fraction = remainingDistanceBefore / segmentDistance;
      segment.insert(0, interpolate(points[i], points[i - 1], fraction));
      break;
    } else {
      segment.insert(0, points[i - 1]);
      remainingDistanceBefore -= segmentDistance;
    }
  }

  // Add the midpoint
  segment.add(midpoint);

  // Calculate points after midpoint
  double remainingDistanceAfter = distanceAfter;
  for (int i = midpointIndex + 1; i < points.length; i++) {
    double segmentDistance = haversineDistance(points[i - 1], points[i]);
    if (remainingDistanceAfter <= segmentDistance) {
      double fraction = remainingDistanceAfter / segmentDistance;
      segment.add(interpolate(points[i - 1], points[i], fraction));
      break;
    } else {
      segment.add(points[i]);
      remainingDistanceAfter -= segmentDistance;
    }
  }

  return segment;
}

//TRIANGLE = HEAD ARROW

// LatLng movePoint(LatLng point, double distance, double bearing) {
//   double radiusEarth = 6371000; // Raio da Terra em metros
//   double bearingRad = bearing * pi / 180;

//   double lat1 = point.latitude * pi / 180;
//   double lng1 = point.longitude * pi / 180;

//   double lat2 = asin(sin(lat1) * cos(distance / radiusEarth) +
//       cos(lat1) * sin(distance / radiusEarth) * cos(bearingRad));
//   double lng2 = lng1 +
//       atan2(sin(bearingRad) * sin(distance / radiusEarth) * cos(lat1),
//           cos(distance / radiusEarth) - sin(lat1) * sin(lat2));

//   return LatLng(lat2 * 180 / pi, lng2 * 180 / pi);
// }

// double calculateBearing(LatLng start, LatLng end) {
//   double startLat = start.latitude * pi / 180;
//   double startLng = start.longitude * pi / 180;
//   double endLat = end.latitude * pi / 180;
//   double endLng = end.longitude * pi / 180;

//   double dLng = endLng - startLng;
//   double y = sin(dLng) * cos(endLat);
//   double x =
//       cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);
//   double bearing = atan2(y, x) * 180 / pi;

//   return (bearing + 360) %
//       360; // Normaliza o ângulo para estar entre 0 e 360 graus
// }

// Polygon getArrowHead(LatLng point, double angle) {
//   double arrowHeadSize = 10; // Tamanho do triângulo em pixels

//   // Calcula os vértices do triângulo
//   LatLng vertex1 = movePoint(point, arrowHeadSize, angle - 30);
//   LatLng vertex2 = movePoint(point, arrowHeadSize, angle + 30);

//   return Polygon(
//     polygonId: const PolygonId('polygon_arrow_head'),
//     points: [point, vertex1, vertex2],
//     fillColor: Colors.red,
//     strokeColor: Colors.red,
//     strokeWidth: 1,
//   );
// }

// Polygon getArrowTriangle(List<LatLng> points) {
//   double angle = calculateBearing(points[0], points[1]);
//   return getArrowHead(points[1], angle + 180);
// }
