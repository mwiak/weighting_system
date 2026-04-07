import 'dart:io';
import 'package:excel/excel.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:weighing_system/utils/debugging_methods.dart';
import '../l10n/app_localizations.dart';
import 'package:weighing_system/utils/date_format.dart';
import '../models/weighing_tab.dart';
import 'package:file_picker/file_picker.dart' as fp;

class ExcelService {
  Future<void> createStyledExcel(
      {required List<WeighingTab> tabs,
      Map<String, bool>? visibleColumns,
      required BuildContext context}) async {
    String? selectedDirectory = await fp.FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      // User canceled the picker
      return;
    }

    Map<String, bool> columns = {
      "id": true,
      "date": true,
      "driverName": true,
      "plateNumber": true,
      "material": true,
      "supplier": true,
      "client": true,
      "emptyWeight": true,
      "grossWeight": true,
      "kiloPrice": true,
      "netWeight": true,
      "totalPrice": true
    };
    final ln10 = AppLocalizations.of(context)!;
    //TODO dir Pickernzabh
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.setDefaultColumnWidth(24);

    List<CellValue> columnsCells = [
      if (columns['id'] ?? true) TextCellValue(ln10.orderNumber),
      if (columns['date'] ?? true) TextCellValue(ln10.dateTime),
      if (columns['driverName'] ?? true) TextCellValue(ln10.driverName),
      if (columns['plateNumber'] ?? true) TextCellValue(ln10.plateNumber),
      if (columns['material'] ?? true) TextCellValue(ln10.material),
      if (columns['supplier'] ?? true) TextCellValue(ln10.supplier),
      if (columns['client'] ?? true) TextCellValue(ln10.client),
      if (columns['emptyWeight'] ?? true) TextCellValue(ln10.emptyWeight),
      if (columns['grossWeight'] ?? true) TextCellValue(ln10.grossWeight),
      if (columns['kiloPrice'] ?? true) TextCellValue(ln10.unitPrice),
      if (columns['netWeight'] ?? true) TextCellValue(ln10.netWeight),
      if (columns['totalPrice'] ?? true) TextCellValue(ln10.totalAmount),
    ];
    if (tabs[0].client.isEmpty) {
      columnsCells.remove(TextCellValue(ln10.client));
    }
    if (tabs[0].supplier.isEmpty) {
      columnsCells.remove(TextCellValue(ln10.supplier));
    }

    List<CellValue> buildRows(WeighingTab inputTab) {
      List<CellValue> data = [
        if (columns['id'] ?? true) TextCellValue(inputTab.id.toString()),
        if (columns['date'] ?? true)
          TextCellValue(dateToArabicDatetimeExcel(inputTab.createdAt)),
        if (columns['driverName'] ?? true)
          TextCellValue(inputTab.driverName.toString()),
        if (columns['plateNumber'] ?? true)
          TextCellValue(inputTab.truckPlate.toString()),
        if (columns['material'] ?? true)
          TextCellValue(inputTab.material.toString()),
        if ((columns['supplier'] ?? true) && tabs[0].supplier.isNotEmpty)
          TextCellValue(inputTab.supplier.toString()),
        if ((columns['client'] ?? true) && tabs[0].client.isNotEmpty)
          TextCellValue(inputTab.client.toString()),
        if (columns['emptyWeigh'] ?? true) IntCellValue(inputTab.emptyWeight),
        if (columns['grossWeight'] ?? true) IntCellValue(inputTab.grossWeight),
        if (columns['kiloPrice'] ?? true)
          DoubleCellValue(inputTab.kilo_price as double),
        if (columns['netWeight'] ?? true) IntCellValue(inputTab.netWeight),
        if (columns['totalPrice'] ?? true)
          DoubleCellValue(inputTab.total_price as double),
      ];
      return data;
    }

