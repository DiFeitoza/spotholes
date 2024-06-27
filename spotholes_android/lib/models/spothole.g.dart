// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spothole.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Spothole _$SpotholeFromJson(Map<String, dynamic> json) => Spothole(
      DateTime.parse(json['date_of_register'] as String),
      DateTime.parse(json['date_of_update'] as String),
      Spothole._latLngFromJson(json['position'] as Map),
      $enumDecode(_$CategoryEnumMap, json['category']),
      $enumDecode(_$TypeEnumMap, json['type']),
    );

Map<String, dynamic> _$SpotholeToJson(Spothole instance) => <String, dynamic>{
      'date_of_register': instance.dateOfRegister.toIso8601String(),
      'date_of_update': instance.dateOfUpdate.toIso8601String(),
      'position': Spothole._latLngToJson(instance.position),
      'category': _$CategoryEnumMap[instance.category]!,
      'type': _$TypeEnumMap[instance.type]!,
    };

const _$CategoryEnumMap = {
  Category.strech: 'strech',
  Category.unitary: 'unitary',
};

const _$TypeEnumMap = {
  Type.jagged: 'jagged',
  Type.pothole: 'pothole',
  Type.deepHole: 'deepHole',
};
