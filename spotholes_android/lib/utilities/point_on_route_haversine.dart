import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/spothole.dart';

// Function to calculate the Haversine distance between two points
double haversine(LatLng point1, LatLng point2) {
  const R = 6371000; // Earth radius in meters
  final phi1 = point1.latitude * pi / 180;
  final phi2 = point2.latitude * pi / 180;
  final deltaPhi = (point2.latitude - point1.latitude) * pi / 180;
  final deltaLambda = (point2.longitude - point1.longitude) * pi / 180;

  final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
      cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c;
}

// Function to calculate the distance from a point to a line segment
double pointToSegmentDistance(LatLng point, LatLng start, LatLng end) {
  final A = [
    point.latitude - start.latitude,
    point.longitude - start.longitude,
  ];
  final B = [
    end.latitude - start.latitude,
    end.longitude - start.longitude,
  ];
  final bMagnitude = B[0] * B[0] + B[1] * B[1];
  if (bMagnitude == 0) {
    return haversine(point, start);
  }
  final t = max(
    0,
    min(1, (A[0] * B[0] + A[1] * B[1]) / bMagnitude),
  );
  final projection = LatLng(
    start.latitude + t * B[0],
    start.longitude + t * B[1],
  );
  return haversine(point, projection);
}

// Function to calculate the accumulated distance along the route
List<double> calculateAccumulatedDistances(List<LatLng> route) {
  List<double> accumulatedDistances = [0.0];
  for (int i = 1; i < route.length; i++) {
    double distance = haversine(route[i - 1], route[i]);
    accumulatedDistances.add(accumulatedDistances.last + distance);
  }
  return accumulatedDistances;
}

// Function to find the nearest point on the route and the accumulated distance to it
double findClosestPointDistance(
    LatLng point, List<LatLng> route, List<double> accumulatedDistances) {
  double minDistance = double.infinity;
  double closestDistance = 0.0;

  for (int i = 0; i < route.length - 1; i++) {
    double distance = pointToSegmentDistance(point, route[i], route[i + 1]);
    if (distance < minDistance) {
      minDistance = distance;
      closestDistance = accumulatedDistances[i];
    }
  }

  return closestDistance;
}

// Function to verify and store accumulated distances from the points in relation to the route
List<Spothole> checkPointsAndStoreAccumulatedDistances(
    List<Spothole> points, List<LatLng> route,
    {double tolerance = 5.0}) {
  List<Spothole> pointsWithinTolerance = [];
  List<double> accumulatedDistances = calculateAccumulatedDistances(route);

  for (var spothole in points) {
    LatLng point = spothole.position;
    double minDistance = double.infinity;
    double accumulatedDistance = 0.0;

    for (int i = 0; i < route.length - 1; i++) {
      final start = route[i];
      final end = route[i + 1];
      final distance = pointToSegmentDistance(point, start, end);
      if (distance < minDistance) {
        minDistance = distance;
        accumulatedDistance = accumulatedDistances[i];
      }
    }

    if (minDistance <= tolerance) {
      spothole.distance = accumulatedDistance;
      pointsWithinTolerance.add(spothole);
    }
  }

  pointsWithinTolerance.sort((a, b) => a.distance!.compareTo(b.distance!));
  return pointsWithinTolerance;
}

// Function to check if a point is within tolerance with respect to a route
bool isPointNearRoute(LatLng point, List<LatLng> route,
    {double tolerance = 5.0}) {
  for (int i = 0; i < route.length - 1; i++) {
    final start = route[i];
    final end = route[i + 1];
    final distance = pointToSegmentDistance(point, start, end);
    if (distance <= tolerance) {
      return true;
    }
  }
  return false;
}

// Function to check a list of points
List<bool> arePointsNearRoute(List<LatLng> points, List<LatLng> route,
    {double tolerance = 5.0}) {
  return points
      .map((point) => isPointNearRoute(point, route, tolerance: tolerance))
      .toList();
}
