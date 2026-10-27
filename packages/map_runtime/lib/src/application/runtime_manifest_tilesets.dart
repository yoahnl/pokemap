import 'package:map_core/map_core.dart';

import 'runtime_character_refs.dart';

Set<String> collectTilesetIdsReferencedOnMap(MapData map) {
  final ids = <String>{};
  void add(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isNotEmpty) {
      ids.add(t);
    }
  }

  for (final layer in map.layers.whereType<TileLayer>()) {
    for (final entry in layer.palette) {
      add(entry.tilesetId);
    }
  }
  for (final layer in map.layers.whereType<ObjectLayer>()) {
    for (final object in layer.tileObjects) {
      add(object.tile.tilesetId);
    }
  }
  return ids;
}

void addSmartTileTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest, {
  Iterable<String> additionalPresetIds = const [],
}) {
  final catalog = manifest.smartTileCatalog;
  if (catalog.isEmpty) return;
  final atlasById = <String, ProjectSmartTileAtlas>{
    for (final atlas in catalog.atlases) atlas.id: atlas,
  };
  final animationById = <String, ProjectSmartTileAnimation>{
    for (final animation in catalog.animations) animation.id: animation,
  };
  final presetById = <String, ProjectSmartTilePreset>{
    for (final preset in catalog.presets) preset.id: preset,
  };
  final patternById = <String, ProjectSmartTilePattern>{
    for (final pattern in catalog.patterns) pattern.id: pattern,
  };

  void addFrame(SmartTileFrameRef frame) {
    final tilesetId = atlasById[frame.atlasId]?.tilesetId.trim() ?? '';
    if (tilesetId.isNotEmpty) ids.add(tilesetId);
  }

  if (map.spatialScene?.cliffFrame case final frame?) addFrame(frame);

  void addSource(SmartTileVisualSource source) {
    source.map(
      model3d: (_) {},
      frame: (source) => addFrame(source.frame),
      animation: (source) {
        final animation = animationById[source.animationId];
        if (animation == null) return;
        for (final frame in animation.frames) {
          addFrame(frame.frame);
        }
      },
    );
  }

  void addPreset(ProjectSmartTilePreset preset) {
    for (final rule in preset.rules) {
      for (final candidate in rule.candidates) {
        for (final part in candidate.parts) {
          addSource(part.source);
        }
      }
    }
  }

  for (final layer in map.layers.whereType<SmartTileLayer>()) {
    final preset = presetById[layer.presetId];
    if (preset == null || preset.usage != layer.usage) continue;
    addPreset(preset);
    for (final stroke in layer.patternStrokes) {
      final pattern = patternById[stroke.patternId];
      if (pattern == null || pattern.usage != layer.usage) continue;
      for (final cell in pattern.cells) {
        for (final part in cell.parts) {
          addSource(part.source);
        }
      }
    }
  }
  for (final id in additionalPresetIds.toSet()) {
    final preset = presetById[id];
    if (preset != null) addPreset(preset);
  }
}

void addEntityVisualTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest,
) {
  final elementById = {for (final e in manifest.elements) e.id: e};
  for (final entity in map.entities) {
    final elementId = entity.resolvedProjectElementIdForEditor?.trim();
    final references = <String>[
      if (elementId != null && elementId.isNotEmpty) elementId,
      ...?entity.healingDisplay?.variantElementIds,
    ];
    for (final reference in references) {
      final entry = elementById[reference];
      if (entry == null || entry.frames.isEmpty) continue;
      for (final frame in entry.frames) {
        final tid = frame.tilesetId.trim().isNotEmpty
            ? frame.tilesetId.trim()
            : entry.tilesetId.trim();
        if (tid.isNotEmpty) ids.add(tid);
      }
    }
  }
}

void addPlacedElementVisualTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest,
) {
  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final elementIds = {
    for (final placed in map.placedElements) placed.elementId.trim(),
    for (final platform in map.movingPlatforms)
      for (final variant in platform.variants) variant.elementId.trim(),
  };
  for (final elementId in elementIds) {
    if (elementId.isEmpty) continue;
    final element = elementById[elementId];
    if (element == null || element.frames.isEmpty) continue;
    for (final frame in element.frames) {
      final frameTilesetId = frame.tilesetId.trim();
      final tilesetId = frameTilesetId.isEmpty
          ? element.tilesetId.trim()
          : frameTilesetId;
      if (tilesetId.isNotEmpty) ids.add(tilesetId);
    }
  }
}

void addCharacterTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest,
) {
  final charById = {for (final c in manifest.characters) c.id: c};
  final playerCharId = manifest.settings.defaultPlayerCharacterId?.trim();
  if (playerCharId != null && playerCharId.isNotEmpty) {
    final character = charById[playerCharId];
    final tid = character != null && _usesCharacterTileset(character)
        ? character.tilesetId.trim() : '';
    if (tid.isNotEmpty) ids.add(tid);
  }
  for (final entity in map.entities) {
    if (entity.kind != MapEntityKind.npc) continue;
    final charId = resolveNpcCharacterId(entity, manifest);
    if (charId == null || charId.isEmpty) continue;
    final character = charById[charId];
    final tid = character != null && _usesCharacterTileset(character)
        ? character.tilesetId.trim() : '';
    if (tid.isNotEmpty) ids.add(tid);
  }
}

