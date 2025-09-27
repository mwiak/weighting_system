// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'truck.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Truck _$TruckFromJson(Map<String, dynamic> json) => Truck(
      id: (json['id'] as num?)?.toInt(),
      plateNumber: json['plateNumber'] as String,
      model: json['model'] as String?,
      capacity: (json['capacity'] as num?)?.toDouble(),
      driverId: (json['driverId'] as num?)?.toInt(),
      active: json['active'] as bool? ?? true,
      createDate: json['createDate'] == null
          ? null
          : DateTime.parse(json['createDate'] as String),
      writeDate: json['writeDate'] == null
          ? null
          : DateTime.parse(json['writeDate'] as String),
    );

Map<String, dynamic> _$TruckToJson(Truck instance) => <String, dynamic>{
      'id': instance.id,
      'plateNumber': instance.plateNumber,
      'model': instance.model,
      'capacity': instance.capacity,
      'driverId': instance.driverId,
      'active': instance.active,
      'createDate': instance.createDate?.toIso8601String(),
      'writeDate': instance.writeDate?.toIso8601String(),
    };
