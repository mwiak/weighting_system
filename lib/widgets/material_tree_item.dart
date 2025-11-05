import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:weighing_system/services/excel_service.dart';

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

    return MaterialTreeItem(
      material,
      suppliers: suppliers,
      clients: clients,
      content: Row(
        children: [
          Container(
              decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Text(material),
              ))
        ],
      ),
      children: [
        if (clients.isNotEmpty)
          TreeViewItem(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.isDisabled) {
                  return Colors.grey; // Disabled color
                }
                if (states.isPressed) {
                  return Colors.blue.withOpacity(0.9); // When pressed
                }
                if (states.isHovered) {
                  return Colors.blue.withOpacity(0.3); // When hovered
                }
                return Colors.blue.withOpacity(0.6); // Default
              }),
              content: Row(
                children: [
                  Text('الزبائن'),
                  Spacer(),
                  Text.rich(TextSpan(text: 'مجموع وزن البضاعة', children: [
                    TextSpan(text: ':'),
                    TextSpan(text: totalWeightSale.toString())
                  ])),
                  SizedBox(
                    width: 20,
                  ),
                  Text.rich(TextSpan(text: 'مجموع قيمة البضاعة', children: [
                    TextSpan(text: ':'),
                    TextSpan(text: totalValueSale.toStringAsFixed(2))
                  ])),
                  SizedBox(
                    width: 20,
                  ),
                  DropDownButton(
                    title: Icon(FluentIcons.settings),
                    items: [
                      MenuFlyoutItem(
                          text: const Text('export to excel'),
                          onPressed: () {
                            ExcelService excel = ExcelService();
                            excel.createStyledExcel(
                                tabs: allClientsList(), context: context);
                          }),
                      MenuFlyoutSeparator(),
                      MenuFlyoutItem(
                          text: const Text('Reply'), onPressed: null),
                      MenuFlyoutItem(
                          text: const Text('Reply all'), onPressed: () {}),
                    ],
                  )
                ],
              ),
              children: _buildClientOrSupplier(clients, context)),
        if (suppliers.isNotEmpty)
          TreeViewItem(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.isDisabled) {
                  return Colors.grey; // Disabled color
                }
                if (states.isPressed) {
                  return Colors.red.withOpacity(0.9); // When pressed
                }
                if (states.isHovered) {
                  return Colors.red.withOpacity(0.3); // When hovered
                }
                return Colors.red.withOpacity(0.6); // Default
              }),
              content: Row(
                children: [
                  Text('الموردين'),
                  Spacer(),
                  Text.rich(TextSpan(text: 'مجموع وزن البضاعة', children: [
                    TextSpan(text: ':'),
                    TextSpan(text: totalWeightPurchase.toString())
                  ])),
                  SizedBox(
                    width: 20,
                  ),
                  Text.rich(TextSpan(text: 'مجموع قيمة البضاعة', children: [
                    TextSpan(text: ':'),
                    TextSpan(text: totalValuePurchase.toStringAsFixed(2))
                  ])),
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
    for (WeighingTab tab in value) {
      totalWeight = totalWeight + tab.netWeight;
      totalPrice = totalPrice + tab.total_price;
    }
    children = value
        .map((tab) => TreeViewItem(
                content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                    width: AppTheme.summaryBoxSized,
                    child: Text(tab.id.toString())),
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
            content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
                width: AppTheme.summaryBoxSized, child: Text(l10n.orderNumber)),
            SizedBox(
                width: AppTheme.summaryBoxSized, child: Text(l10n.driverName)),
            SizedBox(
                width: AppTheme.summaryBoxSized,
                child: Text(l10n.netWeight.toString())),
            SizedBox(
                width: AppTheme.summaryBoxSized, child: Text(l10n.unitPrice)),
            SizedBox(
                width: AppTheme.summaryBoxSized, child: Text(l10n.totalAmount)),
          ],
        )));
    items.add(
      TreeViewItem(
          content: Row(
            children: [
              Text(key),
              SizedBox(
                width: 20,
              ),
              Text.rich(TextSpan(text: 'مجموع وزن البضاعة', children: [
                TextSpan(text: ':'),
                TextSpan(text: totalWeight.toString())
              ])),
              SizedBox(
                width: 20,
              ),
              Text.rich(TextSpan(text: 'مجموع قيمة البضاعة', children: [
                TextSpan(text: ':'),
                TextSpan(text: totalPrice.toStringAsFixed(2))
              ])),
            ],
          ),
          children: children),
    );
  });
  return items;
}
