import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'document_errors.dart';

MapData decodeValidatedMapDocument(
  List<int> bytes,
  String path, {
  void Function(MapData map)? validateMap,
}) {
  final decoded = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
  if (decoded is! Map) {
    throw NarrativeEventAuthoringSessionException(
      'La map $path doit être un objet JSON.',
    );
  }
  final json = <String, dynamic>{};
  for (final entry in decoded.entries) {
    if (entry.key is! String) {
      throw NarrativeEventAuthoringSessionException(
        'La map $path contient une clé invalide.',
      );
    }
    json[entry.key as String] = entry.value;
  }
  final map = MapData.fromJson(json);
  (validateMap ?? MapValidator.validate)(map);
  return map;
}
