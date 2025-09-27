import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weighing_system/widgets/autom_complete_filter_combo_box.dart';
import '../providers/report_provider.dart';

class WeightingOperationsView extends StatefulWidget {
  const WeightingOperationsView({super.key});

  @override
  State<WeightingOperationsView> createState() =>
      _WeightingOperationsViewState();
}

class _WeightingOperationsViewState extends State<WeightingOperationsView> {
  String _statusFilter = 'all'; // Show completed operations by default
  String _driverFilter = '';
  String _truckFilter = '';
  String _clientFilter = '';
  String _supplierFilter = '';
  String _materialFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _operations = [];
  bool _isLoading = false;

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
    // final l10n = AppLocalizations.of(context)!; // Commented out - localization not available

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: const Text('Loading Operations History'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: _loadOperations,
            ),
            CommandBarSeparator(),
            CommandBarButton(
              icon: const Icon(FluentIcons.download),
              label: const Text('Export PDF'),
              onPressed: _exportToPdf,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.excel_document),
              label: const Text('Export CSV'),
              onPressed: _exportToCsv,
            ),
          ],
        ),
      ),
      children: [
        // Filters Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                          const Text('Status:'),
                          const SizedBox(height: 4),
                          ComboBox<String>(
                            value: _statusFilter,
                            items: [
                              const ComboBoxItem<String>(
                                  value: 'completed', child: Text('مكتملة')),
                              const ComboBoxItem<String>(
                                  value: 'incomplete',
                                  child: Text('غير مكتملة')),
                              const ComboBoxItem<String>(
                                  value: 'in-progress',
                                  child: Text('قيد التحميل')),
                              const ComboBoxItem<String>(
                                  value: 'cancelled', child: Text('ملغية')),
                              const ComboBoxItem<String>(
                                  value: 'empty', child: Text('فارغة')),
                              const ComboBoxItem<String>(
                                  value: 'all', child: Text('جميع الحالات')),
                            ],
                            onChanged: (value) => setState(
                                () => _statusFilter = value ?? 'completed'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Material:'),
                          const SizedBox(height: 4),
                          AutoCompleteFilterComboBox(
                            placeholder: 'Filter by material...',
                            onChanged: (value) =>
                                setState(() => _materialFilter = value),
                            value: _materialFilter,
                            suggestionType: AutoCompleteType.material,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Driver Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Driver Name:'),
                          const SizedBox(height: 4),
                          AutoCompleteFilterComboBox(
                            placeholder: 'Filter by driver...',
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
                const SizedBox(height: 12),

                // Second Row of Filters
                Row(
                  children: [
                    // Truck Plate Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Truck Plate:'),
                          const SizedBox(height: 4),
                          AutoCompleteFilterComboBox(
                            placeholder: 'Filter by plate...',
                            onChanged: (value) =>
                                setState(() => _truckFilter = value),
                            value: _truckFilter,
                            suggestionType: AutoCompleteType.truckPlate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Client/Supplier Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Supplier:'),
                          const SizedBox(height: 4),
                          AutoCompleteFilterComboBox(
                            placeholder: 'Filter by supplier...',
                            onChanged: (value) =>
                                setState(() => _supplierFilter = value),
                            value: _supplierFilter,
                            suggestionType: AutoCompleteType.supplier,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Client:'),
                          const SizedBox(height: 4),
                          AutoCompleteFilterComboBox(
                            placeholder: 'Filter by client...',
                            onChanged: (value) =>
                                setState(() => _clientFilter = value),
                            value: _clientFilter,
                            suggestionType: AutoCompleteType.client,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Material Filter
                  ],
                ),
                const SizedBox(height: 12),

                // Date Range Filter
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date:'),
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
                          const Text('End Date:'),
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
                          child: const Text('Last 7 Days'),
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
                          child: const Text('Last 30 Days'),
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
                      child: const Text('Apply Filters'),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      onPressed: _clearFilters,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Operations Table
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operations History (${_operations.length} found)',
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
                  child: const Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text('Order #',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 2,
                          child: Text('Date/Time',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 2,
                          child: Text('Truck Plate',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 2,
                          child: Text('Driver',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 2,
                          child: Text('Client',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 2,
                          child: Text('Supplier',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 2,
                          child: Text('Material',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 1,
                          child: Text('Net Weight (kg)',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 1,
                          child: Text('Status',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),

                // Real data from database
                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.all(48),
                    child: const Center(
                      child: Column(
                        children: [
                          ProgressRing(),
                          SizedBox(height: 16),
                          Text('Loading operations...'),
                        ],
                      ),
                    ),
                  )
                else if (_operations.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(48),
                    child: const Center(
                      child: Text(
                          'No operations found for the selected criteria.'),
                    ),
                  )
                else
                  ..._operations
                      .take(50)
                      .map((operation) => Container(
                            key: ValueKey(
                                'operation_${operation['id'] ?? operation['operation_id'] ?? DateTime.now().millisecondsSinceEpoch}'),
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
                                    flex: 2,
                                    child: Text(
                                        '${operation['tab_id'] ?? operation['id'] ?? ''}')),
                                Expanded(
                                    flex: 2,
                                    child: Text(_formatDateTime(
                                        operation['created_at']))),
                                Expanded(
                                    flex: 2,
                                    child:
                                        Text(operation['truck_plate'] ?? '')),
                                Expanded(
                                    flex: 2,
                                    child:
                                        Text(operation['driver_name'] ?? '')),
                                Expanded(
                                    flex: 2,
                                    child: Text(operation['client'] ?? '')),
                                Expanded(
                                    flex: 2,
                                    child: Text(operation['supplier'] ?? '')),
                                Expanded(
                                    flex: 2,
                                    child: Text(_getMaterialName(operation))),
                                Expanded(
                                    flex: 1,
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

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  String _getClientSupplierName(Map<String, dynamic> operation) {
    // Handle multiple possible field names for client/supplier
    return operation['supplier_client'] ??
        operation['client_name'] ??
        operation['supplier_name'] ??
        operation['client'] ??
        operation['supplier'] ??
        '';
  }

  String _getMaterialName(Map<String, dynamic> operation) {
    // Handle multiple possible field names for material
    return operation['material'] ??
        operation['material_name'] ??
        operation['product_name'] ??
        'N/A';
  }

  String _formatOperationType(dynamic type) {
    if (type == null) return 'Unknown';
    return type
        .toString()
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
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

  void _exportToPdf() async {
    final reportProvider = context.read<ReportProvider>();
    final filePath = await reportProvider.exportOrdersHistoryToPDF(
      operations: _operations,
      startDate: _startDate,
      endDate: _endDate,
      filters: {
        'status': _statusFilter,
        'driver': _driverFilter,
        'truck': _truckFilter,
        'client': _clientFilter,
        'supplier': _supplierFilter,
        'material': _materialFilter,
      },
    );

    if (filePath != null) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Export Successful'),
          content: Text('PDF saved to: $filePath'),
          severity: InfoBarSeverity.success,
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
        ),
      );
    }
  }

  void _exportToCsv() async {
    final reportProvider = context.read<ReportProvider>();
    final filePath = await reportProvider.exportOrdersHistoryToCSV(
      operations: _operations,
      startDate: _startDate,
      endDate: _endDate,
      filters: {
        'status': _statusFilter,
        'driver': _driverFilter,
        'truck': _truckFilter,
        'client': _clientFilter,
        'supplier': _supplierFilter,
        'material': _materialFilter,
      },
    );

    if (filePath != null) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Export Successful'),
          content: Text('CSV saved to: $filePath'),
          severity: InfoBarSeverity.success,
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
        ),
      );
    }
  }
}
