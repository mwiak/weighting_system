import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/print_template.dart';
import '../models/weighing_tab.dart';
import '../widgets/template_editor.dart';
import '../services/template_print_service.dart';
import '../services/weighing_tab_template_service.dart';
import '../theme/app_theme.dart';
import '../services/custom_template_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TemplateManagementScreen extends StatefulWidget {
  const TemplateManagementScreen({Key? key}) : super(key: key);

  @override
  State<TemplateManagementScreen> createState() =>
      _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  final TemplatePrintService _printService = TemplatePrintService();
  final CustomTemplateService _customTemplateService = CustomTemplateService();
  final WeighingTabTemplateService _weighingTabTemplateService =
      WeighingTabTemplateService();
  List<PrintTemplate> _templates = [];
  PrintTemplate? _selectedTemplate;
  bool _isLoading = true;

  // Preview zoom and pan controls
  double _previewZoom = 0.7; // Start at 70% zoom
  Offset _previewPan = Offset.zero;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _initializeTransformation();
  }

  void _initializeTransformation() {
    // Set initial zoom to 70%
    _transformationController.value = Matrix4.identity()..scale(_previewZoom);
  }

  void _zoomIn() {
    setState(() {
      _previewZoom = (_previewZoom * 1.2).clamp(0.1, 3.0);
      _transformationController.value = Matrix4.identity()..scale(_previewZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _previewZoom = (_previewZoom / 1.2).clamp(0.1, 3.0);
      _transformationController.value = Matrix4.identity()..scale(_previewZoom);
    });
  }

  void _resetZoom() {
    setState(() {
      _previewZoom = 0.7; // Reset to 70%
      _previewPan = Offset.zero;
      _transformationController.value = Matrix4.identity()..scale(_previewZoom);
    });
  }

  Future<void> _loadTemplates() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load templates from application directory
      final directory = await getApplicationDocumentsDirectory();
      final templatesDir = Directory('${directory.path}/print_templates');

      if (!await templatesDir.exists()) {
        await templatesDir.create(recursive: true);
        // Add default template
        _templates = [DefaultTemplates.a3WeighingTicket];
        await _saveTemplateToFile(DefaultTemplates.a3WeighingTicket);
      } else {
        final files = await templatesDir
            .list()
            .where((entity) => entity is File && entity.path.endsWith('.json'))
            .toList();

        _templates = [];
        for (final file in files) {
          try {
            final jsonString = await (file as File).readAsString();
            final template = PrintTemplate.fromJsonString(jsonString);
            _templates.add(template);
          } catch (e) {
            debugPrint('Error loading template from ${file.path}: $e');
          }
        }

        // Add default if no templates exist
        if (_templates.isEmpty) {
          _templates = [DefaultTemplates.a3WeighingTicket];
          await _saveTemplateToFile(DefaultTemplates.a3WeighingTicket);
        }
      }

      if (_templates.isNotEmpty) {
        _selectedTemplate = _templates.first;
      }
    } catch (e) {
      debugPrint('Error loading templates: $e');
      // Use default template on error
      _templates = [DefaultTemplates.a3WeighingTicket];
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _saveTemplateToFile(PrintTemplate template) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final templatesDir = Directory('${directory.path}/print_templates');

      if (!await templatesDir.exists()) {
        await templatesDir.create(recursive: true);
      }

      final file = File('${templatesDir.path}/${template.id}.json');
      await file.writeAsString(template.toJsonString());
    } catch (e) {
      debugPrint('Error saving template: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return fluent.ScaffoldPage(
      header: fluent.PageHeader(
        title: Text(l10n.printTemplateManagement),
        commandBar: fluent.CommandBar(
          primaryItems: [
            fluent.CommandBarButton(
              icon: const Icon(fluent.FluentIcons.add),
              label: Text(l10n.newTemplate),
              onPressed: _createNewTemplate,
            ),
            fluent.CommandBarButton(
              icon: const Icon(fluent.FluentIcons.edit),
              label: Text(l10n.edit),
              onPressed: _selectedTemplate != null
                  ? () => _editTemplate(_selectedTemplate!)
                  : null,
            ),
            fluent.CommandBarButton(
              icon: const Icon(fluent.FluentIcons.delete),
              label: Text(l10n.delete),
              onPressed: _selectedTemplate != null
                  ? () => _deleteTemplate(_selectedTemplate!)
                  : null,
            ),
            const fluent.CommandBarSeparator(),
            fluent.CommandBarButton(
              icon: const Icon(fluent.FluentIcons.test_case),
              label: Text(l10n.testPrint),
              onPressed: _selectedTemplate != null
                  ? () => _testPrint(_selectedTemplate!)
                  : null,
            ),
            fluent.CommandBarButton(
              icon: const Icon(fluent.FluentIcons.print),
              label: Text(l10n.printAlignmentGrid),
              onPressed: _printAlignmentGrid,
            ),
            const fluent.CommandBarSeparator(),
            fluent.CommandBarButton(
              icon: const Icon(fluent.FluentIcons.save_as),
              label: Text(l10n.exportPdf),
              onPressed: _selectedTemplate != null
                  ? () => _exportTemplateToPDF(_selectedTemplate!)
                  : null,
            ),
            const fluent.CommandBarSeparator(),
            fluent.CommandBarButton(
              icon: const Icon(fluent.FluentIcons.save_as),
              label: Text(l10n.exportXps),
              onPressed: _selectedTemplate != null
                  ? () => _exportTemplateToPDF(_selectedTemplate!)
                  : null,
            ),
          ],
        ),
      ),
      content: _isLoading
          ? const Center(child: fluent.ProgressRing())
          : Row(
              children: [
                // Template list
                _buildTemplateList(),

                // Template preview
                Expanded(
                  child: _buildTemplatePreview(),
                ),

                // Template details
                _buildTemplateDetails(),
              ],
            ),
    );
  }

  Widget _buildTemplateList() {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 300,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: AppTheme.borderColor,
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 60, // Fixed height to prevent constraint issues
              padding: const EdgeInsets.all(12),
              color: fluent.FluentTheme.of(context).cardColor,
              child: fluent.TextBox(
                placeholder: l10n.searchTemplates,
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(fluent.FluentIcons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final template = _templates[index];
                  final isSelected = _selectedTemplate?.id == template.id;

                  return fluent.ListTile(
                    leading: Icon(
                      fluent.FluentIcons.page,
                      color: isSelected
                          ? fluent.FluentTheme.of(context).accentColor
                          : null,
                    ),
                    title: Text(template.name),
                    subtitle:
                        Text('${template.paperSize} - ${template.orientation}'),
                    trailing: template.isActive
                        ? const Icon(fluent.FluentIcons.accept, size: 12)
                        : null,
                    onPressed: () {
                      setState(() {
                        _selectedTemplate = template;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePreview() {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedTemplate == null) {
      return Center(
        child: Text(l10n.selectTemplateToPreview),
      );
    }

    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: fluent.FluentTheme.of(context).cardColor,
            child: Row(
              children: [
                const Icon(fluent.FluentIcons.preview),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.templatePreview}: ${_selectedTemplate!.name}',
                    style: fluent.FluentTheme.of(context).typography.bodyStrong,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Zoom controls
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.remove),
                  onPressed: () => _zoomOut(),
                ),
                Text('${(_previewZoom * 100).toInt()}%'),
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.add),
                  onPressed: () => _zoomIn(),
                ),
                const SizedBox(width: 4),
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.fit_page),
                  onPressed: () => _resetZoom(),
                ),
                const SizedBox(width: 4),
                fluent.Button(
                  child: Text(l10n.print),
                  onPressed: () => _quickPrint(_selectedTemplate!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withOpacity(0.5),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    boundaryMargin: const EdgeInsets.all(50),
                    minScale: 0.1,
                    maxScale: 3.0,
                    onInteractionUpdate: (details) {
                      setState(() {
                        _previewZoom =
                            _transformationController.value.getMaxScaleOnAxis();
                      });
                    },
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: _buildPreviewCanvas(_selectedTemplate!),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCanvas(PrintTemplate template) {
    // Calculate paper size
    final paperDimensions = {
      'A3': const Size(297, 420),
      'A4': const Size(210, 297),
      'A5': const Size(148, 210),
      'Letter': const Size(216, 279),
      'Legal': const Size(216, 356),
    };

    Size baseDimensions;
    if (template.paperSize == 'Custom' &&
        template.customWidth != null &&
        template.customHeight != null) {
      baseDimensions = Size(template.customWidth!, template.customHeight!);
    } else {
      baseDimensions =
          paperDimensions[template.paperSize] ?? const Size(297, 420);
    }
    final paperSize = template.orientation == 'landscape'
        ? Size(baseDimensions.height, baseDimensions.width)
        : baseDimensions;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure we have valid constraints
        final availableWidth =
            (constraints.maxWidth.isFinite && constraints.maxWidth > 0)
                ? constraints.maxWidth - 100
                : 600;
        final availableHeight =
            (constraints.maxHeight.isFinite && constraints.maxHeight > 0)
                ? constraints.maxHeight - 100
                : 800;

        final maxWidth = availableWidth.clamp(200.0, double.infinity);
        final maxHeight = availableHeight.clamp(200.0, double.infinity);

        // Calculate scale to fit within available space
        final scaleX = maxWidth / paperSize.width;
        final scaleY = maxHeight / paperSize.height;
        final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.2, 2.0);

        final double displayWidth =
            (paperSize.width * scale).clamp(100.0, maxWidth).toDouble();
        final double displayHeight =
            (paperSize.height * scale).clamp(100.0, maxHeight).toDouble();
        final displaySize = Size(displayWidth, displayHeight);

        return Container(
          width: displaySize.width,
          height: displaySize.height,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background image if available
              if (template.backgroundImagePath != null)
                Positioned.fill(
                  child: _buildBackgroundImageWidget(template),
                ),
              // Template fields
              ...template.fields.map((field) {
                // Scale field positions
                final left =
                    (field.x * scale).clamp(0.0, displaySize.width - 40);
                final top =
                    (field.y * scale).clamp(0.0, displaySize.height - 20);

                // Ensure valid constraints - avoid negative heights/widths
                final maxWidth =
                    (displaySize.width - left - 8).clamp(20.0, double.infinity);
                final maxHeight =
                    (displaySize.height - top - 4).clamp(16.0, double.infinity);

                // Skip rendering if position is out of bounds
                if (left < 0 ||
                    top < 0 ||
                    left >= displaySize.width ||
                    top >= displaySize.height) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  left: left,
                  top: top,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 20,
                      maxWidth: maxWidth,
                      minHeight: 16,
                      maxHeight: maxHeight,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      field.fieldName,
                      style: TextStyle(
                        fontSize:
                            (field.fontSize * scale * 0.8).clamp(8.0, 14.0),
                        fontWeight:
                            field.bold ? FontWeight.bold : FontWeight.normal,
                        color: AppTheme.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateDetails() {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedTemplate == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 350,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppTheme.borderColor,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.templateDetails,
              style: fluent.FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(l10n.nameLabel, _selectedTemplate!.name),
            _buildDetailRow(l10n.descriptionLabel, _selectedTemplate!.description),
            _buildDetailRow(l10n.paperSizeLabel, _selectedTemplate!.paperSize),
            _buildDetailRow(l10n.orientationLabel, _selectedTemplate!.orientation),
            _buildDetailRow(l10n.fieldsLabel, '${_selectedTemplate!.fields.length}'),
            _buildDetailRow(
                l10n.statusLabel, _selectedTemplate!.isActive ? l10n.active : l10n.inactive),
            _buildDetailRow(
                l10n.createdLabel, _formatDate(_selectedTemplate!.createdAt)),
            if (_selectedTemplate!.updatedAt != null)
              _buildDetailRow(
                  l10n.updatedLabel, _formatDate(_selectedTemplate!.updatedAt!)),
            const SizedBox(height: 24),
            Text(
              l10n.fields,
              style: fluent.FluentTheme.of(context).typography.bodyStrong,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _selectedTemplate!.fields.isNotEmpty
                  ? ListView.builder(
                      itemCount: _selectedTemplate!.fields.length,
                      itemBuilder: (context, index) {
                        final field = _selectedTemplate!.fields[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field.fieldName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Position: (${field.x.toStringAsFixed(1)}, ${field.y.toStringAsFixed(1)}) mm',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.secondaryTextColor),
                                ),
                                Text(
                                  '${l10n.fontLabel} ${field.fontSize}${l10n.pt}${field.bold ? ", ${l10n.bold}" : ""}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.secondaryTextColor),
                                ),
                                if (field.format != null)
                                  Text(
                                    '${l10n.formatLabel} ${field.format}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        l10n.noFieldsInTemplate,
                        style: const TextStyle(color: AppTheme.secondaryTextColor),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImageWidget(PrintTemplate template) {
    final l10n = AppLocalizations.of(context)!;

    try {
      final file = File(template.backgroundImagePath!);
      if (file.existsSync()) {
        return Opacity(
          opacity: template.backgroundImageOpacity,
          child: Image.file(
            file,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        );
      } else {
        return Container(
          color: Colors.grey.withOpacity(0.3),
          child: Center(
            child: Text(l10n.backgroundImageNotFound),
          ),
        );
      }
    } catch (e) {
      return Container(
        color: Colors.red.withOpacity(0.3),
        child: Center(
          child: Text(l10n.errorLoadingBackgroundImage),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _createNewTemplate() {
    Navigator.of(context).push(
      fluent.FluentPageRoute(
        builder: (context) => TemplateEditor(
          onSave: (template) async {
            await _saveTemplateToFile(template);
            await _loadTemplates();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _editTemplate(PrintTemplate template) {
    Navigator.of(context).push(
      fluent.FluentPageRoute(
        builder: (context) => TemplateEditor(
          initialTemplate: template,
          onSave: (updatedTemplate) async {
            // Update the template with the same ID
            final templateWithId = PrintTemplate(
              id: template.id,
              name: updatedTemplate.name,
              description: updatedTemplate.description,
              paperSize: updatedTemplate.paperSize,
              orientation: updatedTemplate.orientation,
              customWidth: updatedTemplate.customWidth,
              customHeight: updatedTemplate.customHeight,
              fields: updatedTemplate.fields,
              isActive: template.isActive,
              createdAt: template.createdAt,
              updatedAt: DateTime.now(),
            );

            await _saveTemplateToFile(templateWithId);
            await _loadTemplates();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _deleteTemplate(PrintTemplate template) {
    final l10n = AppLocalizations.of(context)!;

    fluent.showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return fluent.ContentDialog(
          title: Text(l10n.deleteTemplate),
          content: Text('${l10n.areYouSureDeleteTemplate} "${template.name}"?'),
          actions: [
            fluent.Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            fluent.FilledButton(
              style: fluent.ButtonStyle(
                backgroundColor:
                    fluent.WidgetStateProperty.all(AppTheme.errorColor),
              ),
              child: Text(l10n.delete),
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  final directory = await getApplicationDocumentsDirectory();
                  final file = File(
                      '${directory.path}/print_templates/${template.id}.json');
                  if (await file.exists()) {
                    await file.delete();
                  }
                  await _loadTemplates();
                } catch (e) {
                  final l10n = AppLocalizations.of(context)!;
                  fluent.showDialog(
                    context: context,
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return fluent.ContentDialog(
                        title: Text(l10n.error),
                        content: Text('${l10n.failedToDeleteTemplate}: $e'),
                        actions: [
                          fluent.Button(
                            child: Text(l10n.ok),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _testPrint(PrintTemplate template) async {
    final l10n = AppLocalizations.of(context)!;

    // Show print options dialog
    fluent.showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return fluent.ContentDialog(
          title: Text(l10n.testPrintOptions),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.chooseTestPrintMethod),
              const SizedBox(height: 16),
              fluent.Button(
                child: Text(l10n.printWithXps),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performTestXpsPrint(template);
                },
              ),
              const SizedBox(height: 16),
              fluent.Button(
                child: Text(l10n.silentPrintWindowsDirect),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performTestPrint(template, useDialog: false);
                },
              ),
              const SizedBox(height: 8),
              fluent.Button(
                child: Text(l10n.printWithDialogPreview),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performTestPrint(template, useDialog: true);
                },
              ),
            ],
          ),
          actions: [
            fluent.Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performTestXpsPrint(PrintTemplate template) async {
    // Create test data
    final testData = <String, dynamic>{};

    // Fill with sample data including Arabic text for testing
    for (final field in template.fields) {
      switch (field.fieldName) {
        case 'orderNumber':
          testData[field.fieldName] = 'TEST-001';
          break;
        case 'date':
        case 'time':
        case 'weighInTime':
        case 'weighOutTime':
          testData[field.fieldName] = DateTime.now().toIso8601String();
          break;
        case 'grossWeight':
          testData[field.fieldName] = '15000';
          break;
        case 'tareWeight':
          testData[field.fieldName] = '5000';
          break;
        case 'netWeight':
          testData[field.fieldName] = '10000';
          break;
        case 'unitPrice':
          testData[field.fieldName] = '25.50';
          break;
        case 'totalAmount':
          testData[field.fieldName] = '255000';
          break;
        case 'truckPlate':
          testData[field.fieldName] = '1234';
          break;
        case 'driverName':
          testData[field.fieldName] = 'محمد أحمد'; // Test Arabic
          break;
        case 'clientName':
          testData[field.fieldName] = 'شركة الاختبار';
          break;
        case 'materialName':
          testData[field.fieldName] = 'بيرين';
          break;
        default:
          testData[field.fieldName] = '[${field.fieldName}]';
      }
    }

    try {
      // Get default printer for silent printing
      String? defaultPrinter;

      // Create test WeighingTab for template printing
      final testTab = WeighingTab();
      testTab.truckPlate = '2356';
      testTab.driverName = 'حمودة البكري';
      testTab.supplier = 'ابراهيم';
      testTab.client = 'مصطفى صفية';
      testTab.material = 'بيرين';
      testTab.grossWeight = 15000;
      testTab.emptyWeight = 8000;
      testTab.status = 'completed';

      await _printService.printWithTemplateXps(
        context,
        template: template,
        weighingTab: testTab,
        printerName: defaultPrinter,
      );
    } catch (e) {
      debugPrint('Test print error: $e');
      if (mounted) {
        fluent.showDialog(
          context: context,
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return fluent.ContentDialog(
              title: const Text('Silent Print Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.silentPrintingFailed),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      e.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.possibleSolutions),
                  const Text('• Try "Print with Dialog" option'),
                  const Text('• Check if printer is connected and online'),
                  const Text('• Ensure printer drivers are installed'),
                  const Text('• Run application as Administrator'),
                ],
              ),
              actions: [
                fluent.Button(
                  child: Text(l10n.ok),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _performTestPrint(PrintTemplate template,
      {required bool useDialog}) async {
    // Create test data
    final testData = <String, dynamic>{};

    // Fill with sample data including Arabic text for testing
    for (final field in template.fields) {
      switch (field.fieldName) {
        case 'orderNumber':
          testData[field.fieldName] = 'TEST-001';
          break;
        case 'date':
        case 'time':
        case 'weighInTime':
        case 'weighOutTime':
          testData[field.fieldName] = DateTime.now().toIso8601String();
          break;
        case 'grossWeight':
          testData[field.fieldName] = '15000';
          break;
        case 'tareWeight':
          testData[field.fieldName] = '5000';
          break;
        case 'netWeight':
          testData[field.fieldName] = '10000';
          break;
        case 'unitPrice':
          testData[field.fieldName] = '25.50';
          break;
        case 'totalAmount':
          testData[field.fieldName] = '255000';
          break;
        case 'truckPlate':
          testData[field.fieldName] = '1234';
          break;
        case 'driverName':
          testData[field.fieldName] = 'محمد أحمد'; // Test Arabic
          break;
        case 'clientName':
          testData[field.fieldName] = 'شركة الاختبار';
          break;
        case 'materialName':
          testData[field.fieldName] = 'بيرين';
          break;
        default:
          testData[field.fieldName] = '[${field.fieldName}]';
      }
    }

    try {
      // Get default printer for silent printing
      String? defaultPrinter;
      if (!useDialog) {
        // DISABLED: final printers = await _printService.getAvailablePrinters();
        final printers = <String>[];
        defaultPrinter = printers.isNotEmpty ? printers.first : null;
      }

      // Create test WeighingTab for template printing
      final testTab = WeighingTab();
      testTab.truckPlate = 'TEST123';
      testTab.driverName = 'Test Driver';
      testTab.supplier = 'Test Client';
      testTab.client = 'Test Client';
      testTab.material = 'Test Material';
      testTab.grossWeight = 15000;
      testTab.emptyWeight = 8000;
      testTab.status = 'completed';

      await _printService.printWithTemplate(
        context,
        template: template,
        weighingTab: testTab,
        preview: useDialog,
        useDialog: useDialog,
        silentPrint: !useDialog,
        printerName: defaultPrinter,
      );

      if (!useDialog && mounted) {
        // Show success message for silent printing
        fluent.showDialog(
          context: context,
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return fluent.ContentDialog(
              title: Text(l10n.printSuccess),
              content: Text(l10n.templatePrintedSuccess),
              actions: [
                fluent.Button(
                  child: Text(l10n.ok),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Test print error: $e');
      if (mounted) {
        fluent.showDialog(
          context: context,
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return fluent.ContentDialog(
              title: const Text('Silent Print Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.silentPrintingFailed),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      e.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.possibleSolutions),
                  const Text('• Try "Print with Dialog" option'),
                  const Text('• Check if printer is connected and online'),
                  const Text('• Ensure printer drivers are installed'),
                  const Text('• Run application as Administrator'),
                ],
              ),
              actions: [
                fluent.Button(
                  child: Text(l10n.ok),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _quickPrint(PrintTemplate template) async {
    // Template printing temporarily disabled - OrderProvider removed
    // TODO: Implement template printing with WeighingTab system
    const orders = <dynamic>[];

    if (orders.isEmpty) {
      fluent.showDialog(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return fluent.ContentDialog(
            title: Text(l10n.error),
            content: const Text('There are no active orders to print.'),
            actions: [
              fluent.Button(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;
    }

    // Show order selection dialog
    fluent.showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return fluent.ContentDialog(
          title: const Text('Select Order to Print'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return fluent.ListTile(
                  title: Text('Order: ${order.orderNumber}'),
                  subtitle: Text(
                      'Truck: ${order.truckPlate} | Net: ${order.netWeight} kg'),
                  onPressed: () async {
                    Navigator.of(context).pop();

                    // Show print options for quick print
                    fluent.showDialog(
                      context: context,
                      builder: (quickPrintContext) {
                        final l10n = AppLocalizations.of(quickPrintContext)!;
                        return fluent.ContentDialog(
                          title: const Text('Quick Print Options'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              fluent.Button(
                                child: const Text('Silent Print (Windows Direct)'),
                                onPressed: () async {
                                  Navigator.of(quickPrintContext).pop();
                                  try {
                                    // Get default printer for silent printing
                                    // DISABLED: final printers = await _printService.getAvailablePrinters();
                                    final printers = <String>[];
                                    final defaultPrinter =
                                        printers.isNotEmpty ? printers.first : null;

                                    // DISABLED: Template printing temporarily disabled
                                    throw Exception(
                                        'Template printing is temporarily disabled');
                                    // Show success for silent printing
                                    _showPrintSuccess(
                                        'Order ${order.orderNumber} printed successfully using Windows direct printing.');
                                  } catch (e) {
                                    debugPrint('Quick print silent error: $e');
                                    _showDetailedPrintError(
                                        'Quick Print (Silent)', e.toString());
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              fluent.Button(
                                child: const Text('Print with Dialog'),
                                onPressed: () async {
                                  Navigator.of(quickPrintContext).pop();
                                  try {
                                    // DISABLED: Template printing temporarily disabled
                                    throw Exception(
                                        'Template printing is temporarily disabled');
                                  } catch (e) {
                                    debugPrint('Quick print dialog error: $e');
                                    _showDetailedPrintError(
                                        'Quick Print (Dialog)', e.toString());
                                  }
                                },
                              ),
                            ],
                          ),
                          actions: [
                            fluent.Button(
                              child: Text(l10n.cancel),
                              onPressed: () =>
                                  Navigator.of(quickPrintContext).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            fluent.Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _printAlignmentGrid() async {
    // Show paper size selection
    fluent.showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        String selectedSize = 'A3';
        String selectedOrientation = 'landscape';

        return fluent.ContentDialog(
          title: const Text('Print Alignment Grid'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Select paper size and orientation for the alignment grid:'),
                  const SizedBox(height: 16),
                  fluent.ComboBox<String>(
                    placeholder: Text('Paper Size'),
                    value: selectedSize,
                    items: ['A3', 'A4', 'A5', 'Letter', 'Legal'].map((size) {
                      return fluent.ComboBoxItem<String>(
                        value: size,
                        child: Text(size),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedSize = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  fluent.RadioButton(
                    checked: selectedOrientation == 'portrait',
                    onChanged: (value) {
                      if (value) {
                        setState(() => selectedOrientation = 'portrait');
                      }
                    },
                    content: const Text('Portrait'),
                  ),
                  const SizedBox(height: 8),
                  fluent.RadioButton(
                    checked: selectedOrientation == 'landscape',
                    onChanged: (value) {
                      if (value) {
                        setState(() => selectedOrientation = 'landscape');
                      }
                    },
                    content: const Text('Landscape'),
                  ),
                ],
              );
            },
          ),
          actions: [
            fluent.Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            fluent.FilledButton(
              child: Text(l10n.print),
              onPressed: () async {
                Navigator.of(context).pop();

                // DISABLED: final calibrationTemplate = TemplatePrintService.createCalibrationTemplate(...);
                final calibrationTemplate = null;

                // Show print options for alignment grid
                fluent.showDialog(
                  context: context,
                  builder: (alignmentContext) {
                    final l10n = AppLocalizations.of(alignmentContext)!;
                    return fluent.ContentDialog(
                      title: const Text('Alignment Grid Print Options'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          fluent.Button(
                            child: const Text('Silent Print (Windows Direct)'),
                            onPressed: () async {
                              Navigator.of(alignmentContext).pop();
                              try {
                                // Get default printer for silent printing
                                // DISABLED: Template printing temporarily disabled
                                throw Exception(
                                    'Template printing is temporarily disabled');
                                _showPrintSuccess(
                                    'Alignment grid printed successfully using Windows direct printing.');
                              } catch (e) {
                                debugPrint('Alignment grid silent error: $e');
                                _showDetailedPrintError(
                                    'Alignment Grid (Silent)', e.toString());
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          fluent.Button(
                            child: const Text('Print with Dialog'),
                            onPressed: () async {
                              Navigator.of(alignmentContext).pop();
                              try {
                                // DISABLED: Template printing temporarily disabled
                                throw Exception(
                                    'Template printing is temporarily disabled');
                              } catch (e) {
                                debugPrint('Alignment grid dialog error: $e');
                                _showDetailedPrintError(
                                    'Alignment Grid (Dialog)', e.toString());
                              }
                            },
                          ),
                        ],
                      ),
                      actions: [
                        fluent.Button(
                          child: Text(l10n.cancel),
                          onPressed: () => Navigator.of(alignmentContext).pop(),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDetailedPrintError(String operation, String error) {
    if (mounted) {
      fluent.showDialog(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: Text('$operation Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$operation failed with the following error:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                width: double.maxFinite,
                child: SelectableText(
                  error,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Troubleshooting:'),
              const Text('• Check printer connection and status'),
              const Text('• Verify printer drivers are installed'),
              const Text('• Try running as Administrator'),
              const Text('• Use "Print with Dialog" as alternative'),
              const Text('• Check Windows printer spooler service'),
            ],
          ),
          actions: [
            fluent.Button(
              child: const Text('Copy Error'),
              onPressed: () {
                // Copy error to clipboard for debugging
                // You might want to add clipboard functionality here
                Navigator.of(context).pop();
              },
            ),
            fluent.Button(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  void _showPrintSuccess(String message) {
    if (mounted) {
      fluent.showDialog(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('Print Success'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(message),
            ],
          ),
          actions: [
            fluent.Button(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  void _exportTemplateToPDF(PrintTemplate template) async {
    // Show data options dialog
    fluent.showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return fluent.ContentDialog(
          title: const Text('Export Template to PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose the data source for the PDF export:'),
              const SizedBox(height: 16),
              fluent.Button(
                child: const Text('Export with Sample Data'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performPDFExport(template, useSampleData: true);
                },
              ),
              const SizedBox(height: 8),
              fluent.Button(
                child: const Text('Export with Real Order Data'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _selectOrderForExport(template);
                },
              ),
              const SizedBox(height: 8),
              fluent.Button(
                child: const Text('Export Empty Template (Field Names Only)'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performPDFExport(template, useEmptyData: true);
                },
              ),
            ],
          ),
          actions: [
            fluent.Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _exportTemplateToXPS(PrintTemplate template) async {
    // Show data options dialog
    fluent.showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return fluent.ContentDialog(
          title: const Text('Export Template to PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose the data source for the PDF export:'),
              const SizedBox(height: 16),
              fluent.Button(
                child: const Text('Export with Sample Data'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performPDFExport(template, useSampleData: true);
                },
              ),
            ],
          ),
          actions: [
            fluent.Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectOrderForExport(PrintTemplate template) async {
    // Template export temporarily disabled - OrderProvider removed
    // TODO: Implement template export with WeighingTab system
    const orders = <dynamic>[];

    if (orders.isEmpty) {
      fluent.showDialog(
        context: context,
        builder: (context) {
          return fluent.ContentDialog(
            title: const Text('No Orders Available'),
            content: const Text(
                'There are no active orders. Using sample data instead.'),
            actions: [
              fluent.Button(
                child: const Text('OK'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performPDFExport(template, useSampleData: true);
                },
              ),
            ],
          );
        },
      );
      return;
    }

    // Show order selection dialog
    fluent.showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return fluent.ContentDialog(
          title: const Text('Select Order for PDF Export'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return fluent.ListTile(
                  title: Text('Order: ${order.orderNumber}'),
                  subtitle: Text(
                      'Truck: ${order.truckPlate} | Net: ${order.netWeight} kg'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _performPDFExport(template);
                  },
                );
              },
            ),
          ),
          actions: [
            fluent.Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performPDFExport(PrintTemplate template,
      {bool useSampleData = false, bool useEmptyData = false}) async {
    try {
      // Show loading dialog
      fluent.showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const fluent.ContentDialog(
          title: Text('Exporting PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              fluent.ProgressRing(),
              SizedBox(height: 16),
              Text('Generating PDF with Arabic support...'),
            ],
          ),
        ),
      );

      // Prepare data based on options
      Map<String, String>? arabicTranslations;

      if (useSampleData) {
        // Create Arabic sample data
        arabicTranslations = {
          'orderNumber': 'طلب رقم TEST-001',
          'clientName': 'شركة الاختبار المحدودة',
          'materialName': 'مادة البناء الأساسية',
          'driverName': 'محمد أحمد السائق',
          'truckPlate': 'أ ب ج - 1234',
          'grossWeight': '15000.00',
          'tareWeight': '5000.00',
          'netWeight': '10000.00',
          'notes': 'هذا نص تجريبي لاختبار اللغة العربية في القالب',
        };
      } else if (useEmptyData) {
        // Use field names as values for empty template
        arabicTranslations = {};
        for (final field in template.fields) {
          arabicTranslations[field.fieldName] = '[${field.fieldName}]';
        }
      }

      // Create a sample WeighingTab for PDF export
      final sampleTab = WeighingTab();
      sampleTab.truckPlate = useSampleData ? 'ABC123' : '[truck_plate]';
      sampleTab.driverName = useSampleData ? 'John Doe' : '[driver_name]';
      sampleTab.supplier = useSampleData ? 'Sample Client Ltd.' : '[supplier]';
      sampleTab.material = useSampleData ? 'Gravel' : '[material]';
      sampleTab.grossWeight = useSampleData ? 15000 : 0;
      sampleTab.emptyWeight = useSampleData ? 8000 : 0;
      sampleTab.isPaid = false;
      sampleTab.status = 'completed';

      final pdfBytes =
          await _weighingTabTemplateService.generateWeighingTabTemplatePDF(
        weighingTab: sampleTab,
        template: template,
        arabicTranslations: arabicTranslations,
      );

      // Save PDF to Downloads folder
      final downloadsDir =
          Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      final fileName =
          'template_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${downloadsDir.path}\\$fileName');
      await file.writeAsBytes(pdfBytes);

      final filePath = file.path;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog
      fluent.showDialog(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('PDF Export Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
              const SizedBox(height: 16),
              Text(
                  'Template "${template.name}" has been exported to PDF successfully.'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  'Export temporarily disabled',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Features included in the exported PDF:'),
              const Text('• Arabic text support with proper rendering'),
              const Text('• Custom field positioning'),
              const Text('• Formatted data values'),
              const Text('• Background image (if set)'),
            ],
          ),
          actions: [
            fluent.Button(
              child: const Text('Open Folder'),
              onPressed: () async {
                // DISABLED: Export functionality temporarily disabled
                Navigator.of(context).pop();
              },
            ),
            fluent.FilledButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      // Show error dialog
      fluent.showDialog(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('Export Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Failed to export template to PDF:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  e.toString(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            fluent.Button(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _performXPSExport(PrintTemplate template,
      {bool useSampleData = false, bool useEmptyData = false}) async {
    try {
      // Show loading dialog
      fluent.showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const fluent.ContentDialog(
          title: Text('Exporting XPS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              fluent.ProgressRing(),
              SizedBox(height: 16),
              Text('Generating PDF with Arabic support...'),
            ],
          ),
        ),
      );

      // Prepare data based on options
      Map<String, String>? arabicTranslations;

      if (useSampleData) {
        // Create Arabic sample data
        arabicTranslations = {
          'orderNumber': '1234',
          'clientName': 'شركة الاختبار المحدودة',
          'materialName': 'مادة البناء الأساسية',
          'driverName': 'محمد أحمد',
          'truckPlate': '85069',
          'grossWeight': '15000',
          'tareWeight': '5000',
          'netWeight': '10000',
          'notes': 'هذا نص تجريبي لاختبار اللغة العربية في القالب',
        };
      } else if (useEmptyData) {
        // Use field names as values for empty template
        arabicTranslations = {};
        for (final field in template.fields) {
          arabicTranslations[field.fieldName] = '[${field.fieldName}]';
        }
      }

      // Create a sample WeighingTab for PDF export
      final sampleTab = WeighingTab();
      sampleTab.truckPlate = useSampleData ? '1234' : '[truck_plate]';
      sampleTab.driverName =
          useSampleData ? 'عبد الرحمن قصار' : '[driver_name]';
      sampleTab.supplier = useSampleData ? 'ابراهيم الشيخ' : '[supplier]';
      sampleTab.client = useSampleData ? 'حسان عبد الرحيم' : '[supplier]';
      sampleTab.material = useSampleData ? 'بيرين' : '[material]';
      sampleTab.grossWeight = useSampleData ? 15000 : 0;
      sampleTab.emptyWeight = useSampleData ? 8000 : 0;
      sampleTab.isPaid = false;
      sampleTab.status = 'completed';

      final pdfBytes =
          await _weighingTabTemplateService.generateWeighingTabTemplatePDF(
        weighingTab: sampleTab,
        template: template,
        arabicTranslations: arabicTranslations,
      );

      // Save PDF to Downloads folder
      final downloadsDir =
          Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      final fileName =
          'template_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${downloadsDir.path}\\$fileName');
      await file.writeAsBytes(pdfBytes);

      final filePath = file.path;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog
      fluent.showDialog(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('PDF Export Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
              const SizedBox(height: 16),
              Text(
                  'Template "${template.name}" has been exported to PDF successfully.'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  'Export temporarily disabled',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Features included in the exported PDF:'),
              const Text('• Arabic text support with proper rendering'),
              const Text('• Custom field positioning'),
              const Text('• Formatted data values'),
              const Text('• Background image (if set)'),
            ],
          ),
          actions: [
            fluent.Button(
              child: const Text('Open Folder'),
              onPressed: () async {
                // DISABLED: Export functionality temporarily disabled
                Navigator.of(context).pop();
              },
            ),
            fluent.FilledButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      // Show error dialog
      fluent.showDialog(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('Export Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Failed to export template to PDF:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  e.toString(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            fluent.Button(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }
}
