import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:weighing_system/database/database_helper.dart';
import 'package:weighing_system/models/print_template.dart';
import 'package:weighing_system/services/custom_template_service.dart';
import 'package:weighing_system/widgets/kilo_price_box.dart';
import 'dart:async';
// import 'package:weighing_system/gen_l10n/app_localizations.dart';
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
      _showInfoBar('could not find a tempalte', InfoBarSeverity.error);
    }
  }

  Future<void> savePDF() async {
    PrintTemplate? defaultTemplate =
        await _templateService.getDefaultTemplate();
    if (defaultTemplate != null) {
      await _printService.saveTemplateStandardPDFNewSilently(
          defaultTemplate, _tab!, null, null, null);
    } else {
      _showInfoBar('could not find a tempalte', InfoBarSeverity.error);
    }
  }

  void _onKiloPriceChanged() {
    final value = num.tryParse(_kiloPriceController.text);
    myProvider = Provider.of<TabsProvider>(context, listen: false);
    myProvider.updateTab(widget.tabIndex, {'kilo_price': value});
    calculateTotalPrice();
    print("Text changed: $value");
  }

  void _onTotalPriceChanged() {
    final value = num.tryParse(_totalPriceController.text);
    myProvider = Provider.of<TabsProvider>(context, listen: false);
    myProvider.updateTab(widget.tabIndex, {'total_price': value});
    print("Text changed: $value");
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
  }

  @override
  void dispose() {
    _kiloPriceController.removeListener(_onKiloPriceChanged);
    _totalPriceController.removeListener(_onTotalPriceChanged);
    _emptyWeightController.dispose();
    _grossWeightController.dispose();
    _truckPlateController.dispose();
    _driverNameController.dispose();
    _clientController.dispose();
    _supplierController.dispose();
    _materialController.dispose();
    _kiloPriceController.dispose();
    _totalPriceController.dispose();
    _emptyWeightDebounceTimer?.cancel();
    _grossWeightDebounceTimer?.cancel();

    super.dispose();
  }

  void _onEmptyWeightChanged(String value) {
    _emptyWeightDebounceTimer?.cancel();
    _emptyWeightDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        final weight = int.tryParse(value) ?? 0;
        context
            .read<TabsProvider>()
            .updateTab(widget.tabIndex, {'emptyWeight': weight});
        calculateTotalPrice();
      }
    });
  }

  void _onGrossWeightChanged(String value) {
    _grossWeightDebounceTimer?.cancel();
    _grossWeightDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        final weight = int.tryParse(value) ?? 0;
        context
            .read<TabsProvider>()
            .updateTab(widget.tabIndex, {'grossWeight': weight});
        calculateTotalPrice();
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
      print('Price: $price');
    } else {
      print('No material found for ${_tab?.material}');
    }
  }

  void calculateTotalPrice() {
    if (_tab!.netWeight != 0) {
      num? kiloPrice = num.tryParse(_kiloPriceController.text);
      if (kiloPrice != null) {
        print('dodoododod');
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
          return const Center(
            child: Text('Tab not found'),
          );
        }

        // Update controllers if data changed from elsewhere
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
        final truckPlateText = tab.truckPlate;
        if (_truckPlateController.text != truckPlateText) {
          _truckPlateController.text = truckPlateText;
        }
        final driverNameText = tab.driverName;
        if (_driverNameController.text != driverNameText) {
          _driverNameController.text = driverNameText;
        }
        final clientText = tab.client;
        if (_clientController.text != clientText) {
          _clientController.text = clientText;
        }
        final supplierText = tab.supplier;
        if (_supplierController.text != supplierText) {
          _supplierController.text = supplierText;
        }
        final materialText = tab.material;
        if (_materialController.text != materialText) {
          _materialController.text = materialText;
        }

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
                        'معلومات الوزن',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 16),

                      // Empty Weight
                      _buildWeightField(
                        label: 'Empty Weight (kg)',
                        controller: _emptyWeightController,
                        onChanged: _onEmptyWeightChanged,
                        onScalePressed: () => _captureWeightFromScale(true),
                        onFocusChanged: (focused) =>
                            setState(() => _emptyWeightFieldFocused = focused),
                      ),
                      const SizedBox(height: 12),

                      // Gross Weight
                      _buildWeightField(
                        label: 'Gross Weight (kg)',
                        controller: _grossWeightController,
                        onChanged: _onGrossWeightChanged,
                        onScalePressed: () => _captureWeightFromScale(false),
                        onFocusChanged: (focused) =>
                            setState(() => _grossWeightFieldFocused = focused),
                      ),
                      const SizedBox(height: 12),

                      // Net Weight (calculated)
                      _buildCalculatedWeight(
                        label: 'Net Weight (kg)',
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
                              'Status: ${_getStatusText(tab.status)}',
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
                        'Business Information',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 16),

                      // Truck Plate
                      _buildLabel('Truck Plate *'),
                      const SizedBox(height: 6),
                      AutoCompleteComboBox(
                        placeholder: 'Enter truck plate...',
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
                      _buildLabel('Driver Name'),
                      const SizedBox(height: 6),
                      AutoCompleteComboBox(
                        placeholder: 'Enter driver name...',
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
                      _buildLabel('Customer (Loading Operation)'),
                      const SizedBox(height: 6),
                      AutoCompleteComboBox(
                        placeholder: 'Select Customer...',
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
                      _buildLabel('Supplier (Unloading Operation)'),
                      const SizedBox(height: 6),
                      AutoCompleteComboBox(
                        placeholder: 'Select Supplier...',
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
                      _buildLabel('Material *'),
                      const SizedBox(height: 6),
                      AutoCompleteComboBox(
                        placeholder: 'Select Material',
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
                        content: const Text('Paid'),
                      ),
                      const SizedBox(height: 12),

                      // Show Price on Print
                      ToggleSwitch(
                        checked: tab.showPriceOnPrint,
                        onChanged: (value) {
                          tabsProvider.updateTab(
                              widget.tabIndex, {'showPriceOnPrint': value});
                        },
                        content: const Text('Show Price on Print'),
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
                  suffix: const Text('kg'),
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
              const Text(
                'kg',
                style: TextStyle(color: Colors.grey),
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
                const Text('Cancel'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Button(
            onPressed: () => printPDF(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.print),
                SizedBox(width: 8),
                Text('Print'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Button(
            onPressed: () => savePDF(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.print),
                SizedBox(width: 8),
                Text('Save PDF'),
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
                Text(tab.isComplete ? 'Complete' : 'Incomplete'),
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

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in-progress':
        return 'In Progress';
      case 'cancelled':
        return 'Cancelled';
      case 'empty':
        return 'Empty';
      default:
        return 'Unknown';
    }
  }

  void _captureWeightFromScale(bool isEmptyWeight) {
    final weightProvider = context.read<WeightProvider>();
    if (!weightProvider.isConnected) {
      _showInfoBar('Scale must be connected before capturing weight',
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
      _showInfoBar(
          'Cannot capture weight while editing field', InfoBarSeverity.warning);
      return;
    }
  }

  void _printTab(WeighingTab tab) {
    // TODO: Implement printing

    _showInfoBar('Printing ${tab.tabTitle}...', InfoBarSeverity.info);
  }

  void _cancelTab() {
    final tabsProvider = context.read<TabsProvider>();
    tabsProvider.cancelTab(widget.tabIndex);
    _showInfoBar('Tab cancelled', InfoBarSeverity.info);
  }

  void _completeTab() async {
    final tabsProvider = context.read<TabsProvider>();
    final success = await tabsProvider.completeTab(widget.tabIndex);
    if (success) {
      _showInfoBar(
          'Tab completed and moved to history', InfoBarSeverity.success);
    } else {
      _showInfoBar('Unable to complete tab. Please fill all required fields.',
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
