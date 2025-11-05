DateTime getTodayStartDate() {
  return DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
}

DateTime getTodayEndDate() {
  return DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day + 1,
  );
}

DateTime getYesterdayStartDate() {
  return DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day - 1,
  );
}

DateTime getYesterdayEndDate() {
  return DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
}

DateTime getLast7StartDate() {
  return DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day - 7,
  );
}

DateTime getLast7EndDate() {
  return DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day + 1,
  );
}

DateTime getLast30StartDate() {
  return DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day - 30,
  );
}

DateTime getLast30EndDate() {
  return DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day + 1,
  );
}