    List<CellValue> buildSumRows() {
      List<CellValue> data = [
        if (columns['id'] ?? true) TextCellValue('الحصيلة'),
        if (columns['date'] ?? true) TextCellValue(''),
        if (columns['driverName'] ?? true) TextCellValue(''),
        if (columns['plateNumber'] ?? true) TextCellValue(''),
        if (columns['material'] ?? true) TextCellValue(''),
        if ((columns['supplier'] ?? true) && tabs[0].supplier.isNotEmpty)
          TextCellValue(''),
        if ((columns['client'] ?? true) && tabs[0].client.isNotEmpty)
          TextCellValue(''),
        if (columns['emptyWeigh'] ?? true) TextCellValue(''),
        if (columns['grossWeight'] ?? true) TextCellValue(''),
        if (columns['kiloPrice'] ?? true) TextCellValue(''),
        if (columns['netWeight'] ?? true) IntCellValue(tabs.totalWeight),
        if (columns['totalPrice'] ?? true)
          DoubleCellValue(tabs.totalPrice as double),
      ];

      return data;
    }

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.black,
      fontSize: 12,
      backgroundColorHex: ExcelColor.blueAccent100,
    );

    final oddRowStyle = CellStyle(
        backgroundColorHex: ExcelColor.blueGrey100,
        numberFormat: NumFormat.defaultFloat);

    // Header (use TextCellValue)
    sheet.appendRow(columnsCells);

    // apply header style to header row (rowIndex 0)
    for (int c = 0; c < columnsCells.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    // Data rows (use TextCellValue and IntCellValue/DoubleCellValue)
    for (int i = 0; i < tabs.length; i++) {
      sheet.appendRow(buildRows(tabs[i]));

      // alternate (greyscale) for every 2nd data row:
      if (i % 2 == 1) {
        final rowIndex = i + 1; // 0 = header, so data starts at 1
        for (int c = 0; c < columnsCells.length; c++) {
          final cellValue = sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: c, rowIndex: rowIndex))
              .value;
          bool isFloat = cellValue is DoubleCellValue;

          sheet
                  .cell(CellIndex.indexByColumnRow(
                      columnIndex: c, rowIndex: rowIndex))
                  .cellStyle =
              oddRowStyle.copyWith(
                  numberFormat: isFloat
                      ? NumFormat.defaultFloat
                      : NumFormat.defaultNumeric);
        }
      }
    }

    sheet.appendRow(buildSumRows());

    // Save file

    String date = dateToArabicDatetimeForFile(DateTime.now());

    final file = File('${selectedDirectory}/الجرد_$date.xlsx')
      ..createSync(recursive: true);
    file.writeAsBytesSync(excel.encode()!);
  }

  Future<void> createSummaryExcel(
      {required List<Map> tabs,
      Map<String, bool>? visibleColumns,
      Map? totals,
      required BuildContext context}) async {
    String? selectedDirectory = await fp.FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      // User canceled the picker
      return;
    }

    Map<String, bool> columns = {
      "kiloPrice": true,
      "netWeight": true,
      "totalPrice": true,
      "totalLoadingCost": true,
      "totalShippingCost": true
    };
    final ln10 = AppLocalizations.of(context)!;
    //TODO dir Pickernzabh
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.setDefaultColumnWidth(24);

    List<CellValue> columnsCells = [
      TextCellValue('الذمة'),
      if (columns['kiloPrice'] ?? true) TextCellValue('سعر الكيلو'),
      if (columns['totalWeight'] ?? true) TextCellValue('وزن البضاعة'),
      if (columns['totalPrice'] ?? true) TextCellValue('قيمة البضاعة'),
      if (columns['totalLoadingCost'] ?? true) TextCellValue('كلفة التعبئة'),
      if (columns['totalShippingCost'] ?? true) TextCellValue('كلفة الشحن'),
      TextCellValue('القيمة النهائية'),
    ].reversed.toList();

    List<CellValue> buildRows(Map entityItem) {
      List<CellValue> data = [
        TextCellValue(entityItem['key'].toString()),
        if (columns['kiloPrice'] ?? true) DoubleCellValue(0.0),
        if (columns['totalWeight'] ?? true)
          IntCellValue(entityItem['total_weight']),
        if (columns['totalPrice'] ?? true)
          DoubleCellValue(entityItem['total_price'] as double),
        if (columns['totalLoadingCost'] ?? true) DoubleCellValue(0.0),
        if (columns['totalShippingCost'] ?? true) DoubleCellValue(0.0),
        DoubleCellValue(0.0),
      ];
      return data.reversed.toList();
    }

    List<CellValue> buildSumRows() {
      List<CellValue> data = [
        TextCellValue('الحصيلة'),
        if (columns['kiloPrice'] ?? true) TextCellValue(''),
        if (columns['totalWeight'] ?? true)
          IntCellValue(totals?['tWeight'] as int ?? 0),
        if (columns['totalPrice'] ?? true)
          DoubleCellValue(totals?['tPrice'] as double ?? 0),
        if (columns['totalLoadingCost'] ?? true) DoubleCellValue(0.0),
        if (columns['totalShippingCost'] ?? true) DoubleCellValue(0.0),
        DoubleCellValue(0.0),
      ];

      return data.reversed.toList();
    }

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.black,
      fontSize: 12,
      backgroundColorHex: ExcelColor.blueAccent100,
    );

    final oddRowStyle = CellStyle(
        backgroundColorHex: ExcelColor.blueGrey100,
        numberFormat: NumFormat.defaultFloat);

    // Header (use TextCellValue)
    sheet.appendRow(columnsCells);

    // apply header style to header row (rowIndex 0)
    for (int c = 0; c < columnsCells.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    // Data rows (use TextCellValue and IntCellValue/DoubleCellValue)
    for (int i = 0; i < tabs.length; i++) {
      sheet.appendRow(buildRows(tabs[i]));

      // alternate (greyscale) for every 2nd data row:
      if (i % 2 == 1) {
        final rowIndex = i + 1; // 0 = header, so data starts at 1
        for (int c = 0; c < columnsCells.length; c++) {
          final cellValue = sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: c, rowIndex: rowIndex))
              .value;
          bool isFloat = cellValue is DoubleCellValue;

          sheet
                  .cell(CellIndex.indexByColumnRow(
                      columnIndex: c, rowIndex: rowIndex))
                  .cellStyle =
              oddRowStyle.copyWith(
                  numberFormat: isFloat
                      ? NumFormat.defaultFloat
                      : NumFormat.defaultNumeric);
        }
      }
    }

    sheet.appendRow(buildSumRows());

    for (int c = 0; c < columnsCells.length; c++) {
      final cellValue = sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: c, rowIndex: tabs.length + 1))
          .value;
      bool isFloat = cellValue is DoubleCellValue;

      sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: c, rowIndex: tabs.length + 1))
              .cellStyle =
          headerStyle.copyWith(
              numberFormat:
                  isFloat ? NumFormat.defaultFloat : NumFormat.defaultNumeric);
    }

    // Save file

    String date = dateToArabicDatetimeForFile(DateTime.now());

    final file = File('${selectedDirectory}/حصيلة_$date.xlsx')
      ..createSync(recursive: true);
    file.writeAsBytesSync(excel.encode()!);
  }

  Future<void> createOperationsExcel(
      {required List<WeighingTab> tabs,
      Map<String, bool>? visibleColumns,
      required BuildContext context}) async {
    String? selectedDirectory = await fp.FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      // User canceled the picker
      return;
    }

    Map<String, bool> columns = {
      "id": true,
      "date": true,
      "driverName": true,
      "plateNumber": true,
      "material": true,
      "supplier": true,
      "client": true,
      "emptyWeight": true,
      "grossWeight": true,
      "kiloPrice": true,
      "netWeight": true,
      "totalPrice": true
    };
    final ln10 = AppLocalizations.of(context)!;
    //TODO dir Pickernzabh
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    List<CellValue> columnsCells = [
      if (columns['id'] ?? true) TextCellValue(ln10.orderNumber),
      if (columns['date'] ?? true) TextCellValue(ln10.dateTime),
      if (columns['driverName'] ?? true) TextCellValue(ln10.driverName),
      if (columns['plateNumber'] ?? true) TextCellValue(ln10.plateNumber),
      if (columns['material'] ?? true) TextCellValue(ln10.material),
      if (columns['supplier'] ?? true) TextCellValue(ln10.supplier),
      if (columns['client'] ?? true) TextCellValue(ln10.client),
      if (columns['emptyWeight'] ?? true) TextCellValue(ln10.emptyWeight),
      if (columns['grossWeight'] ?? true) TextCellValue(ln10.grossWeight),
      if (columns['kiloPrice'] ?? true) TextCellValue(ln10.unitPrice),
      if (columns['netWeight'] ?? true) TextCellValue(ln10.netWeight),
      if (columns['totalPrice'] ?? true) TextCellValue(ln10.totalAmount),
    ];

    List<CellValue> buildRows(WeighingTab inputTab) {
      List<CellValue> data = [
        if (columns['id'] ?? true) TextCellValue(inputTab.id.toString()),
        if (columns['date'] ?? true)
          TextCellValue(dateToArabicDatetimeExcel(inputTab.createdAt)),
        if (columns['driverName'] ?? true)
          TextCellValue(inputTab.driverName.toString()),
        if (columns['plateNumber'] ?? true)
          TextCellValue(inputTab.truckPlate.toString()),
        if (columns['material'] ?? true)
          TextCellValue(inputTab.material.toString()),
        if ((columns['supplier'] ?? true))
          TextCellValue(inputTab.supplier.toString()),
        if ((columns['client'] ?? true))
          TextCellValue(inputTab.client.toString()),
        if (columns['emptyWeigh'] ?? true) IntCellValue(inputTab.emptyWeight),
        if (columns['grossWeight'] ?? true) IntCellValue(inputTab.grossWeight),
        if (columns['kiloPrice'] ?? true)
          DoubleCellValue(inputTab.kilo_price as double),
        if (columns['netWeight'] ?? true) IntCellValue(inputTab.netWeight),
        if (columns['totalPrice'] ?? true)
          DoubleCellValue(inputTab.total_price as double),
      ];
      return data;
    }

    List<CellValue> buildSumRows() {
      List<CellValue> data = [
        if (columns['id'] ?? true) TextCellValue('الحصيلة'),
        if (columns['date'] ?? true) TextCellValue(''),
        if (columns['driverName'] ?? true) TextCellValue(''),
        if (columns['plateNumber'] ?? true) TextCellValue(''),
        if (columns['material'] ?? true) TextCellValue(''),
        if ((columns['supplier'] ?? true)) TextCellValue(''),
        if ((columns['client'] ?? true)) TextCellValue(''),
        if (columns['emptyWeigh'] ?? true) TextCellValue(''),
        if (columns['grossWeight'] ?? true) TextCellValue(''),
        if (columns['kiloPrice'] ?? true) TextCellValue(''),
        if (columns['netWeight'] ?? true) IntCellValue(tabs.totalWeight),
        if (columns['totalPrice'] ?? true)
          DoubleCellValue(tabs.totalPrice as double),
      ];
      return data;
    }

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.black,
    );

    final oddRowStyle = CellStyle(backgroundColorHex: ExcelColor.blueAccent100);

    // Header (use TextCellValue)
    sheet.appendRow(columnsCells);

    // apply header style to header row (rowIndex 0)
    for (int c = 0; c < columnsCells.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    // Data rows (use TextCellValue and IntCellValue/DoubleCellValue)
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i].status == 'cancelled') continue;
      sheet.appendRow(buildRows(tabs[i]));

      // alternate (greyscale) for every 2nd data row:
      if (i % 2 == 1) {
        final rowIndex = i + 1; // 0 = header, so data starts at 1
        for (int c = 0; c < columnsCells.length; c++) {
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: c, rowIndex: rowIndex))
              .cellStyle = oddRowStyle;
        }
      }
    }

    // sheet.appendRow(buildSumRows());

    // Save file

    String date = dateToArabicDatetimeForFile(DateTime.now());

    final file = File('${selectedDirectory}/الجرد_$date.xlsx')
      ..createSync(recursive: true);
    file.writeAsBytesSync(excel.encode()!);
  }
}
