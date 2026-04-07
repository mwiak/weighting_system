import 'package:weighing_system/utils/debugging_methods.dart';

String formatLargeNumber(String? input) {
  if (input == null) return '';

  final int numberOfDigits = input.length;
  printd(input);

  switch (numberOfDigits) {
    case 0:
      return '';
    case 1:
      return input;
    case 2:
      return input;
    case 3:
      return input;
    case 4:
      String result = input.substring(0, 1) + ' ' + input.substring(1);

      return result;
    case 5:
      String result = input.substring(0, 2) + ' ' + input.substring(2);
      printd(result);
      return result;
    case 6:
      String result = '${input.substring(0, 3)} , ${input.substring(3)}';
      printd(result);
      return result;
    // case 7:
    //   String result = '${input.substring(0, 3)} , ${input.substring(4)}';
    //   return result;

    default:
      return input;
  }
}

String? formatLargeNumber2(String? input) {
  if (input == null) return '';
  final int digits = input.length;
  const int MAX = 3;

  if (digits <= 3) {
    return input;
  } else {
    List<String> chars = input.split('').reversed.toList();
    for (String x in chars) {}
  }
}

String formatLargeNumber3(String input) {
  printd(input);
  final buffer = StringBuffer();
  int count = 0;

  for (int i = input.length - 1; i >= 0; i--) {
    buffer.write(input[i]);
    count++;

    // Add space after every 3 chars if more chars remain
    if (count % 3 == 0 && i != 0) {
      buffer.write(' ');
    }
  }

  // Reverse because we built it from right to left
  return buffer.toString().split('').reversed.join();
}
