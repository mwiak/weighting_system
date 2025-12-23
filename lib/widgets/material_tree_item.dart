import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:weighing_system/services/excel_service.dart';
import 'package:weighing_system/utils/debugging_methods.dart';

import '../models/weighing_tab.dart';
import '../l10n/app_localizations.dart';

import '../theme/app_theme.dart';

class MaterialTreeItem extends TreeViewItem {
  final String material;
  final Map<String, List<WeighingTab>> suppliers;
  final Map<String, List<WeighingTab>> clients;
  late int totalNetWeightSold;
  late int totalNetWeightPurchased;
  MaterialTreeItem(this.material,
      {super.key,
      required this.suppliers,
      required this.clients,
      required super.content,
      required super.children});

  factory MaterialTreeItem.from(
      {required String material,
      required Map<String, List<WeighingTab>> suppliers,
      required Map<String, List<WeighingTab>> clients,
      required BuildContext context}) {
    int totalWeightSale = 0;
    num totalValueSale = 0.0;

    int totalWeightPurchase = 0;
    num totalValuePurchase = 0.0;

    for (List<WeighingTab> tabs in suppliers.values) {
      totalWeightPurchase = totalWeightPurchase + tabs.totalWeight;
      totalValuePurchase = totalValuePurchase + tabs.totalPrice;
    }

    for (List<WeighingTab> tabs in clients.values) {
      totalWeightSale = totalWeightSale + tabs.totalWeight;
      totalValueSale = totalValueSale + tabs.totalPrice;
    }

    List<WeighingTab> allClientsList() {
      List<WeighingTab> tabs = [];
      for (List<WeighingTab> l in clients.values) {
        tabs.addAll(l);
      }
      return tabs;
    }

    List<WeighingTab> allSuppliersList() {
      List<WeighingTab> tabs = [];
      for (List<WeighingTab> l in suppliers.values) {
        tabs.addAll(l);
      }
      return tabs;
    }

    return MaterialTreeItem(
      material,
      suppliers: suppliers,
      clients: clients,
      content: Row(
        children: [
          Container(
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
                child: Text(material),
              ))
        ],
      ),
      children: [
        if (clients.isNotEmpty)
          TreeViewItem(
              content: Row(
                children: [
                  Container(
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                        child: Text('الزبائن'),
                      )),
                  Spacer(),
                  buildTotalWeight(
                      'عدد الذمم', clients.entries.length.toString()),
                  SizedBox(
                    width: 20,
                  ),
                  buildTotalWeight(null, totalWeightSale.toString()),
                  SizedBox(
                    width: 20,
                  ),
                  buildTotalWeight(
                      'مجموع قيمة البضاعة', totalValueSale.toStringAsFixed(2)),
                  SizedBox(
                    width: 20,
                  ),
                  DropDownButton(
                    title: Icon(FluentIcons.settings),
                    items: [
                      MenuFlyoutItem(
                          text: const Text('تصدير للأكسل'),
                          onPressed: () {
                            ExcelService excel = ExcelService();
                            excel.createStyledExcel(
                                tabs: allClientsList(), context: context);
                          }),
                    ],
                  )
                ],
              ),
              children: _buildClientOrSupplier(clients, context)),
        if (suppliers.isNotEmpty)
          TreeViewItem(
              content: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                      child: Text('الموردين'),
                    ),
                  ),
                  Spacer(),
                  buildTotalWeight(
                      'عدد الذمم', suppliers.entries.length.toString()),
                  SizedBox(
                    width: 20,
                  ),
                  buildTotalWeight(null, totalWeightPurchase.toString()),
                  SizedBox(
                    width: 20,
                  ),
                  buildTotalWeight('مجموع قيمة البضاعة',
                      totalValuePurchase.toStringAsFixed(2)),
                  SizedBox(
                    width: 20,
                  ),
                  DropDownButton(
                    title: Icon(FluentIcons.settings),
                    items: [
                      MenuFlyoutItem(
                          text: const Text('تصدير للأكسل'),
                          onPressed: () {
                            ExcelService excel = ExcelService();
                            excel.createStyledExcel(
                                tabs: allSuppliersList(), context: context);
                          }),
                    ],
                  )
                ],
              ),
              children: _buildClientOrSupplier(suppliers, context)),
      ],
    );
  }
}

List<TreeViewItem> _buildClientOrSupplier(
    Map<String, List<WeighingTab>> input, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  List<TreeViewItem> items = [];
  List<TreeViewItem> children = [];
  int totalWeight = 0;
  num totalPrice = 0.0;

  input.forEach((key, value) {
    children = [];
    totalWeight = 0;
    totalPrice = 0.0;
    int count = value.length;
    for (WeighingTab tab in value) {
      totalWeight = totalWeight + tab.netWeight;
      totalPrice = totalPrice + tab.total_price;
    }
    children = value
        .map((tab) => TreeViewItem(
            expanded: false,
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(tab.id.toString())),
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(tab.createdAt.toString())),
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(tab.driverName)),
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(tab.netWeight.toString())),
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(tab.kilo_price.toString())),
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(tab.total_price.toStringAsFixed(2))),
              ],
            )))
        .toList();
    children.insert(
        0,
        TreeViewItem(
            expanded: false,
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(l10n.orderNumber)),
                SizedBox(
                    //TODO dateformat
                    width: AppTheme.summaryBoxSized,
                    child: Text(l10n.createdAt)),
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(l10n.driverName)),
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(l10n.netWeight.toString())),
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(l10n.unitPrice)),
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(l10n.totalAmount)),
              ],
            )));
    items.add(
      TreeViewItem(
          expanded: false,
          content: Row(
            children: [
              Text(key),
              SizedBox(
                width: 20,
              ),
              buildTotalWeight(null, totalWeight.toString()),
              SizedBox(
                width: 20,
              ),
              buildTotalWeight(
                  'مجموع قيمة البضاعة', totalPrice.toStringAsFixed(2)),
              Spacer(),
              buildTotalWeight('عدد الشحنات', count.toString(),
                  color: Colors.purple.withValues(alpha: 0.1)),
              SizedBox(
                width: 10,
              ),
              DropDownButton(
                title: Icon(FluentIcons.settings),
                items: [
                  MenuFlyoutItem(
                      text: const Text('تصدير للأكسل'),
                      onPressed: () {
                        ExcelService excel = ExcelService();
                        excel.createStyledExcel(tabs: value, context: context);
                      }),
                ],
              ),
            ],
          ),
          children: children),
    );
  });
  return items;
}

Widget buildTotalWeight(String? label, String total, {Color? color}) {
  color ??= Colors.green.withOpacity(0.2);
  return Container(
    decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.all(Radius.circular(12))),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      child: Text.rich(TextSpan(
          text: label ?? 'مجموع وزن البضاعة',
          children: [TextSpan(text: '  '), TextSpan(text: total)])),
    ),
  );
}
