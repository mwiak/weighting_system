import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';
import '../models/printer_info.dart';

// Define missing Win32 paper size constants
const int DMPAPER_A4 = 9;
const int DMPAPER_A3 = 8;
const int DMPAPER_LETTER = 1;
const int DMPAPER_LEGAL = 5;

// Printer status constants
const int PRINTER_STATUS_OFFLINE = 0x00000080;
const int PRINTER_STATUS_ERROR = 0x00000002;
const int PRINTER_STATUS_PAPER_OUT = 0x00000010;

// Device capabilities constants
const int DC_PAPERS = 2;
const int DC_PAPERNAMES = 16;
const int DC_ENUMRESOLUTIONS = 13;

/// Service for managing Windows printers and their capabilities
class WindowsPrinterManager {
  static final WindowsPrinterManager _instance = WindowsPrinterManager._internal();
  factory WindowsPrinterManager() => _instance;
  WindowsPrinterManager._internal();

  List<PrinterInfo>? _cachedPrinters;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Get list of available printers
  Future<List<PrinterInfo>> getAvailablePrinters({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid()) {
      return _cachedPrinters!;
    }

    try {
      final printers = await _enumeratePrinters();
      _cachedPrinters = printers;
      _lastCacheUpdate = DateTime.now();
      return printers;
    } catch (e) {
      debugPrint('Error enumerating printers: $e');
      return _cachedPrinters ?? [];
    }
  }

  /// Get default printer
  Future<PrinterInfo?> getDefaultPrinter() async {
    try {
      final defaultPrinterName = _getDefaultPrinterName();
      if (defaultPrinterName == null) return null;

      final printers = await getAvailablePrinters();
      return printers.firstWhere(
        (printer) => printer.name == defaultPrinterName,
        orElse: () => throw StateError('Default printer not found'),
      );
    } catch (e) {
      debugPrint('Error getting default printer: $e');
      return null;
    }
  }

  /// Get printer by name
  Future<PrinterInfo?> getPrinterByName(String name) async {
    try {
      final printers = await getAvailablePrinters();
      return printers.firstWhere(
        (printer) => printer.name == name,
        orElse: () => throw StateError('Printer not found'),
      );
    } catch (e) {
      debugPrint('Printer "$name" not found: $e');
      return null;
    }
  }

  /// Check if printer is online and available
  Future<bool> isPrinterOnline(String printerName) async {
    try {
      final printer = await getPrinterByName(printerName);
      return printer?.isOnline ?? false;
    } catch (e) {
      debugPrint('Error checking printer status: $e');
      return false;
    }
  }

  /// Get printer capabilities
  Future<PrinterCapabilities> getPrinterCapabilities(String printerName) async {
    try {
      return await _queryPrinterCapabilities(printerName);
    } catch (e) {
      debugPrint('Error getting printer capabilities for $printerName: $e');
      return PrinterCapabilities.defaultCapabilities();
    }
  }

  /// Detect printer type based on name and capabilities
  PrinterType _detectPrinterType(String printerName, String? description) {
    final nameLower = printerName.toLowerCase();
    final descLower = description?.toLowerCase() ?? '';

    // Thermal printer detection
    if (nameLower.contains('thermal') ||
        nameLower.contains('receipt') ||
        nameLower.contains('pos') ||
        nameLower.contains('zebra') ||
        nameLower.contains('citizen') ||
        nameLower.contains('epson tm') ||
        descLower.contains('thermal') ||
        descLower.contains('receipt')) {
      return PrinterType.thermal;
    }

    // Laser printer detection
    if (nameLower.contains('laser') ||
        nameLower.contains('hp laserjet') ||
        nameLower.contains('canon lbp') ||
        nameLower.contains('brother hl') ||
        descLower.contains('laser')) {
      return PrinterType.laser;
    }

    // Inkjet printer detection
    if (nameLower.contains('inkjet') ||
        nameLower.contains('hp deskjet') ||
        nameLower.contains('hp officejet') ||
        nameLower.contains('canon pixma') ||
        nameLower.contains('epson stylus') ||
        descLower.contains('inkjet')) {
      return PrinterType.inkjet;
    }

    // Dot matrix detection
    if (nameLower.contains('dot matrix') ||
        nameLower.contains('impact') ||
        nameLower.contains('epson lq') ||
        nameLower.contains('oki microline')) {
      return PrinterType.dotMatrix;
    }

    return PrinterType.unknown;
  }

