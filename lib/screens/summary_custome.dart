import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:weighing_system/models/weighing_tab.dart';
import 'package:weighing_system/providers/summaries_provider.dart';
import 'package:weighing_system/utils/date_range_formatter.dart';
import 'package:weighing_system/utils/debugging_methods.dart';
import '../l10n/app_localizations.dart';
import '../models/season.dart';
import '../providers/seasons_provider.dart';
import '../widgets/material_tree_item.dart';

class SummaryCustom extends StatefulWidget {
  const SummaryCustom({super.key});

  @override
  State<SummaryCustom> createState() => _SummaryCustomState();
}

class _SummaryCustomState extends State<SummaryCustom> {
  DateTime? activeDate = DateTime.now();
  DateTime startDate = getTodayStartDate();
  DateTime endDate = getTodayEndDate();

  Map<String, Map<String, Map<String, List<WeighingTab>>>> data = {};
  late SummariesProvider provider;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      provider = context.read<SummariesProvider>();
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
              ...[
                Button(
                  child: Text('اليوم'),
                  onPressed: () => setState(() {
                    startDate = getTodayStartDate();
                    endDate = getTodayEndDate();
                  }),
                ),
                const SizedBox(width: 16),
                Button(
                  child: Text('البارحة'),
                  onPressed: () => setState(() {
                    startDate = getYesterdayStartDate();
                    endDate = getYesterdayEndDate();
                  }),
                ),
                const SizedBox(width: 16),
                Consumer<SeasonsProvider>(
                  builder: (BuildContext context, value, Widget? child) {
                    return DropDownButton(
                      title: Text('مواسم'),
                      items: _buildSeasonsOptions(value.availableSeasons),
                    );
                  },
                ),
                const SizedBox(width: 16),
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
                data = await provider.getCustomSummary(
                    startDate: startDate, endDate: endDate);
                setState(() {});
              }),
          SizedBox(
            height: 20,
          ),
          Consumer<SummariesProvider>(
            builder: (BuildContext context, value, Widget? child) {
              return Flexible(
                  child: SingleChildScrollView(child: _buildTree()));
            },
          )
        ],
      ),
    );
  }

  Widget _buildTree() {
    if (data.isEmpty) return SizedBox.shrink();

    List<String> materials = data.keys.toList();

    List<TreeViewItem> items = [];

    for (String material in materials) {
      Map<String, List<WeighingTab>> suppliers =
          data[material]!['suppliers'] ?? {};
      Map<String, List<WeighingTab>> clients = data[material]!['clients'] ?? {};

      items.add(MaterialTreeItem.from(
          material: material,
          suppliers: suppliers,
          clients: clients,
          context: context));
    }

    return TreeView(items: items);
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
}
