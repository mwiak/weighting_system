import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:weighing_system/utils/debugging_methods.dart';

// Simple script to add test data to the weighing system database
void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  printd('Adding test data to weighing system database...');

  try {
    // Find the database path (similar to how the app does it)
    final documentsPath = Platform.environment['USERPROFILE'];
    if (documentsPath == null) {
      printd('Could not find user profile path');
      return;
    }

    final dbPath = join(documentsPath, 'Documents', 'database', 'database.db');
    printd('Database path: $dbPath');

    if (!File(dbPath).existsSync()) {
      printd('Database file does not exist at: $dbPath');
      return;
    }

    final db = await openDatabase(dbPath);

    // Check current data
    final existingTabs = await db.query('weighing_tabs');
    printd('Existing tabs: ${existingTabs.length}');

    // Add test completed tabs
    final testTabs = [
      {
        'tab_id': 1001,
        'empty_weight': 5000.0,
        'gross_weight': 25000.0,
        'net_weight': 20000.0,
        'truck_plate': 'ABC-123',
        'driver_name': 'John Smith',
        'supplier_client': 'Test Client 1',
        'material': 'Sand',
        'is_paid': 1,
        'show_price_on_print': 1,
        'operation_type': 'loading',
        'has_unsaved_changes': 0,
        'status': 'completed',
        'created_at':
            DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'updated_at':
            DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
      },
      {
        'tab_id': 1002,
        'empty_weight': 4500.0,
        'gross_weight': 24500.0,
        'net_weight': 20000.0,
        'truck_plate': 'DEF-456',
        'driver_name': 'Jane Doe',
        'supplier_client': 'Test Supplier 1',
        'material': 'Gravel',
        'is_paid': 0,
        'show_price_on_print': 1,
        'operation_type': 'unloading',
        'has_unsaved_changes': 0,
        'status': 'completed',
        'created_at':
            DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        'updated_at':
            DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
      },
      {
        'tab_id': 1003,
        'empty_weight': 5200.0,
        'gross_weight': 30200.0,
        'net_weight': 25000.0,
        'truck_plate': 'GHI-789',
        'driver_name': 'Bob Wilson',
        'supplier_client': 'Test Client 2',
        'material': 'Concrete',
        'is_paid': 1,
        'show_price_on_print': 1,
        'operation_type': 'loading',
        'has_unsaved_changes': 0,
        'status': 'completed',
        'created_at':
            DateTime.now().subtract(Duration(hours: 5)).toIso8601String(),
        'updated_at':
            DateTime.now().subtract(Duration(hours: 5)).toIso8601String(),
      }
    ];

    for (final tab in testTabs) {
      try {
        await db.insert('weighing_tabs', tab,
            conflictAlgorithm: ConflictAlgorithm.replace);
        printd('Added test tab: ${tab['tab_id']} - ${tab['truck_plate']}');
      } catch (e) {
        printd('Error adding tab ${tab['tab_id']}: $e');
      }
    }

    // Verify the data was added
    final completedTabs = await db.query(
      'weighing_tabs',
      where: 'status = ?',
      whereArgs: ['completed'],
    );

    printd('\nCompleted tabs in database: ${completedTabs.length}');
    for (final tab in completedTabs) {
      print(
          '  Tab ${tab['tab_id']}: ${tab['truck_plate']} - ${tab['driver_name']} - ${tab['status']}');
    }

    await db.close();
    printd('\nTest data added successfully!');
  } catch (e) {
    printd('Error: $e');
  }
}
