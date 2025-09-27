import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/truck.dart';

/// Truck Provider
/// 
/// Manages the state and operations for trucks in the weighing system.
/// Provides CRUD operations, search functionality, and driver assignment.
class TruckProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Truck> _trucks = [];
  List<Truck> _filteredTrucks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<Truck> get trucks => _filteredTrucks;
  List<Truck> get allTrucks => _trucks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  /// Loads all trucks from the database
  Future<void> loadTrucks() async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _db.query(
        'trucks',
        orderBy: 'plate_number ASC',
      );
      
      _trucks = data.map((map) => Truck.fromMap(map)).toList();
      _applyFilters();
      
      debugPrint('TruckProvider: Loaded ${_trucks.length} trucks');
    } catch (e) {
      _setError('Failed to load trucks: $e');
      debugPrint('TruckProvider: Error loading trucks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Adds a new truck to the database
  Future<bool> addTruck(Truck truck) async {
    _clearError();

    try {
      // Validate truck data
      final validation = _validateTruck(truck);
      if (!validation.isValid) {
        _setError(validation.error!);
        return false;
      }

      // Check for duplicate plate number
      final existing = await _findTruckByPlate(truck.plateNumber);
      if (existing != null) {
        _setError('A truck with plate number ${truck.plateNumber} already exists');
        return false;
      }

      // Validate driver assignment
      if (truck.driverId != null) {
        final driverExists = await _checkDriverExists(truck.driverId!);
        if (!driverExists) {
          _setError('Selected driver does not exist');
          return false;
        }
      }

      final now = DateTime.now();
      final truckToInsert = truck.copyWith(
        createDate: now,
        writeDate: now,
      );

      final id = await _db.insert('trucks', truckToInsert.toMap());
      
      if (id > 0) {
        final newTruck = truckToInsert.copyWith(id: id);
        _trucks.add(newTruck);
        _applyFilters();
        
        debugPrint('TruckProvider: Added truck ${newTruck.plateNumber} with ID $id');
        return true;
      } else {
        _setError('Failed to add truck to database');
        return false;
      }
    } catch (e) {
      _setError('Failed to add truck: $e');
      debugPrint('TruckProvider: Error adding truck: $e');
      return false;
    }
  }

  /// Updates an existing truck
  Future<bool> updateTruck(Truck truck) async {
    if (truck.id == null) {
      _setError('Cannot update truck without ID');
      return false;
    }

    _clearError();

    try {
      // Validate truck data
      final validation = _validateTruck(truck);
      if (!validation.isValid) {
        _setError(validation.error!);
        return false;
      }

      // Check for duplicate plate number (excluding current truck)
      final existing = await _findTruckByPlate(truck.plateNumber);
      if (existing != null && existing.id != truck.id) {
        _setError('A truck with plate number ${truck.plateNumber} already exists');
        return false;
      }

      // Validate driver assignment
      if (truck.driverId != null) {
        final driverExists = await _checkDriverExists(truck.driverId!);
        if (!driverExists) {
          _setError('Selected driver does not exist');
          return false;
        }
      }

      final updatedTruck = truck.copyWith(writeDate: DateTime.now());
      final updateCount = await _db.update(
        'trucks',
        updatedTruck.toMap(),
        where: 'id = ?',
        whereArgs: [truck.id],
      );

      if (updateCount > 0) {
        final index = _trucks.indexWhere((t) => t.id == truck.id);
        if (index >= 0) {
          _trucks[index] = updatedTruck;
          _applyFilters();
        }
        
        debugPrint('TruckProvider: Updated truck ${updatedTruck.plateNumber}');
        return true;
      } else {
        _setError('Truck not found or no changes made');
        return false;
      }
    } catch (e) {
      _setError('Failed to update truck: $e');
      debugPrint('TruckProvider: Error updating truck: $e');
      return false;
    }
  }

  /// Deletes a truck from the database
  Future<bool> deleteTruck(int truckId) async {
    _clearError();

    try {
      // Check if truck has any orders
      final orders = await _db.query(
        'orders',
        where: 'truck_plate = (SELECT plate_number FROM trucks WHERE id = ?)',
        whereArgs: [truckId],
        limit: 1,
      );

      if (orders.isNotEmpty) {
        _setError('Cannot delete truck: has historical weighing operations');
        return false;
      }

      final deleteCount = await _db.delete(
        'trucks',
        where: 'id = ?',
        whereArgs: [truckId],
      );

      if (deleteCount > 0) {
        _trucks.removeWhere((t) => t.id == truckId);
        _applyFilters();
        
        debugPrint('TruckProvider: Deleted truck with ID $truckId');
        return true;
      } else {
        _setError('Truck not found');
        return false;
      }
    } catch (e) {
      _setError('Failed to delete truck: $e');
      debugPrint('TruckProvider: Error deleting truck: $e');
      return false;
    }
  }

  /// Assigns a driver to a truck
  Future<bool> assignDriver(int truckId, int? driverId) async {
    _clearError();

    try {
      if (driverId != null) {
        final driverExists = await _checkDriverExists(driverId);
        if (!driverExists) {
          _setError('Selected driver does not exist');
          return false;
        }
      }

      final updateCount = await _db.update(
        'trucks',
        {
          'driver_id': driverId,
          'write_date': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [truckId],
      );

      if (updateCount > 0) {
        final index = _trucks.indexWhere((t) => t.id == truckId);
        if (index >= 0) {
          _trucks[index] = _trucks[index].copyWith(
            driverId: driverId,
            writeDate: DateTime.now(),
          );
          _applyFilters();
        }
        
        debugPrint('TruckProvider: Assigned driver $driverId to truck $truckId');
        return true;
      } else {
        _setError('Truck not found');
        return false;
      }
    } catch (e) {
      _setError('Failed to assign driver: $e');
      debugPrint('TruckProvider: Error assigning driver: $e');
      return false;
    }
  }

  /// Searches trucks by plate number or model
  void searchTrucks(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    debugPrint('TruckProvider: Search query updated: "$_searchQuery"');
  }

  /// Clears the search filter
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  /// Gets a truck by ID
  Truck? getTruckById(int id) {
    try {
      return _trucks.firstWhere((truck) => truck.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Gets a truck by plate number
  Truck? getTruckByPlate(String plateNumber) {
    try {
      return _trucks.firstWhere((truck) => truck.plateNumber == plateNumber);
    } catch (e) {
      return null;
    }
  }

  /// Gets active trucks only
  List<Truck> get activeTrucks => _trucks.where((t) => t.active).toList();

  /// Gets trucks without assigned drivers
  List<Truck> get trucksWithoutDrivers => _trucks.where((t) => t.driverId == null && t.active).toList();

  /// Gets driver name for a truck
  Future<String?> getDriverName(int? driverId) async {
    if (driverId == null) return null;

    try {
      final data = await _db.query(
        'drivers',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [driverId],
        limit: 1,
      );

      if (data.isNotEmpty) {
        return data.first['name'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Finds a truck by plate number
  Future<Truck?> _findTruckByPlate(String plateNumber) async {
    try {
      final data = await _db.query(
        'trucks',
        where: 'plate_number = ?',
        whereArgs: [plateNumber],
        limit: 1,
      );
      
      if (data.isNotEmpty) {
        return Truck.fromMap(data.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Checks if a driver exists
  Future<bool> _checkDriverExists(int driverId) async {
    try {
      final data = await _db.query(
        'drivers',
        where: 'id = ?',
        whereArgs: [driverId],
        limit: 1,
      );
      
      return data.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Applies search and other filters to the trucks list
  void _applyFilters() {
    _filteredTrucks = _trucks.where((truck) {
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      return truck.plateNumber.toLowerCase().contains(query) ||
             (truck.model?.toLowerCase().contains(query) ?? false);
    }).toList();
    
    notifyListeners();
  }

  /// Validates truck data
  ValidationResult _validateTruck(Truck truck) {
    if (truck.plateNumber.trim().isEmpty) {
      return ValidationResult.invalid('Plate number is required');
    }

    if (truck.plateNumber.trim().length < 3) {
      return ValidationResult.invalid('Plate number must be at least 3 characters');
    }

    if (truck.capacity != null && truck.capacity! < 0) {
      return ValidationResult.invalid('Capacity cannot be negative');
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

  /// Refreshes the trucks list
  Future<void> refresh() async {
    await loadTrucks();
  }
}

/// Validation result helper class
class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult.valid() : isValid = true, error = null;
  const ValidationResult.invalid(this.error) : isValid = false;
}