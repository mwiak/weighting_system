import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../models/print_template.dart';
import '../theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// Visual template editor with drag-and-drop functionality
class TemplateEditor extends StatefulWidget {
  final PrintTemplate? initialTemplate;
  final Function(PrintTemplate)? onSave;

  const TemplateEditor({
    Key? key,
    this.initialTemplate,
    this.onSave,
  }) : super(key: key);

  @override
  State<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<TemplateEditor> {
  // Template properties
  late String _templateName;
  late String _templateDescription;
  late String _paperSize;
  late String _orientation;

  // Canvas properties
  double _canvasScale = 1.0;
  Offset _canvasOffset = Offset.zero;

  // Background image properties
  String? _backgroundImagePath;
  double _backgroundImageOpacity = 0.3;
  bool _useBackgroundInPrint = false;

  // Fields
  List<TemplateFieldItem> _fields = [];
  TemplateFieldItem? _selectedField;

  // Paper dimensions in mm
  final Map<String, Size> _paperDimensions = {
    'A3': const Size(297, 420),
    'A4': const Size(210, 297),
    'A5': const Size(148, 210),
    'Letter': const Size(216, 279),
    'Legal': const Size(216, 356),
    'Custom': const Size(297, 420), // Default custom size
  };

  // Custom paper dimensions
  double _customWidth = 297;
  double _customHeight = 420;

  // Available field variables
  final List<FieldVariable> _availableVariables = [
    // Order fields
    FieldVariable(
        'orderNumber', 'Order Number', Icons.numbers, AppTheme.primaryColor),
    FieldVariable('date', 'Date', Icons.calendar_today, AppTheme.successColor),
    FieldVariable('time', 'Time', Icons.access_time, AppTheme.successColor),
    FieldVariable(
        'datetime', 'Datetime', Icons.access_time, AppTheme.successColor),
    FieldVariable('operationType', 'Operation Type', Icons.swap_horiz,
        AppTheme.accentColor),
    FieldVariable('status', 'Status', Icons.info, AppTheme.secondaryColor),

    // Client fields
    FieldVariable('clientName', 'Client Name', Icons.person,
        AppTheme.loadingOperationColor),
    FieldVariable('clientAddress', 'Client Address', Icons.location_on,
        AppTheme.loadingOperationColor),
    FieldVariable('clientVat', 'Client VAT', Icons.receipt,
        AppTheme.loadingOperationColor),
    FieldVariable('clientPhone', 'Client Phone', Icons.phone,
        AppTheme.loadingOperationColor),
    FieldVariable('clientEmail', 'Client Email', Icons.email,
        AppTheme.loadingOperationColor),

    // Supplier fields
    FieldVariable('supplierName', 'Supplier Name', Icons.business,
        AppTheme.unloadingOperationColor),
    FieldVariable('supplierAddress', 'Supplier Address', Icons.location_on,
        AppTheme.unloadingOperationColor),
    FieldVariable('supplierVat', 'Supplier VAT', Icons.receipt,
        AppTheme.unloadingOperationColor),

    // Vehicle fields
    FieldVariable('truckPlate', 'Truck Plate', Icons.local_shipping,
        AppTheme.warningColor),
    FieldVariable(
        'driverName', 'Driver Name', Icons.person, AppTheme.warningColor),
    FieldVariable(
        'driverLicense', 'Driver License', Icons.badge, AppTheme.warningColor),

    // Material fields
    FieldVariable(
        'materialName', 'Material Name', Icons.inventory, AppTheme.accentColor),
    FieldVariable(
        'materialCode', 'Material Code', Icons.qr_code, AppTheme.accentColor),
    FieldVariable('materialDescription', 'Material Description',
        Icons.description, AppTheme.accentColor),

    // Weight fields
    FieldVariable(
        'grossWeight', 'Gross Weight', Icons.scale, AppTheme.errorColor),
    FieldVariable(
        'tareWeight', 'Tare Weight', Icons.scale, AppTheme.errorColor),
    FieldVariable('netWeight', 'Net Weight', Icons.scale, AppTheme.errorColor),

    // Financial fields
    FieldVariable(
        'unitPrice', 'Unit Price', Icons.attach_money, AppTheme.successColor),
    FieldVariable(
        'totalAmount', 'Total Amount', Icons.payments, AppTheme.successColor),

    // Time fields
    FieldVariable(
        'weighTareTime', 'Weigh Tare Time', Icons.login, AppTheme.primaryColor),
    FieldVariable('weighGrossTime', 'Weigh Gross Time', Icons.logout,
        AppTheme.primaryColor),

    // Other fields
    FieldVariable('notes', 'Notes', Icons.note, AppTheme.secondaryTextColor),
    FieldVariable(
        'barcode', 'Barcode', Icons.qr_code_scanner, AppTheme.primaryTextColor),
    FieldVariable(
        'isPaid', 'isPaid', Icons.monetization_on, AppTheme.primaryTextColor),
    FieldVariable('operator', 'Operator', Icons.person_outline_sharp,
        AppTheme.primaryTextColor),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplate != null) {
      _loadTemplate(widget.initialTemplate!);
    } else {
      _templateName = 'New Template';
      _templateDescription = 'Custom print template';
      _paperSize = 'A3';
      _orientation = 'landscape';
    }
  }

