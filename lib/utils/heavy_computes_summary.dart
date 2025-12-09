import '../models/weighing_tab.dart';

Map<String, WeighingTab> sortWeightMapIsolate(Map<String, WeighingTab> map) {
  final entries = map.entries.toList()
    ..sort((a, b) => b.value.grossWeight.compareTo(a.value.grossWeight));

  return {for (final e in entries) e.key: e.value};
}
