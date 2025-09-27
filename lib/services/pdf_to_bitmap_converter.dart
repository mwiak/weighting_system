// import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/printer_info.dart';

/// Service for converting PDF documents to bitmaps for direct printer output
class PDFToBitmapConverter {
  static final PDFToBitmapConverter _instance =
      PDFToBitmapConverter._internal();
  factory PDFToBitmapConverter() => _instance;
  PDFToBitmapConverter._internal();

  /// Convert a PDF document to bitmap images
  Future<List<BitmapPage>> convertPDFToBitmaps({
    required pw.Document pdfDocument,
    required int dpi,
    required PaperSize paperSize,
    bool applyDithering = true,
    bool isMonochrome = true,
  }) async {
    final bitmaps = <BitmapPage>[];

    try {
      // Get PDF bytes
      final pdfBytes = await pdfDocument.save();

      // Calculate target dimensions in pixels
      final targetSize = paperSize.toPixels(dpi);
      final widthPixels = targetSize.width.round();
      final heightPixels = targetSize.height.round();

      // For now, we'll use a simplified approach since pdf package doesn't
      // have built-in rasterization. In production, you might want to use
      // a native PDF rendering library through FFI
      final bitmap = await _renderPDFPageToBitmap(
        pdfBytes,
        widthPixels,
        heightPixels,
        dpi,
        isMonochrome: isMonochrome,
        applyDithering: applyDithering,
      );

      bitmaps.add(BitmapPage(
        pageNumber: 1,
        bitmap: bitmap,
        widthPixels: widthPixels,
        heightPixels: heightPixels,
        dpi: dpi,
      ));
    } catch (e) {
      debugPrint('Error converting PDF to bitmap: $e');
      rethrow;
    }

    return bitmaps;
  }

  /// Render a single PDF page to bitmap
  Future<Uint8List> _renderPDFPageToBitmap(
    Uint8List pdfBytes,
    int widthPixels,
    int heightPixels,
    int dpi, {
    bool isMonochrome = true,
    bool applyDithering = true,
  }) async {
    // Create a placeholder bitmap for now
    // In production, you would use a proper PDF rendering library
    final image = img.Image(width: widthPixels, height: heightPixels);

    // Fill with white background
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    // Add some sample content to demonstrate the concept
    // This would be replaced with actual PDF rendering
    _drawSampleContent(image, widthPixels, heightPixels);

    // Convert to monochrome if needed
    if (isMonochrome) {
      _convertToMonochrome(image, applyDithering);
    }

    // Encode to bitmap format (BMP for Windows compatibility)
    return Uint8List.fromList(img.encodeBmp(image));
  }

  /// Draw sample content (placeholder for actual PDF rendering)
  void _drawSampleContent(img.Image image, int width, int height) {
    // Draw a border
    img.drawRect(
      image,
      x1: 10,
      y1: 10,
      x2: width - 10,
      y2: height - 10,
      color: img.ColorRgb8(0, 0, 0),
    );

    // Draw some text areas (simplified)
    for (int i = 0; i < 5; i++) {
      final y = 30 + (i * 40);
      img.drawRect(
        image,
        x1: 20,
        y1: y,
        x2: width - 20,
        y2: y + 20,
        color: img.ColorRgb8(128, 128, 128),
      );
    }
  }

