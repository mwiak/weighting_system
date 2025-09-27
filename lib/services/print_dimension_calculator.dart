import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/page_dimensions.dart';
import '../models/windows_printer.dart';

/// Precise dimension calculations for exact-size printing
/// Handles conversions between PDF points, millimeters, inches, and printer pixels
class PrintDimensionCalculator {

  // Standard conversion constants
  static const double pointsPerInch = 72.0;
  static const double mmPerInch = 25.4;
  static const double pointsPerMm = pointsPerInch / mmPerInch; // ~2.834645669

  /// Convert PDF points to millimeters
  static double pointsToMm(double points) {
    return points / pointsPerMm;
  }

  /// Convert millimeters to PDF points
  static double mmToPoints(double mm) {
    return mm * pointsPerMm;
  }

  /// Convert points to inches
  static double pointsToInches(double points) {
    return points / pointsPerInch;
  }

  /// Convert inches to points
  static double inchesToPoints(double inches) {
    return inches * pointsPerInch;
  }

  /// Convert millimeters to inches
  static double mmToInches(double mm) {
    return mm / mmPerInch;
  }

  /// Convert inches to millimeters
  static double inchesToMm(double inches) {
    return inches * mmPerInch;
  }

  /// Convert points to pixels at specific DPI
  static int pointsToPixels(double points, int dpi) {
    final inches = pointsToInches(points);
    return (inches * dpi).round();
  }

  /// Convert pixels to points at specific DPI
  static double pixelsToPoints(int pixels, int dpi) {
    final inches = pixels / dpi;
    return inchesToPoints(inches);
  }

  /// Convert millimeters to pixels at specific DPI
  static int mmToPixels(double mm, int dpi) {
    final inches = mmToInches(mm);
    return (inches * dpi).round();
  }

  /// Convert pixels to millimeters at specific DPI
  static double pixelsToMm(int pixels, int dpi) {
    final inches = pixels / dpi;
    return inchesToMm(inches);
  }

  /// Get optimal DPI for printing a page size on given printer
  static int getOptimalDpi(PageSize pageSize, PrinterCapabilities capabilities) {
    // For templates and precision printing, prefer higher DPI
    if (pageSize.widthMm <= 210 && pageSize.heightMm <= 297) {
      // A4 and smaller - use highest available DPI for precision
      return capabilities.maxDpi;
    }

    // For larger formats, balance quality and memory usage
    final highDpi = capabilities.supportedDpi
        .where((dpi) => dpi >= 600)
        .fold<int?>(null, (prev, curr) => prev == null || curr < prev ? curr : prev);

    return highDpi ?? capabilities.maxDpi;
  }

  /// Calculate print settings for exact-size printing
  static PrintSettings calculateExactSizeSettings(
    PageSize pdfSize,
    WindowsPrinter printer,
    {bool allowScaling = false}
  ) {
    final optimalDpi = getOptimalDpi(pdfSize, printer.capabilities);

    // Check if PDF fits printer's paper sizes without scaling
    final compatiblePaper = printer.getBestPaperSize(pdfSize);

    PageSize targetPaper;
    bool needsScaling = false;

    if (compatiblePaper != null) {
      targetPaper = compatiblePaper;
    } else if (allowScaling && printer.supportedPaperSizes.isNotEmpty) {
      // Use largest available paper and scale
      targetPaper = printer.supportedPaperSizes
          .reduce((a, b) => (a.widthMm * a.heightMm) > (b.widthMm * b.heightMm) ? a : b);
      needsScaling = true;
    } else {
      // Use PDF size as-is (custom paper size)
      targetPaper = pdfSize;
    }

    if (needsScaling && !allowScaling) {
      debugPrint('Warning: PDF size ${pdfSize.toString()} does not fit any printer paper size');
    }

    return PrintSettings(
      pageSize: targetPaper,
      orientation: pdfSize.widthMm > pdfSize.heightMm
          ? Orientation.landscape
          : Orientation.portrait,
      dpi: optimalDpi,
      borderless: printer.capabilities.supportsBorderless,
      margins: printer.capabilities.supportsBorderless
          ? const PrintMargins.zero()
          : printer.capabilities.minimumMargins,
    );
  }

  /// Validate if PDF can be printed at actual size
  static PrintSizeValidation validatePdfSize(
    PageSize pdfSize,
    WindowsPrinter printer,
  ) {
    final bestPaper = printer.getBestPaperSize(pdfSize);

    if (bestPaper != null && bestPaper.matches(pdfSize, toleranceMm: 1.0)) {
      return PrintSizeValidation(
        canPrintActualSize: true,
        recommendedPaper: bestPaper,
        scaleNeeded: 1.0,
        message: 'Perfect match: ${bestPaper.name}',
      );
    }

    if (bestPaper != null && pdfSize.fitsWithin(bestPaper)) {
      return PrintSizeValidation(
        canPrintActualSize: true,
        recommendedPaper: bestPaper,
        scaleNeeded: 1.0,
        message: 'Will print actual size on ${bestPaper.name} with margins',
      );
    }

    // Calculate scaling needed
    final largestPaper = printer.supportedPaperSizes.isNotEmpty
        ? printer.supportedPaperSizes
            .reduce((a, b) => (a.widthMm * a.heightMm) > (b.widthMm * b.heightMm) ? a : b)
        : null;

    if (largestPaper != null) {
      final scaleX = largestPaper.widthMm / pdfSize.widthMm;
      final scaleY = largestPaper.heightMm / pdfSize.heightMm;
      final scale = math.min(scaleX, scaleY);

      return PrintSizeValidation(
        canPrintActualSize: false,
        recommendedPaper: largestPaper,
        scaleNeeded: scale,
        message: 'Requires ${(scale * 100).toStringAsFixed(0)}% scaling on ${largestPaper.name}',
      );
    }

    return PrintSizeValidation(
      canPrintActualSize: false,
      recommendedPaper: null,
      scaleNeeded: 0.0,
      message: 'No compatible paper size found',
    );
  }

