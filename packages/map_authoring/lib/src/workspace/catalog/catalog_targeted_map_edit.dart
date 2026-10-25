import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_request.dart';
import '../../contracts/json_contract_support.dart';
import '../../contracts/resource_ref.dart';
import '../../domains/maps/map_lifecycle_adapter.dart';
import '../../ports/transaction_file_gateway.dart';
import '../../references/resource_library_scope_guard.dart';
import '../../references/resource_usage_documents.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/plan_store.dart';
import 'catalog_project_reader.dart';
import 'catalog_metadata_documents.dart';

final class CatalogTargetedMapSelection {
  const CatalogTargetedMapSelection._({
    required this.map,
    required this.definitions,
    required this.catalogRevision,
    required this.mapRevision,
    required this.mapBytes,
    required this.storageKey,
  });

  final MapData map;
  final ProjectManifest definitions;
  final String catalogRevision;
  final String mapRevision;
  final List<int> mapBytes;
  final String storageKey;
  String get snapshotRevision => computeAuthoringJsonFingerprint({
        'catalogRevision': catalogRevision,
        'mapId': map.id,
        'mapRevision': mapRevision,
      }, logicalName: 'catalog-map-selection.json');

  static Future<CatalogTargetedMapSelection> read({
    required CatalogProjectReader reader,
    required String mapId,
    MapData? projectedMap,
  }) =>
      reader.read((catalog) async {
        final entry =
            catalog.projectMetadata.maps.where((m) => m.id == mapId).single;
        final payload = await reader.store.gateway
            .captureResourcePayload(entry.relativePath);
        if (payload == null) {
          throw const FormatException('catalog.map: missing map');
        }
        try {
          final bytes = await payload.readBytes();
          final raw = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
          if (raw is! Map<String, dynamic>) {
            throw const FormatException('catalog.map: invalid map');
          }
          final map = MapData.fromJson(raw);
          if (map.id != mapId ||
              (projectedMap != null && projectedMap.id != mapId)) {
            throw const FormatException('catalog.map: identity mismatch');
          }
          var definitions = await ProjectCatalogSelection(catalog)
              .forMap(projectedMap ?? map);
          final factIds = <String>{};
          void collectFacts(Object? value) {
            if (value is Map) {
              if (value['factId'] case final String id) factIds.add(id);
              for (final nested in value.values) { collectFacts(nested); }
            } else if (value is List) {
              for (final nested in value) { collectFacts(nested); }
            }
          }
          collectFacts((projectedMap ?? map).toJson());
          if (factIds.isNotEmpty) {
            if (!reader.readOnly) await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
            final facts = reader.readOnly
                ? (await reader.readMetadata({'facts'})).facts.where((fact) => factIds.contains(fact.id)).toList()
                : (await CatalogMetadataDocuments.readDocuments(snapshot: catalog.snapshot,
                    project: const ProjectManifest(name: 'Map dependencies', maps: [], tilesets: []),
                    ids: {'facts': factIds})).project.facts;
            definitions = definitions.copyWith(facts: facts);
          }
          MapValidator.validate(projectedMap ?? map,
              projectDialogueContext: definitions);
          if (await reader.store.gateway
                  .readResourceRevision(entry.relativePath) !=
              payload.resourceRevision) {
            throw const FormatException('catalog.map: map changed during read');
          }
          return CatalogTargetedMapSelection._(
              map: map,
              definitions: definitions,
              catalogRevision: 'sha256:${catalog.snapshot.root.sha256}',
              mapRevision: payload.resourceRevision,
              mapBytes: bytes,
              storageKey: entry.relativePath);
        } finally {
          await payload.release();
        }
      });
}

final class CatalogTargetedMapEdit {
  const CatalogTargetedMapEdit._({
    required this.selection,
    required this.draft,
    required this.workspaceFingerprint,
    required this.diff,
  });

  final CatalogTargetedMapSelection selection;
  final AuthoringMutationDraft draft;
  final String workspaceFingerprint;
  final AuthoringDiff diff;

  static Future<CatalogTargetedMapEdit> prepare({
    required CatalogProjectReader reader,
    required AuthoringRequest request,
  }) async {
    if (request.actionId != 'map.save' || request.actionVersion != 1) {
      throw const FormatException('catalog.map: unsupported targeted action');
    }
    final args = Map<String, dynamic>.from(request.parameters);
    rejectUnknownContractKeys(args, const {'map'});
    final raw = args['map'];
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('catalog.map: map required');
    }
    final updated = MapData.fromJson(raw);
    final selection = await CatalogTargetedMapSelection.read(
        reader: reader, mapId: updated.id, projectedMap: updated);
    if (selection.snapshotRevision != request.expectedRevision) {
      throw AuthoringPlanException(
          code: 'plan.stale',
          message: 'The catalog changed before map planning.');
    }
    final draft = const MapLifecycleAdapter().saveSelection(
        project: selection.definitions,
        before: selection.map,
        beforeBytes: selection.mapBytes,
        beforeRevision: selection.mapRevision,
        updated: updated);
    validateResourceLibraryScopeIndex(
        selection.definitions,
        ResourceLibraryUsageIndex.fromDocuments(maps: [
          updated
        ], documents: [
          ResourceUsageDocument('map', updated.id, updated.id,
              selection.storageKey, updated.toJson()),
        ]));
    final fingerprint = computeAuthoringJsonFingerprint({
      'baseCatalog': selection.catalogRevision,
      'resources': {
        for (final change in draft.changeSet.changes)
          change.storageKey: change.afterRevision,
      },
    }, logicalName: 'catalog-targeted-map-state.json');
    return CatalogTargetedMapEdit._(
        selection: selection,
        draft: draft,
        workspaceFingerprint: fingerprint,
        diff: AuthoringDiff([
          ...draft.changeSet.diff.entries,
          AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource:
                  AuthoringResourceRef(kind: 'catalogHead', id: 'catalog'),
              path: '/workspaceFingerprint',
              before: selection.catalogRevision,
              after: fingerprint),
        ]));
  }
}
