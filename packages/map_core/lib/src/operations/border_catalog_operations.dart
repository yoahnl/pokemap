import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_catalog.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import 'border_format_version.dart';

/// Pure, conservative result of evaluating immutable Border snapshot cleanup.
///
/// [candidateSnapshotIds] may be shown even with partial project information,
/// but [deletedSnapshotIds] is populated only when [hasExhaustiveReferences]
/// proves that both the manifest and every manifest map were supplied.
final class BorderVisualSnapshotRetentionResult {
  BorderVisualSnapshotRetentionResult({
    required this.catalog,
    required Iterable<String> candidateSnapshotIds,
    required Iterable<String> deletedSnapshotIds,
    required this.hasExhaustiveReferences,
  })  : candidateSnapshotIds = List<String>.unmodifiable(
          candidateSnapshotIds,
        ),
        deletedSnapshotIds = List<String>.unmodifiable(deletedSnapshotIds);

  final ProjectBorderCatalog catalog;
  final List<String> candidateSnapshotIds;
  final List<String> deletedSnapshotIds;
  final bool hasExhaustiveReferences;
}

/// Removes unreferenced snapshot metadata only with exhaustive project proof.
///
/// `map_core` never deletes files. The returned [ProjectBorderCatalog] omits
/// safe-to-delete metadata, while [deletedSnapshotIds] tells an outer storage
/// layer which immutable snapshot files may be removed in the same transaction.
/// When [isManifestExhaustive] is false, or [loadedMaps] does not match the
/// manifest map IDs exactly, the original catalog is returned and potential
/// cleanup is reported only through [candidateSnapshotIds].
BorderVisualSnapshotRetentionResult cleanupUnreferencedBorderVisualSnapshots({
  required ProjectManifest manifest,
  required Iterable<MapData> loadedMaps,
  required bool isManifestExhaustive,
}) {
  final maps = List<MapData>.unmodifiable(loadedMaps);
  final referencedSnapshotIds = _referencedSnapshotIds(
    catalog: manifest.borderCatalog,
    maps: maps,
  );
  final candidates = <String>[
    for (final snapshot in manifest.borderCatalog.visualSnapshots)
      if (!referencedSnapshotIds.contains(snapshot.id)) snapshot.id,
  ];
  final hasExhaustiveReferences = isManifestExhaustive &&
      _hasExactManifestMapCoverage(manifest: manifest, loadedMaps: maps);
  if (!hasExhaustiveReferences || candidates.isEmpty) {
    return BorderVisualSnapshotRetentionResult(
      catalog: manifest.borderCatalog,
      candidateSnapshotIds: candidates,
      deletedSnapshotIds: const <String>[],
      hasExhaustiveReferences: hasExhaustiveReferences,
    );
  }

  final candidateSet = candidates.toSet();
  return BorderVisualSnapshotRetentionResult(
    catalog: ProjectBorderCatalog(
      formatVersion: manifest.borderCatalog.formatVersion,
      records: manifest.borderCatalog.records,
      visualSnapshots: [
        for (final snapshot in manifest.borderCatalog.visualSnapshots)
          if (!candidateSet.contains(snapshot.id)) snapshot,
      ],
    ),
    candidateSnapshotIds: candidates,
    deletedSnapshotIds: candidates,
    hasExhaustiveReferences: true,
  );
}

Set<String> _referencedSnapshotIds({
  required ProjectBorderCatalog catalog,
  required Iterable<MapData> maps,
}) {
  final referenced = <String>{};
  for (final record in catalog.records) {
    final definition = record.latestPublished?.definition;
    if (definition == null) continue;
    for (final primitive in definition.primitives) {
      referenced.add(primitive.visualSnapshotId);
    }
    final ground = definition.ground;
    if (ground != null) {
      referenced.addAll(ground.visualSnapshotIdsByRole.values);
    }
  }

  for (final map in maps) {
    for (final layer in map.layers.whereType<BorderLayer>()) {
      for (final feature in layer.content.features) {
        for (final override in feature.overrides) {
          final lockedPlacement = override.lockedPlacement;
          if (lockedPlacement != null) {
            referenced.add(lockedPlacement.visualSnapshotId);
          }
        }
        final materialization = feature.materialization;
        if (materialization == null) continue;
        referenced.addAll(
          materialization.ground.map((cell) => cell.visualSnapshotId),
        );
        referenced.addAll(
          materialization.placements.map(
            (placement) => placement.visualSnapshotId,
          ),
        );
      }
    }
  }
  return referenced;
}

bool _hasExactManifestMapCoverage({
  required ProjectManifest manifest,
  required List<MapData> loadedMaps,
}) {
  final manifestIds = <String>{};
  for (final entry in manifest.maps) {
    if (!manifestIds.add(entry.id)) return false;
  }
  final loadedIds = <String>{};
  for (final map in loadedMaps) {
    if (!loadedIds.add(map.id)) return false;
  }
  return manifestIds.length == loadedIds.length &&
      manifestIds.containsAll(loadedIds);
}

