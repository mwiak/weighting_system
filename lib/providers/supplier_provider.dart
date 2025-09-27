import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/supplier.dart';

class SupplierProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _lastError;
  String _searchQuery = '';

  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  String get searchQuery => _searchQuery;

  List<Supplier> get filteredSuppliers {
    if (_searchQuery.isEmpty) return _suppliers;

    return _suppliers.where((supplier) {
      return supplier.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (supplier.phone?.contains(_searchQuery) ?? false) ||
             (supplier.city?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  Future<void> loadSuppliers() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      final results = await db.query('suppliers', orderBy: 'name');
      
      _suppliers = results.map((row) => Supplier.fromMap(row)).toList();
    } catch (e) {
      _lastError = 'Failed to load suppliers: $e';
      debugPrint(_lastError);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Supplier?> addSupplier(Supplier supplier) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert('suppliers', supplier.toMap());
      
      final newSupplier = supplier.copyWith(id: id);
      _suppliers.add(newSupplier);
      _sortSuppliers();
      notifyListeners();
      
      return newSupplier;
    } catch (e) {
      _lastError = 'Failed to add supplier: $e';
      debugPrint(_lastError);
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(
        'suppliers',
        supplier.toMap(),
        where: 'id = ?',
        whereArgs: [supplier.id],
      );

      if (result > 0) {
        final index = _suppliers.indexWhere((s) => s.id == supplier.id);
        if (index != -1) {
          _suppliers[index] = supplier;
          _sortSuppliers();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _lastError = 'Failed to update supplier: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);

      if (result > 0) {
        _suppliers.removeWhere((supplier) => supplier.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _lastError = 'Failed to delete supplier: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  Supplier? getSupplierById(int id) {
    try {
      return _suppliers.firstWhere((supplier) => supplier.id == id);
    } catch (e) {
      return null;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void _sortSuppliers() {
    _suppliers.sort((a, b) => a.name.compareTo(b.name));
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}