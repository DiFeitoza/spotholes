import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/spothole.dart';

/// Function to calculate the Haversine distance between two points
double haversine(LatLng point1, LatLng point2) {
  /// Earth radius in meters
  const R = 6371000;
  final phi1 = point1.latitude * pi / 180;
  final phi2 = point2.latitude * pi / 180;
  final deltaPhi = (point2.latitude - point1.latitude) * pi / 180;
  final deltaLambda = (point2.longitude - point1.longitude) * pi / 180;

  final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
      cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c;
}

/// Projects a given geographical point onto a line segment defined by two points.
///
/// This function calculates the projection of a point onto a line segment using vector mathematics.
/// It returns the projected point on the line segment.
///
/// Parameters:
/// - [point]: The geographical point (LatLng) to be projected.
/// - [startPoint]: The starting point (LatLng) of the line segment.
/// - [endPoint]: The ending point (LatLng) of the line segment.
///
/// Returns:
/// - The projected point (LatLng) on the line segment.
///
/// Note:
/// - If the start and end points are the same, the function returns the start point.
///
/// Example:
/// ```dart
/// LatLng point = LatLng(37.7749, -122.4194);
/// LatLng startPoint = LatLng(34.0522, -118.2437);
/// LatLng endPoint = LatLng(36.1699, -115.1398);
/// double projectionPoint = projectionPointOnSegment(point, startPoint, endPoint);
/// ```
LatLng projectionPointOnSegment(
    LatLng point, LatLng startPoint, LatLng endPoint) {
  final A = [
    point.latitude - startPoint.latitude,
    point.longitude - startPoint.longitude,
  ];
  final B = [
    endPoint.latitude - startPoint.latitude,
    endPoint.longitude - startPoint.longitude,
  ];
  final bMagnitude = B[0] * B[0] + B[1] * B[1];
  if (bMagnitude == 0) {
    return startPoint;
  }
  final t = max(
    0,
    min(1, (A[0] * B[0] + A[1] * B[1]) / bMagnitude),
  );
  final projectionPoint = LatLng(
    startPoint.latitude + t * B[0],
    startPoint.longitude + t * B[1],
  );
  return projectionPoint;
}

/// Function to calculate the shortest distance from a given point to a line segment defined by two points.
double shortestDistancePointToSegment(
    LatLng point, LatLng startPoint, LatLng endPoint) {
  final projectionPoint = projectionPointOnSegment(point, startPoint, endPoint);
  final shortestDistance = haversine(point, projectionPoint);
  return shortestDistance;
}

/// Function to calculate the accumulated distance along the route
List<double> calculateAccumulatedDistances(List<LatLng> route) {
  List<double> accumulatedDistances = [0.0];
  for (int i = 1; i < route.length; i++) {
    double distance = haversine(route[i - 1], route[i]);
    accumulatedDistances.add(accumulatedDistances.last + distance);
  }
  return accumulatedDistances;
}

/// Function to find the nearest point on the route and the accumulated distance to it
double findClosestPointDistance(
    LatLng point, List<LatLng> route, List<double> accumulatedDistances) {
  double minDistance = double.infinity;
  double closestDistance = 0.0;

  for (int i = 0; i < route.length - 1; i++) {
    var distance =
        shortestDistancePointToSegment(point, route[i], route[i + 1]);
    if (distance < minDistance) {
      minDistance = distance;
      closestDistance = accumulatedDistances[i];
    }
  }
  return closestDistance;
}

/// Function to verify and store accumulated distances from the points in relation to the route
List<Spothole> checkSpotholesAndStoreAccumulatedDistances(
    List<Spothole> spotholes, List<LatLng> route,
    {double tolerance = 5.0}) {
  List<Spothole> spotholesWithinTolerance = [];
  List<double> accumulatedDistances = calculateAccumulatedDistances(route);

  for (var spothole in spotholes) {
    int segmentIndex = 0;
    double minDistance = double.infinity;
    double accumulatedDistance = 0.0;
    late LatLng projectionPoint;

    for (int i = 0; i < route.length - 1; i++) {
      final startPosition = route[i];
      final endPosition = route[i + 1];
      // Calculates the shortest distance from a given point to a line segment defined by two points.
      projectionPoint = projectionPointOnSegment(
          spothole.position, startPosition, endPosition);
      final distance = haversine(spothole.position, projectionPoint);
      if (distance < minDistance) {
        minDistance = distance;
        segmentIndex = i;
      }
    }

    if (minDistance <= tolerance) {
      final projectionDistance =
          haversine(route[segmentIndex], projectionPoint);
      accumulatedDistance =
          accumulatedDistances[segmentIndex] + projectionDistance;
      spothole.distance = accumulatedDistance;
      spotholesWithinTolerance.add(spothole);
    }
  }

  spotholesWithinTolerance.sort((a, b) => a.distance!.compareTo(b.distance!));
  return spotholesWithinTolerance;
}

/// Function to check if a point is within tolerance with respect to a route
bool isPointNearRoute(LatLng point, List<LatLng> route,
    {double tolerance = 5.0}) {
  for (int i = 0; i < route.length - 1; i++) {
    final start = route[i];
    final end = route[i + 1];
    final shortestDistance = shortestDistancePointToSegment(point, start, end);
    if (shortestDistance <= tolerance) {
      return true;
    }
  }
  return false;
}

/// Function to check a list of points
List<bool> arePointsNearRoute(List<LatLng> points, List<LatLng> route,
    {double tolerance = 5.0}) {
  return points
      .map((point) => isPointNearRoute(point, route, tolerance: tolerance))
      .toList();
}