  /// Convert image to monochrome using Floyd-Steinberg dithering
  void _convertToMonochrome(img.Image image, bool applyDithering) {
    if (applyDithering) {
      // Floyd-Steinberg dithering algorithm
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final gray = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);

          // Quantize to black or white
          final newGray = gray > 128 ? 255 : 0;
          final error = gray - newGray;

          // Set the new pixel value
          image.setPixel(x, y, img.ColorRgb8(newGray, newGray, newGray));

          // Distribute error to neighboring pixels
          if (x + 1 < image.width) {
            _addError(image, x + 1, y, error * 7 / 16);
          }
          if (y + 1 < image.height) {
            if (x > 0) {
              _addError(image, x - 1, y + 1, error * 3 / 16);
            }
            _addError(image, x, y + 1, error * 5 / 16);
            if (x + 1 < image.width) {
              _addError(image, x + 1, y + 1, error * 1 / 16);
            }
          }
        }
      }
    } else {
      // Simple threshold conversion
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final gray = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
          final newGray = gray > 128 ? 255 : 0;
          image.setPixel(x, y, img.ColorRgb8(newGray, newGray, newGray));
        }
      }
    }
  }

  /// Add error to a pixel for dithering
  void _addError(img.Image image, int x, int y, double error) {
    if (x < 0 || x >= image.width || y < 0 || y >= image.height) return;

    final pixel = image.getPixel(x, y);
    final gray = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
    final newGray = (gray + error).clamp(0, 255).round();
    image.setPixel(x, y, img.ColorRgb8(newGray, newGray, newGray));
  }

  /// Convert bitmap to ESC/POS bitmap commands
  List<int> convertBitmapToESCPOS(
    BitmapPage bitmapPage, {
    int maxWidth = 576, // Standard 80mm thermal printer width in pixels
  }) {
    final commands = <int>[];

    try {
      // Decode bitmap
      final image = img.decodeBmp(bitmapPage.bitmap);
      if (image == null) {
        throw Exception('Failed to decode bitmap');
      }

      // Scale image if needed
      final scaledImage = _scaleImageToWidth(image, maxWidth);

      // Convert to ESC/POS bitmap format
      commands.addAll(_imageToESCPOSCommands(scaledImage));
    } catch (e) {
      debugPrint('Error converting bitmap to ESC/POS: $e');
      rethrow;
    }

    return commands;
  }

  /// Scale image to fit within specified width
  img.Image _scaleImageToWidth(img.Image image, int maxWidth) {
    if (image.width <= maxWidth) return image;

    final aspectRatio = image.height / image.width;
    final newHeight = (maxWidth * aspectRatio).round();

    return img.copyResize(image, width: maxWidth, height: newHeight);
  }

  /// Convert image to ESC/POS bitmap commands
  List<int> _imageToESCPOSCommands(img.Image image) {
    final commands = <int>[];

    // ESC/POS bitmap header
    commands.addAll([0x1D, 0x76, 0x30, 0x00]); // GS v 0 0

    // Width and height in bytes
    final widthBytes = (image.width + 7) ~/ 8;
    final heightBytes = image.height;

    commands.addAll([
      widthBytes & 0xFF,
      (widthBytes >> 8) & 0xFF,
      heightBytes & 0xFF,
      (heightBytes >> 8) & 0xFF,
    ]);

    // Convert pixels to bitmap data
    for (int y = 0; y < image.height; y++) {
      for (int xByte = 0; xByte < widthBytes; xByte++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final x = xByte * 8 + bit;
          if (x < image.width) {
            final pixel = image.getPixel(x, y);
            final gray = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
            if (gray < 128) {
              // Black pixel
              byte |= (1 << (7 - bit));
            }
          }
        }
        commands.add(byte);
      }
    }

    return commands;
  }

  /// Convert bitmap to Windows DIB format for GDI printing
  Uint8List convertBitmapToDIB(BitmapPage bitmapPage) {
    try {
      // For Windows GDI printing, we need a Device Independent Bitmap (DIB)
      final image = img.decodeBmp(bitmapPage.bitmap);
      if (image == null) {
        throw Exception('Failed to decode bitmap');
      }

      // Create DIB header and data
      return _createDIBFromImage(image);
    } catch (e) {
      debugPrint('Error converting bitmap to DIB: $e');
      rethrow;
    }
  }

  /// Create DIB (Device Independent Bitmap) from image
  Uint8List _createDIBFromImage(img.Image image) {
    final width = image.width;
    final height = image.height;
    final bytesPerPixel = 3; // 24-bit RGB
    final rowSize = ((width * bytesPerPixel + 3) ~/ 4) * 4; // Align to 4 bytes

    // DIB header (BITMAPINFOHEADER)
    final headerSize = 40;
    final imageSize = rowSize * height;

    final dibData = Uint8List(headerSize + imageSize);
    final byteData = dibData.buffer.asByteData();

    // Fill DIB header
    int offset = 0;
    byteData.setUint32(offset, headerSize, Endian.little);
    offset += 4; // biSize
    byteData.setInt32(offset, width, Endian.little);
    offset += 4; // biWidth
    byteData.setInt32(offset, -height, Endian.little);
    offset += 4; // biHeight (negative for top-down)
    byteData.setUint16(offset, 1, Endian.little);
    offset += 2; // biPlanes
    byteData.setUint16(offset, 24, Endian.little);
    offset += 2; // biBitCount
    byteData.setUint32(offset, 0, Endian.little);
    offset += 4; // biCompression (BI_RGB)
    byteData.setUint32(offset, imageSize, Endian.little);
    offset += 4; // biSizeImage
    byteData.setInt32(offset, 2835, Endian.little);
    offset += 4; // biXPelsPerMeter (72 DPI)
    byteData.setInt32(offset, 2835, Endian.little);
    offset += 4; // biYPelsPerMeter
    byteData.setUint32(offset, 0, Endian.little);
    offset += 4; // biClrUsed
    byteData.setUint32(offset, 0, Endian.little);
    offset += 4; // biClrImportant

    // Fill pixel data (BGR format, bottom-up)
    int dataOffset = headerSize;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        dibData[dataOffset++] = pixel.b.toInt(); // Blue
        dibData[dataOffset++] = pixel.g.toInt(); // Green
        dibData[dataOffset++] = pixel.r.toInt(); // Red
      }
      // Pad row to 4-byte boundary
      while ((dataOffset - headerSize) % 4 != 0) {
        dibData[dataOffset++] = 0;
      }
    }

    return dibData;
  }
}

/// Represents a bitmap page ready for printing
class BitmapPage {
  final int pageNumber;
  final Uint8List bitmap;
  final int widthPixels;
  final int heightPixels;
  final int dpi;

  const BitmapPage({
    required this.pageNumber,
    required this.bitmap,
    required this.widthPixels,
    required this.heightPixels,
    required this.dpi,
  });

  /// Get bitmap size in bytes
  int get sizeInBytes => bitmap.length;

  /// Get aspect ratio
  double get aspectRatio => heightPixels / widthPixels;

  /// Get dimensions in millimeters
  Size get sizeInMM {
    final widthMM = widthPixels * 25.4 / dpi;
    final heightMM = heightPixels * 25.4 / dpi;
    return Size(widthMM, heightMM);
  }

  @override
  String toString() {
    return 'BitmapPage(page: $pageNumber, size: ${widthPixels}x${heightPixels}, dpi: $dpi, bytes: ${sizeInBytes})';
  }
}
