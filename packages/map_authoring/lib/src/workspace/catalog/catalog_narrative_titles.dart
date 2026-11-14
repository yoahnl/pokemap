import 'package:map_core/map_core.dart';

import '../../support/authoring_fingerprint.dart';
import 'catalog_derivable_indexes.dart';
import 'catalog_metadata_documents.dart';
import 'catalog_narrative_event_documents.dart';
import 'catalog_narrative_title_maintenance.dart';
import 'catalog_narrative_title_rows.dart';

typedef CatalogNarrativeTitle = ({
  String id,
  String title,
  List<String> tags,
  String? category
});

sealed class CatalogNarrativeTitleRead {
  const CatalogNarrativeTitleRead(this.kind);
  final String kind;
}

final class CatalogNarrativeTitlePage extends CatalogNarrativeTitleRead {
  const CatalogNarrativeTitlePage(super.kind,
      {required this.page, required this.total, required this.entries});
  final int page;
  final int total;
  final List<CatalogNarrativeTitle> entries;
}

final class CatalogNarrativeTitlesPreparationRequired
    extends CatalogNarrativeTitleRead {
  const CatalogNarrativeTitlesPreparationRequired(super.kind, this.reason);
  final String reason;
}

final class CatalogNarrativeTitles implements CatalogDerivableIndex {
  const CatalogNarrativeTitles._();

  static const index = CatalogNarrativeTitles._();
  static const preparationScope = 'narrativeTitles';
  static const kinds = CatalogNarrativeTitleRows.kinds;
  static const pageSize = CatalogNarrativeTitleRows.pageSize;
  static final markerKey = CatalogNarrativeTitleRows.markerKey;

  @override
  CatalogDefinitionKey get marker => markerKey;

  @override
  bool owns(CatalogDefinitionKey key) =>
      key.kind == CatalogDefinitionKind.workspaceState &&
      (key == markerKey || key.id.startsWith('["narrativeTitles",'));

  @override
  List<CatalogDefinitionUnit> initialize(
      Iterable<CatalogDefinitionUnit> units) {
    final positions = <String, Map<int, Map<String, Object?>>>{};
    for (final unit in units) {
      final location = CatalogNarrativeTitleRows.definitionLocation(unit.key);
      if (location == null) continue;
      final at = positions.putIfAbsent(location.$1, () => {});
      if (at.containsKey(location.$2)) _invalid('duplicate_position');
      at[location.$2] = CatalogNarrativeTitleRows.definitionEntry(
          unit, location.$1, location.$2);
    }
    return CatalogNarrativeTitleRows.rows({
      for (final kind in CatalogNarrativeTitleRows.fieldKinds)
        kind: [
          for (var i = 0; i < (positions[kind]?.length ?? 0); i++)
            positions[kind]![i] ?? _invalid('positions_not_contiguous'),
        ],
      CatalogNarrativeTitleRows.eventKind:
          CatalogNarrativeTitleRows.eventEntries(
              CatalogNarrativeEventDocuments.decodeRegistry(units)),
    });
  }

  @override
  Future<List<CatalogDefinitionUnit>> sources(
      CatalogDerivedLookup lookup) async {
    final units = <CatalogDefinitionUnit>[];
    for (final field in CatalogNarrativeTitleRows.fieldKinds) {
      for (var position = 0;; position++) {
        final unit = await lookup(
            CatalogMetadataDocuments.definitionKey(field, position));
        if (unit == null) break;
        units.add(unit);
      }
    }
    units.addAll(await CatalogNarrativeEventDocuments.registryUnits(lookup));
    return units;
  }

  @override
  Iterable<CatalogDefinitionKey> rowKeys(CatalogDefinitionUnit marker) => [
        markerKey,
        for (final entry
            in (CatalogNarrativeTitleRows.kindStates(marker) ?? const {})
                .entries)
          for (var page = 0;
              page < CatalogNarrativeTitleRows.storedPages(entry.value);
              page++)
            CatalogNarrativeTitleRows.pageKey(entry.key, page),
      ];

  @override
  Future<CatalogDerivedPatch> maintain({
    required CatalogDerivedLookup lookup,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
  }) =>
      CatalogNarrativeTitleMaintenance.maintain(
          lookup: lookup, upserts: upserts, removals: removals);

  static Future<CatalogNarrativeTitleRead> read(
      CatalogSnapshot snapshot, String kind, int page) async {
    if (!kinds.contains(kind)) _invalid('kind_unsupported');
    final states =
        CatalogNarrativeTitleRows.kindStates(await snapshot.lookup(markerKey));
    if (states == null) {
      return CatalogNarrativeTitlesPreparationRequired(kind, 'absent');
    }
    final count = states[kind]?['count'];
    if (count is! int) {
      return CatalogNarrativeTitlesPreparationRequired(kind, 'stale');
    }
    if (page < 0 ||
        (page > 0 && page >= CatalogNarrativeTitleRows.pageCount(count))) {
      _invalid('page_out_of_range');
    }
    final entries = count == 0
        ? const <Map<String, Object?>>[]
        : CatalogNarrativeTitleRows.pageEntries(
            await snapshot
                .lookup(CatalogNarrativeTitleRows.pageKey(kind, page)),
            kind,
            page,
            expectedLength: CatalogNarrativeTitleRows.pageLength(count, page));
    return CatalogNarrativeTitlePage(kind, page: page, total: count, entries: [
      for (final entry in entries)
        (
          id: entry['id'] as String,
          title: entry['title'] as String,
          tags: List<String>.unmodifiable(entry['tags'] as List),
          category: entry['category'] as String?,
        )
    ]);
  }

  static Future<CatalogDerivedPatch> prepare(CatalogSnapshot snapshot) async {
    final previous = await snapshot.lookup(markerKey);
    final states = CatalogNarrativeTitleRows.kindStates(previous);
    if (states != null &&
        kinds.every((kind) => states[kind]?['count'] is int)) {
      return (
        upserts: <CatalogDefinitionUnit>[],
        removals: <CatalogDefinitionKey>[]
      );
    }
    final rows = index.initialize(await index.sources(snapshot.lookup));
    final keys = {for (final row in rows) row.key};
    final upserts = <CatalogDefinitionUnit>[];
    for (final row in rows) {
      final existing = await snapshot.lookup(row.key);
      if (existing == null ||
          canonicalAuthoringJson(existing.toJson()) !=
              canonicalAuthoringJson(row.toJson())) {
        upserts.add(row);
      }
    }
    final removals = <CatalogDefinitionKey>[];
    if (previous != null) {
      for (final key in index.rowKeys(previous)) {
        if (!keys.contains(key) && await snapshot.lookup(key) != null) {
          removals.add(key);
        }
      }
    }
    return (upserts: upserts, removals: removals);
  }

  static Never _invalid(String code) =>
      throw FormatException('catalog.narrative_titles.$code');
}
