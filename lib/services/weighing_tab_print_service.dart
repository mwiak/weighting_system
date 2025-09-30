import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/weighing_tab.dart';
import '../models/client.dart';
import '../models/supplier.dart';
import '../models/material.dart';
import '../models/printer_info.dart';
import '../models/print_job.dart';
import 'windows_silent_print_service.dart';

class WeighingTabPrintService {
  static final WeighingTabPrintService _instance =
      WeighingTabPrintService._internal();
  factory WeighingTabPrintService() => _instance;
  WeighingTabPrintService._internal();

  // Cache for Unicode font
  pw.Font? _unicodeFont;

  // Silent printing service
  final _silentPrintService = WindowsSilentPrintService();

  // Company information - this could be loaded from settings
  final Map<String, String> _companyInfo = {
    'name': 'Truck Weighing Systems Ltd.',
    'address': '123 Industrial Road, City, State 12345',
    'phone': '+1 (555) 123-4567',
    'email': 'info@weighingsystems.com',
    'website': 'www.weighingsystems.com',
    'taxId': 'TAX123456789',
  };

  Future<void> printWeighingTicket({
    required WeighingTab tab,
    Client? client,
    Supplier? supplier,
    Material? material,
    bool silentPrint = false,
    String? printerName,
    PdfPageFormat? customPaperSize,
  }) async {
    // final pdf = await _generateWeighingTicket(
    //   tab: tab,
    //   client: client,
    //   supplier: supplier,
    //   material: material,
    // );
    //
    // final documentName = 'Weighing Ticket - ${tab.tabTitle}';
    //
    // if (silentPrint && printerName != null) {
    //   // Use silent printing
    //   try {
    //     final job = await _silentPrintService.printPDFSilently(
    //       pdfDocument: pdf,
    //       printerName: printerName,
    //       documentName: documentName,
    //       customPaperSize: customPaperSize,
    //     );
    //
    //     if (job.status != PrintJobStatus.completed) {
    //       throw Exception('Silent printing failed: ${job.errorMessage ?? 'Unknown error'}');
    //     }
    //
    //     debugPrint('Silent printing completed successfully');
    //     return;
    //   } catch (e) {
    //     debugPrint('Silent printing failed, falling back to dialog: $e');
    //     // Fall through to dialog printing
    //   }
    // }
    //
    // // Use standard printing service with system dialog
    // try {
    //   await Printing.layoutPdf(
    //     onLayout: (PdfPageFormat format) async => pdf.save(),
    //     name: documentName,
    //   );
    // } catch (e) {
    //   debugPrint('Printing failed: ${e.toString()}');
    //   // Fall back to saving PDF file instead of printing
    //   try {
    //     final pdfBytes = await pdf.save();
    //     await savePdfToDownloads(pdfBytes, 'weighing_ticket_${tab.id}');
    //     debugPrint('PDF saved as fallback due to printing error');
    //   } catch (saveError) {
    //     debugPrint('Failed to save PDF: $saveError');
    //   }
    //   throw Exception('Printing failed: $e');
    // }
  }

