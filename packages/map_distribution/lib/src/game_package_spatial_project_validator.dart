import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import 'game_package_format_exception.dart';
import 'game_package_security_policy.dart';
import 'glb_model3d_inspector.dart';
import 'package_path_policy.dart';
import 'raster_image_dimensions.dart';

typedef GamePackagePayloadReader = List<int>? Function(String path);

final class GamePackageSpatialProjectValidator {
  const GamePackageSpatialProjectValidator({
    this.policy = const GamePackageSecurityPolicy(),
    this.gameplay = false,
  });

  final GamePackageSecurityPolicy policy;
  final bool gameplay;

  void _validateGameplay(ProjectManifest project) {
    for (final scene in project.scenes) {
      for (final node in scene.graph.nodes) {
        if (!SpatialGameplayCapabilities.supportsSceneNode(
            scene.executionProfile, node)) {
          _unsupported('scenes.${scene.id}.nodes.${node.id}');
        }
      }
    }
    for (final scenario in project.scenarios) {
      if (scenario.scope != ScenarioScope.globalStory) {
        _unsupported('scenarios.${scenario.id}');
      }
      for (final node in scenario.nodes) {
        if (node.binding.scriptId != null ||
            node.payload.actionKind != null ||
            node.type == ScenarioNodeType.dialogue ||
            node.type == ScenarioNodeType.choice) {
          _unsupported('scenarios.${scenario.id}.nodes.${node.id}');
        }
      }
    }
  }

  void _validateGameplayMap(MapData map, String path) {
    for (final zone in map.gameplayZones) {
      if (zone.kind != GameplayZoneKind.encounter) {
        _unsupported('$path.gameplayZones.${zone.id}');
      }
    }
    for (final trigger in map.triggers) {
      if (trigger.type != TriggerType.event) {
        _unsupported('$path.triggers.${trigger.id}');
      }
    }
    for (final event in map.events) {
      for (final page in event.pages) {
        if (page.script != null ||
            page.spriteId != null ||
            page.sceneTarget == null && page.message == null) {
          _unsupported('$path.events.${event.id}.pages.${page.pageNumber}');
        }
        final condition = page.condition;
        if (condition != null) {
          _validatePageCondition(condition, '$path.events.${event.id}');
        }
      }
    }
    for (final entity in map.entities) {
      final predicates = [
        entity.npc?.visibilityRule?.predicate,
        ...?entity.npc?.conditionalDialogues.map((entry) => entry.when)
      ];
      for (final predicate in predicates) {
        if (predicate != null &&
            const {
              MapEntityRuntimePredicateKind.cutsceneCompleted,
              MapEntityRuntimePredicateKind.cutsceneNotCompleted
            }.contains(predicate.kind)) {
          _unsupported('$path.entities.${entity.id}');
        }
      }
    }
  }

  void _validatePageCondition(ScriptCondition condition, String path) {
    if (!const {
      ScriptConditionType.allOf,
      ScriptConditionType.anyOf,
      ScriptConditionType.not,
      ScriptConditionType.flagIsSet,
      ScriptConditionType.flagIsUnset,
      ScriptConditionType.factEquals,
      ScriptConditionType.stepCompleted,
      ScriptConditionType.itemQuantityAtLeast,
      ScriptConditionType.eventIsConsumed,
    }.contains(condition.type)) {
      _unsupported(path);
    }
    for (final child in condition.children) {
      _validatePageCondition(child, path);
    }
  }

