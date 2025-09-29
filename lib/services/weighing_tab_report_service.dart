import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/weighing_tab.dart';

class WeighingTabReportData {
  final String title;
  final DateTime generatedAt;
  final Map<String, dynamic> data;
  final List<String> columns;
  final List<Map<String, dynamic>> rows;

  WeighingTabReportData({
    required this.title,
    required this.generatedAt,
    required this.data,
    required this.columns,
    required this.rows,
  });
}

class WeighingTabDashboardStats {
  final int totalTabs;
  final int activeTabs;
  final int completedTabs;
  final int cancelledTabs;
  final double totalWeight;
  final double averageWeight;
  final Map<String, int> tabsByStatus;
  final Map<String, double> weightByMonth;
  final Map<String, int> tabsByMaterial;
  final List<Map<String, dynamic>> topDrivers;

  WeighingTabDashboardStats({
    required this.totalTabs,
    required this.activeTabs,
    required this.completedTabs,
    required this.cancelledTabs,
    required this.totalWeight,
    required this.averageWeight,
    required this.tabsByStatus,
    required this.weightByMonth,
    required this.tabsByMaterial,
    required this.topDrivers,
  });
}

class WeighingTabReportService {
  static final WeighingTabReportService _instance =
      WeighingTabReportService._internal();
  factory WeighingTabReportService() => _instance;
  WeighingTabReportService._internal();

  final DatabaseHelper _db = DatabaseHelper();

