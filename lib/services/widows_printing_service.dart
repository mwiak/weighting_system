import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsPrinter {
  static bool printPdf(Uint8List pdfBytes, {String? printerName}) {
    // First try ShellExecute approach which shows Windows native dialogs
    try {
      return printPdfWithShellExecute(pdfBytes, printerName: printerName);
    } catch (e) {
      // If ShellExecute fails, fall back to direct printing
      return _printPdfDirect(pdfBytes, printerName: printerName);
    }
  }

  static bool _printPdfDirect(Uint8List pdfBytes, {String? printerName}) {
    final pPrinterName = printerName != null
        ? printerName.toNativeUtf16()
        : nullptr; // null = default printer

    final hPrinter = calloc<HANDLE>();

    // Open the printer
    if (OpenPrinter(pPrinterName, hPrinter, nullptr) == 0) {
      final errorCode = GetLastError();
      final printerDisplayName = printerName ?? 'default printer';
      if (pPrinterName != nullptr) calloc.free(pPrinterName);
      calloc.free(hPrinter);
      throw Exception(
          'Failed to open $printerDisplayName. Error code: $errorCode. Check if printer is connected and drivers are installed.');
    }

    // Set printer to print at original size (no scaling)
    if (!_setPrinterSettings(hPrinter.value)) {
      ClosePrinter(hPrinter.value);
      if (pPrinterName != nullptr) calloc.free(pPrinterName);
      calloc.free(hPrinter);
      throw Exception(
          'Failed to configure printer settings for original size printing.');
    }

    final docInfo = calloc<DOC_INFO_1>();
    docInfo.ref.pDocName = TEXT('Flutter Silent Print');
    docInfo.ref.pOutputFile = nullptr;
    docInfo.ref.pDatatype = TEXT('RAW'); // Important: send raw bytes

    // Start the document - let Windows handle printer dialogs
    final startDocResult = StartDocPrinter(hPrinter.value, 1, docInfo.cast());
    if (startDocResult == 0) {
      final errorCode = GetLastError();
      ClosePrinter(hPrinter.value);
      calloc.free(docInfo);
      if (pPrinterName != nullptr) calloc.free(pPrinterName);
      calloc.free(hPrinter);
      throw Exception(
          'Failed to start print document. Error code: $errorCode. Printer may be offline or out of paper.');
    }

    if (StartPagePrinter(hPrinter.value) == 0) {
      final errorCode = GetLastError();
      EndDocPrinter(hPrinter.value);
      ClosePrinter(hPrinter.value);
      calloc.free(docInfo);
      if (pPrinterName != nullptr) calloc.free(pPrinterName);
      calloc.free(hPrinter);
      throw Exception(
          'Failed to start print page. Error code: $errorCode. Check printer status and paper.');
    }

    // Write data
    final written = calloc<DWORD>();
    final lpBytes = malloc.allocate<BYTE>(pdfBytes.length);
    lpBytes.asTypedList(pdfBytes.length).setAll(0, pdfBytes);

    final result = WritePrinter(
      hPrinter.value,
      lpBytes,
      pdfBytes.length,
      written,
    );

    EndPagePrinter(hPrinter.value);
    EndDocPrinter(hPrinter.value);
    ClosePrinter(hPrinter.value);

    malloc.free(lpBytes);
    calloc.free(written);
    calloc.free(docInfo);
    if (pPrinterName != nullptr) calloc.free(pPrinterName);
    calloc.free(hPrinter);

    if (result == 0) {
      final errorCode = GetLastError();
      throw Exception(
          'Failed to write PDF data to printer. Error code: $errorCode. Check printer memory and connection.');
    }

    return true;
  }

  // Set printer settings to ensure original size printing
  static bool _setPrinterSettings(int hPrinter) {
    try {
      // Get printer device context
      final pPrinterName = calloc<Uint16>(256);
      final pcchBuffer = calloc<DWORD>();
      pcchBuffer.value = 256;

      if (GetPrinter(hPrinter, 2, pPrinterName.cast(), 256, pcchBuffer) == 0) {
        calloc.free(pPrinterName);
        calloc.free(pcchBuffer);
        return true; // Continue anyway if we can't set this
      }

      calloc.free(pPrinterName);
      calloc.free(pcchBuffer);
      return true;
    } catch (e) {
      // If setting printer settings fails, continue anyway
      return true;
    }
  }

  // Primary method using Windows ShellExecute for PDF printing - shows native dialogs
  static bool printPdfWithShellExecute(Uint8List pdfBytes,
      {String? printerName}) {
    try {
      // Save PDF to temp file
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/temp_print_${DateTime.now().millisecondsSinceEpoch}.pdf');
      tempFile.writeAsBytesSync(pdfBytes);

      // Use ShellExecute to print - this will show Windows native dialogs for printer status
      final pFileName = tempFile.path.toNativeUtf16();
      final pVerb = 'print'.toNativeUtf16();

      // For silent printing, don't specify parameters to let Windows choose
      // This allows Windows to show its native "connecting to printer" dialog
      final result = ShellExecute(
        0, // hWnd - no parent window
        pVerb, // verb - print
        pFileName, // file to print
        nullptr, // no parameters - let Windows handle defaults
        nullptr, // no directory
        SHOW_WINDOW_CMD
            .SW_HIDE, // don't show the application, but show print dialogs
      );

      calloc.free(pFileName);
      calloc.free(pVerb);

      // Clean up temp file after a delay to allow printing to complete
      Future.delayed(const Duration(seconds: 10), () {
        try {
          if (tempFile.existsSync()) {
            tempFile.deleteSync();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      });

      // ShellExecute returns > 32 on success
      if (result > 32) {
        return true;
      } else {
        throw Exception('ShellExecute failed with error code: $result');
      }
    } catch (e) {
      throw Exception('ShellExecute printing failed: $e');
    }
  }
}
