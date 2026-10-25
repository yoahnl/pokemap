import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/transaction_file_gateway.dart';
import '../../references/resource_library_scope_guard.dart';
import '../../references/resource_usage_documents.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../transactions/plan_store.dart';
import '../project_snapshot.dart';
import '../workspace_handle_store.dart';
import 'catalog_metadata_documents.dart';
import 'catalog_project_reader.dart';

final class CatalogSpatialMapSelection {
  CatalogSpatialMapSelection._(this.reader, this.snapshot, this.storageKey,
      this.mapRevision, this.catalogRevision);

  final CatalogProjectReader reader;
  final ProjectSnapshot snapshot;
  final String storageKey;
  final String mapRevision;
  final String catalogRevision;

  static bool supports(String action,
      {Map<String, Object?> parameters = const {}}) {
    if (action == 'map.apply_operations') {
      final operations = parameters['operations'];
      return operations is List &&
          operations.isNotEmpty &&
          operations.every((op) =>
              op is Map &&
              op['kind'] == 'layer.add' &&
              const {'environment', 'border'}.contains(op['layerKind']));
    }
    return const {
      'environment.attach_to_spatial_terrain',
      'environment.area_create',
      'environment.generated_placement_add',
      'environment.generated_placement_adopt_batch',
      'map3d.terrain.configure_appearance',
      'map3d.terrain.surface.upsert_batch',
      'map3d.terrain.surface.delete_batch',
      'border_layer.feature_create',
      'border_layer.feature_update',
      'border_layer.materialize_apply',
      'border_layer.materialize_batch_apply',
      'border_layer.feature_set_variation',
      'border_layer.feature_set_replacement',
      'border_layer.feature_set_offset',
      'border_layer.feature_set_transform',
      'border_layer.feature_set_suppressed',
      'border_layer.feature_clear_slot_override',
      'map3d.instance.upsert',
      'map3d.instance.upsert_batch',
      'smart_tile.layer.create',
      'smart_tile.layer.delete',
      'smart_tile.cell.paint',
      'smart_tile.cell.paint_batch',
      'smart_tile.cell.erase',
    }.contains(action);
  }

  static String fingerprint(
          String catalogRevision, String mapId, String mapRevision) =>
      computeAuthoringJsonFingerprint({
        'catalogRevision': catalogRevision,
        'mapId': mapId,
        'mapRevision': mapRevision,
      }, logicalName: 'catalog-map-selection.json');

