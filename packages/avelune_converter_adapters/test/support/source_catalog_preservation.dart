import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_core/map_core.dart';

List<SourceCatalogDocument> preservedCatalogDocuments(
        SourceCatalogProjection projection) =>
    [
      for (final raw in ((projection.evidence['sourceOnlyData']
              as Map)['documents'] as List)
          .cast<Map>())
        SourceCatalogDocument(
          kind: SourceCatalogDocumentKind.values.byName(raw['kind'] as String),
          relativePath: raw['relativePath'] as String,
          document: Map<String, Object?>.from(raw['document'] as Map),
        ),
    ];

List<ProjectTrainerEntry> preservedCatalogTrainers(
        SourceCatalogProjection projection) =>
    [
      for (final raw in ((projection.evidence['sourceOnlyData']
              as Map)['trainers'] as List)
          .cast<Map>())
        ProjectTrainerEntry.fromJson(Map<String, dynamic>.from(raw)),
    ];

List<ProjectEncounterTable> preservedCatalogEncounters(
        SourceCatalogProjection projection) =>
    [
      for (final raw in ((projection.evidence['sourceOnlyData']
              as Map)['encounterTables'] as List)
          .cast<Map>())
        ProjectEncounterTable.fromJson(Map<String, dynamic>.from(raw)),
    ];

ProjectItemCatalog? preservedCatalogItems(SourceCatalogProjection projection) {
  final value =
      (projection.evidence['sourceOnlyData'] as Map)['mergedItemCatalog'];
  return value == null ? null : decodeProjectItemCatalog(value);
}