  Future<void> printReceipt({
    required WeighingTab tab,
    Client? client,
    Supplier? supplier,
    Material? material,
    bool silentPrint = false,
    String? printerName,
    PdfPageFormat? customPaperSize,
  }) async {
    //   final pdf = await _generateReceipt(
    //     tab: tab,
    //     client: client,
    //     supplier: supplier,
    //     material: material,
    //   );
    //
    //   final documentName = 'Receipt - ${tab.tabTitle}';
    //
    //   if (silentPrint && printerName != null) {
    //     // Use silent printing
    //     try {
    //       final job = await _silentPrintService.printPDFSilently(
    //         pdfDocument: pdf,
    //         printerName: printerName,
    //         documentName: documentName,
    //         customPaperSize: customPaperSize,
    //       );
    //
    //       if (job.status != PrintJobStatus.completed) {
    //         throw Exception('Silent printing failed: ${job.errorMessage ?? 'Unknown error'}');
    //       }
    //
    //       debugPrint('Silent printing completed successfully');
    //       return;
    //     } catch (e) {
    //       debugPrint('Silent printing failed, falling back to dialog: $e');
    //       // Fall through to dialog printing
    //     }
    //   }
    //
    //   // Use standard printing service with system dialog
    //   try {
    //     await Printing.layoutPdf(
    //       onLayout: (PdfPageFormat format) async => pdf.save(),
    //       name: documentName,
    //     );
    //   } catch (e) {
    //     debugPrint('Printing failed: ${e.toString()}');
    //     // Fall back to saving PDF file instead of printing
    //     try {
    //       final pdfBytes = await pdf.save();
    //       await savePdfToDownloads(pdfBytes, 'receipt_${tab.id}');
    //       debugPrint('PDF saved as fallback due to printing error');
    //     } catch (saveError) {
    //       debugPrint('Failed to save PDF: $saveError');
    //     }
    //     throw Exception('Printing failed: $e');
    //   }
    // }
    //
    // Future<pw.Document> _generateWeighingTicket({
    //   required WeighingTab tab,
    //   Client? client,
    //   Supplier? supplier,
    //   Material? material,
    // }) async {
    //   final pdf = pw.Document();
    //   await _loadUnicodeFont();
    //
    //   pdf.addPage(
    //     pw.Page(
    //       pageFormat: PdfPageFormat.a4,
    //       build: (pw.Context context) {
    //         return pw.Column(
    //           crossAxisAlignment: pw.CrossAxisAlignment.start,
    //           children: [
    //             // Header
    //             _buildHeader(),
    //             pw.SizedBox(height: 20),
    //
    //             // Title
    //             pw.Center(
    //               child: pw.Text(
    //                 'WEIGHING TICKET',
    //                 style: pw.TextStyle(
    //                   fontSize: 20,
    //                   fontWeight: pw.FontWeight.bold,
    //                   font: _unicodeFont,
    //                 ),
    //               ),
    //             ),
    //             pw.SizedBox(height: 20),
    //
    //             // Tab Information
    //             _buildTabInfo(tab),
    //             pw.SizedBox(height: 15),
    //
    //             // Vehicle Information
    //             _buildVehicleInfo(tab),
    //             pw.SizedBox(height: 15),
    //
    //             // Weight Information
    //             _buildWeightInfo(tab),
    //             pw.SizedBox(height: 15),
    //
    //             // Business Information
    //             if (tab.supplierClient.isNotEmpty || tab.material.isNotEmpty)
    //               _buildBusinessInfo(tab),
    //
    //             pw.Spacer(),
    //
    //             // Footer
    //             _buildFooter(),
    //           ],
    //         );
    //       },
    //     ),
    //   );

    // return pdf;
  }

  Future<pw.Document> _generateReceipt({
    required WeighingTab tab,
    Client? client,
    Supplier? supplier,
    Material? material,
  }) async {
    final pdf = pw.Document();
    await _loadUnicodeFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildCompactHeader(),
              pw.SizedBox(height: 15),

              // Title
              pw.Center(
                child: pw.Text(
                  'WEIGHT RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: _unicodeFont,
                  ),
                ),
              ),
              pw.SizedBox(height: 15),

              // Essential Information
              _buildCompactTabInfo(tab),
              pw.SizedBox(height: 10),
              _buildCompactWeightInfo(tab),

              pw.Spacer(),

