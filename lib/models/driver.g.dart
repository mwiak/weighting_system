// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Driver _$DriverFromJson(Map<String, dynamic> json) => Driver(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      plateNumbers: (json['plateNumbers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      phone: json['phone'] as String?,
      mobile: json['mobile'] as String?,
      city: json['city'] as String?,
      active: json['active'] as bool? ?? true,
      createDate: json['createDate'] == null
          ? null
          : DateTime.parse(json['createDate'] as String),
      writeDate: json['writeDate'] == null
          ? null
          : DateTime.parse(json['writeDate'] as String),
    );

Map<String, dynamic> _$DriverToJson(Driver instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'plateNumbers': instance.plateNumbers,
      'phone': instance.phone,
      'mobile': instance.mobile,
      'city': instance.city,
      'active': instance.active,
      'createDate': instance.createDate?.toIso8601String(),
      'writeDate': instance.writeDate?.toIso8601String(),
    };
