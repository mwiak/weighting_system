import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/driver.dart';
import '../models/driver_plate.dart';

/// Driver Plate Provider
/// 
/// Manages the state and operations for driver-plate relationships in the weighing system.
/// Handles the many-to-many relationship between drivers and plate numbers.
class DriverPlateProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<DriverPlate> _driverPlates = [];
  List<Driver> _driversWithPlates = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<DriverPlate> get driverPlates => _driverPlates;
  List<Driver> get driversWithPlates => _driversWithPlates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads all driver-plate relationships from the database
  Future<void> loadDriverPlates() async {
    _setLoading(true);
    _clearError();

    try {
      final driverPlateData = await _db.query(
        'driver_plates',
        where: 'active = 1',
        orderBy: 'driver_id, plate_number',
      );
      
      _driverPlates = driverPlateData.map((map) => DriverPlate.fromMap(map)).toList();

      // Load drivers with their plate numbers
      await _loadDriversWithPlates();
      
      debugPrint('DriverPlateProvider: Loaded ${_driverPlates.length} driver-plate relationships');
    } catch (e) {
      _setError('Failed to load driver plates: $e');
      debugPrint('DriverPlateProvider: Error loading driver plates: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Loads drivers along with their associated plate numbers
  Future<void> _loadDriversWithPlates() async {
    try {
      final driversData = await _db.query(
        'drivers',
        where: 'active = 1',
        orderBy: 'name ASC',
      );

      _driversWithPlates = [];
      
      for (final driverMap in driversData) {
        final driverId = driverMap['id'] as int;
        final plateNumbers = _driverPlates
            .where((dp) => dp.driverId == driverId && dp.active)
            .map((dp) => dp.plateNumber)
            .toList();

        final driver = Driver.fromMap(driverMap, plateNumbers: plateNumbers);
        _driversWithPlates.add(driver);
      }
    } catch (e) {
      debugPrint('DriverPlateProvider: Error loading drivers with plates: $e');
    }
  }

  /// Adds a new driver with plate numbers
  Future<bool> addDriverWithPlates(String driverName, List<String> plateNumbers, {
    String? phone,
    String? mobile,
    String? city,
  }) async {
    _clearError();

    if (driverName.trim().isEmpty) {
      _setError('Driver name is required');
      return false;
    }

    if (plateNumbers.isEmpty) {
      _setError('At least one plate number is required');
      return false;
    }

    // Validate plate numbers
    for (final plate in plateNumbers) {
      if (plate.trim().isEmpty) {
        _setError('All plate numbers must be non-empty');
        return false;
      }
      
      // Check if plate is already assigned to another driver
      final existingDriverForPlate = await _getDriverByPlate(plate.trim());
      if (existingDriverForPlate != null) {
        _setError('Plate number $plate is already assigned to ${existingDriverForPlate.name}');
        return false;
      }
    }

    try {
      // Start transaction
      final database = await _db.database;
      await database.transaction((txn) async {
        // Insert driver
        final now = DateTime.now();
        final driver = Driver(
          name: driverName.trim(),
          phone: phone?.trim(),
          mobile: mobile?.trim(),
          city: city?.trim(),
          createDate: now,
          writeDate: now,
        );

        final driverId = await txn.insert('drivers', driver.toMap());

        // Insert driver-plate relationships
        for (final plate in plateNumbers) {
          final driverPlate = DriverPlate(
            driverId: driverId,
            plateNumber: plate.trim(),
            createDate: now,
            writeDate: now,
          );
          await txn.insert('driver_plates', driverPlate.toMap());
        }
      });

      await loadDriverPlates();
      debugPrint('DriverPlateProvider: Added driver $driverName with ${plateNumbers.length} plates');
      return true;
    } catch (e) {
      _setError('Failed to add driver: $e');
      debugPrint('DriverPlateProvider: Error adding driver: $e');
      return false;
    }
  }

  /// Updates a driver and their plate numbers
  Future<bool> updateDriverWithPlates(int driverId, String driverName, List<String> plateNumbers, {
    String? phone,
    String? mobile,
    String? city,
  }) async {
    _clearError();

    if (driverName.trim().isEmpty) {
      _setError('Driver name is required');
      return false;
    }

    if (plateNumbers.isEmpty) {
      _setError('At least one plate number is required');
      return false;
    }

    // Validate plate numbers
    for (final plate in plateNumbers) {
      if (plate.trim().isEmpty) {
        _setError('All plate numbers must be non-empty');
        return false;
      }
      
      // Check if plate is already assigned to another driver
      final existingDriverForPlate = await _getDriverByPlate(plate.trim());
      if (existingDriverForPlate != null && existingDriverForPlate.id != driverId) {
        _setError('Plate number $plate is already assigned to ${existingDriverForPlate.name}');
        return false;
      }
    }

    try {
      // Start transaction
      final database = await _db.database;
      await database.transaction((txn) async {
        final now = DateTime.now();
        
        // Update driver
        await txn.update(
          'drivers',
          {
            'name': driverName.trim(),
            'phone': phone?.trim(),
            'mobile': mobile?.trim(),
            'city': city?.trim(),
            'write_date': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [driverId],
        );

        // Remove old plate relationships
        await txn.delete(
          'driver_plates',
          where: 'driver_id = ?',
          whereArgs: [driverId],
        );

        // Insert new plate relationships
        for (final plate in plateNumbers) {
          final driverPlate = DriverPlate(
            driverId: driverId,
            plateNumber: plate.trim(),
            createDate: now,
            writeDate: now,
          );
          await txn.insert('driver_plates', driverPlate.toMap());
        }
      });

      await loadDriverPlates();
      debugPrint('DriverPlateProvider: Updated driver $driverName with ${plateNumbers.length} plates');
      return true;
    } catch (e) {
      _setError('Failed to update driver: $e');
      debugPrint('DriverPlateProvider: Error updating driver: $e');
      return false;
    }
  }

  /// Deletes a driver and all their plate relationships
  Future<bool> deleteDriver(int driverId) async {
    _clearError();

    try {
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

      // Start transaction
      final database = await _db.database;
      await database.transaction((txn) async {
        // Delete plate relationships
        await txn.delete(
          'driver_plates',
          where: 'driver_id = ?',
          whereArgs: [driverId],
        );

        // Delete driver
        await txn.delete(
          'drivers',
          where: 'id = ?',
          whereArgs: [driverId],
        );
      });

      await loadDriverPlates();
      debugPrint('DriverPlateProvider: Deleted driver with ID $driverId');
      return true;
    } catch (e) {
      _setError('Failed to delete driver: $e');
      debugPrint('DriverPlateProvider: Error deleting driver: $e');
      return false;
    }
  }

  /// Gets a driver by plate number
  Future<Driver?> _getDriverByPlate(String plateNumber) async {
    try {
      final data = await _db.rawQuery('''
        SELECT d.* FROM drivers d
        INNER JOIN driver_plates dp ON d.id = dp.driver_id
        WHERE dp.plate_number = ? AND dp.active = 1 AND d.active = 1
        LIMIT 1
      ''', [plateNumber]);

      if (data.isNotEmpty) {
        final driverMap = data.first;
        final driverId = driverMap['id'] as int;
        final plateNumbers = await _getPlatesByDriver(driverId);
        return Driver.fromMap(driverMap, plateNumbers: plateNumbers);
      }
      return null;
    } catch (e) {
      debugPrint('DriverPlateProvider: Error getting driver by plate: $e');
      return null;
    }
  }

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
      debugPrint('DriverPlateProvider: Error getting plates by driver: $e');
      return [];
    }
  }

  /// Gets a driver by ID
  Driver? getDriverById(int driverId) {
    try {
      return _driversWithPlates.firstWhere((driver) => driver.id == driverId);
    } catch (e) {
      return null;
    }
  }

  /// Gets a driver by plate number (from loaded data)
  Driver? getDriverByPlateNumber(String plateNumber) {
    try {
      return _driversWithPlates.firstWhere(
        (driver) => driver.plateNumbers.contains(plateNumber)
      );
    } catch (e) {
      return null;
    }
  }

  /// Gets all unique plate numbers
  List<String> get allPlateNumbers {
    return _driverPlates
        .where((dp) => dp.active)
        .map((dp) => dp.plateNumber)
        .toSet()
        .toList()
        ..sort();
  }

  /// Gets active drivers only
  List<Driver> get activeDrivers => _driversWithPlates.where((d) => d.active).toList();

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

  /// Refreshes the driver plates list
  Future<void> refresh() async {
    await loadDriverPlates();
  }
}