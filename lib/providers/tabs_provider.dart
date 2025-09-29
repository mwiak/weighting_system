import 'package:flutter/foundation.dart';
import 'dart:async';
import '../database/database_helper.dart';
import '../models/weighing_tab.dart';
import '../models/driver.dart';
import '../models/client.dart';
import '../models/supplier.dart';
import '../models/material.dart';

class TabsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<WeighingTab> _tabs = [];
  int _currentTabIndex = -1;
  static const int maxTabs = 15;
  bool _isLoading = false;
  bool _isInitialized = false;
  Timer? _autoSaveTimer;
  Timer? _debounceTimer;

  // Getters
  List<WeighingTab> get tabs => List.unmodifiable(_tabs);
  int get currentTabIndex => _currentTabIndex;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  WeighingTab? get currentTab =>
      _currentTabIndex >= 0 && _currentTabIndex < _tabs.length
          ? _tabs[_currentTabIndex]
          : null;
  bool get hasActiveTabs => _tabs.isNotEmpty;
  int get tabCount => _tabs.length;

  /// Load only in-progress tabs from database on startup
  Future<void> loadTabs() async {
    _setLoading(true);
    try {
      // First, initialize the ID counter based on existing data
      await _initializeTabIdCounter();

      final data = await _db.query(
        'weighing_tabs',
        where: 'status = ?',
        whereArgs: ['in-progress'],
        orderBy: 'created_at ASC',
      );

      _tabs = data.map((map) => WeighingTab.fromMap(map)).toList();

      // Ensure current tab index is valid
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.isNotEmpty ? _tabs.length - 1 : -1;
      }

      debugPrint('TabsProvider: Loaded ${_tabs.length} in-progress tabs');
    } catch (e) {
      debugPrint('TabsProvider: Error loading tabs: $e');
      _tabs = [];
      _currentTabIndex = -1;
    } finally {
      _setLoading(false);
    }
  }

  /// Initialize the tab ID counter to prevent conflicts
  Future<void> _initializeTabIdCounter() async {
    try {
      // Get the highest tab_id from the database
      final result = await _db.query(
        'weighing_tabs',
        columns: ['MAX(tab_id) as max_id'],
      );

      int maxId = 0;
      if (result.isNotEmpty && result.first['max_id'] != null) {
        maxId = result.first['max_id'] as int;
      }

      // Set the next ID to be one more than the maximum
      WeighingTab.setNextId(maxId + 1);
      debugPrint('TabsProvider: Initialized tab ID counter to ${maxId + 1}');
    } catch (e) {
      debugPrint('TabsProvider: Error initializing ID counter: $e');
      // Fallback to default behavior
      WeighingTab.setNextId(1);
    }
  }

  /// Create a new tab
  Future<bool> createNewTab() async {
    if (_tabs.length >= maxTabs) {
      return false;
    }

    final tab = WeighingTab();

    // Don't save to database immediately - wait until user enters data
    _tabs.add(tab);
    _currentTabIndex = _tabs.length - 1;

    notifyListeners();
    debugPrint('TabsProvider: Created new tab ${tab.id}');
    return true;
  }

  /// Check if a new tab can be created
  bool canCreateNewTab() {
    return _tabs.length < maxTabs;
  }

  /// Switch to a specific tab
  void switchToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  /// Close a tab with validation
  Future<bool> closeTab(int index) async {
    if (index < 0 || index >= _tabs.length) return false;

    final tab = _tabs[index];

    // If tab has no data, close without warning
    if (!tab.hasData) {
      return await _forceCloseTab(index);
    }

    // If tab has data but user hasn't been warned, return false to show warning
    return false;
  }

  /// Force close a tab (after user confirmation)
  Future<bool> forceCloseTab(int index) async {
    return await _forceCloseTab(index);
  }

  /// Internal method to actually close the tab
  Future<bool> _forceCloseTab(int index) async {
    if (index < 0 || index >= _tabs.length) return false;

    final tab = _tabs[index];

    try {
      if (tab.dbId != null) {
        // Set status to cancelled and save to database
        tab.cancelTab();
        await _saveTabToDatabase(tab);
      }

      // Remove from active tabs
      _tabs.removeAt(index);

      // Adjust current tab index
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.isNotEmpty ? _tabs.length - 1 : -1;
      } else if (index <= _currentTabIndex && _currentTabIndex > 0) {
        _currentTabIndex--;
      }

      notifyListeners();
      debugPrint('TabsProvider: Closed tab at index $index');
      return true;
    } catch (e) {
      debugPrint('TabsProvider: Error closing tab: $e');
      return false;
    }
  }

  /// Update a tab's data with debouncing (300ms delay)
  void updateTabDebounced(int index, Map<String, dynamic> updates) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      updateTab(index, updates);
    });
  }

  /// Update a tab's data and save to database
  Future<void> updateTab(int index, Map<String, dynamic> updates) async {
    if (index < 0 || index >= _tabs.length) return;

    final tab = _tabs[index];
    bool hasChanges = false;

    // Update the tab fields
    if (updates.containsKey('emptyWeight')) {
      final value = (updates['emptyWeight'] as int?) ?? 0;
      if (tab.emptyWeight != value) {
        tab.emptyWeight = value;
        hasChanges = true;
      }
    }

    if (updates.containsKey('scaleEmptyWeight')) {
      final value =
          (updates['scaleEmptyWeight'] as DateTime?) ?? DateTime.now();

      tab.scaleEmptyWeightAt = value;
      hasChanges = true;
    }

    if (updates.containsKey('grossWeight')) {
      final value = (updates['grossWeight'] as int?) ?? 0;
      if (tab.grossWeight != value) {
        tab.grossWeight = value;
        hasChanges = true;
      }
    }

    if (updates.containsKey('scaleGrossWeight')) {
      final value =
          (updates['scaleGrossWeight'] as DateTime?) ?? DateTime.now();

      tab.scaleGrossWeightAt = value;
      hasChanges = true;
    }

    if (updates.containsKey('truckPlate')) {
      final value = updates['truckPlate'] as String? ?? '';
      if (tab.truckPlate != value) {
        tab.truckPlate = value;
        hasChanges = true;
      }
    }

    if (updates.containsKey('driverName')) {
      final value = updates['driverName'] as String? ?? '';
      if (tab.driverName != value) {
        tab.driverName = value;
        hasChanges = true;
      }
    }

    if (updates.containsKey('supplier')) {
      final value = updates['supplier'] as String? ?? '';
      if (tab.supplier != value) {
        tab.supplier = value;
        // Clear client when supplier is set (mutual exclusivity)
        if (value.isNotEmpty && tab.client.isNotEmpty) {
          tab.client = '';
        }
        hasChanges = true;
      }
    }

    if (updates.containsKey('client')) {
      final value = updates['client'] as String? ?? '';
      if (tab.client != value) {
        tab.client = value;
        // Clear supplier when client is set (mutual exclusivity)
        if (value.isNotEmpty && tab.supplier.isNotEmpty) {
          tab.supplier = '';
        }
        hasChanges = true;
      }
    }

    if (updates.containsKey('material')) {
      final value = updates['material'] as String? ?? '';
      if (tab.material != value) {
        tab.material = value;
        hasChanges = true;
      }
    }

    if (updates.containsKey('kilo_price')) {
      final value = updates['kilo_price'] as num? ?? 0.0;
      if (tab.kilo_price != value) {
        tab.kilo_price = value;
        hasChanges = true;
      }
    }

    if (updates.containsKey('total_price')) {
      final value = updates['total_price'] as num? ?? 0.0;
      if (tab.total_price != value) {
        tab.total_price = value;
        hasChanges = true;
      }
    }

    if (updates.containsKey('isPaid')) {
      final value = updates['isPaid'] as bool? ?? false;
      if (tab.isPaid != value) {
        tab.isPaid = value;
        hasChanges = true;
      }
    }

    if (updates.containsKey('showPriceOnPrint')) {
      final value = updates['showPriceOnPrint'] as bool? ?? true;
      if (tab.showPriceOnPrint != value) {
        tab.showPriceOnPrint = value;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      tab.markAsChanged();
      tab.updateStatus(); // Update complete/incomplete status
      try {
        await _saveTabToDatabase(tab);
      } catch (e) {
        debugPrint('TabsProvider: Failed to save tab changes: $e');
        // Revert the changes if database save fails
        tab.hasUnsavedChanges = true;
      }
      notifyListeners();
    }
  }

  /// Get tab data for a specific index
  Map<String, dynamic>? getTabData(int index) {
    if (index < 0 || index >= _tabs.length) return null;
    return _tabs[index].toMap();
  }

  /// Save tab to database
  /// Save a tab to the database (public method)
  Future<void> saveTab(WeighingTab tab) async {
    await _saveTabToDatabase(tab);
    notifyListeners();
  }

  Future<void> _saveTabToDatabase(WeighingTab tab) async {
    try {
      if (tab.dbId == null) {
        // First time saving - insert into database
        final tabData = tab.toMap();
        tabData.remove('id'); // Remove id field for insert

        try {
          final dbId = await _db.insert('weighing_tabs', tabData);
          tab.dbId = dbId;
          debugPrint('TabsProvider: Inserted new tab ${tab.id} to database with ID $dbId');
        } catch (insertError) {
          // Handle unique constraint violation on tab_id
          if (insertError.toString().contains('UNIQUE constraint failed')) {
            debugPrint('TabsProvider: Tab ID ${tab.id} conflict, reinitializing counter');

            // Reinitialize the ID counter and retry with new ID
            await _initializeTabIdCounter();

            // Create a new tab with the updated ID counter
            final newTab = WeighingTab();

            // Copy all data to the new tab
            newTab.emptyWeight = tab.emptyWeight;
            newTab.grossWeight = tab.grossWeight;
            newTab.scaleEmptyWeightAt = tab.scaleEmptyWeightAt;
            newTab.scaleGrossWeightAt = tab.scaleGrossWeightAt;
            newTab.truckPlate = tab.truckPlate;
            newTab.driverName = tab.driverName;
            newTab.supplier = tab.supplier;
            newTab.client = tab.client;
            newTab.material = tab.material;
            newTab.kilo_price = tab.kilo_price;
            newTab.total_price = tab.total_price;
            newTab.isPaid = tab.isPaid;
            newTab.showPriceOnPrint = tab.showPriceOnPrint;
            newTab.status = tab.status;
            newTab.createdAt = tab.createdAt;
            newTab.updatedAt = tab.updatedAt;

            // Update the reference and retry save
            final index = _tabs.indexOf(tab);
            if (index >= 0) {
              _tabs[index] = newTab;
            }

            // Retry saving with new ID
            final newTabData = newTab.toMap();
            newTabData.remove('id');
            final dbId = await _db.insert('weighing_tabs', newTabData);
            newTab.dbId = dbId;

            debugPrint('TabsProvider: Resolved ID conflict, saved tab with new ID ${newTab.id}');
            return; // Success, exit the method
          }
          rethrow;
        }
      } else {
        // Update existing record
        final tabData = tab.toMap();
        tabData.remove('id'); // Remove id field for update to avoid conflicts
        await _db.update(
          'weighing_tabs',
          tabData,
          where: 'id = ?',
          whereArgs: [tab.dbId],
        );
        debugPrint('TabsProvider: Updated tab ${tab.id} in database');
      }

      tab.markAsSaved();
    } catch (e) {
      debugPrint('TabsProvider: Error saving tab: $e');
      rethrow; // Re-throw to let caller handle the error
    }
  }

  /// Auto-save all modified tabs
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _autoSaveAllTabs();
    });
  }

  /// Auto-save all tabs with unsaved changes
  Future<void> _autoSaveAllTabs() async {
    for (final tab in _tabs) {
      if (tab.hasUnsavedChanges) {
        await _saveTabToDatabase(tab);
      }
    }
  }

  /// Complete a tab and move it to history
  Future<bool> completeTab(int index) async {
    if (index < 0 || index >= _tabs.length) return false;

    final tab = _tabs[index];

    // Check if tab can be completed
    if (!tab.isComplete) {
      debugPrint('TabsProvider: Cannot complete tab - missing required fields');
      return false;
    }

    try {
      // First, save any new values to their respective tables
      await _saveNewValuesToTables(tab);

      // Mark as completed
      tab.completeTab();

      // Save to database
      await _saveTabToDatabase(tab);

      // Remove from active tabs
      _tabs.removeAt(index);

      // Adjust current tab index
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.isNotEmpty ? _tabs.length - 1 : -1;
      } else if (index <= _currentTabIndex && _currentTabIndex > 0) {
        _currentTabIndex--;
      }

      notifyListeners();
      debugPrint('TabsProvider: Completed tab at index $index');
      return true;
    } catch (e) {
      debugPrint('TabsProvider: Error completing tab: $e');
      return false;
    }
  }

  /// Save new values to their respective tables
  Future<void> _saveNewValuesToTables(WeighingTab tab) async {
    try {
      // Save driver if new
      if (tab.driverName.isNotEmpty) {
        await _saveDriverIfNew(tab.driverName);
      }

      // Save truck plate if new (and associate with driver if both provided)
      if (tab.truckPlate.isNotEmpty) {
        await _saveTruckIfNew(
            tab.truckPlate, tab.driverName.isNotEmpty ? tab.driverName : null);
      }

      // Save client/supplier if new
      if (tab.supplier.isNotEmpty) {
        // Determine if it's a client or supplier based on operation type
        await _saveSupplierIfNew(tab.supplier);
      }

      if (tab.client.isNotEmpty) {
        // Determine if it's a client or supplier based on operation type

        await _saveClientIfNew(tab.client);
      }

      // Save material if new
      if (tab.material.isNotEmpty) {
        await _saveMaterialIfNew(tab.material);
      }

      debugPrint('TabsProvider: Saved new values to respective tables');
    } catch (e) {
      debugPrint('TabsProvider: Error saving new values to tables: $e');
    }
  }

  /// Save driver if it doesn't exist
  Future<void> _saveDriverIfNew(String driverName) async {
    final existing = await _db.query(
      'drivers',
      where: 'name = ?',
      whereArgs: [driverName],
      limit: 1,
    );

    if (existing.isEmpty) {
      final driver = Driver(
        name: driverName,
        createDate: DateTime.now(),
        writeDate: DateTime.now(),
      );
      await _db.insert('drivers', driver.toMap());
      debugPrint('TabsProvider: Added new driver: $driverName');
    }
  }

  /// Save truck plate with driver if both provided
  Future<void> _saveTruckIfNew(String truckPlate, String? driverName) async {
    // If driver name is provided, link them in driver_plates table
    if (driverName != null && driverName.isNotEmpty) {
      await _linkDriverWithTruck(driverName, truckPlate);
    }
    debugPrint('TabsProvider: Processed truck plate: $truckPlate');
  }

  /// Link driver with truck in driver_plates table
  Future<void> _linkDriverWithTruck(
      String driverName, String truckPlate) async {
    try {
      // Get driver ID
      final drivers = await _db.query(
        'drivers',
        where: 'name = ?',
        whereArgs: [driverName],
        limit: 1,
      );

      if (drivers.isNotEmpty) {
        final driverId = drivers.first['id'] as int;

        // Check if link already exists
        final existing = await _db.query(
          'driver_plates',
          where: 'driver_id = ? AND plate_number = ?',
          whereArgs: [driverId, truckPlate],
          limit: 1,
        );

        if (existing.isEmpty) {
          await _db.insert('driver_plates', {
            'driver_id': driverId,
            'plate_number': truckPlate,
            'create_date': DateTime.now().toIso8601String(),
            'write_date': DateTime.now().toIso8601String(),
            'active': 1,
          });
          debugPrint(
              'TabsProvider: Linked driver $driverName with truck $truckPlate');
        }
      }
    } catch (e) {
      debugPrint('TabsProvider: Error linking driver with truck: $e');
    }
  }

  /// Save client if it doesn't exist
  Future<void> _saveClientIfNew(String clientName) async {
    final existing = await _db.query(
      'clients',
      where: 'name = ?',
      whereArgs: [clientName],
      limit: 1,
    );

    if (existing.isEmpty) {
      final client = Client(
        name: clientName,
      );
      await _db.insert('clients', client.toDatabase());
      debugPrint('TabsProvider: Added new client: $clientName');
    }
  }

  /// Save supplier if it doesn't exist
  Future<void> _saveSupplierIfNew(String supplierName) async {
    final existing = await _db.query(
      'suppliers',
      where: 'name = ?',
      whereArgs: [supplierName],
      limit: 1,
    );

    if (existing.isEmpty) {
      final supplier = Supplier(
        name: supplierName,
      );
      await _db.insert('suppliers', supplier.toDatabase());
      debugPrint('TabsProvider: Added new supplier: $supplierName');
    }
  }

  /// Save material if it doesn't exist
  Future<void> _saveMaterialIfNew(String materialName) async {
    final existing = await _db.query(
      'materials',
      where: 'name = ?',
      whereArgs: [materialName],
      limit: 1,
    );

    if (existing.isEmpty) {
      final material = Material(
        name: materialName,
        active: true,
        createDate: DateTime.now(),
        writeDate: DateTime.now(),
      );
      await _db.insert('materials', material.toDatabase());
      debugPrint('TabsProvider: Added new material: $materialName');
    }
  }

  /// Cancel a tab and move it to history
  Future<bool> cancelTab(int index) async {
    if (index < 0 || index >= _tabs.length) return false;

    final tab = _tabs[index];

    try {
      // Mark as cancelled
      tab.cancelTab();

      // Save to database
      await _saveTabToDatabase(tab);

      // Remove from active tabs
      _tabs.removeAt(index);

      // Adjust current tab index
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.isNotEmpty ? _tabs.length - 1 : -1;
      } else if (index <= _currentTabIndex && _currentTabIndex > 0) {
        _currentTabIndex--;
      }

      notifyListeners();
      debugPrint('TabsProvider: Cancelled tab at index $index');
      return true;
    } catch (e) {
      debugPrint('TabsProvider: Error cancelling tab: $e');
      return false;
    }
  }

  /// Get tabs history (closed tabs)
  Future<List<WeighingTab>> getTabsHistory({
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String whereClause = "status IN ('completed', 'cancelled')";
      List<dynamic> whereArgs = [];

      if (statusFilter != null && statusFilter != 'all') {
        whereClause += ' AND status = ?';
        whereArgs.add(statusFilter);
      }

      if (startDate != null) {
        whereClause += ' AND created_at >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND created_at <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final data = await _db.query(
        'weighing_tabs',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );

      return data.map((map) => WeighingTab.fromMap(map)).toList();
    } catch (e) {
      debugPrint('TabsProvider: Error getting tabs history: $e');
      return [];
    }
  }

  /// Initialize provider (only once)
  Future<void> initialize() async {
    if (_isInitialized) {
      // Already initialized, just restart auto-save if needed
      _startAutoSave();
      return;
    }

    await loadTabs();
    _startAutoSave();
    _isInitialized = true;
    debugPrint('TabsProvider: Initialized with ${_tabs.length} tabs');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _debounceTimer?.cancel();
    // Just save the tabs, don't close them when navigating away
    _autoSaveAllTabs();
    _isInitialized = false; // Allow re-initialization if needed
    super.dispose();
  }
}
