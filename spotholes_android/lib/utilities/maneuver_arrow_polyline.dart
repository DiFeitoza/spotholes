import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

double haversineDistance(LatLng point1, LatLng point2) {
  /// Earth's radius in meters
  const double earthRadius = 6371000;
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

      /// Insert midpoint into list
      points.insert(i + 1, midpoint);
      ///Return the midpoint index
      return i + 1;
    }
    accumulatedDistance += segmentDistance;
  }

  /// If the accumulated distance is exactly half
  return points.length - 1;
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

  /// If the accumulated distance is exactly half
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

  /// Add the midpoint
  segment.add(midpoint);

  /// Calculate points after midpoint
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
