import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:weighing_system/database/database_helper.dart';
import 'package:weighing_system/models/season.dart';

class SeasonsProvider extends ChangeNotifier {
  DatabaseHelper db = DatabaseHelper();
  List<Season> availableSeasons = [];

  SeasonsProvider() {
    calculateSeasons();
  }

  void calculateSeasons() async {
    availableSeasons = [];
    final data =
        await db.query('prefs', where: 'setting = ?', whereArgs: ['seasons']);
    final now = DateTime.now();
    if (data.isEmpty) return;

    final Map values = json.decode(data[0]['data']);

    final dateOfInversion = DateTime.parse(values['dayOfInversion']);
    int dayOfInversion = dateOfInversion.day;
    int monthOfInversion = dateOfInversion.month;

    final firstSeason = DateTime.parse(values['firstSeason']);

    if (isBeforeDay(firstSeason, monthOfInversion, dayOfInversion)) {
      availableSeasons.add(Season(
          firstYear: firstSeason.year - 1,
          lastYear: firstSeason.year,
          monthOfStart: monthOfInversion,
          dayOfStart: dayOfInversion));
    } else {
      availableSeasons.add(Season(
          firstYear: firstSeason.year,
          lastYear: firstSeason.year + 1,
          monthOfStart: monthOfInversion,
          dayOfStart: dayOfInversion));
    }

    int firstSeasonToNowYearDiff = availableSeasons[0].lastYear - now.year;
    if (firstSeasonToNowYearDiff == 0) return;

    while (true) {
      bool isNextYear = DateTime(now.year, now.month, now.day).isAfter(DateTime(
          availableSeasons.last.lastYear, monthOfInversion, dayOfInversion));
      if (isNextYear) {
        availableSeasons.add(Season(
            firstYear: availableSeasons.last.lastYear,
            lastYear: availableSeasons.last.lastYear + 1,
            monthOfStart: monthOfInversion,
            dayOfStart: dayOfInversion));
      } else {
        break;
      }
    }
  }

  bool isBeforeDay(DateTime date1, int month2, int day2) {
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date1.year, month2, day2);

    return d1.isBefore(d2);
  }
}
