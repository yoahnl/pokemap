import 'package:map_core/map_core.dart';

Map<String, Object?> canonicalSmartTileCatalogDocument(
  Object? original,
  ProjectSmartTileCatalog before,
  ProjectSmartTileCatalog after,
) {
  final complete = after.toJson(compact: false);
  final merged = before == after
      ? original
      : _mergeCatalogChanges(original, before.toJson(compact: false), complete);
  return _retainUnknownCatalogValues(merged, complete, after.toJson())
      as Map<String, Object?>;
}

Object? _mergeCatalogChanges(Object? original, Object? before, Object? after,
    {String? field}) {
  if (_sameCatalogValue(before, after)) return original;
  if (before is Map && after is Map && original is Map) {
    final merged = Map<String, Object?>.from(original);
    for (final key in before.keys.where((key) => !after.containsKey(key))) {
      merged.remove(key);
    }
    for (final entry in after.entries) {
      merged[entry.key as String] =
          before.containsKey(entry.key) && original.containsKey(entry.key)
              ? _mergeCatalogChanges(
                  original[entry.key], before[entry.key], entry.value,
                  field: entry.key as String)
              : entry.value;
    }
    return merged;
  }
  if (before is List && after is List && original is List) {
    if (_hasCatalogIds(before) &&
        _hasCatalogIds(after) &&
        _hasCatalogIds(original)) {
      final prior = {for (final value in before) (value as Map)['id']: value};
      final raw = {for (final value in original) (value as Map)['id']: value};
      return [
        for (final value in after)
          if (prior.containsKey((value as Map)['id']) &&
              raw.containsKey(value['id']))
            _mergeCatalogChanges(raw[value['id']], prior[value['id']], value)
          else
            value,
      ];
    }
    if (field == 'parts' &&
        before.every((value) => value is Map && value['source'] is Map) &&
        after.every((value) => value is Map && value['source'] is Map) &&
        original.length == before.length) {
      return _mergeVisualPartChanges(original, before, after);
    }
  }
  return after;
}

List<Object?> _mergeVisualPartChanges(List original, List before, List after) {
  final matches = <int, int>{};
  final used = <int>{};
  void assign(int targetIndex, List<int> candidates) {
    if (candidates.isEmpty) return;
    late final int sourceIndex;
    if (candidates.length == 1) {
      sourceIndex = candidates.single;
    } else if (before.length == after.length &&
        candidates.contains(targetIndex) &&
        _sameCatalogValue(before[targetIndex], after[targetIndex])) {
      sourceIndex = targetIndex;
    } else if (candidates.any(
        (index) => _hasUnknownCatalogFields(original[index], before[index]))) {
      throw const FormatException(
          'Existing Smart Tile visual extensions have an ambiguous identity.');
    } else {
      sourceIndex = candidates.first;
    }
    matches[targetIndex] = sourceIndex;
    used.add(sourceIndex);
  }

  for (var index = 0; index < after.length; index++) {
    assign(index, [
      for (var prior = 0; prior < before.length; prior++)
        if (!used.contains(prior) &&
            _sameCatalogValue(before[prior], after[index]))
          prior,
    ]);
  }
  for (var index = 0; index < after.length; index++) {
    if (matches.containsKey(index)) continue;
    assign(index, [
      for (var prior = 0; prior < before.length; prior++)
        if (!used.contains(prior) &&
            _sameCatalogValue((before[prior] as Map)['source'],
                (after[index] as Map)['source']))
          prior,
    ]);
  }
  return [
    for (var index = 0; index < after.length; index++)
      if (matches[index] case final int prior)
        _mergeCatalogChanges(original[prior], before[prior], after[index])
      else
        after[index],
  ];
}

bool _hasCatalogIds(List values) =>
    values.every((value) => value is Map && value['id'] is String);

bool _sameCatalogValue(Object? left, Object? right) {
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.keys.every((key) =>
            right.containsKey(key) && _sameCatalogValue(left[key], right[key]));
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        Iterable<int>.generate(left.length)
            .every((index) => _sameCatalogValue(left[index], right[index]));
  }
  return left == right;
}

bool _hasUnknownCatalogFields(Object? raw, Object? known) {
  if (raw is Map && known is Map) {
    return raw.keys.any((key) =>
        !known.containsKey(key) ||
        _hasUnknownCatalogFields(raw[key], known[key]));
  }
  if (raw is List && known is List) {
    return raw.length == known.length &&
        Iterable<int>.generate(raw.length)
            .any((index) => _hasUnknownCatalogFields(raw[index], known[index]));
  }
  return false;
}

Object? _retainUnknownCatalogValues(
    Object? original, Object? complete, Object? compact) {
  if (complete is Map && compact is Map) {
    final raw = original is Map ? original : const <String, Object?>{};
    final result = Map<String, Object?>.from(raw);
    for (final key in complete.keys) {
      if (compact.containsKey(key)) continue;
      result.remove(key);
      if (complete[key] is Map && raw[key] is Map) {
        final extensions = _retainUnknownCatalogValues(
            raw[key], complete[key], const <String, Object?>{}) as Map;
        if (extensions.isNotEmpty) {
          result[key as String] = (complete[key] as Map).containsKey('kind')
              ? {...complete[key] as Map, ...extensions}
              : extensions;
        }
      }
    }
    for (final entry in compact.entries) {
      result[entry.key as String] = _retainUnknownCatalogValues(
          raw[entry.key], complete[entry.key], entry.value);
    }
    return result;
  }
  if (complete is List && compact is List) {
    if (complete.length != compact.length) {
      throw StateError('Smart Tile compaction changed collection length.');
    }
    final raw = original is List ? original : const <Object?>[];
    final byId = {
      for (final value in raw)
        if (value is Map && value['id'] is String) value['id']: value,
    };
    return [
      for (var index = 0; index < compact.length; index++)
        _retainUnknownCatalogValues(
          compact[index] is Map && (compact[index] as Map)['id'] is String
              ? byId[(compact[index] as Map)['id']]
              : index < raw.length
                  ? raw[index]
                  : null,
          complete[index],
          compact[index],
        ),
    ];
  }
  return compact;
}