  void _loadTemplate(PrintTemplate template) {
    _templateName = template.name;
    _templateDescription = template.description;
    _paperSize = template.paperSize;
    _orientation = template.orientation;

    // Load custom dimensions if it's a custom paper size
    if (template.paperSize == 'Custom') {
      _customWidth = template.customWidth ?? 297;
      _customHeight = template.customHeight ?? 420;
    }

    // Load background image if available
    _backgroundImagePath = template.backgroundImagePath;
    _backgroundImageOpacity = template.backgroundImageOpacity;
    _useBackgroundInPrint = template.useBackgroundInPrint;

    _fields = template.fields
        .map((field) => TemplateFieldItem(
              field: field,
              position: Offset(field.x, field.y),
            ))
        .toList();
  }

  Size get _canvasSize {
    Size baseDimensions;
    if (_paperSize == 'Custom') {
      baseDimensions = Size(_customWidth, _customHeight);
    } else {
      baseDimensions = _paperDimensions[_paperSize] ?? const Size(297, 420);
    }
    return _orientation == 'landscape'
        ? Size(baseDimensions.height, baseDimensions.width)
        : baseDimensions;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 1200 || screenSize.height < 800;

    return fluent.ScaffoldPage(
      header: _buildHeader(),
      content: _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel - Available variables
        _buildVariablesPanel(),

        // Center - Canvas
        Expanded(
          flex: 3,
          child: _buildCanvas(),
        ),

        // Right panel - Properties
        _buildPropertiesPanel(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        // Top toolbar with paper controls
        _buildCompactToolbar(),

        // Main content area
        Expanded(
          child: Row(
            children: [
              // Collapsed variables panel
              _buildCollapsibleVariablesPanel(),

              // Canvas takes most space
              Expanded(
                flex: 4,
                child: _buildCanvas(),
              ),

              // Compact properties panel
              _buildCompactPropertiesPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: fluent.FluentTheme.of(context).cardColor,
      child: Row(
        children: [
          fluent.IconButton(
            icon: const Icon(fluent.FluentIcons.back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _templateName,
                  style: fluent.FluentTheme.of(context).typography.subtitle,
                ),
                Text(
                  _templateDescription,
                  style: fluent.FluentTheme.of(context).typography.caption,
                ),
              ],
            ),
          ),
          fluent.Button(
            child: const Text('Save Template'),
            onPressed: _saveTemplate,
          ),
          const SizedBox(width: 8),
          fluent.Button(
            child: const Text('Export'),
            onPressed: _exportTemplate,
          ),
          const SizedBox(width: 8),
          fluent.Button(
            child: const Text('Import'),
            onPressed: _importTemplate,
          ),
          const SizedBox(width: 8),
          fluent.Button(
            child: const Text('Background'),
            onPressed: _showBackgroundDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildVariablesPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth < 1400 ? 220.0 : 250.0;

    return Container(
      width: panelWidth,
      color: fluent.FluentTheme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: fluent.FluentTheme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Fields',
                  style: fluent.FluentTheme.of(context).typography.bodyStrong,
                ),
                const SizedBox(height: 8),
                fluent.TextBox(
                  placeholder: 'Search fields...',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(fluent.FluentIcons.search),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _availableVariables.length,
              itemBuilder: (context, index) {
                final variable = _availableVariables[index];
                return Draggable<FieldVariable>(
                  data: variable,
                  feedback: _buildDragFeedback(variable),
                  dragAnchorStrategy: (draggable, context, position) {
                    // Custom anchor strategy to center the feedback widget on the cursor
                    final feedbackSize =
                        Size(120, 36); // Approximate feedback size
                    return Offset(
                      feedbackSize.width / 2,
                      feedbackSize.height / 2,
                    );
                  },
                  childWhenDragging: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(variable.icon,
                            color: variable.color.withOpacity(0.5), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variable.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryTextColor
                                      .withOpacity(0.5),
                                ),
                              ),
                              Text(
                                variable.fieldName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.secondaryTextColor
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(variable.icon, color: variable.color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variable.displayName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryTextColor,
                                ),
                              ),
                              Text(
                                variable.fieldName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildCanvas() {
    return Container(
      color: AppTheme.surfaceColor,
      child: Column(
        children: [
          // Canvas toolbar
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: fluent.FluentTheme.of(context).cardColor,
            child: Row(
              children: [
                // Paper size selector
                SizedBox(
                  width: 120,
                  child: fluent.ComboBox<String>(
                    value: _paperSize,
                    items: _paperDimensions.keys.map((size) {
                      return fluent.ComboBoxItem<String>(
                        value: size,
                        child: Text(size),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _paperSize = value;
                          if (value == 'Custom') {
                            _showCustomPaperDialog();
                          }
                        });
                      }
                    },
                    placeholder: const Text('Paper Size'),
                  ),
                ),
                const SizedBox(width: 16),
                // Orientation selector
                fluent.ToggleSwitch(
                  checked: _orientation == 'landscape',
                  onChanged: (value) {
                    setState(() {
                      _orientation = value ? 'landscape' : 'portrait';
                    });
                  },
                  content: Text(
                      _orientation == 'landscape' ? 'Landscape' : 'Portrait'),
                ),
                const Spacer(),
                // Zoom controls
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.remove),
                  onPressed: () {
                    setState(() {
                      _canvasScale = (_canvasScale - 0.1).clamp(0.5, 2.0);
                    });
                  },
                ),
                Text('${(_canvasScale * 100).toInt()}%'),
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.add),
                  onPressed: () {
                    setState(() {
                      _canvasScale = (_canvasScale + 0.1).clamp(0.5, 2.0);
                    });
                  },
                ),
                const SizedBox(width: 8),
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.fit_page),
                  onPressed: _fitToScreen,
                ),
              ],
            ),
          ),
          // Canvas area
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _canvasOffset += details.delta;
                });
              },
              child: Builder(builder: (context) {
                return DragTarget<FieldVariable>(
                  onWillAcceptWithDetails: (details) => true,
                  onAcceptWithDetails: (details) {
                    // Get the RenderBox to calculate accurate positioning
                    final RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    final localOffset = renderBox.globalToLocal(details.offset);
                    _addFieldToCanvas(details.data, localOffset);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Stack(
                      children: [
                        // Grid background
                        CustomPaint(
                          size: Size.infinite,
                          painter: GridPainter(),
                        ),
                        // Paper
                        Positioned(
                          left: _canvasOffset.dx + 50,
                          top: _canvasOffset.dy + 50,
                          child: Transform.scale(
                            scale: _canvasScale,
                            alignment: Alignment.topLeft,
                            child: _buildPaper(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaper() {
    final size = _canvasSize;
    // Convert mm to pixels (assuming 96 DPI, 1mm ≈ 3.78 pixels)
    final pixelSize = Size(size.width * 3.78, size.height * 3.78);

    return Container(
      width: pixelSize.width,
      height: pixelSize.height,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: WeighingTheme.cardShadow,
      ),
      child: Stack(
        children: [
          // Background image (if set)
          if (_backgroundImagePath != null)
            Positioned.fill(
              child: _buildBackgroundImageWidget(),
            ),
          // Ruler guides
          CustomPaint(
            size: pixelSize,
            painter: RulerPainter(mmSize: size),
          ),
          // Fields
          ..._fields.map((fieldItem) => _buildFieldWidget(fieldItem)),
        ],
      ),
    );
  }

  Widget _buildFieldWidget(TemplateFieldItem fieldItem) {
    final field = fieldItem.field;
    // Convert mm to pixels
    final left = field.x * 3.78;
    final top = field.y * 3.78;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedField = fieldItem;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            // Convert pixel movement to mm with 200% increased sensitivity
            final sensitivity =
                3.0 / _canvasScale; // 200% increase: 1.0 * 3.0 = 3.0
            final deltaX = details.delta.dx * sensitivity;
            final deltaY = details.delta.dy * sensitivity;

            final newX = (left + deltaX) / 3.78;
            final newY = (top + deltaY) / 3.78;

            fieldItem.field = TemplateField(
              fieldName: field.fieldName,
              x: newX.clamp(0, _canvasSize.width),
              y: newY.clamp(0, _canvasSize.height),
              maxWidth: field.maxWidth,
              alignment: field.alignment,
              fontSize: field.fontSize,
              bold: field.bold,
              format: field.format,
              prefix: field.prefix,
              suffix: field.suffix,
            );
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _selectedField == fieldItem
                ? AppTheme.primaryColor.withOpacity(0.3)
                : AppTheme.borderColor.withOpacity(0.2),
            border: Border.all(
              color: _selectedField == fieldItem
                  ? AppTheme.primaryColor
                  : AppTheme.borderColor,
              width: _selectedField == fieldItem ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getDisplayText(field),
                style: TextStyle(
                  fontSize: field.fontSize,
                  fontWeight: field.bold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (_selectedField == fieldItem) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _removeField(fieldItem),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: AppTheme.cardColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth < 1400 ? 280.0 : 300.0;

    return Container(
      width: panelWidth,
      color: fluent.FluentTheme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: fluent.FluentTheme.of(context).cardColor,
            child: Row(
              children: [
                const Icon(fluent.FluentIcons.settings),
                const SizedBox(width: 8),
                Text(
                  'Properties',
                  style: fluent.FluentTheme.of(context).typography.bodyStrong,
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedField != null
                ? _buildFieldProperties(_selectedField!)
                : _buildTemplateProperties(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateProperties() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Template Properties',
            style: fluent.FluentTheme.of(context).typography.bodyStrong,
          ),
          const SizedBox(height: 16),
          const Text('Template Name'),
          const SizedBox(height: 4),
          fluent.TextBox(
            placeholder: 'Enter template name',
            controller: TextEditingController(text: _templateName),
            onChanged: (value) => _templateName = value,
          ),
          const SizedBox(height: 12),
          const Text('Description'),
          const SizedBox(height: 4),
          fluent.TextBox(
            placeholder: 'Enter description',
            controller: TextEditingController(text: _templateDescription),
            maxLines: 3,
            onChanged: (value) => _templateDescription = value,
          ),
          const SizedBox(height: 24),
          Text(
            'Canvas Info',
            style: fluent.FluentTheme.of(context).typography.bodyStrong,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
              'Paper Size:',
              _paperSize == 'Custom'
                  ? 'Custom (${_customWidth.toInt()}×${_customHeight.toInt()}mm)'
                  : _paperSize),
          _buildInfoRow('Orientation:', _orientation),
          _buildInfoRow('Width:', '${_canvasSize.width.toInt()} mm'),
          _buildInfoRow('Height:', '${_canvasSize.height.toInt()} mm'),
          _buildInfoRow('Fields:', '${_fields.length}'),
          _buildInfoRow(
              'Background:', _backgroundImagePath != null ? 'Set' : 'None'),
        ],
      ),
    );
  }

  Widget _buildBackgroundImageWidget() {
    try {
      final file = File(_backgroundImagePath!);
      if (file.existsSync()) {
        return Opacity(
          opacity: _backgroundImageOpacity,
          child: Image.file(
            file,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        );
      } else {
        return Container(
          color: Colors.grey.withOpacity(0.3),
          child: const Center(
            child: Text('Background image not found'),
          ),
        );
      }
    } catch (e) {
      return Container(
        color: Colors.red.withOpacity(0.3),
        child: const Center(
          child: Text('Error loading background image'),
        ),
      );
    }
  }

  Widget _buildFieldProperties(TemplateFieldItem fieldItem) {
    final field = fieldItem.field;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Field Properties',
            style: fluent.FluentTheme.of(context).typography.bodyStrong,
          ),
          const SizedBox(height: 8),
          Text(
            field.fieldName,
            style: fluent.FluentTheme.of(context).typography.caption,
          ),
          const SizedBox(height: 16),

          // Position
          const Text('Position'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('X (mm)', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    fluent.NumberBox<double>(
                      value: field.x,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            fieldItem.field = TemplateField(
                              fieldName: field.fieldName,
                              x: value,
                              y: field.y,
                              maxWidth: field.maxWidth,
                              alignment: field.alignment,
                              fontSize: field.fontSize,
                              bold: field.bold,
                              format: field.format,
                              prefix: field.prefix,
                              suffix: field.suffix,
                            );
                          });
                        }
                      },
                      min: 0,
                      max: _canvasSize.width,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Y (mm)', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    fluent.NumberBox<double>(
                      value: field.y,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            fieldItem.field = TemplateField(
                              fieldName: field.fieldName,
                              x: field.x,
                              y: value,
                              maxWidth: field.maxWidth,
                              alignment: field.alignment,
                              fontSize: field.fontSize,
                              bold: field.bold,
                              format: field.format,
                              prefix: field.prefix,
                              suffix: field.suffix,
                            );
                          });
                        }
                      },
                      min: 0,
                      max: _canvasSize.height,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Font settings
          const Text('Font Size'),
          const SizedBox(height: 4),
          fluent.NumberBox<double>(
            value: field.fontSize,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  fieldItem.field = TemplateField(
                    fieldName: field.fieldName,
                    x: field.x,
                    y: field.y,
                    maxWidth: field.maxWidth,
                    alignment: field.alignment,
                    fontSize: value,
                    bold: field.bold,
                    format: field.format,
                    prefix: field.prefix,
                    suffix: field.suffix,
                  );
                });
              }
            },
            min: 6,
            max: 72,
          ),
          const SizedBox(height: 12),

          fluent.Checkbox(
            checked: field.bold,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  fieldItem.field = TemplateField(
                    fieldName: field.fieldName,
                    x: field.x,
                    y: field.y,
                    maxWidth: field.maxWidth,
                    alignment: field.alignment,
                    fontSize: field.fontSize,
                    bold: value,
                    format: field.format,
                    prefix: field.prefix,
                    suffix: field.suffix,
                  );
                });
              }
            },
            content: const Text('Bold'),
          ),
          const SizedBox(height: 12),

          // Alignment
          const Text('Alignment'),
          const SizedBox(height: 4),
          fluent.ComboBox<String>(
            value: field.alignment,
            items: ['left', 'center', 'right'].map((align) {
              return fluent.ComboBoxItem<String>(
                value: align,
                child: Text(align),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  fieldItem.field = TemplateField(
                    fieldName: field.fieldName,
                    x: field.x,
                    y: field.y,
                    maxWidth: field.maxWidth,
                    alignment: value,
                    fontSize: field.fontSize,
                    bold: field.bold,
                    format: field.format,
                    prefix: field.prefix,
                    suffix: field.suffix,
                  );
                });
              }
            },
          ),
          const SizedBox(height: 12),

          // Format
          const Text('Format'),
          const SizedBox(height: 4),
          fluent.TextBox(
            placeholder: 'e.g., dd/MM/yyyy or #,##0.00',
            controller: TextEditingController(text: field.format),
            onChanged: (value) {
              fieldItem.field = TemplateField(
                fieldName: field.fieldName,
                x: field.x,
                y: field.y,
                maxWidth: field.maxWidth,
                alignment: field.alignment,
                fontSize: field.fontSize,
                bold: field.bold,
                format: value.isEmpty ? null : value,
                prefix: field.prefix,
                suffix: field.suffix,
              );
            },
          ),
          const SizedBox(height: 12),

          // Prefix/Suffix
          const Text('Prefix'),
          const SizedBox(height: 4),
          fluent.TextBox(
            placeholder: 'Text before value',
            controller: TextEditingController(text: field.prefix),
            onChanged: (value) {
              fieldItem.field = TemplateField(
                fieldName: field.fieldName,
                x: field.x,
                y: field.y,
                maxWidth: field.maxWidth,
                alignment: field.alignment,
                fontSize: field.fontSize,
                bold: field.bold,
                format: field.format,
                prefix: value.isEmpty ? null : value,
                suffix: field.suffix,
              );
            },
          ),
          const SizedBox(height: 12),

          const Text('Suffix'),
          const SizedBox(height: 4),
          fluent.TextBox(
            placeholder: 'Text after value',
            controller: TextEditingController(text: field.suffix),
            onChanged: (value) {
              fieldItem.field = TemplateField(
                fieldName: field.fieldName,
                x: field.x,
                y: field.y,
                maxWidth: field.maxWidth,
                alignment: field.alignment,
                fontSize: field.fontSize,
                bold: field.bold,
                format: field.format,
                prefix: field.prefix,
                suffix: value.isEmpty ? null : value,
              );
            },
          ),
          const SizedBox(height: 24),

          fluent.FilledButton(
            style: fluent.ButtonStyle(
              backgroundColor:
                  fluent.WidgetStateProperty.all(AppTheme.errorColor),
            ),
            child: const Text('Remove Field'),
            onPressed: () => _removeField(fieldItem),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.secondaryTextColor)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDragFeedback(FieldVariable variable) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: variable.color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(variable.icon, color: AppTheme.cardColor, size: 18),
            const SizedBox(width: 8),
            Text(
              variable.displayName,
              style: const TextStyle(
                color: AppTheme.cardColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addFieldToCanvas(FieldVariable variable, [Offset? dropOffset]) {
    setState(() {
      double x = 50; // Default position
      double y = 50 + (_fields.length * 20.0); // Stack fields vertically

      // If dropped at a specific location, use that position
      if (dropOffset != null) {
        final canvasPosition = _getCanvasPosition(dropOffset);
        x = (canvasPosition.dx / 3.78).clamp(0, _canvasSize.width);
        y = (canvasPosition.dy / 3.78).clamp(0, _canvasSize.height);
      }

      final newField = TemplateField(
        fieldName: variable.fieldName,
        x: x,
        y: y,
        fontSize: 12,
        bold: false,
      );

      _fields.add(TemplateFieldItem(
        field: newField,
        position: Offset(newField.x, newField.y),
      ));
    });
  }

  Offset _getCanvasPosition(Offset localOffset) {
    // localOffset is now relative to the DragTarget widget
    // Account for paper positioning within the canvas
    final paperLeft = _canvasOffset.dx + 50;
    final paperTop = _canvasOffset.dy + 50;

    // Calculate position relative to the paper
    final paperRelativeX = (localOffset.dx - paperLeft) / _canvasScale;
    final paperRelativeY = (localOffset.dy - paperTop) / _canvasScale;

    return Offset(paperRelativeX, paperRelativeY);
  }

  void _removeField(TemplateFieldItem fieldItem) {
    setState(() {
      _fields.remove(fieldItem);
      if (_selectedField == fieldItem) {
        _selectedField = null;
      }
    });
  }

  String _getDisplayText(TemplateField field) {
    String text = field.fieldName;
    if (field.prefix != null) text = '${field.prefix}$text';
    if (field.suffix != null) text = '$text${field.suffix}';
    return text;
  }

  void _fitToScreen() {
    // Calculate scale to fit paper in view
    // Implementation depends on available space
    setState(() {
      _canvasScale = 0.8;
      _canvasOffset = Offset.zero;
    });
  }

  void _saveTemplate() {
    final template = PrintTemplate(
      id: widget.initialTemplate?.id ??
          'template_${DateTime.now().millisecondsSinceEpoch}',
      name: _templateName,
      description: _templateDescription,
      paperSize: _paperSize,
      orientation: _orientation,
      customWidth: _paperSize == 'Custom' ? _customWidth : null,
      customHeight: _paperSize == 'Custom' ? _customHeight : null,
      fields: _fields.map((item) => item.field).toList(),
      createdAt: widget.initialTemplate?.createdAt ?? DateTime.now(),
      updatedAt: widget.initialTemplate != null ? DateTime.now() : null,
      backgroundImagePath: _backgroundImagePath,
      backgroundImageOpacity: _backgroundImageOpacity,
      useBackgroundInPrint: _useBackgroundInPrint,
    );

    if (widget.onSave != null) {
      widget.onSave!(template);
    }

    // Show success message
    fluent.showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: const Text('Success'),
        content: const Text('Template saved successfully!'),
        actions: [
          fluent.Button(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTemplate() async {
    final template = PrintTemplate(
      id: widget.initialTemplate?.id ??
          'template_${DateTime.now().millisecondsSinceEpoch}',
      name: _templateName,
      description: _templateDescription,
      paperSize: _paperSize,
      orientation: _orientation,
      customWidth: _paperSize == 'Custom' ? _customWidth : null,
      customHeight: _paperSize == 'Custom' ? _customHeight : null,
      fields: _fields.map((item) => item.field).toList(),
      createdAt: widget.initialTemplate?.createdAt ?? DateTime.now(),
      updatedAt: widget.initialTemplate != null ? DateTime.now() : null,
      backgroundImagePath: _backgroundImagePath,
      backgroundImageOpacity: _backgroundImageOpacity,
      useBackgroundInPrint: _useBackgroundInPrint,
    );

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Template',
      fileName: '${_templateName.replaceAll(' ', '_')}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsString(template.toJsonString());

      // Show success message
      fluent.showDialog(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('Success'),
          content: Text('Template exported to: $result'),
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

  Future<void> _importTemplate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      try {
        final template = PrintTemplate.fromJsonString(jsonString);
        _loadTemplate(template);
        setState(() {});

        // Show success message
        if (mounted) {
          fluent.showDialog(
            context: context,
            builder: (context) => fluent.ContentDialog(
              title: const Text('Success'),
              content: const Text('Template imported successfully!'),
              actions: [
                fluent.Button(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          fluent.showDialog(
            context: context,
            builder: (context) => fluent.ContentDialog(
              title: const Text('Error'),
              content: Text('Failed to import template: $e'),
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
  }

  Future<void> _showBackgroundDialog() async {
    await fluent.showDialog<void>(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: const Text('Background Image Settings'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload a reference image to display behind the template canvas. '
                    'This image will only be visible in the editor and will not appear in the final printed output.',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.secondaryTextColor),
                  ),
                  const SizedBox(height: 16),

                  // Current image preview
                  if (_backgroundImagePath != null) ...[
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_backgroundImagePath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current: ${_backgroundImagePath?.split('\\').last ?? 'Image loaded'}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.secondaryTextColor),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Opacity control
                  if (_backgroundImagePath != null) ...[
                    const Text('Opacity'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _backgroundImageOpacity,
                            onChanged: (value) {
                              setState(() {
                                _backgroundImageOpacity = value;
                              });
                              this.setState(() {});
                            },
                            min: 0.1,
                            max: 1.0,
                            divisions: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${(_backgroundImageOpacity * 100).round()}%'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Print setting
                  if (_backgroundImagePath != null) ...[
                    fluent.Checkbox(
                      checked: _useBackgroundInPrint,
                      onChanged: (checked) {
                        setState(() {
                          _useBackgroundInPrint = checked ?? false;
                        });
                        this.setState(() {});
                      },
                      content:
                          const Text('Include background in printed output'),
                    ),
                    const Text(
                      'Warning: Only enable this if you want the background image to appear in the final printed document.',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      fluent.FilledButton(
                        child: const Text('Choose Image'),
                        onPressed: () async {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                            );

                            if (result != null &&
                                result.files.single.path != null) {
                              setState(() {
                                _backgroundImagePath = result.files.single.path;
                              });
                              this.setState(() {});
                            }
                          } catch (e) {
                            debugPrint('Error selecting background image: $e');
                            // Don't show error dialog here as the image was applied successfully
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      if (_backgroundImagePath != null)
                        fluent.Button(
                          child: const Text('Remove'),
                          onPressed: () {
                            setState(() {
                              _backgroundImagePath = null;
                            });
                            this.setState(() {});
                          },
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          fluent.Button(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showCustomPaperDialog() {
    fluent.showDialog(
      context: context,
      builder: (context) {
        double tempWidth = _customWidth;
        double tempHeight = _customHeight;

        return fluent.ContentDialog(
          title: const Text('Custom Paper Size'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter custom paper dimensions in millimeters:'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Width (mm)'),
                            const SizedBox(height: 4),
                            fluent.NumberBox<double>(
                              value: tempWidth,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => tempWidth = value);
                                }
                              },
                              min: 50,
                              max: 1000,
                              placeholder: 'Width',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Height (mm)'),
                            const SizedBox(height: 4),
                            fluent.NumberBox<double>(
                              value: tempHeight,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => tempHeight = value);
                                }
                              },
                              min: 50,
                              max: 1000,
                              placeholder: 'Height',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Common sizes for reference:\n• A3: 297 x 420 mm\n• A4: 210 x 297 mm\n• Letter: 216 x 279 mm',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            fluent.Button(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                // Revert to previous paper size if cancelled
                this.setState(() {
                  _paperSize = 'A3'; // Default fallback
                });
              },
            ),
            fluent.FilledButton(
              child: const Text('Apply'),
              onPressed: () {
                this.setState(() {
                  _customWidth = tempWidth;
                  _customHeight = tempHeight;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactToolbar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: fluent.FluentTheme.of(context).cardColor,
      child: Row(
        children: [
          // Paper size selector
          SizedBox(
            width: 100,
            child: fluent.ComboBox<String>(
              value: _paperSize,
              items: _paperDimensions.keys.map((size) {
                return fluent.ComboBoxItem<String>(
                  value: size,
                  child: Text(size, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _paperSize = value;
                    if (value == 'Custom') {
                      _showCustomPaperDialog();
                    }
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // Orientation toggle
          fluent.ToggleSwitch(
            checked: _orientation == 'landscape',
            onChanged: (value) {
              setState(() {
                _orientation = value ? 'landscape' : 'portrait';
              });
            },
            content: Text(_orientation == 'landscape' ? 'L' : 'P',
                style: const TextStyle(fontSize: 12)),
          ),
          const Spacer(),
          // Zoom controls
          Text('${(_canvasScale * 100).toInt()}%',
              style: const TextStyle(fontSize: 12)),
          fluent.IconButton(
            icon: const Icon(fluent.FluentIcons.remove, size: 16),
            onPressed: () {
              setState(() {
                _canvasScale = (_canvasScale - 0.1).clamp(0.5, 2.0);
              });
            },
          ),
          fluent.IconButton(
            icon: const Icon(fluent.FluentIcons.add, size: 16),
            onPressed: () {
              setState(() {
                _canvasScale = (_canvasScale + 0.1).clamp(0.5, 2.0);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleVariablesPanel() {
    return Container(
      width: 180,
      color: fluent.FluentTheme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: fluent.FluentTheme.of(context).cardColor,
            child: Text(
              'Fields',
              style: fluent.FluentTheme.of(context).typography.bodyStrong,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: _availableVariables.length,
              itemBuilder: (context, index) {
                final variable = _availableVariables[index];
                return Draggable<FieldVariable>(
                  data: variable,
                  feedback: _buildDragFeedback(variable),
                  dragAnchorStrategy: (draggable, context, position) {
                    // Custom anchor strategy to center the feedback widget on the cursor
                    final feedbackSize =
                        Size(120, 36); // Approximate feedback size
                    return Offset(
                      feedbackSize.width / 2,
                      feedbackSize.height / 2,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(variable.icon, color: variable.color, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            variable.displayName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  Widget _buildCompactPropertiesPanel() {
    return Container(
      width: 400,
      color: fluent.FluentTheme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: fluent.FluentTheme.of(context).cardColor,
            child: Text(
              'Properties',
              style: fluent.FluentTheme.of(context).typography.bodyStrong,
            ),
          ),
          Expanded(
            child: _selectedField != null
                ? _buildCompactFieldProperties(_selectedField!)
                : _buildCompactTemplateProperties(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTemplateProperties() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactInfoRow(
              'Size:', _paperSize == 'Custom' ? 'Custom' : _paperSize),
          _buildCompactInfoRow('Orient:', _orientation),
          _buildCompactInfoRow('Fields:', '${_fields.length}'),
          _buildCompactInfoRow(
              'Background:', _backgroundImagePath != null ? 'Set' : 'None'),
        ],
      ),
    );
  }

  Widget _buildCompactFieldProperties(TemplateFieldItem fieldItem) {
    final field = fieldItem.field;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.fieldName,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Position controls
          Row(
            children: [
              Expanded(
                child: fluent.NumberBox<double>(
                  value: field.x,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        fieldItem.field = TemplateField(
                          fieldName: field.fieldName,
                          x: value,
                          y: field.y,
                          maxWidth: field.maxWidth,
                          alignment: field.alignment,
                          fontSize: field.fontSize,
                          bold: field.bold,
                          format: field.format,
                          prefix: field.prefix,
                          suffix: field.suffix,
                        );
                      });
                    }
                  },
                  min: 0,
                  max: _canvasSize.width,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: fluent.NumberBox<double>(
                  value: field.y,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        fieldItem.field = TemplateField(
                          fieldName: field.fieldName,
                          x: field.x,
                          y: value,
                          maxWidth: field.maxWidth,
                          alignment: field.alignment,
                          fontSize: field.fontSize,
                          bold: field.bold,
                          format: field.format,
                          prefix: field.prefix,
                          suffix: field.suffix,
                        );
                      });
                    }
                  },
                  min: 0,
                  max: _canvasSize.height,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Font size
          fluent.NumberBox<double>(
            value: field.fontSize,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  fieldItem.field = TemplateField(
                    fieldName: field.fieldName,
                    x: field.x,
                    y: field.y,
                    maxWidth: field.maxWidth,
                    alignment: field.alignment,
                    fontSize: value,
                    bold: field.bold,
                    format: field.format,
                    prefix: field.prefix,
                    suffix: field.suffix,
                  );
                });
              }
            },
            min: 6,
            max: 72,
          ),
          const SizedBox(height: 8),
          fluent.FilledButton(
            style: fluent.ButtonStyle(
              backgroundColor:
                  fluent.WidgetStateProperty.all(AppTheme.errorColor),
            ),
            child: const Text('Remove', style: TextStyle(fontSize: 11)),
            onPressed: () => _removeField(fieldItem),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.secondaryTextColor)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper classes
class TemplateFieldItem {
  TemplateField field;
  Offset position;

  TemplateFieldItem({
    required this.field,
    required this.position,
  });
}

class FieldVariable {
  final String fieldName;
  final String displayName;
  final IconData icon;
  final Color color;

  FieldVariable(this.fieldName, this.displayName, this.icon, this.color);
}

// Custom painters
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.borderColor
      ..strokeWidth = 1;

    // Draw grid lines every 20 pixels
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RulerPainter extends CustomPainter {
  final Size mmSize;

  RulerPainter({required this.mmSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.secondaryTextColor
      ..strokeWidth = 0.5;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw horizontal ruler (top)
    for (int mm = 0; mm <= mmSize.width.toInt(); mm += 10) {
      final x = mm * 3.78;

      if (mm % 50 == 0) {
        // Major tick
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, 15),
          paint,
        );

        // Draw text
        textPainter.text = TextSpan(
          text: mm.toString(),
          style:
              const TextStyle(fontSize: 8, color: AppTheme.secondaryTextColor),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - 10, 17));
      } else {
        // Minor tick
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, 8),
          paint,
        );
      }
    }

    // Draw vertical ruler (left)
    for (int mm = 0; mm <= mmSize.height.toInt(); mm += 10) {
      final y = mm * 3.78;

      if (mm % 50 == 0) {
        // Major tick
        canvas.drawLine(
          Offset(0, y),
          Offset(15, y),
          paint,
        );

        // Draw text
        textPainter.text = TextSpan(
          text: mm.toString(),
          style:
              const TextStyle(fontSize: 8, color: AppTheme.secondaryTextColor),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(17, y - 5));
      } else {
        // Minor tick
        canvas.drawLine(
          Offset(0, y),
          Offset(8, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
