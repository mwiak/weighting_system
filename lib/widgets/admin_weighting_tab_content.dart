import 'package:fluent_ui/fluent_ui.dart';

import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:weighing_system/database/database_helper.dart';
import 'package:weighing_system/models/print_template.dart';
import 'package:weighing_system/services/custom_template_service.dart';
import 'package:weighing_system/utils/date_format.dart';
import 'package:weighing_system/utils/debugging_methods.dart';
import 'package:weighing_system/widgets/kilo_price_box.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../models/weighing_tab.dart';
import '../providers/weight_provider.dart';
import '../providers/tabs_provider.dart';
import '../services/template_print_service.dart';
import 'DatePickerWithTime.dart';
import 'auto_complete_combo_box.dart';

// Text size constants for easy adjustment
const double kStatusFontSize = 7.0;
const double kWeightValueFontSize = 12.0;
const double kWeightUnitFontSize = 10.0;
const double kLabelFontSize = 13.0;
const double kButtonFontSize = 12.5;
const double kIconSize = 12.0;

class AdminWeightingTabContent extends StatefulWidget {
  WeighingTab? tab;
  AdminWeightingTabContent({super.key, this.tab});

  @override
  State<AdminWeightingTabContent> createState() =>
      _AdminWeightingTabContentState();
}

class _AdminWeightingTabContentState extends State<AdminWeightingTabContent> {
  DateTime? creationDate = DateTime.now();
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
  bool isEditing = false;

  Timer? _emptyWeightDebounceTimer;
  Timer? _grossWeightDebounceTimer;
  bool _emptyWeightFieldFocused = false;
  bool _grossWeightFieldFocused = false;

  // Track last synced values to avoid unnecessary updates
  WeighingTab? _lastSyncedTab;
  bool _isUpdatingControllers = false;

  WeighingTab? get _tab {
    final provider = context.read<TabsProvider>();
    final tab = provider.manualActiveTab;
    return tab;
  }

  //printing
  Future<void> printPDF() async {
    PrintTemplate? defaultTemplate =
        await _templateService.getDefaultTemplate();
    if (defaultTemplate != null) {
      await _printService.printTemplateStandardPDFNewSilently(
          defaultTemplate, _tab!, null, null, null);
    } else {
      _showInfoBar(AppLocalizations.of(context)!.couldNotFindTemplate,
          InfoBarSeverity.error);
    }
  }

  Future<void> savePDF() async {
    PrintTemplate? defaultTemplate =
        await _templateService.getDefaultTemplate();
    if (defaultTemplate != null) {
      await _printService.saveTemplateStandardPDFNewSilently(
          defaultTemplate, _tab!, null, null, null);
    } else {
      _showInfoBar(AppLocalizations.of(context)!.couldNotFindTemplate,
          InfoBarSeverity.error);
    }
  }

  void _onKiloPriceChanged() {
    final value = num.tryParse(_kiloPriceController.text);
    myProvider = Provider.of<TabsProvider>(context, listen: false);
    myProvider.updateManualTab(0, {'kilo_price': value});
    calculateTotalPrice();
    debugPrint("Text changed: $value");
  }

  void _onTotalPriceChanged() {
    final value = num.tryParse(_totalPriceController.text);
    myProvider = Provider.of<TabsProvider>(context, listen: false);
    myProvider.updateManualTab(0, {'total_price': value});
    debugPrint("Text changed: $value");
  }

