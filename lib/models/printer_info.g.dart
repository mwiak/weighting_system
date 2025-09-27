// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrinterInfo _$PrinterInfoFromJson(Map<String, dynamic> json) => PrinterInfo(
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      comment: json['comment'] as String?,
      isDefault: json['isDefault'] as bool,
      isOnline: json['isOnline'] as bool,
      type: $enumDecode(_$PrinterTypeEnumMap, json['type']),
      capabilities: PrinterCapabilities.fromJson(
          json['capabilities'] as Map<String, dynamic>),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
    );

Map<String, dynamic> _$PrinterInfoToJson(PrinterInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'location': instance.location,
      'comment': instance.comment,
      'isDefault': instance.isDefault,
      'isOnline': instance.isOnline,
      'type': _$PrinterTypeEnumMap[instance.type]!,
      'capabilities': instance.capabilities,
      'lastSeen': instance.lastSeen.toIso8601String(),
    };

const _$PrinterTypeEnumMap = {
  PrinterType.thermal: 'thermal',
  PrinterType.laser: 'laser',
  PrinterType.inkjet: 'inkjet',
  PrinterType.dotMatrix: 'dotMatrix',
  PrinterType.unknown: 'unknown',
};

PrinterCapabilities _$PrinterCapabilitiesFromJson(Map<String, dynamic> json) =>
    PrinterCapabilities(
      supportsColor: json['supportsColor'] as bool,
      supportsDuplex: json['supportsDuplex'] as bool,
      supportedPaperSizes: (json['supportedPaperSizes'] as List<dynamic>)
          .map((e) => PaperSize.fromJson(e as Map<String, dynamic>))
          .toList(),
      supportedResolutions: (json['supportedResolutions'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      supportsCustomPaperSize: json['supportsCustomPaperSize'] as bool,
      minCustomSize: json['minCustomSize'] == null
          ? null
          : PaperSize.fromJson(json['minCustomSize'] as Map<String, dynamic>),
      maxCustomSize: json['maxCustomSize'] == null
          ? null
          : PaperSize.fromJson(json['maxCustomSize'] as Map<String, dynamic>),
      supportedFormats: (json['supportedFormats'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PrinterCapabilitiesToJson(
        PrinterCapabilities instance) =>
    <String, dynamic>{
      'supportsColor': instance.supportsColor,
      'supportsDuplex': instance.supportsDuplex,
      'supportedPaperSizes': instance.supportedPaperSizes,
      'supportedResolutions': instance.supportedResolutions,
      'supportsCustomPaperSize': instance.supportsCustomPaperSize,
      'minCustomSize': instance.minCustomSize,
      'maxCustomSize': instance.maxCustomSize,
      'supportedFormats': instance.supportedFormats,
    };

PaperSize _$PaperSizeFromJson(Map<String, dynamic> json) => PaperSize(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$PaperSizeToJson(PaperSize instance) => <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'name': instance.name,
    };
