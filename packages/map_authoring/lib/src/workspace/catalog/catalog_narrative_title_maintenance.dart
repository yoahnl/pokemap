import 'dart:math';

import 'package:map_core/map_core.dart';

import '../../support/authoring_fingerprint.dart';
import 'catalog_derivable_indexes.dart';
import 'catalog_metadata_documents.dart';
import 'catalog_narrative_event_documents.dart';
import 'catalog_narrative_title_rows.dart';

typedef _KindPatch = ({
  int count,
  List<CatalogDefinitionUnit> upserts,
  List<CatalogDefinitionKey> removals
});

abstract final class CatalogNarrativeTitleMaintenance {
  static Future<CatalogDerivedPatch> maintain({
    required CatalogDerivedLookup lookup,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
  }) async {
    final none = (
      upserts: <CatalogDefinitionUnit>[],
      removals: <CatalogDefinitionKey>[]
    );
    final changed = <String, Map<int, CatalogDefinitionUnit>>{};
    final removed = <String, Set<int>>{};
    for (final unit in upserts) {
      final location = CatalogNarrativeTitleRows.definitionLocation(unit.key);
      if (location != null) {
        changed.putIfAbsent(location.$1, () => {})[location.$2] = unit;
      }
    }
    for (final key in removals) {
      final location = CatalogNarrativeTitleRows.definitionLocation(key);
      if (location != null) {
        removed.putIfAbsent(location.$1, () => {}).add(location.$2);
      }
    }
    final pending = {for (final unit in upserts) unit.key: unit};
    final removedKeys = removals.toSet();
    final eventsChanged = await CatalogNarrativeEventDocuments.registryChanged(
        lookup, pending, removedKeys);
    if (changed.isEmpty && removed.isEmpty && !eventsChanged) return none;
    final states = CatalogNarrativeTitleRows.kindStates(
        await lookup(CatalogNarrativeTitleRows.markerKey));
    if (states == null) return none;
    final next = {for (final entry in states.entries) entry.key: entry.value};
    final result = none;
    void record(String kind, _KindPatch? patch, int count) {
      if (patch == null) {
        next[kind] = {
          'stale': true,
          'pageCount': CatalogNarrativeTitleRows.pageCount(count)
        };
        return;
      }
      result.upserts.addAll(patch.upserts);
      result.removals.addAll(patch.removals);
      next[kind] = {'count': patch.count};
    }

    for (final kind in {...changed.keys, ...removed.keys}) {
      final count = states[kind]!['count'];
      if (count is! int) continue;
      record(
          kind,
          await _field(lookup, kind, count, changed[kind] ?? const {},
              removed[kind] ?? const {}),
          count);
    }
    final eventCount = states[CatalogNarrativeTitleRows.eventKind]!['count'];
    if (eventsChanged && eventCount is int) {
      List<Map<String, Object?>> entries(
              Iterable<CatalogDefinitionUnit> units) =>
          CatalogNarrativeTitleRows.eventEntries(
              CatalogNarrativeEventDocuments.decodeRegistry(units));
      final before =
          entries(await CatalogNarrativeEventDocuments.registryUnits(lookup));
      final after = entries(await CatalogNarrativeEventDocuments.registryUnits(
          lookup,
          pending: pending,
          removed: removedKeys,
          after: true));
      record(
          CatalogNarrativeTitleRows.eventKind,
          before.length == eventCount
              ? await _lists(
                  lookup, CatalogNarrativeTitleRows.eventKind, before, after)
              : null,
          eventCount);
    }
    if (CatalogNarrativeTitleRows.kinds
        .any((kind) => !_same(states[kind], next[kind]))) {
      result.upserts.add(CatalogNarrativeTitleRows.markerUnit(next));
    }
    return result;
  }

