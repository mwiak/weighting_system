import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:weighing_system/widgets/time_dialog.dart';
import '../l10n/app_localizations.dart';

void openDateTimePicker(
    BuildContext context, DateTime input, Function onChanged) async {
  var selectedDateTime = input;
  DateTime tempDate = selectedDateTime;

  await showDialog(
    context: context,
    builder: (context) {
      return TimeDialog(
        inputDate: tempDate,
        onChanged: onChanged,
      );
    },
  );
}