  /// Calculate print margins for borderless printing
  static PrintMargins calculateBorderlessMargins(
    PageSize pdfSize,
    PageSize paperSize,
    PrinterCapabilities capabilities,
  ) {
    if (!capabilities.supportsBorderless) {
      return capabilities.minimumMargins;
    }

    // For borderless printing, check if PDF fits exactly
    if (pdfSize.matches(paperSize, toleranceMm: 0.1)) {
      return const PrintMargins.zero();
    }

    // If PDF is smaller, center it with zero margins
    if (pdfSize.fitsWithin(paperSize)) {
      return const PrintMargins.zero();
    }

    // If PDF is larger, use minimum margins and scale
    return capabilities.minimumMargins;
  }

  /// Calculate pixel dimensions for GDI rendering
  static PixelDimensions calculatePixelDimensions(
    PageSize pageSize,
    int dpi,
    {PrintMargins? margins}
  ) {
    final effectiveMargins = margins ?? const PrintMargins.zero();

    final printableWidth = pageSize.widthMm - effectiveMargins.leftMm - effectiveMargins.rightMm;
    final printableHeight = pageSize.heightMm - effectiveMargins.topMm - effectiveMargins.bottomMm;

    return PixelDimensions(
      totalWidthPixels: mmToPixels(pageSize.widthMm, dpi),
      totalHeightPixels: mmToPixels(pageSize.heightMm, dpi),
      printableWidthPixels: mmToPixels(printableWidth, dpi),
      printableHeightPixels: mmToPixels(printableHeight, dpi),
      leftMarginPixels: mmToPixels(effectiveMargins.leftMm, dpi),
      topMarginPixels: mmToPixels(effectiveMargins.topMm, dpi),
      dpi: dpi,
    );
  }

  /// Convert template field coordinates to printer pixels
  static FieldPosition convertFieldPosition(
    double fieldXMm,
    double fieldYMm,
    PixelDimensions printDimensions,
  ) {
    return FieldPosition(
      xPixels: mmToPixels(fieldXMm, printDimensions.dpi) + printDimensions.leftMarginPixels,
      yPixels: mmToPixels(fieldYMm, printDimensions.dpi) + printDimensions.topMarginPixels,
    );
  }

  /// Calculate scaling factor to fit PDF on paper
  static double calculateScaleFactor(PageSize pdfSize, PageSize paperSize) {
    final scaleX = paperSize.widthMm / pdfSize.widthMm;
    final scaleY = paperSize.heightMm / pdfSize.heightMm;
    return math.min(scaleX, scaleY);
  }

  /// Get paper size name for display
  static String getPaperSizeDisplayName(PageSize size) {
    if (size.name.isNotEmpty && size.name != 'Custom') {
      return size.name;
    }

    // Try to match against standard sizes
    for (final standard in [
      PageSize.a3, PageSize.a4, PageSize.a5,
      PageSize.letter, PageSize.legal, PageSize.tabloid
    ]) {
      if (size.matches(standard, toleranceMm: 1.0)) {
        return standard.name;
      }
    }

    return '${size.widthMm.toStringAsFixed(0)}×${size.heightMm.toStringAsFixed(0)}mm';
  }

  /// Check if two page sizes are compatible for printing
  static bool arePageSizesCompatible(PageSize pdf, PageSize paper, {double toleranceMm = 2.0}) {
    return pdf.matches(paper, toleranceMm: toleranceMm) || pdf.fitsWithin(paper);
  }
}

/// Result of print size validation
class PrintSizeValidation {
  final bool canPrintActualSize;
  final PageSize? recommendedPaper;
  final double scaleNeeded;
  final String message;

  const PrintSizeValidation({
    required this.canPrintActualSize,
    required this.recommendedPaper,
    required this.scaleNeeded,
    required this.message,
  });

  bool get requiresScaling => scaleNeeded < 0.99 || scaleNeeded > 1.01;

  @override
  String toString() => message;
}

/// Pixel dimensions for rendering
class PixelDimensions {
  final int totalWidthPixels;
  final int totalHeightPixels;
  final int printableWidthPixels;
  final int printableHeightPixels;
  final int leftMarginPixels;
  final int topMarginPixels;
  final int dpi;

  const PixelDimensions({
    required this.totalWidthPixels,
    required this.totalHeightPixels,
    required this.printableWidthPixels,
    required this.printableHeightPixels,
    required this.leftMarginPixels,
    required this.topMarginPixels,
    required this.dpi,
  });

  @override
  String toString() {
    return '${totalWidthPixels}×${totalHeightPixels}px @ ${dpi}dpi';
  }
}

/// Field position in pixels
class FieldPosition {
  final int xPixels;
  final int yPixels;

  const FieldPosition({
    required this.xPixels,
    required this.yPixels,
  });

  @override
  String toString() => '($xPixels, $yPixels)px';
}