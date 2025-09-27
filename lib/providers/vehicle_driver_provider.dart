import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/vehicle_driver_relationship.dart';

class VehicleDriverProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<VehicleDriverRelationship> _relationships = [];
  bool _isLoading = false;
  String? _lastError;

  List<VehicleDriverRelationship> get relationships => List.unmodifiable(_relationships);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  Future<void> loadRelationships() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'vehicle_driver_relationships',
        orderBy: 'usage_count DESC, created_at DESC',
      );

      _relationships = results
          .map((row) => VehicleDriverRelationship.fromMap(row))
          .toList();
    } catch (e) {
      _lastError = 'Failed to load vehicle-driver relationships: $e';
      debugPrint(_lastError);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VehicleDriverRelationship?> addOrUpdateRelationship({
    required String vehiclePlate,
    required String driverName,
    String? driverLicense,
  }) async {
    if (vehiclePlate.trim().isEmpty || driverName.trim().isEmpty) {
      _lastError = 'Vehicle plate and driver name are required';
      notifyListeners();
      return null;
    }

    try {
      final db = await _dbHelper.database;
      
      // Check if relationship already exists
      final existing = await db.query(
        'vehicle_driver_relationships',
        where: 'vehicle_plate = ? AND driver_name = ?',
        whereArgs: [vehiclePlate.trim(), driverName.trim()],
      );

      if (existing.isNotEmpty) {
        // Update usage count and license if provided
        final existingId = existing.first['id'] as int;
        await db.update(
          'vehicle_driver_relationships',
          {
            'usage_count': (existing.first['usage_count'] as int) + 1,
            if (driverLicense?.isNotEmpty == true) 'driver_license': driverLicense,
          },
          where: 'id = ?',
          whereArgs: [existingId],
        );

        // Reload relationships to get updated data
        await loadRelationships();
        
        return _relationships.firstWhere((r) => r.id == existingId);
      } else {
        // Create new relationship
        final relationship = VehicleDriverRelationship(
          vehiclePlate: vehiclePlate.trim(),
          driverName: driverName.trim(),
          driverLicense: driverLicense?.trim(),
          createdAt: DateTime.now(),
        );

        final id = await db.insert('vehicle_driver_relationships', relationship.toMap());
        final newRelationship = relationship.copyWith(id: id);
        
        _relationships.add(newRelationship);
        _sortRelationships();
        notifyListeners();

        return newRelationship;
      }
    } catch (e) {
      _lastError = 'Failed to add/update relationship: $e';
      debugPrint(_lastError);
      notifyListeners();
      return null;
    }
  }

  List<String> getRelatedDrivers(String vehiclePlate) {
    if (vehiclePlate.trim().isEmpty) return [];
    
    return _relationships
        .where((r) => r.vehiclePlate.toLowerCase() == vehiclePlate.toLowerCase().trim())
        .map((r) => r.driverName)
        .toList();
  }

  List<String> getRelatedVehicles(String driverName) {
    if (driverName.trim().isEmpty) return [];
    
    return _relationships
        .where((r) => r.driverName.toLowerCase() == driverName.toLowerCase().trim())
        .map((r) => r.vehiclePlate)
        .toList();
  }

  List<String> getAllVehiclePlates() {
    final plates = <String>{};
    for (final relationship in _relationships) {
      plates.add(relationship.vehiclePlate);
    }
    return plates.toList()..sort();
  }

  List<String> getAllDriverNames() {
    final names = <String>{};
    for (final relationship in _relationships) {
      names.add(relationship.driverName);
    }
    return names.toList()..sort();
  }

  String? getDriverLicense(String driverName) {
    final relationship = _relationships.firstWhere(
      (r) => r.driverName.toLowerCase() == driverName.toLowerCase().trim(),
      orElse: () => VehicleDriverRelationship(
        vehiclePlate: '',
        driverName: '',
        createdAt: DateTime.now(),
      ),
    );
    
    return relationship.driverLicense;
  }

  Future<bool> deleteRelationship(int id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.delete(
        'vehicle_driver_relationships',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result > 0) {
        _relationships.removeWhere((r) => r.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _lastError = 'Failed to delete relationship: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  void _sortRelationships() {
    _relationships.sort((a, b) {
      // Sort by usage count (descending), then by creation date (descending)
      final usageCompare = b.usageCount.compareTo(a.usageCount);
      if (usageCompare != 0) return usageCompare;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}