/// Returns the Border blueprint record with the exact [recordId], if present.
BorderBlueprintRecord? findBorderBlueprintRecordById(
  ProjectBorderCatalog catalog,
  String recordId,
) {
  for (final record in catalog.records) {
    if (record.id == recordId) {
      return record;
    }
  }
  return null;
}

/// Appends [record] while preserving all existing records and snapshots.
ProjectBorderCatalog addBorderBlueprintRecord(
  ProjectBorderCatalog catalog,
  BorderBlueprintRecord record,
) {
  _requireStableRecordId(record.id);
  if (record.latestPublished != null) {
    throw const ValidationException(
      'Adding a Border blueprint record requires an unpublished draft',
    );
  }
  if (record.isDeprecated) {
    throw const ValidationException(
      'Adding a Border blueprint record requires an active draft',
    );
  }
  if (findBorderBlueprintRecordById(catalog, record.id) != null) {
    throw ValidationException(
      'ProjectBorderCatalog already contains record id: ${record.id}',
    );
  }

  return _copyCatalogWithRecords(
    catalog,
    <BorderBlueprintRecord>[...catalog.records, record],
  );
}

/// Replaces the record with [replacement.id] at its existing authored index.
ProjectBorderCatalog replaceBorderBlueprintRecord(
  ProjectBorderCatalog catalog,
  BorderBlueprintRecord replacement,
) {
  _requireStableRecordId(replacement.id);
  final index = catalog.records.indexWhere(
    (record) => record.id == replacement.id,
  );
  if (index < 0) {
    throw ValidationException(
      'ProjectBorderCatalog has no record id: ${replacement.id}',
    );
  }

  _validatePublishedTransition(catalog.records[index], replacement);
  final records = List<BorderBlueprintRecord>.from(catalog.records);
  records[index] = replacement;
  return _copyCatalogWithRecords(catalog, records);
}

void _validatePublishedTransition(
  BorderBlueprintRecord existing,
  BorderBlueprintRecord replacement,
) {
  if (existing.latestPublished != replacement.latestPublished) {
    throw ValidationException(
      'Publication requires the publication transaction for Border blueprint '
      'record: ${existing.id}',
    );
  }
  if (existing.isDeprecated != replacement.isDeprecated) {
    throw ValidationException(
      'Changing Border blueprint availability requires the explicit '
      'deprecation operation for record: ${existing.id}',
    );
  }
}

/// Explicitly deprecates or reactivates one blueprint identity.
///
/// Draft and published state, authored order, snapshots, and the stable ID are
/// preserved. Repeating the current state is a no-op that returns [catalog].
ProjectBorderCatalog setBorderBlueprintRecordDeprecated(
  ProjectBorderCatalog catalog,
  String recordId, {
  required bool isDeprecated,
}) {
  _requireStableRecordId(recordId);
  final index = catalog.records.indexWhere((record) => record.id == recordId);
  if (index < 0) {
    throw ValidationException(
      'ProjectBorderCatalog has no record id: $recordId',
    );
  }

  final existing = catalog.records[index];
  if (existing.isDeprecated == isDeprecated) {
    return catalog;
  }

  final records = List<BorderBlueprintRecord>.from(catalog.records);
  records[index] = BorderBlueprintRecord(
    id: existing.id,
    draft: existing.draft,
    latestPublished: existing.latestPublished,
    isDeprecated: isDeprecated,
  );
  return _copyCatalogWithRecords(catalog, records);
}

/// Removes a never-published draft with the exact [recordId].
///
/// Published identities are retained because map features may still refer to
/// their immutable revisions. Studio deletion therefore applies only to
/// records whose [BorderBlueprintRecord.latestPublished] is `null`.
ProjectBorderCatalog removeBorderBlueprintRecord(
  ProjectBorderCatalog catalog,
  String recordId,
) {
  _requireStableRecordId(recordId);
  final index = catalog.records.indexWhere((record) => record.id == recordId);
  if (index < 0) {
    throw ValidationException(
      'ProjectBorderCatalog has no record id: $recordId',
    );
  }

  final existing = catalog.records[index];
  if (existing.latestPublished != null) {
    throw ValidationException(
      'Published Border blueprint record cannot be removed: $recordId',
    );
  }

  final records = List<BorderBlueprintRecord>.from(catalog.records)
    ..removeAt(index);
  return _copyCatalogWithRecords(catalog, records);
}

void _requireStableRecordId(String recordId) {
  if (recordId.trim().isEmpty || recordId != recordId.trim()) {
    throw const ValidationException(
      'Border blueprint record id must be nonblank and already trimmed',
    );
  }
}

ProjectBorderCatalog _copyCatalogWithRecords(
  ProjectBorderCatalog catalog,
  List<BorderBlueprintRecord> records,
) {
  final requiresV2 = records.any(borderBlueprintRecordRequiresFormatV2);
  return ProjectBorderCatalog(
    formatVersion: requiresV2
        ? ProjectBorderCatalog.formatVersionV2
        : catalog.formatVersion,
    records: records,
    visualSnapshots: catalog.visualSnapshots,
  );
}
