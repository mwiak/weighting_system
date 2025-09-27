import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';
import '../models/printer_info.dart';
import '../models/print_job.dart';
import '../models/printer_configuration.dart';
import 'pdf_to_bitmap_converter.dart';
import 'bitmap_to_raw_converter.dart';
import 'windows_printer_manager.dart';
import 'spooler_print_engine.dart';

/// Main service for silent printing using Windows Print Spooler APIs
/// Converts PDF to bitmap and prints directly without user dialogs
class WindowsSilentPrintService {
  static final WindowsSilentPrintService _instance = WindowsSilentPrintService._internal();
  factory WindowsSilentPrintService() => _instance;
  WindowsSilentPrintService._internal();

  final _pdfToBitmapConverter = PDFToBitmapConverter();
  final _bitmapToRawConverter = BitmapToRawConverter();
  final _printerManager = WindowsPrinterManager();
  final _spoolerEngine = SpoolerPrintEngine();
  final _uuid = const Uuid();

  // Active print jobs
  final Map<String, PrintJob> _activePrintJobs = {};

  /// Print PDF document silently to specified printer
  Future<PrintJob> printPDFSilently({
    required pw.Document pdfDocument,
    required String printerName,
    String? documentName,
    PaperSize? customPaperSize,
    int? customDpi,
    PrintQuality quality = PrintQuality.normal,
    Map<String, dynamic>? settings,
  }) async {
    final jobId = _uuid.v4();
    documentName ??= 'Silent Print Job';

    // Create print job
    final printJob = PrintJob.create(
      id: jobId,
      printerName: printerName,
      documentName: documentName,
      type: PrintJobType.document,
      totalPages: 1, // PDF documents are single page for this implementation
      metadata: {
        'customPaperSize': customPaperSize?.toJson(),
        'customDpi': customDpi,
        'quality': quality.name,
        'settings': settings,
      },
    );

    _activePrintJobs[jobId] = printJob;

    try {
      // Get printer information
      final printerInfo = await _printerManager.getPrinterByName(printerName);
      if (printerInfo == null) {
        throw PrinterException(
          'Printer "$printerName" not found',
          PrinterErrorType.printerNotFound,
        );
      }

      if (!printerInfo.isOnline) {
        throw PrinterException(
          'Printer "$printerName" is offline',
          PrinterErrorType.printerNotFound,
        );
      }

      // Mark job as started
      _activePrintJobs[jobId] = printJob.markStarted();

      // Determine printing parameters
      final paperSize = customPaperSize ?? _getDefaultPaperSize(printerInfo.type);
      final dpi = customDpi ?? _getDefaultDpi(printerInfo.type, quality);

      // Convert PDF to bitmap
      final bitmaps = await _pdfToBitmapConverter.convertPDFToBitmaps(
        pdfDocument: pdfDocument,
        dpi: dpi,
        paperSize: paperSize,
        applyDithering: _shouldApplyDithering(printerInfo.type),
        isMonochrome: !printerInfo.capabilities.supportsColor,
      );

      if (bitmaps.isEmpty) {
        throw Exception('Failed to convert PDF to bitmap');
      }

      // Print each bitmap page
      for (final bitmap in bitmaps) {
        await _printBitmapPage(
          bitmap: bitmap,
          printerInfo: printerInfo,
          documentName: documentName,
          settings: settings,
        );
      }

      // Mark job as completed
      final completedJob = printJob.markCompleted();
      _activePrintJobs[jobId] = completedJob;
      return completedJob;

    } catch (e) {
      // Mark job as failed
      final failedJob = printJob.markFailed(e.toString());
      _activePrintJobs[jobId] = failedJob;
      debugPrint('Silent printing failed: $e');
      rethrow;
    }
  }

  /// Print bitmap page using appropriate method
  Future<void> _printBitmapPage({
    required BitmapPage bitmap,
    required PrinterInfo printerInfo,
    required String documentName,
    Map<String, dynamic>? settings,
  }) async {
    try {
      switch (printerInfo.type) {
        case PrinterType.thermal:
          await _printThermalBitmap(bitmap, printerInfo, documentName, settings);
          break;
        case PrinterType.laser:
        case PrinterType.inkjet:
          await _printRasterBitmap(bitmap, printerInfo, documentName, settings);
          break;
        case PrinterType.dotMatrix:
          await _printDotMatrixBitmap(bitmap, printerInfo, documentName, settings);
          break;
        case PrinterType.unknown:
          await _printGenericBitmap(bitmap, printerInfo, documentName, settings);
          break;
      }
    } catch (e) {
      debugPrint('Error printing bitmap page: $e');
      rethrow;
    }
  }