  /// Enumerate all printers using Windows API
  Future<List<PrinterInfo>> _enumeratePrinters() async {
    final printers = <PrinterInfo>[];

    final pcbNeeded = calloc<DWORD>();
    final pcReturned = calloc<DWORD>();

    try {
      // First call to get required buffer size
      EnumPrinters(
        PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS,
        nullptr,
        2, // PRINTER_INFO_2
        nullptr,
        0,
        pcbNeeded,
        pcReturned,
      );

      final bufferSize = pcbNeeded.value;
      if (bufferSize == 0) {
        return printers; // No printers found
      }

      // Allocate buffer and get printer info
      final buffer = calloc<Uint8>(bufferSize);
      final success = EnumPrinters(
        PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS,
        nullptr,
        2, // PRINTER_INFO_2
        buffer.cast(),
        bufferSize,
        pcbNeeded,
        pcReturned,
      );

      if (success != 0) {
        final printerCount = pcReturned.value;
        final printerInfoSize = sizeOf<PRINTER_INFO_2>();

        for (int i = 0; i < printerCount; i++) {
          final printerInfo = Pointer<PRINTER_INFO_2>.fromAddress(
            buffer.address + (i * printerInfoSize)
          ).ref;

          final name = printerInfo.pPrinterName.toDartString();
          final description = printerInfo.pComment?.toDartString();
          final location = printerInfo.pLocation?.toDartString();

          // Check if printer is online
          final isOnline = await _checkPrinterStatus(name);
          final isDefault = _isDefaultPrinter(name);
          final printerType = _detectPrinterType(name, description);
          final capabilities = await _queryPrinterCapabilities(name);

          printers.add(PrinterInfo(
            name: name,
            description: description,
            location: location,
            comment: printerInfo.pComment?.toDartString(),
            isDefault: isDefault,
            isOnline: isOnline,
            type: printerType,
            capabilities: capabilities,
            lastSeen: DateTime.now(),
          ));
        }
      }

      calloc.free(buffer);
    } catch (e) {
      debugPrint('Error in _enumeratePrinters: $e');
    } finally {
      calloc.free(pcbNeeded);
      calloc.free(pcReturned);
    }

    return printers;
  }

  /// Get default printer name
  String? _getDefaultPrinterName() {
    final pcchBuffer = calloc<DWORD>();
    pcchBuffer.value = 0;

    // First call to get required buffer size
    GetDefaultPrinter(nullptr, pcchBuffer);

    final bufferSize = pcchBuffer.value;
    if (bufferSize == 0) {
      calloc.free(pcchBuffer);
      return null;
    }

    final buffer = calloc<Uint16>(bufferSize);
    final success = GetDefaultPrinter(buffer.cast(), pcchBuffer);

    String? defaultPrinter;
    if (success != 0) {
      defaultPrinter = buffer.cast<Utf16>().toDartString();
    }

    calloc.free(buffer);
    calloc.free(pcchBuffer);

    return defaultPrinter;
  }

  /// Check if printer name matches default printer
  bool _isDefaultPrinter(String printerName) {
    final defaultName = _getDefaultPrinterName();
    return defaultName != null && defaultName == printerName;
  }

  /// Check printer status
  Future<bool> _checkPrinterStatus(String printerName) async {
    final pPrinterName = printerName.toNativeUtf16();
    final hPrinter = calloc<HANDLE>();

    try {
      // Try to open the printer
      final result = OpenPrinter(pPrinterName, hPrinter, nullptr);
      if (result == 0) {
        return false; // Printer not accessible
      }

      // Get printer status
      final pcbNeeded = calloc<DWORD>();
      final success = GetPrinter(hPrinter.value, 2, nullptr, 0, pcbNeeded);

      final bufferSize = pcbNeeded.value;
      if (bufferSize > 0) {
        final buffer = calloc<Uint8>(bufferSize);
        final getResult = GetPrinter(
          hPrinter.value,
          2,
          buffer.cast(),
          bufferSize,
          pcbNeeded,
        );

        if (getResult != 0) {
          final printerInfo = Pointer<PRINTER_INFO_2>.fromAddress(
            buffer.address
          ).ref;

          // Check printer status flags
          final status = printerInfo.Status;
          final isOnline = (status & PRINTER_STATUS_OFFLINE) == 0 &&
                          (status & PRINTER_STATUS_ERROR) == 0 &&
                          (status & PRINTER_STATUS_PAPER_OUT) == 0;

          calloc.free(buffer);
          ClosePrinter(hPrinter.value);
          calloc.free(pcbNeeded);
          calloc.free(hPrinter);
          calloc.free(pPrinterName);

          return isOnline;
        }

        calloc.free(buffer);
      }

      calloc.free(pcbNeeded);
      ClosePrinter(hPrinter.value);
    } catch (e) {
      debugPrint('Error checking printer status for $printerName: $e');
    } finally {
      calloc.free(hPrinter);
      calloc.free(pPrinterName);
    }

    return false;
  }

