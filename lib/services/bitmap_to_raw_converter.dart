import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/printer_info.dart';
import 'pdf_to_bitmap_converter.dart';

/// Service for converting bitmap data to printer-specific RAW formats
class BitmapToRawConverter {
  static final BitmapToRawConverter _instance = BitmapToRawConverter._internal();
  factory BitmapToRawConverter() => _instance;
  BitmapToRawConverter._internal();

  /// Convert bitmap to printer-specific format
  Future<Uint8List> convertBitmapToPrinterFormat({
    required BitmapPage bitmapPage,
    required PrinterType printerType,
    required PrinterCapabilities capabilities,
    Map<String, dynamic>? settings,
  }) async {
    switch (printerType) {
      case PrinterType.thermal:
        return await _convertToThermalFormat(bitmapPage, settings);
      case PrinterType.laser:
      case PrinterType.inkjet:
        return await _convertToRasterFormat(bitmapPage, settings);
      case PrinterType.dotMatrix:
        return await _convertToDotMatrixFormat(bitmapPage, settings);
      case PrinterType.unknown:
        // Default to Windows BMP format
        return await _convertToWindowsBMPFormat(bitmapPage, settings);
    }
  }

  /// Convert bitmap to thermal printer ESC/POS format
  Future<Uint8List> _convertToThermalFormat(
    BitmapPage bitmapPage,
    Map<String, dynamic>? settings,
  ) async {
    final commands = <int>[];

    try {
      // Decode bitmap
      final image = img.decodeBmp(bitmapPage.bitmap);
      if (image == null) {
        throw Exception('Failed to decode bitmap for thermal conversion');
      }

      // Initialize thermal printer
      commands.addAll(_initializeThermalPrinter(settings));

      // Set print density and speed if specified
      if (settings != null) {
        if (settings.containsKey('density')) {
          commands.addAll(_setThermalDensity(settings['density'] as int));
        }
        if (settings.containsKey('speed')) {
          commands.addAll(_setThermalSpeed(settings['speed'] as int));
        }
      }

      // Convert image to thermal bitmap
      final thermalCommands = await _imageToThermalBitmap(image, settings);
      commands.addAll(thermalCommands);

      // Cut paper if enabled
      final autoCut = settings?['autoCut'] as bool? ?? true;
      if (autoCut) {
        commands.addAll(_addPaperCutCommand(settings));
      }

      return Uint8List.fromList(commands);

    } catch (e) {
      debugPrint('Error converting to thermal format: $e');
      rethrow;
    }
  }

  /// Initialize thermal printer with ESC/POS commands
  List<int> _initializeThermalPrinter(Map<String, dynamic>? settings) {
    final commands = <int>[];

    // ESC @ - Initialize printer
    commands.addAll([0x1B, 0x40]);

    // Set character set to UTF-8 if specified
    final charset = settings?['charset'] as String? ?? 'utf8';
    if (charset == 'utf8') {
      commands.addAll([0x1C, 0x43, 0x01]); // Set UTF-8 mode
    }

    // Set line spacing to minimum for bitmap printing
    commands.addAll([0x1B, 0x33, 0x00]); // ESC 3 n (line spacing = n dots)

    return commands;
  }

  /// Set thermal printer density
  List<int> _setThermalDensity(int density) {
    // GS ( E - Set print density (0-15)
    final clampedDensity = density.clamp(0, 15);
    return [0x1D, 0x28, 0x45, 0x02, 0x00, clampedDensity, 0x00];
  }

  /// Set thermal printer speed
  List<int> _setThermalSpeed(int speed) {
    // Implementation depends on printer model
    // This is a generic approach for speed setting
    final clampedSpeed = speed.clamp(1, 9);
    return [0x1D, 0x28, 0x4B, 0x02, 0x00, 0x32, clampedSpeed];
  }

