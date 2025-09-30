import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../models/supplier.dart';
import '../models/material.dart';
import '../models/weighing_tab.dart';

class OdooConfig {
  final String baseUrl;
  final String database;
  final String username;
  final String password;

  OdooConfig({
    required this.baseUrl,
    required this.database,
    required this.username,
    required this.password,
  });
}

class OdooService {
  static final OdooService _instance = OdooService._internal();
  factory OdooService() => _instance;
  OdooService._internal();

  final Dio _dio = Dio();
  OdooConfig? _config;
  String? _sessionId;
  int? _uid;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isConfigured => _config != null;

  void configure(OdooConfig config) {
    _config = config;
    _dio.options.baseUrl = config.baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };

    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<bool> authenticate() async {
    if (_config == null) {
      throw Exception('Odoo service not configured');
    }

    try {
      final response = await _dio.post('/web/session/authenticate', data: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'db': _config!.database,
          'login': _config!.username,
          'password': _config!.password,
        },
        'id': _generateId(),
      });

      if (response.statusCode == 200) {
        final result = response.data['result'];
        if (result != null && result['uid'] != false) {
          _uid = result['uid'];
          _sessionId = result['session_id'];
          _isAuthenticated = true;

          // Store session cookie
          if (response.headers['set-cookie'] != null) {
            _dio.options.headers['Cookie'] =
                response.headers['set-cookie']!.first;
          }

          return true;
        }
      }

