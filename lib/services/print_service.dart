import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';
import '../models/client.dart';
import '../models/supplier.dart';
import '../models/material.dart';
import '../models/printer_info.dart';
import '../models/print_job.dart';
import 'windows_silent_print_service.dart';
// import 'widows_printing_service.dart'; // Disabled due to compilation errors

class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

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

  // Legacy method - disabled, use WeighingTabPrintService instead
  /*
  Future<void> printWeighingTicket({
    required Map<String, dynamic> order, // Legacy - using map instead of Order
    Client? client,
    Supplier? supplier,
    Material? material,
    bool silentPrint = false,
    String? printerName,
    PaperSize? customPaperSize,
  }) async {
    final pdf = await _generateWeighingTicket(
      order: order,
      client: client,
      supplier: supplier,
      material: material,
    );

    if (silentPrint && printerName != null) {
      // Use silent printing
      try {
        final job = await _silentPrintService.printPDFSilently(
          pdfDocument: pdf,
          printerName: printerName,
          documentName: 'Weighing Ticket - ${order.orderNumber}',
          customPaperSize: customPaperSize,
        );

        if (job.status != PrintJobStatus.completed) {
          throw Exception('Silent printing failed: ${job.errorMessage ?? 'Unknown error'}');
        }

        debugPrint('Silent printing completed successfully');
        return;
      } catch (e) {
        debugPrint('Silent printing failed, falling back to dialog: $e');
        // Fall through to dialog printing
      }
    }

    // Use standard printing service with system dialog
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Weighing Ticket - ${order.orderNumber}',
      );
    } catch (e) {
      debugPrint('Printing failed: ${e.toString()}');
      // Fall back to saving PDF file instead of printing
      try {
        final pdfBytes = await pdf.save();
        await savePdfToDownloads(pdfBytes, 'weighing_ticket_${order.orderNumber}');
        debugPrint('PDF saved as fallback due to printing error');
      } catch (saveError) {
        debugPrint('Failed to save PDF: $saveError');
      }
      throw Exception('Printing failed: $e');
    }
  }
  */

  Future<void> printInvoice({
    required Order order,
    Client? client,
    Supplier? supplier,
    Material? material,
    List<Order>? additionalOrders,
    bool silentPrint = false,
    String? printerName,
    PaperSize? customPaperSize,
  }) async {
    final pdf = await _generateInvoice(
      order: order,
      client: client,
      supplier: supplier,
      material: material,
      additionalOrders: additionalOrders,
    );

    if (silentPrint && printerName != null) {
      // Use silent printing
      try {
        final job = await _silentPrintService.printPDFSilently(
          pdfDocument: pdf,
          printerName: printerName,
          documentName: 'Invoice - ${order.orderNumber}',
          customPaperSize: customPaperSize,
        );

        if (job.status != PrintJobStatus.completed) {
          throw Exception('Silent printing failed: ${job.errorMessage ?? 'Unknown error'}');
        }

        debugPrint('Silent printing completed successfully');
        return;
      } catch (e) {
        debugPrint('Silent printing failed, falling back to dialog: $e');
        // Fall through to dialog printing
      }
    }

    // Use standard printing service with system dialog
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice - ${order.orderNumber}',
      );
    } catch (e) {
      debugPrint('Printing failed: ${e.toString()}');
      // Fall back to saving PDF file instead of printing
      try {
        final pdfBytes = await pdf.save();
        await savePdfToDownloads(pdfBytes, 'invoice_${order.orderNumber}');
        debugPrint('PDF saved as fallback due to printing error');
      } catch (saveError) {
        debugPrint('Failed to save PDF: $saveError');
      }
      throw Exception('Printing failed: $e');
    }
  }

  Future<String> saveWeighingTicketToPDF({
    required Order order,
    Client? client,
    Supplier? supplier,
    Material? material,
  }) async {
    final pdf = await _generateWeighingTicket(
      order: order,
      client: client,
      supplier: supplier,
      material: material,
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/weighing_ticket_${order.orderNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  Future<String> saveInvoiceToPDF({
    required Order order,
    Client? client,
    Supplier? supplier,
    Material? material,
    List<Order>? additionalOrders,
  }) async {
    final pdf = await _generateInvoice(
      order: order,
      client: client,
      supplier: supplier,
      material: material,
      additionalOrders: additionalOrders,
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/invoice_${order.orderNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  Future<pw.Document> _generateWeighingTicket({
    required Order order,
    Client? client,
    Supplier? supplier,
    Material? material,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    
    // Load Unicode font for Arabic support
    await _loadUnicodeFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: _unicodeFont,
          bold: _unicodeFont,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              pw.SizedBox(height: 20),
              
              // Ticket Title
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'WEIGHING TICKET',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Ticket Information
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildTicketInfo(order, client, supplier, material),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: _buildWeightInfo(order),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Vehicle and Driver Information
              _buildVehicleInfo(order),
              pw.SizedBox(height: 20),
              
              // Notes
              if (order.notes != null && order.notes!.isNotEmpty) ...[ 
                _buildNotesSection(order.notes!),
                pw.SizedBox(height: 20),
              ],
              
              pw.Spacer(),
              
              // Footer
              _buildTicketFooter(now),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<pw.Document> _generateInvoice({
    required Order order,
    Client? client,
    Supplier? supplier,
    Material? material,
    List<Order>? additionalOrders,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final allOrders = <Order>[order];
    if (additionalOrders != null) {
      allOrders.addAll(additionalOrders);
    }
    
    // Load Unicode font for Arabic support
    await _loadUnicodeFont();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: _unicodeFont,
          bold: _unicodeFont,
        ),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(),
            pw.SizedBox(height: 20),
            
            // Invoice Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Invoice #: ${order.orderNumber}',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'Date: ${_formatDate(now)}',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    if (order.weighOutTime != null)
                      pw.Text(
                        'Due Date: ${_formatDateFromString(order.weighOutTime, addDays: 30)}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Billing Information
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildBillToSection(client ?? supplier),
                ),
                pw.SizedBox(width: 40),
                pw.Expanded(
                  child: _buildBillFromSection(),
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            
            // Invoice Items Table
            _buildInvoiceTable(allOrders, material),
            pw.SizedBox(height: 20),
            
            // Totals
            _buildInvoiceTotals(allOrders),
            pw.SizedBox(height: 30),
            
            // Payment Terms
            _buildPaymentTerms(),
            pw.SizedBox(height: 20),
            
            // Footer
            _buildInvoiceFooter(),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _companyInfo['name']!,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(_companyInfo['address']!, style: pw.TextStyle(fontSize: 10)),
              pw.Text('Phone: ${_companyInfo['phone']}', style: pw.TextStyle(fontSize: 10)),
              pw.Text('Email: ${_companyInfo['email']}', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(_companyInfo['website']!, style: pw.TextStyle(fontSize: 10)),
              pw.Text('Tax ID: ${_companyInfo['taxId']}', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTicketInfo(Order order, Client? client, Supplier? supplier, Material? material) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('TICKET INFORMATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Ticket #: ${order.orderNumber}'),
          pw.Text('Date: ${_formatDateFromString(order.weighInTime) != 'N/A' ? _formatDateFromString(order.weighInTime) : _formatDate(DateTime.now())}'),
          pw.Text('Operation: ${order.operationType.toUpperCase()}'),
          if (client != null) pw.Text('Client: ${client.name}'),
          if (supplier != null) pw.Text('Supplier: ${supplier.name}'),
          if (material != null) pw.Text('Material: ${material.name}'),
          pw.Text('Status: ${order.status.toUpperCase()}'),
        ],
      ),
    );
  }

  pw.Widget _buildWeightInfo(Order order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('WEIGHT INFORMATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Gross Weight: ${order.grossWeight?.toStringAsFixed(2) ?? 'N/A'} kg'),
          pw.Text('Tare Weight: ${order.tareWeight?.toStringAsFixed(2) ?? 'N/A'} kg'),
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.yellow100,
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Text(
              'Net Weight: ${order.netWeight?.toStringAsFixed(2) ?? 'N/A'} kg',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
          ),
          if (order.weighInTime != null)
            pw.Text('Weigh In: ${_formatDateFromString(order.weighInTime)}'),
          if (order.weighOutTime != null)
            pw.Text('Weigh Out: ${_formatDateFromString(order.weighOutTime)}'),
        ],
      ),
    );
  }

  pw.Widget _buildVehicleInfo(Order order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('VEHICLE & DRIVER INFORMATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Truck Plate: ${order.truckPlate ?? 'N/A'}'),
                    pw.Text('Driver Name: ${order.driverName ?? 'N/A'}'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Driver License: ${order.driverLicense ?? 'N/A'}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNotesSection(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('NOTES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(notes),
        ],
      ),
    );
  }

  pw.Widget _buildTicketFooter(DateTime printTime) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Printed: ${_formatDateTime(printTime)}', style: pw.TextStyle(fontSize: 8)),
          pw.Text('This is a system-generated document', style: pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildBillToSection(dynamic entity) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (entity != null) ...[
            pw.Text(entity.name ?? 'N/A', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            if (entity.street != null) pw.Text(entity.street!),
            if (entity.street2 != null) pw.Text(entity.street2!),
            if (entity.city != null || entity.zip != null)
              pw.Text('${entity.city ?? ''} ${entity.zip ?? ''}'),
            if (entity.phone != null) pw.Text('Phone: ${entity.phone}'),
            if (entity.email != null) pw.Text('Email: ${entity.email}'),
            if (entity.vat != null) pw.Text('VAT: ${entity.vat}'),
          ] else
            pw.Text('N/A'),
        ],
      ),
    );
  }

  pw.Widget _buildBillFromSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Bill From:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(_companyInfo['name']!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(_companyInfo['address']!),
          pw.Text('Phone: ${_companyInfo['phone']}'),
          pw.Text('Email: ${_companyInfo['email']}'),
          pw.Text('Tax ID: ${_companyInfo['taxId']}'),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceTable(List<Order> orders, Material? material) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Weight (kg)', isHeader: true),
            _buildTableCell('Unit Price', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
          ],
        ),
        // Rows
        ...orders.map((order) => pw.TableRow(
          children: [
            _buildTableCell('${material?.name ?? 'Material'} - ${order.orderNumber}'),
            _buildTableCell('${order.netWeight?.toStringAsFixed(2) ?? '0.00'}'),
            _buildTableCell('\$${order.unitPrice?.toStringAsFixed(2) ?? '0.00'}'),
            _buildTableCell('\$${order.totalAmount?.toStringAsFixed(2) ?? '0.00'}'),
          ],
        )).toList(),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }

  pw.Widget _buildInvoiceTotals(List<Order> orders) {
    final subtotal = orders.fold<double>(0.0, (sum, order) => sum + (order.totalAmount ?? 0.0));
    final tax = subtotal * 0.1; // 10% tax
    final total = subtotal + tax;

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _buildTotalRow('Subtotal:', '\$${subtotal.toStringAsFixed(2)}'),
            _buildTotalRow('Tax (10%):', '\$${tax.toStringAsFixed(2)}'),
            pw.Divider(color: PdfColors.black),
            _buildTotalRow('Total:', '\$${total.toStringAsFixed(2)}', isTotal: true),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isTotal ? 14 : 12,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isTotal ? 14 : 12,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPaymentTerms() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Payment Terms:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('• Payment due within 30 days of invoice date'),
          pw.Text('• Late payments subject to 1.5% monthly service charge'),
          pw.Text('• Please include invoice number with payment'),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Center(
        child: pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Load Unicode font for Arabic support
  Future<void> _loadUnicodeFont() async {
    if (_unicodeFont != null) return;
    
    try {
      // Try to load a system font that supports Unicode/Arabic
      final fontData = await _getSystemFont();
      if (fontData != null) {
        _unicodeFont = pw.Font.ttf(fontData.buffer.asByteData());
      } else {
        // Fallback to a default font from Google Fonts or embedded font
        final fontData = await _getDefaultUnicodeFont();
        if (fontData.isNotEmpty) {
          _unicodeFont = pw.Font.ttf(fontData.buffer.asByteData());
        }
      }
    } catch (e) {
      // If all fails, use the default font (might not support Arabic)
      debugPrint('Failed to load Unicode font: $e');
    }
  }
  
  // Try to get a system font that supports Arabic
  Future<Uint8List?> _getSystemFont() async {
    try {
      // Common Windows fonts that support Arabic
      const fontPaths = [
        'C:/Windows/Fonts/arial.ttf',
        'C:/Windows/Fonts/calibri.ttf', 
        'C:/Windows/Fonts/tahoma.ttf',
        'C:/Windows/Fonts/segoeui.ttf',
      ];
      
      for (final fontPath in fontPaths) {
        final file = File(fontPath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (e) {
      debugPrint('Error loading system font: $e');
    }
    return null;
  }
  
  // Get a default Unicode font (you can embed a font file in assets)
  Future<Uint8List> _getDefaultUnicodeFont() async {
    // For now, we'll use a simple fallback approach
    // In a production app, you should embed a Unicode font in assets
    try {
      // Try to get a system font data directly 
      const fontPaths = [
        'C:/Windows/Fonts/arial.ttf',
        'C:/Windows/Fonts/tahoma.ttf',
      ];
      
      for (final fontPath in fontPaths) {
        final file = File(fontPath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
      
      // Ultimate fallback - return empty list which will use default font
      debugPrint('No Unicode font found, using default font (may not support Arabic)');
      return Uint8List.fromList([]);
    } catch (e) {
      // Ultimate fallback - this might not support Arabic properly
      debugPrint('Failed to load Unicode font: $e');
      return Uint8List.fromList([]);
    }
  }

  void updateCompanyInfo(Map<String, String> newInfo) {
    _companyInfo.addAll(newInfo);
  }

  Map<String, String> get companyInfo => Map.from(_companyInfo);
  
  // Add fallback methods for when Windows printing fails
  Future<void> printWeighingTicketWithDialog({
    required Order order,
    Client? client,
    Supplier? supplier,
    Material? material,
  }) async {
    final pdf = await _generateWeighingTicket(
      order: order,
      client: client,
      supplier: supplier,
      material: material,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Weighing Ticket - ${order.orderNumber}',
    );
  }
  
  Future<void> printInvoiceWithDialog({
    required Order order,
    Client? client,
    Supplier? supplier,
    Material? material,
    List<Order>? additionalOrders,
  }) async {
    final pdf = await _generateInvoice(
      order: order,
      client: client,
      supplier: supplier,
      material: material,
      additionalOrders: additionalOrders,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice - ${order.orderNumber}',
    );
  }

  /// Generate weighing ticket PDF without printing
  Future<pw.Document> generateWeighingTicket({
    required Order order,
    Client? client,
    Supplier? supplier,
    Material? material,
  }) async {
    return await _generateWeighingTicket(
      order: order,
      client: client,
      supplier: supplier,
      material: material,
    );
  }

  /// Generate invoice PDF without printing
  Future<pw.Document> generateInvoice({
    required Order order,
    Client? client,
    Supplier? supplier,
    Material? material,
    List<Order>? additionalOrders,
  }) async {
    return await _generateInvoice(
      order: order,
      client: client,
      supplier: supplier,
      material: material,
      additionalOrders: additionalOrders,
    );
  }

  /// Get list of available printers
  Future<List<PrinterInfo>> getAvailablePrinters({bool forceRefresh = false}) async {
    return await _silentPrintService.getAvailablePrinters(forceRefresh: forceRefresh);
  }

  /// Get default printer
  Future<PrinterInfo?> getDefaultPrinter() async {
    return await _silentPrintService.getDefaultPrinter();
  }

  /// Test silent printing functionality
  Future<bool> testSilentPrint(String printerName) async {
    return await _silentPrintService.testPrint(printerName);
  }

  /// Check if printer supports silent printing
  Future<bool> supportssilentPrinting(String printerName) async {
    return await _silentPrintService.supportssilentPrinting(printerName);
  }

  /// Get print job status
  List<PrintJob> getActivePrintJobs() {
    return _silentPrintService.getActivePrintJobs();
  }

  /// Cancel print job
  Future<bool> cancelPrintJob(String jobId) async {
    return await _silentPrintService.cancelPrintJob(jobId);
  }

  /// Clear completed print jobs
  void clearCompletedJobs() {
    _silentPrintService.clearCompletedJobs();
  }

  Future<void> savePdfToDownloads(Uint8List pdfBytes, String fileName) async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      final file = File('${downloadsDir?.path ?? '.'}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);
      debugPrint('PDF saved to: ${file.path}');
    } catch (e) {
      debugPrint('Failed to save PDF to downloads: $e');
      // Try saving to documents directory instead
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        final file = File('${documentsDir.path}/$fileName.pdf');
        await file.writeAsBytes(pdfBytes);
        debugPrint('PDF saved to: ${file.path}');
      } catch (e2) {
        debugPrint('Failed to save PDF to documents: $e2');
        throw Exception('Unable to save PDF file');
      }
    }
  }

  /// Format date from string with optional day addition
  String _formatDateFromString(String? dateString, {int addDays = 0}) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    try {
      final date = DateTime.parse(dateString);
      final adjustedDate = addDays > 0 ? date.add(Duration(days: addDays)) : date;
      return _formatDate(adjustedDate);
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }
}