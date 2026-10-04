import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../workspace/project_snapshot.dart';

List<String> unsupportedMapDuplicateFields(
    ProjectSnapshot snapshot, MapData map) {
  final fields = <String>[];
  void compare(Object? original, Object? represented, String path) {
    if (original is Map && represented is Map) {
      for (final entry in original.entries) {
        final childPath = '$path/${entry.key}';
        if (!represented.containsKey(entry.key)) {
          fields.add(childPath);
        } else {
          compare(entry.value, represented[entry.key], childPath);
        }
      }
    } else if (original is List && represented is List) {
      for (var index = 0; index < original.length; index++) {
        if (index >= represented.length) {
          fields.add('$path/$index');
        } else {
          compare(original[index], represented[index], '$path/$index');
        }
      }
    }
  }

  compare(jsonDecode(utf8.decode(snapshot.resourceBytes('map:${map.id}'))),
      map.toJson(), '');
  return fields;
}
