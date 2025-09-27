import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/driver.dart';

/// Driver Provider
/// 
/// Manages the state and operations for drivers in the weighing system.
/// Provides CRUD operations, search functionality, and data validation.
class DriverProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Driver> _drivers = [];
  List<Driver> _filteredDrivers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<Driver> get drivers => _filteredDrivers;
  List<Driver> get allDrivers => _drivers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  /// Loads all drivers from the database
  Future<void> loadDrivers() async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _db.query(
        'drivers',
        orderBy: 'name ASC',
      );
      
      // Load drivers with their plate numbers
      _drivers = [];
      for (final driverMap in data) {
        final driverId = driverMap['id'] as int;
        final plateNumbers = await _getPlatesByDriver(driverId);
        final driver = Driver.fromMap(driverMap, plateNumbers: plateNumbers);
        _drivers.add(driver);
      }
      _applyFilters();
      
      debugPrint('DriverProvider: Loaded ${_drivers.length} drivers');
    } catch (e) {
      _setError('Failed to load drivers: $e');
      debugPrint('DriverProvider: Error loading drivers: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Adds a new driver to the database
  Future<bool> addDriver(Driver driver) async {
    _clearError();

    try {
      // Validate driver data
      final validation = _validateDriver(driver);
      if (!validation.isValid) {
        _setError(validation.error!);
        return false;
      }

      // Check for plate number requirement
      if (driver.plateNumbers.isEmpty) {
        _setError('Driver must have at least one plate number');
        return false;
      }

      final now = DateTime.now();
      final driverToInsert = driver.copyWith(
        createDate: now,
        writeDate: now,
      );

      final id = await _db.insert('drivers', driverToInsert.toMap());
      
      if (id > 0) {
        final newDriver = driverToInsert.copyWith(id: id);
        _drivers.add(newDriver);
        _applyFilters();
        
        debugPrint('DriverProvider: Added driver ${newDriver.name} with ID $id');
        return true;
      } else {
        _setError('Failed to add driver to database');
        return false;
      }
    } catch (e) {
      _setError('Failed to add driver: $e');
      debugPrint('DriverProvider: Error adding driver: $e');
      return false;
    }
  }

  /// Updates an existing driver
  Future<bool> updateDriver(Driver driver) async {
    if (driver.id == null) {
      _setError('Cannot update driver without ID');
      return false;
    }

    _clearError();

    try {
      // Validate driver data
      final validation = _validateDriver(driver);
      if (!validation.isValid) {
        _setError(validation.error!);
        return false;
      }

      // Check for plate number requirement
      if (driver.plateNumbers.isEmpty) {
        _setError('Driver must have at least one plate number');
        return false;
      }

      final updatedDriver = driver.copyWith(writeDate: DateTime.now());
      final updateCount = await _db.update(
        'drivers',
        updatedDriver.toMap(),
        where: 'id = ?',
        whereArgs: [driver.id],
      );

      if (updateCount > 0) {
        final index = _drivers.indexWhere((d) => d.id == driver.id);
        if (index >= 0) {
          _drivers[index] = updatedDriver;
          _applyFilters();
        }
        
        debugPrint('DriverProvider: Updated driver ${updatedDriver.name}');
        return true;
      } else {
        _setError('Driver not found or no changes made');
        return false;
      }
    } catch (e) {
      _setError('Failed to update driver: $e');
      debugPrint('DriverProvider: Error updating driver: $e');
      return false;
    }
  }

  /// Deletes a driver from the database
  Future<bool> deleteDriver(int driverId) async {
    _clearError();

    try {
      // Check if driver has any plate relationships
      final plateRelationships = await _db.query(
        'driver_plates',
        where: 'driver_id = ? AND active = ?',
        whereArgs: [driverId, 1],
      );

      if (plateRelationships.isNotEmpty) {
        _setError('Cannot delete driver: has ${plateRelationships.length} active plate(s)');
        return false;
      }

      // Check if driver has any orders
      final orders = await _db.query(
        'orders',
        where: 'truck_plate IN (SELECT plate_number FROM driver_plates WHERE driver_id = ?)',
        whereArgs: [driverId],
        limit: 1,
      );

      if (orders.isNotEmpty) {
        _setError('Cannot delete driver: has historical weighing operations');
        return false;
      }

      final deleteCount = await _db.delete(
        'drivers',
        where: 'id = ?',
        whereArgs: [driverId],
      );

      if (deleteCount > 0) {
        _drivers.removeWhere((d) => d.id == driverId);
        _applyFilters();
        
        debugPrint('DriverProvider: Deleted driver with ID $driverId');
        return true;
      } else {
        _setError('Driver not found');
        return false;
      }
    } catch (e) {
      _setError('Failed to delete driver: $e');
      debugPrint('DriverProvider: Error deleting driver: $e');
      return false;
    }
  }

  /// Searches drivers by name or plate numbers
  void searchDrivers(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    debugPrint('DriverProvider: Search query updated: "$_searchQuery"');
  }

  /// Clears the search filter
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  /// Gets a driver by ID
  Driver? getDriverById(int id) {
    try {
      return _drivers.firstWhere((driver) => driver.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Gets active drivers only
  List<Driver> get activeDrivers => _drivers.where((d) => d.active).toList();

  /// Gets all plate numbers for a driver
  Future<List<String>> _getPlatesByDriver(int driverId) async {
    try {
      final data = await _db.query(
        'driver_plates',
        columns: ['plate_number'],
        where: 'driver_id = ? AND active = 1',
        whereArgs: [driverId],
      );

      return data.map((map) => map['plate_number'] as String).toList();
    } catch (e) {
      debugPrint('DriverProvider: Error getting plates by driver: $e');
      return [];
    }
  }

  /// Applies search and other filters to the drivers list
  void _applyFilters() {
    _filteredDrivers = _drivers.where((driver) {
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      return driver.name.toLowerCase().contains(query) ||
             driver.plateNumbers.any((plate) => plate.toLowerCase().contains(query)) ||
             (driver.city?.toLowerCase().contains(query) ?? false);
    }).toList();
    
    notifyListeners();
  }

  /// Validates driver data
  ValidationResult _validateDriver(Driver driver) {
    if (driver.name.trim().isEmpty) {
      return ValidationResult.invalid('Driver name is required');
    }

    if (driver.name.trim().length < 2) {
      return ValidationResult.invalid('Driver name must be at least 2 characters');
    }

    if (driver.plateNumbers.isEmpty) {
      return ValidationResult.invalid('Driver must have at least one plate number');
    }

    for (final plate in driver.plateNumbers) {
      if (plate.trim().isEmpty) {
        return ValidationResult.invalid('All plate numbers must be non-empty');
      }
      if (plate.trim().length < 3) {
        return ValidationResult.invalid('Plate numbers must be at least 3 characters');
      }
    }

    return ValidationResult.valid();
  }

  /// Sets loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clears error message
  void _clearError() {
    _error = null;
  }

  /// Refreshes the drivers list
  Future<void> refresh() async {
    await loadDrivers();
  }
}

/// Validation result helper class
class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult.valid() : isValid = true, error = null;
  const ValidationResult.invalid(this.error) : isValid = false;
}