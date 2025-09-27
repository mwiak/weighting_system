import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../services/weighing_tab_print_service.dart';
import '../services/weighing_tab_template_service.dart';
import '../models/weighing_tab.dart';
import '../models/client.dart';
import '../models/supplier.dart';
import '../models/material.dart';
import '../models/printer_info.dart';
import '../models/print_job.dart';
import '../models/print_template.dart';

class PrintProvider extends ChangeNotifier {
  final WeighingTabPrintService _printService = WeighingTabPrintService();
  final WeighingTabTemplateService _templateService = WeighingTabTemplateService();

  bool _isPrinting = false;
  String? _lastError;
  String? _lastPrintedDocument;

  // Print settings
  bool _silentPrintEnabled = false;
  String? _selectedPrinter;
  String _selectedPaperSize = 'A4';
  List<PrinterInfo> _availablePrinters = [];

  // Print history
  final List<PrintJob> _printHistory = [];
  PrintJob? _lastPrintJob;

  // Template settings
  List<PrintTemplate> _availableTemplates = [];
  PrintTemplate? _selectedTemplate;
  bool _templatesLoaded = false;

  // Getters
  bool get isPrinting => _isPrinting;
  bool get isLoading => _isPrinting;
  String? get lastError => _lastError;
  String? get lastPrintedDocument => _lastPrintedDocument;
  bool get silentPrintEnabled => _silentPrintEnabled;
  String? get selectedPrinter => _selectedPrinter;
  String get selectedPaperSize => _selectedPaperSize;
  List<PrinterInfo> get availablePrinters =>
      List.unmodifiable(_availablePrinters);
  List<PrintJob> get printHistory => List.unmodifiable(_printHistory);
  PrintJob? get lastPrintJob => _lastPrintJob;

  // Template getters
  List<PrintTemplate> get availableTemplates =>
      List.unmodifiable(_availableTemplates);
  PrintTemplate? get selectedTemplate => _selectedTemplate;
  bool get templatesLoaded => _templatesLoaded;

  // Company settings
  Map<String, String> get companyInfo => const {
        'name': 'Truck Weighing Systems Ltd.',
        'address': '123 Industrial Road, City, State 12345',
        'phone': '+1 (555) 123-4567',
        'email': 'info@weighingsystems.com',
        'website': 'www.weighingsystems.com',
        'taxId': 'TAX123456789',
      };

  PrintProvider() {
    _initialize();
  }

  /// Initialize the provider
  Future<void> _initialize() async {
    try {
      await _loadAvailablePrinters();
      debugPrint(
          'PrintProvider: Initialized with ${_availablePrinters.length} printers');
    } catch (e) {
      debugPrint('PrintProvider: Failed to initialize: $e');
      _setError('Failed to initialize printer: $e');
    }
  }

  Future<void> _loadAvailablePrinters() async {
    try {
      _availablePrinters = await _printService.getAvailablePrinters();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load available printers: $e');
    }
  }

  Future<bool> checkPrinterAvailability() async {
    try {
      final info = await Printing.info();
      return info.canPrint;
    } catch (e) {
      _setError('Failed to check printer availability: $e');
      return false;
    }
  }

  // Settings methods
  void setSilentPrint(bool enabled) {
    _silentPrintEnabled = enabled;
    notifyListeners();
  }

  void setSelectedPrinter(String? printerName) {
    _selectedPrinter = printerName;
    notifyListeners();
  }

  void setPaperSize(String paperSize) {
    _selectedPaperSize = paperSize;
    notifyListeners();
  }

  PdfPageFormat? getCustomPaperSize() {
    switch (_selectedPaperSize) {
      case 'A4':
        return PdfPageFormat.a4;
      case 'A5':
        return PdfPageFormat.a5;
      case 'Letter':
        return PdfPageFormat.letter;
      case 'Custom':
        return PdfPageFormat.letter; // Default fallback
      default:
        return PdfPageFormat.a4;
    }
  }

  void setLoading(bool loading) {
    _isPrinting = loading;
    if (loading) {
      _lastError = null;
    }
    notifyListeners();
  }

  void addPrintHistory(String documentName, String message, bool success) {
    final printJob = PrintJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      printerName: _selectedPrinter ?? 'Default',
      documentName: documentName,
      type: PrintJobType.weighingTicket,
      status: success ? PrintJobStatus.completed : PrintJobStatus.failed,
      createdAt: DateTime.now(),
      completedAt: success ? DateTime.now() : null,
      totalPages: 1,
      printedPages: success ? 1 : 0,
      errorMessage: success ? null : message,
    );

    _printHistory.insert(0, printJob);
    _lastPrintJob = printJob;

    // Keep only last 50 print jobs
    if (_printHistory.length > 50) {
      _printHistory.removeRange(50, _printHistory.length);
    }

