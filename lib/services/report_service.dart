import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
// import '../models/order.dart'; // Legacy - replaced by weighing_tab_report_service.dart
import '../models/client.dart';
import '../models/supplier.dart';
import '../models/material.dart';

class ReportData {
  final String title;
  final DateTime generatedAt;
  final Map<String, dynamic> data;
  final List<String> columns;
  final List<Map<String, dynamic>> rows;

  ReportData({
    required this.title,
    required this.generatedAt,
    required this.data,
    required this.columns,
    required this.rows,
  });
}

class DashboardStats {
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalWeight;
  final double totalRevenue;
  final double averageWeight;
  final double averageRevenue;
  final Map<String, int> ordersByStatus;
  final Map<String, double> revenueByMonth;
  final Map<String, int> ordersByMaterial;
  final List<Map<String, dynamic>> topClients;

  DashboardStats({
    required this.totalOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalWeight,
    required this.totalRevenue,
    required this.averageWeight,
    required this.averageRevenue,
    required this.ordersByStatus,
    required this.revenueByMonth,
    required this.ordersByMaterial,
    required this.topClients,
  });
}

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final DatabaseHelper _db = DatabaseHelper();

  Future<DashboardStats> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    try {
      // Basic counts
      final totalOrdersResult = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE create_date BETWEEN ? AND ?',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final totalOrders = totalOrdersResult.first['count'] as int;

      final pendingOrdersResult = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE status = ? AND create_date BETWEEN ? AND ?',
        ['draft', startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final pendingOrders = pendingOrdersResult.first['count'] as int;

      final completedOrdersResult = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE status = ? AND create_date BETWEEN ? AND ?',
        ['completed', startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final completedOrders = completedOrdersResult.first['count'] as int;

      // Weight and revenue totals
      final weightsResult = await _db.rawQuery(
        'SELECT SUM(net_weight) as total_weight, AVG(net_weight) as avg_weight FROM orders WHERE net_weight > 0 AND create_date BETWEEN ? AND ?',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final totalWeight = (weightsResult.first['total_weight'] as double?) ?? 0.0;
      final averageWeight = (weightsResult.first['avg_weight'] as double?) ?? 0.0;

      final revenueResult = await _db.rawQuery(
        'SELECT SUM(total_amount) as total_revenue, AVG(total_amount) as avg_revenue FROM orders WHERE create_date BETWEEN ? AND ?',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final totalRevenue = (revenueResult.first['total_revenue'] as double?) ?? 0.0;
      final averageRevenue = (revenueResult.first['avg_revenue'] as double?) ?? 0.0;

      // Orders by status
      final statusResult = await _db.rawQuery(
        'SELECT status, COUNT(*) as count FROM orders WHERE create_date BETWEEN ? AND ? GROUP BY status',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final ordersByStatus = <String, int>{};
      for (final row in statusResult) {
        ordersByStatus[row['status'] as String] = row['count'] as int;
      }

      // Revenue by month (last 12 months) - Revenue available in orders table
      final monthlyRevenueResult = await _db.rawQuery(
        '''SELECT strftime('%Y-%m', create_date) as month, COUNT(*) as count
           FROM orders
           WHERE create_date >= datetime('now', '-12 months')
           GROUP BY strftime('%Y-%m', create_date)
           ORDER BY month''',
      );
      final revenueByMonth = <String, double>{};
      for (final row in monthlyRevenueResult) {
        revenueByMonth[row['month'] as String] = (row['count'] as int).toDouble();
      }

      // Orders by material
      final materialResult = await _db.rawQuery(
        '''SELECT material as material_name, COUNT(id) as count
           FROM orders
           WHERE create_date BETWEEN ? AND ? AND material != ''
           GROUP BY material
           ORDER BY count DESC
           LIMIT 10''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final ordersByMaterial = <String, int>{};
      for (final row in materialResult) {
        ordersByMaterial[row['material_name'] as String? ?? 'Unknown'] = row['count'] as int;
      }

      // Top clients by weight (since revenue not available)
      final topClientsResult = await _db.rawQuery(
        '''SELECT supplier_client as client_name, COUNT(id) as order_count,
                  SUM(net_weight) as total_weight, 0.0 as total_revenue
           FROM orders
           WHERE create_date BETWEEN ? AND ? AND supplier_client != ''
           GROUP BY supplier_client
           ORDER BY total_weight DESC
           LIMIT 10''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return DashboardStats(
        totalOrders: totalOrders,
        activeOrders: pendingOrders,
        completedOrders: completedOrders,
        cancelledOrders: 0, // No cancelled orders in new system
        totalWeight: totalWeight,
        totalRevenue: totalRevenue,
        averageWeight: averageWeight,
        averageRevenue: averageRevenue,
        ordersByStatus: ordersByStatus,
        revenueByMonth: revenueByMonth,
        ordersByMaterial: ordersByMaterial,
        topClients: topClientsResult,
      );
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      return DashboardStats(
        totalOrders: 0,
        activeOrders: 0,
        completedOrders: 0,
        cancelledOrders: 0,
        totalWeight: 0.0,
        totalRevenue: 0.0,
        averageWeight: 0.0,
        averageRevenue: 0.0,
        ordersByStatus: {},
        revenueByMonth: {},
        ordersByMaterial: {},
        topClients: [],
      );
    }
  }

  Future<ReportData> generateOrdersReport({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? clientId,
    int? materialId,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    final whereConditions = ['o.create_date BETWEEN ? AND ?'];
    final params = [startDate.toIso8601String(), endDate.toIso8601String()];

    if (status != null && status.isNotEmpty) {
      whereConditions.add('o.status = ?');
      params.add(status);
    }

    if (clientId != null) {
      whereConditions.add('o.client_id = ?');
      params.add(clientId.toString());
    }

    if (materialId != null) {
      whereConditions.add('o.material_id = ?');
      params.add(materialId.toString());
    }

    final query = '''
      SELECT 
        o.order_number,
        o.status,
        o.operation_type,
        o.truck_plate,
        o.driver_name,
        o.gross_weight,
        o.tare_weight,
        o.net_weight,
        o.unit_price,
        o.total_amount,
        o.weigh_in_time,
        o.weigh_out_time,
        o.create_date,
        c.name as client_name,
        s.name as supplier_name,
        m.name as material_name
      FROM orders o
      LEFT JOIN clients c ON o.client_id = c.id
      LEFT JOIN suppliers s ON o.supplier_id = s.id
      LEFT JOIN materials m ON o.material_id = m.id
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY o.create_date DESC
    ''';

    final results = await _db.rawQuery(query, params);

    return ReportData(
      title: 'Orders Report',
      generatedAt: DateTime.now(),
      data: {
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
        'clientId': clientId,
        'materialId': materialId,
        'totalRecords': results.length,
      },
      columns: [
        'Order Number',
        'Status',
        'Operation',
        'Client',
        'Material',
        'Truck Plate',
        'Net Weight (kg)',
        'Total Amount',
        'Created Date',
      ],
      rows: results,
    );
  }

  Future<ReportData> generateRevenueReport({
    DateTime? startDate,
    DateTime? endDate,
    String groupBy = 'month', // month, week, day
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 90));
    endDate ??= DateTime.now();

    String dateFormat;
    switch (groupBy) {
      case 'day':
        dateFormat = '%Y-%m-%d';
        break;
      case 'week':
        dateFormat = '%Y-W%W';
        break;
      case 'month':
      default:
        dateFormat = '%Y-%m';
        break;
    }

    final query = '''
      SELECT 
        strftime('$dateFormat', o.create_date) as period,
        COUNT(o.id) as order_count,
        SUM(o.net_weight) as total_weight,
        SUM(o.total_amount) as total_revenue,
        AVG(o.total_amount) as avg_revenue,
        AVG(o.net_weight) as avg_weight
      FROM orders o
      WHERE o.create_date BETWEEN ? AND ? 
        AND o.status = 'completed'
        AND o.total_amount > 0
      GROUP BY strftime('$dateFormat', o.create_date)
      ORDER BY period
    ''';

    final results = await _db.rawQuery(query, [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);

    return ReportData(
      title: 'Revenue Report',
      generatedAt: DateTime.now(),
      data: {
        'startDate': startDate,
        'endDate': endDate,
        'groupBy': groupBy,
        'totalRecords': results.length,
        'totalRevenue': results.fold<double>(0, (sum, row) => sum + ((row['total_revenue'] as double?) ?? 0)),
        'totalWeight': results.fold<double>(0, (sum, row) => sum + ((row['total_weight'] as double?) ?? 0)),
      },
      columns: [
        'Period',
        'Orders',
        'Total Weight (kg)',
        'Total Revenue',
        'Avg Revenue',
        'Avg Weight (kg)',
      ],
      rows: results,
    );
  }

  Future<ReportData> generateClientReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 90));
    endDate ??= DateTime.now();

    final query = '''
      SELECT 
        c.name as client_name,
        c.email,
        c.phone,
        c.city,
        COUNT(o.id) as order_count,
        SUM(o.net_weight) as total_weight,
        SUM(o.total_amount) as total_revenue,
        AVG(o.total_amount) as avg_revenue,
        MAX(o.create_date) as last_order_date
      FROM clients c
      LEFT JOIN orders o ON c.id = o.client_id 
        AND o.create_date BETWEEN ? AND ?
        AND o.status = 'completed'
      GROUP BY c.id, c.name, c.email, c.phone, c.city
      ORDER BY total_revenue DESC
    ''';

    final results = await _db.rawQuery(query, [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);

    return ReportData(
      title: 'Client Performance Report',
      generatedAt: DateTime.now(),
      data: {
        'startDate': startDate,
        'endDate': endDate,
        'totalRecords': results.length,
        'activeClients': results.where((r) => (r['order_count'] as int) > 0).length,
      },
      columns: [
        'Client Name',
        'Email',
        'Phone',
        'City',
        'Orders',
        'Total Weight (kg)',
        'Total Revenue',
        'Avg Revenue',
        'Last Order',
      ],
      rows: results,
    );
  }

  Future<ReportData> generateMaterialReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 90));
    endDate ??= DateTime.now();

    final query = '''
      SELECT 
        m.name as material_name,
        m.type,
        m.list_price,
        COUNT(o.id) as order_count,
        SUM(o.net_weight) as total_weight,
        SUM(o.total_amount) as total_revenue,
        AVG(o.net_weight) as avg_weight_per_order,
        MIN(o.create_date) as first_order_date,
        MAX(o.create_date) as last_order_date
      FROM materials m
      LEFT JOIN orders o ON m.id = o.material_id 
        AND o.create_date BETWEEN ? AND ?
        AND o.status = 'completed'
      GROUP BY m.id, m.name, m.type, m.list_price
      ORDER BY total_revenue DESC
    ''';

    final results = await _db.rawQuery(query, [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);

    return ReportData(
      title: 'Material Performance Report',
      generatedAt: DateTime.now(),
      data: {
        'startDate': startDate,
        'endDate': endDate,
        'totalRecords': results.length,
        'activeMaterials': results.where((r) => (r['order_count'] as int) > 0).length,
      },
      columns: [
        'Material Name',
        'Type',
        'List Price',
        'Orders',
        'Total Weight (kg)',
        'Total Revenue',
        'Avg Weight/Order',
        'First Order',
        'Last Order',
      ],
      rows: results,
    );
  }

  Future<String> exportReportToPDF(ReportData report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            _buildReportHeader(report),
            pw.SizedBox(height: 20),
            
            // Summary information
            _buildReportSummary(report),
            pw.SizedBox(height: 20),
            
            // Data table
            _buildReportTable(report),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${report.title.replaceAll(' ', '_')}_${_formatDateForFile(report.generatedAt)}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  Future<String> exportReportToCSV(ReportData report) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${report.title.replaceAll(' ', '_')}_${_formatDateForFile(report.generatedAt)}.csv';
    final file = File('${directory.path}/$fileName');

    final csvContent = StringBuffer();
    
    // Add header row
    csvContent.writeln(report.columns.map((col) => '"$col"').join(','));
    
    // Add data rows
    for (final row in report.rows) {
      final values = report.columns.map((col) {
        final value = _getColumnValue(row, col);
        return '"${value.toString().replaceAll('"', '""')}"';
      }).join(',');
      csvContent.writeln(values);
    }

    await file.writeAsString(csvContent.toString());
    return file.path;
  }

  pw.Widget _buildReportHeader(ReportData report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                report.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated on ${_formatDateTime(report.generatedAt)}',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.Text(
            'Truck Weighing System',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReportSummary(ReportData report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Report Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 20,
            runSpacing: 4,
            children: report.data.entries.map((entry) {
              return pw.Text('${entry.key}: ${entry.value}', style: pw.TextStyle(fontSize: 10));
            }).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReportTable(ReportData report) {
    const int maxRowsPerPage = 25;
    final chunks = _chunkList(report.rows, maxRowsPerPage);
    
    return pw.Column(
      children: chunks.map((chunk) {
        return pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black),
          columnWidths: _getColumnWidths(report.columns),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: report.columns.map((col) => _buildTableCell(col, isHeader: true)).toList(),
            ),
            // Data rows
            ...chunk.map((row) => pw.TableRow(
              children: report.columns.map((col) => 
                _buildTableCell(_getColumnValue(row, col).toString())
              ).toList(),
            )).toList(),
          ],
        );
      }).toList(),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  Map<int, pw.TableColumnWidth> _getColumnWidths(List<String> columns) {
    final widths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < columns.length; i++) {
      widths[i] = const pw.FlexColumnWidth(1.0);
    }
    return widths;
  }

  dynamic _getColumnValue(Map<String, dynamic> row, String column) {
    // Map display column names to database column names
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
      if (column.contains('Amount') || column.contains('Price') || column.contains('Revenue')) {
        return '\$${value.toStringAsFixed(2)}';
      }
      return value.toStringAsFixed(2);
    }
    if (value is DateTime) {
      return _formatDate(value);
    }
    if (column.contains('Date') && value is String) {
      try {
        final date = DateTime.parse(value);
        return _formatDate(date);
      } catch (e) {
        return value;
      }
    }
    return value;
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateForFile(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
  }

  // Operations history methods
  Future<List<Map<String, dynamic>>> getOrdersHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? operationType,
    String? status,
    String? driverFilter,
    String? truckFilter,
    String? clientSupplierFilter,
    String? materialFilter,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();
    

    // Build WHERE conditions for orders table
    final orderWhereConditions = <String>[];
    final orderParams = <dynamic>[];
    
    // Add date filter
    if (startDate != null && endDate != null) {
      orderWhereConditions.add('DATE(o.create_date) >= DATE(?)');
      orderWhereConditions.add('DATE(o.create_date) <= DATE(?)');
      orderParams.add(startDate.toIso8601String().split('T')[0]);
      orderParams.add(endDate.toIso8601String().split('T')[0]);
    }

    if (operationType != null && operationType.isNotEmpty && operationType != 'all') {
      orderWhereConditions.add('o.operation_type = ?');
      orderParams.add(operationType);
    }

    if (status != null && status.isNotEmpty && status != 'all') {
      orderWhereConditions.add('o.status = ?');
      orderParams.add(status);
    }

    if (driverFilter != null && driverFilter.isNotEmpty) {
      orderWhereConditions.add('o.driver_name LIKE ?');
      orderParams.add('%$driverFilter%');
    }

    if (truckFilter != null && truckFilter.isNotEmpty) {
      orderWhereConditions.add('o.truck_plate LIKE ?');
      orderParams.add('%$truckFilter%');
    }

    // Build WHERE conditions for weighing_tabs table
    final tabWhereConditions = <String>['t.is_closed = 1', "t.status IN ('completed', 'cancelled', 'empty')"];
    final tabParams = <dynamic>[];
    
    // Add date filter for tabs
    if (startDate != null && endDate != null) {
      tabWhereConditions.add('DATE(t.created_at) >= DATE(?)');
      tabWhereConditions.add('DATE(t.created_at) <= DATE(?)');
      tabParams.add(startDate.toIso8601String().split('T')[0]);
      tabParams.add(endDate.toIso8601String().split('T')[0]);
    }

    if (operationType != null && operationType.isNotEmpty && operationType != 'all') {
      tabWhereConditions.add('t.operation_type = ?');
      tabParams.add(operationType);
    }

    if (status != null && status.isNotEmpty && status != 'all') {
      tabWhereConditions.add('t.status = ?');
      tabParams.add(status);
    }

    if (driverFilter != null && driverFilter.isNotEmpty) {
      tabWhereConditions.add('t.driver_name LIKE ?');
      tabParams.add('%$driverFilter%');
    }

    if (truckFilter != null && truckFilter.isNotEmpty) {
      tabWhereConditions.add('t.truck_plate LIKE ?');
      tabParams.add('%$truckFilter%');
    }

    if (clientSupplierFilter != null && clientSupplierFilter.isNotEmpty) {
      tabWhereConditions.add('t.supplier_client LIKE ?');
      tabParams.add('%$clientSupplierFilter%');
    }

    if (materialFilter != null && materialFilter.isNotEmpty) {
      tabWhereConditions.add('t.material LIKE ?');
      tabParams.add('%$materialFilter%');
    }

    final orderWhereClause = orderWhereConditions.isNotEmpty 
        ? 'WHERE ${orderWhereConditions.join(' AND ')}'
        : '';
        
    final tabWhereClause = 'WHERE ${tabWhereConditions.join(' AND ')}';
        
    final query = '''
      SELECT * FROM (
        SELECT 
          o.id,
          o.order_number,
          o.operation_type,
          o.client_id,
          o.supplier_id,
          o.material_id,
          o.truck_plate,
          o.driver_name,
          o.driver_license,
          o.gross_weight,
          o.tare_weight,
          o.net_weight,
          o.unit_price,
          o.total_amount,
          o.status,
          o.weigh_in_time,
          o.weigh_out_time,
          o.notes,
          o.create_date as created_at,
          o.write_date as updated_at,
          'orders' as source_table
        FROM orders o
        $orderWhereClause
        
        UNION ALL
        
        SELECT 
          t.id,
          ('WT-' || t.tab_id) as order_number,
          t.operation_type,
          NULL as client_id,
          NULL as supplier_id,
          NULL as material_id,
          t.truck_plate,
          t.driver_name,
          NULL as driver_license,
          t.gross_weight,
          t.empty_weight as tare_weight,
          t.net_weight,
          NULL as unit_price,
          NULL as total_amount,
          t.status,
          NULL as weigh_in_time,
          NULL as weigh_out_time,
          NULL as notes,
          t.created_at,
          t.updated_at,
          'weighing_tabs' as source_table
        FROM weighing_tabs t
        $tabWhereClause
      ) combined
      ORDER BY created_at DESC
      LIMIT 1000
    ''';
    
    // Combine all parameters
    final params = [...orderParams, ...tabParams];

    try {
      final database = await _db.database;
      final results = await database.rawQuery(query, params);
      return results;
    } catch (e) {
      debugPrint('Error getting orders history: $e');
      return [];
    }
  }

  Future<String?> exportOrdersHistoryToPDF({
    required List<Map<String, dynamic>> operations,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    if (operations.isEmpty) return null;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            _buildOperationsHistoryHeader(startDate, endDate, filters),
            pw.SizedBox(height: 20),
            
            // Summary information
            _buildOperationsHistorySummary(operations),
            pw.SizedBox(height: 20),
            
            // Data table
            _buildOperationsHistoryTable(operations),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Operations_History_${_formatDateForFile(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  Future<String?> exportOrdersHistoryToCSV({
    required List<Map<String, dynamic>> operations,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    if (operations.isEmpty) return null;

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Operations_History_${_formatDateForFile(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');

    final csvContent = StringBuffer();
    
    final columns = [
      'Order Number', 'Date/Time', 'Truck Plate', 'Driver', 'Client/Supplier', 
      'Material', 'Type', 'Gross Weight (kg)', 'Tare Weight (kg)', 'Net Weight (kg)', 'Status'
    ];
    
    // Add header row
    csvContent.writeln(columns.map((col) => '"$col"').join(','));
    
    // Add data rows
    for (final operation in operations) {
      final values = [
        operation['order_number'] ?? '',
        _formatDateTime(DateTime.tryParse(operation['create_date']?.toString() ?? '') ?? DateTime.now()),
        operation['truck_plate'] ?? '',
        operation['driver_name'] ?? '',
        operation['client_name'] ?? operation['supplier_name'] ?? 'N/A',
        operation['material_name'] ?? 'N/A',
        operation['operation_type'] ?? '',
        (operation['gross_weight'] ?? 0.0).toStringAsFixed(1),
        (operation['tare_weight'] ?? 0.0).toStringAsFixed(1),
        (operation['net_weight'] ?? 0.0).toStringAsFixed(1),
        operation['status'] ?? '',
      ].map((value) => '"${value.toString().replaceAll('"', '""')}"').join(',');
      csvContent.writeln(values);
    }

    await file.writeAsString(csvContent.toString());
    return file.path;
  }

  pw.Widget _buildOperationsHistoryHeader(DateTime? startDate, DateTime? endDate, Map<String, dynamic>? filters) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Operations History Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Truck Weighing System',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated on ${_formatDateTime(DateTime.now())}',
            style: pw.TextStyle(fontSize: 12),
          ),
          if (startDate != null && endDate != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Period: ${_formatDate(startDate)} to ${_formatDate(endDate)}',
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildOperationsHistorySummary(List<Map<String, dynamic>> operations) {
    final totalOperations = operations.length;
    final completedOperations = operations.where((op) => op['status'] == 'completed').length;
    final activeOperations = operations.where((op) => op['status'] == 'active').length;
    final totalWeight = operations.fold<double>(0, (sum, op) => sum + ((op['net_weight'] as double?) ?? 0));
    final totalRevenue = operations.fold<double>(0, (sum, op) => sum + ((op['total_amount'] as double?) ?? 0));

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 20,
            runSpacing: 4,
            children: [
              pw.Text('Total Operations: $totalOperations', style: pw.TextStyle(fontSize: 10)),
              pw.Text('Completed: $completedOperations', style: pw.TextStyle(fontSize: 10)),
              pw.Text('Active: $activeOperations', style: pw.TextStyle(fontSize: 10)),
              pw.Text('Total Weight: ${totalWeight.toStringAsFixed(1)} kg', style: pw.TextStyle(fontSize: 10)),
              pw.Text('Total Revenue: \$${totalRevenue.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildOperationsHistoryTable(List<Map<String, dynamic>> operations) {
    const int maxRowsPerPage = 20;
    final chunks = _chunkList(operations, maxRowsPerPage);
    
    final columns = ['Order #', 'Date', 'Truck', 'Driver', 'Client/Supplier', 'Material', 'Type', 'Net Weight', 'Status'];
    
    return pw.Column(
      children: chunks.map((chunk) {
        return pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.0),
            3: const pw.FlexColumnWidth(1.0),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(1.0),
            6: const pw.FlexColumnWidth(0.8),
            7: const pw.FlexColumnWidth(1.0),
            8: const pw.FlexColumnWidth(0.8),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: columns.map((col) => _buildTableCell(col, isHeader: true)).toList(),
            ),
            // Data rows
            ...chunk.map((operation) => pw.TableRow(
              children: [
                _buildTableCell(operation['order_number']?.toString() ?? ''),
                _buildTableCell(_formatDate(DateTime.tryParse(operation['create_date']?.toString() ?? '') ?? DateTime.now())),
                _buildTableCell(operation['truck_plate']?.toString() ?? ''),
                _buildTableCell(operation['driver_name']?.toString() ?? ''),
                _buildTableCell((operation['client_name'] ?? operation['supplier_name'])?.toString() ?? 'N/A'),
                _buildTableCell(operation['material_name']?.toString() ?? 'N/A'),
                _buildTableCell(operation['operation_type']?.toString() ?? ''),
                _buildTableCell('${(operation['net_weight'] ?? 0.0).toStringAsFixed(1)} kg'),
                _buildTableCell(operation['status']?.toString() ?? ''),
              ],
            )).toList(),
          ],
        );
      }).toList(),
    );
  }
}