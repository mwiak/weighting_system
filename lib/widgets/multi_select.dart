import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:weighing_system/utils/debugging_methods.dart';
import '../l10n/app_localizations.dart';
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
  client, // For customers only
  supplier, // For suppliers only
  material,
}

class MultiSelect extends StatefulWidget {
  final String placeholder;
  final List<String> passedList;
  final Function onSelect;
  final Function onDeselect;
  final ValueChanged<String> onChanged;
  final AutoCompleteType suggestionType;

  const MultiSelect({
    super.key,
    required this.placeholder,
    required this.passedList,
    required this.onChanged,
    required this.suggestionType,
    required this.onSelect,
    required this.onDeselect,
  });

  @override
  State<MultiSelect> createState() => _MultiSelectState();
}

class _MultiSelectState extends State<MultiSelect> {
  TextEditingController newController = TextEditingController();

  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;
  List<String> selectedItems = [];

  bool isPointerInside = false;

  @override
  void initState() {
    super.initState();

    // Listen to controller changes for immediate UI updates
    newController.addListener(_onControllerChanged);

    // Load suggestions after the build to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAllSuggestions();
      }
    });
  }

  @override
  void didUpdateWidget(MultiSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestionType != widget.suggestionType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) resetWidget();
      });
    }
  }

  void resetWidget() async {
    printd('reseting in !!!!!');
    selectedItems = [];
    await _loadAllSuggestions();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _debounceTimer?.cancel();
    newController.removeListener(_onControllerChanged);

    newController.dispose();

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

  void _handleFocusChange() {
    if (_focusNode.hasFocus && !_showSuggestions) {
      _showOverlay();
    } else if (!_focusNode.hasFocus && _showSuggestions) {
      // Fixed: Hide overlay when focus is lost AND overlay is showing
      if (!_focusNode.hasFocus && !isPointerInside) {
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
            'AutoCompleteFilterComboBox: Debounced onChanged called with: $value');
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
          child: MouseRegion(
            onEnter: (v) {
              isPointerInside = true;
            },
            onExit: (v) {
              isPointerInside = false;
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _buildSuggestionsOverlay(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    if (filteredSuggestions.isEmpty) return const SizedBox.shrink();
    printd("suggestioninggg");
    return Container(
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: StatefulBuilder(builder: (context, updateOverlay) {
        return Column(
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
                    return ListTile.selectable(
                        title: Text(suggestion),
                        selected: selectedItems.contains(suggestion),
                        selectionMode: ListTileSelectionMode.multiple,
                        onSelectionChange: (selected) {
                          updateOverlay(() {
                            if (selected) {
                              selectedItems.add(suggestion);
                              widget.onSelect(suggestion);
                            } else {
                              selectedItems.remove(suggestion);
                              widget.onDeselect(suggestion);
                            }
                          });
                        });
                  },
                ),
              ),

            // Add new entry option
          ],
        );
      }),
    );
  }

  Future<void> _loadAllSuggestions() async {
    if (!mounted) return;

    _isLoading = true;

    try {
      switch (widget.suggestionType) {
        case AutoCompleteType.truckPlate:
          _suggestions = await _getTruckPlates();
          break;
        case AutoCompleteType.driver:
          _suggestions = await _getDriverNames();
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
      printd('it is mounted!!!!!');

      _isLoading = false;

      printd('set state was called');
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
    if (newController.text.isEmpty) return _suggestions;

    final normalizedInput = normalizeArabic(newController.text);
    printd('start filtering');
    return _suggestions.where((suggestion) {
      final normalizedSuggestion = normalizeArabic(suggestion);
      return normalizedSuggestion.contains(normalizedInput) ||
          suggestion.toLowerCase().contains(newController.text.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Container(
        key: _textFieldKey,
        child: TextFormBox(
          controller: newController,
          focusNode: _focusNode,
          placeholder: widget.placeholder,
          onChanged: (value) {
            debugPrint(
                'AutoCompleteFilterComboBox: TextFormBox onChanged called with: $value');
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
      ),
    );
  }
}