    notifyListeners();
  }

  /// Print a weighing ticket
  Future<bool> printWeighingTicket({
    required WeighingTab tab,
    Client? client,
    Supplier? supplier,
    Material? material,
  }) async {
    if (_isPrinting) {
      _setError('Another print job is already in progress');
      return false;
    }

    _setPrinting(true);
    try {
      await _printService.printWeighingTicket(
        tab: tab,
        client: client,
        supplier: supplier,
        material: material,
        silentPrint: _silentPrintEnabled,
        printerName: _selectedPrinter,
        customPaperSize: getCustomPaperSize(),
      );

      _lastPrintedDocument = 'Weighing Ticket - ${tab.tabTitle}';
      addPrintHistory(
          'Weighing Ticket - ${tab.tabTitle}', 'Printed successfully', true);
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to print weighing ticket: $e');
      addPrintHistory(
          'Weighing Ticket - ${tab.tabTitle}', 'Print failed: $e', false);
      return false;
    } finally {
      _setPrinting(false);
    }
  }

  /// Print a receipt
  Future<bool> printReceipt({
    required WeighingTab tab,
    Client? client,
    Supplier? supplier,
    Material? material,
  }) async {
    if (_isPrinting) {
      _setError('Another print job is already in progress');
      return false;
    }

    _setPrinting(true);
    try {
      await _printService.printReceipt(
        tab: tab,
        client: client,
        supplier: supplier,
        material: material,
        silentPrint: _silentPrintEnabled,
        printerName: _selectedPrinter,
        customPaperSize: getCustomPaperSize(),
      );

      _lastPrintedDocument = 'Receipt - ${tab.tabTitle}';
      addPrintHistory(
          'Receipt - ${tab.tabTitle}', 'Printed successfully', true);
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to print receipt: $e');
      addPrintHistory('Receipt - ${tab.tabTitle}', 'Print failed: $e', false);
      return false;
    } finally {
      _setPrinting(false);
    }
  }

  Future<bool> testPrinter(String printerName) async {
    try {
      return await _printService.testPrinter(printerName);
    } catch (e) {
      _setError('Failed to test printer: $e');
      return false;
    }
  }

  void refreshPrinters() {
    _loadAvailablePrinters();
  }

  void clearHistory() {
    _printHistory.clear();
    _lastPrintJob = null;
    notifyListeners();
  }

  void _setPrinting(bool printing) {
    _isPrinting = printing;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    _isPrinting = false;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    notifyListeners();
  }

  // Template methods

  /// Load available templates
  Future<void> loadTemplates() async {
    try {
      _availableTemplates = await _templateService.getAvailableTemplates();
      _templatesLoaded = true;

      // Select first template if none selected and templates available
      if (_selectedTemplate == null && _availableTemplates.isNotEmpty) {
        _selectedTemplate = _availableTemplates.first;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading templates: $e');
      _setError('Failed to load templates: $e');
    }
  }

  /// Set selected template
  void setSelectedTemplate(PrintTemplate? template) {
    _selectedTemplate = template;
    notifyListeners();
  }

  /// Print weighing tab with template
  Future<void> printWithTemplate({
    required WeighingTab weighingTab,
    required PrintTemplate template,
    Client? client,
    Supplier? supplier,
    Material? material,
    bool preview = false,
  }) async {
    try {
      setLoading(true);
      _clearError();

      // Use the template service to print
      await _templateService.printWeighingTabWithTemplate(
        context: null, // Note: Context is required but we don't have it here
        weighingTab: weighingTab,
        template: template,
        client: client,
        supplier: supplier,
        material: material,
        silentPrint: _silentPrintEnabled,
        printerName: _selectedPrinter,
        useDialog: !_silentPrintEnabled,
        preview: preview,
      );

      // Add to print history
      addPrintHistory(
        'Template Print - ${weighingTab.tabTitle}',
        'Printed successfully with template: ${template.name}',
        true,
      );

      _lastPrintedDocument = 'Template Print - ${weighingTab.tabTitle}';
    } catch (e) {
      _setError('Template printing failed: $e');

      // Add failed job to history
      addPrintHistory(
        'Template Print - ${weighingTab.tabTitle}',
        'Print failed: $e',
        false,
      );
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  /// Generate template PDF
  Future<List<int>> generateTemplatePDF({
    required WeighingTab weighingTab,
    required PrintTemplate template,
    Client? client,
    Supplier? supplier,
    Material? material,
    Map<String, String>? arabicTranslations,
  }) async {
    try {
      setLoading(true);
      _clearError();

      final pdfBytes = await _templateService.generateWeighingTabTemplatePDF(
        weighingTab: weighingTab,
        template: template,
        client: client,
        supplier: supplier,
        material: material,
        arabicTranslations: arabicTranslations,
      );

      addPrintHistory(
        'Template PDF - ${weighingTab.tabTitle}',
        'PDF generated successfully with template: ${template.name}',
        true,
      );

      return pdfBytes;
    } catch (e) {
      _setError('Template PDF generation failed: $e');

      addPrintHistory(
        'Template PDF - ${weighingTab.tabTitle}',
        'PDF generation failed: $e',
        false,
      );
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  /// Create default template
  PrintTemplate createDefaultTemplate() {
    return _templateService.createDefaultWeighingTabTemplate();
  }

  /// Save template
  Future<String?> saveTemplate(PrintTemplate template) async {
    try {
      final result = await _templateService.saveTemplate(template);

      // Reload templates to include the new one
      await loadTemplates();

      return result;
    } catch (e) {
      _setError('Failed to save template: $e');
      return null;
    }
  }

  /// Delete template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      final result = await _templateService.deleteTemplate(templateId);

      if (result) {
        // Remove from local list
        _availableTemplates.removeWhere((t) => t.id == templateId);

        // Update selected template if it was deleted
        if (_selectedTemplate?.id == templateId) {
          _selectedTemplate = _availableTemplates.isNotEmpty ? _availableTemplates.first : null;
        }

        notifyListeners();
      }

      return result;
    } catch (e) {
      _setError('Failed to delete template: $e');
      return false;
    }
  }

}
