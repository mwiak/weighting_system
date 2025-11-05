import 'package:fluent_ui/fluent_ui.dart';
import '../l10n/app_localizations.dart';

class TimeDialog extends StatefulWidget {
  DateTime inputDate;
  final Function onChanged;
  TimeDialog({super.key, required this.inputDate, required this.onChanged});

  @override
  State<TimeDialog> createState() => _TimeDialogState();
}

class _TimeDialogState extends State<TimeDialog> {
  int tempSeconds = 0;
  late DateTime tempDate;

  @override
  void initState() {
    super.initState();
    tempDate = widget.inputDate;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ContentDialog(
      constraints: const BoxConstraints(
        maxWidth: 400,
        maxHeight: 900,
      ),
      title: Row(
        children: [Text('اختر التاريخ و الوقت')],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DatePicker(
            selected: tempDate,
            onChanged: (date) {
              tempDate = tempDate.copyWith(
                  year: date.year, month: date.month, day: date.day);
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          TimePicker(
            selected: tempDate,
            onChanged: (time) {
              tempDate = tempDate.copyWith(
                  hour: time.hour, minute: time.minute, second: time.second);
              setState(() {});
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
                      setState(() {});
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
          child: Text(l10n.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Button(
          child: Text(l10n.save),
          onPressed: () {
            widget.onChanged(tempDate);

            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