  static Future<CatalogSpatialMapSelection> read(
      {required CatalogProjectReader reader,
      required ProjectHandle projectHandle,
      required String actionId,
      required Map<String, Object?> parameters}) async {
    if (!supports(actionId, parameters: parameters)) {
      throw const FormatException('catalog.spatial: unsupported action');
    }
    if (actionId == 'map.apply_operations') {
      final operations = parameters['operations'];
      if (operations is! List ||
          operations.isEmpty ||
          operations.any((op) =>
              op is! Map ||
              op['kind'] != 'layer.add' ||
              !const {'environment', 'border'}.contains(op['layerKind']))) {
        throw AuthoringPlanException(
            code: 'catalog.mutation_scope_required',
            message:
                'Only native Environment and Border layer creation have a targeted map-operation scope.');
      }
    }
    final mapId = parameters['mapId'];
    if (mapId is! String || mapId.isEmpty || mapId.trim() != mapId) {
      throw const FormatException('catalog.spatial: mapId required');
    }
    final selected =
        await reader.withMetadataFields({'settings', 'pokemon', 'newGame'});
    return selected.read((catalog) async {
      await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
      final base = catalog.projectMetadata;
      final owner = await CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot,
          project: base,
          ids: {
            'maps': {mapId}
          });
      final entry =
          owner.project.maps.where((entry) => entry.id == mapId).firstOrNull;
      if (entry == null) {
        throw const ProjectSnapshotException(
            'project.map_missing', 'The map is not declared.');
      }
      final payload =
          await reader.store.gateway.captureResourcePayload(entry.relativePath);
      if (payload == null) {
        throw const ProjectSnapshotException(
            'project.map_missing', 'The map document is missing.');
      }
      try {
        final mapBytes = await payload.readBytes();
        final map = MapData.fromJson(Map<String, dynamic>.from(
            jsonDecode(utf8.decode(mapBytes)) as Map));
        final supportsTwoDimensions = actionId == 'map.apply_operations' ||
            actionId.startsWith('environment.') ||
            actionId.startsWith('border_layer.') ||
            actionId.startsWith('smart_tile.');
        if (map.id != mapId ||
            (map.spatialScene == null && !supportsTwoDimensions)) {
          throw const FormatException(
              'catalog.spatial: map identity or dimension mismatch');
        }
        final ids = <String, Set<String>>{
          'maps': {mapId}
        };
        var candidates = <Object?>[
          map.toJson(),
          parameters,
          owner.project.toJson(),
        ];
        final newGame = base.newGame;
        final initialFactIds = <String>{
          ...newGame.initialFacts.keys,
          ...newGame.initialFactValues.keys,
          for (final values
              in newGame.initialFactValuesByAvatarCharacterId.values)
            ...values.keys,
          if (newGame.existingPartyFactId case final String id) id,
        };
        if (initialFactIds.isNotEmpty) ids['facts'] = initialFactIds;
        if (newGame.startMapId.isNotEmpty) ids['maps']!.add(newGame.startMapId);
        if (newGame.initialRecoveryPoint case final recovery?) {
          ids['maps']!.add(recovery.mapId);
        }
        void collectReferences() {
          for (final field in const {
            'maps': {'mapId', 'targetMapId', 'destinationMapId'},
            'groups': {'groupId', 'parentGroupId', 'escapeRopeDungeonId'},
            'dialogues': {
              'dialogueId',
              'preBattleDialogueId',
              'victoryDialogueId',
              'defeatDialogueId'
            },
            'scenes': {'sceneId', 'preSessionSceneId'},
            'cinematics': {'cinematicId'},
            'scripts': {'scriptId'},
            'trainers': {'trainerId', 'playerTrainerId'},
            'encounterTables': {'encounterTableId', 'tableId'},
            'facts': {'factId'},
            'scenarios': {'scenarioId'},
          }.entries) {
            final found = _references(candidates, field.value);
            if (found.isNotEmpty) {
              ids.putIfAbsent(field.key, () => {}).addAll(found);
            }
          }
        }

        collectReferences();
        var metadata = owner.project;
        while (true) {
          final count =
              ids.values.fold<int>(0, (n, values) => n + values.length);
          if (count > catalog.snapshot.limits.maxClosureNodes) {
            throw const FormatException(
                'catalog.spatial: dependency budget exceeded');
          }
          metadata = (await CatalogMetadataDocuments.readDocuments(
                  snapshot: catalog.snapshot, project: base, ids: ids))
              .project;
          candidates = [map.toJson(), parameters, metadata.toJson()];
          collectReferences();
          for (final dialogue in metadata.dialogues) {
            if (dialogue.folderId case final String folder) {
              ids.putIfAbsent('dialogueFolders', () => {}).add(folder);
            }
          }
          for (final folder in metadata.dialogueFolders) {
            if (folder.parentFolderId case final String parent) {
              ids.putIfAbsent('dialogueFolders', () => {}).add(parent);
            }
          }
          if (count ==
              ids.values.fold<int>(0, (n, values) => n + values.length)) {
            break;
          }
        }
        final roots = <CatalogDefinitionKey>{};
        for (final field in const {
          CatalogDefinitionKind.environmentPreset: {'presetId'},
          CatalogDefinitionKind.borderRecord: {
            'blueprintId',
            'targetBlueprintId'
          },
          CatalogDefinitionKind.smartTileAtlas: {'atlasId'},
          CatalogDefinitionKind.smartTilePreset: {'presetId'},
          CatalogDefinitionKind.smartTileMaterial: {'materialId'},
          CatalogDefinitionKind.model3d: {'modelId'},
          CatalogDefinitionKind.character: {
            'characterId',
            'avatarCharacterId',
            'defaultPlayerCharacterId',
            'playerAvatarCharacterIds'
          },
          CatalogDefinitionKind.element: {
            'elementId',
            'portraitElementId',
            'illustrationElementId'
          },
        }.entries) {
          for (final id in _references(candidates, field.value)) {
            final key = CatalogDefinitionKey(field.key, id);
            if (await catalog.snapshot.indexEntry(key) != null) {
              roots.add(key);
            }
          }
        }
        for (final id in newGame.initialFactValuesByAvatarCharacterId.keys) {
          roots.add(CatalogDefinitionKey(CatalogDefinitionKind.character, id));
        }
        var definitions = await ProjectCatalogSelection(catalog)
            .forMap(map, additionalRoots: roots);
        final encoded = definitions.toJson();
        final metadataJson = metadata.toJson();
        for (final field in ids.keys) {
          encoded[field] = metadataJson[field];
        }
        definitions = ProjectManifest.fromJson(encoded);
        MapValidator.validate(map, projectDialogueContext: definitions);
        final projectBytes = utf8.encode(jsonEncode(definitions.toJson()));
        final catalogRevision = 'sha256:${catalog.snapshot.root.sha256}';
        final revision =
            fingerprint(catalogRevision, mapId, payload.resourceRevision);
        final snapshot = ProjectSnapshot(
            projectHandle: projectHandle,
            revision: revision,
            manifest: definitions,
            materializedCatalogProject: true,
            availableProjectSections: const {},
            scopedStorageRevisions: {
              entry.relativePath: payload.resourceRevision
            },
            maps: [
              map
            ],
            resourceFingerprints: {
              'project': computeAuthoringBytesFingerprint(projectBytes,
                  logicalName: 'project.json'),
              'map:$mapId': payload.resourceRevision
            },
            resourceBytes: {
              'project': projectBytes,
              'map:$mapId': mapBytes
            },
            resourceStorageKeys: {
              'project': 'project.json',
              'map:$mapId': entry.relativePath
            });
        final result = CatalogSpatialMapSelection._(selected, snapshot,
            entry.relativePath, payload.resourceRevision, catalogRevision);
        if (await result.currentRevision() != revision) {
          throw AuthoringPlanException(
              code: 'plan.stale',
              message:
                  'The selected map changed while reading its dependencies.');
        }
        return result;
      } finally {
        await payload.release();
      }
    });
  }

  Future<String> currentRevision() async {
    final payload =
        await reader.store.gateway.captureResourcePayload('project.json');
    if (payload == null) {
      throw AuthoringPlanException(
          code: 'plan.stale', message: 'The project descriptor disappeared.');
    }
    try {
      if (payload.byteLength > 4096 ||
          canonicalAuthoringJson(
                  jsonDecode(utf8.decode(await payload.readBytes()))) !=
              canonicalAuthoringJson(reader.descriptor)) {
        throw AuthoringPlanException(
            code: 'plan.stale', message: 'The project descriptor changed.');
      }
    } finally {
      await payload.release();
    }
    final root = await reader.store.readHead();
    final map = await reader.store.gateway.readResourceRevision(storageKey);
    if (root == null || map == null) {
      throw AuthoringPlanException(
          code: 'plan.stale',
          message: 'The selected map or catalog disappeared.');
    }
    return fingerprint('sha256:${root.sha256}', snapshot.maps.single.id, map);
  }

  Future<
      ({
        List<AuthoringResourceChange> changes,
        AuthoringDiff diff,
        String fingerprint
      })> translate(AuthoringPlan plan) async {
    final changes = plan.changeSet.changes;
    if (changes.length != 1 ||
        changes.single.storageKey != storageKey ||
        changes.single.resource.kind != 'map' ||
        changes.single.resource.id != snapshot.maps.single.id ||
        changes.single.beforeRevision != mapRevision ||
        changes.single.afterPayload == null) {
      throw AuthoringPlanException(
          code: 'catalog.mutation_outside_scope',
          message: 'The semantic action must change only its selected map.');
    }
    final projected = MapData.fromJson(Map<String, dynamic>.from(
        jsonDecode(utf8.decode(await changes.single.afterPayload!.readBytes()))
            as Map));
    MapValidator.validate(projected, projectDialogueContext: snapshot.manifest);
    validateResourceLibraryScopeIndex(
        snapshot.manifest,
        ResourceLibraryUsageIndex.fromDocuments(maps: [
          projected
        ], documents: [
          ResourceUsageDocument('map', projected.id, projected.name, storageKey,
              projected.toJson())
        ]));
    final state = computeAuthoringJsonFingerprint({
      'baseCatalog': catalogRevision,
      'resources': {storageKey: changes.single.afterRevision}
    }, logicalName: 'catalog-spatial-map-state.json');
    final diff = AuthoringDiff([
      for (final entry in plan.changeSet.diff.entries)
        AuthoringDiffEntry.fromJson({
          ...entry.toJson(),
          'resource': {
            ...entry.resource.toJson(),
            'extensions': {
              ...entry.resource.extensions,
              'nativeMapResourcePath': storageKey
            }
          }
        }),
      AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: AuthoringResourceRef(kind: 'catalogHead', id: 'catalog'),
          path: '/workspaceFingerprint',
          before: catalogRevision,
          after: state),
    ]);
    return (changes: changes, diff: diff, fingerprint: state);
  }
}

Set<String> _references(Object? value, Set<String> keys) {
  final result = <String>{};
  void visit(Object? item) {
    if (item is Map) {
      for (final entry in item.entries) {
        if (keys.contains(entry.key)) {
          final value = entry.value;
          if (value is String && value.isNotEmpty) {
            result.add(value);
          }
          if (value is List) {
            result
                .addAll(value.whereType<String>().where((id) => id.isNotEmpty));
          }
        }
        visit(entry.value);
      }
    } else if (item is List) {
      for (final nested in item) {
        visit(nested);
      }
    }
  }

  visit(value);
  return result;
}
