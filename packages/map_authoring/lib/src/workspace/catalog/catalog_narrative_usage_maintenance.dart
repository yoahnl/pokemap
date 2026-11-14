import 'package:map_core/map_core.dart';

import '../../support/authoring_fingerprint.dart';
import 'catalog_derivable_indexes.dart';
import 'catalog_metadata_documents.dart';
import 'catalog_narrative_event_documents.dart';
import 'catalog_narrative_owner_analysis.dart';
import 'catalog_narrative_title_rows.dart';
import 'catalog_narrative_usage_index.dart';

abstract final class CatalogNarrativeUsageMaintenance {
  static Future<CatalogDerivedPatch> maintain(
    CatalogNarrativeUsageIndex index, {
    required CatalogDerivedLookup lookup,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
  }) async {
    final none = (
      upserts: <CatalogDefinitionUnit>[],
      removals: <CatalogDefinitionKey>[]
    );
    final definitions = <(String, int), CatalogDefinitionUnit?>{};
    final records = <CatalogDefinitionKey, CatalogDefinitionUnit?>{};
    void track(CatalogDefinitionKey key, CatalogDefinitionUnit? unit) {
      final location = CatalogNarrativeTitleRows.definitionLocation(key);
      if (location != null &&
          CatalogNarrativeOwnerAnalysis.fields.containsKey(location.$1)) {
        definitions[location] = unit;
      } else if (CatalogNarrativeEventDocuments.isRecordKey(key)) {
        records[key] = unit;
      }
    }

    for (final key in removals) {
      track(key, null);
    }
    for (final unit in upserts) {
      track(unit.key, unit);
    }
    if (definitions.isEmpty && records.isEmpty) return none;
    final state = await lookup(index.marker);
    if (state == null || !index.ready(state)) return none;
    final pending = {for (final unit in upserts) unit.key: unit};
    Future<CatalogDefinitionUnit?> after(CatalogDefinitionKey key) async =>
        pending[key] ?? await lookup(key);
    final before = <CatalogNarrativeOwner, CatalogNarrativeOwnerReferences>{};
    final next = <CatalogNarrativeOwner, CatalogNarrativeOwnerReferences>{};
    void keep(
        Map<CatalogNarrativeOwner, CatalogNarrativeOwnerReferences> images,
        CatalogNarrativeOwnerReferences references) {
      images[references.owner] = references;
    }

    for (final MapEntry(key: (field, position), value: unit)
        in definitions.entries) {
      final previous =
          await lookup(CatalogMetadataDocuments.definitionKey(field, position));
      if (previous != null) {
        keep(
            before,
            CatalogNarrativeOwnerAnalysis.ofDefinition(
                field, CatalogNarrativeUsageIndex.definition(previous)));
      }
      if (unit != null) {
        keep(
            next,
            CatalogNarrativeOwnerAnalysis.ofDefinition(
                field, CatalogNarrativeUsageIndex.definition(unit)));
      }
    }
    for (final MapEntry(:key, value: unit) in records.entries) {
      final previous = await CatalogNarrativeEventDocuments.readRecordUnit(
          await lookup(key), lookup);
      if (previous != null) {
        keep(before, CatalogNarrativeOwnerAnalysis.ofEvent(previous));
      }
      final current =
          await CatalogNarrativeEventDocuments.readRecordUnit(unit, after);
      if (current != null) {
        keep(next, CatalogNarrativeOwnerAnalysis.ofEvent(current));
      }
    }
    final removed = <int, Map<String, Set<String>>>{};
    final added = <int, Map<String, Set<String>>>{};
    Set<(String, String)> facetsOf(CatalogNarrativeOwnerReferences? images) => {
          if (images != null)
            for (final (facet, entry) in index.facets(images))
              (facet, canonicalAuthoringJson(entry)),
        };
    for (final owner in {...before.keys, ...next.keys}) {
      final previous = facetsOf(before[owner]);
      final current = facetsOf(next[owner]);
      for (final (target, changes) in [
        (removed, previous.difference(current)),
        (added, current.difference(previous)),
      ]) {
        for (final (facet, entry) in changes) {
          target
              .putIfAbsent(index.bucketOf(facet), () => {})
              .putIfAbsent(facet, () => {})
              .add(entry);
        }
      }
    }
    for (final bucket in {...removed.keys, ...added.keys}) {
      final entries =
          index.bucketEntries(await lookup(index.bucketKey(bucket)), bucket);
      if (entries == null) return _stale(index);
      for (final MapEntry(key: facet, value: values)
          in (removed[bucket] ?? const <String, Set<String>>{}).entries) {
        final current = entries[facet];
        if (current == null || !current.containsAll(values)) {
          return _stale(index);
        }
        current.removeAll(values);
      }
      for (final MapEntry(key: facet, value: values)
          in (added[bucket] ?? const <String, Set<String>>{}).entries) {
        final current = entries.putIfAbsent(facet, () => {});
        if (values.any(current.contains)) return _stale(index);
        current.addAll(values);
      }
      none.upserts.add(index.bucketUnit(bucket, entries));
    }
    return none;
  }

  static CatalogDerivedPatch _stale(CatalogNarrativeUsageIndex index) => (
        upserts: [index.markerUnit(stale: true)],
        removals: <CatalogDefinitionKey>[]
      );
}
