import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _db;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database?> get db async {
    if (_db == null) {
      _db = await intialDb();
      return _db;
    } else {
      return _db;
    }
  }

  intialDb() async {
    try {
      // Database in same folder as executable
      final databaseDir = Directory(join(Directory.current.path, 'database'));

      // Create database directory if it doesn't exist
      if (!await databaseDir.exists()) {
        debugPrint('Creating database directory: ${databaseDir.path}');
        await databaseDir.create(recursive: true);
      }

      String databasePath = join(databaseDir.path, 'database.db');

      debugPrint('Database path: $databasePath');
      debugPrint('Database exists: ${await File(databasePath).exists()}');

      Database mydb = await openDatabase(
        databasePath,
        onCreate: _onCreate,
        version: 1,
        onUpgrade: _onUpgrade,
      );

      await mydb.execute('PRAGMA foreign_keys = ON');
      debugPrint('Database initialized successfully');

      return mydb;
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<Database> get database async {
    final database = await db;
    return database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Running onCreate - Database version: $version');

    try {
      // Create clients table
      debugPrint('Creating clients table...');
      await db.execute('''
        CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        normalized_name TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        mobile TEXT,
        city TEXT,
        active INTEGER DEFAULT 1,
        create_date TEXT DEFAULT CURRENT_TIMESTAMP,
        write_date TEXT DEFAULT CURRENT_TIMESTAMP,
        odoo_id INTEGER,
        sync_status INTEGER DEFAULT 0
      )
    ''');

      // Create suppliers table
      await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        normalized_name TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        mobile TEXT,
        city TEXT,
        active INTEGER DEFAULT 1,
        create_date TEXT DEFAULT CURRENT_TIMESTAMP,
        write_date TEXT DEFAULT CURRENT_TIMESTAMP,
        odoo_id INTEGER,
        sync_status INTEGER DEFAULT 0
      )
    ''');

      // Create materials table
      await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        normalized_name TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL,
        description TEXT,
        active INTEGER DEFAULT 1,
        create_date TEXT DEFAULT CURRENT_TIMESTAMP,
        write_date TEXT DEFAULT CURRENT_TIMESTAMP,
        odoo_id INTEGER,
        sync_status INTEGER DEFAULT 0
      )
    ''');

      // Orders table removed - replaced by weighing_tabs table

      // Create sync queue table
      await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        operation TEXT NOT NULL,
        data TEXT,
        attempts INTEGER DEFAULT 0,
        max_attempts INTEGER DEFAULT 3,
        last_attempt TEXT,
        error_message TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

      // Create drivers table - now with plate numbers instead of license
      await db.execute('''
      CREATE TABLE drivers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        normalized_name TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        mobile TEXT,
        city TEXT,
        active INTEGER DEFAULT 1,
        create_date TEXT DEFAULT CURRENT_TIMESTAMP,
        write_date TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

      // Create driver_plates table - simple mapping of drivers to plate numbers
      await db.execute('''
      CREATE TABLE driver_plates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        driver_id INTEGER NOT NULL,
        plate_number TEXT NOT NULL,
        active INTEGER DEFAULT 1,
        create_date TEXT DEFAULT CURRENT_TIMESTAMP,
        write_date TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (driver_id) REFERENCES drivers (id),
        UNIQUE(driver_id, plate_number)
      )
    ''');

      // Create weighing_tabs table (new tab management system)
      await db.execute('''
      CREATE TABLE weighing_tabs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        empty_weight INTEGER DEFAULT 0,
        scale_empty_weight TEXT,
        gross_weight INTEGER DEFAULT 0,
        scale_gross_weight TEXT,
        net_weight INTEGER DEFAULT 0,
        truck_plate TEXT DEFAULT '',
        driver_name TEXT DEFAULT '',
        client TEXT DEFAULT '',
        supplier TEXT DEFAULT '',
        material TEXT DEFAULT '',
        kilo_price REAL,
        total_price REAL,
        notes TEXT DEFAULT '',
        is_paid INTEGER DEFAULT 0,
        show_price_on_print INTEGER DEFAULT 0,
        has_unsaved_changes INTEGER DEFAULT 0,
        status TEXT DEFAULT 'in-progress',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
      //auth - admin or normal
      await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT,
        type TEXT NOT NULL
      )
    ''');

      await db.execute('''
      CREATE TABLE prefs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setting TEXT NOT NULL UNIQUE,
        data TEXT
      )
    ''');

      // Create app_settings table
      await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setting_key TEXT NOT NULL UNIQUE,
        setting_value TEXT,
        setting_type TEXT DEFAULT 'string',
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

      // Insert default Odoo settings
      await db.execute('''
      INSERT INTO app_settings (setting_key, setting_value, setting_type, description) VALUES
      ('odoo_url', '', 'string', 'Odoo server URL'),
      ('odoo_database', '', 'string', 'Odoo database name'),
      ('odoo_username', '', 'string', 'Odoo username'),
      ('odoo_password', '', 'string', 'Odoo password'),
      ('print_schema_template', '', 'text', 'Custom print schema template'),
      ('company_name', '', 'string', 'Company name for documents'),
      ('auto_sync_enabled', '1', 'boolean', 'Enable automatic synchronization with Odoo')
    ''');

      await db.execute('''
      INSERT INTO users (username, password, type) VALUES
      ('Mohammed', '362646', 'admin'),
      ('Abo Hussien', '0', 'user')
    ''');
      await db.insert('prefs', {
        'setting': 'seasons',
        'data': json.encode({
          'dayOfInversion': DateTime(2025, 10, 5).toIso8601String(),
          'firstSeason': DateTime.now().toIso8601String()
        })
      });
      // Create indexes for better performance
      await db.execute('CREATE INDEX idx_clients_name ON clients (name)');
      await db.execute('CREATE INDEX idx_suppliers_name ON suppliers (name)');
      await db.execute('CREATE INDEX idx_materials_name ON materials (name)');
      // Orders indexes removed - replaced by weighing_tabs indexes
      await db.execute(
          'CREATE INDEX idx_sync_queue_table_record ON sync_queue (table_name, record_id)');
      await db.execute('CREATE INDEX idx_drivers_name ON drivers (name)');
      await db.execute(
          'CREATE INDEX idx_driver_plates_driver ON driver_plates (driver_id)');
      await db.execute(
          'CREATE INDEX idx_driver_plates_plate ON driver_plates (plate_number)');
      await db.execute(
          'CREATE INDEX idx_app_settings_key ON app_settings (setting_key)');
      await db.execute(
          'CREATE INDEX idx_weighing_tabs_truck ON weighing_tabs (truck_plate)');
      await db.execute(
          'CREATE INDEX idx_weighing_tabs_status ON weighing_tabs (status)');

      debugPrint('All tables and indexes created successfully');
    } catch (e, stackTrace) {
      debugPrint('ERROR in onCreate: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    // For weighing_tabs, use abort to prevent data corruption
    if (table == 'weighing_tabs') {
      return await db.insert(table, data,
          conflictAlgorithm: ConflictAlgorithm.abort);
    }
    if (table == 'prefs') {
      return await db.insert(table, data,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    return await db.insert(table, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;

    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawDelete(sql, arguments);
  }

  // Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Clear all data (for testing purposes)
  Future<void> clearAllData() async {
    final db = await database;
    // Orders table removed - replaced by weighing_tabs
    await db.delete('clients');
    await db.delete('suppliers');
    await db.delete('materials');
    await db.delete('drivers');
    await db.delete('driver_plates');
    await db.delete('sync_queue');
    await db.delete('weighing_tabs');
  }
}
