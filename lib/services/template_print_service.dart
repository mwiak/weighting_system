import 'dart:io';
import 'dart:typed_data';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';
import 'package:weighing_system/services/widows_printing_service.dart';
import 'package:weighing_system/services/xps.dart';
// import 'package:weighing_system/services/windows_native_print_service.dart'; // Disabled
import 'package:weighing_system/utils/debugging_methods.dart';
import '../models/print_template.dart';
import '../models/weighing_tab.dart';
import '../models/client.dart';
import '../models/supplier.dart';
import '../models/material.dart';
import '../models/printer_info.dart';
import '../models/print_job.dart';
import 'windows_silent_print_service.dart';
import 'pdf_to_bitmap_converter.dart';
import 'custom_template_service.dart';
import 'package:file_picker/file_picker.dart' as fp;

/// Service for printing on pre-printed forms using templates
class TemplatePrintService {
  static final TemplatePrintService _instance =
      TemplatePrintService._internal();

  factory TemplatePrintService() => _instance;

  TemplatePrintService._internal();

  // Cache for Unicode font
  pw.Font? _unicodeFont;

  // Silent printing service
  final _silentPrintService = WindowsSilentPrintService();

  // PDF to bitmap converter
  final _pdfToBitmapConverter = PDFToBitmapConverter();

  // Windows-native printing service
  // final _nativePrintService = WindowsNativePrintService(); // Disabled

  // Paper sizes in mm
  static const Map<String, PdfPageFormat> paperSizes = {
    'A3': PdfPageFormat.a3,
    'A4': PdfPageFormat.a4,
    'A5': PdfPageFormat.a5,
    'Letter': PdfPageFormat.letter,
    'Legal': PdfPageFormat.legal,
  };

  /// Print WeighingTab data on pre-printed form using template
  Future<PrintJob?> printWithTemplate(
    BuildContext context, {
    required PrintTemplate template,
    required WeighingTab weighingTab,
    Client? client,
    Supplier? supplier,
    Material? material,
    String? printerName,
    bool preview = false,
    bool useDialog = false,
    bool silentPrint = false,
  }) async {
    if (silentPrint && printerName != null) {
      // Use silent printing with exact template dimensions
      try {
        return await _printTemplateSilently(
            template, weighingTab, client, supplier, material, printerName);
      } catch (e) {
        debugPrint(
            'Silent template printing failed, falling back to dialog: $e');
        // Fall through to dialog printing
      }
    }

    if (preview || useDialog) {
      // Use legacy PDF preview for dialog-based printing
      await _printWithDialog(template, weighingTab, client, supplier, material);
    } else {
      // Use standard Flutter printing (Windows-native disabled)
      try {
        await _printWithDialog(
            template, weighingTab, client, supplier, material);
      } catch (e) {
        debugPrint('Printing failed, trying legacy method: $e');
        // Fallback to legacy PDF method
        await _printWithLegacyMethod(
            template, weighingTab, client, supplier, material, printerName);
      }
    }
    return null;
  }

  Future<void> printWithTemplateXps(
    BuildContext context, {
    required PrintTemplate template,
    required WeighingTab weighingTab,
    Client? client,
    Supplier? supplier,
    Material? material,
    String? printerName,
  }) async {
    try {
      return await _printTemplateXpsSilently(
          template, weighingTab, client, supplier, material);
    } catch (e) {
      debugPrint('Silent template printing failed, falling back to dialog: $e');
      // Fall through to dialog printing
    }

    return null;
  }

  /// Print using dialog (preview mode)
  Future<void> _printWithDialog(
    PrintTemplate template,
    WeighingTab weighingTab,
    Client? client,
    Supplier? supplier,
    Material? material,
  ) async {
    // Import CustomTemplateService to generate PDF
    final customTemplateService = CustomTemplateService();

    // Generate PDF using the template
    final pdf = await customTemplateService.generateCustomTemplatePDF(
      template: template,
      weighingTab: weighingTab,
      client: client,
      supplier: supplier,
      material: material,
    );

    // Get the correct page format for printing
    PdfPageFormat pageFormat;
    if (template.paperSize == 'Custom' &&
        template.customWidth != null &&
        template.customHeight != null) {
      // Convert mm to points (1mm = 2.835 points)
      final widthPoints = template.customWidth! * PdfPageFormat.mm;
      final heightPoints = template.customHeight! * PdfPageFormat.mm;
      pageFormat = PdfPageFormat(widthPoints, heightPoints);
    } else {
      pageFormat = paperSizes[template.paperSize] ?? PdfPageFormat.a4;
    }

    final isLandscape = template.orientation == 'landscape';
    final format = isLandscape ? pageFormat.landscape : pageFormat.portrait;

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat _) async => pdf.save(),
      format: format,
      name: 'Template Print - ${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Legacy PDF printing method (fallback)
  Future<void> _printWithLegacyMethod(
    PrintTemplate template,
    WeighingTab weighingTab,
    Client? client,
    Supplier? supplier,
    Material? material,
    String? printerName,
  ) async {
    // Generate PDF using the template
    final customTemplateService = CustomTemplateService();
    final pdf = await customTemplateService.generateCustomTemplatePDF(
      template: template,
      weighingTab: weighingTab,
      client: client,
      supplier: supplier,
      material: material,
    );

    final pdfBytes = await pdf.save();

    try {
      // Use silent print service as fallback
      final printJob = await _silentPrintService.printPDFSilently(
        pdfDocument: pdf,
        printerName: printerName ?? 'Default',
        documentName: 'Template Print - ${weighingTab.tabTitle}',
      );

      if (printJob.status == PrintJobStatus.failed) {
        throw Exception(
            'Windows printer returned false - check printer status');
      }
    } catch (e) {
      // If printing fails, provide helpful error message
      final errorMessage = e.toString();
      if (errorMessage.contains('ShellExecute failed with error code:')) {
        throw Exception(
            'Printing failed. Please check:\n• Printer is turned on and connected\n• Printer has paper and ink/toner\n• Default PDF viewer is installed\n• Try "Print with Dialog" option');
      } else {
        throw Exception('Printing failed: $errorMessage');
      }
    }
  }