  void validate(ProjectManifest project, GamePackagePayloadReader readPayload) {
    try {
      if (project.version != ProjectVersion.v9 ||
          project.settings.dimension != ProjectDimension.threeD ||
          project.maps.isEmpty) {
        _fail('runtime3d.invalid_project', 'project/project.json',
            'Exploration requires a v9 3D project with an initial map.');
      }
      final json = project.toJson();
      for (final field in const [
        'scripts',
        'cinematics',
        'cinematicMediaAssets',
        'presentationCinematics',
      ]) {
        final value = json[field];
        if (value is List && value.isNotEmpty ||
            value is Map && value.isNotEmpty) {
          _unsupported('project.$field');
        }
      }
      for (final field in const [
        'scenarios',
        'facts',
        'worldRules',
        'scenes',
        'storylines',
        'shops',
        'badges',
        'trainers',
        'encounterTables',
        'progression',
      ]) {
        final value = json[field];
        if (!gameplay &&
            (value is List && value.isNotEmpty ||
                value is Map && value.isNotEmpty)) {
          _unsupported('project.$field');
        }
      }
      if (!gameplay &&
              (project.newGame.enabled ||
                  project.pokemon.enabled ||
                  (project.eventRegistry?.records.isNotEmpty ?? false)) ||
          project.regionalMap != null) {
        _unsupported('project/project.json');
      }
      if (gameplay) _validateGameplay(project);
      final maps = <MapData>[];
      for (final entry in project.maps) {
        final path = 'project/${entry.relativePath}';
        final mapJson = _object(_json(_read(readPayload, path)));
        final spatial = _object(mapJson['spatialScene']);
        if (spatial['navigation'] is! Map) {
          _fail('runtime3d.navigation_missing', path,
              'Every exploration map requires authored navigation.');
        }
        final map = MapData.fromJson(mapJson);
        if (map.id != entry.id) {
          _fail('runtime3d.map_id_mismatch', path,
              'Map identity differs from its manifest.');
        }
        for (final field in const [
          'events',
          'triggers',
          'gameplayZones',
        ]) {
          final value = mapJson[field];
          if (!gameplay && value is List && value.isNotEmpty) {
            _unsupported('$path.$field');
          }
        }
        if (gameplay) _validateGameplayMap(map, path);
        MapValidator.validate(map, projectDialogueContext: project);
        maps.add(map);
      }
      final mapsById = {for (final map in maps) map.id: map};
      for (final map in maps) {
        for (final connection in map.connections) {
          final path =
              'maps.${map.id}.connections.${connection.direction.name}';
          final target = mapsById[connection.targetMapId];
          if (target == null) {
            _fail('runtime3d.connection_target_missing', path,
                'The connected map is missing.');
          }
          if (!hasMapConnectionOverlap(
              sourceSize: map.size,
              targetSize: target.size,
              direction: connection.direction,
              offset: connection.offset)) {
            _fail('runtime3d.connection_no_overlap', path,
                'The connected map edges do not overlap.');
          }
          final horizontal = connection.direction.usesHorizontalOffset;
          final length = horizontal ? map.size.width : map.size.height;
          final targetLength =
              horizontal ? target.size.width : target.size.height;
          for (var index = 0; index < length; index++) {
            final targetIndex = index - connection.offset;
            if (targetIndex < 0 || targetIndex >= targetLength) continue;
            final sourcePos = switch (connection.direction) {
              MapConnectionDirection.north => GridPos(x: index, y: 0),
              MapConnectionDirection.south =>
                GridPos(x: index, y: map.size.height - 1),
              MapConnectionDirection.east =>
                GridPos(x: map.size.width - 1, y: index),
              MapConnectionDirection.west => GridPos(x: 0, y: index),
            };
            final targetPos = switch (connection.direction) {
              MapConnectionDirection.north =>
                GridPos(x: targetIndex, y: target.size.height - 1),
              MapConnectionDirection.south => GridPos(x: targetIndex, y: 0),
              MapConnectionDirection.east => GridPos(x: 0, y: targetIndex),
              MapConnectionDirection.west =>
                GridPos(x: target.size.width - 1, y: targetIndex),
            };
            final sourceHeight = map.spatialScene!
                .worldHeightAt(sourcePos.x + .5, sourcePos.y + .5);
            final targetHeight = target.spatialScene!
                .worldHeightAt(targetPos.x + .5, targetPos.y + .5);
            if ((sourceHeight - targetHeight).abs() > .25) {
              _fail('runtime3d.connection_height_mismatch', path,
                  'Connected edges require matching terrain heights.');
            }
          }
        }
        for (final warp in map.warps) {
          final target = mapsById[warp.targetMapId];
          if (target == null) {
            _fail(
                'runtime3d.warp_target_missing',
                'maps.${map.id}.warps.${warp.id}',
                'The passage destination map is missing.');
          }
          if (warp.targetPos.x >= target.size.width ||
              warp.targetPos.y >= target.size.height) {
            _fail(
                'runtime3d.warp_arrival_outside',
                'maps.${map.id}.warps.${warp.id}',
                'The passage arrival is outside its destination map.');
          }
        }
      }
      final dialogues = <String, RuntimeDialogueDocument>{};
      for (final entry in project.dialogues) {
        if (!gameplay && entry.declaredOutcomes.isNotEmpty ||
            !entry.relativePath.endsWith('.json')) {
          _unsupported('dialogues.${entry.id}');
        }
        final path = 'project/${entry.relativePath}';
        final bytes = _read(readPayload, path);
        _json(bytes);
        final document = const RuntimeDialogueDocumentCodec().decodeUtf8(bytes);
        for (final node in document.nodes) {
          for (final step in node.steps) {
            if (!gameplay &&
                    (step is! RuntimeDialogueLine ||
                        step.characterId != null ||
                        step.portraitStateId != null) ||
                step is RuntimeDialogueLine && step.portraitStateId != null) {
              _unsupported('$path.${node.title}');
            }
          }
        }
        final start = entry.defaultStartNode;
        if (start != null &&
            !document.nodes.any((node) => node.title == start)) {
          _fail('runtime3d.dialogue_node_missing', path,
              'Dialogue start node is missing.');
        }
        dialogues[entry.id] = document;
      }
      void validateEntityDialogue(DialogueRef ref, String entityId) {
        if (ref.scriptPathRelative.isNotEmpty) _unsupported(entityId);
        final document = dialogues[ref.dialogueId];
        if (document == null ||
            ref.startNode != null &&
                !document.nodes.any((node) => node.title == ref.startNode)) {
          _fail('runtime3d.dialogue_node_missing', entityId,
              'Entity dialogue or start node is missing.');
        }
      }

      for (final map in maps) {
        final defaultSpawnId = map.mapMetadata.defaultSpawnId?.trim();
        if (defaultSpawnId != null &&
            defaultSpawnId.isNotEmpty &&
            !map.entities.any((entity) =>
                entity.kind == MapEntityKind.spawn &&
                entity.spawn?.role == EntitySpawnRole.playerStart &&
                entity.id == defaultSpawnId)) {
          _fail('runtime3d.spawn_missing', 'maps.${map.id}.defaultSpawnId',
              'The default player start entity is missing.');
        }
        for (final entity in map.entities) {
          if (entity.kind == MapEntityKind.spawn) {
            final spawn = entity.spawn;
            if (spawn == null ||
                (spawn.role != EntitySpawnRole.playerStart &&
                    (!gameplay || spawn.role != EntitySpawnRole.other)) ||
                spawn.categoryTag.isNotEmpty ||
                entity.size != const GridSize(width: 1, height: 1) ||
                entity.properties.isNotEmpty ||
                entity.editorVisual != null ||
                entity.npc != null ||
                entity.sign != null ||
                entity.item != null) {
              _unsupported('maps.${map.id}.entities.${entity.id}');
            }
            continue;
          }
          if (gameplay && entity.kind == MapEntityKind.sign) {
            final sign = entity.sign;
            if (sign == null ||
                sign.dialogue == null ||
                sign.plainText.isNotEmpty ||
                entity.size != const GridSize(width: 1, height: 1) ||
                entity.properties.isNotEmpty ||
                entity.npc != null ||
                entity.item != null ||
                entity.spawn != null) {
              _unsupported('maps.${map.id}.entities.${entity.id}');
            }
            validateEntityDialogue(sign.dialogue!, entity.id);
            continue;
          }
          if (gameplay && entity.kind == MapEntityKind.custom) {
            if (entity.properties.isNotEmpty ||
                entity.npc != null ||
                entity.sign != null ||
                entity.item != null ||
                entity.spawn != null) {
              _unsupported('maps.${map.id}.entities.${entity.id}');
            }
            continue;
          }
          final npc = entity.npc;
          if (entity.kind != MapEntityKind.npc ||
              npc == null ||
              entity.size != const GridSize(width: 1, height: 1) ||
              !entity.blocksMovement ||
              entity.properties.isNotEmpty ||
              !gameplay && entity.editorVisual != null ||
              entity.sign != null ||
              entity.item != null ||
              entity.spawn != null ||
              npc.visualElementId.isNotEmpty ||
              npc.movement != const MapEntityNpcMovementConfig() ||
              npc.lineOfSightRange != 0 ||
              !gameplay &&
                  (npc.trainerId != null ||
                      npc.defeatDialogueRef != null ||
                      npc.visibilityRule != null ||
                      npc.conditionalDialogues.isNotEmpty)) {
            _unsupported('maps.${map.id}.entities.${entity.id}');
          }
          final character = project.characters
              .where((c) => c.id == npc.characterId)
              .firstOrNull;
          if (character == null ||
              !EntityFacing.values.every((direction) => character.animations
                  .any((clip) =>
                      clip.direction == direction &&
                      (clip.state == CharacterAnimationState.idle ||
                          clip.state == CharacterAnimationState.walk)))) {
            _fail('runtime3d.npc_character_missing', entity.id,
                'Static NPC requires directional character animations.');
          }
          for (final ref in [
            npc.dialogue,
            npc.defeatDialogueRef,
            ...npc.conditionalDialogues.map((entry) => entry.dialogue)
          ]) {
            if (ref == null) continue;
            validateEntityDialogue(ref, entity.id);
          }
        }
      }
      ProjectValidator.validate(project, maps: maps);
      final catalogue = _catalogue(readPayload);
      final closedAssets = <String, List<int>>{};
      List<int> closeAsset(String id,
          {String? expectedPath, String? mediaType}) {
        final record = catalogue[id];
        if (record == null ||
            expectedPath != null && record.logicalPath != expectedPath ||
            mediaType != null && record.mediaType != mediaType) {
          _fail('runtime3d.asset_reference_invalid', id,
              'The canonical source asset is missing or inconsistent.');
        }
        return closedAssets.putIfAbsent(id, () {
          final blob = _read(readPayload, record.blobPath);
          final digest = computeNarrativeProjectFingerprint([
            NarrativeProjectFingerprintEntry(
                relativePath: 'artifact-content', bytes: blob),
          ]);
          if (blob.length != record.byteLength || digest != record.digest) {
            _fail('runtime3d.asset_integrity_mismatch', record.blobPath,
                'Canonical content digest or byte length differs.');
          }
          final logical = _read(readPayload, 'project/${record.logicalPath}');
          if (logical.length != blob.length ||
              computeNarrativeProjectFingerprint([
                    NarrativeProjectFingerprintEntry(
                        relativePath: 'artifact-content', bytes: logical),
                  ]) !=
                  digest) {
            _fail('runtime3d.asset_integrity_mismatch', record.logicalPath,
                'Logical content differs from its canonical blob.');
          }
          return blob;
        });
      }

      final inspector = GlbModel3dInspector(
        maxTextureDimension:
            policy.maxImageDimension < 4096 ? policy.maxImageDimension : 4096,
        maxTexturePixels:
            policy.maxImagePixels < 16777216 ? policy.maxImagePixels : 16777216,
      );
      for (final model in project.models3d) {
        final bytes = closeAsset(model.sourceAssetId,
            expectedPath: model.relativePath, mediaType: 'model/gltf-binary');
        if (inspector.inspect(bytes) != model.inspection) {
          _fail('runtime3d.model_inspection_mismatch', model.relativePath,
              'Model geometry, bounds or animation inspection differs from its bytes.');
        }
      }
      final imageBounds = <String, RasterImageDimensions>{};
      RasterImageDimensions closeImage(String id, {String? expectedPath}) {
        final bytes = closeAsset(id, expectedPath: expectedPath);
        return imageBounds.putIfAbsent(id, () {
          final record = catalogue[id]!;
          final dimensions =
              decodeRasterImageDimensions(bytes, mediaType: record.mediaType);
          if (dimensions == null ||
              dimensions.width > policy.maxImageDimension ||
              dimensions.height > policy.maxImageDimension ||
              dimensions.width * dimensions.height > policy.maxImagePixels) {
            _fail('decodedAssetQuotaExceeded', record.logicalPath,
                'Image dimensions are invalid or exceed policy.');
          }
          final decoded = image.decodeImage(Uint8List.fromList(bytes));
          if (decoded == null ||
              decoded.width != dimensions.width ||
              decoded.height != dimensions.height) {
            _fail('runtime3d.image_invalid', record.logicalPath,
                'The referenced image cannot be decoded.');
          }
          return dimensions;
        });
      }

      for (final tileset in project.tilesets) {
        final source = tileset.source;
        if (source is! ProjectRegularAtlasTilesetSource) {
          _unsupported('tilesets.${tileset.id}');
        }
        final dimensions =
            closeImage(source.assetId, expectedPath: tileset.relativePath);
        if (source.pixelWidth != dimensions.width ||
            source.pixelHeight != dimensions.height) {
          _fail('runtime3d.image_dimensions_mismatch', tileset.relativePath,
              'Atlas metadata differs from its image.');
        }
      }
      if (gameplay) {
        for (final map in maps) {
          for (final entity in map.entities) {
            final elementId = entity.editorVisual?.elementId;
            if (elementId == null) continue;
            final path = 'maps.${map.id}.entities.${entity.id}.editorVisual';
            final element = project.elements
                .where((entry) => entry.id == elementId)
                .firstOrNull;
            if (element == null || element.frames.isEmpty) {
              _fail('runtime3d.entity_visual_invalid', path,
                  'The entity visual requires a canonical element with frames.');
            }
            for (final frame in element.frames) {
              final tilesetId = frame.tilesetId.trim().isEmpty
                  ? element.tilesetId
                  : frame.tilesetId;
              final tileset = project.tilesets
                  .where((entry) => entry.id == tilesetId)
                  .firstOrNull;
              final source = tileset?.source;
              if (source is! ProjectRegularAtlasTilesetSource) {
                _fail('runtime3d.entity_visual_invalid', path,
                    'Entity visual frames require canonical atlas images.');
              }
              final dimensions = closeImage(source.assetId,
                  expectedPath: tileset!.relativePath);
              final rect = frame.source;
              if (rect.x < 0 ||
                  rect.y < 0 ||
                  rect.width <= 0 ||
                  rect.height <= 0 ||
                  (rect.x + rect.width) * project.settings.tileWidth >
                      dimensions.width ||
                  (rect.y + rect.height) * project.settings.tileHeight >
                      dimensions.height ||
                  frame.durationMs != null && frame.durationMs! <= 0) {
                _fail('runtime3d.entity_visual_invalid', path,
                    'Entity visual cell rectangles must fit their canonical image.');
              }
            }
          }
        }
      }
      final hero = project.characters
          .where((character) =>
              character.id == project.settings.defaultPlayerCharacterId)
          .firstOrNull;
      if (hero == null || hero.animations.isEmpty) {
        _fail('runtime3d.hero_missing', 'settings.defaultPlayerCharacterId',
            'An animated exploration hero is required.');
      }
      for (final direction in [
        EntityFacing.north,
        EntityFacing.south,
        EntityFacing.east,
        EntityFacing.west
      ]) {
        if (!hero.animations.any((clip) =>
            clip.state == CharacterAnimationState.walk &&
            clip.direction == direction &&
            clip.frames.isNotEmpty)) {
          _fail('runtime3d.hero_animation_missing', hero.id,
              'The hero requires a walk animation in each direction.');
        }
      }
      for (final character in project.characters) {
        for (final clip in character.animations) {
          final sourceId = clip.sourceAssetId;
          if (sourceId == null || sourceId.isEmpty) {
            _fail('runtime3d.animation_source_missing', character.id,
                '3D character animations require dedicated image sources.');
          }
          _validateFrames(clip.frames, closeImage(sourceId), character.id);
        }
        for (final clip in character.customAnimations) {
          _validateFrames(
              clip.frames, closeImage(clip.sourceAssetId), character.id);
        }
      }
    } on GamePackageFormatException {
      rethrow;
    } on Object catch (error) {
      _fail('runtime3d.invalid_project', 'project/project.json',
          'Spatial exploration validation failed: $error');
    }
  }

