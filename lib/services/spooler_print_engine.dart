import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';
import '../models/printer_info.dart';
import '../models/print_job.dart';

// Define missing Win32 constants
const int DM_PAPERSIZE = 0x00000002;
const int DM_PAPERLENGTH = 0x00000004;
const int DM_PAPERWIDTH = 0x00000008;
const int DM_PRINTQUALITY = 0x00000400;
const int DM_YRESOLUTION = 0x00002000;
const int DM_IN_BUFFER = 8;
const int DM_OUT_BUFFER = 2;

// Printer status constants
const int PRINTER_STATUS_OFFLINE = 0x00000080;
const int PRINTER_STATUS_ERROR = 0x00000002;
const int PRINTER_STATUS_PAPER_OUT = 0x00000010;
const int PRINTER_STATUS_BUSY = 0x00000200;

// Job control constants
const int JOB_CONTROL_CANCEL = 3;

/// Core engine for Windows Print Spooler API operations
class SpoolerPrintEngine {
  static final SpoolerPrintEngine _instance = SpoolerPrintEngine._internal();
  factory SpoolerPrintEngine() => _instance;
  SpoolerPrintEngine._internal();

  /// Print raw data directly to printer using Windows Print Spooler
  Future<bool> printRawData({
    required String printerName,
    required Uint8List data,
    required String documentName,
    String dataType = 'RAW',
    PaperSize? customPaperSize,
    int? customDpi,
  }) async {
    final pPrinterName = printerName.toNativeUtf16();
    final hPrinter = calloc<HANDLE>();

    try {
      // Open the printer
      final openResult = OpenPrinter(pPrinterName, hPrinter, nullptr);
      if (openResult == 0) {
        final error = GetLastError();
        throw PrinterException(
          'Failed to open printer "$printerName". Error: $error',
          PrinterErrorType.printerNotFound,
        );
      }

      // Configure printer settings if custom paper size or DPI specified
      if (customPaperSize != null || customDpi != null) {
        await _configurePrinterSettings(
          hPrinter.value,
          customPaperSize: customPaperSize,
          customDpi: customDpi,
        );
      }

      // Create document info
      final docInfo = calloc<DOC_INFO_1>();
      final pDocName = documentName.toNativeUtf16();
      final pDataType = dataType.toNativeUtf16();

      docInfo.ref.pDocName = pDocName;
      docInfo.ref.pOutputFile = nullptr;
      docInfo.ref.pDatatype = pDataType;

      // Start the document
      final startDocResult = StartDocPrinter(hPrinter.value, 1, docInfo.cast());
      if (startDocResult == 0) {
        final error = GetLastError();
        throw PrinterException(
          'Failed to start document. Error: $error',
          PrinterErrorType.documentStartFailed,
        );
      }

      // Start the page
      final startPageResult = StartPagePrinter(hPrinter.value);
      if (startPageResult == 0) {
        final error = GetLastError();
        EndDocPrinter(hPrinter.value);
        throw PrinterException(
          'Failed to start page. Error: $error',
          PrinterErrorType.pageStartFailed,
        );
      }

      // Write data to printer
      final success = await _writeDataToPrinter(hPrinter.value, data);

      // End the page
      EndPagePrinter(hPrinter.value);

      // End the document
      EndDocPrinter(hPrinter.value);

      // Cleanup
      calloc.free(pDocName);
      calloc.free(pDataType);
      calloc.free(docInfo);

      return success;

    } catch (e) {
      debugPrint('Error in printRawData: $e');
      rethrow;
    } finally {
      if (hPrinter.value != 0) {
        ClosePrinter(hPrinter.value);
      }
      calloc.free(hPrinter);
      calloc.free(pPrinterName);
    }
  }

