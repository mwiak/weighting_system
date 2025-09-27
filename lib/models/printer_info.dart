import 'package:json_annotation/json_annotation.dart';

part 'printer_info.g.dart';

@JsonSerializable()
class PrinterInfo {
  final String name;
  final String? description;
  final String? location;
  final String? comment;
  final bool isDefault;
  final bool isOnline;
  final PrinterType type;
  final PrinterCapabilities capabilities;
  final DateTime lastSeen;

  const PrinterInfo({
    required this.name,
    this.description,
    this.location,
    this.comment,
    required this.isDefault,
    required this.isOnline,
    required this.type,
    required this.capabilities,
    required this.lastSeen,
  });

  factory PrinterInfo.fromJson(Map<String, dynamic> json) =>
      _$PrinterInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PrinterInfoToJson(this);

  @override
  String toString() {
    return 'PrinterInfo(name: $name, type: $type, isOnline: $isOnline)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterInfo &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

@JsonSerializable()
class PrinterCapabilities {
  final bool supportsColor;
  final bool supportsDuplex;
  final List<PaperSize> supportedPaperSizes;
  final List<int> supportedResolutions; // DPI values
  final bool supportsCustomPaperSize;
  final PaperSize? minCustomSize;
  final PaperSize? maxCustomSize;
  final List<String> supportedFormats; // RAW, EMF, TEXT, etc.

  const PrinterCapabilities({
    required this.supportsColor,
    required this.supportsDuplex,
    required this.supportedPaperSizes,
    required this.supportedResolutions,
    required this.supportsCustomPaperSize,
    this.minCustomSize,
    this.maxCustomSize,
    required this.supportedFormats,
  });

  factory PrinterCapabilities.fromJson(Map<String, dynamic> json) =>
      _$PrinterCapabilitiesFromJson(json);

  Map<String, dynamic> toJson() => _$PrinterCapabilitiesToJson(this);

  /// Default capabilities for unknown printers
  factory PrinterCapabilities.defaultCapabilities() {
    return const PrinterCapabilities(
      supportsColor: false,
      supportsDuplex: false,
      supportedPaperSizes: [
        PaperSize.a4,
        PaperSize.a3,
        PaperSize.letter,
      ],
      supportedResolutions: [300, 600],
      supportsCustomPaperSize: true,
      supportedFormats: ['RAW', 'EMF'],
    );
  }

  /// Thermal printer capabilities
  factory PrinterCapabilities.thermalPrinter() {
    return const PrinterCapabilities(
      supportsColor: false,
      supportsDuplex: false,
      supportedPaperSizes: [
        PaperSize.thermal58mm,
        PaperSize.thermal80mm,
      ],
      supportedResolutions: [203, 300],
      supportsCustomPaperSize: true,
      minCustomSize: PaperSize.thermal58mm,
      maxCustomSize: PaperSize(width: 112, height: 2000, name: 'Max Thermal'),
      supportedFormats: ['RAW', 'ESC/POS'],
    );
  }
}

enum PrinterType {
  @JsonValue('thermal')
  thermal,
  @JsonValue('laser')
  laser,
  @JsonValue('inkjet')
  inkjet,
  @JsonValue('dotMatrix')
  dotMatrix,
  @JsonValue('unknown')
  unknown,
}

@JsonSerializable()
class PaperSize {
  final double width; // in mm
  final double height; // in mm
  final String name;

  const PaperSize({
    required this.width,
    required this.height,
    required this.name,
  });

  factory PaperSize.fromJson(Map<String, dynamic> json) =>
      _$PaperSizeFromJson(json);

  Map<String, dynamic> toJson() => _$PaperSizeToJson(this);

  // Common paper sizes
  static const PaperSize a4 = PaperSize(width: 210, height: 297, name: 'A4');
  static const PaperSize a3 = PaperSize(width: 297, height: 420, name: 'A3');
  static const PaperSize letter = PaperSize(width: 216, height: 279, name: 'Letter');
  static const PaperSize legal = PaperSize(width: 216, height: 356, name: 'Legal');

  // Thermal paper sizes
  static const PaperSize thermal58mm = PaperSize(width: 58, height: 200, name: '58mm Thermal');
  static const PaperSize thermal80mm = PaperSize(width: 80, height: 200, name: '80mm Thermal');
  static const PaperSize thermal112mm = PaperSize(width: 112, height: 200, name: '112mm Thermal');

  /// Convert to pixels at given DPI
  Size toPixels(int dpi) {
    final widthPixels = (width * dpi / 25.4).round();
    final heightPixels = (height * dpi / 25.4).round();
    return Size(widthPixels.toDouble(), heightPixels.toDouble());
  }

  /// Convert from pixels at given DPI
  factory PaperSize.fromPixels(int widthPixels, int heightPixels, int dpi, String name) {
    final widthMM = widthPixels * 25.4 / dpi;
    final heightMM = heightPixels * 25.4 / dpi;
    return PaperSize(width: widthMM, height: heightMM, name: name);
  }

  @override
  String toString() => '$name (${width}x${height}mm)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperSize &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}

class Size {
  final double width;
  final double height;

  const Size(this.width, this.height);

  @override
  String toString() => 'Size(${width.toStringAsFixed(1)}, ${height.toStringAsFixed(1)})';
}