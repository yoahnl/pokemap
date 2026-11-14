import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../support/authoring_fingerprint.dart';
import 'catalog_derivable_indexes.dart';
import 'catalog_metadata_documents.dart';
import 'catalog_narrative_event_documents.dart';
import 'catalog_narrative_owner_analysis.dart';
import 'catalog_narrative_title_rows.dart';
import 'catalog_narrative_usage_maintenance.dart';

typedef CatalogNarrativeFacets = Iterable<(String, Map<String, Object?>)>
    Function(CatalogNarrativeOwnerReferences references, int version);

sealed class CatalogNarrativeUsageRead {
  const CatalogNarrativeUsageRead();
}

final class CatalogNarrativeUsageEntries extends CatalogNarrativeUsageRead {
  const CatalogNarrativeUsageEntries(this.entries);
  final List<Map<String, Object?>> entries;
}

final class CatalogNarrativeUsagesPreparationRequired
    extends CatalogNarrativeUsageRead {
  const CatalogNarrativeUsagesPreparationRequired(this.reason);
  final String reason;
}

final class CatalogNarrativeUsageIndex implements CatalogDerivableIndex {
  const CatalogNarrativeUsageIndex(
      this.name, this.buckets, this.version, this.facets);

  final String name;
  final int buckets;
  final int version;
  final CatalogNarrativeFacets facets;

