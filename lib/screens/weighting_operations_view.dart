import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:weighing_system/utils/date_range_formatter.dart';
import 'package:weighing_system/utils/debugging_methods.dart';
import '../l10n/app_localizations.dart';
import 'package:weighing_system/models/season.dart';
import 'package:weighing_system/providers/seasons_provider.dart';
import 'package:weighing_system/widgets/autom_complete_filter_combo_box.dart';
import 'package:weighing_system/widgets/operation_widgets/operation_entry.dart';
import 'package:weighing_system/widgets/operation_widgets/operation_header.dart';
import 'package:weighing_system/widgets/order_details_dialog.dart';
import '../providers/report_provider.dart';
import '../models/weighing_tab.dart';
import '../services/excel_service.dart';

class WeightingOperationsView extends StatefulWidget {
  const WeightingOperationsView({super.key});

  @override
  State<WeightingOperationsView> createState() =>
      _WeightingOperationsViewState();
}

class _WeightingOperationsViewState extends State<WeightingOperationsView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String _statusFilter = 'all'; // Show all operations by default
  String _driverFilter = '';
  String _truckFilter = '';
  String _clientFilter = '';
  String _supplierFilter = '';
  String _materialFilter = '';
  String _idFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _operations = [];
  bool _isLoading = false;
  bool checked = true;

  @override
  void initState() {
    super.initState();
    // Set default date range to last 30 days
    _endDate = getLast30EndDate();
    _startDate = getLast30StartDate();
    _loadOperations();
    debugPrint(
        'INIT STATE WAS CALLED ************ \n *********************\n================================');
  }

  void _loadOperations() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<ReportProvider>();

      // debugPrint('Loading operations with filters:');
      // debugPrint('  Status: $_statusFilter');

      // debugPrint('  Date Range: $_startDate to $_endDate');

      final operations = await provider.getOrdersHistory(
          startDate: _startDate,
          endDate: _endDate,
          status: _statusFilter == 'all' ? null : _statusFilter,
          driverFilter: _driverFilter.isEmpty ? null : _driverFilter,
          truckFilter: _truckFilter.isEmpty ? null : _truckFilter,
          supplierFilter: _supplierFilter.isEmpty ? null : _supplierFilter,
          clientFilter: _clientFilter.isEmpty ? null : _clientFilter,
          materialFilter: _materialFilter.isEmpty ? null : _materialFilter,
          idFilter: int.tryParse(_idFilter) ?? 0);

      debugPrint('Found ${operations.length} operations');
      if (operations.isNotEmpty) {
        // debugPrint('Sample operation data: ${operations.first}');
        // Show all available statuses for debugging
        final statuses = operations.map((op) => op['status']).toSet();
        // debugPrint('Available statuses in results: $statuses');
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

  void _loadOperationsWithoutSetState() async {
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
        idFilter: int.tryParse(_idFilter) ?? 0);

    debugPrint('Found ${operations.length} operations');
    if (operations.isNotEmpty) {
      // debugPrint('Sample operation data: ${operations.first}');
      // Show all available statuses for debugging
      final statuses = operations.map((op) => op['status']).toSet();
      // debugPrint('Available statuses in results: $statuses');
    } else {
      // debugPrint('No operations found - this might indicate the issue');
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    printd('OperationViewScreen: rebuilt');

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.time_sheet),
              label: Text('تصدير excel'),
              onPressed: () {
                final excel = ExcelService();
                excel.createOperationsExcel(
                    tabs:
                        _operations.map((o) => WeighingTab.fromMap(o)).toList(),
                    context: context);
              },
            ),
          ],
        ),
      ),
      children: [
        Expander(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(FluentIcons.search),
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
                            Text(l10n.orderNumber + ':'),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 500,
                              child: TextBox(
                                placeholder: 'فلترة بالرقم التسلسلي',
                                onChanged: (value) =>
                                    setState(() => _idFilter = value),
                              ),
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
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            const SizedBox(
                                height: 20), // Align with date pickers
                            Row(
                              children: [
                                Button(
                                  child: Text('اليوم'),
                                  onPressed: () => setState(() {
                                    _startDate = getTodayStartDate();
                                    _endDate = getTodayEndDate();
                                  }),
                                ),
                                const SizedBox(width: 16),
                                Button(
                                  child: Text('البارحة'),
                                  onPressed: () => setState(() {
                                    _endDate = getYesterdayEndDate();
                                    _startDate = getYesterdayStartDate();
                                  }),
                                ),
                                const SizedBox(width: 16),
                                Consumer<SeasonsProvider>(
                                  builder: (BuildContext context, value,
                                      Widget? child) {
                                    return DropDownButton(
                                      title: Text('مواسم'),
                                      items: _buildSeasonsOptions(
                                          value.availableSeasons),
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                DropDownButton(title: Text('مزيد'), items: [
                                  MenuFlyoutItem(
                                      text: Text('آخر 7 أيام'),
                                      onPressed: () => setState(() {
                                            _endDate = getLast7EndDate();
                                            _startDate = getLast7StartDate();
                                          })),
                                  MenuFlyoutItem(
                                    text: Text('آخر 30 يوما'),
                                    onPressed: () => () => setState(() {
                                          _endDate = getLast30EndDate();
                                          _startDate = getLast30StartDate();
                                        }),
                                  ),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Quick Date Buttons
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
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {},
                        child: Text('إعداد تقرير'),
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
                  child: OperationHeader(),
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
                  ..._operations.take(50).map((operation) => OperationEntry(
                      operation: operation,
                      onPressed: (v) {
                        _showOrderDetails(v as Map<String, dynamic>);
                      })),
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

  List<MenuFlyoutItem> _buildSeasonsOptions(List<Season> data) {
    List<MenuFlyoutItem> items = [];

    for (Season item in data) {
      items.add(MenuFlyoutItem(
          text: Text(item.label),
          onPressed: () {
            _endDate = item.seasonEndDate;
            _startDate = item.seasonStartDate;
          }));
    }
    return items;
  }
}
