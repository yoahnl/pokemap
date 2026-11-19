import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import '../support/authoring_fingerprint.dart';
import '../workspace/catalog/catalog_metadata_documents.dart';
import '../workspace/catalog/catalog_resource_positions.dart';

final class CatalogHistoryMetadata {
  CatalogHistoryMetadata._(
      this.snapshot, this.references, this.units, this.expectedDocuments);

  final CatalogSnapshot snapshot;
  final List<CatalogObjectReference> references;
  final List<CatalogDefinitionUnit> units;
  final List<CatalogDefinitionUnit>? expectedDocuments;

  static Future<CatalogHistoryMetadata> read(CatalogSnapshot snapshot) async {
    final units = <CatalogDefinitionUnit>[];
    final positions = <CatalogDefinitionUnit>[];
    final references = await snapshot.objectReferences(onUnit: (unit) {
      final kind = unit.key.kind;
      if (kind == CatalogDefinitionKind.catalogMetadata ||
          kind == CatalogDefinitionKind.workspaceState) {
        units.add(unit);
      } else if (CatalogResourcePositions.sections.containsKey(kind)) {
        positions.add(CatalogDefinitionUnit(
            key: unit.key, payload: {'position': unit.payload['position']}));
      }
    });
    List<CatalogDefinitionUnit>? expected;
    try {
      expected = CatalogMetadataDocuments.initialize([...units, ...positions]);
    } on FormatException catch (error) {
      if (error.message != 'catalog.resource_positions.invalid_position' &&
          error.message != 'catalog.resource_positions.non_contiguous') {
        rethrow;
      }
    }
    return CatalogHistoryMetadata._(snapshot, references, units, expected);
  }

  Future<void> authenticate(
      Iterable<CatalogDefinitionUnit> metadataUnits) async {
    final supplied = <CatalogDefinitionKey, CatalogDefinitionUnit>{};
    for (final unit in metadataUnits) {
      if (!const {
            CatalogDefinitionKind.catalogMetadata,
            CatalogDefinitionKind.workspaceState,
          }.contains(unit.key.kind) ||
          supplied.containsKey(unit.key)) {
        throw const FormatException(
            'catalog.history_conversion: invalid metadata evidence');
      }
      supplied[unit.key] = unit;
    }
    var count = 0;
    for (final kind in [
      CatalogDefinitionKind.catalogMetadata,
      CatalogDefinitionKind.workspaceState,
    ]) {
      String? cursor;
      final cursors = <String>{};
      do {
        final page = await snapshot.page(
            kind: kind, limit: snapshot.limits.indexPageSize, cursor: cursor);
        for (final entry in page.items) {
          count++;
          final unit = supplied[entry.key];
          if (unit == null) {
            throw const FormatException(
                'catalog.history_conversion: incomplete metadata evidence');
          }
          final bytes = utf8.encode(canonicalAuthoringJson(unit.toJson()));
          if (bytes.length != entry.reference.byteLength ||
              crypto.sha256.convert(bytes).toString() !=
                  entry.reference.sha256) {
            throw const FormatException(
                'catalog.history_conversion: mismatched metadata evidence');
          }
        }
        cursor = page.nextCursor;
        if (cursor != null && !cursors.add(cursor)) {
          throw const FormatException(
              'catalog.history_conversion: repeated index cursor');
        }
      } while (cursor != null);
    }
    if (count != supplied.length) {
      throw const FormatException(
          'catalog.history_conversion: unrelated metadata evidence');
    }
  }
}
