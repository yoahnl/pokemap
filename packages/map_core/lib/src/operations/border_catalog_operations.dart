import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_catalog.dart';

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
  return ProjectBorderCatalog(
    formatVersion: catalog.formatVersion,
    records: records,
    visualSnapshots: catalog.visualSnapshots,
  );
}
