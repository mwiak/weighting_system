import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../models/weighing_tab.dart';
import '../models/print_template.dart';
import '../models/client.dart';
import '../models/supplier.dart';
import '../models/material.dart';
import '../models/print_job.dart';
import 'template_print_service.dart';
import 'custom_template_service.dart';

/// Bridge service for WeighingTab template operations
/// Provides a clean API for template printing with automatic data lookup
class WeighingTabTemplateService {
  static final WeighingTabTemplateService _instance =
      WeighingTabTemplateService._internal();
  factory WeighingTabTemplateService() => _instance;
  WeighingTabTemplateService._internal();

  final TemplatePrintService _templatePrintService = TemplatePrintService();
  final CustomTemplateService _customTemplateService = CustomTemplateService();

  /// Print WeighingTab using a template with automatic client/supplier/material lookup
  Future<PrintJob?> printWeighingTabWithTemplate({
    BuildContext? context,
    required WeighingTab weighingTab,
    required PrintTemplate template,
    Client? client,
    Supplier? supplier,
    Material? material,
    String? printerName,
    bool preview = false,
    bool useDialog = false,
    bool silentPrint = false,
    Future<Client?> Function(String name)? clientLookup,
    Future<Supplier?> Function(String name)? supplierLookup,
    Future<Material?> Function(String name)? materialLookup,
  }) async {
    try {
      // Use provided entities or lookup by name if lookup functions provided
      Client? finalClient = client;
      Supplier? finalSupplier = supplier;
      Material? finalMaterial = material;

      if (finalClient == null && weighingTab.supplier.isNotEmpty) {
        if (clientLookup != null) {
          finalClient = await clientLookup(weighingTab.supplier);
        }
      }

      if (finalSupplier == null && weighingTab.supplier.isNotEmpty) {
        if (supplierLookup != null) {
          finalSupplier = await supplierLookup(weighingTab.supplier);
        }
      }

      if (finalMaterial == null &&
          weighingTab.material.isNotEmpty &&
          materialLookup != null) {
        finalMaterial = await materialLookup(weighingTab.material);
      }

      // Use template print service
      if (context == null) {
        throw ArgumentError('Context is required for template printing');
      }

      return await _templatePrintService.printWithTemplate(
        context,
        template: template,
        weighingTab: weighingTab,
        client: finalClient,
        supplier: finalSupplier,
        material: finalMaterial,
        printerName: printerName,
        preview: preview,
        useDialog: useDialog,
        silentPrint: silentPrint,
      );
    } catch (e) {
      debugPrint('Error printing weighing tab with template: $e');
      rethrow;
    }
  }

  /// Generate PDF for preview without printing
  Future<List<int>> generateWeighingTabTemplatePDF({
    required WeighingTab weighingTab,
    required PrintTemplate template,
    Client? client,
    Supplier? supplier,
    Material? material,
    Map<String, String>? arabicTranslations,
  }) async {
    try {
      final pdf = await _customTemplateService.generateCustomTemplatePDF(
        template: template,
        weighingTab: weighingTab,
        client: client,
        supplier: supplier,
        material: material,
        arabicTranslations: arabicTranslations,
      );

      return await pdf.save();
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      rethrow;
    }
  }

  /// Get all available templates
  Future<List<PrintTemplate>> getAvailableTemplates() async {
    try {
      return await _customTemplateService.getAllTemplates();
    } catch (e) {
      debugPrint('Error loading templates: $e');
      return [];
    }
  }

  /// Load a specific template by ID
  Future<PrintTemplate?> getTemplate(String templateId) async {
    try {
      return await _customTemplateService.loadTemplate(templateId);
    } catch (e) {
      debugPrint('Error loading template $templateId: $e');
      return null;
    }
  }

  /// Save a template
  Future<String?> saveTemplate(PrintTemplate template) async {
    try {
      return await _customTemplateService.saveTemplate(template);
    } catch (e) {
      debugPrint('Error saving template: $e');
      return null;
    }
  }

  /// Delete a template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      return await _customTemplateService.deleteTemplate(templateId);
    } catch (e) {
      debugPrint('Error deleting template: $e');
      return false;
    }
  }

  /// Create a default template adapted for WeighingTab
  PrintTemplate createDefaultWeighingTabTemplate() {
    return PrintTemplate(
      id: 'weighing_tab_default',
      name: 'Default WeighingTab Template',
      description: 'Default template for WeighingTab printing',
      paperSize: 'A4',
      orientation: 'portrait',
      createdAt: DateTime.now(),
      fields: [
        // Header fields
        TemplateField(
          fieldName: 'tabTitle',
          x: 50,
          y: 30,
          fontSize: 16,
          bold: true,
          prefix: 'Tab: ',
        ),
        TemplateField(
          fieldName: 'currentDate',
          x: 150,
          y: 30,
          fontSize: 12,
        ),
        TemplateField(
          fieldName: 'status',
          x: 50,
          y: 50,
          fontSize: 12,
          prefix: 'Status: ',
        ),

        // Vehicle information
        TemplateField(
          fieldName: 'truckPlate',
          x: 50,
          y: 80,
          fontSize: 14,
          bold: true,
          prefix: 'Truck: ',
        ),
        TemplateField(
          fieldName: 'driverName',
          x: 50,
          y: 100,
          fontSize: 12,
          prefix: 'Driver: ',
        ),

        // Business information
        TemplateField(
          fieldName: 'supplierName',
          x: 50,
          y: 130,
          fontSize: 12,
          prefix: 'Client/Supplier: ',
        ),
        TemplateField(
          fieldName: 'materialName',
          x: 50,
          y: 150,
          fontSize: 12,
          prefix: 'Material: ',
        ),

        // Weight information
        TemplateField(
          fieldName: 'grossWeight',
          x: 50,
          y: 180,
          fontSize: 14,
          bold: true,
          format: '#,##0.00',
          prefix: 'Gross Weight: ',
          suffix: ' kg',
        ),
        TemplateField(
          fieldName: 'emptyWeight',
          x: 50,
          y: 200,
          fontSize: 14,
          bold: true,
          format: '#,##0.00',
          prefix: 'Empty Weight: ',
          suffix: ' kg',
        ),
        TemplateField(
          fieldName: 'netWeight',
          x: 50,
          y: 220,
          fontSize: 16,
          bold: true,
          format: '#,##0.00',
          prefix: 'NET WEIGHT: ',
          suffix: ' kg',
        ),

        // Additional information
        TemplateField(
          fieldName: 'operationType',
          x: 50,
          y: 250,
          fontSize: 12,
          prefix: 'Operation: ',
        ),
        TemplateField(
          fieldName: 'isPaid',
          x: 50,
          y: 270,
          fontSize: 12,
          prefix: 'Payment: ',
        ),

        // Barcode
        TemplateField(
          fieldName: 'barcode',
          x: 50,
          y: 300,
          fontSize: 8,
        ),
      ],
    );
  }

  /// Get available variables for template creation
  Map<String, String> get availableVariables =>
      CustomTemplateService.availableVariables;
}
