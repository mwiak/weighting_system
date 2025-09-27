// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrinterConfiguration _$PrinterConfigurationFromJson(
        Map<String, dynamic> json) =>
    PrinterConfiguration(
      printerName: json['printerName'] as String,
      defaultPaperSize:
          PaperSize.fromJson(json['defaultPaperSize'] as Map<String, dynamic>),
      defaultDpi: (json['defaultDpi'] as num).toInt(),
      defaultQuality:
          $enumDecode(_$PrintQualityEnumMap, json['defaultQuality']),
      enableSilentPrinting: json['enableSilentPrinting'] as bool,
      enableFallbackToPdfDialog: json['enableFallbackToPdfDialog'] as bool,
      customSettings: json['customSettings'] as Map<String, dynamic>,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$PrinterConfigurationToJson(
        PrinterConfiguration instance) =>
    <String, dynamic>{
      'printerName': instance.printerName,
      'defaultPaperSize': instance.defaultPaperSize,
      'defaultDpi': instance.defaultDpi,
      'defaultQuality': _$PrintQualityEnumMap[instance.defaultQuality]!,
      'enableSilentPrinting': instance.enableSilentPrinting,
      'enableFallbackToPdfDialog': instance.enableFallbackToPdfDialog,
      'customSettings': instance.customSettings,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

const _$PrintQualityEnumMap = {
  PrintQuality.draft: 'draft',
  PrintQuality.fast: 'fast',
  PrintQuality.normal: 'normal',
  PrintQuality.high: 'high',
};

PrinterPreferences _$PrinterPreferencesFromJson(Map<String, dynamic> json) =>
    PrinterPreferences(
      defaultPrinter: json['defaultPrinter'] as String?,
      printerConfigurations:
          (json['printerConfigurations'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, PrinterConfiguration.fromJson(e as Map<String, dynamic>)),
      ),
      enablePrintQueue: json['enablePrintQueue'] as bool,
      maxQueueSize: (json['maxQueueSize'] as num).toInt(),
      printTimeout:
          Duration(microseconds: (json['printTimeout'] as num).toInt()),
      autoRetryFailedJobs: json['autoRetryFailedJobs'] as bool,
      maxRetryAttempts: (json['maxRetryAttempts'] as num).toInt(),
      enablePrintStatistics: json['enablePrintStatistics'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$PrinterPreferencesToJson(PrinterPreferences instance) =>
    <String, dynamic>{
      'defaultPrinter': instance.defaultPrinter,
      'printerConfigurations': instance.printerConfigurations,
      'enablePrintQueue': instance.enablePrintQueue,
      'maxQueueSize': instance.maxQueueSize,
      'printTimeout': instance.printTimeout.inMicroseconds,
      'autoRetryFailedJobs': instance.autoRetryFailedJobs,
      'maxRetryAttempts': instance.maxRetryAttempts,
      'enablePrintStatistics': instance.enablePrintStatistics,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