  @override
  void initState() {
    super.initState();
    if (widget.tab != null) isEditing = true;
    printd(isEditing.toString());
    final tab = widget.tab ?? _tab;

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
    _notesController.dispose();
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
              .updateManualTab(0, {'emptyWeight': weight});
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
              .updateManualTab(0, {'grossWeight': weight});
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
    final l10n = AppLocalizations.of(context)!;

    return ContentDialog(
      constraints: BoxConstraints(minHeight: 400, minWidth: 500),
      actions: [
        Button(
            child: Text(l10n.cancel),
            onPressed: () {
              context.read<TabsProvider>();
              Navigator.of(context).pop();
            })
      ],
      content: Consumer<TabsProvider>(
        builder: (context, tabsProvider, child) {
          final tab = tabsProvider.manualActiveTab;

          if (tab == null) {
            return Center(
              child: Text(AppLocalizations.of(context)!.tabNotFound),
            );
          }

          // Sync controllers efficiently
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncControllersWithTab(tab);
          });

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
                        isEditing
                            ? Row(
                                children: [
                                  Text(
                                    _formatStatus(_tab!.status),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(_tab!.status),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  ComboBox(
                                      placeholder: Text('تغيير الحالة'),
                                      onChanged: (v) {
                                        if (v != null) {
                                          tabsProvider.manualActiveTab?.status =
                                              v;
                                          setState(() {});
                                        }
                                      },
                                      items: [
                                        ComboBoxItem(
                                            value: 'completed',
                                            child: Text(
                                                _formatStatus('completed'))),
                                        ComboBoxItem(
                                            value: 'cancelled',
                                            child: Text(
                                                _formatStatus('cancelled'))),
                                      ])
                                ],
                              )
                            : SizedBox.shrink(),
                        Text(dateToArabicDatetimeOperationEntry(creationDate!)),
                        SizedBox(
                          height: 10,
                        ),
                        Button(
                            child: Text('تغيير التاريخ و الوقت'),
                            onPressed: () {
                              openDateTimePicker(context, creationDate!, (v) {
                                creationDate = v;
                                tabsProvider.updateManualTab(
                                    1, {'createdAt': creationDate});
                              });
                            }),
                        SizedBox(
                          height: 10,
                        ),
                        // Empty Weight
                        _buildWeightField(
                          label: AppLocalizations.of(context)!.grossWeightKg,
                          controller: _grossWeightController,
                          onChanged: _onGrossWeightChanged,
                          onScalePressed: () => {},
                          onFocusChanged: (focused) => setState(
                              () => _grossWeightFieldFocused = focused),
                        ),
                        const SizedBox(height: 4),
                        _buildWeightField(
                          label: AppLocalizations.of(context)!.emptyWeightKg,
                          controller: _emptyWeightController,
                          onChanged: _onEmptyWeightChanged,
                          onScalePressed: () => {},
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
                                    tabsProvider.updateManualTab(
                                        0, {'truckPlate': value});
                                  },
                                  suggestionType: AutoCompleteType.truckPlate,
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Column(
                              children: [
                                _buildLabel(
                                    AppLocalizations.of(context)!.driverName),
                                const SizedBox(height: 4),
                                AutoCompleteComboBox(
                                  placeholder: AppLocalizations.of(context)!
                                      .enterDriverName,
                                  value: tab.driverName,
                                  controller: _driverNameController,
                                  onChanged: (value) {
                                    tabsProvider.updateManualTab(
                                        0, {'driverName': value});
                                  },
                                  suggestionType: AutoCompleteType.driver,
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
                                    AppLocalizations.of(context)!.client),
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
                                      tabsProvider.updateManualTab(0, {
                                        'client': value,
                                        'supplier': '',
                                      });
                                    } else {
                                      tabsProvider.updateManualTab(
                                          0, {'client': value});
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
                                    AppLocalizations.of(context)!.supplier),
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
                                      tabsProvider.updateManualTab(0, {
                                        'supplier': value,
                                        'client': '',
                                      });
                                    } else {
                                      tabsProvider.updateManualTab(
                                          0, {'supplier': value});
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _buildLabel(AppLocalizations.of(context)!
                                    .materialRequired),
                                const SizedBox(height: 4),
                                AutoCompleteComboBox(
                                  placeholder: AppLocalizations.of(context)!
                                      .selectMaterial,
                                  value: tab.material,
                                  controller: _materialController,
                                  onChanged: (value) async {
                                    tabsProvider.updateManualTab(
                                        0, {'material': value});
                                    if (_materialController.text.isNotEmpty) {
                                      await getMaterialLogic();
                                    }
                                  },
                                  suggestionType: AutoCompleteType.material,
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            KiloPriceBox(
                                controller: _kiloPriceController,
                                onChange: (v) {
                                  calculateTotalPrice();
                                }),
                            SizedBox(
                              width: 5,
                            ),
                            TotalPriceBox(
                                controller: _totalPriceController,
                                onChange: (v) {})
                          ],
                        ), // Material

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            _buildLabel(AppLocalizations.of(context)!.notes),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.15,
                              child: TextBox(
                                  controller: _notesController,
                                  onChanged: (v) {
                                    tabsProvider
                                        .updateManualTab(0, {'notes': v});
                                  }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Payment Status
                        ToggleSwitch(
                          checked: tab.isPaid,
                          onChanged: (value) {
                            tabsProvider.updateManualTab(0, {'isPaid': value});
                          },
                          content: Text(AppLocalizations.of(context)!.paid),
                        ),
                        const SizedBox(height: 8),

                        // Show Price on Print
                        ToggleSwitch(
                          checked: tab.showPriceOnPrint,
                          onChanged: (value) {
                            tabsProvider.updateManualTab(
                                0, {'showPriceOnPrint': value});
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
      ),
    );
  }

  Widget _buildWeightField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required VoidCallback onScalePressed,
    required ValueChanged<bool> onFocusChanged,
  }) {
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
                  controller: controller,
                  placeholder: '0.0',
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
                  onPressed: weightProvider.isConnected ? onScalePressed : null,
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
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(
                value.toStringAsFixed(1),
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
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: kLabelFontSize,
      ),
    );
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
                    Icon(FluentIcons.print, size: kIconSize),
                    SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.print,
                        style: TextStyle(fontSize: kButtonFontSize)),
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
                    Icon(FluentIcons.print, size: kIconSize),
                    SizedBox(width: 6),
                    Text(AppLocalizations.of(context)!.savePDF,
                        style: TextStyle(fontSize: kButtonFontSize)),
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
              child: isEditing
                  ? FilledButton(
                      onPressed: () {
                        _modifyTab();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.save,
                              style: TextStyle(fontSize: kButtonFontSize)),
                        ],
                      ),
                    )
                  : FilledButton(
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
                              style: TextStyle(fontSize: kButtonFontSize)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods for status display

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
      tabsProvider.updateManualTab(0, {'emptyWeight': currentWeight});
      tabsProvider.updateManualTab(0, {'scaleEmptyWeight': DateTime.now()});
    } else if (!isEmptyWeight && !_grossWeightFieldFocused) {
      _grossWeightController.text = currentWeight.toString();
      tabsProvider.updateManualTab(0, {'grossWeight': currentWeight});
      tabsProvider.updateManualTab(0, {'scaleGrossWeight': DateTime.now()});
      calculateTotalPrice();
    } else {
      _showInfoBar(AppLocalizations.of(context)!.cannotCaptureWhileEditing,
          InfoBarSeverity.warning);
      return;
    }
  }

