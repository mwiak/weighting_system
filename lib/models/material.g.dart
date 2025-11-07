// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Material _$MaterialFromJson(Map<String, dynamic> json) => Material(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      normalizedName: json['normalizedName'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      description: json['description'] as String?,
      active: json['active'] as bool? ?? true,
      createDate: json['createDate'] == null
          ? null
          : DateTime.parse(json['createDate'] as String),
      writeDate: json['writeDate'] == null
          ? null
          : DateTime.parse(json['writeDate'] as String),
      odooId: (json['odooId'] as num?)?.toInt(),
      syncStatus: (json['syncStatus'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MaterialToJson(Material instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'normalizedName': instance.normalizedName,
      'price': instance.price,
      'description': instance.description,
      'active': instance.active,
      'createDate': instance.createDate?.toIso8601String(),
      'writeDate': instance.writeDate?.toIso8601String(),
      'odooId': instance.odooId,
      'syncStatus': instance.syncStatus,
    };
