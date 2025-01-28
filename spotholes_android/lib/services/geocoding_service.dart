import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingService {
  GeocodingService._();
  static final GeocodingService _instance = GeocodingService._();
  static GeocodingService get instance => _instance;

  String formattedPlacemark(Placemark placemark) {
    final parts = [
      placemark.street,
      placemark.locality,
      placemark.subLocality,
      placemark.subAdministrativeArea,
      placemark.country,
    ].where((part) => part != '');

    String formatted = parts.join(', ');

    if (placemark.postalCode != null) {
      formatted += ' - ${placemark.postalCode}';
    }
    return formatted;
  }

  Future<Placemark> getFirstPlacemarkFromLatLng(LatLng latLng) async {
    try {
      return await placemarkFromCoordinates(latLng.latitude, latLng.longitude)
          .then((placeMarks) => placeMarks.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getFirstPlacemarkFormattedFromLatLng(LatLng latLng) async {
    return await getFirstPlacemarkFromLatLng(latLng)
        .then((placemark) => formattedPlacemark(placemark));
  }

  Future<List<String>> getFormattedPlacemarksFromLatLng(LatLng latLng) async {
    try {
      final placemarkList =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      final formattedList = placemarkList
          .map((placemark) => formattedPlacemark(placemark))
          .toList();
      return formattedList;
    } catch (e) {
      rethrow;
    }
  }
}
