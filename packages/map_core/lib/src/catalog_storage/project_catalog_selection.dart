import 'dart:convert';

import '../../map_core_domain.dart';
import '../models/scene_actor_route.dart';
import 'catalog_storage.dart';
import 'portable_catalog_publication.dart';

final class ProjectCatalogSelection {
  ProjectCatalogSelection(this.catalog);

  final PortableProjectCatalog catalog;

  Future<ProjectManifest> forMap(
    MapData map, {
    Iterable<CatalogDefinitionKey> additionalRoots = const [],
  }) => forMaps([map], additionalRoots: additionalRoots);

  Future<ProjectManifest> forMaps(
    Iterable<MapData> maps, {
    Iterable<CatalogDefinitionKey> additionalRoots = const [],
  }) async {
    final roots = <CatalogDefinitionKey>{...additionalRoots};
    for (final map in maps) {
      roots.addAll(await _rootsForMap(map));
    }
    return resolve(roots);
  }

  Future<Set<CatalogDefinitionKey>> _rootsForMap(MapData map) async {
    final metadata = catalog.projectMetadata;
    final roots = <CatalogDefinitionKey>{};
    void add(CatalogDefinitionKind kind, String? id) {
      if (id != null && id.isNotEmpty) {
        roots.add(CatalogDefinitionKey(kind, id));
      }
    }

    add(CatalogDefinitionKind.tileset, map.tilesetId);
    for (final layer in map.layers) {
      switch (layer) {
        case TileLayer(:final palette):
          for (final tile in palette) {
            add(CatalogDefinitionKind.tileset, tile.tilesetId);
          }
        case ObjectLayer(:final tileObjects):
          for (final tile in tileObjects) {
            add(CatalogDefinitionKind.tileset, tile.tile.tilesetId);
          }
        case SmartTileLayer(
          :final presetId,
          :final materialPalette,
          :final patternStrokes,
        ):
          add(CatalogDefinitionKind.smartTilePreset, presetId);
          for (final id in materialPalette) {
            add(CatalogDefinitionKind.smartTileMaterial, id);
          }
          for (final stroke in patternStrokes) {
            add(CatalogDefinitionKind.smartTilePattern, stroke.patternId);
          }
        case EnvironmentLayer(:final content):
          for (final area in content.areas) {
            add(CatalogDefinitionKind.environmentPreset, area.presetId);
          }
        case BorderLayer(:final content):
          for (final feature in content.features) {
            add(CatalogDefinitionKind.borderRecord, feature.blueprintId);
            for (final placement
                in feature.materialization?.placements ??
                    const <BorderResolvedPlacement>[]) {
              add(
                CatalogDefinitionKind.borderVisualSnapshot,
                placement.visualSnapshotId,
              );
            }
            for (final ground
                in feature.materialization?.ground ??
                    const <BorderResolvedGroundCell>[]) {
              add(
                CatalogDefinitionKind.borderVisualSnapshot,
                ground.visualSnapshotId,
              );
            }
          }
        default:
          break;
      }
    }
    for (final placed in map.placedElements) {
      add(CatalogDefinitionKind.element, placed.elementId);
    }
    for (final platform in map.movingPlatforms) {
      for (final variant in platform.variants) {
        add(CatalogDefinitionKind.element, variant.elementId);
      }
    }
    add(
      CatalogDefinitionKind.character,
      metadata.settings.defaultPlayerCharacterId,
    );
    for (final id in metadata.newGame.playerAvatarCharacterIds) {
      add(CatalogDefinitionKind.character, id);
    }
    final sceneIds = _mapSceneIds(map, metadata);
    final scenes = metadata.scenes.where(
      (scene) => sceneIds.contains(scene.id),
    );
    final trainerIds = {
      for (final entity in map.entities) ?entity.npc?.trainerId,
      for (final scene in scenes)
        for (final node in scene.graph.nodes)
          if (node.payload case SceneBattlePayload(:final trainerId))
            ?trainerId,
      for (final scene in scenes)
        for (final node in scene.graph.nodes)
          if (node.payload case SceneBattlePayload(:final demonstration))
            ?demonstration?.playerTrainerId,
    };
    for (final trainer in metadata.trainers.where(
      (trainer) => trainerIds.contains(trainer.id),
    )) {
      add(CatalogDefinitionKind.character, trainer.characterId);
      add(CatalogDefinitionKind.element, trainer.portraitElementId);
    }
    for (final entity in map.entities) {
      add(
        CatalogDefinitionKind.element,
        entity.resolvedProjectElementIdForEditor,
      );
      for (final id
          in entity.healingDisplay?.variantElementIds ?? const <String>[]) {
        add(CatalogDefinitionKind.element, id);
      }
      add(CatalogDefinitionKind.character, entity.npc?.characterId);
      for (final variant
          in entity.presentation?.variants ??
              const <MapEntityPresentationVariant>[]) {
        add(CatalogDefinitionKind.character, variant.characterId);
      }
    }
    for (final event in map.events) {
      for (final page in event.pages) {
        final id = page.spriteId;
        if (id != null && id.isNotEmpty) {
          final key = CatalogDefinitionKey(CatalogDefinitionKind.character, id);
          if (await catalog.snapshot.indexEntry(key) != null) roots.add(key);
        }
      }
    }
    for (final instance
        in map.spatialScene?.instances ?? const <SpatialModelInstance>[]) {
      add(CatalogDefinitionKind.model3d, instance.modelId);
    }
    add(
      CatalogDefinitionKind.smartTileAtlas,
      map.spatialScene?.cliffFrame?.atlasId,
    );
    final cinematicIds = {
      for (final scene in scenes)
        for (final node in scene.graph.nodes)
          if (node.payload case SceneCinematicPayload(:final cinematicId))
            cinematicId,
    };
    for (final cinematic in metadata.cinematics.where(
      (cinematic) =>
          cinematic.mapId == map.id || cinematicIds.contains(cinematic.id),
    )) {
      for (final binding
          in cinematic.stageContext?.actorAppearanceBindings ??
              const <CinematicActorAppearanceBinding>[]) {
        add(CatalogDefinitionKind.character, binding.characterId);
      }
    }
    for (final scene in scenes) {
      for (final node in scene.graph.nodes) {
        final payload = node.payload;
        if (payload is SceneActionPayload && payload.interactiveCommand is SceneActorRouteInteractiveCommand) {
          for (final step in (payload.interactiveCommand as SceneActorRouteInteractiveCommand).steps) {
            if (step is SceneActorAppearanceStep) add(CatalogDefinitionKind.character, step.characterId);
          }
        }
        if (payload case SceneActionPayload(
          interactiveCommand: SceneWarpInteractiveCommand(:final presentation),
        )) {
          add(
            CatalogDefinitionKind.element,
            presentation?.illustrationElementId,
          );
        }
        if (payload is SceneYarnDialoguePayload) {
          for (final id in payload.speakerHints) {
            final key = CatalogDefinitionKey(
              CatalogDefinitionKind.character,
              id,
            );
            if (await catalog.snapshot.indexEntry(key) != null) roots.add(key);
          }
          for (final policy in payload.linePolicies) {
            for (final icon
                in policy.feedback.segments.whereType<DialogueIconSegment>()) {
              final key = CatalogDefinitionKey(
                CatalogDefinitionKind.tileset,
                icon.assetId,
              );
              if (await catalog.snapshot.indexEntry(key) != null) {
                roots.add(key);
              }
            }
          }
        }
      }
    }
    return roots;
  }

