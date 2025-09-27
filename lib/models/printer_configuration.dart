import 'package:json_annotation/json_annotation.dart';
import 'printer_info.dart';

part 'printer_configuration.g.dart';

@JsonSerializable()
class PrinterConfiguration {
  final String printerName;
  final PaperSize defaultPaperSize;
  final int defaultDpi;
  final PrintQuality defaultQuality;
  final bool enableSilentPrinting;
  final bool enableFallbackToPdfDialog;
  final Map<String, dynamic> customSettings;
  final DateTime lastUpdated;

  const PrinterConfiguration({
    required this.printerName,
    required this.defaultPaperSize,
    required this.defaultDpi,
    required this.defaultQuality,
    required this.enableSilentPrinting,
    required this.enableFallbackToPdfDialog,
    required this.customSettings,
    required this.lastUpdated,
  });

  factory PrinterConfiguration.fromJson(Map<String, dynamic> json) =>
      _$PrinterConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$PrinterConfigurationToJson(this);

  /// Create default configuration for a printer
  factory PrinterConfiguration.defaultForPrinter(
    String printerName,
    PrinterType type,
  ) {
    PaperSize paperSize;
    int dpi;
    PrintQuality quality;

    switch (type) {
      case PrinterType.thermal:
        paperSize = PaperSize.thermal80mm;
        dpi = 203;
        quality = PrintQuality.fast;
        break;
      case PrinterType.laser:
      case PrinterType.inkjet:
        paperSize = PaperSize.a4;
        dpi = 300;
        quality = PrintQuality.normal;
        break;
      case PrinterType.dotMatrix:
        paperSize = PaperSize.a4;
        dpi = 180;
        quality = PrintQuality.draft;
        break;
      case PrinterType.unknown:
        paperSize = PaperSize.a4;
        dpi = 300;
        quality = PrintQuality.normal;
        break;
    }

    return PrinterConfiguration(
      printerName: printerName,
      defaultPaperSize: paperSize,
      defaultDpi: dpi,
      defaultQuality: quality,
      enableSilentPrinting: true,
      enableFallbackToPdfDialog: true,
      customSettings: {},
      lastUpdated: DateTime.now(),
    );
  }

  /// Copy with new values
  PrinterConfiguration copyWith({
    PaperSize? defaultPaperSize,
    int? defaultDpi,
    PrintQuality? defaultQuality,
    bool? enableSilentPrinting,
    bool? enableFallbackToPdfDialog,
    Map<String, dynamic>? customSettings,
  }) {
    return PrinterConfiguration(
      printerName: printerName,
      defaultPaperSize: defaultPaperSize ?? this.defaultPaperSize,
      defaultDpi: defaultDpi ?? this.defaultDpi,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      enableSilentPrinting: enableSilentPrinting ?? this.enableSilentPrinting,
      enableFallbackToPdfDialog: enableFallbackToPdfDialog ?? this.enableFallbackToPdfDialog,
      customSettings: customSettings ?? Map.from(this.customSettings),
      lastUpdated: DateTime.now(),
    );
  }

  /// Update custom setting
  PrinterConfiguration updateCustomSetting(String key, dynamic value) {
    final newSettings = Map<String, dynamic>.from(customSettings);
    newSettings[key] = value;
    return copyWith(customSettings: newSettings);
  }

  /// Remove custom setting
  PrinterConfiguration removeCustomSetting(String key) {
    final newSettings = Map<String, dynamic>.from(customSettings);
    newSettings.remove(key);
    return copyWith(customSettings: newSettings);
  }

  /// Get custom setting with default value
  T? getCustomSetting<T>(String key, [T? defaultValue]) {
    final value = customSettings[key];
    if (value is T) return value;
    return defaultValue;
  }

