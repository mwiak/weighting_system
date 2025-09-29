import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:weighing_system/database/database_helper.dart';
import 'package:weighing_system/models/print_template.dart';
import 'package:weighing_system/services/custom_template_service.dart';
import 'package:weighing_system/widgets/kilo_price_box.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/weighing_tab.dart';
import '../providers/weight_provider.dart';
import '../providers/tabs_provider.dart';
import '../services/template_print_service.dart';
import 'auto_complete_combo_box.dart';

class WeighingTabContent extends StatefulWidget {
  final int tabIndex;

  const WeighingTabContent({
    super.key,
    required this.tabIndex,
  });

  @override
  State<WeighingTabContent> createState() => _WeighingTabContentState();
}

class _WeighingTabContentState extends State<WeighingTabContent> {
  late TextEditingController _emptyWeightController;
  late TextEditingController _grossWeightController;
  late TextEditingController _truckPlateController;
  late TextEditingController _driverNameController;
  late TextEditingController _clientController;
  late TextEditingController _supplierController;
  late TextEditingController _materialController;
  late TextEditingController _kiloPriceController;
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

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column - Weight Information
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.weightInformation,
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 16),

                      // Empty Weight
                      _buildWeightField(
                        label: AppLocalizations.of(context)!.emptyWeightKg,
                        controller: _emptyWeightController,
                        onChanged: _onEmptyWeightChanged,
                        onScalePressed: () => _captureWeightFromScale(true),
                        onFocusChanged: (focused) =>
                            setState(() => _emptyWeightFieldFocused = focused),
                      ),
                      const SizedBox(height: 12),

                      // Gross Weight
                      _buildWeightField(
                        label: AppLocalizations.of(context)!.grossWeightKg,
                        controller: _grossWeightController,
                        onChanged: _onGrossWeightChanged,
                        onScalePressed: () => _captureWeightFromScale(false),
                        onFocusChanged: (focused) =>
                            setState(() => _grossWeightFieldFocused = focused),
                      ),
                      const SizedBox(height: 12),

                      // Net Weight (calculated)
                      _buildCalculatedWeight(
                        label: AppLocalizations.of(context)!.netWeightKg,
                        value: tab.netWeight,
                      ),
                      const SizedBox(height: 24),

                      // Operation Status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(tab.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(tab.status),
                              color: _getStatusColor(tab.status),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.statusLabel(
                                  _getStatusText(context, tab.status)),
                              style: TextStyle(
                                color: _getStatusColor(tab.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Operation type removed from schema
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Right Column - Business Information
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.businessInformation,
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 16),

                      // Truck Plate
                      _buildLabel(
                          AppLocalizations.of(context)!.truckPlateRequired),
                      const SizedBox(height: 6),
                      AutoCompleteComboBox(
                        placeholder:
                            AppLocalizations.of(context)!.enterTruckPlate,
                        value: tab.truckPlate,
                        controller: _truckPlateController,
                        onChanged: (value) {
                          tabsProvider.updateTab(
                              widget.tabIndex, {'truckPlate': value});
                        },
                        suggestionType: AutoCompleteType.truckPlate,
                      ),
                      const SizedBox(height: 12),

                      // Driver Name
                      _buildLabel(AppLocalizations.of(context)!.driverName),
                      const SizedBox(height: 6),
                      AutoCompleteComboBox(
                        placeholder:
                            AppLocalizations.of(context)!.enterDriverName,
                        value: tab.driverName,
                        controller: _driverNameController,
                        onChanged: (value) {
                          tabsProvider.updateTab(
                              widget.tabIndex, {'driverName': value});
                        },
                        suggestionType: AutoCompleteType.driver,
                      ),
                      const SizedBox(height: 12),

                      // Customer Field
                      _buildLabel(AppLocalizations.of(context)!
                          .customerLoadingOperation),
                      const SizedBox(height: 6),
                      AutoCompleteComboBox(
                        placeholder:
                            AppLocalizations.of(context)!.selectCustomer,
                        value: tab.client,
                        controller: _clientController,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            // Clear supplier when client is set
                            _supplierController.text = '';
                            tabsProvider.updateTab(widget.tabIndex, {
                              'client': value,
                              'supplier': '',
                            });
                          } else {
                            tabsProvider
                                .updateTab(widget.tabIndex, {'client': value});
                          }
                        },
                        suggestionType: AutoCompleteType.client,
                      ),
                      const SizedBox(height: 12),

                      // Supplier Field
                      _buildLabel(AppLocalizations.of(context)!
                          .supplierUnloadingOperation),
                      const SizedBox(height: 6),
                      AutoCompleteComboBox(
                        placeholder:
                            AppLocalizations.of(context)!.selectSupplier,
                        value: tab.supplier,
                        controller: _supplierController,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            // Clear client when supplier is set
                            _clientController.text = '';
                            tabsProvider.updateTab(widget.tabIndex, {
                              'supplier': value,
                              'client': '',
                            });
                          } else {
                            tabsProvider.updateTab(
                                widget.tabIndex, {'supplier': value});
                          }
                        },
                        suggestionType: AutoCompleteType.supplier,
                      ),
                      const SizedBox(height: 12),

                      // Material
                      _buildLabel(
                          AppLocalizations.of(context)!.materialRequired),
                      const SizedBox(height: 6),
                      AutoCompleteComboBox(
                        placeholder:
                            AppLocalizations.of(context)!.selectMaterial,
                        value: tab.material,
                        controller: _materialController,
                        onChanged: (value) async {
                          tabsProvider
                              .updateTab(widget.tabIndex, {'material': value});
                          if (_materialController.text.isNotEmpty) {
                            await getMaterialLogic();
                          }
                        },
                        suggestionType: AutoCompleteType.material,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          KiloPriceBox(
                              controller: _kiloPriceController,
                              onChange: (v) {
                                calculateTotalPrice();
                              }),
                          SizedBox(
                            width: 10,
                          ),
                          TotalPriceBox(
                              controller: _totalPriceController,
                              onChange: (v) {})
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Payment Status
                      ToggleSwitch(
                        checked: tab.isPaid,
                        onChanged: (value) {
                          tabsProvider
                              .updateTab(widget.tabIndex, {'isPaid': value});
                        },
                        content: Text(AppLocalizations.of(context)!.paid),
                      ),
                      const SizedBox(height: 12),

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
                      const SizedBox(height: 24),

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
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: value > 0 ? Colors.green : Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.kg,
                style: const TextStyle(color: Colors.grey),
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
        fontSize: 14,
      ),
    );
  }

  Widget _buildActionButtons(WeighingTab tab) {
    // final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Button(
            onPressed: () => _cancelTab(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FluentIcons.cancel),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.cancel),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Button(
            onPressed: () => printPDF(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.print),
                SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.print),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Button(
            onPressed: () => savePDF(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.print),
                SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.savePDF),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: tab.isComplete ? () => _completeTab() : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    tab.isComplete ? FluentIcons.completed : FluentIcons.clear),
                const SizedBox(width: 8),
                Text(tab.isComplete
                    ? AppLocalizations.of(context)!.complete
                    : AppLocalizations.of(context)!.incomplete),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for status display
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in-progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'empty':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return FluentIcons.completed;
      case 'in-progress':
        return FluentIcons.warning;
      case 'cancelled':
        return FluentIcons.cancel;
      case 'empty':
        return FluentIcons.clear;
      default:
        return FluentIcons.warning;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    switch (status) {
      case 'completed':
        return AppLocalizations.of(context)!.completed;
      case 'in-progress':
        return AppLocalizations.of(context)!.inProgress;
      case 'cancelled':
        return AppLocalizations.of(context)!.cancelled;
      case 'empty':
        return AppLocalizations.of(context)!.empty;
      default:
        return AppLocalizations.of(context)!.unknown;
    }
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
    } else {
      _showInfoBar(AppLocalizations.of(context)!.cannotCaptureWhileEditing,
          InfoBarSeverity.warning);
      return;
    }
  }

  void _printTab(WeighingTab tab) {
    // TODO: Implement printing

    _showInfoBar(AppLocalizations.of(context)!.printingOperation(tab.tabTitle),
        InfoBarSeverity.info);
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
    if (success) {
      _showInfoBar(AppLocalizations.of(context)!.tabCompletedAndMoved,
          InfoBarSeverity.success);
    } else {
      _showInfoBar(AppLocalizations.of(context)!.unableToCompleteTab,
          InfoBarSeverity.error);
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