//TODO......
  void _cancelTab() {
    final tabsProvider = context.read<TabsProvider>();
    tabsProvider.cancelTab(0);
    _showInfoBar(
        AppLocalizations.of(context)!.tabCancelled, InfoBarSeverity.info);
  }

  void _completeTab() async {
    final tabsProvider = context.read<TabsProvider>();
    final success = await tabsProvider.completeManualTab();
    if (success) {
      Navigator.of(context).pop();
      _showInfoBar(AppLocalizations.of(context)!.tabCompletedAndMoved,
          InfoBarSeverity.success);
    } else {
      _showInfoBar(AppLocalizations.of(context)!.unableToCompleteTab,
          InfoBarSeverity.error);
    }
  }

  void _modifyTab() async {
    final tabsProvider = context.read<TabsProvider>();
    final success = await tabsProvider.modifyManualTab();
    if (success) {
      Navigator.of(context).pop();
      _showInfoBar(AppLocalizations.of(context)!.tabCompletedAndMoved,
          InfoBarSeverity.success);
    } else {
      _showInfoBar(AppLocalizations.of(context)!.unableToCompleteTab,
          InfoBarSeverity.error);
    }
  }

  Color _getStatusColor(dynamic status) {
    switch (status?.toString().toLowerCase()) {
      case 'complete':
      case 'completed':
        return Colors.green;
      case 'incomplete':
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'completed':
        return l10n.statusCompleted;
      case 'in-progress':
      case 'inprogress':
        return l10n.statusInProgress;
      case 'incomplete':
        return l10n.statusIncomplete;
      case 'cancelled':
        return l10n.statusCancelled;
      case 'empty':
        return l10n.statusEmpty;
      default:
        // Fallback: capitalize each word
        return status
            .split('-')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
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
}