bool _usesCharacterTileset(ProjectCharacterEntry character) =>
    character.animations.isEmpty || character.animations.any(
      (animation) => animation.sourceAssetId?.trim().isNotEmpty != true,
    );

Set<String> collectRuntimeMapCharacterIds(
  NarrativeMapView map,
  ProjectManifest manifest, {
  Set<String> additionalCharacterIds = const {},
  Set<String> additionalSceneIds = const {},
}) {
  final playerId = manifest.settings.defaultPlayerCharacterId?.trim();
  final sceneIds = collectRuntimeMapSceneIds(
    map,
    manifest,
    additionalSceneIds: additionalSceneIds,
  );
  final cinematicIds = {
    for (final scene in manifest.scenes)
      if (sceneIds.contains(scene.id))
        for (final node in scene.graph.nodes)
          if (node.payload case SceneCinematicPayload payload)
            payload.cinematicId,
  };
  final knownCharacters = manifest.characters.map((value) => value.id).toSet();
  return {
    if (playerId != null && playerId.isNotEmpty) playerId,
    if (manifest.partyCompanion.enabled)
      for (final visual in manifest.partyCompanion.mappings) visual.characterId,
    if (manifest.contactDevice case final device?)
      for (final contact in device.contacts) ?contact.characterId,
    ...manifest.newGame.playerAvatarCharacterIds,
    for (final scene in manifest.scenes)
      if (sceneIds.contains(scene.id))
        for (final node in scene.graph.nodes)
          if (node.payload case SceneActionPayload(interactiveCommand: SceneActorRouteInteractiveCommand(:final steps)))
            for (final step in steps)
              if (step is SceneActorAppearanceStep) step.characterId,
    for (final scene in manifest.scenes)
      if (sceneIds.contains(scene.id))
        for (final node in scene.graph.nodes)
          if (node.payload case SceneActionPayload(:final consequence))
            if (consequence case SceneSetPlayerAvatarConsequence(:final characterId))
              characterId,
    for (final entity in map.entities) ?resolveNpcCharacterId(entity, manifest),
    for (final entity in map.entities)
      for (final variant
          in entity.presentation?.variants ??
              const <MapEntityPresentationVariant>[])
        ?variant.characterId,
    for (final event in map.events)
      for (final page in event.pages)
        if (page.spriteId case final id?)
          if (knownCharacters.contains(id)) id,
    for (final cinematic in manifest.cinematics)
      if (cinematic.mapId == map.id || cinematicIds.contains(cinematic.id))
        for (final binding
            in cinematic.stageContext?.actorAppearanceBindings ??
                const <CinematicActorAppearanceBinding>[])
          binding.characterId,
    ...additionalCharacterIds,
  };
}

Set<String> collectRuntimeMapSceneIds(
  NarrativeMapView map,
  ProjectManifest manifest, {
  Set<String> additionalSceneIds = const {},
}) {
  final ids = <String>{
    ...additionalSceneIds,
    ?manifest.newGame.preSessionSceneId,
    for (final event in map.events)
      for (final page in event.pages)
        if (page.sceneTarget case final target?) target.sceneId,
  };
  for (final record
      in manifest.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
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
  for (final scenario in manifest.scenarios) {
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

Set<String> collectAllRuntimeTilesetIds(
  MapData map,
  ProjectManifest manifest, {
  Set<String> additionalSceneIds = const {},
  Set<String> additionalCharacterIds = const {},
  Iterable<String> additionalSmartTilePresetIds = const [],
}) {
  final ids = collectTilesetIdsReferencedOnMap(map);
  addSmartTileTilesetIds(
    ids,
    map,
    manifest,
    additionalPresetIds: additionalSmartTilePresetIds,
  );
  addEntityVisualTilesetIds(ids, map, manifest);
  addCharacterTilesetIds(ids, map, manifest);
  // Append placed-element visuals after the established sources so their
  // relative insertion order remains unchanged while the set deduplicates.
  addPlacedElementVisualTilesetIds(ids, map, manifest);
  final characterIds = collectRuntimeMapCharacterIds(
    map,
    manifest,
    additionalCharacterIds: additionalCharacterIds,
    additionalSceneIds: additionalSceneIds,
  );
  for (final character in manifest.characters) {
    if (characterIds.contains(character.id) &&
        _usesCharacterTileset(character) && character.tilesetId.isNotEmpty) {
      ids.add(character.tilesetId);
    }
  }
  final sceneIds = collectRuntimeMapSceneIds(
    map,
    manifest,
    additionalSceneIds: additionalSceneIds,
  );
  final registeredTilesets = manifest.tilesets.map((entry) => entry.id).toSet();
  for (final scene in manifest.scenes) {
    if (!sceneIds.contains(scene.id)) continue;
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is SceneActionPayload) {
        final command = payload.interactiveCommand;
        if (command is SceneWarpInteractiveCommand &&
            command.presentation?.illustrationElementId != null) {
          final visual = resolveSceneWarpPresentationVisual(
            command.presentation!,
            manifest,
          )!;
          ids.add(visual.tilesetId);
        }
      }
      if (payload is! SceneYarnDialoguePayload) continue;
      for (final policy in payload.linePolicies) {
        for (final icon
            in policy.feedback.segments.whereType<DialogueIconSegment>()) {
          if (registeredTilesets.contains(icon.assetId)) ids.add(icon.assetId);
        }
      }
    }
  }
  return ids;
}