  static Future<_KindPatch?> _field(
      CatalogDerivedLookup lookup,
      String field,
      int count,
      Map<int, CatalogDefinitionUnit> changes,
      Set<int> removed) async {
    final int length;
    if (removed.isNotEmpty) {
      length = removed.reduce(min);
      if (removed.length != count - length ||
          removed.any((position) => position >= count) ||
          changes.keys.any((position) => position >= length)) {
        return null;
      }
    } else {
      final appended =
          changes.keys.where((position) => position >= count).toList()..sort();
      for (var i = 0; i < appended.length; i++) {
        if (appended[i] != count + i) return null;
      }
      length = count + appended.length;
    }
    final after = <int, Map<String, Object?>>{};
    final before = <int, Map<String, Object?>>{};
    for (final MapEntry(key: position, value: unit) in changes.entries) {
      final entry =
          CatalogNarrativeTitleRows.definitionEntry(unit, field, position);
      if (position < count) {
        final previous = await lookup(
            CatalogMetadataDocuments.definitionKey(field, position));
        if (previous == null) return null;
        final old = CatalogNarrativeTitleRows.definitionEntry(
            previous, field, position);
        if (_same(old, entry)) continue;
        before[position] = old;
      }
      after[position] = entry;
    }
    final pages = {
      for (final position in after.keys)
        position ~/ CatalogNarrativeTitleRows.pageSize,
      if (length < count && length % CatalogNarrativeTitleRows.pageSize != 0)
        (length - 1) ~/ CatalogNarrativeTitleRows.pageSize,
    };
    final upserts = <CatalogDefinitionUnit>[];
    for (final page in pages) {
      if (page >= CatalogNarrativeTitleRows.pageCount(length)) continue;
      final old = await _read(lookup, field, count, page);
      if (old == null) return null;
      final start = page * CatalogNarrativeTitleRows.pageSize;
      for (final MapEntry(key: position, value: entry) in before.entries) {
        if (position ~/ CatalogNarrativeTitleRows.pageSize == page &&
            !_same(old[position - start], entry)) {
          return null;
        }
      }
      final entries = [
        for (var i = 0;
            i < CatalogNarrativeTitleRows.pageLength(length, page);
            i++)
          after[start + i] ?? old[i],
      ];
      if (!_same(entries, old)) {
        upserts.add(CatalogNarrativeTitleRows.pageUnit(field, page, entries));
      }
    }
    return (
      count: length,
      upserts: upserts,
      removals: _trailing(field, length, count),
    );
  }

  static Future<_KindPatch?> _lists(
      CatalogDerivedLookup lookup,
      String kind,
      List<Map<String, Object?>> before,
      List<Map<String, Object?>> after) async {
    final pages = <int>{
      for (var i = 0; i < max(before.length, after.length); i++)
        if (i >= before.length ||
            i >= after.length ||
            !_same(before[i], after[i]))
          i ~/ CatalogNarrativeTitleRows.pageSize,
    };
    final upserts = <CatalogDefinitionUnit>[];
    for (final page in pages) {
      if (page >= CatalogNarrativeTitleRows.pageCount(after.length)) continue;
      final old = await _read(lookup, kind, before.length, page);
      final start = page * CatalogNarrativeTitleRows.pageSize;
      if (old == null ||
          !_same(
              old,
              before.sublist(
                  min(start, before.length),
                  min(start + CatalogNarrativeTitleRows.pageSize,
                      before.length)))) {
        return null;
      }
      upserts.add(CatalogNarrativeTitleRows.pageUnit(
          kind,
          page,
          after.sublist(
              start,
              start +
                  CatalogNarrativeTitleRows.pageLength(after.length, page))));
    }
    return (
      count: after.length,
      upserts: upserts,
      removals: _trailing(kind, after.length, before.length),
    );
  }

  static Future<List<Map<String, Object?>>?> _read(
      CatalogDerivedLookup lookup, String kind, int count, int page) async {
    if (page >= CatalogNarrativeTitleRows.pageCount(count)) return const [];
    try {
      return CatalogNarrativeTitleRows.pageEntries(
          await lookup(CatalogNarrativeTitleRows.pageKey(kind, page)),
          kind,
          page,
          expectedLength: CatalogNarrativeTitleRows.pageLength(count, page));
    } on FormatException {
      return null;
    }
  }

  static List<CatalogDefinitionKey> _trailing(
          String kind, int length, int count) =>
      [
        for (var page = CatalogNarrativeTitleRows.pageCount(length);
            page < CatalogNarrativeTitleRows.pageCount(count);
            page++)
          CatalogNarrativeTitleRows.pageKey(kind, page),
      ];

  static bool _same(Object? a, Object? b) =>
      canonicalAuthoringJson(a) == canonicalAuthoringJson(b);
}