  @override
  String toString() {
    return 'PrinterConfiguration(printer: $printerName, paper: $defaultPaperSize, dpi: $defaultDpi)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterConfiguration &&
          runtimeType == other.runtimeType &&
          printerName == other.printerName;

  @override
  int get hashCode => printerName.hashCode;
}

enum PrintQuality {
  @JsonValue('draft')
  draft,
  @JsonValue('fast')
  fast,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
}

@JsonSerializable()
class PrinterPreferences {
  final String? defaultPrinter;
  final Map<String, PrinterConfiguration> printerConfigurations;
  final bool enablePrintQueue;
  final int maxQueueSize;
  final Duration printTimeout;
  final bool autoRetryFailedJobs;
  final int maxRetryAttempts;
  final bool enablePrintStatistics;
  final DateTime lastUpdated;

  const PrinterPreferences({
    this.defaultPrinter,
    required this.printerConfigurations,
    required this.enablePrintQueue,
    required this.maxQueueSize,
    required this.printTimeout,
    required this.autoRetryFailedJobs,
    required this.maxRetryAttempts,
    required this.enablePrintStatistics,
    required this.lastUpdated,
  });

  factory PrinterPreferences.fromJson(Map<String, dynamic> json) =>
      _$PrinterPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$PrinterPreferencesToJson(this);

  /// Create default preferences
  factory PrinterPreferences.defaults() {
    return PrinterPreferences(
      defaultPrinter: null,
      printerConfigurations: {},
      enablePrintQueue: true,
      maxQueueSize: 100,
      printTimeout: const Duration(minutes: 5),
      autoRetryFailedJobs: true,
      maxRetryAttempts: 3,
      enablePrintStatistics: true,
      lastUpdated: DateTime.now(),
    );
  }

  /// Copy with new values
  PrinterPreferences copyWith({
    String? defaultPrinter,
    Map<String, PrinterConfiguration>? printerConfigurations,
    bool? enablePrintQueue,
    int? maxQueueSize,
    Duration? printTimeout,
    bool? autoRetryFailedJobs,
    int? maxRetryAttempts,
    bool? enablePrintStatistics,
  }) {
    return PrinterPreferences(
      defaultPrinter: defaultPrinter ?? this.defaultPrinter,
      printerConfigurations: printerConfigurations ?? Map.from(this.printerConfigurations),
      enablePrintQueue: enablePrintQueue ?? this.enablePrintQueue,
      maxQueueSize: maxQueueSize ?? this.maxQueueSize,
      printTimeout: printTimeout ?? this.printTimeout,
      autoRetryFailedJobs: autoRetryFailedJobs ?? this.autoRetryFailedJobs,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      enablePrintStatistics: enablePrintStatistics ?? this.enablePrintStatistics,
      lastUpdated: DateTime.now(),
    );
  }

  /// Add or update printer configuration
  PrinterPreferences updatePrinterConfiguration(PrinterConfiguration config) {
    final newConfigs = Map<String, PrinterConfiguration>.from(printerConfigurations);
    newConfigs[config.printerName] = config;
    return copyWith(printerConfigurations: newConfigs);
  }

  /// Remove printer configuration
  PrinterPreferences removePrinterConfiguration(String printerName) {
    final newConfigs = Map<String, PrinterConfiguration>.from(printerConfigurations);
    newConfigs.remove(printerName);

    // Clear default printer if it was removed
    String? newDefaultPrinter = defaultPrinter;
    if (defaultPrinter == printerName) {
      newDefaultPrinter = newConfigs.keys.isNotEmpty ? newConfigs.keys.first : null;
    }

    return copyWith(
      printerConfigurations: newConfigs,
      defaultPrinter: newDefaultPrinter,
    );
  }

  /// Get configuration for a printer
  PrinterConfiguration? getConfigurationForPrinter(String printerName) {
    return printerConfigurations[printerName];
  }

  /// Get configuration for a printer or create default
  PrinterConfiguration getOrCreateConfiguration(String printerName, PrinterType type) {
    return printerConfigurations[printerName] ??
           PrinterConfiguration.defaultForPrinter(printerName, type);
  }

  /// Set default printer
  PrinterPreferences setDefaultPrinter(String printerName) {
    return copyWith(defaultPrinter: printerName);
  }

  /// Get all configured printer names
  List<String> get configuredPrinters => printerConfigurations.keys.toList();

  /// Check if printer is configured
  bool isPrinterConfigured(String printerName) {
    return printerConfigurations.containsKey(printerName);
  }
}