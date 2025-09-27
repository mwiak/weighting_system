import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/app_setting.dart';

class AppSettingsProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Map<String, AppSetting> _settings = {};
  bool _isLoading = false;
  String? _lastError;

  Map<String, AppSetting> get settings => Map.unmodifiable(_settings);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // Odoo settings getters
  String get odooUrl => getSetting('odoo_url')?.value ?? '';
  String get odooDatabase => getSetting('odoo_database')?.value ?? '';
  String get odooUsername => getSetting('odoo_username')?.value ?? '';
  String get odooPassword => getSetting('odoo_password')?.value ?? '';
  bool get isOdooConfigured => odooUrl.isNotEmpty && 
                               odooDatabase.isNotEmpty && 
                               odooUsername.isNotEmpty && 
                               odooPassword.isNotEmpty;

  // Print settings getters
  String get printSchemaTemplate => getSetting('print_schema_template')?.value ?? '';
  String get companyName => getSetting('company_name')?.value ?? '';

  // General settings getters
  bool get autoSyncEnabled => getSetting('auto_sync_enabled')?.value == '1';

  Future<void> loadSettings() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      final results = await db.query('app_settings');

      _settings.clear();
      for (final row in results) {
        final setting = AppSetting.fromMap(row);
        _settings[setting.key] = setting;
      }
    } catch (e) {
      _lastError = 'Failed to load settings: $e';
      debugPrint(_lastError);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  AppSetting? getSetting(String key) {
    return _settings[key];
  }

  Future<bool> updateSetting({
    required String key,
    required String value,
    String? description,
  }) async {
    try {
      final db = await _dbHelper.database;
      
      final result = await db.update(
        'app_settings',
        {
          'setting_value': value,
          'updated_at': DateTime.now().toIso8601String(),
          if (description != null) 'description': description,
        },
        where: 'setting_key = ?',
        whereArgs: [key],
      );

      if (result > 0) {
        // Update local cache
        final existingSetting = _settings[key];
        if (existingSetting != null) {
          _settings[key] = existingSetting.copyWith(
            value: value,
            updatedAt: DateTime.now(),
            description: description,
          );
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _lastError = 'Failed to update setting $key: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOdooSettings({
    required String url,
    required String database,
    required String username,
    required String password,
  }) async {
    try {
      final updates = [
        updateSetting(key: 'odoo_url', value: url),
        updateSetting(key: 'odoo_database', value: database),
        updateSetting(key: 'odoo_username', value: username),
        updateSetting(key: 'odoo_password', value: password),
      ];

      final results = await Future.wait(updates);
      final allSucceeded = results.every((result) => result);
      
      if (allSucceeded) {
        _lastError = null;
      } else {
        _lastError = 'Failed to update some Odoo settings';
      }
      
      notifyListeners();
      return allSucceeded;
    } catch (e) {
      _lastError = 'Failed to update Odoo settings: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePrintSettings({
    required String template,
    required String companyName,
  }) async {
    try {
      final updates = [
        updateSetting(key: 'print_schema_template', value: template),
        updateSetting(key: 'company_name', value: companyName),
      ];

      final results = await Future.wait(updates);
      final allSucceeded = results.every((result) => result);
      
      if (allSucceeded) {
        _lastError = null;
      } else {
        _lastError = 'Failed to update some print settings';
      }
      
      notifyListeners();
      return allSucceeded;
    } catch (e) {
      _lastError = 'Failed to update print settings: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleAutoSync() async {
    final currentValue = autoSyncEnabled;
    return await updateSetting(
      key: 'auto_sync_enabled',
      value: currentValue ? '0' : '1',
    );
  }

  Future<bool> testOdooConnection() async {
    if (!isOdooConfigured) {
      _lastError = 'Odoo is not fully configured';
      notifyListeners();
      return false;
    }

    try {
      // TODO: Implement actual Odoo connection test
      // This would use the OdooService to test the connection
      await Future.delayed(const Duration(seconds: 2)); // Simulate network call
      
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Odoo connection test failed: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  Future<bool> addCustomSetting({
    required String key,
    required String value,
    String type = 'string',
    String? description,
  }) async {
    try {
      final db = await _dbHelper.database;
      
      final setting = AppSetting(
        key: key,
        value: value,
        type: type,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await db.insert('app_settings', setting.toMap());
      
      if (id > 0) {
        _settings[key] = setting.copyWith(id: id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _lastError = 'Failed to add custom setting: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSetting(String key) async {
    // Prevent deletion of core settings
    final coreSettings = {
      'odoo_url',
      'odoo_database',
      'odoo_username',
      'odoo_password',
      'print_schema_template',
      'company_name',
      'auto_sync_enabled',
    };

    if (coreSettings.contains(key)) {
      _lastError = 'Cannot delete core setting: $key';
      notifyListeners();
      return false;
    }

    try {
      final db = await _dbHelper.database;
      final result = await db.delete(
        'app_settings',
        where: 'setting_key = ?',
        whereArgs: [key],
      );

      if (result > 0) {
        _settings.remove(key);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _lastError = 'Failed to delete setting: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Map<String, String> getOdooConfigMap() {
    return {
      'url': odooUrl,
      'database': odooDatabase,
      'username': odooUsername,
      'password': odooPassword,
    };
  }
}