  /// Print to thermal printer using ESC/POS commands
  Future<void> _printThermalBitmap(
    BitmapPage bitmap,
    PrinterInfo printerInfo,
    String documentName,
    Map<String, dynamic>? settings,
  ) async {
    try {
      // Convert bitmap to ESC/POS format
      final escPosData = await _bitmapToRawConverter.convertBitmapToPrinterFormat(
        bitmapPage: bitmap,
        printerType: PrinterType.thermal,
        capabilities: printerInfo.capabilities,
        settings: {
          'maxWidth': 576, // 80mm thermal printer width
          'dithering': true,
          'autoCut': settings?['autoCut'] ?? true,
          'density': settings?['density'] ?? 8,
          'speed': settings?['speed'] ?? 5,
          ...?settings,
        },
      );

      // Send raw data to printer
      final success = await _spoolerEngine.printRawData(
        printerName: printerInfo.name,
        data: escPosData,
        documentName: documentName,
        dataType: 'RAW',
      );

      if (!success) {
        throw Exception('Failed to send thermal data to printer');
      }

    } catch (e) {
      debugPrint('Error printing thermal bitmap: $e');
      rethrow;
    }
  }

  /// Print to laser/inkjet printer using GDI
  Future<void> _printRasterBitmap(
    BitmapPage bitmap,
    PrinterInfo printerInfo,
    String documentName,
    Map<String, dynamic>? settings,
  ) async {
    try {
      // Convert bitmap to DIB format for GDI
      final dibData = _pdfToBitmapConverter.convertBitmapToDIB(bitmap);

      // Use GDI printing for better quality on office printers
      final success = await _spoolerEngine.printBitmapWithGDI(
        printerName: printerInfo.name,
        dibData: dibData,
        documentName: documentName,
        customPaperSize: PaperSize.fromPixels(
          bitmap.widthPixels,
          bitmap.heightPixels,
          bitmap.dpi,
          'Custom',
        ),
      );

      if (!success) {
        throw Exception('Failed to print bitmap with GDI');
      }

    } catch (e) {
      debugPrint('Error printing raster bitmap: $e');
      rethrow;
    }
  }

  /// Print to dot matrix printer
  Future<void> _printDotMatrixBitmap(
    BitmapPage bitmap,
    PrinterInfo printerInfo,
    String documentName,
    Map<String, dynamic>? settings,
  ) async {
    try {
      // Convert bitmap to dot matrix format
      final dotMatrixData = await _bitmapToRawConverter.convertBitmapToPrinterFormat(
        bitmapPage: bitmap,
        printerType: PrinterType.dotMatrix,
        capabilities: printerInfo.capabilities,
        settings: settings,
      );

      // Send raw data to printer
      final success = await _spoolerEngine.printRawData(
        printerName: printerInfo.name,
        data: dotMatrixData,
        documentName: documentName,
        dataType: 'RAW',
      );

      if (!success) {
        throw Exception('Failed to send dot matrix data to printer');
      }

    } catch (e) {
      debugPrint('Error printing dot matrix bitmap: $e');
      rethrow;
    }
  }

  /// Print to generic/unknown printer using Windows BMP
  Future<void> _printGenericBitmap(
    BitmapPage bitmap,
    PrinterInfo printerInfo,
    String documentName,
    Map<String, dynamic>? settings,
  ) async {
    try {
      // Use DIB format for generic printers
      final dibData = _pdfToBitmapConverter.convertBitmapToDIB(bitmap);

      final success = await _spoolerEngine.printBitmapWithGDI(
        printerName: printerInfo.name,
        dibData: dibData,
        documentName: documentName,
      );

      if (!success) {
        throw Exception('Failed to print generic bitmap');
      }

    } catch (e) {
      debugPrint('Error printing generic bitmap: $e');
      rethrow;
    }
  }

  /// Get default paper size for printer type
  PaperSize _getDefaultPaperSize(PrinterType printerType) {
    switch (printerType) {
      case PrinterType.thermal:
        return PaperSize.thermal80mm;
      case PrinterType.laser:
      case PrinterType.inkjet:
      case PrinterType.dotMatrix:
      case PrinterType.unknown:
        return PaperSize.a4;
    }
  }

  /// Get default DPI for printer type and quality
  int _getDefaultDpi(PrinterType printerType, PrintQuality quality) {
    switch (printerType) {
      case PrinterType.thermal:
        return 203; // Standard thermal printer DPI
      case PrinterType.laser:
        switch (quality) {
          case PrintQuality.draft:
            return 300;
          case PrintQuality.fast:
            return 300;
          case PrintQuality.normal:
            return 600;
          case PrintQuality.high:
            return 1200;
        }
      case PrinterType.inkjet:
        switch (quality) {
          case PrintQuality.draft:
            return 150;
          case PrintQuality.fast:
            return 300;
          case PrintQuality.normal:
            return 600;
          case PrintQuality.high:
            return 1200;
        }
      case PrinterType.dotMatrix:
        return 180; // Typical dot matrix DPI
      case PrinterType.unknown:
        return 300; // Safe default
    }
  }

