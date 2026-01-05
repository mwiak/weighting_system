import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:weighing_system/database/database_helper.dart';
import 'package:weighing_system/theme/app_theme.dart';
import 'package:weighing_system/widgets/admin_weighting_tab_content.dart';
import 'package:weighing_system/widgets/operation_widgets/operation_details_card.dart';
import '../l10n/app_localizations.dart';
import 'package:weighing_system/models/user.dart';
import 'package:weighing_system/providers/user_provider.dart';
import 'package:weighing_system/widgets/operation_widgets/operation_entry.dart';
import 'package:weighing_system/widgets/operation_widgets/operation_header.dart';
import '../models/print_template.dart';
import '../providers/tabs_provider.dart';
import '../services/custom_template_service.dart';
import '../services/template_print_service.dart';
import '../models/weighing_tab.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/client_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/material_provider.dart';
import 'bar/overlay_ui.dart';

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

  void _showEditingDialog() async {
    context.read<TabsProvider>().createInMemoryManualTab(tab: widget.operation);
    await showDialog(
        context: context,
        builder: (context) {
          return AdminWeightingTabContent(
            tab: widget.operation,
          );
        });
  }

  void _deleteOperation(int id) async {
    final DatabaseHelper db = DatabaseHelper();
    final response =
        await db.delete('weighing_tabs', where: 'id = ?', whereArgs: [id]);
    if (response > 0) {
      _showInfoBar('تم الحذف', InfoBarSeverity.success);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<UserProvider>(
      builder: (BuildContext context, value, Widget? child) {
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
              const SizedBox(width: 8),
              if (value.activeUser!.type == UserRanks.admin) ...[
                Button(
                  onPressed: () {
                    _deleteOperation(widget.operation.id!);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FluentIcons.delete),
                      const SizedBox(width: 8),
                      Text(l10n.delete),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Button(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditingDialog();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FluentIcons.edit),
                      const SizedBox(width: 8),
                      Text(l10n.edit),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              FilledButton(
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
              const SizedBox(width: 8),
              Button(
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
              const SizedBox(width: 8),
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
                OperationDetailsHeader(),
                SizedBox(
                  height: 10,
                ),
                // Action buttons row

                const SizedBox(height: 8),
                OperationDetailsEntry(
                    operation: widget.operation.toMap(), onPressed: () {}),

                // Order details content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            OperationDetailsStatusCard(
                              label: l10n.status,
                              value: _formatStatus(widget.operation.status),
                              svgPath: '',
                            ),
                            OperationDetailsCard(
                              label: l10n.notes,
                              value: widget.operation.notes,
                              svgPath:
                                  FluentIcons.sticky_notes_outline_app_icon,
                            ),
                            OperationDetailsCard(
                                svgPath: FluentIcons.stopwatch,
                                label: l10n.createDate,
                                value: _formatDateTime(
                                    widget.operation.createdAt)),
                            OperationDetailsCard(
                              label: l10n.lastUpdated,
                              value:
                                  _formatDateTime(widget.operation.updatedAt),
                              svgPath: 'assets/editicon.svg',
                            ),
                            OperationDetailsCard(
                              label: l10n.paid,
                              value:
                                  widget.operation.isPaid ? l10n.yes : l10n.no,
                              svgPath: FluentIcons.money,
                            ),
                          ],
                        ),
                        // Use a two-column layout to fit more information
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OperationDetailsCard(
                              label: l10n.weighInTime,
                              value: _formatDateTime(
                                  widget.operation.scaleEmptyWeightAt),
                              svgPath: 'assets/test.svg',
                            ),
                            OperationDetailsCard(
                              label: l10n.weighOutTime,
                              value: _formatDateTime(
                                  widget.operation.scaleGrossWeightAt),
                              svgPath: 'assets/weightin.svg',
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
      },
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