  @override
  CatalogDefinitionKey get marker => CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState, '${name}Index');

  CatalogDefinitionKey bucketKey(int bucket) => CatalogDefinitionKey(
      CatalogDefinitionKind.workspaceState, jsonEncode([name, bucket]));

  int bucketOf(String facet) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(facet)) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash % buckets;
  }

  @override
  bool owns(CatalogDefinitionKey key) =>
      key.kind == CatalogDefinitionKind.workspaceState &&
      (key == marker || key.id.startsWith('["$name",'));

  @override
  List<CatalogDefinitionUnit> initialize(
          Iterable<CatalogDefinitionUnit> units) =>
      _rows(
          units,
          storedVersion([
                for (final unit in units)
                  if (unit.key == marker) unit
              ].firstOrNull) ??
              version);

  List<CatalogDefinitionUnit> _rows(
      Iterable<CatalogDefinitionUnit> units, int version) {
    final entries = [for (var i = 0; i < buckets; i++) <String, Set<String>>{}];
    void add(CatalogNarrativeOwnerReferences references) {
      for (final (facet, entry) in facets(references, version)) {
        entries[bucketOf(facet)]
            .putIfAbsent(facet, () => {})
            .add(canonicalAuthoringJson(entry));
      }
    }

    for (final unit in units) {
      final location = CatalogNarrativeTitleRows.definitionLocation(unit.key);
      if (location == null ||
          !CatalogNarrativeOwnerAnalysis.fields.containsKey(location.$1)) {
        continue;
      }
      add(CatalogNarrativeOwnerAnalysis.ofDefinition(
          location.$1, definition(unit)));
    }
    final registry = CatalogNarrativeEventDocuments.decodeRegistry(units);
    for (final record in registry?['records'] as List? ?? const []) {
      add(CatalogNarrativeOwnerAnalysis.ofEvent(
          NarrativeEventRecord.fromJson(record)));
    }
    return [
      markerUnit(version: version),
      for (var i = 0; i < buckets; i++) bucketUnit(i, entries[i], version),
    ];
  }

  @override
  Future<List<CatalogDefinitionUnit>> sources(
      CatalogDerivedLookup lookup) async {
    final units = <CatalogDefinitionUnit>[];
    for (final field in CatalogNarrativeOwnerAnalysis.fields.keys) {
      for (var position = 0;; position++) {
        final unit = await lookup(
            CatalogMetadataDocuments.definitionKey(field, position));
        if (unit == null) break;
        units.add(unit);
      }
    }
    units.addAll(await CatalogNarrativeEventDocuments.registryUnits(lookup));
    if (await lookup(marker) case final state?) units.add(state);
    return units;
  }

  @override
  Iterable<CatalogDefinitionKey> rowKeys(CatalogDefinitionUnit marker) =>
      [this.marker, for (var i = 0; i < buckets; i++) bucketKey(i)];

  @override
  Future<CatalogDerivedPatch> maintain({
    required CatalogDerivedLookup lookup,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
  }) =>
      CatalogNarrativeUsageMaintenance.maintain(this,
          lookup: lookup, upserts: upserts, removals: removals);

  Future<CatalogNarrativeUsageRead> read(
      CatalogSnapshot snapshot, String facet) async {
    final state = await snapshot.lookup(marker);
    if (state == null) {
      return const CatalogNarrativeUsagesPreparationRequired('absent');
    }
    if (!ready(state)) {
      return const CatalogNarrativeUsagesPreparationRequired('stale');
    }
    final bucket = bucketOf(facet);
    final entries = bucketEntries(
        await snapshot.lookup(bucketKey(bucket)), bucket, version);
    if (entries == null) {
      throw const FormatException('catalog.narrative_usages.bucket_invalid');
    }
    return CatalogNarrativeUsageEntries([
      for (final entry in entries[facet] ?? const <String>{})
        Map<String, Object?>.from(jsonDecode(entry) as Map)
    ]);
  }

  Future<CatalogDerivedPatch> prepare(CatalogSnapshot snapshot) async {
    final state = await snapshot.lookup(marker);
    if (state != null && ready(state)) {
      return (
        upserts: <CatalogDefinitionUnit>[],
        removals: <CatalogDefinitionKey>[]
      );
    }
    final upserts = <CatalogDefinitionUnit>[];
    for (final row in _rows(await sources(snapshot.lookup), version)) {
      final existing = await snapshot.lookup(row.key);
      if (existing == null ||
          canonicalAuthoringJson(existing.toJson()) !=
              canonicalAuthoringJson(row.toJson())) {
        upserts.add(row);
      }
    }
    return (upserts: upserts, removals: <CatalogDefinitionKey>[]);
  }

  bool ready(CatalogDefinitionUnit state) =>
      storedVersion(state) == version && state.payload['stale'] != true;

  int? storedVersion(CatalogDefinitionUnit? state) {
    final stored = state?.payload['schemaVersion'];
    return state?.key == marker &&
            stored is int &&
            stored >= 1 &&
            stored <= version &&
            state!.payload['buckets'] == buckets
        ? stored
        : null;
  }

  CatalogDefinitionUnit markerUnit(
          {bool stale = false, required int version}) =>
      CatalogDefinitionUnit(key: marker, payload: {
        'id': marker.id,
        'schemaVersion': version,
        'buckets': buckets,
        if (stale) 'stale': true,
      });

  CatalogDefinitionUnit bucketUnit(
          int bucket, Map<String, Set<String>> entries, int version) =>
      CatalogDefinitionUnit(key: bucketKey(bucket), payload: {
        'id': bucketKey(bucket).id,
        'schemaVersion': version,
        'bucket': bucket,
        'entries': {
          for (final facet in entries.keys.toList()..sort())
            if (entries[facet]!.isNotEmpty)
              facet: [
                for (final entry in entries[facet]!.toList()..sort())
                  jsonDecode(entry)
              ],
        },
      });

  Map<String, Set<String>>? bucketEntries(
      CatalogDefinitionUnit? unit, int bucket, int version) {
    final payload = unit?.payload;
    final entries = payload?['entries'];
    if (payload == null ||
        payload['schemaVersion'] != version ||
        payload['bucket'] != bucket ||
        entries is! Map) {
      return null;
    }
    final result = <String, Set<String>>{};
    for (final MapEntry(:key, :value) in entries.entries) {
      if (key is! String || value is! List || value.isEmpty) return null;
      result[key] = {for (final entry in value) canonicalAuthoringJson(entry)};
    }
    return result;
  }

  static Map definition(CatalogDefinitionUnit unit) {
    final value = unit.payload['value'];
    final definition = value is Map ? value['definition'] : null;
    if (definition is! Map) {
      throw const FormatException(
          'catalog.narrative_usages.definition_invalid');
    }
    return definition;
  }
}
