String normalizeArabic(String input) {
  final diacritics = RegExp(r'[ًٌٍَُِّْ]');
  const tatweel = 'ـ';

  return input
      .replaceAll(diacritics, '') // Remove diacritics
      .replaceAll(tatweel, '') // Remove Tatweel
      .replaceAll(RegExp(r'[إأآٱ]'), 'ا') // Alef variants → Alef
      .replaceAll('ى', 'ي') // Alef Maqsura → Yeh
      .replaceAll('ة', 'ت')
      .replaceAll('ه', 'ت') // Teh Marbuta → Heh
      .replaceAll(RegExp(r'[ئءؤ]'), 'ء') // Waw with Hamza → Waw
      .trim(); // Remove leading/trailing whitespace
}
