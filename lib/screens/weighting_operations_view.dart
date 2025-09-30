import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weighing_system/widgets/autom_complete_filter_combo_box.dart';
import 'package:weighing_system/widgets/order_details_dialog.dart';
import '../providers/report_provider.dart';
import '../models/weighing_tab.dart';

class WeightingOperationsView extends StatefulWidget {
  const WeightingOperationsView({super.key});

  @override
  State<WeightingOperationsView> createState() =>
      _WeightingOperationsViewState();
}

class _WeightingOperationsViewState extends State<WeightingOperationsView> {
  String _statusFilter = 'all'; // Show all operations by default
  String _driverFilter = '';
  String _truckFilter = '';
  String _clientFilter = '';
  String _supplierFilter = '';
  String _materialFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _operations = [];
  bool _isLoading = false;
  bool checked = true;

  @override
  void initState() {
    super.initState();
    // Set default date range to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadOperations();
  }

  void _loadOperations() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<ReportProvider>();

      debugPrint('Loading operations with filters:');
      debugPrint('  Status: $_statusFilter');

      debugPrint('  Date Range: $_startDate to $_endDate');

      final operations = await provider.getOrdersHistory(
        startDate: _startDate,
        endDate: _endDate,
        status: _statusFilter == 'all' ? null : _statusFilter,
        driverFilter: _driverFilter.isEmpty ? null : _driverFilter,
        truckFilter: _truckFilter.isEmpty ? null : _truckFilter,
        supplierFilter: _supplierFilter.isEmpty ? null : _supplierFilter,
        clientFilter: _clientFilter.isEmpty ? null : _clientFilter,
        materialFilter: _materialFilter.isEmpty ? null : _materialFilter,
      );

      debugPrint('Found ${operations.length} operations');
      if (operations.isNotEmpty) {
        debugPrint('Sample operation data: ${operations.first}');
        // Show all available statuses for debugging
        final statuses = operations.map((op) => op['status']).toSet();
        debugPrint('Available statuses in results: $statuses');
      } else {
        debugPrint('No operations found - this might indicate the issue');
      }

