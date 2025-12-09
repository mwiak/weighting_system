import 'package:fluent_ui/fluent_ui.dart';
import 'package:weighing_system/database/database_helper.dart';
import 'package:weighing_system/utils/debugging_methods.dart';

import '../models/weighing_tab.dart';
import '../widgets/multi_select.dart';

class SummariesProvider extends ChangeNotifier {
  bool isLoading = true;
  final _db = DatabaseHelper();

  //List<Map<String, dynamic>>

  Future<Map<String, Map<String, Map<String, List<WeighingTab>>>>>
      getDailySummary({
    required DateTime exactDate,
    String? statusFilter,
  }) async {
    final startDate = exactDate.copyWith(hour: 0, minute: 0, second: 0);
    final endDate = exactDate.copyWith(hour: 23, minute: 59, second: 59);

    try {
      String whereClause = "status IN ('completed')";
      List<dynamic> whereArgs = [];

      whereClause += ' AND created_at >= ?';
      whereArgs.add(startDate.toIso8601String());

      whereClause += ' AND created_at <= ?';
      whereArgs.add(endDate.toIso8601String());

      final data = await _db.query(
        'weighing_tabs',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );
      final allTabs = data.map((op) => WeighingTab.fromMap(op)).toList();
      final grouped = <String, Map<String, Map<String, List<WeighingTab>>>>{};

      for (WeighingTab tab in allTabs) {
        final material = tab.material;
        final supplier = tab.supplier;
        final client = tab.client;

        grouped.putIfAbsent(material, () => {'suppliers': {}, 'clients': {}});
        if (supplier.isNotEmpty) {
          grouped[material]!['suppliers']!.putIfAbsent(supplier, () => []);
          grouped[material]!['suppliers']![supplier]!.add(tab);
        }
        if (client.isNotEmpty) {
          grouped[material]!['clients']!.putIfAbsent(client, () => []);
          grouped[material]!['clients']![client]!.add(tab);
        }
      }
      print(grouped);
      return grouped;
    } catch (e) {
      debugPrint('TabsProvider: Error getting tabs history: $e');
      return {};
    }
  }

  Future<Map<String, Map<String, Map<String, List<WeighingTab>>>>>
      getCustomSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? statusFilter,
  }) async {
    try {
      String whereClause = "status IN ('completed')";
      List<dynamic> whereArgs = [];

      whereClause += ' AND created_at >= ?';
      whereArgs.add(startDate.toIso8601String());

      whereClause += ' AND created_at < ?';
      whereArgs.add(endDate.toIso8601String());

      final data = await _db.query(
        'weighing_tabs',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );
      final allTabs = data.map((op) => WeighingTab.fromMap(op)).toList();
      final grouped = <String, Map<String, Map<String, List<WeighingTab>>>>{};

      for (WeighingTab tab in allTabs) {
        final material = tab.material;
        final supplier = tab.supplier;
        final client = tab.client;

        grouped.putIfAbsent(material, () => {'suppliers': {}, 'clients': {}});
        if (supplier.isNotEmpty) {
          grouped[material]!['suppliers']!.putIfAbsent(supplier, () => []);
          grouped[material]!['suppliers']![supplier]!.add(tab);
        }
        if (client.isNotEmpty) {
          grouped[material]!['clients']!.putIfAbsent(client, () => []);
          grouped[material]!['clients']![client]!.add(tab);
        }
      }
      print(grouped);
      return grouped;
    } catch (e) {
      debugPrint('TabsProvider: Error getting tabs history: $e');
      return {};
    }
  }

  Future<Map<String, Map<String, Map<String, List<WeighingTab>>>>>
      getPerPersonSummary({
    required DateTime startDate,
    required DateTime endDate,
    required AutoCompleteType type,
    required List<String> terms,
  }) async {
    try {
      if (terms.isEmpty) return {};

      String whereClause = "status IN ('completed')";
      List<dynamic> whereArgs = [];

      whereClause += ' AND created_at >= ?';
      whereArgs.add(startDate.toIso8601String());

      whereClause += ' AND created_at < ?';
      whereArgs.add(endDate.toIso8601String());

      String column = parseType(type);
      whereClause =
          buildSearchQueryTerms(column, whereClause, terms, whereArgs);
      print(whereArgs);
      print(terms);

      final data = await _db.query(
        'weighing_tabs',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );
      final allTabs = data.map((op) => WeighingTab.fromMap(op)).toList();
      final grouped = <String, Map<String, Map<String, List<WeighingTab>>>>{};

      for (WeighingTab tab in allTabs) {
        final material = tab.material;
        final supplier = tab.supplier;
        final client = tab.client;

        grouped.putIfAbsent(material, () => {'suppliers': {}, 'clients': {}});
        if (supplier.isNotEmpty) {
          grouped[material]!['suppliers']!.putIfAbsent(supplier, () => []);
          grouped[material]!['suppliers']![supplier]!.add(tab);
        }
        if (client.isNotEmpty) {
          grouped[material]!['clients']!.putIfAbsent(client, () => []);
          grouped[material]!['clients']![client]!.add(tab);
        }
      }
      printd(grouped.toString());
      //TODO offload to isolate
      Map<String, Map<String, Map<String, List<WeighingTab>>>> sorted = {};

      return grouped;
    } catch (e) {
      debugPrint('TabsProvider: Error getting tabs history: $e');
      return {};
    }
  }

  String parseType(AutoCompleteType type) {
    switch (type) {
      case AutoCompleteType.client:
        return 'client';
      case AutoCompleteType.supplier:
        return 'supplier';
      case AutoCompleteType.truckPlate:
        return 'truck_plate';
      case AutoCompleteType.driver:
        return 'driver_name';
      case AutoCompleteType.material:
        return 'material';
    }
  }

  String buildSearchQueryTerms(
    String column,
    String query,
    List<String> terms,
    List<dynamic> whereArgs,
  ) {
    if (terms.isEmpty) return query;

    query += ' AND (';
    for (int x = 0; x < terms.length; x++) {
      if (x > 0) query += ' OR ';
      query += '$column = ?';
      whereArgs.add(terms[x]);
    }
    query += ')';
    return query;
  }
}
