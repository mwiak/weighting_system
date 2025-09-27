import 'package:flutter/foundation.dart';
import '../services/weighing_tab_report_service.dart';

class ReportProvider extends ChangeNotifier {
  final WeighingTabReportService _reportService = WeighingTabReportService();

  bool _isGenerating = false;
  String? _lastError;
  WeighingTabDashboardStats? _dashboardStats;
  WeighingTabReportData? _currentReport;

  // Report filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;
  int? _selectedClientId;
  int? _selectedMaterialId;
  String _revenueGroupBy = 'month';

  // Getters
  bool get isGenerating => _isGenerating;
  String? get lastError => _lastError;
  WeighingTabDashboardStats? get dashboardStats => _dashboardStats;
  WeighingTabReportData? get currentReport => _currentReport;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get selectedStatus => _selectedStatus;
  int? get selectedClientId => _selectedClientId;
  int? get selectedMaterialId => _selectedMaterialId;
  String get revenueGroupBy => _revenueGroupBy;

  // Filter setters
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setClientFilter(int? clientId) {
    _selectedClientId = clientId;
    notifyListeners();
  }

  void setMaterialFilter(int? materialId) {
    _selectedMaterialId = materialId;
    notifyListeners();
  }

  void setRevenueGroupBy(String groupBy) {
    _revenueGroupBy = groupBy;
    notifyListeners();
  }

  void clearFilters() {
    _startDate = null;
    _endDate = null;
    _selectedStatus = null;
    _selectedClientId = null;
    _selectedMaterialId = null;
    _revenueGroupBy = 'month';
    notifyListeners();
  }

  Future<bool> loadDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _dashboardStats = await _reportService.getDashboardStats(
        startDate: startDate ?? _startDate,
        endDate: endDate ?? _endDate,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to load dashboard stats: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> generateOrdersReport({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? clientId,
    int? materialId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Temporarily disabled - method doesn't exist in WeighingTabReportService
      throw Exception('Orders report temporarily disabled');
    } catch (e) {
      _setError('Failed to generate orders report: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> generateRevenueReport({
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      throw Exception('Revenue report temporarily disabled');
    } catch (e) {
      _setError('Failed to generate revenue report: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> generateClientReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      throw Exception('Client report temporarily disabled');
    } catch (e) {
      _setError('Failed to generate client report: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> generateMaterialReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      throw Exception('Material report temporarily disabled');
    } catch (e) {
      _setError('Failed to generate material report: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> exportCurrentReportToPDF() async {
    if (_currentReport == null) {
      _setError('No report to export');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      throw Exception('PDF export temporarily disabled');
    } catch (e) {
      _setError('Failed to export report to PDF: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> exportCurrentReportToCSV() async {
    if (_currentReport == null) {
      _setError('No report to export');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      throw Exception('CSV export temporarily disabled');
    } catch (e) {
      _setError('Failed to export report to CSV: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Convenience methods for specific report types
  Future<bool> generateQuickDashboard() async {
    return await loadDashboardStats(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
  }

  Future<bool> generateMonthlyOrdersReport() async {
    return await generateOrdersReport(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
  }

  Future<bool> generateYearlyRevenueReport() async {
    return await generateRevenueReport(
      startDate: DateTime.now().subtract(const Duration(days: 365)),
      endDate: DateTime.now(),
      groupBy: 'month',
    );
  }

  Future<bool> generateWeeklyRevenueReport() async {
    return await generateRevenueReport(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
      groupBy: 'week',
    );
  }

  // Utility methods for formatting data
  String formatRevenue(double? amount) {
    if (amount == null) return '\$0.00';
    return '\$${amount.toStringAsFixed(2)}';
  }

  String formatWeight(double? weight) {
    if (weight == null) return '0 kg';
    return '${weight.toStringAsFixed(1)} kg';
  }

  String formatPercentage(double? percentage) {
    if (percentage == null) return '0%';
    return '${percentage.toStringAsFixed(1)}%';
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _setLoading(bool loading) {
    _isGenerating = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    notifyListeners();
  }

  void clearCurrentReport() {
    _currentReport = null;
    notifyListeners();
  }

  // Methods for operations history management
  Future<List<Map<String, dynamic>>> getOrdersHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? driverFilter,
    String? truckFilter,
    String? clientFilter,
    String? supplierFilter,
    String? materialFilter,
  }) async {
    try {
      return await _reportService.getTabsHistory(
        // Updated method
        startDate: startDate,
        endDate: endDate,
        status: status,
        driverFilter: driverFilter,
        truckFilter: truckFilter,
        clientFilter: clientFilter,
        supplierFilter: supplierFilter,
        materialFilter: materialFilter,
      );
    } catch (e) {
      _setError('Failed to load orders history: $e');
      return [];
    }
  }

  Future<String?> exportOrdersHistoryToPDF({
    required List<Map<String, dynamic>> operations,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      return await _reportService.exportTabsHistoryToPDF(
        // Updated method
        tabs: operations,
        startDate: startDate,
        endDate: endDate,
        filters: filters,
      );
    } catch (e) {
      _setError('Failed to export operations to PDF: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> exportOrdersHistoryToCSV({
    required List<Map<String, dynamic>> operations,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      throw Exception('CSV export temporarily disabled');
    } catch (e) {
      _setError('Failed to export operations to CSV: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
}