  /// Convert image to thermal bitmap commands
  Future<List<int>> _imageToThermalBitmap(
    img.Image image,
    Map<String, dynamic>? settings,
  ) async {
    final commands = <int>[];

    try {
      // Get thermal printer width (default 80mm = 576 pixels at 203 DPI)
      final maxWidth = settings?['maxWidth'] as int? ?? 576;

      // Scale image if needed
      final scaledImage = _scaleImageToWidth(image, maxWidth);

      // Convert to monochrome with dithering
      final monoImage = _convertToMonochrome(scaledImage,
        applyDithering: settings?['dithering'] as bool? ?? true);

      // Convert to ESC/POS bitmap format
      commands.addAll(_imageToESCPOSBitmap(monoImage));

    } catch (e) {
      debugPrint('Error converting image to thermal bitmap: $e');
      rethrow;
    }

    return commands;
  }

  /// Convert image to ESC/POS bitmap format
  List<int> _imageToESCPOSBitmap(img.Image image) {
    final commands = <int>[];

    // Calculate dimensions
    final width = image.width;
    final height = image.height;
    final bytesPerLine = (width + 7) ~/ 8; // Round up to nearest byte

    // Use GS v 0 command for bitmap printing
    commands.addAll([0x1D, 0x76, 0x30, 0x00]); // GS v 0 0

    // Width and height in bytes
    commands.addAll([
      bytesPerLine & 0xFF,
      (bytesPerLine >> 8) & 0xFF,
      height & 0xFF,
      (height >> 8) & 0xFF,
    ]);

    // Convert pixels to bitmap data
    for (int y = 0; y < height; y++) {
      for (int xByte = 0; xByte < bytesPerLine; xByte++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final x = xByte * 8 + bit;
          if (x < width) {
            final pixel = image.getPixel(x, y);
            final gray = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
            if (gray < 128) { // Black pixel (inverted for thermal)
              byte |= (1 << (7 - bit));
            }
          }
        }
        commands.add(byte);
      }
    }

