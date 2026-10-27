import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_request.dart';
import '../../contracts/json_contract_support.dart';
import '../../contracts/resource_ref.dart';
import '../../documents/map_exterior_decoration_authoring.dart';
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
          final exterior = await loadMapExteriorDecoration(
            projectRoot: reader.store.projectRoot,
            map: map,
            mapRelativePath: entry.relativePath,
            reader: reader.store.fileReader,
          );
          var definitions = await ProjectCatalogSelection(catalog).forMaps(
            [
              projectedMap ?? map,
              for (final sector
                  in exterior?.sectors ?? const <ExteriorDecorationSector>[])
                sector.asVisualMap().copyWith(id: map.id),
            ],
            additionalRoots: [
              for (final border in exterior?.borders ??
                  const <ExteriorDecorationBorder>[]) ...[
                CatalogDefinitionKey(CatalogDefinitionKind.borderRecord,
                    border.feature.blueprintId),
                for (final instance in border.instances)
                  CatalogDefinitionKey(
                      CatalogDefinitionKind.model3d, instance.modelId),
                for (final placement
                    in border.feature.materialization?.placements ??
                        const <BorderResolvedPlacement>[])
                  CatalogDefinitionKey(
                      CatalogDefinitionKind.borderVisualSnapshot,
                      placement.visualSnapshotId),
                for (final ground in border.feature.materialization?.ground ??
                    const <BorderResolvedGroundCell>[])
                  CatalogDefinitionKey(
                      CatalogDefinitionKind.borderVisualSnapshot,
                      ground.visualSnapshotId),
              ],
            ],
          );
          final dependencyIds = <String, Set<String>>{
            'dialogues': {},
            'facts': {},
          };
          void collectReferences(Object? value) {
            if (value is Map) {
              for (final entry in value.entries) {
                final field = switch (entry.key) {
                  'dialogueId' ||
                  'preBattleDialogueId' ||
                  'victoryDialogueId' ||
                  'defeatDialogueId' =>
                    'dialogues',
                  'factId' => 'facts',
                  _ => null,
                };
                final id = entry.value;
                if (field != null && id is String && id.isNotEmpty) {
                  dependencyIds[field]!.add(id);
                }
                collectReferences(entry.value);
              }
            } else if (value is List) {
              for (final nested in value) {
                collectReferences(nested);
              }
            }
          }

          collectReferences((projectedMap ?? map).toJson());
          dependencyIds['dialogues']!
              .removeAll(definitions.dialogues.map((dialogue) => dialogue.id));
          dependencyIds['facts']!
              .removeAll(definitions.facts.map((fact) => fact.id));
          dependencyIds.removeWhere((_, ids) => ids.isEmpty);
          if (dependencyIds.isNotEmpty) {
            if (dependencyIds.values
                    .fold<int>(0, (count, ids) => count + ids.length) >
                catalog.snapshot.limits.maxClosureNodes) {
              throw const FormatException(
                  'catalog.map: dependency budget exceeded');
            }
            if (!reader.readOnly) {
              await reader.store
                  .requireMetadataIndexAdmission(catalog.snapshot);
            }
            final metadata = reader.readOnly
                ? await reader.readMetadata(dependencyIds.keys.toSet())
                : (await CatalogMetadataDocuments.readDocuments(
                        snapshot: catalog.snapshot,
                        project: const ProjectManifest(
                            name: 'Map dependencies', maps: [], tilesets: []),
                        ids: dependencyIds))
                    .project;
            definitions = definitions.copyWith(
              dialogues: [
                ...definitions.dialogues,
                ...metadata.dialogues.where((dialogue) =>
                    dependencyIds['dialogues']?.contains(dialogue.id) ?? false),
              ],
              facts: [
                ...definitions.facts,
                ...metadata.facts.where((fact) =>
                    dependencyIds['facts']?.contains(fact.id) ?? false),
              ],
            );
          }
          final encounterTableIds = {
            for (final layer
                in (projectedMap ?? map).layers.whereType<SmartTileLayer>())
              if (layer.encounterBehavior?.encounter.encounterTableId
                  case final String id)
                id,
          }.difference(
              definitions.encounterTables.map((table) => table.id).toSet());
          if (encounterTableIds.isNotEmpty) {
            if (!reader.readOnly) {
              await reader.store
                  .requireMetadataIndexAdmission(catalog.snapshot);
            }
            final tables = reader.readOnly
                ? (await reader.readMetadata({'encounterTables'}))
                    .encounterTables
                    .where((table) => encounterTableIds.contains(table.id))
                    .toList()
                : (await CatalogMetadataDocuments.readDocuments(
                        snapshot: catalog.snapshot,
                        project: const ProjectManifest(
                            name: 'Map dependencies', maps: [], tilesets: []),
                        ids: {'encounterTables': encounterTableIds}))
                    .project
                    .encounterTables;
            definitions = definitions.copyWith(
                encounterTables: [...definitions.encounterTables, ...tables]);
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
