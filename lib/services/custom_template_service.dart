import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:weighing_system/utils/date_format.dart';
import 'package:weighing_system/utils/debugging_methods.dart';
import '../models/print_template.dart';
import '../models/weighing_tab.dart';
import '../models/client.dart';
import '../models/supplier.dart';
import '../models/material.dart';

class CustomTemplateService {
  static final CustomTemplateService _instance =
      CustomTemplateService._internal();
  factory CustomTemplateService() => _instance;
  CustomTemplateService._internal();

  // Cache for Arabic/Unicode font
  pw.Font? _arabicFont;
  pw.Font? _arabicSemiBoldFont;
  pw.Font? _arabicBoldFont;
  pw.Font? _arabicExtraBoldFont;
  pw.Font? _unicodeFont;

  // Available data variables that can be used in templates
  static const Map<String, String> availableVariables = {
    // WeighingTab information
    'tabId': 'Tab ID',
    'tabTitle': 'Tab Title',
    'operationType': 'Operation Type',
    'status': 'Status',
    'createDate': 'Create Date',
    'updateDate': 'Update Date',

    // Weight information
    'grossWeight': 'Gross Weight',
    'emptyWeight': 'Empty Weight (Tare)',
    'netWeight': 'Net Weight',
    'isPaid': 'Payment Status',
    'showPriceOnPrint': 'Show Price on Print',

    // Client information
    'clientName': 'Client Name',
    'clientAddress': 'Client Address',
    'clientCity': 'Client City',
    'clientPhone': 'Client Phone',
    'clientEmail': 'Client Email',
    'clientVat': 'Client VAT',

    // Supplier information
    'supplierName': 'Supplier Name',
    'supplierAddress': 'Supplier Address',
    'supplierCity': 'Supplier City',
    'supplierPhone': 'Supplier Phone',
    'supplierEmail': 'Supplier Email',
    'supplierVat': 'Supplier VAT',

    // Material information
    'materialName': 'Material Name',
    'materialCode': 'Material Code',
    'materialDescription': 'Material Description',
    'materialListPrice': 'Material List Price',
    'materialStandardPrice': 'Material Standard Price',

    // Vehicle information
    'truckPlate': 'Truck Plate',
    'driverName': 'Driver Name',
    'driverLicense': 'Driver License',

    // Additional fields
    'notes': 'Notes',
    'barcode': 'Barcode',
    'currentDate': 'Current Date',
    'currentTime': 'Current Time',
    'currentDateTime': 'Current Date Time',
  };