      setState(() => _operations = operations);
    } catch (e) {
      debugPrint('Error loading operations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ScaffoldPage.scrollable(
      children: [
        Expander(
          contentPadding: EdgeInsets.zero,
          leading: Icon(FluentIcons.search),
          header: const Text('بحث'),
          content: Card(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First Row of Filters
                  Row(
                    children: [
                      // Operation Type Filter

                      // Status Filter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.status + ':'),
                            const SizedBox(height: 4),
                            ComboBox<String>(
                              value: _statusFilter,
                              items: [
                                ComboBoxItem<String>(
                                    value: 'in-progress',
                                    child: Text(l10n.statusInProgress)),
                                ComboBoxItem<String>(
                                    value: 'completed',
                                    child: Text(l10n.statusCompleted)),
                                ComboBoxItem<String>(
                                    value: 'cancelled',
                                    child: Text(l10n.statusCancelled)),
                                ComboBoxItem<String>(
                                    value: 'all',
                                    child: Text(l10n.allStatuses)),
                              ],
                              onChanged: (value) => setState(
                                  () => _statusFilter = value ?? 'all'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.material + ':'),
                            const SizedBox(height: 4),
                            AutoCompleteFilterComboBox(
                              placeholder: l10n.filterByMaterial,
                              onChanged: (value) =>
                                  setState(() => _materialFilter = value),
                              value: _materialFilter,
                              suggestionType: AutoCompleteType.material,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Driver Filter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.driverName + ':'),
                            const SizedBox(height: 4),
                            AutoCompleteFilterComboBox(
                              placeholder: l10n.filterByDriver,
                              onChanged: (value) =>
                                  setState(() => _driverFilter = value),
                              value: _driverFilter,
                              suggestionType: AutoCompleteType.driver,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Second Row of Filters
                  Row(
                    children: [
                      // Truck Plate Filter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.truckPlate + ':'),
                            const SizedBox(height: 4),
                            AutoCompleteFilterComboBox(
                              placeholder: l10n.filterByPlate,
                              onChanged: (value) =>
                                  setState(() => _truckFilter = value),
                              value: _truckFilter,
                              suggestionType: AutoCompleteType.truckPlate,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),

                      // Client/Supplier Filter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.supplier + ':'),
                            const SizedBox(height: 4),
                            AutoCompleteFilterComboBox(
                              placeholder: l10n.filterBySupplier,
                              onChanged: (value) =>
                                  setState(() => _supplierFilter = value),
                              value: _supplierFilter,
                              suggestionType: AutoCompleteType.supplier,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.client + ':'),
                            const SizedBox(height: 4),
                            AutoCompleteFilterComboBox(
                              placeholder: l10n.filterByClient,
                              onChanged: (value) =>
                                  setState(() => _clientFilter = value),
                              value: _clientFilter,
                              suggestionType: AutoCompleteType.client,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Material Filter
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Date Range Filter
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.startDate + ':'),
                            const SizedBox(height: 4),
                            DatePicker(
                              selected: _startDate,
                              onChanged: (date) =>
                                  setState(() => _startDate = date),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.endDate + ':'),
                            const SizedBox(height: 4),
                            DatePicker(
                              selected: _endDate,
                              onChanged: (date) =>
                                  setState(() => _endDate = date),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Quick Date Buttons
                      Column(
                        children: [
                          const SizedBox(height: 20), // Align with date pickers
                          Button(
                            child: Text(l10n.last7Days),
                            onPressed: () => setState(() {
                              _endDate = DateTime.now();
                              _startDate =
                                  _endDate!.subtract(const Duration(days: 7));
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          Button(
                            child: Text(l10n.last30Days),
                            onPressed: () => setState(() {
                              _endDate = DateTime.now();
                              _startDate =
                                  _endDate!.subtract(const Duration(days: 30));
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Apply/Clear Buttons
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _loadOperations,
                        child: Text(l10n.applyFilters),
                      ),
                      const SizedBox(width: 8),
                      Button(
                        onPressed: _clearFilters,
                        child: Text(l10n.clearFilters),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Filters Section

        const SizedBox(height: 16),

        // Operations Table
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.operationsFound(_operations.length),
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 12),

                // Table Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 1,
                          child: Text(l10n.orderNumber,
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 1,
                          child: Text(l10n.dateTime,
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 1,
                          child: Text(l10n.truckPlate,
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 1,
                          child: Text(l10n.driverName,
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 1,
                          child: Text(l10n.client,
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 1,
                          child: Text(l10n.supplier,
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 1,
                          child: Text(l10n.material,
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 2,
                          child: Text(l10n.netWeightKg,
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 1,
                          child: Text(l10n.status,
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 1,
                          child: Text('Actions',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),

                // Real data from database
                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          const ProgressRing(),
                          const SizedBox(height: 16),
                          Text(l10n.loadingOperations),
                        ],
                      ),
                    ),
                  )
                else if (_operations.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Text(l10n.noOperationsFound),
                    ),
                  )
                else
                  ..._operations
                      .take(50)
                      .map((operation) => Container(
                            key: ValueKey(
                                'operation_${operation['id'] ?? operation['tab_id'] ?? DateTime.now().millisecondsSinceEpoch}'),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey.withOpacity(0.2)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 1,
                                    child: Text(
                                        '${operation['id'] ?? operation['tab_id'] ?? ''}')),
                                Expanded(
                                    flex: 1,
                                    child: Text(_formatDateTime(
                                        operation['created_at']))),
                                Expanded(
                                    flex: 1,
                                    child:
                                        Text(operation['truck_plate'] ?? '')),
                                Expanded(
                                    flex: 1,
                                    child:
                                        Text(operation['driver_name'] ?? '')),
                                Expanded(
                                    flex: 1,
                                    child: Text(operation['client'] ?? '')),
                                Expanded(
                                    flex: 1,
                                    child: Text(operation['supplier'] ?? '')),
                                Expanded(
                                    flex: 1,
                                    child: Text(_getMaterialName(operation))),
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        '${(operation['net_weight'] ?? 0.0).toStringAsFixed(1)}')),
                                Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            _getStatusColor(operation['status'])
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _formatStatus(operation['status']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _getStatusColor(
                                              operation['status']),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )),
                                Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Button(
                                        onPressed: () =>
                                            _showOrderDetails(operation),
                                        child: const Icon(FluentIcons.info),
                                      ),
                                    )),
                              ],
                            ),
                          ))
                      .toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = 'all';
      _driverFilter = '';
      _truckFilter = '';
      _clientFilter = '';
      _supplierFilter = '';
      _materialFilter = '';
      _endDate = DateTime.now();
      _startDate = _endDate!.subtract(const Duration(days: 30));
    });
    _loadOperations();
  }

  void _showOrderDetails(Map<String, dynamic> operation) {
    final weighingTab = WeighingTab.fromMap(operation);
    showDialog<void>(
      context: context,
      builder: (context) => OrderDetailsDialog(operation: weighingTab),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  String _getMaterialName(Map<String, dynamic> operation) {
    // Handle multiple possible field names for material
    return operation['material'] ??
        operation['material_name'] ??
        operation['product_name'] ??
        'N/A';
  }

  String _formatStatus(dynamic status) {
    if (status == null) return 'Unknown';
    return status
        .toString()
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getStatusColor(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'complete':
      case 'completed':
        return Colors.green;
      case 'incomplete':
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