  /// Query printer capabilities
  Future<PrinterCapabilities> _queryPrinterCapabilities(String printerName) async {
    try {
      final pPrinterName = printerName.toNativeUtf16();
      final hPrinter = calloc<HANDLE>();

      final result = OpenPrinter(pPrinterName, hPrinter, nullptr);
      if (result == 0) {
        calloc.free(pPrinterName);
        calloc.free(hPrinter);
        return PrinterCapabilities.defaultCapabilities();
      }

      // Get device capabilities
      final capabilities = await _getDeviceCapabilities(hPrinter.value, printerName);

      ClosePrinter(hPrinter.value);
      calloc.free(hPrinter);
      calloc.free(pPrinterName);

      return capabilities;
    } catch (e) {
      debugPrint('Error querying capabilities for $printerName: $e');
      return PrinterCapabilities.defaultCapabilities();
    }
  }

  /// Get device capabilities using simplified detection
  Future<PrinterCapabilities> _getDeviceCapabilities(int hPrinter, String printerName) async {
    try {
      final pDevice = printerName.toNativeUtf16();

      // TODO: DeviceCapabilities API not available in current win32 package
      // Using simplified capabilities detection for now

      // Provide default paper sizes based on printer type
      final printerType = _detectPrinterType(printerName, '');
      final paperSizes = <PaperSize>[];
      final resolutions = <int>[];

      if (printerType == PrinterType.thermal) {
        paperSizes.addAll([PaperSize.thermal80mm, PaperSize.thermal58mm]);
        resolutions.addAll([203, 300]);
      } else {
        paperSizes.addAll([PaperSize.a4, PaperSize.a3, PaperSize.letter, PaperSize.legal]);
        resolutions.addAll([300, 600, 1200]);
      }

      calloc.free(pDevice);

      return printerType == PrinterType.thermal
          ? PrinterCapabilities.thermalPrinter()
          : PrinterCapabilities(
              supportsColor: printerType != PrinterType.dotMatrix,
              supportsDuplex: printerType == PrinterType.laser,
              supportedPaperSizes: paperSizes,
              supportedResolutions: resolutions,
              supportsCustomPaperSize: true,
              supportedFormats: ['RAW', 'EMF'],
            );

    } catch (e) {
      debugPrint('Error getting device capabilities: $e');
      return PrinterCapabilities.defaultCapabilities();
    }
  }

  /// Convert Windows paper ID to PaperSize
  PaperSize? _convertWindowsPaperIdToSize(int paperId, String paperName) {
    switch (paperId) {
      case DMPAPER_A4:
        return PaperSize.a4;
      case DMPAPER_A3:
        return PaperSize.a3;
      case DMPAPER_LETTER:
        return PaperSize.letter;
      case DMPAPER_LEGAL:
        return PaperSize.legal;
      default:
        // For unknown paper types, try to parse the name
        if (paperName.toLowerCase().contains('a4')) return PaperSize.a4;
        if (paperName.toLowerCase().contains('a3')) return PaperSize.a3;
        if (paperName.toLowerCase().contains('letter')) return PaperSize.letter;
        if (paperName.toLowerCase().contains('80')) return PaperSize.thermal80mm;
        if (paperName.toLowerCase().contains('58')) return PaperSize.thermal58mm;
        return null;
    }
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    return _cachedPrinters != null &&
           _lastCacheUpdate != null &&
           DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  /// Clear printer cache
  void clearCache() {
    _cachedPrinters = null;
    _lastCacheUpdate = null;
  }

  /// Set default printer
  Future<bool> setDefaultPrinter(String printerName) async {
    try {
      final pPrinterName = printerName.toNativeUtf16();
      final result = SetDefaultPrinter(pPrinterName);
      calloc.free(pPrinterName);

      if (result != 0) {
        clearCache(); // Clear cache to refresh default printer status
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error setting default printer: $e');
      return false;
    }
  }

  /// Test printer connectivity
  Future<bool> testPrinterConnection(String printerName) async {
    try {
      final isOnline = await isPrinterOnline(printerName);
      if (!isOnline) return false;

      // Try to open and close the printer
      final pPrinterName = printerName.toNativeUtf16();
      final hPrinter = calloc<HANDLE>();

      final result = OpenPrinter(pPrinterName, hPrinter, nullptr);
      if (result != 0) {
        ClosePrinter(hPrinter.value);
        calloc.free(hPrinter);
        calloc.free(pPrinterName);
        return true;
      }

      calloc.free(hPrinter);
      calloc.free(pPrinterName);
      return false;
    } catch (e) {
      debugPrint('Error testing printer connection: $e');
      return false;
    }
  }
}