import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../models/sync_queue.dart';
import '../models/client.dart';
import '../models/supplier.dart';
import '../models/material.dart';
import '../models/weighing_tab.dart';
import '../database/database_helper.dart';
import '../services/odoo_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final Connectivity _connectivity = Connectivity();
  final OdooService _odooService = OdooService();
  
  bool _isOnline = false;
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _lastError;
  DateTime? _lastSyncTime;
  int _pendingSyncCount = 0;
  double _syncProgress = 0.0;
  
  Timer? _connectivityTimer;
  Timer? _autoSyncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Configuration
  bool _autoSyncEnabled = true;
  Duration _autoSyncInterval = const Duration(minutes: 5);
  
  // Getters
  bool get isOnline => _isOnline;
  SyncStatus get syncStatus => _syncStatus;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingSyncCount => _pendingSyncCount;
  double get syncProgress => _syncProgress;
  bool get autoSyncEnabled => _autoSyncEnabled;
  Duration get autoSyncInterval => _autoSyncInterval;
  
  bool get isSyncing => _syncStatus == SyncStatus.syncing;
  bool get hasError => _syncStatus == SyncStatus.error;
  bool get canSync => _isOnline && !isSyncing;

  SyncProvider() {
    _initialize();
  }

  void _initialize() {
    _checkConnectivity();
    _loadPendingSyncCount();
    _startConnectivityMonitoring();
    _startAutoSync();
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline;
      _isOnline = connectivityResult == ConnectivityResult.wifi || 
                 connectivityResult == ConnectivityResult.ethernet ||
                 connectivityResult == ConnectivityResult.mobile;
      
      if (!wasOnline && _isOnline) {
        // Just came online, trigger sync if auto-sync is enabled
        if (_autoSyncEnabled && _pendingSyncCount > 0) {
          Future.delayed(const Duration(seconds: 2), () {
            performFullSync();
          });
        }
      }
      
      notifyListeners();
    } catch (e) {
      _isOnline = false;
      notifyListeners();
    }
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final wasOnline = _isOnline;
        _isOnline = result == ConnectivityResult.wifi || 
                   result == ConnectivityResult.ethernet ||
                   result == ConnectivityResult.mobile;
        
        if (!wasOnline && _isOnline) {
          // Just came online
          if (_autoSyncEnabled && _pendingSyncCount > 0) {
            Future.delayed(const Duration(seconds: 2), () {
              performFullSync();
            });
          }
        }
        
        notifyListeners();
      },
    );
  }

  void _startAutoSync() {
    if (!_autoSyncEnabled) return;
    
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (timer) {
      if (_isOnline && _pendingSyncCount > 0 && !isSyncing) {
        performFullSync();
      }
    });
  }

  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  Future<void> _loadPendingSyncCount() async {
    try {
      final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM sync_queue WHERE attempts < max_attempts'
      );
      _pendingSyncCount = result.first['count'] as int;
      notifyListeners();
    } catch (e) {
      // Ignore error, will be 0
    }
  }

  Future<void> queueForSync(
    String tableName,
    int recordId,
    String operation, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final syncItem = SyncQueue(
        tableName: tableName,
        recordId: recordId,
        operation: operation,
        data: data,
      );

      await _db.insert('sync_queue', syncItem.toDatabase());
      _pendingSyncCount++;
      
      // Trigger immediate sync if online and auto-sync is enabled
      if (_isOnline && _autoSyncEnabled && !isSyncing) {
        Future.delayed(const Duration(seconds: 1), () {
          performFullSync();
        });
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to queue item for sync: $e');
    }
  }

  Future<void> performFullSync() async {
    if (!_isOnline || isSyncing) return;

    _setSyncStatus(SyncStatus.syncing);
    _syncProgress = 0.0;
    _clearError();

    try {
      // Get all pending sync items
      final syncItems = await _getPendingSyncItems();
      
      if (syncItems.isEmpty) {
        _setSyncStatus(SyncStatus.success);
        _lastSyncTime = DateTime.now();
        return;
      }

      final totalItems = syncItems.length;
      int processedItems = 0;

      for (final item in syncItems) {
        if (!_isOnline) {
          _setError('Connection lost during sync');
          _setSyncStatus(SyncStatus.error);
          return;
        }

        try {
          await _processSyncItem(item);
          processedItems++;
          _syncProgress = processedItems / totalItems;
          notifyListeners();
        } catch (e) {
          // Update attempts count and error message
          await _updateSyncItemAttempt(item, e.toString());
        }
      }

      await _loadPendingSyncCount();
      _setSyncStatus(SyncStatus.success);
      _lastSyncTime = DateTime.now();
      _syncProgress = 1.0;

    } catch (e) {
      _setError('Sync failed: $e');
      _setSyncStatus(SyncStatus.error);
    }
  }

  Future<List<SyncQueue>> _getPendingSyncItems() async {
    final result = await _db.query(
      'sync_queue',
      where: 'attempts < max_attempts',
      orderBy: 'created_at ASC',
    );

    return result.map((map) => SyncQueue.fromDatabase(map)).toList();
  }

  Future<void> _processSyncItem(SyncQueue item) async {
    // This is where you would implement the actual sync logic with Odoo
    // For now, we'll simulate the process
    
    switch (item.operation) {
      case 'create':
        await _syncCreate(item);
        break;
      case 'update':
        await _syncUpdate(item);
        break;
      case 'delete':
        await _syncDelete(item);
        break;
    }

    // Remove from sync queue on success
    await _db.delete('sync_queue', where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> _syncCreate(SyncQueue item) async {
    if (!_odooService.isAuthenticated) {
      throw Exception('Not authenticated with Odoo');
    }

    int? odooId;
    
    try {
      switch (item.tableName) {
        case 'clients':
          final client = Client.fromJson(item.data!);
          odooId = await _odooService.createPartner(client);
          break;
          
        case 'suppliers':
          final supplier = Supplier.fromJson(item.data!);
          odooId = await _odooService.createSupplier(supplier);
          break;
          
        case 'materials':
          final material = Material.fromJson(item.data!);
          odooId = await _odooService.createProduct(material);
          break;
          
        case 'weighing_tabs':
          final tab = WeighingTab.fromMap(item.data!);
          odooId = await _odooService.createWeighingTab(tab);
          break;
          
        default:
          throw Exception('Unknown table: ${item.tableName}');
      }
      
      if (odooId != null) {
        // Update local record with Odoo ID
        await _db.update(
          item.tableName,
          {
            'odoo_id': odooId,
            'sync_status': 1,
            'write_date': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [item.recordId],
        );
      } else {
        throw Exception('Failed to create record in Odoo');
      }
    } catch (e) {
      debugPrint('Sync create error: $e');
      rethrow;
    }
  }

  Future<void> _syncUpdate(SyncQueue item) async {
    if (!_odooService.isAuthenticated) {
      throw Exception('Not authenticated with Odoo');
    }

    try {
      // Get the local record's Odoo ID
      final localRecord = await _db.query(
        item.tableName,
        where: 'id = ?',
        whereArgs: [item.recordId],
        limit: 1,
      );
      
      if (localRecord.isEmpty) {
        throw Exception('Local record not found');
      }
      
      final odooId = localRecord.first['odoo_id'] as int?;
      if (odooId == null) {
        throw Exception('Record not synced to Odoo yet');
      }

      bool success = false;
      
      switch (item.tableName) {
        case 'clients':
        case 'suppliers':
          success = await _odooService.updatePartner(odooId, item.data!);
          break;
          
        case 'materials':
          success = await _odooService.updateProduct(odooId, item.data!);
          break;
          
        case 'weighing_tabs':
          success = await _odooService.updateWeighingTab(odooId, item.data!);
          break;
          
        default:
          throw Exception('Unknown table: ${item.tableName}');
      }
      
      if (success) {
        // Update sync status
        await _db.update(
          item.tableName,
          {
            'sync_status': 1,
            'write_date': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [item.recordId],
        );
      } else {
        throw Exception('Failed to update record in Odoo');
      }
    } catch (e) {
      debugPrint('Sync update error: $e');
      rethrow;
    }
  }

  Future<void> _syncDelete(SyncQueue item) async {
    if (!_odooService.isAuthenticated) {
      throw Exception('Not authenticated with Odoo');
    }

    try {
      final odooId = item.data?['odoo_id'] as int?;
      if (odooId == null) {
        // Record was never synced to Odoo, nothing to delete
        return;
      }

      bool success = false;
      
      switch (item.tableName) {
        case 'clients':
        case 'suppliers':
          success = await _odooService.updatePartner(odooId, {'active': false});
          break;
          
        case 'materials':
          success = await _odooService.updateProduct(odooId, {'active': false});
          break;
          
        case 'weighing_tabs':
          success = await _odooService.updateWeighingTab(odooId, {'status': 'cancelled'});
          break;
          
        default:
          throw Exception('Unknown table: ${item.tableName}');
      }
      
      if (!success) {
        throw Exception('Failed to delete/deactivate record in Odoo');
      }
    } catch (e) {
      debugPrint('Sync delete error: $e');
      rethrow;
    }
  }

  Future<void> _updateSyncItemAttempt(SyncQueue item, String errorMessage) async {
    final updatedItem = item.copyWith(
      attempts: item.attempts + 1,
      lastAttempt: DateTime.now(),
      errorMessage: errorMessage,
    );

    await _db.update(
      'sync_queue',
      updatedItem.toDatabase(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> retrySyncItem(SyncQueue item) async {
    if (!_isOnline) {
      _setError('No internet connection');
      return;
    }

    try {
      await _processSyncItem(item);
      await _loadPendingSyncCount();
      notifyListeners();
    } catch (e) {
      await _updateSyncItemAttempt(item, e.toString());
      _setError('Retry failed: $e');
    }
  }

  Future<void> removeSyncItem(SyncQueue item) async {
    await _db.delete('sync_queue', where: 'id = ?', whereArgs: [item.id]);
    await _loadPendingSyncCount();
    notifyListeners();
  }

  Future<void> clearFailedSyncItems() async {
    await _db.delete('sync_queue', where: 'attempts >= max_attempts');
    await _loadPendingSyncCount();
    notifyListeners();
  }

  Future<List<SyncQueue>> getFailedSyncItems() async {
    final result = await _db.query(
      'sync_queue',
      where: 'attempts >= max_attempts',
      orderBy: 'created_at DESC',
    );

    return result.map((map) => SyncQueue.fromDatabase(map)).toList();
  }

  Future<List<SyncQueue>> getAllSyncItems() async {
    final result = await _db.query(
      'sync_queue',
      orderBy: 'created_at DESC',
    );

    return result.map((map) => SyncQueue.fromDatabase(map)).toList();
  }

  void setAutoSyncEnabled(bool enabled) {
    _autoSyncEnabled = enabled;
    
    if (enabled) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }
    
    notifyListeners();
  }

  void setAutoSyncInterval(Duration interval) {
    _autoSyncInterval = interval;
    
    if (_autoSyncEnabled) {
      _startAutoSync();
    }
    
    notifyListeners();
  }

  void setMaxRetryAttempts(int attempts) {
    // This setter is disabled as retry logic is not implemented
    notifyListeners();
  }

  String? getConnectionStatusText() {
    if (!_isOnline) return 'Offline';
    
    switch (_syncStatus) {
      case SyncStatus.idle:
        return _pendingSyncCount > 0 ? 'Pending sync ($pendingSyncCount items)' : 'Online';
      case SyncStatus.syncing:
        return 'Syncing... ${(_syncProgress * 100).toInt()}%';
      case SyncStatus.success:
        return 'Last sync: ${_formatLastSyncTime()}';
      case SyncStatus.error:
        return 'Sync failed';
    }
  }

  String _formatLastSyncTime() {
    if (_lastSyncTime == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  void _setSyncStatus(SyncStatus status) {
    _syncStatus = status;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    _setSyncStatus(SyncStatus.error);
  }

  void _clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _autoSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}