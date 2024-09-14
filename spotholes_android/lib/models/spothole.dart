import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:spotholes_android/utilities/custom_icons.dart';

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
  jagged(text: 'Via Danificada'),
  pothole(text: 'Buraco'),
  deepHole(text: 'Buraco Acentuado');

  final String text;

  const Type({
    required this.text,
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Spothole {
  Spothole(this.dateOfRegister, this.dateOfUpdate, this.position, this.category,
      this.type,
      [this.distance, this.id]);

  DateTime dateOfRegister;
  DateTime dateOfUpdate;
  @JsonKey(fromJson: _latLngFromJson, toJson: _latLngToJson)
  LatLng position;
  Category category;
  Type type;
  @JsonKey(includeToJson: false, includeFromJson: false)
  double? distance;
  @JsonKey(includeToJson: false, includeFromJson: false)
  String? id;

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

  static getImageRiskByType(type) {
    switch (type) {
      case Type.pothole:
        return CustomIcons.riskTypePothole;
      case Type.deepHole:
        return CustomIcons.riskTypeDeepHole;
      case Type.jagged:
        return CustomIcons.riskTypeJagged;
    }
  }

  static getFormattedTimeFromLastUpdate(dateOfUpdate) {
    final now = DateTime.now();
    final difference = now.difference(dateOfUpdate);

    if (difference.inSeconds < 60) {
      return 'menos de um minuto';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutos atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} horas atrás';
    } else if (difference.inDays == 1) {
      return '1 dia atrás';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} dias atrás';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mês' : 'meses'} atrás';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'ano' : 'anos'} atrás';
    }
  }
}
