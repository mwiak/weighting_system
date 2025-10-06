import 'package:intl/intl.dart';
import 'package:weighing_system/utils/text_format.dart';

String dateToArabicDatetime(DateTime input) {
  final formatter = DateFormat('EEEE  yyyy/MM/dd --  hh:mm a ', 'ar');

  return formatter.format(input);
}

String dateToArabicDatetimeOperationEntry(DateTime input) {
  final formatter = DateFormat('EEEE\ndd/ MM / yyyy\nhh:mm a', 'ar');

  return formatter.format(input);
}

String dateToArabicDatetimeExcel(DateTime input) {
  final formatter = DateFormat('EEEE_dd/ MM / yyyy_hh:mm a', 'ar');

  return formatter.format(input);
}

String dateToArabicDatetimeShort(DateTime input) {
  final formatter = DateFormat('yyyy/MM/dd-hh:mm a', 'ar');

  return formatter.format(input);
}

String dateToArabicDatetimeForFile(DateTime input) {
  final formatter = DateFormat('yyyy_MM_dd_hh_mm_a', 'ar');

  return formatter.format(input);
}