      _isAuthenticated = false;
      return false;
    } catch (e) {
      _isAuthenticated = false;
      debugPrint('Odoo authentication error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/web/session/destroy', data: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {},
        'id': _generateId(),
      });
    } catch (e) {
      debugPrint('Odoo logout error: $e');
    } finally {
      _isAuthenticated = false;
      _uid = null;
      _sessionId = null;
      _dio.options.headers.remove('Cookie');
    }
  }

  Future<Map<String, dynamic>> call(
    String model,
    String method,
    List<dynamic> args, {
    Map<String, dynamic>? kwargs,
  }) async {
    if (!_isAuthenticated) {
      throw Exception('Not authenticated with Odoo');
    }

    try {
      final response = await _dio.post('/web/dataset/call_kw', data: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': model,
          'method': method,
          'args': args,
          'kwargs': kwargs ?? {},
        },
        'id': _generateId(),
      });

      if (response.statusCode == 200) {
        if (response.data['error'] != null) {
          throw Exception('Odoo error: ${response.data['error']['message']}');
        }
        return response.data;
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Odoo call error: $e');
      rethrow;
    }
  }

  // Partner (Client/Supplier) operations
  Future<int?> createPartner(Client client) async {
    try {
      final result = await call(
        'res.partner',
        'create',
        [
          {
            'name': client.name,
            'email': client.email,
            'phone': client.phone,
            'mobile': client.mobile,
            'street': client.street,
            'street2': client.street2,
            'city': client.city,
            'zip': client.zip,
            'vat': client.vat,
            'is_company': client.isCompany,
            'supplier_rank': client.supplierRank,
            'customer_rank': client.customerRank,
            'active': client.active,
          }
        ],
      );

      return result['result'] as int?;
    } catch (e) {
      debugPrint('Error creating partner: $e');
      return null;
    }
  }

  Future<int?> createSupplier(Supplier supplier) async {
    try {
      final result = await call(
        'res.partner',
        'create',
        [
          {
            'name': supplier.name,
            'email': supplier.email,
            'phone': supplier.phone,
            'mobile': supplier.mobile,
            'street': supplier.street,
            'street2': supplier.street2,
            'city': supplier.city,
            'zip': supplier.zip,
            'vat': supplier.vat,
            'is_company': supplier.isCompany,
            'supplier_rank': supplier.supplierRank,
            'customer_rank': supplier.customerRank,
            'active': supplier.active,
          }
        ],
      );

      return result['result'] as int?;
    } catch (e) {
      debugPrint('Error creating supplier: $e');
      return null;
    }
  }

  Future<bool> updatePartner(int odooId, Map<String, dynamic> values) async {
    try {
      final result = await call(
        'res.partner',
        'write',
        [
          [odooId],
          values
        ],
      );

      return result['result'] == true;
    } catch (e) {
      debugPrint('Error updating partner: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchPartners({
    List<dynamic>? domain,
    List<String>? fields,
    int? limit,
  }) async {
    try {
      final result = await call(
        'res.partner',
        'search_read',
        [],
        kwargs: {
          if (domain != null) 'domain': domain,
          if (fields != null) 'fields': fields,
          if (limit != null) 'limit': limit,
        },
      );

      return List<Map<String, dynamic>>.from(result['result'] ?? []);
    } catch (e) {
      debugPrint('Error searching partners: $e');
      return [];
    }
  }

  // Product operations
  Future<int?> createProduct(Material material) async {
    try {
      final result = await call(
        'product.product',
        'create',
        [
          {
            'name': material.name,
            'list_price': material.price ?? 0.0,
            'standard_price': material.price ?? 0.0,
            'type': 'product',
            'tracking': 'none',
            'description': material.description,
            'active': material.active,
          }
        ],
      );

      return result['result'] as int?;
    } catch (e) {
      debugPrint('Error creating product: $e');
      return null;
    }
  }

  Future<bool> updateProduct(int odooId, Map<String, dynamic> values) async {
    try {
      final result = await call(
        'product.product',
        'write',
        [
          [odooId],
          values
        ],
      );

      return result['result'] == true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts({
    List<dynamic>? domain,
    List<String>? fields,
    int? limit,
  }) async {
    try {
      final result = await call(
        'product.product',
        'search_read',
        [],
        kwargs: {
          if (domain != null) 'domain': domain,
          if (fields != null) 'fields': fields,
          if (limit != null) 'limit': limit,
        },
      );

      return List<Map<String, dynamic>>.from(result['result'] ?? []);
    } catch (e) {
      debugPrint('Error searching products: $e');
      return [];
    }
  }

  // Custom weighing order operations (if using custom model)
  // DISABLED: Order model removed
  /* Future<int?> createWeighingOrder(Order order) async {
    try {
      final result = await call(
        'weighing.order', // Custom model name
        'create',
        [{
          'order_number': order.orderNumber,
          'partner_id': order.clientId,
          'supplier_id': order.supplierId,
          'product_id': order.materialId,
          'operation_type': order.operationType,
          'truck_plate': order.truckPlate,
          'driver_name': order.driverName,
          'driver_license': order.driverLicense,
          'gross_weight': order.grossWeight,
          'tare_weight': order.tareWeight,
          'net_weight': order.netWeight,
          'unit_price': order.unitPrice,
          'total_amount': order.totalAmount,
          'state': order.status,
          'weigh_in_time': order.weighInTime?.toIso8601String(),
          'weigh_out_time': order.weighOutTime?.toIso8601String(),
          'notes': order.notes,
        }],
      );

      return result['result'] as int?;
    } catch (e) {
      debugPrint('Error creating weighing order: $e');
      return null;
    }
  }
  */

  Future<bool> updateWeighingOrder(
      int odooId, Map<String, dynamic> values) async {
    try {
      final result = await call(
        'weighing.order',
        'write',
        [
          [odooId],
          values
        ],
      );

      return result['result'] == true;
    } catch (e) {
      debugPrint('Error updating weighing order: $e');
      return false;
    }
  }

  // WeighingTab methods - using simplified weighing.tab model
  Future<int?> createWeighingTab(WeighingTab tab) async {
    try {
      final result = await call(
        'weighing.tab', // Simplified model name
        'create',
        [
          {
            'tab_id': tab.id ?? 0,
            'truck_plate': tab.truckPlate,
            'driver_name': tab.driverName,
            'supplier_client': tab.supplier,
            'material': tab.material,
            'empty_weight': tab.emptyWeight,
            'gross_weight': tab.grossWeight,
            'net_weight': tab.netWeight,
            'status': tab.status,
            'is_paid': tab.isPaid,
            'show_price_on_print': tab.showPriceOnPrint,
            'created_at': tab.createdAt.toIso8601String(),
            'updated_at': tab.updatedAt.toIso8601String(),
          }
        ],
      );

      return result['result'] as int?;
    } catch (e) {
      debugPrint('Error creating weighing tab: $e');
      return null;
    }
  }

  Future<bool> updateWeighingTab(
      int odooId, Map<String, dynamic> values) async {
    try {
      final result = await call(
        'weighing.tab',
        'write',
        [
          [odooId],
          values
        ],
      );

      return result['result'] == true;
    } catch (e) {
      debugPrint('Error updating weighing tab: $e');
      return false;
    }
  }

  // Connection test
  Future<bool> testConnection() async {
    try {
      if (!_isAuthenticated) {
        final authSuccess = await authenticate();
        if (!authSuccess) return false;
      }

      // Simple test call to get user info
      final result = await call('res.users', 'read', [
        _uid
      ], kwargs: {
        'fields': ['name', 'login']
      });

      return result['result'] != null;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  // Utility methods
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Map<String, dynamic> _buildDomain(Map<String, dynamic> filters) {
    final domain = <dynamic>[];

    filters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        if (value is String) {
          domain.add([key, 'ilike', value]);
        } else {
          domain.add([key, '=', value]);
        }
      }
    });

    return {'domain': domain};
  }

  // Batch operations for better performance
  Future<List<int?>> createMultipleRecords(
    String model,
    List<Map<String, dynamic>> records,
  ) async {
    final results = <int?>[];

    for (final record in records) {
      try {
        final result = await call(model, 'create', [record]);
        results.add(result['result'] as int?);
      } catch (e) {
        debugPrint('Error creating record: $e');
        results.add(null);
      }
    }

    return results;
  }

  Future<List<bool>> updateMultipleRecords(
    String model,
    Map<int, Map<String, dynamic>> updates,
  ) async {
    final results = <bool>[];

    for (final entry in updates.entries) {
      try {
        final result = await call(model, 'write', [
          [entry.key],
          entry.value
        ]);
        results.add(result['result'] == true);
      } catch (e) {
        debugPrint('Error updating record: $e');
        results.add(false);
      }
    }

    return results;
  }
}
