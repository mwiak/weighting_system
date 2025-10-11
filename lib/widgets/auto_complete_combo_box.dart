import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:weighing_system/utils/debugging_methods.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/client_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/material_provider.dart';
import '../providers/driver_plate_provider.dart';
import '../models/supplier.dart';
import '../models/material.dart' as m;
import '../database/database_helper.dart';
import '../utils/arabic_normalize.dart';

enum AutoCompleteType {
  truckPlate,
  driver,
  supplierClient, // Keep for backward compatibility
  client, // For customers only
  supplier, // For suppliers only
  material,
}

class AutoCompleteComboBox extends StatefulWidget {
  final String placeholder;
  final String value;
  final ValueChanged<String> onChanged;
  final AutoCompleteType suggestionType;
  final TextEditingController? controller;
  final TextEditingController? driverController;
  final TextEditingController? plateController;

  const AutoCompleteComboBox({
    super.key,
    required this.placeholder,
    required this.value,
    required this.onChanged,
    required this.suggestionType,
    this.controller,
    this.driverController,
    this.plateController,
  });

  @override
  State<AutoCompleteComboBox> createState() => _AutoCompleteComboBoxState();
}

class _AutoCompleteComboBoxState extends State<AutoCompleteComboBox> {
  late TextEditingController _controller;
  late TextEditingController _driverController;
  late TextEditingController _plateController;
  bool _ownsController = false;
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;
  bool isPointerInside = false;
  List<String> crossSuggestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = TextEditingController(text: widget.value);
      _ownsController = true;
    }

    if (widget.suggestionType == AutoCompleteType.truckPlate &&
        widget.driverController != null) {
      widget.driverController!.addListener(_handleDriverVehicleRelationship);
      _driverController = widget.driverController!;
    }

    if (widget.suggestionType == AutoCompleteType.driver &&
        widget.plateController != null) {
      widget.plateController!.addListener(_handleDriverVehicleRelationship);
      _plateController = widget.plateController!;
    }

    _focusNode.addListener(_handleFocusChange);

    // Listen to controller changes for immediate UI updates
    _controller.addListener(_onControllerChanged);

    // Load suggestions after the build to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAllSuggestions();
      }
    });
  }

  @override
  void didUpdateWidget(AutoCompleteComboBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _ownsController = false;
      } else {
        _controller = TextEditingController(text: widget.value);
        _ownsController = true;
      }
    }

    // Update controller text when widget value changes, but only if not currently focused/editing
    // and only if we own the controller
    if (_ownsController &&
        oldWidget.value != widget.value &&
        !_focusNode.hasFocus) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _debounceTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    widget.driverController?.removeListener(_handleDriverVehicleRelationship);
    widget.plateController?.removeListener(_handleDriverVehicleRelationship);
    if (_ownsController) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Trigger immediate UI update when controller text changes
    if (mounted && _showSuggestions) {
      setState(() {
        // This will cause the overlay to rebuild with updated filteredSuggestions
      });
      _updateOverlay();
    }
  }

  void _handleFocusChange() async {
    if (_focusNode.hasFocus && !_showSuggestions) {
      _showOverlay();
    } else if (!_focusNode.hasFocus && _showSuggestions) {
      if (!isPointerInside) {
        _hideOverlay();
      }
    }
  }

  void _onTextChanged(String value) {
    // Immediately update UI by triggering rebuild for filtered suggestions
    if (mounted) {
      setState(() {
        // This will cause filteredSuggestions to be recalculated
      });
    }

    // Update overlay if it's showing
    if (_showSuggestions) {
      _updateOverlay();
    }

    // Debounced callback to parent (reduced from 600ms to 200ms for better responsiveness)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        debugPrint(
            'AutoCompleteComboBox: Debounced onChanged called with: $value');
        widget.onChanged(value);
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null || !mounted) return;

    setState(() {
      _showSuggestions = true;
    });

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    printd('hiding it');
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _updateOverlay() {
    if (_overlayEntry != null && _showSuggestions) {
      _overlayEntry?.remove();
      _overlayEntry = _createOverlayEntry();
      if (mounted) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    printd('suggestion on');
    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: material.Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: _buildSuggestionsOverlay(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    if (filteredSuggestions.isEmpty) return const SizedBox.shrink();
    printd("suggestioninggg");
    return MouseRegion(
      onEnter: (x) {
        isPointerInside = true;
      },
      onExit: (x) {
        isPointerInside = false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: FluentTheme.of(context).cardColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Existing entries
            if (filteredSuggestions.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = filteredSuggestions[index];
                    return HoverButton(
                      onPressed: () {
                        printd('clicked');
                        debugPrint(
                            'AutoCompleteComboBox: Selecting suggestion: $suggestion');
                        _controller.text = suggestion;
                        widget.onChanged(suggestion);
                        _hideOverlay();
                        debugPrint(
                            'AutoCompleteComboBox: Controller text set to: ${_controller.text}');
                      },
                      builder: (context, states) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          width: double.infinity,
                          color: states.isHovering
                              ? FluentTheme.of(context)
                                  .accentColor
                                  .withOpacity(0.1)
                              : Colors.transparent,
                          child: Text(
                            suggestion,
                            style: FluentTheme.of(context).typography.body,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            if (crossSuggestions.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: crossSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = crossSuggestions[index];
                    if (index == 0) {
                      return Column(
                        children: [
                          Text('عناصر مرتبطة'),
                          HoverButton(
                            onPressed: () {
                              printd('clicked');
                              debugPrint(
                                  'AutoCompleteComboBox: Selecting suggestion: $suggestion');
                              _controller.text = suggestion;
                              widget.onChanged(suggestion);
                              _hideOverlay();
                              debugPrint(
                                  'AutoCompleteComboBox: Controller text set to: ${_controller.text}');
                            },
                            builder: (context, states) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                width: double.infinity,
                                color: states.isHovering
                                    ? FluentTheme.of(context)
                                        .accentColor
                                        .withOpacity(0.1)
                                    : Colors.transparent,
                                child: Text(
                                  suggestion,
                                  style:
                                      FluentTheme.of(context).typography.body,
                                ),
                              );
                            },
                          )
                        ],
                      );
                    }
                    return HoverButton(
                      onPressed: () {
                        printd('clicked');
                        debugPrint(
                            'AutoCompleteComboBox: Selecting suggestion: $suggestion');
                        _controller.text = suggestion;
                        widget.onChanged(suggestion);
                        _hideOverlay();
                        debugPrint(
                            'AutoCompleteComboBox: Controller text set to: ${_controller.text}');
                      },
                      builder: (context, states) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          width: double.infinity,
                          color: states.isHovering
                              ? FluentTheme.of(context)
                                  .accentColor
                                  .withOpacity(0.1)
                              : Colors.transparent,
                          child: Text(
                            suggestion,
                            style: FluentTheme.of(context).typography.body,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAllSuggestions() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      switch (widget.suggestionType) {
        case AutoCompleteType.truckPlate:
          _suggestions = await _getTruckPlates();
          break;
        case AutoCompleteType.driver:
          _suggestions = await _getDriverNames();
          break;
        case AutoCompleteType.supplierClient:
          _suggestions = await _getSuppliersAndClients();
          break;
        case AutoCompleteType.client:
          _suggestions = await _getClients();
          break;
        case AutoCompleteType.supplier:
          _suggestions = await _getSuppliers();
          break;
        case AutoCompleteType.material:
          _suggestions = await _getMaterials();
          break;
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      _suggestions = [];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _getTruckPlates() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final results = await db.query(
      'driver_plates',
      columns: ['plate_number'],
      distinct: true,
      where: 'active = 1',
      orderBy: 'plate_number',
    );
    return results.map((row) => row['plate_number'] as String).toList();
  }

  Future<List<String>> _getDriverNames() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final results = await db.query(
      'drivers',
      columns: ['name'],
      where: 'active = 1',
      orderBy: 'name',
    );
    return results.map((row) => row['name'] as String).toList();
  }

  Future<List<String>> _getSuppliersAndClients() async {
    if (!mounted) return [];

    try {
      // Get providers directly without post frame callback to avoid issues
      final clientProvider =
          Provider.of<ClientProvider>(context, listen: false);
      final supplierProvider =
          Provider.of<SupplierProvider>(context, listen: false);

      // Ensure data is loaded
      if (clientProvider.clients.isEmpty) {
        await clientProvider.loadClients();
      }
      if (supplierProvider.suppliers.isEmpty) {
        await supplierProvider.loadSuppliers();
      }

      final names = <String>[];
      names.addAll(clientProvider.clients.map((client) => client.name));
      names.addAll(supplierProvider.suppliers.map((supplier) => supplier.name));

      names.sort();
      return names;
    } catch (e) {
      debugPrint('Error loading suppliers and clients: $e');
      return [];
    }
  }

  Future<List<String>> _getClients() async {
    if (!mounted) return [];

    try {
      final clientProvider =
          Provider.of<ClientProvider>(context, listen: false);

      // Ensure data is loaded
      if (clientProvider.clients.isEmpty) {
        await clientProvider.loadClients();
      }

      final names =
          clientProvider.clients.map((client) => client.name).toList();
      names.sort();
      return names;
    } catch (e) {
      debugPrint('Error loading clients: $e');
      return [];
    }
  }

  Future<List<String>> _getSuppliers() async {
    if (!mounted) return [];

    try {
      final supplierProvider =
          Provider.of<SupplierProvider>(context, listen: false);

      // Ensure data is loaded
      if (supplierProvider.suppliers.isEmpty) {
        await supplierProvider.loadSuppliers();
      }

      final names =
          supplierProvider.suppliers.map((supplier) => supplier.name).toList();
      names.sort();
      return names;
    } catch (e) {
      debugPrint('Error loading suppliers: $e');
      return [];
    }
  }

  Future<List<String>> _getMaterials() async {
    if (!mounted) return [];

    try {
      // Get provider directly without post frame callback to avoid issues
      final materialProvider =
          Provider.of<MaterialProvider>(context, listen: false);

      // Ensure data is loaded
      if (materialProvider.materials.isEmpty) {
        await materialProvider.loadMaterials();
      }

      final materials = materialProvider.materials
          .map((material) => material.name)
          .toList()
        ..sort();
      return materials;
    } catch (e) {
      debugPrint('Error loading materials: $e');
      return [];
    }
  }

  List<String> get filteredSuggestions {
    if (_controller.text.isEmpty) return _suggestions;

    final normalizedInput = normalizeArabic(_controller.text);
    return _suggestions.where((suggestion) {
      final normalizedSuggestion = normalizeArabic(suggestion);
      return normalizedSuggestion.contains(normalizedInput) ||
          suggestion.toLowerCase().contains(_controller.text.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.15,
      key: _textFieldKey,
      child: TextFormBox(
        controller: _controller,
        focusNode: _focusNode,
        placeholder: widget.placeholder,
        onChanged: (value) {
          debugPrint(
              'AutoCompleteComboBox: TextFormBox onChanged called with: $value');
          _onTextChanged(value);
          // Show overlay if we have suggestions and focus, or if user is typing

          if ((_focusNode.hasFocus && filteredSuggestions.isNotEmpty) ||
              value.isNotEmpty) {
            _showOverlay();
          } else {
            _hideOverlay();
          }
        },
        onTap: () {
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller!.text.length),
          );
          if (filteredSuggestions.isNotEmpty) {
            _showOverlay();
          }
        },
        suffix: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: ProgressRing(strokeWidth: 2),
              ),
            IconButton(
              icon: Icon(_showSuggestions
                  ? FluentIcons.chevron_up
                  : FluentIcons.chevron_down),
              onPressed: () {
                if (_showSuggestions) {
                  _hideOverlay();
                } else {
                  _showOverlay();
                  _focusNode.requestFocus();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleDriverVehicleRelationship() async {
    if (widget.suggestionType == AutoCompleteType.truckPlate) {
      // When truck plate is entered, suggest related drivers
      final value = widget.driverController?.text;
      printd('the plate is printing this1!!!!11      ' + (value ?? 'no value'));
      crossSuggestions = [];
      if (value != null && value.isNotEmpty) {
        final veichles = await _getRelatedVehicles(value);
        printd(veichles.toString());
        if (veichles.isNotEmpty) {
          printd('there is actuay a value');
          crossSuggestions = veichles;
        }
      }
    } else if (widget.suggestionType == AutoCompleteType.driver) {
      // When driver is entered, suggest related vehicles
      final value = widget.plateController?.text;
      printd('the driver is printing this1!!!!11   ' + (value ?? 'no value'));
      crossSuggestions = [];
      if (value != null && value.isNotEmpty) {
        final drivers = await _getRelatedDrivers(value);
        printd(drivers.toString());
        if (drivers.isNotEmpty) {
          crossSuggestions = drivers;
          printd(crossSuggestions.toString());
        }
      }
    }
  }

  Future<List<String>> _getRelatedDrivers(String vehiclePlate) async {
    if (vehiclePlate.isEmpty) return [];

    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    print('i am searching for values');
    final data = await db.rawQuery('SELECT * FROM drivers');
    final data3 = await db.rawQuery('SELECT * FROM driver_plates');

    String orignialQuery = '''SELECT d.name as driver_name FROM drivers d
      INNER JOIN driver_plates dp ON d.id = dp.driver_id WHERE dp.plate_number = ?''';

    //WHERE dp.plate_number = ? AND dp.active = 1 AND d.active = 1
    final results = await db.rawQuery('''
      SELECT d.name as driver_name FROM drivers d
      INNER JOIN driver_plates dp ON d.id = dp.driver_id WHERE dp.plate_number = ?
      
    ''', [vehiclePlate]);
    printd(results.toString());
    return results.map((row) => row['driver_name'] as String).toList();
  }

  Future<List<String>> _getRelatedVehicles(String driverName) async {
    if (driverName.isEmpty) return [];
    print('I am searching for value');
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final results = await db.rawQuery('''
      SELECT DISTINCT dp.plate_number as vehicle_plate FROM driver_plates dp
      INNER JOIN drivers d ON d.id = dp.driver_id
      WHERE d.name = ? AND dp.active = 1 AND d.active = 1
    ''', [driverName]);
    return results.map((row) => row['vehicle_plate'] as String).toList();
  }

  void _showDriverSuggestions(List<String> drivers) {
    // This would trigger a callback to suggest drivers for the current vehicle
    debugPrint('Related drivers for vehicle: $drivers');
  }

  void _showVehicleSuggestions(List<String> vehicles) {
    // This would trigger a callback to suggest vehicles for the current driver
    debugPrint('Related vehicles for driver: $vehicles');
  }
}