    return commands;
  }

  /// Add paper cut command
  List<int> _addPaperCutCommand(Map<String, dynamic>? settings) {
    final cutType = settings?['cutType'] as String? ?? 'full';

    switch (cutType) {
      case 'partial':
        return [0x1B, 0x69]; // ESC i - Partial cut
      case 'full':
      default:
        return [0x1B, 0x64, 0x03, 0x1D, 0x56, 0x00]; // Feed 3 lines + full cut
    }
  }

  /// Convert bitmap to laser/inkjet raster format
  Future<Uint8List> _convertToRasterFormat(
    BitmapPage bitmapPage,
    Map<String, dynamic>? settings,
  ) async {
    try {
      // For laser/inkjet printers, use PCL or PostScript
      final format = settings?['format'] as String? ?? 'pcl';

      switch (format.toLowerCase()) {
        case 'pcl':
          return await _convertToPCLFormat(bitmapPage, settings);
        case 'postscript':
          return await _convertToPostScriptFormat(bitmapPage, settings);
        default:
          // Default to Windows BMP format
          return bitmapPage.bitmap;
      }
    } catch (e) {
      debugPrint('Error converting to raster format: $e');
      return bitmapPage.bitmap;
    }
  }

  /// Convert to PCL (Printer Command Language) format
  Future<Uint8List> _convertToPCLFormat(
    BitmapPage bitmapPage,
    Map<String, dynamic>? settings,
  ) async {
    final commands = <String>[];

    try {
      // PCL Reset
      commands.add('\x1B%-12345X');

      // PCL Job Start
      commands.add('\x1B&l0O'); // Portrait orientation
      commands.add('\x1B&l1A'); // A4 paper (or custom size)

      // Set resolution
      final dpi = bitmapPage.dpi;
      commands.add('\x1B*t${dpi}R'); // Set resolution

      // Raster graphics commands would go here
      // This is a simplified implementation
      commands.add('\x1B*r1A'); // Start raster graphics

      // Insert bitmap data here (simplified)
      commands.add('\x1B*rB'); // End raster graphics

      // PCL Job End
      commands.add('\x1B%-12345X');

      final commandString = commands.join('');
      return Uint8List.fromList(utf8.encode(commandString));

    } catch (e) {
      debugPrint('Error converting to PCL: $e');
      rethrow;
    }
  }

  /// Convert to PostScript format
  Future<Uint8List> _convertToPostScriptFormat(
    BitmapPage bitmapPage,
    Map<String, dynamic>? settings,
  ) async {
    try {
      final psCommands = StringBuffer();

      // PostScript header
      psCommands.writeln('%!PS-Adobe-3.0');
      psCommands.writeln('%%Creator: Flutter Weighing System');
      psCommands.writeln('%%Pages: 1');
      psCommands.writeln('%%EndComments');

      // Set page size
      psCommands.writeln('%%Page: 1 1');
      psCommands.writeln('gsave');

      // Scale and position
      final width = bitmapPage.widthPixels;
      final height = bitmapPage.heightPixels;
      psCommands.writeln('72 ${bitmapPage.dpi} div dup scale'); // Scale to points
      psCommands.writeln('0 $height translate');
      psCommands.writeln('1 -1 scale'); // Flip Y-axis

      // Image command (simplified)
      psCommands.writeln('$width $height 8 [$width 0 0 $height 0 0]');
      psCommands.writeln('{ currentfile 3 string readhexstring pop } bind');
      psCommands.writeln('false 3 colorimage');

      // Add bitmap data as hex (simplified - would need actual conversion)
      psCommands.writeln('% Bitmap data would go here');

      psCommands.writeln('grestore');
      psCommands.writeln('showpage');
      psCommands.writeln('%%EOF');

      return Uint8List.fromList(utf8.encode(psCommands.toString()));

    } catch (e) {
      debugPrint('Error converting to PostScript: $e');
      rethrow;
    }
  }

  /// Convert bitmap to dot matrix format
  Future<Uint8List> _convertToDotMatrixFormat(
    BitmapPage bitmapPage,
    Map<String, dynamic>? settings,
  ) async {
    try {
      final commands = <int>[];

      // Decode bitmap
      final image = img.decodeBmp(bitmapPage.bitmap);
      if (image == null) {
        throw Exception('Failed to decode bitmap for dot matrix conversion');
      }

      // Initialize dot matrix printer
      commands.addAll([0x1B, 0x40]); // ESC @ - Initialize

      // Set graphics mode
      commands.addAll([0x1B, 0x2A, 0x00]); // ESC * - Graphics mode

      // Convert image to dot matrix bitmap
      final dotMatrixData = _imageToDotMatrixBitmap(image);
      commands.addAll(dotMatrixData);

      // End graphics mode
      commands.addAll([0x0D, 0x0A]); // CR LF

      return Uint8List.fromList(commands);

    } catch (e) {
      debugPrint('Error converting to dot matrix format: $e');
      rethrow;
    }
  }

  /// Convert image to dot matrix bitmap
  List<int> _imageToDotMatrixBitmap(img.Image image) {
    final commands = <int>[];

    // Convert to monochrome
    final monoImage = _convertToMonochrome(image, applyDithering: false);

    // Convert to dot matrix format (8-pin or 24-pin)
    // This is a simplified implementation
    for (int y = 0; y < monoImage.height; y += 8) {
      for (int x = 0; x < monoImage.width; x++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          if (y + bit < monoImage.height) {
            final pixel = monoImage.getPixel(x, y + bit);
            final gray = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
            if (gray < 128) {
              byte |= (1 << bit);
            }
          }
        }
        commands.add(byte);
      }
    }

    return commands;
  }

  /// Convert to Windows BMP format (default)
  Future<Uint8List> _convertToWindowsBMPFormat(
    BitmapPage bitmapPage,
    Map<String, dynamic>? settings,
  ) async {
    // Return bitmap as-is (already in BMP format)
    return bitmapPage.bitmap;
  }

  /// Scale image to specified width while maintaining aspect ratio
  img.Image _scaleImageToWidth(img.Image image, int maxWidth) {
    if (image.width <= maxWidth) return image;

    final aspectRatio = image.height / image.width;
    final newHeight = (maxWidth * aspectRatio).round();

    return img.copyResize(image, width: maxWidth, height: newHeight);
  }

  /// Convert image to monochrome
  img.Image _convertToMonochrome(img.Image image, {bool applyDithering = true}) {
    final monoImage = img.Image.from(image);

    if (applyDithering) {
      // Floyd-Steinberg dithering
      for (int y = 0; y < monoImage.height; y++) {
        for (int x = 0; x < monoImage.width; x++) {
          final pixel = monoImage.getPixel(x, y);
          final gray = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);

          final newGray = gray > 128 ? 255 : 0;
          final error = gray - newGray;

          monoImage.setPixel(x, y, img.ColorRgb8(newGray, newGray, newGray));

          // Distribute error to neighboring pixels
          if (x + 1 < monoImage.width) {
            _addDitheringError(monoImage, x + 1, y, error * 7 / 16);
          }
          if (y + 1 < monoImage.height) {
            if (x > 0) {
              _addDitheringError(monoImage, x - 1, y + 1, error * 3 / 16);
            }
            _addDitheringError(monoImage, x, y + 1, error * 5 / 16);
            if (x + 1 < monoImage.width) {
              _addDitheringError(monoImage, x + 1, y + 1, error * 1 / 16);
            }
          }
        }
      }
    } else {
      // Simple threshold
      for (int y = 0; y < monoImage.height; y++) {
        for (int x = 0; x < monoImage.width; x++) {
          final pixel = monoImage.getPixel(x, y);
          final gray = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
          final newGray = gray > 128 ? 255 : 0;
          monoImage.setPixel(x, y, img.ColorRgb8(newGray, newGray, newGray));
        }
      }
    }

    return monoImage;
  }

  /// Add dithering error to pixel
  void _addDitheringError(img.Image image, int x, int y, double error) {
    if (x < 0 || x >= image.width || y < 0 || y >= image.height) return;

    final pixel = image.getPixel(x, y);
    final gray = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
    final newGray = (gray + error).clamp(0, 255).round();
    image.setPixel(x, y, img.ColorRgb8(newGray, newGray, newGray));
  }

  /// Generate ZPL (Zebra Programming Language) commands
  Future<Uint8List> convertToZPL({
    required BitmapPage bitmapPage,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final zplCommands = StringBuffer();

      // ZPL header
      zplCommands.writeln('^XA'); // Start format

      // Set print width and length
      final width = bitmapPage.widthPixels;
      final height = bitmapPage.heightPixels;
      zplCommands.writeln('^PW$width'); // Print width
      zplCommands.writeln('^LL$height'); // Label length

      // Position and print bitmap
      zplCommands.writeln('^FO0,0'); // Field origin
      zplCommands.writeln('^GFA,${bitmapPage.sizeInBytes},$width,$height,'); // Graphic field

      // Convert bitmap to ZPL hex format (simplified)
      final image = img.decodeBmp(bitmapPage.bitmap);
      if (image != null) {
        final hexData = _imageToZPLHex(image);
        zplCommands.write(hexData);
      }

      zplCommands.writeln('^FS'); // Field separator
      zplCommands.writeln('^XZ'); // End format

      return Uint8List.fromList(utf8.encode(zplCommands.toString()));

    } catch (e) {
      debugPrint('Error converting to ZPL: $e');
      rethrow;
    }
  }

  /// Convert image to ZPL hex format
  String _imageToZPLHex(img.Image image) {
    final hexBuffer = StringBuffer();
    final width = image.width;
    final height = image.height;
    final bytesPerLine = (width + 7) ~/ 8;

    for (int y = 0; y < height; y++) {
      for (int xByte = 0; xByte < bytesPerLine; xByte++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final x = xByte * 8 + bit;
          if (x < width) {
            final pixel = image.getPixel(x, y);
            final gray = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
            if (gray < 128) {
              byte |= (1 << (7 - bit));
            }
          }
        }
        hexBuffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
      }
    }

    return hexBuffer.toString();
  }
}