  /// Check if dithering should be applied
  bool _shouldApplyDithering(PrinterType printerType) {
    switch (printerType) {
      case PrinterType.thermal:
      case PrinterType.dotMatrix:
        return true; // Monochrome printers benefit from dithering
      case PrinterType.laser:
      case PrinterType.inkjet:
      case PrinterType.unknown:
        return false; // Color/grayscale printers handle dithering internally
    }
  }

  /// Get list of available printers
  Future<List<PrinterInfo>> getAvailablePrinters({bool forceRefresh = false}) async {
    return await _printerManager.getAvailablePrinters(forceRefresh: forceRefresh);
  }

  /// Get default printer
  Future<PrinterInfo?> getDefaultPrinter() async {
    return await _printerManager.getDefaultPrinter();
  }

  /// Check if printer supports silent printing
  Future<bool> supportssilentPrinting(String printerName) async {
    try {
      final printer = await _printerManager.getPrinterByName(printerName);
      if (printer == null) return false;

      // Check if printer is online and accessible
      return printer.isOnline &&
             await _printerManager.isPrinterOnline(printerName);
    } catch (e) {
      debugPrint('Error checking silent printing support: $e');
      return false;
    }
  }

  /// Test print a small bitmap to verify printer functionality
  Future<bool> testPrint(String printerName) async {
    try {
      // Create a small test bitmap
      final testPdf = pw.Document();
      testPdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(100, 50), // Small test page
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text('Test Print', style: pw.TextStyle(fontSize: 12)),
            );
          },
        ),
      );

      // Print test document
      final job = await printPDFSilently(
        pdfDocument: testPdf,
        printerName: printerName,
        documentName: 'Test Print',
        customPaperSize: const PaperSize(width: 35, height: 18, name: 'Test'),
      );

      return job.status == PrintJobStatus.completed;

    } catch (e) {
      debugPrint('Test print failed: $e');
      return false;
    }
  }

  /// Get active print jobs
  List<PrintJob> getActivePrintJobs() {
    return _activePrintJobs.values.where((job) => job.isInProgress).toList();
  }

  /// Get print job by ID
  PrintJob? getPrintJob(String jobId) {
    return _activePrintJobs[jobId];
  }

  /// Cancel print job
  Future<bool> cancelPrintJob(String jobId) async {
    final job = _activePrintJobs[jobId];
    if (job == null || job.isFinished) return false;

    try {
      // Cancel job in Windows print spooler
      // Note: This requires additional Windows API calls to get the actual job ID
      // For now, we'll mark it as cancelled locally
      _activePrintJobs[jobId] = job.markCancelled();
      return true;
    } catch (e) {
      debugPrint('Error cancelling print job: $e');
      return false;
    }
  }

  /// Clear completed print jobs from memory
  void clearCompletedJobs() {
    _activePrintJobs.removeWhere((key, job) => job.isFinished);
  }

  /// Get printer status
  Future<PrinterStatus> getPrinterStatus(String printerName) async {
    return await _spoolerEngine.getPrinterStatus(printerName);
  }

  /// Print ZPL format (for Zebra printers)
  Future<PrintJob> printZPL({
    required BitmapPage bitmap,
    required String printerName,
    String? documentName,
    Map<String, dynamic>? settings,
  }) async {
    final jobId = _uuid.v4();
    documentName ??= 'ZPL Print Job';

    final printJob = PrintJob.create(
      id: jobId,
      printerName: printerName,
      documentName: documentName,
      type: PrintJobType.template,
      totalPages: 1,
    );

    _activePrintJobs[jobId] = printJob.markStarted();

    try {
      // Convert bitmap to ZPL format
      final zplData = await _bitmapToRawConverter.convertToZPL(
        bitmapPage: bitmap,
        settings: settings,
      );

      // Send ZPL data to printer
      final success = await _spoolerEngine.printRawData(
        printerName: printerName,
        data: zplData,
        documentName: documentName,
        dataType: 'RAW',
      );

      if (!success) {
        throw Exception('Failed to send ZPL data to printer');
      }

      final completedJob = printJob.markCompleted();
      _activePrintJobs[jobId] = completedJob;
      return completedJob;

    } catch (e) {
      final failedJob = printJob.markFailed(e.toString());
      _activePrintJobs[jobId] = failedJob;
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _activePrintJobs.clear();
  }
}