  Future<ProjectManifest> resolve(Iterable<CatalogDefinitionKey> roots) async {
    final selected = <CatalogDefinitionKey, CatalogDefinitionUnit>{};
    final active = <CatalogDefinitionKey>{};
    final dynamic = {
      for (final declaration
          in PortableCatalogPublication.projectDynamicDependencies(
            catalog.projectMetadata,
          ))
        declaration.owner: declaration.targets,
    };
    Future<void> visit(CatalogDefinitionKey key, int depth) async {
      if (active.contains(key)) {
        throw FormatException('catalog.selection: dependency cycle at $key');
      }
      if (selected.containsKey(key)) return;
      if (depth > catalog.snapshot.limits.maxClosureDepth ||
          selected.length >= catalog.snapshot.limits.maxClosureNodes) {
        throw const FormatException(
          'catalog.selection: closure budget exceeded',
        );
      }
      final unit = await catalog.lookup(key);
      if (unit == null) {
        throw FormatException('catalog.selection: missing definition $key');
      }
      active.add(key);
      selected[key] = unit;
      final familyId = switch (key.kind) {
        CatalogDefinitionKind.resourceLibraryEntry =>
          ResourceLibraryEntry.fromJson(
            Map<String, Object?>.from(unit.payload['value']! as Map),
          ).familyId,
        CatalogDefinitionKind.resourceFamily => ResourceFamily.fromJson(
          Map<String, Object?>.from(unit.payload['value']! as Map),
        ).parentId,
        _ => null,
      };
      final isClassification =
          key.kind == CatalogDefinitionKind.resourceLibraryEntry ||
          key.kind == CatalogDefinitionKind.resourceFamily;
      for (final dependency in {
        if (!isClassification)
          ..._dependencies(catalog.projectWithDefinitions([unit])),
        if (familyId != null &&
            !ResourceLibraryCatalog.predefinedFamilies.any(
              (family) => family.id == familyId,
            ))
          CatalogDefinitionKey(CatalogDefinitionKind.resourceFamily, familyId),
        ...unit.references,
        ...?dynamic[key],
      }) {
        await visit(dependency, depth + 1);
      }
      final resourceKind = key.kind == CatalogDefinitionKind.borderRecord
          ? 'borderBlueprint'
          : key.kind.name;
      if (ResourceLibraryCatalog.resourceKinds.contains(resourceKind)) {
        final classificationKey = CatalogDefinitionKey(
          CatalogDefinitionKind.resourceLibraryEntry,
          '$resourceKind:${key.id}',
        );
        if (await catalog.lookup(classificationKey) != null) {
          await visit(classificationKey, depth + 1);
        }
      }
      active.remove(key);
    }

    for (final root in roots) {
      await visit(root, 0);
    }
    return catalog.projectWithDefinitions(selected.values);
  }
}

