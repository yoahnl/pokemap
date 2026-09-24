import 'dart:convert';

import 'package:map_core/map_core.dart';

final class PokemonMovesCatalogMergeResult {
  const PokemonMovesCatalogMergeResult({
    required this.catalog,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
  });

  final PokemonCatalogFile catalog;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
}

final class PokemonMovesCatalogMerge {
  const PokemonMovesCatalogMerge();

  PokemonMovesCatalogMergeResult merge({
    required PokemonCatalogFile? localCatalog,
    required PokemonCatalogFile externalCatalog,
  }) {
    final localById = <String, Map<String, dynamic>>{
      for (final entry
          in localCatalog?.entries ?? const <Map<String, dynamic>>[])
        ((entry['id'] as String?)?.trim() ?? ''): _copy(entry),
    }..remove('');
    final externalById = <String, Map<String, dynamic>>{
      for (final entry in externalCatalog.entries)
        ((entry['id'] as String?)?.trim() ?? ''): _copy(entry),
    }..remove('');
    final created = <String>[];
    final updated = <String>[];
    final unchanged = <String>[];
    final merged = <Map<String, dynamic>>[];
    for (final external in externalById.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      final local = localById.remove(external.key);
      if (local == null) {
        created.add(external.key);
        merged.add(_copy(external.value));
        continue;
      }
      final result = _mergeEntry(local, external.value);
      if (_equals(local, result)) {
        unchanged.add(external.key);
      } else {
        updated.add(external.key);
      }
      merged.add(result);
    }
    final preserved = localById.keys.toList()..sort();
    for (final id in preserved) {
      merged.add(_copy(localById[id]!));
    }
    merged.sort((a, b) =>
        ((a['id'] as String?) ?? '').compareTo((b['id'] as String?) ?? ''));
    final externalMeta = externalCatalog.meta;
    final localMeta = localCatalog?.meta;
    return PokemonMovesCatalogMergeResult(
      catalog: PokemonCatalogFile(
        schemaVersion: externalCatalog.schemaVersion,
        kind: externalCatalog.kind,
        catalog: externalCatalog.catalog,
        meta: PokemonDataMeta(
          description: externalMeta.description,
          sourcePriority: externalMeta.sourcePriority,
          notes: [
            ...externalMeta.notes,
            if (localMeta != null)
              ...localMeta.notes.where(
                (note) => !externalMeta.notes.contains(note),
              ),
          ],
        ),
        entries: merged,
      ),
      createdIds: created,
      updatedIds: updated,
      unchangedIds: unchanged,
      preservedLocalOnlyIds: preserved,
    );
  }

  Map<String, dynamic> _mergeEntry(
    Map<String, dynamic> local,
    Map<String, dynamic> external,
  ) {
    final merged = <String, dynamic>{};
    for (final field in external.entries) {
      final localValue = local[field.key];
      if (field.key == 'names' &&
          localValue is Map &&
          field.value is Map<String, dynamic>) {
        merged[field.key] = {
          for (final entry in localValue.entries)
            if (entry.key is String)
              entry.key as String: _copyValue(entry.value),
          for (final entry in (field.value as Map<String, dynamic>).entries)
            entry.key: _copyValue(entry.value),
        };
      } else {
        merged[field.key] = _copyValue(field.value ?? localValue);
      }
    }
    for (final field in local.entries) {
      if (_canonical(external) &&
          const {'power', 'accuracyText', 'shortDesc'}.contains(field.key)) {
        continue;
      }
      merged.putIfAbsent(field.key, () => _copyValue(field.value));
    }
    return merged;
  }

  bool _canonical(Map<String, dynamic> entry) =>
      entry.containsKey('basePower') ||
      entry.containsKey('effects') ||
      entry.containsKey('sourceRefs') ||
      entry.containsKey('engineSupportLevel') ||
      entry.containsKey('unsupportedReasons') ||
      entry.containsKey('noPpBoosts') ||
      entry.containsKey('critRatio') ||
      entry['accuracy'] is Map;

  Map<String, dynamic> _copy(Map<String, dynamic> value) =>
      (jsonDecode(jsonEncode(value)) as Map).cast<String, dynamic>();

  Object? _copyValue(Object? value) =>
      value == null ? null : jsonDecode(jsonEncode(value));

  bool _equals(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      for (final key in left.keys) {
        if (!right.containsKey(key) || !_equals(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (!_equals(left[index], right[index])) return false;
      }
      return true;
    }
    return left == right;
  }
}
