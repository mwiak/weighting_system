import 'dart:math' as math;
import 'package:fluent_ui/fluent_ui.dart';
import '../l10n/app_localizations.dart';
// import 'package:flutter/foundation.dart'; // Unused
import '../models/page_dimensions.dart';
import '../models/windows_printer.dart';
import '../models/print_template.dart';
// import '../services/print_dimension_calculator.dart'; // Disabled

/// Print preview widget with dimension awareness and scaling indicators
class DimensionAwarePrintPreview extends StatefulWidget {
  final PrintTemplate? template;
  final Map<String, dynamic>? templateData;
  final PageSize? pdfSize;
  final WindowsPrinter? selectedPrinter;
  final bool showRulers;
  final bool showMargins;
  final Function(Map<String, dynamic>?)? onValidationChanged;

  const DimensionAwarePrintPreview({
    super.key,
    this.template,
    this.templateData,
    this.pdfSize,
    this.selectedPrinter,
    this.showRulers = true,
    this.showMargins = true,
    this.onValidationChanged,
  });

  @override
  State<DimensionAwarePrintPreview> createState() =>
      _DimensionAwarePrintPreviewState();
}

class _DimensionAwarePrintPreviewState
    extends State<DimensionAwarePrintPreview> {
  double _zoomLevel = 1.0;
  Map<String, dynamic>? _validationResult;

  @override
  void initState() {
    super.initState();
    _updateValidation();
  }

  @override
  void didUpdateWidget(DimensionAwarePrintPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.template != oldWidget.template ||
        widget.pdfSize != oldWidget.pdfSize ||
        widget.selectedPrinter != oldWidget.selectedPrinter) {
      _updateValidation();
    }
  }

  void _updateValidation() {
    if (widget.selectedPrinter == null) {
      _validationResult = null;
      if (widget.onValidationChanged != null) {
        widget.onValidationChanged!(null);
      }
      return;
    }

    PageSize? targetSize;
    if (widget.template != null) {
      targetSize = _getTemplatePageSize(widget.template!);
    } else if (widget.pdfSize != null) {
      targetSize = widget.pdfSize!;
    }

    if (targetSize != null) {
      // Simplified validation (PrintDimensionCalculator disabled)
      final validation = <String, dynamic>{
        'isValid': true,
        'message': 'Print validation disabled - using simplified mode',
      };

      setState(() => _validationResult = validation);

      if (widget.onValidationChanged != null) {
        widget.onValidationChanged!(validation);
      }
    }
  }

  PageSize _getTemplatePageSize(PrintTemplate template) {
    if (template.paperSize == 'Custom' &&
        template.customWidth != null &&
        template.customHeight != null) {
      PageSize size = PageSize(
        widthMm: template.customWidth!,
        heightMm: template.customHeight!,
        name: 'Custom',
      );
      return template.orientation == 'landscape' ? size.rotated : size;
    }

    PageSize size;
    switch (template.paperSize) {
      case 'A3':
        size = PageSize.a3;
        break;
      case 'A4':
        size = PageSize.a4;
        break;
      case 'A5':
        size = PageSize.a5;
        break;
      case 'Letter':
        size = PageSize.letter;
        break;
      case 'Legal':
        size = PageSize.legal;
        break;
      default:
        size = PageSize.a4;
    }

    return template.orientation == 'landscape' ? size.rotated : size;
  }

  @override
  Widget build(BuildContext context) {
    final pageSize = widget.template != null
        ? _getTemplatePageSize(widget.template!)
        : widget.pdfSize;

    if (pageSize == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FluentIcons.document,
                size: 48, color: Color(0xFF9E9E9E)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.noDocumentToPreview),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Preview controls
        _buildPreviewControls(pageSize),
        const SizedBox(height: 8),

        // Validation status
        if (_validationResult != null) _buildValidationStatus(),

        // Preview area
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[20],
              border: Border.all(color: Colors.grey[40] ?? Colors.grey),
            ),
            child: _buildPreviewContent(pageSize),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewControls(PageSize pageSize) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Document: ${pageSize.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${pageSize.widthMm.toStringAsFixed(1)} × ${pageSize.heightMm.toStringAsFixed(1)} mm',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
            ),

            // Zoom controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(FluentIcons.remove),
                  onPressed: _zoomLevel > 0.25
                      ? () => _setZoom(_zoomLevel - 0.25)
                      : null,
                ),
                Text('${(_zoomLevel * 100).toInt()}%'),
                IconButton(
                  icon: const Icon(FluentIcons.add),
                  onPressed: _zoomLevel < 3.0
                      ? () => _setZoom(_zoomLevel + 0.25)
                      : null,
                ),
                const SizedBox(width: 8),
                Button(
                  onPressed: () => _setZoom(1.0),
                  child: Text(AppLocalizations.of(context)!.fit),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // View options
            ToggleButton(
              checked: widget.showRulers,
              onChanged: (checked) => setState(() {}),
              child: Text(AppLocalizations.of(context)!.rulers),
            ),
            const SizedBox(width: 4),
            ToggleButton(
              checked: widget.showMargins,
              onChanged: (checked) => setState(() {}),
              child: Text(AppLocalizations.of(context)!.margins),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationStatus() {
    if (_validationResult == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InfoBar(
        title: Text(
            _validationResult!['isValid'] ? 'Print Ready' : 'Print Warning'),
        content: Text(_validationResult!['message']),
        severity: _validationResult!['isValid']
            ? InfoBarSeverity.success
            : InfoBarSeverity.warning,
        isLong: false,
      ),
    );
  }

  Widget _buildPreviewContent(PageSize pageSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate preview dimensions
        const margin = 20.0;
        final maxWidth = constraints.maxWidth - (margin * 2);
        final maxHeight = constraints.maxHeight - (margin * 2);

        // Calculate scale to fit
        final scaleX = maxWidth / pageSize.widthMm;
        final scaleY = maxHeight / pageSize.heightMm;
        final baseScale = math.min(scaleX, scaleY) * 0.8; // Leave some padding

        final finalScale = baseScale * _zoomLevel;

        final previewWidth = pageSize.widthMm * finalScale;
        final previewHeight = pageSize.heightMm * finalScale;

        return Stack(
          children: [
            // Centered preview
            Center(
              child: Container(
                width: previewWidth,
                height: previewHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[60] ?? Colors.grey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: _buildPageContent(pageSize, finalScale),
              ),
            ),

            // Rulers
            if (widget.showRulers)
              _buildRulers(pageSize, finalScale, constraints),
          ],
        );
      },
    );
  }

  Widget _buildPageContent(PageSize pageSize, double scale) {
    if (widget.template != null) {
      return _buildTemplatePreview(widget.template!, pageSize, scale);
    }

    // Generic PDF preview
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FluentIcons.document,
                size: 48, color: Color(0xFFD32F2F)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.pdfPreview),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePreview(
      PrintTemplate template, PageSize pageSize, double scale) {
    return Stack(
      children: [
        // Background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
        ),

        // Template fields
        ...template.fields
            .map((field) => _buildFieldPreview(field, scale, pageSize)),

        // Margins overlay
        if (widget.showMargins && widget.selectedPrinter != null)
          _buildMarginsOverlay(pageSize, scale),
      ],
    );
  }

  Widget _buildFieldPreview(
      TemplateField field, double scale, PageSize pageSize) {
    final data = widget.templateData ?? {};
    final value = data[field.fieldName]?.toString() ?? '[${field.fieldName}]';

    return Positioned(
      left: field.x * scale,
      top: field.y * scale,
      child: Container(
        constraints: field.maxWidth != null
            ? BoxConstraints(maxWidth: field.maxWidth! * scale)
            : null,
        child: Text(
          value,
          style: TextStyle(
            fontSize:
                field.fontSize * scale * 0.75, // Approximate screen scaling
            fontWeight: field.bold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF212121),
          ),
          textAlign: _getTextAlign(field.alignment),
        ),
      ),
    );
  }

  Widget _buildMarginsOverlay(PageSize pageSize, double scale) {
    if (widget.selectedPrinter?.capabilities.minimumMargins == null) {
      return const SizedBox.shrink();
    }

    final margins = widget.selectedPrinter!.capabilities.minimumMargins;
    return Positioned.fill(
      child: Container(
        margin: EdgeInsets.only(
          left: margins.leftMm * scale,
          top: margins.topMm * scale,
          right: margins.rightMm * scale,
          bottom: margins.bottomMm * scale,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.red.withOpacity(0.5),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
    );
  }

  Widget _buildRulers(
      PageSize pageSize, double scale, BoxConstraints constraints) {
    return Stack(
      children: [
        // Horizontal ruler (top)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 20,
          child: _buildHorizontalRuler(pageSize.widthMm, scale),
        ),

        // Vertical ruler (left)
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: 20,
          child: _buildVerticalRuler(pageSize.heightMm, scale),
        ),
      ],
    );
  }

  Widget _buildHorizontalRuler(double widthMm, double scale) {
    return Container(
      color: Colors.grey[10],
      child: CustomPaint(
        painter: RulerPainter(
          maxValue: widthMm,
          scale: scale,
          isHorizontal: true,
        ),
      ),
    );
  }

  Widget _buildVerticalRuler(double heightMm, double scale) {
    return Container(
      color: Colors.grey[10],
      child: CustomPaint(
        painter: RulerPainter(
          maxValue: heightMm,
          scale: scale,
          isHorizontal: false,
        ),
      ),
    );
  }

  void _setZoom(double zoom) {
    setState(() => _zoomLevel = zoom.clamp(0.25, 3.0));
  }

  TextAlign _getTextAlign(String alignment) {
    switch (alignment.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }
}

