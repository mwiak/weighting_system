import '../models/weighing_tab.dart';

Map<String, WeighingTab> sortWeightMapIsolate(Map<String, WeighingTab> map) {
  final entries = map.entries.toList()
    ..sort((a, b) => b.value.grossWeight.compareTo(a.value.grossWeight));

  return {for (final e in entries) e.key: e.value};
}

Map<String, List<WeighingTab>> sortSupplierOrClientMap(
    Map<String, List<WeighingTab>> input) {
  // if (false){
  //   final entries = input.entries.toList()
  //     ..sort((a, b) => b.value.grossWeight.compareTo(a.value.grossWeight));
  //
  //   return {for (final e in entries) e.key: e.value};
  // }
  Map<String, List<WeighingTab>> result = {};
  List<Map<String, int>> sotred = [];
  if (input.isEmpty) {
    return {};
  }
  for (String key in input.keys) {
    sotred.add({key: input[key]!.totalWeight});
  }
  sotred.sort((a, b) => b.values.first - a.values.first);
  for (Map<String, int> x in sotred) {
    result[x.keys.first] = input[x.keys.first]!;
  }
  return result;
}

Map<String, Map<String, Map<String, List<WeighingTab>>>>
    sortWeightMaterialsIsolate(
        Map<String, Map<String, Map<String, List<WeighingTab>>>> map) {
  Map<String, Map<String, Map<String, List<WeighingTab>>>> sortedMap = {};
  for (String key in map.keys) {
    final clients = sortSupplierOrClientMap(map[key]!['clients']!);
    final suppliers = sortSupplierOrClientMap(map[key]!['suppliers']!);
    sortedMap[key] = {'clients': clients, 'suppliers': suppliers};
  }

  return sortedMap;
}