  /// Generate PDF using a custom template with Arabic support for WeighingTab
  Future<pw.Document> generateCustomTemplatePDF({
    required PrintTemplate template,
    required WeighingTab weighingTab,
    Client? client,
    Supplier? supplier,
    Material? material,
    Map<String, String>? arabicTranslations,
  }) async {
    await _loadCustomFonts();

    final pdf = pw.Document();
    final now = DateTime.now();

    // Prepare data values
    final dataValues = _prepareDataValuesFromTab(
      weighingTab: weighingTab,
      client: client,
      supplier: supplier,
      material: material,
      now: now,
      arabicTranslations: arabicTranslations,
    );

    // Get page format
    final pageFormat = _getPageFormat(template);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(0), // No margins for custom positioning
        theme: pw.ThemeData.withFont(
          base: _unicodeFont ?? pw.Font.helvetica(),
          bold: _arabicFont ?? pw.Font.helveticaBold(),
        ),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Background image only if explicitly enabled for printing
              if (template.useBackgroundInPrint &&
                  template.backgroundImagePath != null)
                _buildBackgroundImage(template),

              // Positioned fields
              ..._buildTemplateFields(template, dataValues),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Save template to local storage
  Future<String> saveTemplate(PrintTemplate template) async {
    final directory = await getApplicationDocumentsDirectory();
    final templatesDir = Directory('${directory.path}/print_templates');

    if (!await templatesDir.exists()) {
      await templatesDir.create(recursive: true);
    }

    final file = File('${templatesDir.path}/${template.id}.json');
    await file.writeAsString(template.toJsonString());

    return file.path;
  }

  /// Load template from local storage
  Future<PrintTemplate?> loadTemplate(String templateId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/print_templates/$templateId.json');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return PrintTemplate.fromJsonString(jsonString);
      }
    } catch (e) {
      debugPrint('Error loading template: $e');
    }
    return null;
  }

  /// Get all saved templates
  Future<List<PrintTemplate>> getAllTemplates() async {
    final templates = <PrintTemplate>[];

    try {
      final directory = await getApplicationDocumentsDirectory();
      final templatesDir = Directory('${directory.path}/print_templates');

      if (await templatesDir.exists()) {
        final files =
            templatesDir.listSync().where((f) => f.path.endsWith('.json'));

        for (final file in files) {
          try {
            final jsonString = await File(file.path).readAsString();
            final template = PrintTemplate.fromJsonString(jsonString);
            templates.add(template);
          } catch (e) {
            debugPrint('Error loading template ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading templates directory: $e');
    }

    return templates;
  }

  Future<PrintTemplate?> getDefaultTemplate() async {
    final templates = <PrintTemplate>[];

    try {
      final directory = await getApplicationDocumentsDirectory();
      final templatesDir = Directory('${directory.path}/print_templates');

      if (await templatesDir.exists()) {
        final files =
            templatesDir.listSync().where((f) => f.path.endsWith('.json'));

        for (final file in files) {
          try {
            final jsonString = await File(file.path).readAsString();
            final template = PrintTemplate.fromJsonString(jsonString);
            if (template.isActive) {
              templates.add(template);
            }
          } catch (e) {
            debugPrint('Error loading template ${file.path}: $e');
          }
        }
        return templates[0];
      }
    } catch (e) {
      debugPrint('Error reading templates directory: $e');
    }
  }

  /// Delete a template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/print_templates/$templateId.json');

      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting template: $e');
    }
    return false;
  }

  /// Create a default Arabic template
  PrintTemplate createDefaultArabicTemplate() {
    return PrintTemplate(
      id: 'arabic_weighing_default',
      name: 'قالب الوزن العربي',
      description: 'قالب افتراضي لتذاكر الوزن باللغة العربية',
      paperSize: 'A4',
      orientation: 'portrait',
      createdAt: DateTime.now(),
      fields: [
        // Arabic header
        TemplateField(
          fieldName: 'orderNumber',
          x: 150,
          y: 50,
          fontSize: 16,
          bold: true,
          prefix: 'رقم الطلب: ',
        ),
        TemplateField(
          fieldName: 'currentDate',
          x: 150,
          y: 70,
          fontSize: 12,
          prefix: 'التاريخ: ',
        ),

        // Client information in Arabic
        TemplateField(
          fieldName: 'clientName',
          x: 50,
          y: 120,
          fontSize: 14,
          bold: true,
          prefix: 'العميل: ',
        ),
        TemplateField(
          fieldName: 'clientAddress',
          x: 50,
          y: 140,
          fontSize: 10,
          prefix: 'العنوان: ',
          maxWidth: 200,
        ),

        // Material information
        TemplateField(
          fieldName: 'materialName',
          x: 50,
          y: 180,
          fontSize: 12,
          bold: true,
          prefix: 'المادة: ',
        ),

        // Weight information
        TemplateField(
          fieldName: 'grossWeight',
          x: 300,
          y: 220,
          fontSize: 14,
          bold: true,
          alignment: 'right',
          format: '#,##0.00',
          prefix: 'الوزن الإجمالي: ',
          suffix: ' كيلو',
        ),
        TemplateField(
          fieldName: 'tareWeight',
          x: 300,
          y: 240,
          fontSize: 14,
          bold: true,
          alignment: 'right',
          format: '#,##0.00',
          prefix: 'وزن الفارغ: ',
          suffix: ' كيلو',
        ),
        TemplateField(
          fieldName: 'netWeight',
          x: 300,
          y: 260,
          fontSize: 16,
          bold: true,
          alignment: 'right',
          format: '#,##0.00',
          prefix: 'الوزن الصافي: ',
          suffix: ' كيلو',
        ),

        // Vehicle information
        TemplateField(
          fieldName: 'truckPlate',
          x: 50,
          y: 320,
          fontSize: 12,
          prefix: 'رقم الشاحنة: ',
        ),
        TemplateField(
          fieldName: 'driverName',
          x: 50,
          y: 340,
          fontSize: 12,
          prefix: 'السائق: ',
        ),

        // Notes
        TemplateField(
          fieldName: 'notes',
          x: 50,
          y: 400,
          fontSize: 10,
          prefix: 'ملاحظات: ',
          maxWidth: 400,
        ),
      ],
    );
  }

  // Private helper methods

  /// Prepare data values from WeighingTab for template rendering
  Map<String, String> _prepareDataValuesFromTab({
    required WeighingTab weighingTab,
    Client? client,
    Supplier? supplier,
    Material? material,
    required DateTime now,
    Map<String, String>? arabicTranslations,
    bool showPrice = false,
  }) {
    final values = <String, String>{};

    // WeighingTab information
    values['tabId'] = (weighingTab.id ?? 0).toString();
    values['tabTitle'] = weighingTab.tabTitle;
    values['orderNumber'] = (weighingTab.id ?? 0).toString();

    values['status'] = weighingTab.status.toUpperCase();
    values['createDate'] = dateToArabicDatetime(DateTime.now());
    values['updateDate'] = dateToArabicDatetime(weighingTab.updatedAt);
    values['weighTareTime'] = weighingTab.scaleEmptyWeightAt != null
        ? dateToArabicDatetimeShort(weighingTab.scaleEmptyWeightAt!)
        : "";
    values['weighGrossTime'] = weighingTab.scaleGrossWeightAt != null
        ? dateToArabicDatetimeShort(weighingTab.scaleGrossWeightAt!)
        : "";

    values['datetime'] = dateToArabicDatetime(DateTime.now());

    // Weight information
    values['grossWeight'] = weighingTab.grossWeight.toString();
    values['emptyWeight'] = weighingTab.emptyWeight.toString();
    values['netWeight'] = weighingTab.netWeight.toString();
    values['isPaid'] = weighingTab.isPaid ? 'مدفوع' : '';
    values['showPriceOnPrint'] = weighingTab.showPriceOnPrint ? 'Yes' : 'No';
    values['clientName'] = weighingTab.client;
    values['supplierName'] = weighingTab.supplier;
    values['materialName'] = weighingTab.material;

    // Client information
    if (client != null) {
      values['clientCity'] = client.city ?? '';
      values['clientPhone'] = client.phone ?? '';
    } else if (weighingTab.supplier.isNotEmpty) {
      // Use the string value from weighingTab if no client object provided

      // Could be either
    }

    // Supplier information
    if (supplier != null) {
      values['supplierName'] = weighingTab.supplier ?? 'مورد';
      values['supplierCity'] = supplier.city ?? '';
      values['supplierPhone'] = supplier.phone ?? '';
    } else if (weighingTab.supplier.isNotEmpty) {
      // Use the string value from weighingTab if no supplier object provided
      values['supplierName'] = weighingTab.supplier;
    }

    // Material information
    if (material != null) {
      values['materialCode'] = material.id?.toString() ?? '';
      values['materialDescription'] = material.description ?? '';
      values['materialListPrice'] =
          material.price?.toStringAsFixed(2) ?? '0.00';
      values['materialStandardPrice'] =
          material.price?.toStringAsFixed(2) ?? '0.00';
    } else if (weighingTab.material.isNotEmpty) {
      // Use the string value from weighingTab if no material object provided
      values['materialName'] = weighingTab.material;
    }
    values['unitPrice'] = weighingTab.kilo_price.toStringAsFixed(2) ?? '';
    values['totalAmount'] = weighingTab.total_price.toStringAsFixed(2) ?? '';
    // Vehicle information
    values['truckPlate'] = weighingTab.truckPlate;
    values['driverName'] = weighingTab.driverName;
    values['driverLicense'] = ''; // Not available in WeighingTab
    //price

    // Additional fields
    values['isPaid'] = values['isPaid']! +
        '\n' +
        weighingTab.notes; // Not available in WeighingTab, could add later
    values['barcode'] = weighingTab.id.toString(); // Use tab ID as barcode
    values['currentDate'] = _formatDate(now);
    values['currentTime'] = _formatTime(now);
    values['currentDateTime'] = _formatDateTime(now);

    // Legacy weight field mappings for existing templates
    values['tareWeight'] =
        weighingTab.emptyWeight.toString(); // Map emptyWeight to tareWeight

    if (!weighingTab.showPriceOnPrint) {
      values['unitPrice'] = '';
      values['totalAmount'] = '';
    }

    // Apply Arabic translations if provided
    // if (arabicTranslations != null) {
    //   for (final entry in arabicTranslations.entries) {
    //     if (values.containsKey(entry.key)) {
    //       values[entry.key] = entry.value;
    //     }
    //   }
    // }

    return values;
  }

  Future<void> _loadFonts() async {
    if (_arabicFont != null && _unicodeFont != null) return;

    try {
      // Load Arabic-supporting fonts
      final arabicFontData = await _getArabicFont();
      if (arabicFontData != null) {
        _arabicFont = pw.Font.ttf(arabicFontData.buffer.asByteData());
        _unicodeFont = _arabicFont; // Use same font for both
      } else {
        // Fallback to system fonts
        final systemFontData = await _getSystemFont();
        if (systemFontData != null) {
          _unicodeFont = pw.Font.ttf(systemFontData.buffer.asByteData());

          _arabicFont = _unicodeFont;
        }
      }
    } catch (e) {
      debugPrint('Failed to load Arabic fonts: $e');
      // Will use default fonts (might not display Arabic correctly)
    }
  }

  Future<void> _loadCustomFonts() async {
    if (_arabicFont != null && _unicodeFont != null) return;

    try {
      // Load Arabic-supporting fonts
      final arabicFontData = await _getArabicFont();
      final normalArabicFontData = await _loadCustomArabicFont('normal');
      final semiBoldArabicFontData = await _loadCustomArabicFont('semibold');
      final boldArabicFontData = await _loadCustomArabicFont('bold');
      final extraBoldArabicFontData = await _loadCustomArabicFont('extrabold');

      if (normalArabicFontData != null &&
          semiBoldArabicFontData != null &&
          boldArabicFontData != null &&
          extraBoldArabicFontData != null) {
        _arabicFont = pw.Font.ttf(normalArabicFontData.buffer.asByteData());
        _arabicSemiBoldFont =
            pw.Font.ttf(semiBoldArabicFontData.buffer.asByteData());
        _arabicBoldFont = pw.Font.ttf(boldArabicFontData.buffer.asByteData());
        _arabicExtraBoldFont =
            pw.Font.ttf(extraBoldArabicFontData.buffer.asByteData());
        _unicodeFont = _arabicFont; // Use same font for both
      } else {
        // Fallback to system fonts
        final systemFontData = await _getSystemFont();
        if (systemFontData != null) {
          _unicodeFont = pw.Font.ttf(systemFontData.buffer.asByteData());

          _arabicFont = _unicodeFont;
        }
      }
    } catch (e) {
      debugPrint('Failed to load Arabic fonts: $e');
      // Will use default fonts (might not display Arabic correctly)
    }
  }

  Future<Uint8List?> _getArabicFont() async {
    try {
      // Common Windows fonts that support Arabic
      const arabicFontPaths = [
        'C:/Windows/Fonts/arial.ttf',
        'C:/Windows/Fonts/tahoma.ttf',
        'C:/Windows/Fonts/calibri.ttf',
        'C:/Windows/Fonts/segoeui.ttf',
        'C:/Windows/Fonts/times.ttf',
        'C:/Windows/Fonts/trebuc.ttf',
      ];

      for (final fontPath in arabicFontPaths) {
        final file = File(fontPath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (e) {
      debugPrint('Error loading Arabic font: $e');
    }
    return null;
  }

  Future<Uint8List?> _loadCustomArabicFont(String fontWeight) async {
    final Map<String, String> fontsPaths = {
      'normal': './used_fonts/NotoSansArabic-Regular.ttf',
      'semibold': './used_fonts/NotoSansArabic-SemiBold.ttf',
      'bold': './used_fonts/NotoSansArabic-Bold.ttf',
      'extrabold': './used_fonts/NotoSansArabic-ExtraBold.ttf'
    };

    try {
      final currentFontPath = fontsPaths[fontWeight];
      final file = File(currentFontPath!);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error loading Arabic font: $e');
    }
    return null;
  }

  Future<Uint8List?> _getSystemFont() async {
    try {
      const systemFontPaths = [
        'C:/Windows/Fonts/arial.ttf',
        'C:/Windows/Fonts/calibri.ttf',
        'C:/Windows/Fonts/segoeui.ttf',
      ];

      for (final fontPath in systemFontPaths) {
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

  PdfPageFormat _getPageFormat(PrintTemplate template) {
    switch (template.paperSize.toLowerCase()) {
      case 'a3':
        return template.orientation == 'landscape'
            ? PdfPageFormat.a3.landscape
            : PdfPageFormat.a3;
      case 'a4':
        return template.orientation == 'landscape'
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4;
      case 'letter':
        return template.orientation == 'landscape'
            ? PdfPageFormat.letter.landscape
            : PdfPageFormat.letter;
      case 'custom':
        if (template.customWidth != null && template.customHeight != null) {
          return PdfPageFormat(
            template.customWidth! * PdfPageFormat.mm,
            template.customHeight! * PdfPageFormat.mm,
          );
        }
        return PdfPageFormat.a4;
      default:
        return PdfPageFormat.a4;
    }
  }

  pw.Widget _buildBackgroundImage(PrintTemplate template) {
    try {
      if (template.backgroundImagePath != null) {
        // Load image from file path for printing
        final file = File(template.backgroundImagePath!);
        if (file.existsSync()) {
          final imageBytes = file.readAsBytesSync();
          return pw.Opacity(
            opacity: template.backgroundImageOpacity,
            child: pw.Image(
              pw.MemoryImage(imageBytes),
              fit: pw.BoxFit.cover,
            ),
          );
        } else {
          debugPrint(
              'Background image file not found: ${template.backgroundImagePath}');
        }
      }
    } catch (e) {
      debugPrint('Error loading background image: $e');
    }
    return pw.Container();
  }

  List<pw.Widget> _buildTemplateFields(
      PrintTemplate template, Map<String, String> dataValues) {
    final widgets = <pw.Widget>[];

    for (final field in template.fields) {
      final value = dataValues[field.fieldName] ?? '';
      if (value.isEmpty && field.fieldName != 'barcode') continue;

      final displayText = _formatFieldValue(value, field);

      widgets.add(
        pw.Positioned(
          left: field.x * PdfPageFormat.mm,
          top: field.y * PdfPageFormat.mm,
          child: _buildFieldWidget(displayText, field),
        ),
      );
    }

    return widgets;
  }

  pw.Widget _buildFieldWidget(String text, TemplateField field) {
    final textAlign = _getTextAlign(field.alignment);
    final fontWeight = field.bold ? pw.FontWeight.bold : pw.FontWeight.normal;

    if (field.fieldName == 'barcode' && text.isNotEmpty) {
      // Generate barcode for barcode fields
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.BarcodeWidget(
            data: text,
            barcode: pw.Barcode.code128(),
            width: 100,
            height: 30,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: field.fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ],
      );
    }

    return pw.Container(
      width: field.maxWidth != null ? field.maxWidth! * PdfPageFormat.mm : null,
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: field.fontSize,
            fontWeight: fontWeight,
            fontBold: _arabicBoldFont),
        textAlign: textAlign,
        textDirection:
            _isArabicText(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
    );
  }

  String _formatFieldValue(String value, TemplateField field) {
    String result = value;

    // Apply number formatting
    if (field.format != null && _isNumeric(value)) {
      try {
        final number = double.parse(value);
        result = _formatNumber(number, field.format!);
      } catch (e) {
        // Keep original value if formatting fails
      }
    }

    // Apply prefix and suffix
    if (field.prefix != null) {
      result = field.prefix! + result;
    }
    if (field.suffix != null) {
      result = result + field.suffix!;
    }

    return result;
  }

  pw.TextAlign _getTextAlign(String alignment) {
    switch (alignment.toLowerCase()) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      default:
        return pw.TextAlign.left;
    }
  }

  bool _isArabicText(String text) {
    // Simple Arabic text detection

    if (text.contains(RegExp(r'[\u0600-\u06FF]'))) {
      printd('the text is Arabic changing direction************');
    }
    return text.contains(RegExp(r'[\u0600-\u06FF]'));
  }

  bool _isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  String _formatNumber(double number, String format) {
    // Simple number formatting - can be enhanced
    if (format.contains('#,##0.00')) {
      return number.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => ',',
          );
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }
}
