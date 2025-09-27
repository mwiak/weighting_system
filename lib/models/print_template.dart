import 'dart:convert';

/// Defines a field position on a pre-printed form
class TemplateField {
  final String fieldName;      // e.g., 'orderNumber', 'clientName', 'netWeight'
  final double x;              // X position in mm from left edge
  final double y;              // Y position in mm from top edge
  final double? maxWidth;      // Maximum width in mm (for text wrapping)
  final String alignment;      // 'left', 'center', 'right'
  final double fontSize;       // Font size in points
  final bool bold;            // Bold text
  final String? format;       // Format string for numbers/dates
  final String? prefix;       // Text to add before value
  final String? suffix;       // Text to add after value

  TemplateField({
    required this.fieldName,
    required this.x,
    required this.y,
    this.maxWidth,
    this.alignment = 'left',
    this.fontSize = 12,
    this.bold = false,
    this.format,
    this.prefix,
    this.suffix,
  });

  factory TemplateField.fromJson(Map<String, dynamic> json) {
    return TemplateField(
      fieldName: json['fieldName'],
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      maxWidth: json['maxWidth']?.toDouble(),
      alignment: json['alignment'] ?? 'left',
      fontSize: (json['fontSize'] ?? 12).toDouble(),
      bold: json['bold'] ?? false,
      format: json['format'],
      prefix: json['prefix'],
      suffix: json['suffix'],
    );
  }

  Map<String, dynamic> toJson() => {
    'fieldName': fieldName,
    'x': x,
    'y': y,
    if (maxWidth != null) 'maxWidth': maxWidth,
    'alignment': alignment,
    'fontSize': fontSize,
    'bold': bold,
    if (format != null) 'format': format,
    if (prefix != null) 'prefix': prefix,
    if (suffix != null) 'suffix': suffix,
  };
}

/// Defines a complete print template for a pre-printed form
class PrintTemplate {
  final String id;
  final String name;
  final String description;
  final String paperSize;      // 'A3', 'A4', 'Letter', 'Custom', etc.
  final String orientation;    // 'portrait' or 'landscape'
  final double? customWidth;   // Width in mm (only for Custom paper size)
  final double? customHeight;  // Height in mm (only for Custom paper size)
  final List<TemplateField> fields;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? backgroundImagePath; // File path for reference image (editor only)
  final double backgroundImageOpacity; // Background image opacity (0.1 to 1.0)
  final bool useBackgroundInPrint; // Whether to include background in printed output

  PrintTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.paperSize,
    required this.orientation,
    this.customWidth,
    this.customHeight,
    required this.fields,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.backgroundImagePath,
    this.backgroundImageOpacity = 0.3,
    this.useBackgroundInPrint = false,
  });

  factory PrintTemplate.fromJson(Map<String, dynamic> json) {
    return PrintTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      paperSize: json['paperSize'],
      orientation: json['orientation'],
      customWidth: json['customWidth']?.toDouble(),
      customHeight: json['customHeight']?.toDouble(),
      fields: (json['fields'] as List)
          .map((field) => TemplateField.fromJson(field))
          .toList(),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      backgroundImagePath: json['backgroundImagePath'],
      backgroundImageOpacity: json['backgroundImageOpacity']?.toDouble() ?? 0.3,
      useBackgroundInPrint: json['useBackgroundInPrint'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'paperSize': paperSize,
    'orientation': orientation,
    if (customWidth != null) 'customWidth': customWidth,
    if (customHeight != null) 'customHeight': customHeight,
    'fields': fields.map((field) => field.toJson()).toList(),
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (backgroundImagePath != null) 'backgroundImagePath': backgroundImagePath,
    'backgroundImageOpacity': backgroundImageOpacity,
    'useBackgroundInPrint': useBackgroundInPrint,
  };

  String toJsonString() => jsonEncode(toJson());
  
  factory PrintTemplate.fromJsonString(String jsonString) {
    return PrintTemplate.fromJson(jsonDecode(jsonString));
  }
}

/// Example A3 weighing ticket template
class DefaultTemplates {
  static PrintTemplate get a3WeighingTicket => PrintTemplate(
    id: 'a3_weighing_default',
    name: 'A3 Weighing Ticket',
    description: 'Default template for A3 pre-printed weighing forms',
    paperSize: 'A3',
    orientation: 'landscape',
    createdAt: DateTime.now(),
    fields: [
      // Header fields
      TemplateField(
        fieldName: 'orderNumber',
        x: 350,  // mm from left
        y: 40,   // mm from top
        fontSize: 14,
        bold: true,
      ),
      TemplateField(
        fieldName: 'date',
        x: 350,
        y: 55,
        fontSize: 12,
        format: 'dd/MM/yyyy',
      ),
      TemplateField(
        fieldName: 'time',
        x: 350,
        y: 65,
        fontSize: 12,
        format: 'HH:mm:ss',
      ),
      
      // Client/Supplier section
      TemplateField(
        fieldName: 'clientName',
        x: 80,
        y: 100,
        maxWidth: 150,
        fontSize: 12,
      ),
      TemplateField(
        fieldName: 'clientAddress',
        x: 80,
        y: 110,
        maxWidth: 150,
        fontSize: 10,
      ),
      TemplateField(
        fieldName: 'clientVat',
        x: 80,
        y: 120,
        fontSize: 10,
        prefix: 'VAT: ',
      ),
      
      // Vehicle information
      TemplateField(
        fieldName: 'truckPlate',
        x: 80,
        y: 150,
        fontSize: 14,
        bold: true,
      ),
      TemplateField(
        fieldName: 'driverName',
        x: 80,
        y: 165,
        fontSize: 12,
      ),
      TemplateField(
        fieldName: 'driverLicense',
        x: 80,
        y: 175,
        fontSize: 10,
      ),
      
      // Material
      TemplateField(
        fieldName: 'materialName',
        x: 250,
        y: 150,
        fontSize: 12,
        bold: true,
      ),
      TemplateField(
        fieldName: 'materialCode',
        x: 250,
        y: 165,
        fontSize: 10,
      ),
      
      // Weight information - positioned for pre-printed weight boxes
      TemplateField(
        fieldName: 'grossWeight',
        x: 150,
        y: 220,
        fontSize: 16,
        bold: true,
        alignment: 'right',
        format: '#,##0.00',
        suffix: ' kg',
      ),
      TemplateField(
        fieldName: 'tareWeight',
        x: 150,
        y: 240,
        fontSize: 16,
        bold: true,
        alignment: 'right',
        format: '#,##0.00',
        suffix: ' kg',
      ),
      TemplateField(
        fieldName: 'netWeight',
        x: 150,
        y: 260,
        fontSize: 18,
        bold: true,
        alignment: 'right',
        format: '#,##0.00',
        suffix: ' kg',
      ),
      
      // Pricing (if needed)
      TemplateField(
        fieldName: 'unitPrice',
        x: 250,
        y: 220,
        fontSize: 12,
        alignment: 'right',
        format: '#,##0.00',
        prefix: '€ ',
      ),
      TemplateField(
        fieldName: 'totalAmount',
        x: 250,
        y: 260,
        fontSize: 14,
        bold: true,
        alignment: 'right',
        format: '#,##0.00',
        prefix: '€ ',
      ),
      
      // Signatures/Notes area
      TemplateField(
        fieldName: 'notes',
        x: 80,
        y: 320,
        maxWidth: 200,
        fontSize: 10,
      ),
      
      // Barcode/QR Code position (if needed)
      TemplateField(
        fieldName: 'barcode',
        x: 320,
        y: 320,
        fontSize: 8,  // For barcode text below
      ),
    ],
  );
}
