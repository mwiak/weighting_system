import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../database/database_helper.dart';

class ClientProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Client> _clients = [];
  Client? _selectedClient;
  
  // Filter and search
  String _searchQuery = '';
  bool _showActiveOnly = true;

  // Loading states
  bool _isLoading = false;
  String? _lastError;
  
  // Getters
  List<Client> get clients => _clients;
  List<Client> get filteredClients => _applyFilters(_clients);
  List<Client> get activeClients => _clients.where((client) => client.active).toList();
  Client? get selectedClient => _selectedClient;
  String get searchQuery => _searchQuery;
  bool get showActiveOnly => _showActiveOnly;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // Statistics
  int get totalClients => _clients.length;

  ClientProvider() {
    loadClients();
  }

  Future<void> loadClients() async {
    _setLoading(true);
    _clearError();
    
    try {
      final clientMaps = await _db.query(
        'clients',
        orderBy: 'name ASC',
      );
      
      _clients = clientMaps.map((map) => Client.fromDatabase(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load clients: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Client?> createClient({
    required String name,
    String? email,
    String? phone,
    String? mobile,
    String? street,
    String? street2,
    String? city,
    String? zip,
    String? vat,
    bool isCompany = false,
    bool active = true,
  }) async {
    _clearError();

    try {
      final client = Client(
        name: name,
        email: email,
        phone: phone,
        mobile: mobile,
        street: street,
        street2: street2,
        city: city,
        zip: zip,
        vat: vat,
        isCompany: isCompany,
        active: active,
        createDate: DateTime.now().toIso8601String(),
        writeDate: DateTime.now().toIso8601String(),
      );

      final id = await _db.insert('clients', client.toDatabase());
      final createdClient = client.copyWith(id: id);

      _clients.add(createdClient);
      _clients.sort((a, b) => a.name.compareTo(b.name));

      notifyListeners();
      return createdClient;
    } catch (e) {
      _setError('Failed to create client: $e');
      return null;
    }
  }

  Future<bool> updateClient(Client client) async {
    _clearError();

    try {
      final updatedData = client.toDatabase();
      
      await _db.update(
        'clients',
        updatedData,
        where: 'id = ?',
        whereArgs: [client.id],
      );
      
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;

        if (_selectedClient?.id == client.id) {
          _selectedClient = _clients[index];
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update client: $e');
      return false;
    }
  }

  Future<bool> deleteClient(Client client) async {
    _clearError();

    try {
      await _db.delete('clients', where: 'id = ?', whereArgs: [client.id]);

      _clients.removeWhere((c) => c.id == client.id);

      if (_selectedClient?.id == client.id) {
        _selectedClient = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete client: $e');
      return false;
    }
  }

  Future<bool> toggleClientStatus(Client client) async {
    final updatedClient = client.copyWith(
      active: !client.active,
      writeDate: DateTime.now().toIso8601String(),
    );

    return await updateClient(updatedClient);
  }


  void selectClient(Client? client) {
    _selectedClient = client;
    notifyListeners();
  }

  Client? findClientByName(String name) {
    return _clients.where((client) => 
      client.name.toLowerCase() == name.toLowerCase()
    ).firstOrNull;
  }

  List<Client> searchClients(String query) {
    if (query.isEmpty) return _clients;

    final lowerQuery = query.toLowerCase();
    return _clients.where((client) =>
      client.name.toLowerCase().contains(lowerQuery) ||
      (client.phone?.contains(query) ?? false) ||
      (client.city?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void setShowActiveOnly(bool showActive) {
    _showActiveOnly = showActive;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _showActiveOnly = true;
    notifyListeners();
  }

  List<Client> _applyFilters(List<Client> clients) {
    var filteredClients = clients;

    // Active filter
    if (_showActiveOnly) {
      filteredClients = filteredClients.where((client) => client.active).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filteredClients = filteredClients.where((client) {
        return client.name.toLowerCase().contains(_searchQuery) ||
               (client.phone?.contains(_searchQuery) ?? false) ||
               (client.mobile?.contains(_searchQuery) ?? false) ||
               (client.email?.toLowerCase().contains(_searchQuery) ?? false) ||
               (client.city?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return filteredClients;
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

  // Export/Import functionality
  Map<String, dynamic> exportClientsToJson() {
    return {
      'clients': _clients.map((client) => client.toJson()).toList(),
      'export_date': DateTime.now().toIso8601String(),
      'total_count': _clients.length,
    };
  }

  Future<bool> importClientsFromJson(Map<String, dynamic> data) async {
    try {
      final clientsData = data['clients'] as List<dynamic>;
      int importCount = 0;

      for (final clientData in clientsData) {
        final client = Client.fromJson(clientData as Map<String, dynamic>);

        // Check if client already exists by name
        final existing = findClientByName(client.name);
        if (existing == null) {
          await createClient(
            name: client.name,
            email: client.email,
            phone: client.phone,
            mobile: client.mobile,
            street: client.street,
            street2: client.street2,
            city: client.city,
            zip: client.zip,
            vat: client.vat,
            isCompany: client.isCompany,
            active: client.active,
          );
          importCount++;
        }
      }

      return importCount > 0;
    } catch (e) {
      _setError('Failed to import clients: $e');
      return false;
    }
  }

  // Helper method to find client by ID
  Client? getClientById(int id) {
    try {
      return _clients.firstWhere((client) => client.id == id);
    } catch (e) {
      return null;
    }
  }
}