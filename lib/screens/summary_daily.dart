import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:weighing_system/models/weighing_tab.dart';
import 'package:weighing_system/providers/summaries_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/material_tree_item.dart';

class SummaryDaily extends StatefulWidget {
  const SummaryDaily({super.key});

  @override
  State<SummaryDaily> createState() => _SummaryDailyState();
}

class _SummaryDailyState extends State<SummaryDaily> {
  DateTime? activeDate = DateTime.now();
  Map<String, Map<String, Map<String, List<WeighingTab>>>> data = {};
  late SummariesProvider provider;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      provider = context.read<SummariesProvider>();

      data = await provider.getDailySummary(exactDate: activeDate!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('day of gard'),
              SizedBox(
                width: 10,
              ),
              SizedBox(
                width: 100,
                child: DatePicker(
                  selected: activeDate,
                  onChanged: (v) {
                    activeDate = v;
                    setState(() {});
                  },
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Card(
                  child: Button(
                      child: Text('generate'),
                      onPressed: () async {
                        data = await provider.getDailySummary(
                            exactDate: activeDate!);
                        setState(() {});
                      })),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Consumer<SummariesProvider>(
            builder: (BuildContext context, value, Widget? child) {
              return _buildTree();
            },
          )
        ],
      ),
    ));
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
}
