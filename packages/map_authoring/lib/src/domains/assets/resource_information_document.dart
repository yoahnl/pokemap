import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../workspace/project_snapshot.dart';
import '../maps/smart_tile_catalog_document.dart';

List<int> encodeResourceInformationDocument(
    ProjectSnapshot snapshot, ProjectManifest manifest) {
  final original = jsonDecode(utf8.decode(snapshot.resourceBytes('project')));
  if (original is! Map<String, dynamic>) {
    throw const FormatException('The original resource manifest is invalid.');
  }
  final merged = Map<String, Object?>.from(
      _mergeChanged(original, snapshot.manifest.toJson(), manifest.toJson())
          as Map);
  if (manifest.smartTileCatalog.isNotEmpty ||
      merged.containsKey('smartTileCatalog')) {
    merged['smartTileCatalog'] = canonicalSmartTileCatalogDocument(
        original['smartTileCatalog'],
        snapshot.manifest.smartTileCatalog,
        manifest.smartTileCatalog);
  }
  return utf8.encode(jsonEncode(merged));
}

Object? _mergeChanged(Object? original, Object? before, Object? after) {
  if (jsonEncode(before) == jsonEncode(after)) return original;
  if (before is Map && after is Map && original is Map) {
    final merged = Map<String, Object?>.from(original);
    for (final key in before.keys.where((key) => !after.containsKey(key))) {
      merged.remove(key);
    }
    for (final key in after.keys) {
      merged[key as String] =
          before.containsKey(key) && original.containsKey(key)
              ? _mergeChanged(original[key], before[key], after[key])
              : after[key];
    }
    return merged;
  }
  if (before is List &&
      after is List &&
      original is List &&
      before.every((item) => item is Map && item['id'] is String) &&
      after.every((item) => item is Map && item['id'] is String) &&
      original.every((item) => item is Map && item['id'] is String)) {
    final prior = {for (final item in before) (item as Map)['id']: item};
    final raw = {for (final item in original) (item as Map)['id']: item};
    return [
      for (final item in after)
        if (prior.containsKey((item as Map)['id']) &&
            raw.containsKey(item['id']))
          _mergeChanged(raw[item['id']], prior[item['id']], item)
        else
          item
    ];
  }
  return after;
}
