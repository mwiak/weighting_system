import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void openDateTimePicker(
    BuildContext context, DateTime input, Function onChanged) async {
  var selectedDateTime = input;
  DateTime tempDate = selectedDateTime ?? DateTime.now();

  await showDialog(
    context: context,
    builder: (context) {
      int tempSeconds = 0;
      final l11n = AppLocalizations.of(context)!;
      return ContentDialog(
        title: const Text('اختر تاريخ و وقت الإنشاء'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DatePicker(
              selected: tempDate,
              onChanged: (date) {
                tempDate = tempDate.copyWith(
                    year: date.year, month: date.month, day: date.day);
              },
            ),
            const SizedBox(height: 12),
            TimePicker(
              selected: tempDate,
              onChanged: (time) {
                tempDate = tempDate.copyWith(
                    hour: time.hour, minute: time.minute, second: time.second);
              },
            ),
            const SizedBox(height: 12),
            // Seconds selector
            Row(
              children: [
                const Text('الثواني:'),
                const SizedBox(width: 10),
                Expanded(
                  child: ComboBox<int>(
                    value: tempSeconds,
                    items: List.generate(
                      60,
                      (i) => ComboBoxItem(
                        value: i,
                        child: Text(i.toString().padLeft(2, '0')),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        tempSeconds = value;
                        tempDate = tempDate.copyWith(second: value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Button(
            child: Text(l11n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: Text(l11n.continue_),
            onPressed: () {
              selectedDateTime = tempDate;
              onChanged(tempDate);
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}
