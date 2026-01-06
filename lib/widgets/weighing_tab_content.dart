import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:weighing_system/animated_widgets/animated_icon.dart';
import 'package:weighing_system/database/database_helper.dart';
import 'package:weighing_system/models/print_template.dart';
import 'package:weighing_system/models/user.dart';
import 'package:weighing_system/providers/client_provider.dart';
import 'package:weighing_system/providers/driver_plate_provider.dart';
import 'package:weighing_system/providers/material_provider.dart';
import 'package:weighing_system/providers/supplier_provider.dart';
import 'package:weighing_system/providers/user_provider.dart';
import 'package:weighing_system/services/custom_template_service.dart';
import 'package:weighing_system/theme/app_theme.dart';
import 'package:weighing_system/widgets/kilo_price_box.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../models/weighing_tab.dart';
import '../providers/weight_provider.dart';
import '../providers/tabs_provider.dart';
import '../services/template_print_service.dart';
import '../utils/date_format.dart';
import '../utils/debugging_methods.dart';
import 'auto_complete_combo_box.dart';

// Text size constants for easy adjustment
const double kStatusFontSize = 7.0;
const double kWeightValueFontSize = 20.0;
const double kWeightUnitFontSize = 14.0;
const double kLabelFontSize = 16.0;
const double kButtonFontSize = 12.5;
const double kFinalButtonFontSize = 16;
const double kIconSize = 12.0;

class WeighingTabContent extends StatefulWidget {
  final int tabIndex;

  const WeighingTabContent({
    super.key,
    required this.tabIndex,
  });

  @override
  State<WeighingTabContent> createState() => _WeighingTabContentState();
}