              // Compact Footer
              _buildCompactFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _companyInfo['name']!,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                font: _unicodeFont,
              ),
            ),
            pw.Text(_companyInfo['address']!,
                style: pw.TextStyle(font: _unicodeFont)),
            pw.Text(_companyInfo['phone']!,
                style: pw.TextStyle(font: _unicodeFont)),
            pw.Text(_companyInfo['email']!,
                style: pw.TextStyle(font: _unicodeFont)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Date: ${DateTime.now().toString().split(' ')[0]}',
              style: pw.TextStyle(font: _unicodeFont),
            ),
            pw.Text(
              'Time: ${DateTime.now().toString().split(' ')[1].substring(0, 8)}',
              style: pw.TextStyle(font: _unicodeFont),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCompactHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          _companyInfo['name']!,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            font: _unicodeFont,
          ),
        ),
        pw.Text(
          DateTime.now().toString().split(' ')[0],
          style: pw.TextStyle(font: _unicodeFont, fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildTabInfo(WeighingTab tab) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Tab Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: _unicodeFont,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Tab ID:', style: pw.TextStyle(font: _unicodeFont)),
              pw.Text('${tab.id ?? 0}', style: pw.TextStyle(font: _unicodeFont)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Status:', style: pw.TextStyle(font: _unicodeFont)),
              pw.Text(tab.status.toUpperCase(),
                  style: pw.TextStyle(font: _unicodeFont)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Operation Type:',
                  style: pw.TextStyle(font: _unicodeFont)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactTabInfo(WeighingTab tab) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Tab ID:',
                style: pw.TextStyle(font: _unicodeFont, fontSize: 10)),
            pw.Text('${tab.id ?? 0}',
                style: pw.TextStyle(font: _unicodeFont, fontSize: 10)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Truck:',
                style: pw.TextStyle(font: _unicodeFont, fontSize: 10)),
            pw.Text(tab.truckPlate,
                style: pw.TextStyle(font: _unicodeFont, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildVehicleInfo(WeighingTab tab) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Vehicle Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: _unicodeFont,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Truck Plate:', style: pw.TextStyle(font: _unicodeFont)),
              pw.Text(
                  tab.truckPlate.isNotEmpty ? tab.truckPlate : 'Not specified',
                  style: pw.TextStyle(font: _unicodeFont)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Driver Name:', style: pw.TextStyle(font: _unicodeFont)),
              pw.Text(
                  tab.driverName.isNotEmpty ? tab.driverName : 'Not specified',
                  style: pw.TextStyle(font: _unicodeFont)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildWeightInfo(WeighingTab tab) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Weight Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: _unicodeFont,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Gross Weight:', style: pw.TextStyle(font: _unicodeFont)),
              pw.Text('${tab.grossWeight.toStringAsFixed(0)} kg',
                  style: pw.TextStyle(font: _unicodeFont)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Empty Weight:', style: pw.TextStyle(font: _unicodeFont)),
              pw.Text('${tab.emptyWeight.toStringAsFixed(0)} kg',
                  style: pw.TextStyle(font: _unicodeFont)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Net Weight:',
                  style: pw.TextStyle(
                      font: _unicodeFont, fontWeight: pw.FontWeight.bold)),
              pw.Text('${tab.netWeight.toStringAsFixed(0)} kg',
                  style: pw.TextStyle(
                      font: _unicodeFont, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactWeightInfo(WeighingTab tab) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Gross:',
                style: pw.TextStyle(font: _unicodeFont, fontSize: 10)),
            pw.Text('${tab.grossWeight.toStringAsFixed(0)} kg',
                style: pw.TextStyle(font: _unicodeFont, fontSize: 10)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Empty:',
                style: pw.TextStyle(font: _unicodeFont, fontSize: 10)),
            pw.Text('${tab.emptyWeight.toStringAsFixed(0)} kg',
                style: pw.TextStyle(font: _unicodeFont, fontSize: 10)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('NET:',
                style: pw.TextStyle(
                    font: _unicodeFont,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold)),
            pw.Text('${tab.netWeight.toStringAsFixed(0)} kg',
                style: pw.TextStyle(
                    font: _unicodeFont,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide()),
      ),
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for using our weighing services',
            style: pw.TextStyle(
              font: _unicodeFont,
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            _companyInfo['website']!,
            style: pw.TextStyle(font: _unicodeFont, fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactFooter() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide()),
      ),
      padding: const pw.EdgeInsets.only(top: 5),
      child: pw.Text(
        'Thank you for using our services',
        style: pw.TextStyle(
          font: _unicodeFont,
          fontSize: 8,
          fontStyle: pw.FontStyle.italic,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  Future<void> _loadUnicodeFont() async {
    if (_unicodeFont == null) {
      try {
        final fontData = await PdfGoogleFonts.notoSansRegular();
        _unicodeFont = pw.Font.ttf(fontData as ByteData);
      } catch (e) {
        debugPrint('Failed to load Unicode font, using default: $e');
        // Use default font if Unicode font fails to load
        _unicodeFont = pw.Font.helvetica();
      }
    }
  }

  Future<void> savePdfToDownloads(Uint8List pdfBytes, String fileName) async {
    try {
      Directory? downloadsDirectory;

      if (Platform.isWindows) {
        // Get the user's Downloads folder on Windows
        final homeDir = Directory(Platform.environment['USERPROFILE']!);
        downloadsDirectory = Directory('${homeDir.path}\\Downloads');
      } else {
        downloadsDirectory = await getDownloadsDirectory();
      }

      if (downloadsDirectory != null && await downloadsDirectory.exists()) {
        final file = File('${downloadsDirectory.path}\\$fileName.pdf');
        await file.writeAsBytes(pdfBytes);
        debugPrint('PDF saved to: ${file.path}');
      } else {
        throw Exception('Downloads directory not found');
      }
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      rethrow;
    }
  }

  Future<List<PrinterInfo>> getAvailablePrinters() {
    return _silentPrintService.getAvailablePrinters();
  }

  Future<bool> testPrinter(String printerName) async {
    return await _silentPrintService.testPrint(printerName);
  }
}
