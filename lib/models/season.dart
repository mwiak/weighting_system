class Season {
  int firstYear = 0;
  int lastYear = 0;
  int monthOfStart = 0;
  int dayOfStart = 0;

  Season(
      {required this.firstYear,
      required this.lastYear,
      required this.monthOfStart,
      required this.dayOfStart});

  DateTime get seasonStartDate => DateTime(firstYear, monthOfStart, dayOfStart);
  DateTime get seasonEndDate => DateTime(lastYear, monthOfStart, dayOfStart);

  String get label => 'موسم  $firstYear - $lastYear';
}
