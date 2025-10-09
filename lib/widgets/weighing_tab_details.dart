import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weighing_system/widgets/operation_widgets/operation_header.dart';
import '../providers/tabs_provider.dart';
import '../models/weighing_tab.dart';

class WeighingTabDetails extends StatelessWidget {
  const WeighingTabDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<TabsProvider>(
      builder: (context, tabsProvider, child) {
        WeighingTab? currentTab = tabsProvider.currentTab;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(FluentIcons.info, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.tabDetails,
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: currentTab != null
                      ? _buildTabDetails(context, currentTab, tabsProvider)
                      : _buildNoSelectionState(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoSelectionState() {
    return Builder(builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FluentIcons.info,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noTabSelectedMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.selectTabToView,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabDetails(
      BuildContext context, WeighingTab tab, TabsProvider tabsProvider) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(tab).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab.tabTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(tab),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusDisplay(tab, l10n),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Operation type removed from schema
                    if (tab.hasUnsavedChanges) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.unsaved.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Vehicle Information
          _buildSection(
            l10n.vehicleInformation,
            FluentIcons.bus,
            [
              _buildDetailRow(
                  l10n.truckPlateLabel,
                  tab.truckPlate.isNotEmpty
                      ? tab.truckPlate
                      : l10n.notSpecified,
                  l10n),
              _buildDetailRow(
                  l10n.driverName,
                  tab.driverName.isNotEmpty
                      ? tab.driverName
                      : l10n.notSpecified,
                  l10n),
            ],
          ),
          const SizedBox(height: 20),

          // Weight Information
          _buildSection(
            l10n.weightInformation,
            FluentIcons.scale_volume,
            [
              _buildDetailRow(
                  l10n.grossWeight,
                  tab.grossWeight > 0
                      ? '${tab.grossWeight.toStringAsFixed(0)} kg'
                      : l10n.notRecorded,
                  l10n),
              _buildDetailRow(
                  l10n.emptyWeight,
                  tab.emptyWeight > 0
                      ? '${tab.emptyWeight.toStringAsFixed(0)} kg'
                      : l10n.notRecorded,
                  l10n),
              _buildDetailRow(
                  l10n.netWeight,
                  tab.netWeight > 0
                      ? '${tab.netWeight.toStringAsFixed(0)} kg'
                      : l10n.notCalculated,
                  l10n,
                  isHighlighted: tab.netWeight > 0),
            ],
          ),
          const SizedBox(height: 20),

          // Business Information
          _buildSection(
            l10n.businessInformation,
            FluentIcons.people,
            [
              _buildDetailRow(
                  l10n.clientSupplier,
                  (tab.client.isNotEmpty
                      ? tab.client
                      : tab.supplier.isNotEmpty
                          ? tab.supplier
                          : l10n.notSpecified),
                  l10n),
              _buildDetailRow(
                  l10n.material,
                  tab.material.isNotEmpty ? tab.material : l10n.notSpecified,
                  l10n),
              _buildDetailRow(l10n.paymentStatus,
                  tab.isPaid ? l10n.paid : l10n.unpaid, l10n),
              _buildDetailRow(l10n.showPriceOnPrint,
                  tab.showPriceOnPrint ? l10n.yes : l10n.no, l10n),
            ],
          ),
          const SizedBox(height: 20),

          // Timing Information
          _buildSection(
            l10n.timingInformation,
            FluentIcons.clock,
            [
              _buildDetailRow(
                  l10n.createdAt, _formatDateTime(tab.createdAt, l10n), l10n),
              _buildDetailRow(
                  l10n.lastUpdated, _formatDateTime(tab.updatedAt, l10n), l10n),
              // Operation type removed from schema
            ],
          ),

          const SizedBox(height: 24),

          // Actions
          _buildActionsSection(context, tab, tabsProvider),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, AppLocalizations l10n,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                color: isHighlighted ? Colors.blue : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(
      BuildContext context, WeighingTab tab, TabsProvider tabsProvider) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.actions,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        if (!tab.hasData) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _startWeighing(context, tab),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FluentIcons.add),
                  const SizedBox(width: 8),
                  Text(l10n.startWeighing),
                ],
              ),
            ),
          ),
        ] else if (tab.isInProgress) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _continueWeighing(context, tab),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FluentIcons.scale_volume),
                  const SizedBox(width: 8),
                  Text(l10n.continueWeighing),
                ],
              ),
            ),
          ),
        ] else if (tab.isComplete && !tab.isCompleted) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _completeTab(context, tab, tabsProvider),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FluentIcons.accept),
                  const SizedBox(width: 8),
                  Text(l10n.completeTab),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Secondary actions
        Row(
          children: [
            Expanded(
              child: Button(
                onPressed: tab.hasData ? () => _printTab(context, tab) : null,
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
            const SizedBox(width: 8),
            Expanded(
              child: Button(
                onPressed: () => _editTab(context, tab),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FluentIcons.edit),
                    const SizedBox(width: 8),
                    Text(l10n.edit),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (tab.hasData && !tab.isCompleted) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Button(
                  onPressed: () => _resetTab(context, tab, tabsProvider),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FluentIcons.refresh),
                      const SizedBox(width: 8),
                      Text(l10n.reset),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Button(
                  onPressed: () => _cancelTab(context, tab, tabsProvider),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FluentIcons.cancel),
                      const SizedBox(width: 8),
                      Text(l10n.cancel),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(WeighingTab tab) {
    if (tab.isCompleted) return Colors.green;
    if (tab.isCancelled) return Colors.red;
    if (tab.isComplete) return Colors.blue;
    if (tab.isInProgress) return Colors.orange;
    return Colors.grey;
  }

  // _getOperationColor method removed - operation type no longer used

  String _getStatusDisplay(WeighingTab tab, AppLocalizations l10n) {
    if (!tab.hasData) return l10n.empty;
    if (tab.isInProgress) return l10n.inProgress;
    if (tab.isComplete) return l10n.readyToComplete;
    if (tab.isCompleted) return l10n.completed;
    if (tab.isCancelled) return l10n.cancelled;
    return tab.status.toUpperCase();
  }

  String _formatDateTime(DateTime? dateTime, AppLocalizations l10n) {
    if (dateTime == null) return l10n.notSet;
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _startWeighing(BuildContext context, WeighingTab tab) {
    final l10n = AppLocalizations.of(context)!;
    _showInfoBar(context, l10n.switchToWeighingTab, InfoBarSeverity.info);
  }

  void _continueWeighing(BuildContext context, WeighingTab tab) {
    final l10n = AppLocalizations.of(context)!;
    _showInfoBar(
        context, l10n.switchToWeighingTabContinue, InfoBarSeverity.info);
  }

  void _completeTab(
      BuildContext context, WeighingTab tab, TabsProvider tabsProvider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.completeTab),
        content: Text(l10n.completeTabConfirm(tab.tabTitle)),
        actions: [
          Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: Text(l10n.complete),
            onPressed: () {
              tab.completeTab();
              tabsProvider.saveTab(tab);
              Navigator.of(context).pop();
              _showInfoBar(
                  context, l10n.tabCompletedSuccess, InfoBarSeverity.success);
            },
          ),
        ],
      ),
    );
  }

  void _editTab(BuildContext context, WeighingTab tab) {
    final l10n = AppLocalizations.of(context)!;
    _showInfoBar(context, l10n.tabEditingComingSoon, InfoBarSeverity.info);
  }

  void _printTab(BuildContext context, WeighingTab tab) {
    final l10n = AppLocalizations.of(context)!;
    _showInfoBar(
        context, l10n.printFunctionalityComingSoon, InfoBarSeverity.info);
  }

  void _resetTab(
      BuildContext context, WeighingTab tab, TabsProvider tabsProvider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.resetTab),
        content: Text(l10n.resetTabConfirm(tab.tabTitle)),
        actions: [
          Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: Text(l10n.reset),
            onPressed: () {
              tab.reset();
              tabsProvider.saveTab(tab);
              Navigator.of(context).pop();
              _showInfoBar(
                  context, l10n.tabResetSuccess, InfoBarSeverity.warning);
            },
          ),
        ],
      ),
    );
  }

  void _cancelTab(
      BuildContext context, WeighingTab tab, TabsProvider tabsProvider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.cancelTab),
        content: Text(l10n.cancelTabConfirm(tab.tabTitle)),
        actions: [
          Button(
            child: Text(l10n.no),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: Text(l10n.yesCancelTab),
            onPressed: () async {
              Navigator.of(context).pop();
              // Use unified cancellation logic from TabsProvider
              final success =
                  await tabsProvider.cancelTab(tabsProvider.tabs.indexOf(tab));
              if (success) {
                _showInfoBar(
                    context, l10n.tabCancelledMessage, InfoBarSeverity.warning);
              } else {
                _showInfoBar(
                    context, l10n.failedToCancelTab, InfoBarSeverity.error);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showInfoBar(
      BuildContext context, String message, InfoBarSeverity severity) {
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
}
