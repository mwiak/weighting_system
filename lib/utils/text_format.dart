String replaceArabicNumbers(String input) {
  const easternArabicNumerals = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  return input.split('').map((char) {
    return easternArabicNumerals[char] ?? char;
  }).join();
}

String replaceEnglishNumbers(String input) {
  const easternArabicNumerals = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };

  return input.split('').map((char) {
    return easternArabicNumerals[char] ?? char;
  }).join();
}
