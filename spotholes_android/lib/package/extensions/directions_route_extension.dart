import 'package:google_directions_api/google_directions_api.dart';

extension DirectionsRouteExtension on DirectionsRoute {
  DirectionsRoute copyWith({
    List<Leg>? legs,
    GeoCoordBounds? bounds,
    String? copyrights,
    OverviewPolyline? overviewPolyline,
    String? summary,
    List<String?>? warnings,
    List<num?>? waypointOrder,
    final Fare? fare,
  }) {
    return DirectionsRoute(
      bounds: bounds ?? this.bounds,
      copyrights: copyrights ?? this.copyrights,
      legs: legs ?? this.legs,
      overviewPolyline: overviewPolyline ?? this.overviewPolyline,
      summary: summary ?? this.summary,
      warnings: warnings ?? this.warnings,
      waypointOrder: waypointOrder ?? this.waypointOrder,
      fare: fare ?? this.fare,
    );
  }
}
