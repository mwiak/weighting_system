import 'package:flutter/foundation.dart';
import '../models/material.dart';
import '../database/database_helper.dart';
import '../utils/arabic_normalize.dart';

class MaterialProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Material> _materials = [];
  Material? _selectedMaterial;
  
  // Filter and search
  String _searchQuery = '';
  bool _showActiveOnly = true;
  
  // Loading states
  bool _isLoading = false;
  String? _lastError;
  
  // Getters
  List<Material> get materials => _materials;
  List<Material> get filteredMaterials => _applyFilters(_materials);
  Material? get selectedMaterial => _selectedMaterial;
  String get searchQuery => _searchQuery;
  bool get showActiveOnly => _showActiveOnly;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  
  // Statistics
  int get totalMaterials => _materials.length;
  int get activeMaterials => _materials.where((m) => m.active).length;

  MaterialProvider() {
    loadMaterials();
  }

  Future<void> loadMaterials() async {
    _setLoading(true);
    _clearError();
    
    try {
      final materialMaps = await _db.query(
        'materials',
        orderBy: 'name ASC',
      );
      
      _materials = materialMaps.map((map) => Material.fromDatabase(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load materials: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addMaterial(Material material) async {
    _clearError();
    
    try {
      final id = await _db.insert('materials', material.toDatabase());
      final createdMaterial = material.copyWith(id: id);
      
      _materials.add(createdMaterial);
      _materials.sort((a, b) => a.name.compareTo(b.name));
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create material: $e');
      return false;
    }
  }

  Future<bool> updateMaterial(Material material) async {
    _clearError();
    
    try {
      final updatedData = material.copyWith(
        writeDate: DateTime.now(),
      ).toDatabase();
      
      await _db.update(
        'materials',
        updatedData,
        where: 'id = ?',
        whereArgs: [material.id],
      );
      
      final index = _materials.indexWhere((m) => m.id == material.id);
      if (index != -1) {
        _materials[index] = material.copyWith(writeDate: DateTime.now());
        
        if (_selectedMaterial?.id == material.id) {
          _selectedMaterial = _materials[index];
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update material: $e');
      return false;
    }
  }

  Future<bool> deleteMaterial(Material material) async {
    _clearError();
    
    try {
      await _db.delete('materials', where: 'id = ?', whereArgs: [material.id]);
      
      _materials.removeWhere((m) => m.id == material.id);
      
      if (_selectedMaterial?.id == material.id) {
        _selectedMaterial = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete material: $e');
      return false;
    }
  }

  Future<bool> toggleMaterialStatus(Material material) async {
    final updatedMaterial = material.copyWith(active: !material.active);
    return await updateMaterial(updatedMaterial);
  }

  void selectMaterial(Material? material) {
    _selectedMaterial = material;
    notifyListeners();
  }

  Material? findMaterialByName(String name) {
    final normalizedSearchName = normalizeArabic(name);
    return _materials.where((material) =>
      material.normalizedName == normalizedSearchName
    ).firstOrNull;
  }

  // Removed - no longer needed with simplified model

  List<Material> searchMaterials(String query) {
    if (query.isEmpty) return _materials;

    final normalizedQuery = normalizeArabic(query);
    final lowerQuery = query.toLowerCase();
    return _materials.where((material) =>
      (material.normalizedName?.contains(normalizedQuery) ?? false) ||
      (material.description?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  // Method removed - no longer needed with simplified model

  void setShowActiveOnly(bool activeOnly) {
    _showActiveOnly = activeOnly;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _showActiveOnly = true;
    notifyListeners();
  }

  List<Material> _applyFilters(List<Material> materials) {
    var filteredMaterials = materials;

    // Active filter
    if (_showActiveOnly) {
      filteredMaterials = filteredMaterials.where((material) => material.active).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final normalizedQuery = normalizeArabic(_searchQuery);
      filteredMaterials = filteredMaterials.where((material) {
        return (material.normalizedName?.contains(normalizedQuery) ?? false) ||
               (material.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return filteredMaterials;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _lastError = null;
    }
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    notifyListeners();
  }

  // Pricing analysis
  double get averagePrice {
    final materialsWithPrice = _materials.where((m) => m.price != null && m.price! > 0);
    if (materialsWithPrice.isEmpty) return 0.0;
    final totalPrice = materialsWithPrice.map((m) => m.price!).reduce((a, b) => a + b);
    return totalPrice / materialsWithPrice.length;
  }

  Material? get mostExpensive {
    final materialsWithPrice = _materials.where((m) => m.price != null && m.price! > 0);
    if (materialsWithPrice.isEmpty) return null;
    return materialsWithPrice.reduce((a, b) => (a.price ?? 0) > (b.price ?? 0) ? a : b);
  }

  Material? get cheapest {
    final materialsWithPrice = _materials.where((m) => m.price != null && m.price! > 0);
    if (materialsWithPrice.isEmpty) return null;
    return materialsWithPrice.reduce((a, b) => (a.price ?? 0) < (b.price ?? 0) ? a : b);
  }

  // Export/Import functionality
  Map<String, dynamic> exportMaterialsToJson() {
    return {
      'materials': _materials.map((material) => material.toJson()).toList(),
      'export_date': DateTime.now().toIso8601String(),
      'total_count': _materials.length,
      'statistics': {
        'total_materials': totalMaterials,
        'active_materials': activeMaterials,
        'average_price': averagePrice,
      },
    };
  }

  Future<bool> importMaterialsFromJson(Map<String, dynamic> data) async {
    try {
      final materialsData = data['materials'] as List<dynamic>;
      int importCount = 0;
      
      for (final materialData in materialsData) {
        final material = Material.fromJson(materialData as Map<String, dynamic>);
        
        // Check if material already exists by name
        final existingByName = findMaterialByName(material.name);
            
        if (existingByName == null) {
          await addMaterial(material);
          importCount++;
        }
      }
      
      return importCount > 0;
    } catch (e) {
      _setError('Failed to import materials: $e');
      return false;
    }
  }

  // Helper method to find material by ID
  Material? getMaterialById(int id) {
    try {
      return _materials.firstWhere((material) => material.id == id);
    } catch (e) {
      return null;
    }
  }
}