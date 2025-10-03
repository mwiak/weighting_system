import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/client_provider.dart';
import '../providers/report_provider.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  int _selectedReportIndex = 0;

  List<String> _reportTypes = [];

  @override
  void initState() {
    super.initState();
    // Load initial dashboard stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Initialize report types with localization
    _reportTypes = [
      l10n.dashboard,
      l10n.ordersReport,
      l10n.revenueReport,
      l10n.clientReport,
      l10n.materialReport,
    ];

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(l10n.reportsAndAnalytics),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: Text(l10n.refresh),
              onPressed: () => _refreshCurrentReport(),
            ),
            CommandBarSeparator(),
            CommandBarButton(
              icon: const Icon(FluentIcons.download),
              label: Text(l10n.exportPdf),
              onPressed: () => _exportToPDF(),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.excel_document),
              label: Text(l10n.exportCsv),
              onPressed: () => _exportToCSV(),
            ),
          ],
        ),
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sidebar - Report types
            SizedBox(
              width: 200,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reportTypes,
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_reportTypes.length, (index) {
                        final isSelected = _selectedReportIndex == index;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile.selectable(
                            selected: isSelected,
                            title: Text(_reportTypes[index]),
                            onSelectionChange: (selected) {
                              if (selected) {
                                setState(() => _selectedReportIndex = index);
                                _loadSelectedReport();
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Main content area
            Expanded(
              child: Consumer<ReportProvider>(
                builder: (context, reportProvider, child) {
                  return Column(
                    children: [
                      // Filters section
                      _buildFiltersSection(reportProvider),
                      const SizedBox(height: 16),

                      // Report content
                      _buildReportContent(reportProvider),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersSection(ReportProvider reportProvider) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.filters,
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Date Range
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: InfoLabel(
                          label: l10n.startDate,
                          child: DatePicker(
                            selected: reportProvider.startDate,
                            onChanged: (date) {
                              reportProvider.setDateRange(
                                date,
                                reportProvider.endDate,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoLabel(
                          label: l10n.endDate,
                          child: DatePicker(
                            selected: reportProvider.endDate,
                            onChanged: (date) {
                              reportProvider.setDateRange(
                                reportProvider.startDate,
                                date,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Quick date ranges
                DropDownButton(
                  title: Text(l10n.quickRange),
                  items: [
                    MenuFlyoutItem(
                      text: Text(l10n.last7Days),
                      onPressed: () => _setQuickDateRange(7),
                    ),
                    MenuFlyoutItem(
                      text: Text(l10n.last30Days),
                      onPressed: () => _setQuickDateRange(30),
                    ),
                    MenuFlyoutItem(
                      text: Text(l10n.last90Days),
                      onPressed: () => _setQuickDateRange(90),
                    ),
                    MenuFlyoutItem(
                      text: Text(l10n.thisYear),
                      onPressed: () => _setQuickDateRange(365),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                FilledButton(
                  onPressed: reportProvider.isGenerating ? null : _applyFilters,
                  child: reportProvider.isGenerating
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: ProgressRing(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.generatingReport),
                          ],
                        )
                      : Text(l10n.applyFilters),
                ),
                const SizedBox(width: 8),
                Button(
                  onPressed: () {
                    reportProvider.clearFilters();
                    _applyFilters();
                  },
                  child: Text(l10n.clear),
                ),
              ],
            ),

            // Additional filters based on report type
            if (_selectedReportIndex == 1) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Consumer<ClientProvider>(
                      builder: (context, clientProvider, child) {
                        return InfoLabel(
                          label: l10n.clientFilter,
                          child: ComboBox<int?>(
                            placeholder: Text(l10n.allClients),
                            value: reportProvider.selectedClientId,
                            items: [
                              ComboBoxItem<int?>(
                                value: null,
                                child: Text(l10n.allClients),
                              ),
                              ...clientProvider.clients.map(
                                (client) => ComboBoxItem<int?>(
                                  value: client.id,
                                  child: Text(client.name),
                                ),
                              ),
                            ],
                            onChanged: reportProvider.setClientFilter,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoLabel(
                      label: l10n.statusFilter,
                      child: ComboBox<String?>(
                        placeholder: Text(l10n.allStatuses),
                        value: reportProvider.selectedStatus,
                        items: [
                          ComboBoxItem<String?>(
                            value: null,
                            child: Text(l10n.allStatuses),
                          ),
                          ComboBoxItem<String?>(
                            value: 'active',
                            child: Text(l10n.active),
                          ),
                          ComboBoxItem<String?>(
                            value: 'completed',
                            child: Text(l10n.completed),
                          ),
                          ComboBoxItem<String?>(
                            value: 'cancelled',
                            child: Text(l10n.cancelled),
                          ),
                        ],
                        onChanged: reportProvider.setStatusFilter,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (_selectedReportIndex == 2) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                child: InfoLabel(
                  label: l10n.groupBy,
                  child: ComboBox<String>(
                    value: reportProvider.revenueGroupBy,
                    items: [
                      ComboBoxItem(value: 'day', child: Text(l10n.daily)),
                      ComboBoxItem(value: 'week', child: Text(l10n.weekly)),
                      ComboBoxItem(value: 'month', child: Text(l10n.monthly)),
                    ],
                    onChanged: (value) =>
                        reportProvider.setRevenueGroupBy(value ?? 'month'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(ReportProvider reportProvider) {
    final l10n = AppLocalizations.of(context)!;

    if (reportProvider.isGenerating) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                const ProgressRing(),
                const SizedBox(height: 16),
                Text(l10n.generatingReport),
              ],
            ),
          ),
        ),
      );
    }

    if (reportProvider.lastError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: InfoBar(
            title: Text(l10n.error),
            content: Text(reportProvider.lastError ?? l10n.unknown),
            severity: InfoBarSeverity.error,
          ),
        ),
      );
    }

    switch (_selectedReportIndex) {
      case 0:
        return _buildDashboardView(reportProvider);
      case 1:
      case 2:
      case 3:
      case 4:
        return _buildReportTableView(reportProvider);
      default:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.selectReportType),
          ),
        );
    }
  }

  Widget _buildDashboardView(ReportProvider reportProvider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = reportProvider.dashboardStats;
    if (stats == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.noDashboardData),
        ),
      );
    }

    return Column(
      children: [
        // Stats cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                l10n.totalTabs,
                stats.totalTabs.toString(),
                FluentIcons.clipboard_list,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                l10n.totalWeight,
                reportProvider.formatWeight(stats.totalWeight),
                FluentIcons.scale_volume,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                l10n.totalRevenue,
                reportProvider.formatWeight(stats.totalWeight),
                FluentIcons.money,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                l10n.activeTabs,
                stats.activeTabs.toString(),
                FluentIcons.processing,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Orders by status chart
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.ordersByStatus,
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 12),
                      ...stats.tabsByStatus.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key.toUpperCase()),
                              Text(entry.value.toString()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Top clients
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.topDriversByWeight,
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 12),
                      ...stats.topDrivers.take(5).map(
                            (driver) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      driver['driver_name']?.toString() ??
                                          l10n.unknown,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(reportProvider.formatWeight(
                                    driver['total_weight'] as double?,
                                  )),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportTableView(ReportProvider reportProvider) {
    final l10n = AppLocalizations.of(context)!;
    final report = reportProvider.currentReport;
    if (report == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.noReportData),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.generated}: ${reportProvider.formatDate(report.generatedAt)} | ${report.rows.length} ${l10n.records}',
                      style: TextStyle(color: Colors.grey[120]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Report summary
            if (report.data.isNotEmpty) ...[
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: report.data.entries.map((entry) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[20],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Data table - Using ListView instead of DataTable for Fluent UI compatibility
            SizedBox(
              height: 400, // Fixed height to prevent unlimited height error
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[20],
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                      child: Row(
                        children: report.columns
                            .map((column) => Expanded(
                                  child: Text(column,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ))
                            .toList(),
                      ),
                    ),
                    // Data rows
                    ...report.rows.take(100).map((row) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey[60] ?? Colors.grey)),
                          ),
                          child: Row(
                            children: report.columns
                                .map((column) => Expanded(
                                      child: Text(_getTableCellValue(
                                          row, column, reportProvider)),
                                    ))
                                .toList(),
                          ),
                        )),
                  ],
                ),
              ),
            ),

            if (report.rows.length > 100) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.showingFirst} 100 ${l10n.records}.',
                style: TextStyle(color: Colors.grey[120], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, AccentColor color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[120],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTableCellValue(
      Map<String, dynamic> row, String column, ReportProvider reportProvider) {
    final columnMap = {
      'Order Number': 'order_number',
      'Status': 'status',
      'Operation': 'operation_type',
      'Client': 'client_name',
      'Material': 'material_name',
      'Truck Plate': 'truck_plate',
      'Net Weight (kg)': 'net_weight',
      'Total Amount': 'total_amount',
      'Created Date': 'create_date',
      'Period': 'period',
      'Orders': 'order_count',
      'Total Weight (kg)': 'total_weight',
      'Total Revenue': 'total_revenue',
      'Avg Revenue': 'avg_revenue',
      'Avg Weight (kg)': 'avg_weight',
      'Client Name': 'client_name',
      'Email': 'email',
      'Phone': 'phone',
      'City': 'city',
      'Last Order': 'last_order_date',
      'Material Name': 'material_name',
      'Type': 'type',
      'List Price': 'list_price',
      'Avg Weight/Order': 'avg_weight_per_order',
      'First Order': 'first_order_date',
    };

    final key = columnMap[column] ?? column.toLowerCase().replaceAll(' ', '_');
    final value = row[key];

    if (value == null) return '';
    if (value is double) {
      if (column.contains('Amount') ||
          column.contains('Price') ||
          column.contains('Revenue')) {
        return reportProvider.formatRevenue(value);
      }
      if (column.contains('Weight')) {
        return reportProvider.formatWeight(value);
      }
      return value.toStringAsFixed(2);
    }
    if (column.contains('Date') && value is String) {
      try {
        final date = DateTime.parse(value);
        return reportProvider.formatDate(date);
      } catch (e) {
        return value;
      }
    }
    return value.toString();
  }

  void _setQuickDateRange(int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    context.read<ReportProvider>().setDateRange(startDate, endDate);
  }

  void _loadSelectedReport() {
    final reportProvider = context.read<ReportProvider>();

    switch (_selectedReportIndex) {
      case 0:
        reportProvider.loadDashboardStats();
        break;
      case 1:
        reportProvider.generateOrdersReport();
        break;
      case 2:
        reportProvider.generateRevenueReport();
        break;
      case 3:
        reportProvider.generateClientReport();
        break;
      case 4:
        reportProvider.generateMaterialReport();
        break;
    }
  }

  void _applyFilters() {
    _loadSelectedReport();
  }

  void _refreshCurrentReport() {
    _loadSelectedReport();
  }

  void _exportToPDF() async {
    final l10n = AppLocalizations.of(context)!;
    final reportProvider = context.read<ReportProvider>();
    final filePath = await reportProvider.exportCurrentReportToPDF();

    if (filePath != null) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: Text(l10n.exportSuccessful),
          content: Text('${l10n.pdfSavedTo}: $filePath'),
          severity: InfoBarSeverity.success,
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
        ),
      );
    }
  }

  void _exportToCSV() async {
    final l10n = AppLocalizations.of(context)!;
    final reportProvider = context.read<ReportProvider>();
    final filePath = await reportProvider.exportCurrentReportToCSV();

    if (filePath != null) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: Text(l10n.exportSuccessful),
          content: Text('${l10n.csvSavedTo}: $filePath'),
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