  Future<WeighingTabDashboardStats> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    try {
      // Basic counts
      final totalTabsResult = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM weighing_tabs WHERE DATE(created_at) BETWEEN DATE(?) AND DATE(?)',
        [
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0]
        ],
      );
      final totalTabs = totalTabsResult.first['count'] as int;

      final activeTabsResult = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM weighing_tabs WHERE status = ? AND DATE(created_at) BETWEEN DATE(?) AND DATE(?)',
        [
          'in-progress',
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0]
        ],
      );
      final activeTabs = activeTabsResult.first['count'] as int;

      final completedTabsResult = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM weighing_tabs WHERE status = ? AND DATE(created_at) BETWEEN DATE(?) AND DATE(?)',
        [
          'completed',
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0]
        ],
      );
      final completedTabs = completedTabsResult.first['count'] as int;

      final cancelledTabsResult = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM weighing_tabs WHERE status = ? AND DATE(created_at) BETWEEN DATE(?) AND DATE(?)',
        [
          'cancelled',
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0]
        ],
      );
      final cancelledTabs = cancelledTabsResult.first['count'] as int;

      // Weight totals
      final weightsResult = await _db.rawQuery(
        'SELECT SUM(net_weight) as total_weight, AVG(net_weight) as avg_weight FROM weighing_tabs WHERE net_weight > 0 AND DATE(created_at) BETWEEN DATE(?) AND DATE(?)',
        [
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0]
        ],
      );
      final totalWeight =
          (weightsResult.first['total_weight'] as double?) ?? 0.0;
      final averageWeight =
          (weightsResult.first['avg_weight'] as double?) ?? 0.0;

      // Tabs by status
      final statusResult = await _db.rawQuery(
        'SELECT status, COUNT(*) as count FROM weighing_tabs WHERE DATE(created_at) BETWEEN DATE(?) AND DATE(?) GROUP BY status',
        [
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0]
        ],
      );
      final tabsByStatus = <String, int>{};
      for (final row in statusResult) {
        tabsByStatus[row['status'] as String] = row['count'] as int;
      }

      // Weight by month (last 12 months)
      final monthlyWeightResult = await _db.rawQuery(
        '''SELECT strftime('%Y-%m', created_at) as month, SUM(net_weight) as total_weight
           FROM weighing_tabs
           WHERE created_at >= datetime('now', '-12 months') AND net_weight > 0
           GROUP BY strftime('%Y-%m', created_at)
           ORDER BY month''',
      );
      final weightByMonth = <String, double>{};
      for (final row in monthlyWeightResult) {
        weightByMonth[row['month'] as String] =
            (row['total_weight'] as double?) ?? 0.0;
      }

      // Tabs by material
      final materialResult = await _db.rawQuery(
        '''SELECT material, COUNT(*) as count
           FROM weighing_tabs
           WHERE DATE(created_at) BETWEEN DATE(?) AND DATE(?) AND material != ''
           GROUP BY material
           ORDER BY count DESC
           LIMIT 10''',
        [
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0]
        ],
      );
      final tabsByMaterial = <String, int>{};
      for (final row in materialResult) {
        tabsByMaterial[row['material'] as String? ?? 'Unknown'] =
            row['count'] as int;
      }

      // Top drivers by weight
      final topDriversResult = await _db.rawQuery(
        '''SELECT driver_name, COUNT(*) as tab_count, SUM(net_weight) as total_weight
           FROM weighing_tabs
           WHERE DATE(created_at) BETWEEN DATE(?) AND DATE(?) AND driver_name != '' AND net_weight > 0
           GROUP BY driver_name
           ORDER BY total_weight DESC
           LIMIT 10''',
        [
          startDate.toIso8601String().split('T')[0],
          endDate.toIso8601String().split('T')[0]
        ],
      );

      return WeighingTabDashboardStats(
        totalTabs: totalTabs,
        activeTabs: activeTabs,
        completedTabs: completedTabs,
        cancelledTabs: cancelledTabs,
        totalWeight: totalWeight,
        averageWeight: averageWeight,
        tabsByStatus: tabsByStatus,
        weightByMonth: weightByMonth,
        tabsByMaterial: tabsByMaterial,
        topDrivers: topDriversResult,
      );
    } catch (e) {
      debugPrint('Error getting weighing tab dashboard stats: $e');
      return WeighingTabDashboardStats(
        totalTabs: 0,
        activeTabs: 0,
        completedTabs: 0,
        cancelledTabs: 0,
        totalWeight: 0.0,
        averageWeight: 0.0,
        tabsByStatus: {},
        weightByMonth: {},
        tabsByMaterial: {},
        topDrivers: [],
      );
    }
  }

  Future<WeighingTabReportData> generateTabsReport({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? driverName,
    String? truckPlate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    final whereConditions = <String>[];
    final params = <dynamic>[];

    // Add date filter
    whereConditions.add('DATE(created_at) BETWEEN DATE(?) AND DATE(?)');
    params.add(startDate.toIso8601String().split('T')[0]);
    params.add(endDate.toIso8601String().split('T')[0]);

    // Add filters
    if (status != null && status.isNotEmpty && status != 'all') {
      whereConditions.add('status = ?');
      params.add(status);
    }

    if (driverName != null && driverName.isNotEmpty) {
      whereConditions.add('driver_name LIKE ?');
      params.add('%$driverName%');
    }

    if (truckPlate != null && truckPlate.isNotEmpty) {
      whereConditions.add('truck_plate LIKE ?');
      params.add('%$truckPlate%');
    }

    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';

    final query = '''
      SELECT
        tab_id,
        truck_plate,
        driver_name,
        supplier_client,
        material,
        empty_weight,
        gross_weight,
        net_weight,
        status,
        is_paid,
        created_at,
        updated_at
      FROM weighing_tabs
      $whereClause
      ORDER BY created_at DESC
      LIMIT 1000
    ''';

    try {
      final results = await _db.rawQuery(query, params);

      final columns = [
        'Tab ID',
        'Truck Plate',
        'Driver',
        'Client/Supplier',
        'Material',
        'Empty Weight (kg)',
        'Gross Weight (kg)',
        'Net Weight (kg)',
        'Operation',
        'Status',
        'Paid',
        'Created At',
      ];

      final rows = results.map((row) {
        return {
          'Tab ID': row['tab_id']?.toString() ?? '',
          'Truck Plate': row['truck_plate']?.toString() ?? '',
          'Driver': row['driver_name']?.toString() ?? '',
          'Client/Supplier': row['supplier_client']?.toString() ?? '',
          'Material': row['material']?.toString() ?? '',
          'Empty Weight (kg)':
              (row['empty_weight'] as double?)?.toStringAsFixed(0) ?? '0',
          'Gross Weight (kg)':
              (row['gross_weight'] as double?)?.toStringAsFixed(0) ?? '0',
          'Net Weight (kg)':
              (row['net_weight'] as double?)?.toStringAsFixed(0) ?? '0',
          'Status': row['status']?.toString() ?? '',
          'Paid': (row['is_paid'] as int?) == 1 ? 'Yes' : 'No',
          'Created At': row['created_at']?.toString() ?? '',
        };
      }).toList();

      final data = {
        'total_tabs': results.length,
        'total_weight': results.fold(
            0.0, (sum, row) => sum + ((row['net_weight'] as double?) ?? 0.0)),
        'date_range':
            '${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}',
        'filters_applied': {
          'status': status,
          'driver_name': driverName,
          'truck_plate': truckPlate,
        },
      };

      return WeighingTabReportData(
        title: 'Weighing Tabs Report',
        generatedAt: DateTime.now(),
        data: data,
        columns: columns,
        rows: rows,
      );
    } catch (e) {
      debugPrint('Error generating tabs report: $e');
      return WeighingTabReportData(
        title: 'Weighing Tabs Report',
        generatedAt: DateTime.now(),
        data: {'error': e.toString()},
        columns: [],
        rows: [],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getTabsHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? driverFilter,
    String? truckFilter,
    String? clientFilter,
    String? supplierFilter,
    String? materialFilter,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    final whereConditions = <String>[];
    final params = <dynamic>[];

    // Date filter
    whereConditions.add('DATE(created_at) BETWEEN DATE(?) AND DATE(?)');
    params.add(startDate.toIso8601String().split('T')[0]);
    params.add(endDate.toIso8601String().split('T')[0]);

    // Include all tabs in history (all statuses: in-progress, completed, cancelled)

    // Add filters

    if (status != null && status.isNotEmpty && status != 'all') {
      whereConditions.add('status = ?');
      params.add(status);
    }

    if (driverFilter != null && driverFilter.isNotEmpty) {
      whereConditions.add('driver_name LIKE ?');
      params.add('%$driverFilter%');
    }

    if (truckFilter != null && truckFilter.isNotEmpty) {
      whereConditions.add('truck_plate LIKE ?');
      params.add('%$truckFilter%');
    }

    if (clientFilter != null && clientFilter.isNotEmpty) {
      whereConditions.add('client LIKE ?');
      params.add('%$clientFilter%');
    }

    if (supplierFilter != null && supplierFilter.isNotEmpty) {
      whereConditions.add('supplier LIKE ?');
      params.add('%$supplierFilter%');
    }

    if (materialFilter != null && materialFilter.isNotEmpty) {
      whereConditions.add('material LIKE ?');
      params.add('%$materialFilter%');
    }

    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';

    final query = '''
      SELECT
        tab_id as id,
        truck_plate,
        driver_name,
        client,
        supplier,
        material,
        empty_weight,
        gross_weight,
        net_weight,
        status,
        is_paid,
        created_at,
        updated_at,
        'weighing_tabs' as source_table
      FROM weighing_tabs
      $whereClause
      ORDER BY created_at DESC
      LIMIT 1000
    ''';

    try {
      final database = await _db.database;

      debugPrint('WeighingTabReportService: Executing query:');
      debugPrint('  Query: $query');
      debugPrint('  Params: $params');

      final results = await database.rawQuery(query, params);

      debugPrint('WeighingTabReportService: Found ${results.length} results');
      if (results.isNotEmpty) {
        debugPrint('  Sample result: ${results}');
        // Show available statuses in database
        final statuses = results.map((r) => r['status']).toSet();
        debugPrint('  Available statuses: $statuses');
      }

      return results;
    } catch (e) {
      debugPrint('Error getting tabs history: $e');
      return [];
    }
  }

  Future<String?> exportTabsHistoryToPDF({
    required List<Map<String, dynamic>> tabs,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    if (tabs.isEmpty) return null;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            _buildTabsHistoryHeader(startDate, endDate, filters),
            pw.SizedBox(height: 20),

            // Summary information
            _buildTabsHistorySummary(tabs),
            pw.SizedBox(height: 20),

            // Data table
            _buildTabsHistoryTable(tabs),
          ];
        },
      ),
    );

    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File(
          '${output.path}/weighing_tabs_history_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      debugPrint('Error saving tabs history PDF: $e');
      return null;
    }
  }

  pw.Widget _buildTabsHistoryHeader(
      DateTime? startDate, DateTime? endDate, Map<String, dynamic>? filters) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Weighing Tabs History Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Generated on: ${DateTime.now().toString().split('.')[0]}',
          style: const pw.TextStyle(fontSize: 12),
        ),
        if (startDate != null && endDate != null)
          pw.Text(
            'Period: ${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        if (filters != null && filters.isNotEmpty)
          pw.Text(
            'Filters Applied: ${filters.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).map((e) => '${e.key}: ${e.value}').join(', ')}',
            style: const pw.TextStyle(fontSize: 10),
          ),
      ],
    );
  }

  pw.Widget _buildTabsHistorySummary(List<Map<String, dynamic>> tabs) {
    final totalWeight = tabs.fold(
        0.0, (sum, tab) => sum + ((tab['net_weight'] as double?) ?? 0.0));
    final completedTabs =
        tabs.where((tab) => tab['status'] == 'completed').length;
    final averageWeight = tabs.isNotEmpty ? totalWeight / tabs.length : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text('Total Tabs',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${tabs.length}'),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Completed',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('$completedTabs'),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Total Weight',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${totalWeight.toStringAsFixed(0)} kg'),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Average Weight',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${averageWeight.toStringAsFixed(0)} kg'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTabsHistoryTable(List<Map<String, dynamic>> tabs) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(1.5),
        7: const pw.FlexColumnWidth(1.5),
        8: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Tab ID',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Truck',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Driver',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Client',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Supplier',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Material',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Empty (kg)',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Gross (kg)',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Net (kg)',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Status',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
        // Data rows
        ...tabs.take(50).map((tab) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('${tab['tab_id'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('${tab['truck_plate'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('${tab['driver_name'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('${tab['client'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('${tab['supplier'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('${tab['material'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                      '${(tab['empty_weight'] as double?)?.toStringAsFixed(0) ?? '0'}',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                      '${(tab['gross_weight'] as double?)?.toStringAsFixed(0) ?? '0'}',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                      '${(tab['net_weight'] as double?)?.toStringAsFixed(0) ?? '0'}',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('${tab['status'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
              ],
            )),
      ],
    );
  }

  Future<String?> exportTabsReportToCSV({
    required WeighingTabReportData reportData,
  }) async {
    if (reportData.rows.isEmpty) return null;

    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File(
          '${output.path}/weighing_tabs_report_${DateTime.now().millisecondsSinceEpoch}.csv');

      final csv = StringBuffer();

      // Add header
      csv.writeln(reportData.columns.join(','));

      // Add data rows
      for (final row in reportData.rows) {
        final values = reportData.columns
            .map((column) => '"${row[column] ?? ''}"')
            .join(',');
        csv.writeln(values);
      }

      await file.writeAsString(csv.toString());
      return file.path;
    } catch (e) {
      debugPrint('Error exporting tabs report to CSV: $e');
      return null;
    }
  }
}