  /// Write data to printer in chunks
  Future<bool> _writeDataToPrinter(int hPrinter, Uint8List data) async {
    const chunkSize = 8192; // 8KB chunks
    final totalBytes = data.length;
    int bytesWritten = 0;

    final lpBytes = malloc.allocate<BYTE>(chunkSize);
    final pcWritten = calloc<DWORD>();

    try {
      while (bytesWritten < totalBytes) {
        final remainingBytes = totalBytes - bytesWritten;
        final currentChunkSize = remainingBytes > chunkSize ? chunkSize : remainingBytes;

        // Copy data to native buffer
        final chunk = data.sublist(bytesWritten, bytesWritten + currentChunkSize);
        lpBytes.asTypedList(currentChunkSize).setAll(0, chunk);

        // Write chunk to printer
        final result = WritePrinter(
          hPrinter,
          lpBytes,
          currentChunkSize,
          pcWritten,
        );

        if (result == 0) {
          final error = GetLastError();
          throw PrinterException(
            'Failed to write data to printer. Error: $error',
            PrinterErrorType.writeDataFailed,
          );
        }

        final actualWritten = pcWritten.value;
        if (actualWritten != currentChunkSize) {
          throw PrinterException(
            'Partial write: expected $currentChunkSize, written $actualWritten',
            PrinterErrorType.writeDataFailed,
          );
        }

        bytesWritten += actualWritten;

        // Optional: Add a small delay for slower printers
        if (remainingBytes > chunkSize) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      return true;

    } catch (e) {
      debugPrint('Error writing data to printer: $e');
      rethrow;
    } finally {
      malloc.free(lpBytes);
      calloc.free(pcWritten);
    }
  }

  /// Configure printer settings (DEVMODE)
  Future<void> _configurePrinterSettings(
    int hPrinter, {
    PaperSize? customPaperSize,
    int? customDpi,
  }) async {
    try {
      // Get current printer configuration
      final pcbNeeded = calloc<DWORD>();
      GetPrinter(hPrinter, 2, nullptr, 0, pcbNeeded);

      final bufferSize = pcbNeeded.value;
      if (bufferSize == 0) {
        calloc.free(pcbNeeded);
        return; // Cannot get printer info
      }

      final buffer = calloc<Uint8>(bufferSize);
      final success = GetPrinter(hPrinter, 2, buffer.cast(), bufferSize, pcbNeeded);

      if (success == 0) {
        calloc.free(buffer);
        calloc.free(pcbNeeded);
        return;
      }

      final printerInfo = Pointer<PRINTER_INFO_2>.fromAddress(buffer.address).ref;
      if (printerInfo.pDevMode == nullptr) {
        calloc.free(buffer);
        calloc.free(pcbNeeded);
        return;
      }

      // Modify DEVMODE structure
      final devMode = printerInfo.pDevMode.ref;
      bool modified = false;

      // Set custom paper size
      if (customPaperSize != null) {
        devMode.dmPaperSize = 256; // DMPAPER_USER constant value
        devMode.dmPaperWidth = (customPaperSize.width * 10).round(); // Width in 0.1mm units
        devMode.dmPaperLength = (customPaperSize.height * 10).round(); // Height in 0.1mm units
        devMode.dmFields |= DM_PAPERSIZE | DM_PAPERLENGTH | DM_PAPERWIDTH;
        modified = true;
      }

      // Set custom DPI
      if (customDpi != null) {
        devMode.dmPrintQuality = customDpi;
        devMode.dmYResolution = customDpi;
        devMode.dmFields |= DM_PRINTQUALITY | DM_YRESOLUTION;
        modified = true;
      }

      // Apply changes if any modifications were made
      if (modified) {
        final setResult = DocumentProperties(
          0, // hwnd
          hPrinter,
          nullptr, // printer name
          printerInfo.pDevMode,
          printerInfo.pDevMode,
          DM_IN_BUFFER | DM_OUT_BUFFER,
        );

        if (setResult < 0) {
          debugPrint('Failed to set printer properties: $setResult');
        }
      }

      calloc.free(buffer);
      calloc.free(pcbNeeded);

    } catch (e) {
      debugPrint('Error configuring printer settings: $e');
    }
  }

  /// Print bitmap data using Windows GDI (currently disabled due to compilation issues)
  Future<bool> printBitmapWithGDI({
    required String printerName,
    required Uint8List dibData,
    required String documentName,
    PaperSize? customPaperSize,
  }) async {
    // TODO: Implement GDI printing when win32 package supports required APIs
    debugPrint('GDI printing not yet implemented - falling back to RAW printing');
    return false;
  }

  /// Draw bitmap to GDI device context (currently disabled)
  Future<bool> _drawBitmapToGDI(
    int hDC,
    Uint8List dibData,
    PaperSize? customPaperSize,
  ) async {
    // TODO: Implement when GDI APIs are available
    debugPrint('GDI bitmap drawing not implemented');
    return false;
  }

  /// Get printer status
  Future<PrinterStatus> getPrinterStatus(String printerName) async {
    final pPrinterName = printerName.toNativeUtf16();
    final hPrinter = calloc<HANDLE>();

    try {
      final openResult = OpenPrinter(pPrinterName, hPrinter, nullptr);
      if (openResult == 0) {
        return PrinterStatus.notFound;
      }

      final pcbNeeded = calloc<DWORD>();
      GetPrinter(hPrinter.value, 2, nullptr, 0, pcbNeeded);

      final bufferSize = pcbNeeded.value;
      if (bufferSize == 0) {
        ClosePrinter(hPrinter.value);
        calloc.free(pcbNeeded);
        return PrinterStatus.unknown;
      }

      final buffer = calloc<Uint8>(bufferSize);
      final success = GetPrinter(hPrinter.value, 2, buffer.cast(), bufferSize, pcbNeeded);

      if (success != 0) {
        final printerInfo = Pointer<PRINTER_INFO_2>.fromAddress(buffer.address).ref;
        final status = printerInfo.Status;

        PrinterStatus printerStatus;
        if ((status & PRINTER_STATUS_OFFLINE) != 0) {
          printerStatus = PrinterStatus.offline;
        } else if ((status & PRINTER_STATUS_ERROR) != 0) {
          printerStatus = PrinterStatus.error;
        } else if ((status & PRINTER_STATUS_PAPER_OUT) != 0) {
          printerStatus = PrinterStatus.paperOut;
        } else if ((status & PRINTER_STATUS_BUSY) != 0) {
          printerStatus = PrinterStatus.busy;
        } else {
          printerStatus = PrinterStatus.ready;
        }

        calloc.free(buffer);
        ClosePrinter(hPrinter.value);
        calloc.free(pcbNeeded);
        return printerStatus;
      }

      calloc.free(buffer);
      calloc.free(pcbNeeded);
      ClosePrinter(hPrinter.value);

    } catch (e) {
      debugPrint('Error getting printer status: $e');
    } finally {
      calloc.free(hPrinter);
      calloc.free(pPrinterName);
    }

    return PrinterStatus.unknown;
  }

  /// Cancel print job
  Future<bool> cancelPrintJob(String printerName, int jobId) async {
    final pPrinterName = printerName.toNativeUtf16();
    final hPrinter = calloc<HANDLE>();

    try {
      final openResult = OpenPrinter(pPrinterName, hPrinter, nullptr);
      if (openResult == 0) {
        return false;
      }

      final result = SetJob(hPrinter.value, jobId, 0, nullptr, JOB_CONTROL_CANCEL);
      ClosePrinter(hPrinter.value);

      return result != 0;

    } catch (e) {
      debugPrint('Error cancelling print job: $e');
      return false;
    } finally {
      calloc.free(hPrinter);
      calloc.free(pPrinterName);
    }
  }
}

/// Printer status enumeration
enum PrinterStatus {
  ready,
  busy,
  error,
  offline,
  paperOut,
  notFound,
  unknown,
}

/// Printer error types
enum PrinterErrorType {
  printerNotFound,
  deviceContextFailed,
  documentStartFailed,
  pageStartFailed,
  writeDataFailed,
  configurationFailed,
  unknown,
}

/// Custom exception for printer operations
class PrinterException implements Exception {
  final String message;
  final PrinterErrorType type;
  final int? errorCode;

  const PrinterException(this.message, this.type, [this.errorCode]);

  @override
  String toString() {
    return 'PrinterException($type): $message${errorCode != null ? ' (Error: $errorCode)' : ''}';
  }
}