Set<String> _mapSceneIds(MapData map, ProjectManifest metadata) {
  final ids = <String>{
    ?metadata.newGame.preSessionSceneId,
    for (final event in map.events)
      for (final page in event.pages)
        if (page.sceneTarget case final target?) target.sceneId,
  };
  for (final record
      in metadata.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
    final definition = record.definitionOrNull;
    if (definition == null) continue;
    final applies = definition.source.when(
      entityInteract: (mapId, _) => mapId == map.id,
      entityBump: (mapId, _) => mapId == map.id,
      entityAutorun: (mapId, _) => mapId == map.id,
      modelInteract: (mapId, _) => mapId == map.id,
      triggerBump: (mapId, _) => mapId == map.id,
      triggerEnter: (mapId, _) => mapId == map.id,
      mapEnter: (mapId) => mapId == map.id,
      outcomeReceived: (_) => true,
    );
    if (applies) ids.add(definition.sceneId);
  }
  for (final scenario in metadata.scenarios) {
    if (scenario.scope != ScenarioScope.globalStory &&
        !scenario.nodes.any((node) => node.binding.mapId == map.id)) {
      continue;
    }
    for (final node in scenario.nodes) {
      final id = node.metadata['eventV2.sceneId'];
      if (id != null && id.isNotEmpty) ids.add(id);
    }
  }
  return ids;
}