class _WeighingTabContentState extends State<WeighingTabContent>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _emptyWeightController;
  late TextEditingController _grossWeightController;
  late TextEditingController _truckPlateController;
  late TextEditingController _driverNameController;
  late TextEditingController _clientController;
  late TextEditingController _supplierController;
  late TextEditingController _materialController;
  late TextEditingController _kiloPriceController;
  late TextEditingController _notesController;
  late TextEditingController _totalPriceController;
  final TemplatePrintService _printService = TemplatePrintService();
  final CustomTemplateService _templateService = CustomTemplateService();
  late TabsProvider myProvider;
  bool isPaid = false;
  bool printPrice = false;

  Timer? _emptyWeightDebounceTimer;
  Timer? _grossWeightDebounceTimer;
  bool _emptyWeightFieldFocused = false;
  bool _grossWeightFieldFocused = false;

  // Track last synced values to avoid unnecessary updates
  WeighingTab? _lastSyncedTab;
  bool _isUpdatingControllers = false;
  final controller = FlyoutController();

  WeighingTab? get _tab {
    final provider = context.read<TabsProvider>();
    return widget.tabIndex < provider.tabs.length
        ? provider.tabs[widget.tabIndex]
        : null;
  }

  //printing
  Future<void> printPDF() async {
    PrintTemplate? defaultTemplate =
        await _templateService.getDefaultTemplate();
    if (defaultTemplate != null) {
      await _printService.printTemplateStandardPDFNewSilently(
          defaultTemplate, _tab!, null, null, null);
    } else {
      if (mounted) {
        _showInfoBar(AppLocalizations.of(context)!.couldNotFindTemplate,
            InfoBarSeverity.error);
      }
    }
  }

  Future<void> savePDF() async {
    PrintTemplate? defaultTemplate =
        await _templateService.getDefaultTemplate();
    if (defaultTemplate != null) {
      await _printService.saveTemplateStandardPDFNewSilently(
          defaultTemplate, _tab!, null, null, null);
    } else {
      if (mounted) {
        _showInfoBar(AppLocalizations.of(context)!.couldNotFindTemplate,
            InfoBarSeverity.error);
      }
    }
  }

  void _onKiloPriceChanged() {
    final value = num.tryParse(_kiloPriceController.text);
    myProvider = Provider.of<TabsProvider>(context, listen: false);
    myProvider.updateTab(widget.tabIndex, {'kilo_price': value});
    calculateTotalPrice();
    debugPrint("Text changed: $value");
  }

  void _onTotalPriceChanged() {
    final value = num.tryParse(_totalPriceController.text);
    myProvider = Provider.of<TabsProvider>(context, listen: false);
    myProvider.updateTab(widget.tabIndex, {'total_price': value});
    debugPrint("Text changed: $value");
  }

  @override
  void initState() {
    super.initState();
    final tab = _tab;
    // creation date load

    //
    _emptyWeightController = TextEditingController(
      text: tab?.emptyWeight != null && tab!.emptyWeight > 0
          ? tab.emptyWeight.toString()
          : '',
    );
    _grossWeightController = TextEditingController(
      text: tab?.grossWeight != null && tab!.grossWeight > 0
          ? tab.grossWeight.toString()
          : '',
    );
    myProvider = Provider.of<TabsProvider>(context, listen: false);
    _truckPlateController = TextEditingController(text: tab?.truckPlate ?? '');
    _driverNameController = TextEditingController(text: tab?.driverName ?? '');
    _clientController = TextEditingController(text: tab?.client ?? '');
    _supplierController = TextEditingController(text: tab?.supplier ?? '');
    _materialController = TextEditingController(text: tab?.material ?? '');
    _notesController = TextEditingController(text: tab?.notes ?? '');
    _kiloPriceController = TextEditingController(
        text: tab?.kilo_price.toStringAsFixed(2) ?? (0.0).toStringAsFixed(2));
    _totalPriceController = TextEditingController(
        text: tab?.total_price.toStringAsFixed(2) ?? (0.0).toStringAsFixed(2));
    _kiloPriceController.addListener(_onKiloPriceChanged);
    _totalPriceController.addListener(_onTotalPriceChanged);

    // Initialize last synced tab
    _lastSyncedTab = tab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchAllNewValues();
    });
  }

  /// Sync controllers with tab data efficiently
  void _syncControllersWithTab(WeighingTab tab) {
    if (_isUpdatingControllers) return;

    // Check if tab data has actually changed
    if (_lastSyncedTab != null && _tabDataEquals(_lastSyncedTab!, tab)) {
      return;
    }

    _isUpdatingControllers = true;

    try {
      // Update weight controllers only if not focused
      if (!_emptyWeightFieldFocused) {
        final emptyWeightText =
            tab.emptyWeight > 0 ? tab.emptyWeight.toString() : '';
        if (_emptyWeightController.text != emptyWeightText) {
          _emptyWeightController.text = emptyWeightText;
        }
      }

      if (!_grossWeightFieldFocused) {
        final grossWeightText =
            tab.grossWeight > 0 ? tab.grossWeight.toString() : '';
        if (_grossWeightController.text != grossWeightText) {
          _grossWeightController.text = grossWeightText;
        }
      }

      // Update business field controllers
      if (_truckPlateController.text != tab.truckPlate) {
        _truckPlateController.text = tab.truckPlate;
      }
      if (_driverNameController.text != tab.driverName) {
        _driverNameController.text = tab.driverName;
      }
      if (_clientController.text != tab.client) {
        _clientController.text = tab.client;
      }
      if (_supplierController.text != tab.supplier) {
        _supplierController.text = tab.supplier;
      }
      if (_materialController.text != tab.material) {
        _materialController.text = tab.material;
      }

      _lastSyncedTab = tab;
    } finally {
      _isUpdatingControllers = false;
    }
  }

  /// Check if tab data has meaningfully changed
  bool _tabDataEquals(WeighingTab tab1, WeighingTab tab2) {
    return tab1.emptyWeight == tab2.emptyWeight &&
        tab1.grossWeight == tab2.grossWeight &&
        tab1.truckPlate == tab2.truckPlate &&
        tab1.driverName == tab2.driverName &&
        tab1.client == tab2.client &&
        tab1.supplier == tab2.supplier &&
        tab1.material == tab2.material &&
        tab1.kilo_price == tab2.kilo_price &&
        tab1.total_price == tab2.total_price;
  }

  // fetch all new values
  void fetchAllNewValues() {
    context.read<ClientProvider>().loadClients();
    context.read<SupplierProvider>().loadSuppliers();
    context.read<DriverPlateProvider>().loadDriverPlates();
    context.read<MaterialProvider>().loadMaterials();
  }

  @override
  void dispose() {
    // Cancel timers first to prevent any pending operations
    _emptyWeightDebounceTimer?.cancel();
    _emptyWeightDebounceTimer = null;
    _grossWeightDebounceTimer?.cancel();
    _grossWeightDebounceTimer = null;

    // Remove listeners before disposing controllers
    _kiloPriceController.removeListener(_onKiloPriceChanged);
    _totalPriceController.removeListener(_onTotalPriceChanged);

    // Dispose all controllers
    _emptyWeightController.dispose();
    _grossWeightController.dispose();
    _truckPlateController.dispose();
    _driverNameController.dispose();
    _clientController.dispose();
    _supplierController.dispose();
    _materialController.dispose();
    _kiloPriceController.dispose();
    _totalPriceController.dispose();

    super.dispose();
  }

  void _onEmptyWeightChanged(String value) {
    _emptyWeightDebounceTimer?.cancel();
    _emptyWeightDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        try {
          final weight = int.tryParse(value) ?? 0;
          context
              .read<TabsProvider>()
              .updateTab(widget.tabIndex, {'emptyWeight': weight});
          context
              .read<TabsProvider>()
              .updateTab(widget.tabIndex, {'scaleEmptyWeight': null});
          calculateTotalPrice();
        } catch (e) {
          debugPrint('WeighingTabContent: Error updating empty weight: $e');
        }
      }
    });
  }

  void _onGrossWeightChanged(String value) {
    _grossWeightDebounceTimer?.cancel();
    _grossWeightDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        try {
          final weight = int.tryParse(value) ?? 0;
          context
              .read<TabsProvider>()
              .updateTab(widget.tabIndex, {'grossWeight': weight});
          //TODO
          context
              .read<TabsProvider>()
              .updateTab(widget.tabIndex, {'scaleGrossWeight': null});

          calculateTotalPrice();
        } catch (e) {
          debugPrint('WeighingTabContent: Error updating gross weight: $e');
        }
      }
    });
  }

  //get material price once
  Future<void> getMaterialLogic() async {
    final datahelper = DatabaseHelper();
    final data = await datahelper.query(
      'materials',
      columns: ['price'],
      where: "name = ?",
      whereArgs: [_tab?.material],
    );
    if (data.isNotEmpty) {
      final price = data[0]['price'] ?? 0.0;
      _kiloPriceController.text = price.toStringAsFixed(3);
      _tab?.kilo_price = price; // or as double/int
      debugPrint('Price: $price');
    } else {
      debugPrint('No material found for ${_tab?.material}');
    }
  }

  void calculateTotalPrice() {
    if (_tab!.netWeight != 0) {
      num? kiloPrice = num.tryParse(_kiloPriceController.text);
      if (kiloPrice != null) {
        debugPrint('Calculating total price');
        num totalPrice = kiloPrice * _tab!.netWeight;
        _totalPriceController.text = totalPrice.toStringAsFixed(2);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // final l10n = AppLocalizations.of(context)!;

    return Consumer<TabsProvider>(
      builder: (context, tabsProvider, child) {
        final tab = widget.tabIndex < tabsProvider.tabs.length
            ? tabsProvider.tabs[widget.tabIndex]
            : null;

        if (tab == null) {
          return Center(
            child: Text(AppLocalizations.of(context)!.tabNotFound),
          );
        }

        // Sync controllers efficiently
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncControllersWithTab(tab);
        });

        return Consumer<UserProvider>(
          builder: (BuildContext context, UserProvider value, Widget? child) {
            final enabled =
                value.activeUser?.type == UserRanks.admin ? true : false;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Weight Information
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: SizedBox(
                                  width: 150,
                                  height: 30,
                                  child: InfoBadge(
                                      source: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'الرقم',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(
                                        width: 2,
                                      ),
                                      Text(
                                        _tab?.id?.toString() ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  )),
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Expanded(
                                flex: 6,
                                child: SizedBox(
                                  height: 30,
                                  child: InfoBadge(
                                    color: Colors.green.withValues(alpha: 0.5),
                                    source: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dateToArabicDatetimeWeightTab(
                                              _tab!.createdAt),
                                          style:
                                              const TextStyle(fontSize: 13.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          // Empty Weight
                          _buildWeightField(
                            isEmptyWeight: false,
                            enabled: enabled,
                            label: AppLocalizations.of(context)!.grossWeightKg,
                            controller: _grossWeightController,
                            onChanged: _onGrossWeightChanged,
                            //TODO MOCK MOCK MOCK
                            onScalePressed: () =>
                                _captureWeightFromScale(false),
                            onFocusChanged: (focused) => setState(
                                () => _grossWeightFieldFocused = focused),
                          ),
                          const SizedBox(height: 4),
                          _buildWeightField(
                            enabled: enabled,
                            label: AppLocalizations.of(context)!.emptyWeightKg,
                            controller: _emptyWeightController,
                            onChanged: _onEmptyWeightChanged,
                            onScalePressed: () => _captureWeightFromScale(true),
                            onFocusChanged: (focused) => setState(
                                () => _emptyWeightFieldFocused = focused),
                          ),

                          // Gross Weight

                          const SizedBox(height: 4),

                          // Net Weight (calculated)
                          _buildCalculatedWeight(
                            label: AppLocalizations.of(context)!.netWeightKg,
                            value: tab.netWeight,
                          ),
                          const SizedBox(height: 4),

                          const SizedBox(height: 30),
                          RepaintBoundary(child: _buildLockSection())

                          // Operation type removed from schema
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Right Column - Business Information
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Truck Plate
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                children: [
                                  _buildLabel(AppLocalizations.of(context)!
                                      .truckPlateRequired),
                                  const SizedBox(height: 4),
                                  AutoCompleteComboBox(
                                    placeholder: AppLocalizations.of(context)!
                                        .enterTruckPlate,
                                    value: tab.truckPlate,
                                    controller: _truckPlateController,
                                    onChanged: (value) {
                                      tabsProvider.updateTab(widget.tabIndex,
                                          {'truckPlate': value});
                                    },
                                    suggestionType: AutoCompleteType.truckPlate,
                                    driverController: _driverNameController,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Column(
                                children: [
                                  _buildLabel(
                                      AppLocalizations.of(context)!.driverName +
                                          ' ' +
                                          '(مطلوب)'),
                                  const SizedBox(height: 4),
                                  AutoCompleteComboBox(
                                    placeholder: AppLocalizations.of(context)!
                                        .enterDriverName,
                                    value: tab.driverName,
                                    controller: _driverNameController,
                                    onChanged: (value) {
                                      tabsProvider.updateTab(widget.tabIndex,
                                          {'driverName': value});
                                    },
                                    suggestionType: AutoCompleteType.driver,
                                    plateController: _truckPlateController,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                children: [
                                  _buildLabel(
                                      AppLocalizations.of(context)!.client +
                                          ' ' +
                                          '(مطلوب)'),
                                  const SizedBox(height: 4),
                                  AutoCompleteComboBox(
                                    placeholder: AppLocalizations.of(context)!
                                        .selectCustomer,
                                    value: tab.client,
                                    controller: _clientController,
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        // Clear supplier when client is set
                                        _supplierController.text = '';
                                        tabsProvider
                                            .updateTab(widget.tabIndex, {
                                          'client': value,
                                          'supplier': '',
                                        });
                                      } else {
                                        tabsProvider.updateTab(
                                            widget.tabIndex, {'client': value});
                                      }
                                    },
                                    suggestionType: AutoCompleteType.client,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Column(
                                children: [
                                  _buildLabel(
                                      AppLocalizations.of(context)!.supplier +
                                          ' ' +
                                          '(مطلوب)'),
                                  const SizedBox(height: 4),
                                  AutoCompleteComboBox(
                                    placeholder: AppLocalizations.of(context)!
                                        .selectSupplier,
                                    value: tab.supplier,
                                    controller: _supplierController,
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        // Clear client when supplier is set
                                        _clientController.text = '';
                                        tabsProvider
                                            .updateTab(widget.tabIndex, {
                                          'supplier': value,
                                          'client': '',
                                        });
                                      } else {
                                        tabsProvider.updateTab(widget.tabIndex,
                                            {'supplier': value});
                                      }
                                    },
                                    suggestionType: AutoCompleteType.supplier,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _buildLabel(AppLocalizations.of(context)!
                                          .materialRequired +
                                      ' ' +
                                      '(مطلوب)'),
                                  const SizedBox(height: 4),
                                  AutoCompleteComboBox(
                                    placeholder: AppLocalizations.of(context)!
                                        .selectMaterial,
                                    value: tab.material,
                                    controller: _materialController,
                                    onChanged: (value) async {
                                      tabsProvider.updateTab(
                                          widget.tabIndex, {'material': value});
                                      if (_materialController.text.isNotEmpty) {
                                        await getMaterialLogic();
                                      }
                                    },
                                    suggestionType: AutoCompleteType.material,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              KiloPriceBox(
                                  controller: _kiloPriceController,
                                  onChange: (v) {
                                    calculateTotalPrice();
                                  }),
                              // Column(
                              //   mainAxisAlignment: MainAxisAlignment.start,
                              //   children: [
                              //
                              //   ],
                              // ),
                              const SizedBox(
                                width: 5,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  TotalPriceBox(
                                      controller: _totalPriceController,
                                      onChange: (v) {}),
                                ],
                              )
                            ],
                          ), // Material

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              _buildLabel(AppLocalizations.of(context)!.notes),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.30,
                                child: TextBox(
                                    controller: _notesController,
                                    onChanged: (v) {
                                      tabsProvider.updateTab(
                                          widget.tabIndex, {'notes': v});
                                    }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Payment Status
                          ToggleSwitch(
                            checked: tab.isPaid,
                            onChanged: (value) {
                              tabsProvider.updateTab(
                                  widget.tabIndex, {'isPaid': value});
                            },
                            content: Text(AppLocalizations.of(context)!.paid),
                          ),
                          const SizedBox(height: 8),

                          // Show Price on Print
                          ToggleSwitch(
                            checked: tab.showPriceOnPrint,
                            onChanged: (value) {
                              tabsProvider.updateTab(
                                  widget.tabIndex, {'showPriceOnPrint': value});
                            },
                            content: Text(
                                AppLocalizations.of(context)!.showPriceOnPrint),
                          ),
                          const SizedBox(height: 12),

                          // Action Buttons
                          _buildActionButtons(tab),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWeightField(
      {required String label,
      required TextEditingController controller,
      required ValueChanged<String> onChanged,
      required VoidCallback onScalePressed,
      required ValueChanged<bool> onFocusChanged,
      bool enabled = true,
      bool isEmptyWeight = true}) {
    bool canCaptureWeight() {
      bool notLocked = !_tab!.isLocked;
      if (notLocked) return true;
      if (isEmptyWeight && !notLocked && _tab!.scaleEmptyWeightAt != null) {
        if (_tab!.scaleGrossWeightAt != null) {
          if (_tab!.scaleGrossWeightAt!.isBefore(_tab!.scaleEmptyWeightAt!)) {
            return true;
          }
        }
        return false;
      }
      if (!isEmptyWeight && !notLocked && _tab!.scaleGrossWeightAt != null) {
        if (_tab!.scaleEmptyWeightAt != null) {
          if (_tab!.scaleEmptyWeightAt!.isBefore(_tab!.scaleGrossWeightAt!)) {
            return true;
          }
        }
        return false;
      }
      return true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Focus(
                onFocusChange: onFocusChanged,
                child: TextFormBox(
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  enabled: enabled,
                  controller: controller,
                  placeholder: '0',
                  onChanged: onChanged,
                  suffix: Text(AppLocalizations.of(context)!.kg),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      // Prevent negative values
                      if (newValue.text.startsWith('-')) {
                        return oldValue;
                      }
                      // Prevent multiple decimal points
                      if (newValue.text.split('.').length > 2) {
                        return oldValue;
                      }
                      return newValue;
                    }),
                  ],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Consumer<WeightProvider>(
              builder: (context, weightProvider, child) {
                return IconButton(
                  icon: Icon(
                    FluentIcons.scale_volume,
                    color:
                        weightProvider.isConnected ? Colors.green : Colors.grey,
                  ),
                  onPressed: weightProvider.isConnected && canCaptureWeight()
                      ? onScalePressed
                      : null,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _mockBuildWeightField(
      {required String label,
      required TextEditingController controller,
      required ValueChanged<String> onChanged,
      required VoidCallback onScalePressed,
      required ValueChanged<bool> onFocusChanged,
      bool enabled = true,
      bool isEmptyWeight = true}) {
    bool canCaptureWeight() {
      bool notLocked = !_tab!.isLocked;
      if (notLocked) return true;
      if (isEmptyWeight && !notLocked && _tab!.scaleEmptyWeightAt != null) {
        if (_tab!.scaleGrossWeightAt != null) {
          if (_tab!.scaleGrossWeightAt!.isBefore(_tab!.scaleEmptyWeightAt!)) {
            return true;
          }
        }
        return false;
      }
      if (!isEmptyWeight && !notLocked && _tab!.scaleGrossWeightAt != null) {
        if (_tab!.scaleEmptyWeightAt != null) {
          if (_tab!.scaleEmptyWeightAt!.isBefore(_tab!.scaleGrossWeightAt!)) {
            return true;
          }
        }
        return false;
      }
      return true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Focus(
                onFocusChange: onFocusChanged,
                child: TextFormBox(
                  enabled: enabled,
                  controller: controller,
                  placeholder: '0',
                  onChanged: onChanged,
                  suffix: Text(AppLocalizations.of(context)!.kg),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      // Prevent negative values
                      if (newValue.text.startsWith('-')) {
                        return oldValue;
                      }
                      // Prevent multiple decimal points
                      if (newValue.text.split('.').length > 2) {
                        return oldValue;
                      }
                      return newValue;
                    }),
                  ],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Consumer<WeightProvider>(
              builder: (context, weightProvider, child) {
                return IconButton(
                  icon: Icon(
                    FluentIcons.scale_volume,
                    color:
                        weightProvider.isConnected ? Colors.green : Colors.grey,
                  ),
                  onPressed: canCaptureWeight() ? onScalePressed : null,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalculatedWeight({
    required String label,
    required int value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: kWeightValueFontSize,
                  fontWeight: FontWeight.w600,
                  color: value > 0 ? Colors.green : Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.kg,
                style: const TextStyle(
                    color: Colors.grey, fontSize: kWeightUnitFontSize),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppTheme.kLabelsStyleWT);
  }

  Widget _buildActionButtons(WeighingTab tab) {
    // final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Button(
                onPressed: () => printPDF(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FluentIcons.print, size: kIconSize),
                    const SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.print,
                        style: const TextStyle(fontSize: kButtonFontSize)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Button(
                onPressed: () => savePDF(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FluentIcons.print, size: kIconSize),
                    const SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.savePDF,
                        style: const TextStyle(fontSize: kButtonFontSize)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: tab.isComplete ? () => _completeTab() : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        tab.isComplete
                            ? FluentIcons.completed
                            : FluentIcons.clear,
                        size: kIconSize),
                    const SizedBox(width: 6),
                    Text(
                        tab.isComplete
                            ? AppLocalizations.of(context)!.complete
                            : AppLocalizations.of(context)!.incomplete,
                        style: const TextStyle(fontSize: kFinalButtonFontSize)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLockSection() {
    printd(_tab!.canLock.toString());
    printd(_tab!.isLocked.toString());
    if (!_tab!.canLock) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SimpleAnimatedIcon(),
          Text(
            'يا أبو صطيف اذا اجاك بيرين حط الوزن الإجمالي بالاول و بعدا اسم المورد و رح يطلعلك زر حفظ هون لازم تكبسو',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    if (!_tab!.isLocked) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: FilledButton(
            child: const Text(
              'حفظ',
              style: TextStyle(fontSize: 20),
            ),
            onPressed: () {
              context.read<TabsProvider>().lockTab(widget.tabIndex);
            }),
      );
    }

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SimpleAnimatedIcon(),
        Text(
          'بس تخلص تعباية كبوس على حفظ نهائي ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _captureWeightFromScale(bool isEmptyWeight) {
    final weightProvider = context.read<WeightProvider>();
    if (!weightProvider.isConnected) {
      _showInfoBar(AppLocalizations.of(context)!.scaleMustBeConnected,
          InfoBarSeverity.warning);
      return;
    }

    final currentWeight = weightProvider.displayWeight;
    final tabsProvider = context.read<TabsProvider>();

    if (isEmptyWeight && !_emptyWeightFieldFocused) {
      _emptyWeightController.text = currentWeight.toString();
      tabsProvider.updateTab(widget.tabIndex, {'emptyWeight': currentWeight});
      tabsProvider
          .updateTab(widget.tabIndex, {'scaleEmptyWeight': DateTime.now()});
    } else if (!isEmptyWeight && !_grossWeightFieldFocused) {
      _grossWeightController.text = currentWeight.toString();
      tabsProvider.updateTab(widget.tabIndex, {'grossWeight': currentWeight});
      tabsProvider
          .updateTab(widget.tabIndex, {'scaleGrossWeight': DateTime.now()});
      calculateTotalPrice();
    } else {
      _showInfoBar(AppLocalizations.of(context)!.cannotCaptureWhileEditing,
          InfoBarSeverity.warning);
      return;
    }
  }

  void _mockCaptureWeightFromScale(bool isEmptyWeight) {
    final tabsProvider = context.read<TabsProvider>();

    if (isEmptyWeight && !_emptyWeightFieldFocused) {
      _emptyWeightController.text = 4000.toString();
      tabsProvider.updateTab(widget.tabIndex, {'emptyWeight': 4000});
      tabsProvider
          .updateTab(widget.tabIndex, {'scaleEmptyWeight': DateTime.now()});
    } else if (!isEmptyWeight && !_grossWeightFieldFocused) {
      _grossWeightController.text = 5000.toString();
      tabsProvider.updateTab(widget.tabIndex, {'grossWeight': 5000});
      tabsProvider
          .updateTab(widget.tabIndex, {'scaleGrossWeight': DateTime.now()});
      calculateTotalPrice();
    } else {
      _showInfoBar(AppLocalizations.of(context)!.cannotCaptureWhileEditing,
          InfoBarSeverity.warning);
      return;
    }
  }

  void _cancelTab() {
    final tabsProvider = context.read<TabsProvider>();
    tabsProvider.cancelTab(widget.tabIndex);
    _showInfoBar(
        AppLocalizations.of(context)!.tabCancelled, InfoBarSeverity.info);
  }

  void _completeTab() async {
    final tabsProvider = context.read<TabsProvider>();
    final success = await tabsProvider.completeTab(widget.tabIndex);
    if (success && mounted) {
      _showInfoBar(AppLocalizations.of(context)!.tabCompletedAndMoved,
          InfoBarSeverity.success);
      fetchAllNewValues();
    } else {
      if (mounted) {
        _showInfoBar(AppLocalizations.of(context)!.unableToCompleteTab,
            InfoBarSeverity.error);
      }
    }
  }

  void _showInfoBar(String message, InfoBarSeverity severity) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(message),
        severity: severity,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
