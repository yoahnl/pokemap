import 'package:map_core/map_core.dart';

import '../../support/authoring_fingerprint.dart';
import 'catalog_narrative_titles.dart';

typedef CatalogDerivedLookup = Future<CatalogDefinitionUnit?> Function(
    CatalogDefinitionKey key);

typedef CatalogDerivedPatch = ({
  List<CatalogDefinitionUnit> upserts,
  List<CatalogDefinitionKey> removals
});

abstract interface class CatalogDerivableIndex {
  CatalogDefinitionKey get marker;

  bool owns(CatalogDefinitionKey key);

  List<CatalogDefinitionUnit> initialize(Iterable<CatalogDefinitionUnit> units);

  Future<List<CatalogDefinitionUnit>> sources(CatalogDerivedLookup lookup);

  Iterable<CatalogDefinitionKey> rowKeys(CatalogDefinitionUnit marker);

  Future<CatalogDerivedPatch> maintain({
    required CatalogDerivedLookup lookup,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
  });
}

abstract final class CatalogDerivableIndexes {
  static const List<CatalogDerivableIndex> all = [CatalogNarrativeTitles.index];

  static List<CatalogDefinitionUnit> expected(
      Iterable<CatalogDefinitionUnit> units) {
    final keys = {for (final unit in units) unit.key};
    return [
      for (final index in all)
        if (keys.contains(index.marker)) ...index.initialize(units),
    ];
  }

  static Future<CatalogDerivedPatch> maintain({
    required CatalogDerivedLookup lookup,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
  }) async {
    final result = (
      upserts: <CatalogDefinitionUnit>[],
      removals: <CatalogDefinitionKey>[]
    );
    for (final index in all) {
      final patch = await index.maintain(lookup: lookup, upserts: [
        for (final unit in upserts)
          if (!index.owns(unit.key)) unit
      ], removals: [
        for (final key in removals)
          if (!index.owns(key)) key
      ]);
      result.upserts.addAll(patch.upserts);
      result.removals.addAll(patch.removals);
    }
    return result;
  }

  static Future<List<CatalogDefinitionUnit>?> admitDelta({
    required CatalogSnapshot before,
    required CatalogSnapshot next,
    required Iterable<CatalogDefinitionUnit> upserts,
  }) async {
    final result = <CatalogDefinitionUnit>[];
    for (final index in all) {
      final owned = {
        for (final unit in upserts)
          if (index.owns(unit.key)) unit.key: unit
      };
      if (await next.lookup(index.marker) == null) {
        if (owned.isNotEmpty) return null;
        continue;
      }
      final maintained = await index.maintain(lookup: before.lookup, upserts: [
        for (final unit in upserts)
          if (!index.owns(unit.key)) unit
      ], removals: const []);
      if (await _present(next, maintained.upserts, owned.keys) &&
          await _absent(next, maintained.removals)) {
        result.addAll(maintained.upserts);
        continue;
      }
      final rows = index.initialize(await index.sources(next.lookup));
      final rowKeys = {for (final row in rows) row.key};
      final previous = await before.lookup(index.marker);
      if (!await _present(next, rows, owned.keys) ||
          !await _absent(next, [
            if (previous != null)
              for (final key in index.rowKeys(previous))
                if (!rowKeys.contains(key)) key
          ])) {
        return null;
      }
      result.addAll(rows);
    }
    return result;
  }

  static Future<bool> _present(
      CatalogSnapshot next,
      List<CatalogDefinitionUnit> rows,
      Iterable<CatalogDefinitionKey> owned) async {
    final keys = {for (final row in rows) row.key};
    if (!owned.every(keys.contains)) return false;
    for (final row in rows) {
      final actual = await next.lookup(row.key);
      if (actual == null ||
          canonicalAuthoringJson(actual.toJson()) !=
              canonicalAuthoringJson(row.toJson())) {
        return false;
      }
    }
    return true;
  }

  static Future<bool> _absent(
      CatalogSnapshot next, Iterable<CatalogDefinitionKey> keys) async {
    for (final key in keys) {
      if (await next.lookup(key) != null) return false;
    }
    return true;
  }
}
