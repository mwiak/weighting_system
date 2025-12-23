import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:weighing_system/models/weighing_tab.dart';
import 'package:weighing_system/providers/summaries_provider.dart';
import 'package:weighing_system/utils/date_range_formatter.dart';
import 'package:weighing_system/widgets/kilo_price_box.dart';
import 'package:weighing_system/widgets/multi_select.dart';
import '../l10n/app_localizations.dart';
import '../models/season.dart';
import '../providers/seasons_provider.dart';
import '../widgets/material_tree_item.dart';
import 'dart:isolate';

class SummaryByPerson extends StatefulWidget {
  const SummaryByPerson({super.key});

  @override
  State<SummaryByPerson> createState() => _SummaryByPersonState();
}

class _SummaryByPersonState extends State<SummaryByPerson> {
  DateTime? activeDate = DateTime.now();
  DateTime startDate = getTodayStartDate();
  DateTime endDate = getTodayEndDate();
  AutoCompleteType summaryType = AutoCompleteType.supplier;
  List<String> searchingTerms = [];
  TextEditingController unifiedPriceController = TextEditingController();

  Map<String, Map<String, Map<String, List<WeighingTab>>>> data = {};
  late SummariesProvider provider;

  num? parserAttempt() {
    return num.tryParse(unifiedPriceController.text.trim());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      startDate =
          context.read<SeasonsProvider>().availableSeasons.last.seasonStartDate;
      endDate =
          context.read<SeasonsProvider>().availableSeasons.last.seasonEndDate;
      provider = context.read<SummariesProvider>();

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ComboBox<AutoCompleteType>(
                  value: summaryType,
                  onChanged: (v) {
                    if (v != null) {
                      if (summaryType != v) {
                        summaryType = v;
                        searchingTerms = [];
                        setState(() {});
                      }
                    }
                  },
                  items: [
                    ...AutoCompleteType.values.map((v) =>
                        ComboBoxItem<AutoCompleteType>(
                            value: v,
                            child: Text(_buildSuggestionType(v, l10n))))
                  ]),
              SizedBox(
                width: 20,
              ),
              UnifiedPriceBox(
                  controller: unifiedPriceController, onChange: (v) {}),
              SizedBox(
                width: 20,
              ),
              MultiSelect(
                  placeholder: _buildSuggestionType(summaryType, l10n),
                  passedList: searchingTerms,
                  onChanged: (s) {},
                  suggestionType: summaryType,
                  onSelect: (v) {
                    searchingTerms.add(v);
                    setState(() {});
                  },
                  onDeselect: (v) {
                    searchingTerms.remove(v);
                    setState(() {});
                  }),
              SizedBox(
                width: 20,
              ),
              _buildSelectedItemsChips()
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.startDate + ':'),
                    const SizedBox(height: 4),
                    DatePicker(
                      selected: startDate,
                      onChanged: (date) async {
                        startDate = date;
                        await Future.delayed(Duration(milliseconds: 350));
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.endDate + ':'),
                    const SizedBox(height: 4),
                    DatePicker(
                      selected: endDate,
                      onChanged: (date) async {
                        endDate = date;
                        await Future.delayed(Duration(milliseconds: 350));
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ...[
                Button(
                  child: Text('اليوم'),
                  onPressed: () => setState(() {
                    startDate = getTodayStartDate();
                    endDate = getTodayEndDate();
                  }),
                ),
                const SizedBox(width: 8),
                Button(
                  child: Text('البارحة'),
                  onPressed: () => setState(() {
                    startDate = getYesterdayStartDate();
                    endDate = getYesterdayEndDate();
                  }),
                ),
                const SizedBox(width: 8),
                Button(
                  child: Text('الموسم الحالي'),
                  onPressed: () => setState(() {
                    startDate = context
                        .read<SeasonsProvider>()
                        .availableSeasons
                        .last
                        .seasonStartDate;
                    endDate = context
                        .read<SeasonsProvider>()
                        .availableSeasons
                        .last
                        .seasonEndDate;
                  }),
                ),
                const SizedBox(width: 8),
                Consumer<SeasonsProvider>(
                  builder: (BuildContext context, value, Widget? child) {
                    return DropDownButton(
                      title: Text('مواسم'),
                      items: _buildSeasonsOptions(value.availableSeasons),
                    );
                  },
                ),
                const SizedBox(width: 8),
                DropDownButton(title: Text('مزيد'), items: [
                  MenuFlyoutItem(
                      text: Text('آخر 7 أيام'),
                      onPressed: () => setState(() {
                            startDate = getLast7StartDate();
                            endDate = getLast7EndDate();
                          })),
                  MenuFlyoutItem(
                    text: Text('آخر 30 يوما'),
                    onPressed: () => () => setState(() {
                          startDate = getLast30StartDate();
                          endDate = getLast30EndDate();
                        }),
                  ),
                ]),
              ],
              SizedBox(
                height: 20,
              ),
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Button(
              child: Text('إنشاء تقرير'),
              onPressed: () async {
                data = await provider.getPerPersonSummary(
                    startDate: startDate,
                    endDate: endDate,
                    type: summaryType,
                    terms: searchingTerms);
                setState(() {});
              }),
          SizedBox(
            height: 20,
          ),
          Consumer<SummariesProvider>(
            builder: (BuildContext context, value, Widget? child) {
              return Flexible(
                  child: SingleChildScrollView(
                      child: _buildTree(unifiedPrice: parserAttempt())));
            },
          )
        ],
      ),
    );
  }

  Widget _buildTree({num? unifiedPrice}) {
    if (data.isEmpty) return SizedBox.shrink();
    late Map<String, List<WeighingTab>> suppliers;
    late Map<String, List<WeighingTab>> clients;
    List<String> materials = data.keys.toList();

    List<TreeViewItem> items = [];

    for (String material in materials) {
      suppliers = data[material]!['suppliers'] ?? {};
      clients = data[material]!['clients'] ?? {};
      if (unifiedPrice != null) {
        for (List item in suppliers.values) {
          for (WeighingTab tab in item) {
            tab.kilo_price = unifiedPrice;
            tab.total_price = unifiedPrice * tab.netWeight;
          }
        }

        for (List item in clients.values) {
          for (WeighingTab tab in item) {
            tab.kilo_price = unifiedPrice;
            tab.total_price = unifiedPrice * tab.netWeight;
          }
        }
      }
      items.add(MaterialTreeItem.from(
          material: material,
          suppliers: suppliers,
          clients: clients,
          context: context));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TreeView(items: items),
    );
  }

  List<MenuFlyoutItem> _buildSeasonsOptions(List<Season> data) {
    List<MenuFlyoutItem> items = [];

    for (Season item in data) {
      items.add(MenuFlyoutItem(
          text: Text(item.label),
          onPressed: () {
            endDate = item.seasonEndDate;
            startDate = item.seasonStartDate;
            setState(() {});
          }));
    }
    return items;
  }

  String _buildSuggestionType(AutoCompleteType type, AppLocalizations l10n) {
    switch (type) {
      case AutoCompleteType.client:
        return l10n.client;
      case AutoCompleteType.supplier:
        return l10n.supplier;
      case AutoCompleteType.driver:
        return l10n.driverName;
      case AutoCompleteType.truckPlate:
        return l10n.truckPlate;
      case AutoCompleteType.material:
        return l10n.material;
    }
  }

  Widget _buildSelectedItemsChips() {
    List<Widget> items = [];
    for (String item in searchingTerms) {
      items.add(Container(
        decoration: BoxDecoration(
          color: FluentTheme.of(context).accentColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(item),
        ),
      ));
    }
    return SizedBox(
      width: 300,
      child: Wrap(
        runSpacing: 4,
        spacing: 3.0,
        children: items,
      ),
    );
  }
}
