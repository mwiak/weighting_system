import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/print_template.dart';
import '../services/custom_template_service.dart';
import '../services/template_print_service.dart';
import '../models/weighing_tab.dart';
import '../providers/client_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/material_provider.dart';

class OrderDetailsDialog extends StatefulWidget {
  final WeighingTab operation;

  const OrderDetailsDialog({
    super.key,
    required this.operation,
  });

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  final TemplatePrintService _printService = TemplatePrintService();
  final CustomTemplateService _templateService = CustomTemplateService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _printOrder() async {
    try {
      final weighingTab = _createWeighingTabFromOperation();

      PrintTemplate? defaultTemplate =
          await _templateService.getDefaultTemplate();
      if (defaultTemplate != null) {
        await _printService.printTemplateStandardPDFNewSilently(
            defaultTemplate, weighingTab, null, null, null);
        _showInfoBar(
          AppLocalizations.of(context)!.printSuccessful,
          InfoBarSeverity.success,
        );
      } else {
        _showInfoBar(
          AppLocalizations.of(context)!.couldNotFindTemplate,
          InfoBarSeverity.error,
        );
      }
    } catch (e) {
      _showInfoBar(
        '${AppLocalizations.of(context)!.printFailed}: $e',
        InfoBarSeverity.error,
      );
    }
  }

  Future<void> _savePDF() async {
    try {
      final weighingTab = _createWeighingTabFromOperation();

      PrintTemplate? defaultTemplate =
          await _templateService.getDefaultTemplate();
      if (defaultTemplate != null) {
        await _printService.saveTemplateStandardPDFNewSilently(
            defaultTemplate, weighingTab, null, null, null);
        _showInfoBar(
          AppLocalizations.of(context)!.pdfSaved,
          InfoBarSeverity.success,
        );
      } else {
        _showInfoBar(
          AppLocalizations.of(context)!.couldNotFindTemplate,
          InfoBarSeverity.error,
        );
      }
    } catch (e) {
      _showInfoBar(
        '${AppLocalizations.of(context)!.savePdfFailed}: $e',
        InfoBarSeverity.error,
      );
    }
  }

  WeighingTab _createWeighingTabFromOperation() {
    return widget.operation;
  }

  void _showInfoBar(String message, InfoBarSeverity severity) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(message),
        severity: severity,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ContentDialog(
      constraints: const BoxConstraints(
        maxWidth: 1200,
        maxHeight: 900,
      ),
      title: Row(
        children: [
          const Icon(FluentIcons.info),
          const SizedBox(width: 8),
          Text(l10n.orderDetails),
          const Spacer(),
          IconButton(
            icon: const Icon(FluentIcons.chrome_close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 700,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _printOrder,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FluentIcons.print),
                        const SizedBox(width: 8),
                        Text(l10n.print),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Button(
                    onPressed: _savePDF,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FluentIcons.save),
                        const SizedBox(width: 8),
                        Text(l10n.savePDF),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Order details content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Use a two-column layout to fit more information
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          child: Column(
                            children: [
                              // Basic Order Information
                              _buildSection(
                                l10n.basicInformation,
                                [
                                  _buildDetailRow(l10n.orderNumber,
                                      '${widget.operation.id}'),
                                  _buildDetailRow(l10n.status,
                                      _formatStatus(widget.operation.status)),
                                  _buildDetailRow(
                                      l10n.createDate,
                                      _formatDateTime(
                                          widget.operation.createdAt)),
                                  _buildDetailRow(
                                      l10n.lastUpdated,
                                      _formatDateTime(
                                          widget.operation.updatedAt)),
                                  _buildDetailRow(
                                      l10n.weighInTime,
                                      _formatDateTime(
                                          widget.operation.scaleEmptyWeightAt)),
                                  _buildDetailRow(
                                      l10n.weighOutTime,
                                      _formatDateTime(
                                          widget.operation.scaleGrossWeightAt)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Vehicle and Driver Information
                              _buildSection(
                                l10n.vehicleInformation,
                                [
                                  _buildDetailRow(l10n.truckPlate,
                                      widget.operation.truckPlate),
                                  _buildDetailRow(l10n.driverName,
                                      widget.operation.driverName),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Business Partners Information
                              _buildSection(
                                l10n.businessPartners,
                                [
                                  _buildDetailRow(
                                      l10n.client, widget.operation.client),
                                  _buildDetailRow(
                                      l10n.supplier, widget.operation.supplier),
                                  _buildDetailRow(
                                      l10n.material, widget.operation.material),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right Column
                        Expanded(
                          child: Column(
                            children: [
                              // Weight Measurements
                              _buildSection(
                                l10n.weightMeasurements,
                                [
                                  _buildDetailRow(l10n.grossWeight,
                                      '${widget.operation.grossWeight} kg'),
                                  _buildDetailRow(l10n.tareWeight,
                                      '${widget.operation.emptyWeight} kg'),
                                  _buildDetailRow(l10n.netWeight,
                                      '${widget.operation.netWeight} kg'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Financial Information
                              _buildSection(
                                l10n.financialInformation,
                                [
                                  _buildDetailRow(l10n.unitPrice,
                                      '${widget.operation.kilo_price.toStringAsFixed(2)}'),
                                  _buildDetailRow(l10n.totalAmount,
                                      '${widget.operation.total_price.toStringAsFixed(2)}'),
                                  _buildDetailRow(
                                      l10n.paid,
                                      widget.operation.isPaid
                                          ? l10n.yes
                                          : l10n.no),
                                  _buildDetailRow(
                                      l10n.showPriceOnPrint,
                                      widget.operation.showPriceOnPrint
                                          ? l10n.yes
                                          : l10n.no),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Additional Information
                              _buildSection(
                                l10n.additionalInfo,
                                [
                                  _buildDetailRow(
                                      l10n.unsavedChanges,
                                      widget.operation.hasUnsavedChanges
                                          ? l10n.yes
                                          : l10n.no),
                                  _buildDetailRow(
                                      l10n.completed,
                                      widget.operation.isComplete
                                          ? l10n.yes
                                          : l10n.no),
                                  _buildDetailRow(
                                      l10n.databaseId,
                                      widget.operation.id?.toString() ??
                                          l10n.unsaved),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          child: Text(l10n.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: FluentTheme.of(context).typography.subtitle,
        ),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? l10n.notAvailable : value,
              style: FluentTheme.of(context)
                  .typography
                  .body
                  ?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    final l10n = AppLocalizations.of(context)!;
    if (dateTime == null) return l10n.na;
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatOperationType(dynamic type) {
    final l10n = AppLocalizations.of(context)!;
    if (type == null) return l10n.na;
    switch (type.toString().toLowerCase()) {
      case 'loading':
        return l10n.loadingOutgoing;
      case 'unloading':
        return l10n.unloadingIncoming;
      default:
        return type.toString();
    }
  }

  String _formatStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'completed':
        return l10n.statusCompleted;
      case 'in-progress':
      case 'inprogress':
        return l10n.statusInProgress;
      case 'incomplete':
        return l10n.statusIncomplete;
      case 'cancelled':
        return l10n.statusCancelled;
      case 'empty':
        return l10n.statusEmpty;
      default:
        // Fallback: capitalize each word
        return status
            .split('-')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}
