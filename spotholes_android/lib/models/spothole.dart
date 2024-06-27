import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'spothole.g.dart';

enum Category {
  strech(text: 'Trecho esburacado'),
  unitary(text: 'Buraco');

  final String text;

  const Category({
    required this.text,
  });
}

enum Type {
  jagged(text: 'Via de trafego irregular'),
  pothole(text: 'Buraco'),
  deepHole(text: 'Buraco acentuado');

  final String text;

  const Type({
    required this.text,
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Spothole {
  Spothole(this.dateOfRegister, this.dateOfUpdate, this.position, this.category,
      this.type);

  DateTime dateOfRegister;
  DateTime dateOfUpdate;
  @JsonKey(fromJson: _latLngFromJson, toJson: _latLngToJson)
  LatLng position;
  Category category;
  Type type;

  factory Spothole.fromJson(Map<String, dynamic> json) =>
      _$SpotholeFromJson(json);

  Map<String, dynamic> toJson() => _$SpotholeToJson(this);

  static LatLng _latLngFromJson(Map json) {
    return LatLng(json['latitude'], json['longitude']);
  }

  static Map<String, dynamic> _latLngToJson(LatLng latLng) {
    return {
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
    };
  }
}
