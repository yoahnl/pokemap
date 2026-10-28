import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../domains/maps/semantic_map_action_support.dart';
import '../../domains/maps/warp_connection_actions.dart';
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
import 'catalog_narrative_event_documents.dart';
import 'catalog_project_reader.dart';

final class CatalogSpatialMapSelection {
  CatalogSpatialMapSelection._(this.reader, this.snapshot, this.storageKey,
      this.mapRevision, this.catalogRevision, this.mapId);

  final CatalogProjectReader reader;
  final ProjectSnapshot snapshot;
  final String storageKey;
  final String mapRevision;
  final String catalogRevision;
  final String mapId;

  static bool supports(String action,
      {Map<String, Object?> parameters = const {}}) {
    if (action == 'map.update_metadata' && parameters.containsKey('escapeRopeDungeonId')) return false;
    if (action == 'map.apply_operations') {
      final operations = parameters['operations'];
      return operations is List &&
          operations.isNotEmpty &&
          operations.every((op) =>
              op is Map &&
              (op['kind'] == 'layer.reorder_by_id' ||
                  (op['kind'] == 'layer.add' &&
                      const {'environment', 'border'}.contains(op['layerKind']))));
    }
    return const {
      'warp.ladder.configure',
      'warp.update',
      'warp.create',
      'connection.upsert',
      'connection.create_bidirectional_apply',
      'entity.upsert',
      'trigger.create',
      'map3d.navigation.configure',
      'map3d.camera.configure',
      'map.update_metadata',
      'environment.attach_to_spatial_terrain',
      'environment.area_create',
      'environment.generated_placement_add',
      'environment.generated_placement_adopt_batch',
      'map3d.terrain.configure_appearance',
      'map3d.terrain.surface.upsert_batch',
      'map3d.lift.upsert_batch',
      'map3d.lift.delete_batch',
      'map3d.terrain.surface.delete_batch',
      'border_layer.feature_create',
      'border_layer.feature_delete',
      'border_layer.feature_update',
      'border_layer.feature_move',
      'border_layer.feature_reorder',
      'border_layer.feature_set_keep_out',
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
      'smart_tile.layer.change_preset',
      'smart_tile.layer.delete',
      'smart_tile.layer.set_encounter_behavior',
      'smart_tile.layer.clear_encounter_behavior',
      'smart_tile.cell.paint',
      'smart_tile.cell.paint_batch',
      'smart_tile.cell.erase',
      'smart_tile.pattern.paint',
      'smart_tile.pattern.paint_batch',
    }.contains(action);
  }

  static String fingerprint(
          String catalogRevision, String mapId, String mapRevision,
          {Map<String, String> readDependencies = const {}}) =>
      computeAuthoringJsonFingerprint({
        'catalogRevision': catalogRevision,
        'mapId': mapId,
        'mapRevision': mapRevision,
        if (readDependencies.isNotEmpty) 'readDependencies': readDependencies,
      }, logicalName: 'catalog-map-selection.json');

