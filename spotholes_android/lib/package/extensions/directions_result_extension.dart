import 'package:google_directions_api/google_directions_api.dart';

extension DirectionsResultExtension on DirectionsResult {
  DirectionsResult copyWith({
    List<DirectionsRoute>? routes,
    List<GeocodedWaypoint>? geocodedWaypoints,
    DirectionsStatus? status,
    String? errorMessage,
    List<TravelMode>? availableTravelModes,
  }) {
    return DirectionsResult(
      routes: routes ?? this.routes,
      geocodedWaypoints: geocodedWaypoints ?? this.geocodedWaypoints,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      availableTravelModes: availableTravelModes ?? this.availableTravelModes,
    );
  }
}