  void _validateFrames(List<CharacterAnimationFrame> frames,
      RasterImageDimensions dimensions, String path) {
    if (frames.isEmpty) {
      _fail('runtime3d.animation_frames_invalid', path,
          'Animation frames cannot be empty.');
    }
    for (final frame in frames) {
      final rect = frame.source;
      if (frame.durationMs <= 0 ||
          rect.x < 0 ||
          rect.y < 0 ||
          rect.width <= 0 ||
          rect.height <= 0 ||
          rect.x + rect.width > dimensions.width ||
          rect.y + rect.height > dimensions.height) {
        _fail('runtime3d.animation_frames_invalid', path,
            'Animation duration or pixel rectangle is invalid.');
      }
    }
  }

  Map<String, _SpatialAsset> _catalogue(GamePackagePayloadReader read) {
    final json =
        _object(_json(_read(read, 'project/assets/.pokemap-assets.json')));
    _keys(json, {'schemaVersion', 'records'});
    if (json['schemaVersion'] != 1 || json['records'] is! List) {
      throw const FormatException('Invalid asset catalogue.');
    }
    final result = <String, _SpatialAsset>{};
    final logicalPaths = <String>{};
    for (final raw in json['records'] as List) {
      final record = _object(raw);
      _keys(record, {'id', 'logicalPath', 'artifact', 'usages', 'tags'});
      final artifact = _object(record['artifact']);
      _keys(artifact, {'digest', 'handle', 'mediaType', 'byteLength'});
      final id = record['id'] as String;
      final path = record['logicalPath'] as String;
      final digest = artifact['digest'] as String;
      final length = artifact['byteLength'] as int;
      final mediaType = artifact['mediaType'] as String;
      PackagePathPolicy.validate('project/$path', errorPath: path);
      if (id.isEmpty ||
          id.trim() != id ||
          !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(digest) ||
          artifact['handle'] != 'artifact://sha256/${digest.substring(7)}' ||
          !RegExp(r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$')
              .hasMatch(mediaType) ||
          length < 0 ||
          length > policy.maxFileBytes ||
          result.containsKey(id) ||
          !logicalPaths.add(PackagePathPolicy.collisionKey(path))) {
        throw const FormatException('Invalid canonical asset record.');
      }
      for (final field in ['usages', 'tags']) {
        if (record[field] is! List ||
            (record[field] as List).any((v) => v is! String)) {
          throw const FormatException('Invalid asset record strings.');
        }
      }
      result[id] = _SpatialAsset(path, digest, mediaType, length);
    }
    return result;
  }

  List<int> _read(GamePackagePayloadReader read, String path) {
    PackagePathPolicy.validate(path, errorPath: path);
    final bytes = read(path);
    if (bytes == null) {
      _fail('missingFile', path, 'Referenced exploration payload is missing.');
    }
    if (bytes.length > policy.maxFileBytes) {
      _fail('entryTooLarge', path, 'Referenced payload exceeds policy.');
    }
    return bytes;
  }

  Object? _json(List<int> bytes) {
    if (bytes.length > policy.maxJsonBytes) {
      throw const FormatException('JSON quota exceeded.');
    }
    return jsonDecode(utf8.decode(bytes, allowMalformed: false));
  }

  Map<String, dynamic> _object(Object? value) =>
      Map<String, dynamic>.from(value as Map);
  void _keys(Map<String, dynamic> value, Set<String> allowed) {
    if (value.keys.any((key) => !allowed.contains(key)) ||
        allowed.any((key) => !value.containsKey(key))) {
      throw const FormatException('Unexpected canonical catalogue fields.');
    }
  }

  Never _unsupported(String path) => _fail(
      gameplay
          ? 'runtime3d.gameplay_unsupported'
          : 'runtime3d.exploration_only',
      path,
      gameplay
          ? 'This operation is outside map3d.gameplay@1.'
          : '3D packages currently support exploration only.');
  Never _fail(String code, String path, String message) =>
      throw GamePackageFormatException(
          code: code, path: path, message: message);
}

final class _SpatialAsset {
  const _SpatialAsset(
      this.logicalPath, this.digest, this.mediaType, this.byteLength);
  final String logicalPath, digest, mediaType;
  final int byteLength;
  String get blobPath =>
      'project/assets/.pokemap-store/${digest.substring(7)}.blob';
}
