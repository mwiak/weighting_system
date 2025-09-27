// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_plate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverPlate _$DriverPlateFromJson(Map<String, dynamic> json) => DriverPlate(
      id: (json['id'] as num?)?.toInt(),
      driverId: (json['driverId'] as num).toInt(),
      plateNumber: json['plateNumber'] as String,
      active: json['active'] as bool? ?? true,
      createDate: json['createDate'] == null
          ? null
          : DateTime.parse(json['createDate'] as String),
      writeDate: json['writeDate'] == null
          ? null
          : DateTime.parse(json['writeDate'] as String),
    );

Map<String, dynamic> _$DriverPlateToJson(DriverPlate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driverId': instance.driverId,
      'plateNumber': instance.plateNumber,
      'active': instance.active,
      'createDate': instance.createDate?.toIso8601String(),
      'writeDate': instance.writeDate?.toIso8601String(),
    };
