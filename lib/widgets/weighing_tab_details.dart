import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/tabs_provider.dart';
import '../models/weighing_tab.dart';

class WeighingTabDetails extends StatelessWidget {
  const WeighingTabDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TabsProvider>(
      builder: (context, tabsProvider, child) {
        WeighingTab? currentTab = tabsProvider.currentTab;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(FluentIcons.info, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tab Details',
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.info,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Tab Selected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select a tab to view details',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabDetails(BuildContext context, WeighingTab tab, TabsProvider tabsProvider) {
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
                        _getStatusDisplay(tab),
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
                        child: const Text(
                          'UNSAVED',
                          style: TextStyle(
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
            'Vehicle Information',
            FluentIcons.bus,
            [
              _buildDetailRow('Truck Plate', tab.truckPlate.isNotEmpty ? tab.truckPlate : 'Not specified'),
              _buildDetailRow('Driver Name', tab.driverName.isNotEmpty ? tab.driverName : 'Not specified'),
            ],
          ),
          const SizedBox(height: 20),

          // Weight Information
          _buildSection(
            'Weight Information',
            FluentIcons.scale_volume,
            [
              _buildDetailRow(
                  'Gross Weight',
                  tab.grossWeight > 0
                      ? '${tab.grossWeight.toStringAsFixed(0)} kg'
                      : 'Not recorded'),
              _buildDetailRow(
                  'Empty Weight',
                  tab.emptyWeight > 0
                      ? '${tab.emptyWeight.toStringAsFixed(0)} kg'
                      : 'Not recorded'),
              _buildDetailRow(
                  'Net Weight',
                  tab.netWeight > 0
                      ? '${tab.netWeight.toStringAsFixed(0)} kg'
                      : 'Not calculated',
                  isHighlighted: tab.netWeight > 0),
            ],
          ),
          const SizedBox(height: 20),

          // Business Information
          _buildSection(
            'Business Information',
            FluentIcons.people,
            [
              _buildDetailRow('Client/Supplier',
                (tab.client.isNotEmpty ? tab.client : tab.supplier.isNotEmpty ? tab.supplier : 'Not specified')),
              _buildDetailRow('Material',
                tab.material.isNotEmpty ? tab.material : 'Not specified'),
              _buildDetailRow('Payment Status', tab.isPaid ? 'Paid' : 'Unpaid'),
              _buildDetailRow('Show Price on Print', tab.showPriceOnPrint ? 'Yes' : 'No'),
            ],
          ),
          const SizedBox(height: 20),

          // Timing Information
          _buildSection(
            'Timing Information',
            FluentIcons.clock,
            [
              _buildDetailRow('Created At', _formatDateTime(tab.createdAt)),
              _buildDetailRow('Last Updated', _formatDateTime(tab.updatedAt)),
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

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
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

  Widget _buildActionsSection(BuildContext context, WeighingTab tab, TabsProvider tabsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        if (tab.isEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _startWeighing(context, tab),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FluentIcons.add),
                  SizedBox(width: 8),
                  Text('Start Weighing'),
                ],
              ),
            ),
          ),
        ] else if (tab.isInProgress) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _continueWeighing(context, tab),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FluentIcons.scale_volume),
                  SizedBox(width: 8),
                  Text('Continue Weighing'),
                ],
              ),
            ),
          ),
        ] else if (tab.isComplete && !tab.isCompleted) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _completeTab(context, tab, tabsProvider),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FluentIcons.accept),
                  SizedBox(width: 8),
                  Text('Complete Tab'),
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FluentIcons.print),
                    SizedBox(width: 8),
                    Text('Print'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Button(
                onPressed: () => _editTab(context, tab),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FluentIcons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FluentIcons.refresh),
                      SizedBox(width: 8),
                      Text('Reset'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Button(
                  onPressed: () => _cancelTab(context, tab, tabsProvider),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FluentIcons.cancel),
                      SizedBox(width: 8),
                      Text('Cancel'),
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

  String _getStatusDisplay(WeighingTab tab) {
    if (tab.isEmpty) return 'Empty';
    if (tab.isInProgress) return 'In Progress';
    if (tab.isComplete) return 'Ready to Complete';
    if (tab.isCompleted) return 'Completed';
    if (tab.isCancelled) return 'Cancelled';
    return tab.status.toUpperCase();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _startWeighing(BuildContext context, WeighingTab tab) {
    _showInfoBar(
        context, 'Switch to the weighing tab to start recording weights', InfoBarSeverity.info);
  }

  void _continueWeighing(BuildContext context, WeighingTab tab) {
    _showInfoBar(
        context, 'Switch to the weighing tab to continue recording weights', InfoBarSeverity.info);
  }

  void _completeTab(BuildContext context, WeighingTab tab, TabsProvider tabsProvider) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Complete Tab'),
        content: Text('Mark tab "${tab.tabTitle}" as completed?'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Complete'),
            onPressed: () {
              tab.completeTab();
              tabsProvider.saveTab(tab);
              Navigator.of(context).pop();
              _showInfoBar(context, 'Tab completed successfully',
                  InfoBarSeverity.success);
            },
          ),
        ],
      ),
    );
  }

  void _editTab(BuildContext context, WeighingTab tab) {
    _showInfoBar(
        context, 'Tab editing functionality coming soon', InfoBarSeverity.info);
  }

  void _printTab(BuildContext context, WeighingTab tab) {
    _showInfoBar(
        context, 'Print functionality coming soon', InfoBarSeverity.info);
  }

  void _resetTab(BuildContext context, WeighingTab tab, TabsProvider tabsProvider) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Reset Tab'),
        content: Text('Reset all data in tab "${tab.tabTitle}"? This action cannot be undone.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Reset'),
            onPressed: () {
              tab.reset();
              tabsProvider.saveTab(tab);
              Navigator.of(context).pop();
              _showInfoBar(context, 'Tab reset successfully',
                  InfoBarSeverity.warning);
            },
          ),
        ],
      ),
    );
  }

  void _cancelTab(BuildContext context, WeighingTab tab, TabsProvider tabsProvider) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Cancel Tab'),
        content: Text('Cancel tab "${tab.tabTitle}"?'),
        actions: [
          Button(
            child: const Text('No'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Yes, Cancel'),
            onPressed: () {
              tab.cancelTab();
              tabsProvider.saveTab(tab);
              Navigator.of(context).pop();
              _showInfoBar(context, 'Tab cancelled', InfoBarSeverity.warning);
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