  /// Print template silently using Windows Print Spooler APIs
  Future<PrintJob> _printTemplateSilently(
    PrintTemplate template,
    WeighingTab weighingTab,
    Client? client,
    Supplier? supplier,
    Material? material,
    String printerName,
  ) async {
    try {
      // Generate PDF with exact template dimensions
      final customTemplateService = CustomTemplateService();
      final pdf = await customTemplateService.generateCustomTemplatePDF(
        template: template,
        weighingTab: weighingTab,
        client: client,
        supplier: supplier,
        material: material,
      );

      // Create custom paper size from template
      PaperSize customPaperSize;
      if (template.paperSize == 'Custom' &&
          template.customWidth != null &&
          template.customHeight != null) {
        customPaperSize = PaperSize(
          width: template.customWidth!,
          height: template.customHeight!,
          name: 'Template Custom',
        );
      } else {
        // Convert standard paper size to PaperSize object
        customPaperSize = _convertStandardPaperSize(template.paperSize);
      }

      // Print silently with exact dimensions
      final job = await _silentPrintService.printPDFSilently(
        pdfDocument: pdf,
        printerName: printerName,
        documentName: 'Template Print - ${weighingTab.tabTitle}',
        customPaperSize: customPaperSize,
        customDpi: 203,
        // Default thermal printer DPI
        settings: {
          'preserveExactDimensions': true,
          'noScaling': true,
        },
      );

      return job;
    } catch (e) {
      debugPrint('Error in silent template printing: $e');
      rethrow;
    }
  }

  Future<void> _printTemplateXpsSilently(
    PrintTemplate template,
    WeighingTab weighingTab,
    Client? client,
    Supplier? supplier,
    Material? material,
  ) async {
    try {
      // Generate PDF with exact template dimensions
      final customTemplateService = CustomTemplateService();
      final pdf = await customTemplateService.generateCustomTemplatePDF(
        template: template,
        weighingTab: weighingTab,
        client: client,
        supplier: supplier,
        material: material,
      );
      File pdfFile = File('pdfile.pdf');

      final bytes = await pdf.save();
      await pdfFile.writeAsBytes(bytes);

      int res = await printPdfToDefaultPrinter(pdfFile.path);
      printd(res.toString());

      // Create custom paper size from template
      PaperSize customPaperSize;
      if (template.paperSize == 'Custom' &&
          template.customWidth != null &&
          template.customHeight != null) {
        customPaperSize = PaperSize(
          width: template.customWidth!,
          height: template.customHeight!,
          name: 'Template Custom',
        );
      } else {
        // Convert standard paper size to PaperSize object
        customPaperSize = _convertStandardPaperSize(template.paperSize);
      }

      //real work *********************************

      // final response = await convertPdfToXPS5(pdfFile.path, './output.xps');
    } catch (e) {
      debugPrint('Error in silent template printing: $e');
      rethrow;
    }
  }

  Future<void> printTemplateStandardPDFNewSilently(
    PrintTemplate template,
    WeighingTab weighingTab,
    Client? client,
    Supplier? supplier,
    Material? material,
  ) async {
    try {
      // Generate PDF with exact template dimensions
      final customTemplateService = CustomTemplateService();
      final pdf = await customTemplateService.generateCustomTemplatePDF(
        template: template,
        weighingTab: weighingTab,
        client: client,
        supplier: supplier,
        material: material,
      );
      File pdfFile = File('pdfile.pdf');

      final bytes = await pdf.save();
      await pdfFile.writeAsBytes(bytes);

      int res = await printPdfToDefaultPrinter(pdfFile.path);
      printd(res.toString());
    } catch (e) {
      debugPrint('Error in silent template printing: $e');
      rethrow;
    }
  }

  Future<void> saveTemplateStandardPDFNewSilently(
    PrintTemplate template,
    WeighingTab weighingTab,
    Client? client,
    Supplier? supplier,
    Material? material,
  ) async {
    try {
      // Generate PDF with exact template dimensions
      final customTemplateService = CustomTemplateService();
      final pdf = await customTemplateService.generateCustomTemplatePDF(
        template: template,
        weighingTab: weighingTab,
        client: client,
        supplier: supplier,
        material: material,
      );

      String? selectedDirectory =
          await fp.FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        // User canceled the picker
        return;
      }
      final filePath = '$selectedDirectory/my_new_file.pdf';
      File pdfFile = File(filePath);
      final bytes = await pdf.save();
      await pdfFile.writeAsBytes(bytes);

      // int res = await printPdfToDefaultPrinter(pdfFile.path);
      //       // printd(res.toString());
    } catch (e) {
      debugPrint('Error in silent template printing: $e');
      rethrow;
    }
  }

  /// Convert standard paper size name to PaperSize object
  PaperSize _convertStandardPaperSize(String paperSizeName) {
    switch (paperSizeName.toUpperCase()) {
      case 'A3':
        return PaperSize.a3;
      case 'A4':
        return PaperSize.a4;
      case 'A5':
        return const PaperSize(width: 148, height: 210, name: 'A5');
      case 'LETTER':
        return PaperSize.letter;
      case 'LEGAL':
        return PaperSize.legal;
      default:
        return PaperSize.a4; // Default fallback
    }
  }

  /// Print weighing ticket on pre-printed form - DISABLED (Order dependency removed)
}
