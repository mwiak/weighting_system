// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Client _$ClientFromJson(Map<String, dynamic> json) => Client(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      normalizedName: json['normalizedName'] as String?,
      phone: json['phone'] as String?,
      mobile: json['mobile'] as String?,
      city: json['city'] as String?,
      active: json['active'] as bool? ?? true,
      createDate: json['createDate'] as String?,
      writeDate: json['writeDate'] as String?,
      odooId: (json['odooId'] as num?)?.toInt(),
      syncStatus: (json['syncStatus'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ClientToJson(Client instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'normalizedName': instance.normalizedName,
      'phone': instance.phone,
      'mobile': instance.mobile,
      'city': instance.city,
      'active': instance.active,
      'createDate': instance.createDate,
      'writeDate': instance.writeDate,
      'odooId': instance.odooId,
      'syncStatus': instance.syncStatus,
    };