  static Future<CatalogSpatialMapSelection> _readProperties({
    required CatalogProjectReader reader, required ProjectHandle projectHandle,
    required String actionId, required Map<String, Object?> parameters,
  }) async {
    final mapId = parameters['mapId'];
    if (mapId is! String || mapId.isEmpty || mapId.trim() != mapId) {
      throw const FormatException('catalog.map_properties: mapId required');
    }
    final selected = await reader.withMetadataFields({'settings'});
    return selected.read((catalog) async {
      await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
      final settings = catalog.projectMetadata.settings;
      final base = ProjectManifest(name: catalog.projectMetadata.name,
          version: catalog.projectMetadata.version, maps: const [], tilesets: const [],
          settings: ProjectSettings(dimension: settings.dimension, spatialCamera: settings.spatialCamera,
              tileWidth: settings.tileWidth, tileHeight: settings.tileHeight));
      final documents = await CatalogMetadataDocuments.readDocuments(snapshot: catalog.snapshot,
          project: base, ids: {'maps': {mapId}});
      final entry = documents.project.maps.where((entry) => entry.id == mapId).firstOrNull;
      if (entry == null) {
        throw const ProjectSnapshotException('project.map_missing', 'The map is not declared.');
      }
      final payload = await reader.store.gateway.captureResourcePayload(entry.relativePath);
      if (payload == null) {
        throw const ProjectSnapshotException('project.map_missing', 'The map document is missing.');
      }
      try {
        final bytes = await payload.readBytes();
        final map = MapData.fromJson(Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
        if (map.id != mapId || (actionId == 'map3d.camera.configure' && map.spatialScene == null)) {
          throw const FormatException('catalog.map_properties: map identity or dimension mismatch');
        }
        MapValidator.validate(map);
        final projectBytes = utf8.encode(jsonEncode(documents.project.toJson()));
        final snapshot = ProjectSnapshot(projectHandle: projectHandle,
            revision: fingerprint(selected.revision, mapId, payload.resourceRevision),
            manifest: documents.project, materializedCatalogProject: true,
            availableProjectSections: const {}, scopedStorageRevisions: {entry.relativePath: payload.resourceRevision},
            maps: [map], resourceFingerprints: {'project': computeAuthoringBytesFingerprint(projectBytes, logicalName: 'project.json'),
              'map:$mapId': payload.resourceRevision},
            resourceBytes: {'project': projectBytes, 'map:$mapId': bytes},
            resourceStorageKeys: {'project': 'project.json', 'map:$mapId': entry.relativePath});
        final selection = CatalogSpatialMapSelection._(selected, snapshot,
            entry.relativePath, payload.resourceRevision, selected.revision, mapId);
        if (await selection.currentRevision() != snapshot.revision) {
          throw AuthoringPlanException(code: 'plan.stale', message: 'The map changed while selecting its properties.');
        }
        return selection;
      } finally {
        await payload.release();
      }
    });
  }

  static Future<CatalogSpatialMapSelection> read(
      {required CatalogProjectReader reader,
      required ProjectHandle projectHandle,
      required String actionId,
      required Map<String, Object?> parameters}) async {
    if (!supports(actionId, parameters: parameters)) {
      throw const FormatException('catalog.spatial: unsupported action');
    }
    if (actionId == 'map.update_metadata' || actionId == 'map3d.camera.configure' ||
        actionId == 'warp.ladder.configure') {
      return _readProperties(reader: reader, projectHandle: projectHandle, actionId: actionId, parameters: parameters);
    }
    if (const {'warp.update', 'warp.create', 'connection.upsert',
        'connection.create_bidirectional_apply'}.contains(actionId)) {
      return _readRelations(reader: reader, projectHandle: projectHandle,
          actionId: actionId, parameters: parameters);
    }
    if (actionId == 'map.apply_operations') {
      final operations = parameters['operations'];
      if (operations is! List ||
          operations.isEmpty ||
          operations.any((op) =>
              op is! Map ||
              (op['kind'] != 'layer.reorder_by_id' &&
                  (op['kind'] != 'layer.add' ||
                      !const {'environment', 'border'}.contains(op['layerKind']))))) {
        throw AuthoringPlanException(
            code: 'catalog.mutation_scope_required',
            message:
                'Only native Environment and Border layer creation and identity layer reordering have a targeted map-operation scope.');
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
            actionId == 'map.update_metadata' ||
            actionId == 'entity.upsert' ||
            actionId == 'trigger.create' ||
            actionId.startsWith('environment.') ||
            actionId.startsWith('border_layer.') ||
            actionId.startsWith('smart_tile.');
        if (map.id != mapId ||
            (map.spatialScene == null && !supportsTwoDimensions)) {
          throw const FormatException(
              'catalog.spatial: map identity or dimension mismatch');
        }
        if (actionId == 'entity.upsert' && parameters['entity'] is Map) {
          final entity = MapEntity.fromJson(
              Map<String, dynamic>.from(parameters['entity'] as Map));
          final before = map.entities
              .where((existing) => existing.id == entity.id)
              .firstOrNull;
          if (before != null && before.kind != entity.kind) {
            throw AuthoringPlanException(
                code: 'catalog.mutation_scope_required',
                message:
                    'Changing an existing entity kind requires an incoming narrative reference index.');
          }
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
        final consumedEventIds = _consumedNarrativeEvents(candidates);
        final dependencyCount = consumedEventIds.length +
            ids.values.fold<int>(0, (count, values) => count + values.length);
        if (dependencyCount > catalog.snapshot.limits.maxClosureNodes) {
          throw const FormatException(
              'catalog.spatial: dependency budget exceeded');
        }
        if (consumedEventIds.isNotEmpty) {
          metadata = metadata.copyWith(
              eventRegistry: await CatalogNarrativeEventDocuments.read(
                  catalog.snapshot, consumedEventIds));
        }
        final roots = <CatalogDefinitionKey>{};
        for (final field in const {
          CatalogDefinitionKind.environmentPreset: {'presetId'},
          CatalogDefinitionKind.borderRecord: {
            'blueprintId',
            'targetBlueprintId'
          },
          CatalogDefinitionKind.smartTileAtlas: {'atlasId'},
          CatalogDefinitionKind.smartTilePreset: {'presetId', 'targetPresetId'},
          CatalogDefinitionKind.smartTileMaterial: {'materialId'},
          CatalogDefinitionKind.smartTilePattern: {'patternId'},
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
            'illustrationElementId',
            'variantElementIds'
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
        if (consumedEventIds.isNotEmpty) {
          encoded['eventRegistry'] = metadata.eventRegistry?.toJson();
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
            entry.relativePath, payload.resourceRevision, catalogRevision, mapId);
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

  static Future<CatalogSpatialMapSelection> _readRelations({
    required CatalogProjectReader reader,
    required ProjectHandle projectHandle,
    required String actionId,
    required Map<String, Object?> parameters,
  }) async {
    final isWarp = actionId.startsWith('warp.');
    final args = SemanticParameters(parameters, allowed: {
      'mapId',
      if (isWarp) 'warp',
      if (actionId == 'warp.update') 'warpId',
      if (!isWarp) ...{'direction', 'targetMapId', 'offset'},
    });
    final mapId = args.string('mapId');
    final selected = await reader.withMetadataFields({'settings'});
    return selected.read((catalog) async {
      await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
      var metadata = await CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot, project: catalog.projectMetadata,
          ids: {'maps': {mapId}});
      final maps = <String, MapData>{};
      final mapBytes = <String, List<int>>{};
      final revisions = <String, String>{};
      final storageKeys = <String, String>{};
      final fingerprints = <String, String>{};
      Future<MapData> readMap(String id) async {
        if (maps[id] != null) return maps[id]!;
        final entry = metadata.project.maps.where((entry) => entry.id == id).firstOrNull;
        if (entry == null) {
          throw semanticFailure(isWarp ? 'warp.target_map_missing' : 'connection.target_map_missing',
              'A selected relation map is not declared.', details: {'mapId': id});
        }
        final payload = await reader.store.gateway.captureResourcePayload(entry.relativePath);
        if (payload == null) throw const FormatException('catalog.relation: selected map missing');
        try {
          final bytes = await payload.readBytes();
          final map = MapData.fromJson(Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
          if (map.id != id) throw const FormatException('catalog.relation: map identity mismatch');
          maps[id] = map;
          mapBytes['map:$id'] = bytes;
          storageKeys['map:$id'] = entry.relativePath;
          fingerprints['map:$id'] = payload.resourceRevision;
          revisions[entry.relativePath] = payload.resourceRevision;
          return map;
        } finally {
          await payload.release();
        }
      }
      final source = await readMap(mapId);
      const actions = WarpConnectionActions();
      MapWarp? updated;
      MapData? after;
      var destinationOnly = false;
      String targetId;
      if (isWarp) {
        if (actionId == 'warp.create') {
          after = actions.previewCreate(source, warp: args.object('warp'));
          updated = after.warps.last;
        } else {
          final warpId = args.string('warpId');
          after = actions.previewUpdate(source, warpId: warpId, warp: args.object('warp'));
          final index = source.warps.indexWhere((warp) => warp.id == warpId);
          updated = after.warps[index];
          destinationOnly = source.warps[index].copyWith(
              targetMapId: updated.targetMapId, targetPos: updated.targetPos) == updated;
        }
        targetId = updated.targetMapId;
      } else {
        targetId = args.string('targetMapId');
        actions.previewConnection(source, direction: args.string('direction'),
            targetMapId: targetId, offset: args.integer('offset'));
      }
      metadata = await CatalogMetadataDocuments.readDocuments(
          snapshot: catalog.snapshot, project: catalog.projectMetadata,
          ids: {'maps': {mapId, targetId}});
      final target = await readMap(targetId);
      if (!isWarp) {
        final direction = MapConnectionDirection.values.byName(args.string('direction'));
        final neighbors = <String>{
          if (source.spatialScene == null)
            for (final connection in source.connections)
              if (connection.direction == direction) connection.targetMapId,
          if (actionId == 'connection.create_bidirectional_apply' && target.spatialScene == null)
            for (final connection in target.connections)
              if (connection.direction == direction.opposite) connection.targetMapId,
        }..removeAll(maps.keys);
        if (neighbors.isNotEmpty) {
          metadata = await CatalogMetadataDocuments.readDocuments(
              snapshot: catalog.snapshot, project: catalog.projectMetadata,
              ids: {'maps': {mapId, targetId, ...neighbors}});
          for (final id in neighbors) { await readMap(id); }
        }
      }
      var definitions = metadata.project;
      if (updated != null && !destinationOnly && updated.door != null) {
        final instance = source.spatialScene!.instances.singleWhere(
            (value) => value.id == updated!.door!.instanceId);
        final unit = await catalog.lookup(CatalogDefinitionKey(CatalogDefinitionKind.model3d, instance.modelId));
        definitions = definitions.copyWith(models3d: [
          if (unit != null) ProjectModel3dEntry.fromJson(Map<String, dynamic>.from(unit.payload['value'] as Map)),
        ]);
        validateMapWarpDoor(after!, updated, models: definitions.models3d);
      }
      final projectBytes = utf8.encode(jsonEncode(definitions.toJson()));
      final catalogRevision = 'sha256:${catalog.snapshot.root.sha256}';
      final sourcePath = storageKeys['map:$mapId']!;
      final dependencies = Map<String, String>.from(revisions)..remove(sourcePath);
      final revision = fingerprint(catalogRevision, mapId, revisions[sourcePath]!, readDependencies: dependencies);
      final snapshot = ProjectSnapshot(projectHandle: projectHandle, revision: revision,
          manifest: definitions, materializedCatalogProject: true,
          availableProjectSections: const {}, scopedStorageRevisions: revisions,
          maps: maps.values.toList(), resourceFingerprints: {
            ...fingerprints, 'project': computeAuthoringBytesFingerprint(projectBytes, logicalName: 'project.json')},
          resourceBytes: {...mapBytes, 'project': projectBytes},
          resourceStorageKeys: {...storageKeys, 'project': 'project.json'});
      final result = CatalogSpatialMapSelection._(selected, snapshot, sourcePath,
          revisions[sourcePath]!, catalogRevision, mapId);
      if (await result.currentRevision() != revision) {
        throw AuthoringPlanException(code: 'plan.stale',
            message: 'A selected relation map or catalog changed while reading.');
      }
      return result;
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
    final dependencies = <String, String>{};
    for (final path in snapshot.scopedStorageRevisions!.keys.where((path) => path != storageKey)) {
      final revision = await reader.store.gateway.readResourceRevision(path);
      if (revision == null) throw AuthoringPlanException(code: 'plan.stale', message: 'A selected warp destination disappeared.');
      dependencies[path] = revision;
    }
    return fingerprint('sha256:${root.sha256}', mapId, map, readDependencies: dependencies);
  }

  Future<
      ({
        List<AuthoringResourceChange> changes,
        AuthoringDiff diff,
        String fingerprint
      })> translate(AuthoringPlan plan) async {
    final changes = plan.changeSet.changes;
    final action = plan.request.actionId;
    final relation = const {'warp.update', 'warp.create', 'connection.upsert',
        'connection.create_bidirectional_apply'}.contains(action);
    final expectedMaps = <String, MapData>{};
    if (relation) {
      const actions = WarpConnectionActions();
      final source = snapshot.mapById(mapId)!;
      final parameters = plan.request.parameters;
      if (action.startsWith('warp.')) {
        final warp = Map<String, Object?>.from(parameters['warp'] as Map);
        expectedMaps[mapId] = action == 'warp.create'
            ? actions.previewCreate(source, warp: warp)
            : actions.previewUpdate(source, warpId: parameters['warpId'] as String, warp: warp);
      } else {
        final direction = parameters['direction'] as String;
        final targetId = parameters['targetMapId'] as String;
        final offset = parameters['offset'] as int;
        expectedMaps[mapId] = actions.previewConnection(source, direction: direction,
            targetMapId: targetId, offset: offset);
        if (action == 'connection.create_bidirectional_apply') {
          expectedMaps[targetId] = actions.previewConnection(snapshot.mapById(targetId)!,
              direction: MapConnectionDirection.values.byName(direction).opposite.name,
              targetMapId: mapId, offset: -offset);
        }
      }
    }
    if (changes.length != (relation ? expectedMaps.length : 1)) {
      throw AuthoringPlanException(code: 'catalog.mutation_outside_scope',
          message: 'The action must change only its selected maps.');
    }
    final seen = <String>{};
    for (final change in changes) {
      final id = change.resource.id;
      final expectedPath = relation ? snapshot.resourceStorageKeys['map:$id'] : storageKey;
      if (!seen.add(id) || change.storageKey != expectedPath ||
          change.resource.kind != 'map' ||
          (relation ? !expectedMaps.containsKey(id) : id != mapId) ||
          change.beforeRevision != snapshot.resourceFingerprints['map:$id'] ||
          change.afterPayload == null) {
        throw AuthoringPlanException(code: 'catalog.mutation_outside_scope',
            message: 'The action changed data outside its selected maps.');
      }
      final projected = MapData.fromJson(Map<String, dynamic>.from(
          jsonDecode(utf8.decode(await change.afterPayload!.readBytes())) as Map));
      if (relation) {
        if (projected != expectedMaps[id]) {
          throw AuthoringPlanException(code: 'catalog.mutation_outside_scope',
              message: 'The relation changed data outside its validated update.');
        }
      } else if (action == 'warp.ladder.configure') {
        final parameters = plan.request.parameters;
        final ladder = parameters['ladder'];
        final expected = updateWarpOnMap(snapshot.mapById(mapId)!,
            warpId: parameters['warpId'] as String,
            ladder: ladder == null
                ? null
                : MapWarpLadder.fromJson(
                    Map<String, dynamic>.from(ladder as Map)),
            clearLadder: ladder == null);
        if (projected != expected) {
          throw AuthoringPlanException(
              code: 'catalog.mutation_outside_scope',
              message: 'The ladder action changed unrelated map content.');
        }
      } else {
        MapValidator.validate(projected, projectDialogueContext: snapshot.manifest);
        validateResourceLibraryScopeIndex(snapshot.manifest,
            ResourceLibraryUsageIndex.fromDocuments(maps: [projected], documents: [
              ResourceUsageDocument('map', projected.id, projected.name, storageKey, projected.toJson())
            ]));
      }
    }
    final state = computeAuthoringJsonFingerprint({
      'baseCatalog': catalogRevision,
      'resources': {for (final change in changes) change.storageKey: change.afterRevision}
    }, logicalName: 'catalog-spatial-map-state.json');
    final diff = AuthoringDiff([
      for (final entry in plan.changeSet.diff.entries)
        AuthoringDiffEntry.fromJson({
          ...entry.toJson(),
          'resource': {
            ...entry.resource.toJson(),
            'extensions': {
              ...entry.resource.extensions,
              'nativeMapResourcePath': snapshot.resourceStorageKeys['map:${entry.resource.id}'] ?? storageKey
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

Set<String> _consumedNarrativeEvents(Object? value) {
  final result = <String>{};
  void visit(Object? node) {
    if (node is Map) {
      if (node['kind'] == 'narrativeEventConsumed' && node['eventId'] is String) {
        result.add(node['eventId'] as String);
      }
      for (final child in node.values) {
        visit(child);
      }
    } else if (node is List) {
      for (final child in node) {
        visit(child);
      }
    }
  }
  visit(value);
  return result;
}