Iterable<CatalogDefinitionKey> _dependencies(ProjectManifest view) sync* {
  CatalogDefinitionKey key(CatalogDefinitionKind kind, String id) =>
      CatalogDefinitionKey(kind, id);
  for (final tileset in view.tilesets) {
    if (tileset.folderId case final id?) {
      yield key(CatalogDefinitionKind.tilesetFolder, id);
    }
    for (final entry in tileset.paletteEntries) {
      for (final frame in entry.frames) {
        if (frame.tilesetId.isNotEmpty && frame.tilesetId != tileset.id) {
          yield key(CatalogDefinitionKind.tileset, frame.tilesetId);
        }
      }
    }
  }
  for (final element in view.elements) {
    yield key(CatalogDefinitionKind.tileset, element.tilesetId);
    if (element.categoryId.isNotEmpty) {
      yield key(CatalogDefinitionKind.elementCategory, element.categoryId);
    }
    for (final frame in element.frames) {
      if (frame.tilesetId.isNotEmpty) {
        yield key(CatalogDefinitionKind.tileset, frame.tilesetId);
      }
    }
  }
  for (final category in view.elementCategories) {
    if (category.parentCategoryId case final id?) {
      yield key(CatalogDefinitionKind.elementCategory, id);
    }
  }
  for (final folder in view.tilesetFolders) {
    if (folder.parentFolderId case final id?) {
      yield key(CatalogDefinitionKind.tilesetFolder, id);
    }
  }
  for (final character in view.characters) {
    if (character.tilesetId.isNotEmpty) {
      yield key(CatalogDefinitionKind.tileset, character.tilesetId);
    }
    for (final portrait in character.portraits) {
      yield key(
        CatalogDefinitionKind.characterStudioDefinition,
        jsonEncode(['characterPortraitState', portrait.portraitStateId]),
      );
    }
    for (final animation in character.customAnimations) {
      yield key(
        CatalogDefinitionKind.characterStudioDefinition,
        jsonEncode(['characterAnimationDefinition', animation.definitionId]),
      );
    }
  }
  for (final environment in view.environmentPresets) {
    if (environment.categoryId case final id?) {
      yield key(CatalogDefinitionKind.elementCategory, id);
    }
    for (final item in environment.palette) {
      yield item.visualKind == EnvironmentVisualKind.element
          ? key(CatalogDefinitionKind.element, item.elementId!)
          : key(CatalogDefinitionKind.model3d, item.modelId!);
    }
  }
  final smart = view.smartTileCatalog;
  for (final atlas in smart.atlases) {
    yield key(CatalogDefinitionKind.tileset, atlas.tilesetId);
  }
  for (final material in smart.materials) {
    if (material.categoryId.isNotEmpty) {
      yield key(CatalogDefinitionKind.smartTileCategory, material.categoryId);
    }
  }
  Iterable<CatalogDefinitionKey> parts(
    Iterable<SmartTileVisualPart> values,
  ) sync* {
    for (final part in values) {
      yield switch (part.source) {
        SmartTileFrameSource(:final frame) => key(
          CatalogDefinitionKind.smartTileAtlas,
          frame.atlasId,
        ),
        SmartTileAnimationSource(:final animationId) => key(
          CatalogDefinitionKind.smartTileAnimation,
          animationId,
        ),
        SmartTileModel3dSource(:final modelId) => key(
          CatalogDefinitionKind.model3d,
          modelId,
        ),
      };
    }
  }

  for (final animation in smart.animations) {
    for (final frame in animation.frames) {
      yield key(CatalogDefinitionKind.smartTileAtlas, frame.frame.atlasId);
    }
  }
  for (final preset in smart.presets) {
    if (preset.categoryId.isNotEmpty) {
      yield key(CatalogDefinitionKind.smartTileCategory, preset.categoryId);
    }
    for (final id in smartTilePresetMaterialIds(
      preset,
    ).where((id) => id.isNotEmpty)) {
      yield key(CatalogDefinitionKind.smartTileMaterial, id);
    }
    for (final rule in preset.rules) {
      for (final candidate in rule.candidates) {
        yield* parts(candidate.parts);
      }
    }
  }
  for (final pattern in smart.patterns) {
    if (pattern.categoryId.isNotEmpty) {
      yield key(CatalogDefinitionKind.smartTileCategory, pattern.categoryId);
    }
    for (final cell in pattern.cells) {
      yield* parts(cell.parts);
    }
  }
  for (final record in view.borderCatalog.records) {
    final published = record.latestPublished?.definition;
    if (published == null) {
      throw const FormatException('catalog.selection: unpublished Border');
    }
    for (final definition in <BorderBlueprintDefinition>[
      record.draft.definition,
      published,
    ]) {
      if (definition.categoryId case final id?) {
        yield key(CatalogDefinitionKind.elementCategory, id);
      }
      for (final primitive in definition.primitives) {
        if (primitive.isSpatial) {
          yield key(CatalogDefinitionKind.model3d, primitive.sourceModelId!);
        } else {
          yield key(CatalogDefinitionKind.element, primitive.sourceElementId!);
          if (primitive is BorderPublishedPrimitive) {
            yield key(
              CatalogDefinitionKind.borderVisualSnapshot,
              primitive.visualSnapshotId,
            );
          }
        }
        for (final surface in primitive.groundSurfaces) {
          yield key(
            CatalogDefinitionKind.smartTilePreset,
            surface.sourceSmartTilePresetId,
          );
          yield key(
            CatalogDefinitionKind.smartTileMaterial,
            surface.materialId,
          );
        }
      }
      if (definition.ground case final ground?) {
        yield key(
          CatalogDefinitionKind.smartTilePreset,
          ground.sourceSmartTilePresetId,
        );
        if (ground is BorderPublishedGround) {
          for (final id in ground.visualSnapshotIdsByRole.values) {
            yield key(CatalogDefinitionKind.borderVisualSnapshot, id);
          }
        }
      }
    }
  }
  for (final family in view.resourceLibraryCatalog.families) {
    final parent = family.parentId;
    if (parent != null &&
        !ResourceLibraryCatalog.predefinedFamilies.any((f) => f.id == parent)) {
      yield key(CatalogDefinitionKind.resourceFamily, parent);
    }
  }
  for (final entry in view.resourceLibraryCatalog.entries) {
    final family = entry.familyId;
    if (family != null &&
        !ResourceLibraryCatalog.predefinedFamilies.any((f) => f.id == family)) {
      yield key(CatalogDefinitionKind.resourceFamily, family);
    }
  }
}