/// Custom painter for rulers
class RulerPainter extends CustomPainter {
  final double maxValue;
  final double scale;
  final bool isHorizontal;

  RulerPainter({
    required this.maxValue,
    required this.scale,
    required this.isHorizontal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[80] ?? Colors.grey
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw ruler marks every 10mm
    for (int mm = 0; mm <= maxValue; mm += 10) {
      final position = mm * scale;

      if (isHorizontal) {
        if (position <= size.width) {
          // Draw mark
          canvas.drawLine(
            Offset(position, size.height - 5),
            Offset(position, size.height),
            paint,
          );

          // Draw label
          if (mm > 0) {
            textPainter.text = TextSpan(
              text: '${mm}mm',
              style: const TextStyle(fontSize: 8, color: Color(0xFF9E9E9E)),
            );
            textPainter.layout();
            textPainter.paint(
              canvas,
              Offset(position - textPainter.width / 2, 2),
            );
          }
        }
      } else {
        if (position <= size.height) {
          // Draw mark
          canvas.drawLine(
            Offset(size.width - 5, position),
            Offset(size.width, position),
            paint,
          );

          // Draw label
          if (mm > 0) {
            textPainter.text = TextSpan(
              text: '$mm',
              style: const TextStyle(fontSize: 8, color: Color(0xFF9E9E9E)),
            );
            textPainter.layout();

            canvas.save();
            canvas.translate(2, position + textPainter.width / 2);
            canvas.rotate(-math.pi / 2);
            textPainter.paint(canvas, Offset.zero);
            canvas.restore();
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
