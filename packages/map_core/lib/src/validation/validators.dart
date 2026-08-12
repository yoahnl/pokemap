import '../exceptions/map_exceptions.dart';
import '../encounters/encounter_contract.dart';
import '../models/badge_definition.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/map_layer.dart';
import '../models/narrative_value.dart';
import '../models/project_manifest.dart';
import '../models/project_presentation_profile.dart';
import '../models/project_tileset_source.dart';
import '../models/project_trainer.dart';
import '../models/scenario_asset.dart';
import '../models/script_conditions.dart';
import '../models/smart_tile.dart';
import '../models/smart_tile_field.dart';
import '../operations/map_entities.dart';
import '../operations/map_placed_element_footprint.dart';
import '../operations/narrative_fact_runtime.dart';
import '../operations/smart_tile_catalog_validation.dart';
import '../operations/smart_tile_layer_operations.dart';
import 'dialogue_validation.dart';
import 'entity_editor_visual_validation.dart';

class ProjectValidator {
  // Scenario action/source kinds partagés avec l'éditeur/runtime.
  // On garde ces chaînes localisées ici pour valider de manière
  // déterministe sans dépendre d'un package runtime.
  static const Set<String> _scenarioWorldSourceKinds = <String>{
    'sourceMapEnter',
    'sourceTriggerEnter',
    'sourceEntityInteract',
  };
  static const String _scenarioOutcomeSourceKind = 'sourceOutcome';
  static const String _scenarioEmitOutcomeKind = 'emitOutcome';

  /// Rectangles sources valides, [durationMs] > 0 si présent, au moins une frame,
  /// tailles identiques si plusieurs frames (préparation animation).
  static void _validateVisualFrames(
    List<TilesetVisualFrame> frames, {
    required String context,
    required Set<String> knownTilesetIds,
  }) {
    if (frames.isEmpty) {
      throw ValidationException('$context must have at least one visual frame');
    }
    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final src = frame.source;
      if (src.x < 0 || src.y < 0) {
        throw ValidationException(
          '$context frame $i has invalid source coordinates',
        );
      }
      if (src.width <= 0 || src.height <= 0) {
        throw ValidationException('$context frame $i has invalid source size');
      }
      final overrideId = frame.tilesetId.trim();
      if (overrideId.isNotEmpty && !knownTilesetIds.contains(overrideId)) {
        throw ValidationException(
          '$context frame $i references missing tileset: $overrideId',
        );
      }
      final d = frame.durationMs;
      if (d != null && d <= 0) {
        throw ValidationException(
          '$context frame $i durationMs must be positive when set',
        );
      }
    }
    if (frames.length > 1) {
      final w = frames.first.source.width;
      final h = frames.first.source.height;
      for (var i = 1; i < frames.length; i++) {
        final s = frames[i].source;
        if (s.width != w || s.height != h) {
          throw ValidationException(
            '$context animation frames must share the same width and height',
          );
        }
      }
    }
  }

  static void validate(ProjectManifest manifest) {
    if (manifest.version != ProjectVersion.v6) {
      throw const ValidationException(
        'Smart Tiles-only projects require ProjectVersion.v6',
        code: 'smart_tile_v6_project_required',
      );
    }
    final smartTileDiagnostics = validateProjectSmartTileCatalog(
      catalog: manifest.smartTileCatalog,
      projectTilesetIds: manifest.tilesets.map((tileset) => tileset.id),
    );
    for (final diagnostic in smartTileDiagnostics) {
      if (diagnostic.isError) {
        throw ValidationException(
          '${diagnostic.path}: ${diagnostic.message}',
          code: diagnostic.code,
          details: <String, Object?>{
            'path': diagnostic.path,
            if (diagnostic.presetId case final presetId?) 'presetId': presetId,
            if (diagnostic.ruleId case final ruleId?) 'ruleId': ruleId,
            if (diagnostic.mask case final mask?) 'mask': mask,
            if (diagnostic.missingMasks.isNotEmpty)
              'missingMasks': diagnostic.missingMasks,
          },
        );
      }
    }
    for (final diagnostic in validateProjectPresentationProfile(
      manifest.effectivePresentation,
    )) {
      if (diagnostic.severity != ProjectPresentationDiagnosticSeverity.error) {
        continue;
      }
      throw ValidationException(
        '${diagnostic.path}: ${diagnostic.message}',
        code: diagnostic.code,
        details: <String, Object?>{'path': diagnostic.path},
      );
    }
    _validateUniqueness(manifest);
    _validateHierarchy(manifest);
    _validateEncounterTables(manifest.encounterTables);
    _validateProjectDialogues(manifest);
    _validateNewGameConfig(manifest);
    _validateTrainers(manifest);
    _validateCharacters(manifest);
    _validateSettings(manifest.settings);
  }

  static void _validateNewGameConfig(ProjectManifest manifest) {
    final config = manifest.newGame;
    if (!config.enabled) {
      return;
    }

    final startMapId = config.startMapId.trim();
    if (startMapId.isEmpty) {
      throw const ValidationException(
        'Enabled newGame config requires a startMapId',
      );
    }
    if (!manifest.maps.any((map) => map.id == startMapId)) {
      throw ValidationException(
        'newGame startMapId references an unknown map: $startMapId',
      );
    }
    if (config.startSpawnId != null && config.startSpawnId!.trim().isEmpty) {
      throw const ValidationException(
        'newGame startSpawnId must not be blank when provided',
      );
    }
    if (config.playerName.trim().isEmpty) {
      throw const ValidationException(
        'newGame playerName must not be blank',
      );
    }
    final characterIds = manifest.characters.map((entry) => entry.id).toSet();
    final avatarIds = <String>{};
    for (final rawAvatarId in config.playerAvatarCharacterIds) {
      final avatarId = rawAvatarId.trim();
      if (avatarId.isEmpty || !avatarIds.add(avatarId)) {
        throw ValidationException(
          'newGame playerAvatarCharacterIds contains an empty or duplicate id: '
          '$rawAvatarId',
        );
      }
      if (!characterIds.contains(avatarId)) {
        throw ValidationException(
          'newGame playerAvatarCharacterIds references an unknown character: '
          '$avatarId',
        );
      }
    }
    if (config.startingMoney < 0) {
      throw const ValidationException(
        'newGame startingMoney must be non-negative',
      );
    }
    if (config.initialParty.length > 6) {
      throw const ValidationException(
        'newGame initialParty must contain at most 6 Pokemon',
      );
    }

    try {
      for (final entry in config.initialBag) {
        entry.normalized();
      }
      for (final member in config.initialParty) {
        member.normalized();
      }
    } on StateError catch (error) {
      throw ValidationException('Invalid newGame initial state: $error');
    }

    final factsById = {for (final fact in manifest.facts) fact.id: fact};
    final factIds = factsById.keys.toSet();
    for (final entry in config.resolvedInitialFactValues.entries) {
      final factId = entry.key;
      final normalizedFactId = factId.trim();
      if (normalizedFactId.isEmpty || !factIds.contains(normalizedFactId)) {
        throw ValidationException(
          'newGame initialFacts references an unknown Fact: $factId',
        );
      }
      if (factsById[normalizedFactId]!.valueKind != entry.value.kind) {
        throw ValidationException(
          'newGame initial Fact type does not match $factId',
        );
      }
    }
    final existingPartyFactId = config.existingPartyFactId?.trim();
    if (existingPartyFactId != null && existingPartyFactId.isNotEmpty) {
      final existingPartyFact = factsById[existingPartyFactId];
      if (existingPartyFact == null) {
        throw ValidationException(
          'newGame existingPartyFactId references an unknown Fact: '
          '$existingPartyFactId',
        );
      }
      if (existingPartyFact.valueKind != NarrativeValueKind.boolean) {
        throw ValidationException(
          'newGame existingPartyFactId must reference a bool Fact: '
          '$existingPartyFactId',
        );
      }
    }
    final starterSceneId = config.starterSelectionSceneId?.trim();
    if (starterSceneId != null &&
        starterSceneId.isNotEmpty &&
        !manifest.scenes.any((scene) => scene.id == starterSceneId)) {
      throw ValidationException(
        'newGame starterSelectionSceneId references an unknown Scene: '
        '$starterSceneId',
      );
    }

    final starterIds = <String>{};
    for (final option in config.starterOptions) {
      final optionId = option.id.trim();
      if (optionId.isEmpty || !starterIds.add(optionId)) {
        throw ValidationException(
          'newGame starterOptions contains an empty or duplicate id: '
          '${option.id}',
        );
      }
      if (option.label.trim().isEmpty) {
        throw ValidationException(
          'newGame starter option $optionId has an empty label',
        );
      }
      try {
        option.pokemon.normalized();
      } on StateError catch (error) {
        throw ValidationException(
          'Invalid newGame starter option $optionId: $error',
        );
      }
    }
  }

  static void _validateUniqueness(ProjectManifest manifest) {
    _validateUniqueIds(
      manifest.narrativeDiagnosticSuppressions,
      (suppression) => suppression.diagnosticId,
      duplicateMessagePrefix: 'Duplicate narrative diagnostic suppression',
    );
    _validateUniqueIds(
      manifest.maps,
      (map) => map.id,
      duplicateMessagePrefix: 'Duplicate map ID',
    );
    _validateUniqueIds(
      manifest.groups,
      (group) => group.id,
      duplicateMessagePrefix: 'Duplicate group ID',
    );
    _validateUniqueIds(
      manifest.tilesets,
      (tileset) => tileset.id,
      duplicateMessagePrefix: 'Duplicate tileset ID',
    );
    _validateUniqueIds(
      manifest.tilesetFolders,
      (folder) => folder.id,
      duplicateMessagePrefix: 'Duplicate tileset folder ID',
    );
    _validateUniqueIds(
      manifest.elementCategories,
      (category) => category.id,
      duplicateMessagePrefix: 'Duplicate element category ID',
    );
    _validateUniqueIds(
      manifest.elements,
      (element) => element.id,
      duplicateMessagePrefix: 'Duplicate element ID',
    );
    _validateUniqueIds(
      manifest.encounterTables,
      (table) => table.id,
      duplicateMessagePrefix: 'Duplicate encounter table ID',
    );
    _validateUniqueIds(
      manifest.dialogueFolders,
      (f) => f.id,
      duplicateMessagePrefix: 'Duplicate dialogue folder ID',
    );
    _validateUniqueIds(
      manifest.dialogues,
      (d) => d.id,
      duplicateMessagePrefix: 'Duplicate dialogue ID',
    );
    _validateUniqueIds(
      manifest.scenarios,
      (s) => s.id,
      duplicateMessagePrefix: 'Duplicate scenario ID',
    );
    _validateUniqueIds(
      manifest.trainers,
      (t) => t.id,
      duplicateMessagePrefix: 'Duplicate trainer ID',
    );
    _validateUniqueIds(
      manifest.characters,
      (c) => c.id,
      duplicateMessagePrefix: 'Duplicate character ID',
    );
    final factResolver = NarrativeFactRuntimeResolver.fromFacts(manifest.facts);
    if (!factResolver.isValid) {
      throw ValidationException(
        'Invalid Fact runtime catalog: '
        '${factResolver.issues.map((issue) => issue.message).join(' ')}',
      );
    }
  }

  static void _validateProjectDialogues(ProjectManifest manifest) {
    final dialogueFolderIds = manifest.dialogueFolders.map((f) => f.id).toSet();
    final dialogueRelativePaths = <String>{};
    for (final d in manifest.dialogues) {
      final id = d.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Dialogue entry has an empty id');
      }
      if (d.name.trim().isEmpty) {
        throw ValidationException('Dialogue $id has an empty name');
      }
      assertValidProjectDialogueRelativePath(d.relativePath, dialogueId: id);
      final rpNorm = d.relativePath.replaceAll(r'\', '/');
      if (!dialogueRelativePaths.add(rpNorm)) {
        throw ValidationException(
          'Duplicate dialogue relativePath in manifest: $rpNorm',
        );
      }
      assertValidDialogueStartNode(
        d.defaultStartNode,
        contextLabel: 'Dialogue $id defaultStartNode',
      );
      final outcomeIds = <String>{};
      for (final outcome in d.declaredOutcomes) {
        final outcomeId = outcome.id.trim();
        if (outcomeId.isEmpty) {
          throw ValidationException(
            'Dialogue $id has a declared outcome with an empty id',
          );
        }
        if (outcomeId == 'completed') {
          throw ValidationException(
            'Dialogue $id declared outcome "completed" is reserved for the '
            'Scene fallback port',
          );
        }
        if (outcome.label.trim().isEmpty) {
          throw ValidationException(
            'Dialogue $id outcome $outcomeId has an empty label',
          );
        }
        if (!outcomeIds.add(outcomeId)) {
          throw ValidationException(
            'Dialogue $id has duplicate declared outcome: $outcomeId',
          );
        }
      }
      final df = d.folderId?.trim();
      if (df != null && df.isNotEmpty && !dialogueFolderIds.contains(df)) {
        throw ValidationException(
          'Dialogue $id references unknown dialogue folder: $df',
        );
      }
    }
  }

  static void _validateHierarchy(ProjectManifest manifest) {
    final groupIds = manifest.groups.map((g) => g.id).toSet();

    for (final group in manifest.groups) {
      if (group.parentGroupId != null &&
          !groupIds.contains(group.parentGroupId)) {
        throw ValidationException(
          'Group ${group.id} references non-existent parent: ${group.parentGroupId}',
        );
      }
      if (group.parentGroupId == group.id) {
        throw ValidationException('Group ${group.id} cannot be its own parent');
      }

      var current = group;
      final visited = {group.id};
      while (current.parentGroupId != null) {
        if (!groupIds.contains(current.parentGroupId)) {
          break;
        }
        if (!visited.add(current.parentGroupId!)) {
          throw ValidationException(
            'Cycle detected in group hierarchy at ${group.id}',
          );
        }
        current = manifest.groups
            .firstWhere((candidate) => candidate.id == current.parentGroupId);
      }
    }

    for (final map in manifest.maps) {
      if (map.groupId != null && !groupIds.contains(map.groupId)) {
        throw ValidationException(
          'Map ${map.id} references non-existent group: ${map.groupId}',
        );
      }
      _validateRelativePath(map.relativePath, 'Map ${map.id}');
    }

    _validateTilesetFolders(manifest);
    _validateDialogueFolders(manifest);
    _validateTilesets(manifest, groupIds);
    _validateElementCategories(manifest);
    _validateElements(manifest, groupIds);
    _validateScenarios(manifest);
  }

  static void _validateTilesetFolders(ProjectManifest manifest) {
    final folderById = <String, ProjectTilesetFolder>{};
    for (final folder in manifest.tilesetFolders) {
      if (folder.id.trim().isEmpty) {
        throw const ValidationException('Tileset folder ID cannot be empty');
      }
      if (folder.name.trim().isEmpty) {
        throw ValidationException(
          'Tileset folder "${folder.id}" has an empty name',
        );
      }
      folderById[folder.id] = folder;
    }

    for (final folder in manifest.tilesetFolders) {
      final parentId = folder.parentFolderId;
      if (parentId == null) continue;
      if (!folderById.containsKey(parentId)) {
        throw ValidationException(
          'Tileset folder ${folder.id} references missing parent: $parentId',
        );
      }
      if (parentId == folder.id) {
        throw ValidationException(
          'Tileset folder ${folder.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final chain = <String>{};
      while (cursor != null) {
        if (!chain.add(cursor)) {
          throw ValidationException(
            'Cycle detected in tileset folder hierarchy at ${folder.id}',
          );
        }
        cursor = folderById[cursor]?.parentFolderId;
      }
    }

    final folderIds = folderById.keys.toSet();
    for (final tileset in manifest.tilesets) {
      final fid = tileset.folderId?.trim();
      if (fid == null || fid.isEmpty) continue;
      if (!folderIds.contains(fid)) {
        throw ValidationException(
          'Tileset ${tileset.id} references unknown tileset folder: $fid',
        );
      }
    }
  }

  static void _validateDialogueFolders(ProjectManifest manifest) {
    final folderById = <String, ProjectDialogueFolder>{};
    for (final folder in manifest.dialogueFolders) {
      if (folder.id.trim().isEmpty) {
        throw const ValidationException('Dialogue folder ID cannot be empty');
      }
      if (folder.name.trim().isEmpty) {
        throw ValidationException(
          'Dialogue folder "${folder.id}" has an empty name',
        );
      }
      folderById[folder.id] = folder;
    }

    for (final folder in manifest.dialogueFolders) {
      final parentId = folder.parentFolderId;
      if (parentId == null) continue;
      if (!folderById.containsKey(parentId)) {
        throw ValidationException(
          'Dialogue folder ${folder.id} references missing parent: $parentId',
        );
      }
      if (parentId == folder.id) {
        throw ValidationException(
          'Dialogue folder ${folder.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final chain = <String>{};
      while (cursor != null) {
        if (!chain.add(cursor)) {
          throw ValidationException(
            'Cycle detected in dialogue folder hierarchy at ${folder.id}',
          );
        }
        cursor = folderById[cursor]?.parentFolderId;
      }
    }
  }

  static void _validateTilesets(
      ProjectManifest manifest, Set<String> groupIds) {
    var worldTilesetCount = 0;
    final tilesetElementGroupIdsByTileset = <String, Set<String>>{};
    final allTilesetIds = manifest.tilesets.map((t) => t.id).toSet();

    for (final tileset in manifest.tilesets) {
      _validateRelativePath(tileset.relativePath, 'Tileset ${tileset.id}');
      _validateTilesetSource(tileset);

      if (tileset.scope == TilesetScope.global) {
        if (tileset.groupId != null) {
          throw ValidationException(
            'Global tileset ${tileset.id} cannot have groupId',
          );
        }
      } else {
        final groupId = tileset.groupId;
        if (groupId == null || !groupIds.contains(groupId)) {
          throw ValidationException(
            'Group-scoped tileset ${tileset.id} must reference an existing group',
          );
        }
      }

      if (tileset.isWorldTileset) {
        worldTilesetCount++;
        if (tileset.scope != TilesetScope.global) {
          throw ValidationException(
              'World tileset ${tileset.id} must be global');
        }
      }

      final elementGroupById = <String, TilesetElementGroup>{};
      for (final group in tileset.elementGroups) {
        if (group.id.trim().isEmpty) {
          throw ValidationException(
            'Tileset ${tileset.id} has an internal group with empty ID',
          );
        }
        if (group.name.trim().isEmpty) {
          throw ValidationException(
            'Tileset ${tileset.id} internal group ${group.id} has an empty name',
          );
        }
        if (elementGroupById.containsKey(group.id)) {
          throw ValidationException(
            'Duplicate internal group ID in tileset ${tileset.id}: ${group.id}',
          );
        }
        elementGroupById[group.id] = group;
      }

      for (final group in tileset.elementGroups) {
        final parentId = group.parentGroupId;
        if (parentId == null) continue;
        if (!elementGroupById.containsKey(parentId)) {
          throw ValidationException(
            'Tileset ${tileset.id} internal group ${group.id} references missing parent: $parentId',
          );
        }
        if (parentId == group.id) {
          throw ValidationException(
            'Tileset ${tileset.id} internal group ${group.id} cannot be its own parent',
          );
        }
        String? cursor = parentId;
        final visited = <String>{group.id};
        while (cursor != null) {
          if (!visited.add(cursor)) {
            throw ValidationException(
              'Cycle detected in tileset ${tileset.id} internal groups at ${group.id}',
            );
          }
          cursor = elementGroupById[cursor]?.parentGroupId;
        }
      }

      tilesetElementGroupIdsByTileset[tileset.id] =
          elementGroupById.keys.toSet();

      final paletteIds = <String>{};
      for (final entry in tileset.paletteEntries) {
        if (entry.id.trim().isEmpty) {
          throw ValidationException(
            'Palette entry in tileset ${tileset.id} has an empty ID',
          );
        }
        if (!paletteIds.add(entry.id)) {
          throw ValidationException(
            'Duplicate palette entry ID in tileset ${tileset.id}: ${entry.id}',
          );
        }
        _validateVisualFrames(
          entry.frames,
          context: 'Palette entry ${entry.id} in tileset ${tileset.id}',
          knownTilesetIds: allTilesetIds,
        );
      }
    }

    if (worldTilesetCount > 1) {
      throw const ValidationException('Only one world tileset can be defined');
    }
  }

  static void _validateTilesetSource(ProjectTilesetEntry tileset) {
    final source = tileset.source;
    if (source == null) return;
    if (source is ProjectRegularAtlasTilesetSource) {
      _validateRegularAtlasTilesetSource(tileset, source);
      return;
    }
    if (source is ProjectImageCollectionTilesetSource) {
      _validateImageCollectionTilesetSource(tileset, source);
      return;
    }
    throw ValidationException(
      'Tileset ${tileset.id} has an unsupported canonical source',
    );
  }

  static void _validateRegularAtlasTilesetSource(
    ProjectTilesetEntry tileset,
    ProjectRegularAtlasTilesetSource source,
  ) {
    final stableId = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$');
    if (!stableId.hasMatch(source.assetId) ||
        source.pixelWidth <= 0 ||
        source.pixelHeight <= 0 ||
        source.tileWidth <= 0 ||
        source.tileHeight <= 0 ||
        source.marginX < 0 ||
        source.marginY < 0 ||
        source.spacingX < 0 ||
        source.spacingY < 0 ||
        source.columns <= 0 ||
        source.rows <= 0 ||
        // Complete cells are authoritative. Tiled permits a final raster band
        // smaller than one stride; it is inert and never enters the grid.
        source.marginX * 2 +
                source.columns * source.tileWidth +
                (source.columns - 1) * source.spacingX >
            source.pixelWidth ||
        source.marginY * 2 +
                source.rows * source.tileHeight +
                (source.rows - 1) * source.spacingY >
            source.pixelHeight) {
      throw ValidationException(
        'Tileset ${tileset.id} has an invalid regular atlas source',
      );
    }
    final tileIds = <int>{};
    for (final property in source.tileProperties) {
      if (property.tileId < 0 ||
          property.tileId >= source.tileCount ||
          !tileIds.add(property.tileId)) {
        throw ValidationException(
          'Tileset ${tileset.id} has an invalid regular atlas source '
          'tile property: ${property.tileId}',
        );
      }
    }
    final animationTileIds = <int>{};
    for (final animation in source.tileAnimations) {
      if (animation.tileId < 0 ||
          animation.tileId >= source.tileCount ||
          !animationTileIds.add(animation.tileId) ||
          animation.frames.isEmpty ||
          animation.frames.any(
            (frame) =>
                frame.tileId < 0 ||
                frame.tileId >= source.tileCount ||
                frame.durationMs <= 0,
          )) {
        throw ValidationException(
          'Tileset ${tileset.id} has an invalid regular atlas source '
          'animation for tile ${animation.tileId}',
        );
      }
    }
  }

  static void _validateImageCollectionTilesetSource(
    ProjectTilesetEntry tileset,
    ProjectImageCollectionTilesetSource source,
  ) {
    final stableId = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$');
    final pagesById = <String, ProjectImageCollectionPage>{};
    final assetIds = <String>{};
    if (source.pages.isEmpty) {
      throw ValidationException(
        'Tileset ${tileset.id} has an invalid image collection source: '
        'at least one page is required',
      );
    }
    for (final page in source.pages) {
      if (!stableId.hasMatch(page.id) ||
          !stableId.hasMatch(page.assetId) ||
          page.pixelWidth <= 0 ||
          page.pixelHeight <= 0 ||
          pagesById.containsKey(page.id) ||
          !assetIds.add(page.assetId)) {
        throw ValidationException(
          'Tileset ${tileset.id} has an invalid image collection source '
          'page: ${page.id}',
        );
      }
      pagesById[page.id] = page;
    }

    _validateProjectTilesetProperties(
      tileset,
      source.properties,
      context: 'source',
    );

    final tileIds = <int>{};
    for (final tile in source.tileDefinitions) {
      if (tile.tileId < 0 || !tileIds.add(tile.tileId)) {
        throw ValidationException(
          'Tileset ${tileset.id} has an invalid image collection source '
          'tile ID: ${tile.tileId}',
        );
      }
    }
    if (tileIds.isEmpty) {
      throw ValidationException(
        'Tileset ${tileset.id} has an invalid image collection source: '
        'at least one tile definition is required',
      );
    }

    for (final tile in source.tileDefinitions) {
      final page = pagesById[tile.pageId];
      final rect = tile.sourceRect;
      if (page == null ||
          rect.x < 0 ||
          rect.y < 0 ||
          rect.width <= 0 ||
          rect.height <= 0 ||
          rect.x + rect.width > page.pixelWidth ||
          rect.y + rect.height > page.pixelHeight) {
        throw ValidationException(
          'Tileset ${tileset.id} has an invalid image collection source '
          'rectangle for tile ${tile.tileId}',
        );
      }
      _validateProjectTilesetProperties(
        tileset,
        tile.properties,
        context: 'tile ${tile.tileId}',
      );
      for (final frame in tile.animation) {
        if (frame.durationMs <= 0 || !tileIds.contains(frame.tileId)) {
          throw ValidationException(
            'Tileset ${tileset.id} has an invalid image collection source '
            'animation frame for tile ${tile.tileId}',
          );
        }
      }
      _validateProjectTilesetCollisionObjects(tileset, tile);
    }
  }

  static void _validateProjectTilesetCollisionObjects(
    ProjectTilesetEntry tileset,
    ProjectImageCollectionTileDefinition tile,
  ) {
    final objectIds = <int>{};
    for (final object in tile.collisionObjects) {
      final dimensionsAreValid = switch (object.shape) {
        ProjectTilesetCollisionShape.rectangle ||
        ProjectTilesetCollisionShape.ellipse =>
          object.width > 0 && object.height > 0 && object.points.isEmpty,
        ProjectTilesetCollisionShape.polygon =>
          object.width >= 0 && object.height >= 0 && object.points.length >= 3,
        ProjectTilesetCollisionShape.polyline =>
          object.width >= 0 && object.height >= 0 && object.points.length >= 2,
        ProjectTilesetCollisionShape.point =>
          object.width == 0 && object.height == 0 && object.points.isEmpty,
      };
      if (object.id < 0 ||
          !objectIds.add(object.id) ||
          !object.x.isFinite ||
          !object.y.isFinite ||
          !object.width.isFinite ||
          !object.height.isFinite ||
          !object.rotation.isFinite ||
          !dimensionsAreValid ||
          object.points
              .any((point) => !point.x.isFinite || !point.y.isFinite)) {
        throw ValidationException(
          'Tileset ${tileset.id} has an invalid image collection source '
          'collision object ${object.id} for tile ${tile.tileId}',
        );
      }
      _validateProjectTilesetProperties(
        tileset,
        object.properties,
        context: 'collision object ${object.id} of tile ${tile.tileId}',
      );
    }
  }

  static void _validateProjectTilesetProperties(
    ProjectTilesetEntry tileset,
    List<ProjectTilesetProperty> properties, {
    required String context,
  }) {
    final names = <String>{};
    for (final property in properties) {
      final value = property.value;
      final valueIsValid = switch (property.type) {
        ProjectTilesetPropertyType.string => value is String,
        ProjectTilesetPropertyType.integer => value is int,
        ProjectTilesetPropertyType.decimal => value is num && value.isFinite,
        ProjectTilesetPropertyType.boolean => value is bool,
        ProjectTilesetPropertyType.color => value is String &&
            RegExp(r'^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(value),
        ProjectTilesetPropertyType.assetReference =>
          value is String && value.trim().isNotEmpty,
        ProjectTilesetPropertyType.objectReference => value is int,
        ProjectTilesetPropertyType.structured => value is Map &&
            property.customType != null &&
            property.customType!.trim().isNotEmpty &&
            _isJsonCompatible(value),
      };
      if (property.name.trim().isEmpty ||
          !names.add(property.name) ||
          !valueIsValid) {
        throw ValidationException(
          'Tileset ${tileset.id} has an invalid image collection source '
          'property ${property.name} on $context',
        );
      }
    }
  }

  static bool _isJsonCompatible(Object? value) {
    if (value == null || value is String || value is bool || value is int) {
      return true;
    }
    if (value is double) return value.isFinite;
    if (value is List) return value.every(_isJsonCompatible);
    if (value is Map) {
      return value.keys.every((key) => key is String) &&
          value.values.every(_isJsonCompatible);
    }
    return false;
  }

  static void _validateElementCategories(ProjectManifest manifest) {
    final categoryById = <String, ProjectElementCategory>{};
    for (final category in manifest.elementCategories) {
      if (category.id.trim().isEmpty) {
        throw const ValidationException('Element category ID cannot be empty');
      }
      if (category.name.trim().isEmpty) {
        throw ValidationException(
          'Element category ${category.id} has an empty name',
        );
      }
      categoryById[category.id] = category;
    }

    for (final category in manifest.elementCategories) {
      final parentId = category.parentCategoryId;
      if (parentId == null) continue;
      if (!categoryById.containsKey(parentId)) {
        throw ValidationException(
          'Element category ${category.id} references missing parent: $parentId',
        );
      }
      if (parentId == category.id) {
        throw ValidationException(
          'Element category ${category.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final visited = <String>{category.id};
      while (cursor != null) {
        if (!visited.add(cursor)) {
          throw ValidationException(
            'Cycle detected in element categories at ${category.id}',
          );
        }
        cursor = categoryById[cursor]?.parentCategoryId;
      }
    }
  }

  static void _validateElements(
      ProjectManifest manifest, Set<String> groupIds) {
    final tilesetIds = manifest.tilesets.map((t) => t.id).toSet();
    final tilesetElementGroupIdsByTileset = <String, Set<String>>{
      for (final tileset in manifest.tilesets)
        tileset.id: tileset.elementGroups.map((group) => group.id).toSet(),
    };
    final categoryIds = manifest.elementCategories.map((e) => e.id).toSet();

    for (final element in manifest.elements) {
      if (element.id.trim().isEmpty) {
        throw const ValidationException('Element ID cannot be empty');
      }
      if (element.name.trim().isEmpty) {
        throw ValidationException('Element ${element.id} has an empty name');
      }
      if (!tilesetIds.contains(element.tilesetId)) {
        throw ValidationException(
          'Element ${element.id} references missing tileset: ${element.tilesetId}',
        );
      }
      if (!categoryIds.contains(element.categoryId)) {
        throw ValidationException(
          'Element ${element.id} references missing category: ${element.categoryId}',
        );
      }
      if (element.groupId != null && !groupIds.contains(element.groupId)) {
        throw ValidationException(
          'Element ${element.id} references missing group: ${element.groupId}',
        );
      }
      if (element.tilesetGroupId != null &&
          element.tilesetGroupId!.trim().isEmpty) {
        throw ValidationException(
          'Element ${element.id} has an empty tilesetGroupId',
        );
      }
      if (element.tilesetGroupId != null) {
        final tilesetGroups =
            tilesetElementGroupIdsByTileset[element.tilesetId] ?? const {};
        if (!tilesetGroups.contains(element.tilesetGroupId)) {
          throw ValidationException(
            'Element ${element.id} references missing tileset group ${element.tilesetGroupId} in tileset ${element.tilesetId}',
          );
        }
      }
      _validateVisualFrames(
        element.frames,
        context: 'Element ${element.id}',
        knownTilesetIds: tilesetIds,
      );
      _validateElementCollisionProfile(element);
    }
  }

  static void _validateElementCollisionProfile(ProjectElementEntry element) {
    final profile = element.collisionProfile;
    if (profile == null) {
      return;
    }
    final padding = profile.padding;
    if (padding.top < 0 ||
        padding.right < 0 ||
        padding.bottom < 0 ||
        padding.left < 0) {
      throw ValidationException(
        'Element ${element.id} collision profile contains negative padding values',
      );
    }
    final source = element.frames.primarySource;
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.shapeCells,
      label: 'shape',
    );
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.cells,
      label: 'final',
    );
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.manualAddedCells,
      label: 'manualAdded',
    );
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.manualRemovedCells,
      label: 'manualRemoved',
    );
  }

  static void _validateCollisionCellsList({
    required String elementId,
    required TilesetSourceRect source,
    required List<GridPos> cells,
    required String label,
  }) {
    final seen = <String>{};
    for (final cell in cells) {
      if (cell.x < 0 || cell.y < 0) {
        throw ValidationException(
          'Element $elementId collision profile contains negative $label cell coordinates',
        );
      }
      if (cell.x >= source.width || cell.y >= source.height) {
        throw ValidationException(
          'Element $elementId $label collision cell (${cell.x}, ${cell.y}) is outside source bounds ${source.width}x${source.height}',
        );
      }
      final key = '${cell.x}:${cell.y}';
      if (!seen.add(key)) {
        throw ValidationException(
          'Element $elementId collision profile contains duplicate $label cell ($key)',
        );
      }
    }
  }

  static void _validateScenarios(ProjectManifest manifest) {
    final knownScriptIds = manifest.scripts.map((script) => script.id).toSet();
    final knownDialogueIds =
        manifest.dialogues.map((dialogue) => dialogue.id).toSet();
    final knownMapIds = manifest.maps.map((map) => map.id).toSet();
    final knownTrainerIds =
        manifest.trainers.map((trainer) => trainer.id).toSet();

    for (final scenario in manifest.scenarios) {
      final scenarioId = _requireProjectNonBlank(
        scenario.id,
        'Scenario ID cannot be empty',
      );
      _requireProjectNonBlank(
          scenario.name, 'Scenario $scenarioId has an empty name');

      // Outcomes déclarés: non vides et sans doublons.
      final declaredOutcomeIds = <String>{};
      for (final rawOutcomeId in scenario.declaredOutcomes) {
        final outcomeId = _requireProjectNonBlank(
          rawOutcomeId,
          'Scenario $scenarioId has an empty declared outcome',
        );
        if (!declaredOutcomeIds.add(outcomeId)) {
          throw ValidationException(
            'Scenario $scenarioId has duplicate declared outcome: $outcomeId',
          );
        }
      }

      // Condition d'activation scénario (gating global/local).
      if (scenario.activationCondition != null) {
        _validateScriptCondition(
          scenario.activationCondition!,
          contextLabel: 'Scenario $scenarioId activationCondition',
        );
      }

      if (scenario.nodes.isEmpty) {
        throw ValidationException('Scenario $scenarioId must contain nodes');
      }
      final nodeIds = <String>{};
      var startNodesCount = 0;
      for (final node in scenario.nodes) {
        final nodeId = _requireProjectNonBlank(
          node.id,
          'Scenario $scenarioId has a node with empty id',
        );
        if (!nodeIds.add(nodeId)) {
          throw ValidationException(
            'Scenario $scenarioId has duplicate node id: $nodeId',
          );
        }
        if (node.type == ScenarioNodeType.start) {
          startNodesCount++;
        }

        final actionKind = node.payload.actionKind?.trim() ?? '';
        final outcomeId = node.binding.outcomeId?.trim() ?? '';

        if (actionKind == _scenarioEmitOutcomeKind ||
            actionKind == _scenarioOutcomeSourceKind) {
          if (outcomeId.isEmpty) {
            throw ValidationException(
              'Scenario $scenarioId node $nodeId kind "$actionKind" requires outcomeId',
            );
          }
        }
        if (scenario.scope == ScenarioScope.globalStory &&
            _scenarioWorldSourceKinds.contains(actionKind)) {
          throw ValidationException(
            'Scenario $scenarioId is globalStory and cannot use world source kind: $actionKind',
          );
        }
        if (scenario.scope == ScenarioScope.localEventFlow &&
            actionKind == _scenarioOutcomeSourceKind) {
          throw ValidationException(
            'Scenario $scenarioId is localEventFlow and cannot use sourceOutcome',
          );
        }

        final binding = node.binding;
        final scriptId = binding.scriptId?.trim();
        if (scriptId != null &&
            scriptId.isNotEmpty &&
            !knownScriptIds.contains(scriptId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown script: $scriptId',
          );
        }
        final dialogueId = binding.dialogueId?.trim();
        if (dialogueId != null &&
            dialogueId.isNotEmpty &&
            !knownDialogueIds.contains(dialogueId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown dialogue: $dialogueId',
          );
        }
        final mapId = binding.mapId?.trim();
        if (mapId != null && mapId.isNotEmpty && !knownMapIds.contains(mapId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown map: $mapId',
          );
        }
        final trainerId = binding.trainerId?.trim();
        if (trainerId != null &&
            trainerId.isNotEmpty &&
            !knownTrainerIds.contains(trainerId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown trainer: $trainerId',
          );
        }
        final eventId = binding.eventId?.trim();
        if (eventId != null &&
            eventId.isNotEmpty &&
            (mapId == null || mapId.isEmpty)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId cannot define eventId without mapId',
          );
        }
        final condition = node.payload.condition;
        if (condition != null) {
          _validateScriptCondition(
            condition,
            contextLabel: 'Scenario $scenarioId node $nodeId condition',
          );
        }
      }
      if (startNodesCount != 1) {
        throw ValidationException(
          'Scenario $scenarioId must contain exactly one start node',
        );
      }
      final entryNodeId = _requireProjectNonBlank(
        scenario.entryNodeId,
        'Scenario $scenarioId has an empty entryNodeId',
      );
      if (!nodeIds.contains(entryNodeId)) {
        throw ValidationException(
          'Scenario $scenarioId entryNodeId references missing node: $entryNodeId',
        );
      }

      final edgeIds = <String>{};
      final outgoingByNode = <String, int>{};
      for (final edge in scenario.edges) {
        final edgeId = _requireProjectNonBlank(
          edge.id,
          'Scenario $scenarioId has an edge with empty id',
        );
        if (!edgeIds.add(edgeId)) {
          throw ValidationException(
            'Scenario $scenarioId has duplicate edge id: $edgeId',
          );
        }
        final fromNodeId = _requireProjectNonBlank(
          edge.fromNodeId,
          'Scenario $scenarioId edge $edgeId has empty fromNodeId',
        );
        final toNodeId = _requireProjectNonBlank(
          edge.toNodeId,
          'Scenario $scenarioId edge $edgeId has empty toNodeId',
        );
        if (!nodeIds.contains(fromNodeId)) {
          throw ValidationException(
            'Scenario $scenarioId edge $edgeId references missing fromNodeId: $fromNodeId',
          );
        }
        if (!nodeIds.contains(toNodeId)) {
          throw ValidationException(
            'Scenario $scenarioId edge $edgeId references missing toNodeId: $toNodeId',
          );
        }
        if (fromNodeId == toNodeId) {
          throw ValidationException(
            'Scenario $scenarioId edge $edgeId cannot target the same node',
          );
        }
        outgoingByNode[fromNodeId] = (outgoingByNode[fromNodeId] ?? 0) + 1;
      }

      final nodeById = <String, ScenarioNode>{
        for (final node in scenario.nodes) node.id: node,
      };
      for (final entry in nodeById.entries) {
        final node = entry.value;
        final outgoing = outgoingByNode[node.id] ?? 0;
        if (node.type == ScenarioNodeType.choice && outgoing < 2) {
          throw ValidationException(
            'Scenario $scenarioId choice node ${node.id} must have at least two outgoing edges',
          );
        }
        if (node.type == ScenarioNodeType.condition && outgoing < 2) {
          throw ValidationException(
            'Scenario $scenarioId condition node ${node.id} must have at least two outgoing edges',
          );
        }
        if (node.type == ScenarioNodeType.end && outgoing > 0) {
          throw ValidationException(
            'Scenario $scenarioId end node ${node.id} cannot have outgoing edges',
          );
        }
      }
    }
  }

  static void _validateScriptCondition(
    ScriptCondition condition, {
    required String contextLabel,
  }) {
    for (final key in condition.params.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException('$contextLabel has an empty param key');
      }
    }
    switch (condition.type) {
      case ScriptConditionType.allOf:
      case ScriptConditionType.anyOf:
        if (condition.children.isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires at least one child',
          );
        }
        for (var i = 0; i < condition.children.length; i++) {
          _validateScriptCondition(
            condition.children[i],
            contextLabel: '$contextLabel.children[$i]',
          );
        }
        return;
      case ScriptConditionType.not:
        if (condition.children.length != 1) {
          throw ValidationException(
            '$contextLabel not requires exactly one child',
          );
        }
        _validateScriptCondition(
          condition.children.first,
          contextLabel: '$contextLabel.children[0]',
        );
        return;
      case ScriptConditionType.flagIsSet:
      case ScriptConditionType.flagIsUnset:
        final flagName = condition.params[ScriptConditionParams.flagName];
        if (flagName == null || flagName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty flagName',
          );
        }
        return;
      case ScriptConditionType.factEquals:
        _validateFactEqualsCondition(condition, contextLabel);
        return;
      case ScriptConditionType.stepCompleted:
        _requireScriptConditionReference(
          condition,
          ScriptConditionParams.stepId,
          contextLabel,
        );
        return;
      case ScriptConditionType.badgeOwned:
        _requireScriptConditionReference(
          condition,
          ScriptConditionParams.badgeId,
          contextLabel,
        );
        return;
      case ScriptConditionType.itemQuantityAtLeast:
        _requireScriptConditionReference(
          condition,
          ScriptConditionParams.itemId,
          contextLabel,
        );
        _requireNonNegativeScriptConditionInteger(
          condition,
          ScriptConditionParams.quantity,
          contextLabel,
        );
        return;
      case ScriptConditionType.moneyAtLeast:
        _requireNonNegativeScriptConditionInteger(
          condition,
          ScriptConditionParams.amount,
          contextLabel,
        );
        return;
      case ScriptConditionType.eventIsConsumed:
        final eventId = condition.params[ScriptConditionParams.eventId];
        if (eventId == null || eventId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel eventIsConsumed requires a non-empty eventId',
          );
        }
        return;
      case ScriptConditionType.playerOnMap:
        final mapId = condition.params[ScriptConditionParams.mapId];
        if (mapId == null || mapId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel playerOnMap requires a non-empty mapId',
          );
        }
        return;
      case ScriptConditionType.variableEquals:
      case ScriptConditionType.variableGreaterThan:
      case ScriptConditionType.variableLessThan:
        final variableName =
            condition.params[ScriptConditionParams.variableName];
        final value = condition.params[ScriptConditionParams.value];
        if (variableName == null || variableName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty variableName',
          );
        }
        if (value == null || value.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty value',
          );
        }
        return;
      case ScriptConditionType.fieldAbilityUnlocked:
        final ability = condition.params[ScriptConditionParams.ability];
        if (ability == null || ability.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel fieldAbilityUnlocked requires a non-empty ability',
          );
        }
        return;
      case ScriptConditionType.partyHasMove:
      case ScriptConditionType.partyHasUsableMove:
        final moveId = condition.params[ScriptConditionParams.moveId];
        if (moveId == null || moveId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty moveId',
          );
        }
        return;
    }
  }

  static String _requireProjectNonBlank(String value, String message) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ValidationException(message);
    }
    return trimmed;
  }

  static void _validateRelativePath(String path, String label) {
    final value = path.trim();
    if (value.isEmpty) {
      throw ValidationException('$label has an empty relativePath');
    }
    if (value.startsWith('/') || value.startsWith('\\')) {
      throw ValidationException('$label relativePath must be relative');
    }
    if (value.contains(':\\') || value.contains(':/')) {
      throw ValidationException('$label relativePath must not be absolute');
    }
    if (value.contains('..')) {
      throw ValidationException('$label relativePath must not escape project');
    }
  }

  static void _validateEncounterTables(List<ProjectEncounterTable> tables) {
    for (final table in tables) {
      final id = table.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Encounter table ID cannot be empty');
      }
      if (table.name.trim().isEmpty) {
        throw ValidationException('Encounter table $id name cannot be empty');
      }
      if (!table.chancePerStep.isFinite) {
        throw ValidationException(
          'Encounter table $id chancePerStep must be finite '
          '(got ${table.chancePerStep})',
          code: 'encounter.chance_not_finite',
          details: <String, Object?>{'tableId': id},
        );
      }
      if (table.chancePerStep < 0) {
        throw ValidationException(
          'Encounter table $id chancePerStep must not be negative '
          '(got ${table.chancePerStep})',
          code: 'encounter.chance_negative',
          details: <String, Object?>{'tableId': id},
        );
      }
      if (table.chancePerStep > 1) {
        throw ValidationException(
          'Encounter table $id chancePerStep must not exceed 1 '
          '(got ${table.chancePerStep})',
          code: 'encounter.chance_above_one',
          details: <String, Object?>{'tableId': id},
        );
      }
      for (var i = 0; i < table.conditions.length; i++) {
        try {
          _validateScriptCondition(
            table.conditions[i],
            contextLabel: 'Encounter table $id conditions[$i]',
          );
        } on ValidationException catch (error) {
          throw ValidationException(
            error.message,
            code: 'encounter.condition_invalid',
            details: <String, Object?>{
              'tableId': id,
              'conditionIndex': i,
              if (error.code != null) 'causeCode': error.code,
            },
          );
        }
      }
      for (var i = 0; i < table.entries.length; i++) {
        final entry = table.entries[i];
        if (entry.speciesId.trim().isEmpty) {
          throw ValidationException(
            'Encounter table $id entry $i has empty speciesId',
            code: 'encounter.species_empty',
            details: <String, Object?>{'tableId': id, 'entryIndex': i},
          );
        }
        if (entry.minLevel <= 0 || entry.maxLevel <= 0) {
          throw ValidationException(
            'Encounter table $id entry $i levels must be positive',
            code: 'encounter.level_non_positive',
            details: <String, Object?>{'tableId': id, 'entryIndex': i},
          );
        }
        if (entry.minLevel > entry.maxLevel) {
          throw ValidationException(
            'Encounter table $id entry $i minLevel (${entry.minLevel}) > maxLevel (${entry.maxLevel})',
            code: 'encounter.level_range_invalid',
            details: <String, Object?>{'tableId': id, 'entryIndex': i},
          );
        }
        if (entry.weight <= 0) {
          throw ValidationException(
            'Encounter table $id entry $i weight must be positive (got ${entry.weight})',
            code: 'encounter.weight_non_positive',
            details: <String, Object?>{'tableId': id, 'entryIndex': i},
          );
        }
      }
    }
  }

  static void _validateTrainers(ProjectManifest manifest) {
    final elementIds = manifest.elements.map((e) => e.id).toSet();
    final characterIds = manifest.characters.map((c) => c.id).toSet();
    final badgeIds = manifest.badges.map((badge) => badge.id).toSet();
    final badgesById = <String, BadgeDefinition>{
      for (final badge in manifest.badges) badge.id: badge,
    };
    final dialogueIds =
        manifest.dialogues.map((dialogue) => dialogue.id).toSet();
    for (final trainer in manifest.trainers) {
      final id = trainer.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Trainer ID cannot be empty');
      }
      if (trainer.name.trim().isEmpty) {
        throw ValidationException('Trainer $id has an empty name');
      }
      if (trainer.trainerClass.trim().isEmpty) {
        throw ValidationException('Trainer $id has an empty trainerClass');
      }
      final battleDifficulty = trainer.battleDifficulty;
      if (battleDifficulty != null &&
          (battleDifficulty < 1 || battleDifficulty > 10)) {
        throw ValidationException(
          'Trainer $id battleDifficulty must stay within 1..10 (got $battleDifficulty)',
        );
      }
      if (trainer.moneyReward < 0) {
        throw ValidationException(
          'Trainer $id moneyReward must be non-negative '
          '(got ${trainer.moneyReward})',
        );
      }
      final rewardItemIds = <String>{};
      for (var i = 0; i < trainer.rewardItemGrants.length; i++) {
        final itemGrant = trainer.rewardItemGrants[i];
        final itemId = itemGrant.itemId.trim();
        if (itemId.isEmpty) {
          throw ValidationException(
            'Trainer $id rewardItemGrants[$i] has empty itemId',
          );
        }
        if (itemGrant.quantity <= 0) {
          throw ValidationException(
            'Trainer $id rewardItemGrants[$i] quantity must be positive '
            '(got ${itemGrant.quantity})',
          );
        }
        if (!rewardItemIds.add(itemId)) {
          throw ValidationException(
            'Trainer $id rewardItemGrants contains duplicate itemId "$itemId"',
          );
        }
      }
      final rewardFlagIds = <String>{};
      for (var i = 0; i < trainer.rewardFlagIds.length; i++) {
        final flagId = trainer.rewardFlagIds[i].trim();
        if (flagId.isEmpty) {
          throw ValidationException(
            'Trainer $id rewardFlagIds[$i] must not be empty',
          );
        }
        if (!rewardFlagIds.add(flagId)) {
          throw ValidationException(
            'Trainer $id rewardFlagIds contains duplicate flag "$flagId"',
          );
        }
      }
      final rewardBadgeId = trainer.rewardBadgeId?.trim();
      if (rewardBadgeId != null) {
        if (rewardBadgeId.isEmpty) {
          throw ValidationException(
            'Trainer $id rewardBadgeId must not be empty when provided',
          );
        }
        if (!badgeIds.contains(rewardBadgeId)) {
          throw ValidationException(
            'Trainer $id rewardBadgeId "$rewardBadgeId" does not exist in '
            'project badges',
          );
        }
      }
      final lifecycleDialogueIds = <String, String?>{
        'preBattleDialogueId': trainer.preBattleDialogueId,
        'victoryDialogueId': trainer.victoryDialogueId,
        'defeatDialogueId': trainer.defeatDialogueId,
      };
      for (final entry in lifecycleDialogueIds.entries) {
        final dialogueId = entry.value?.trim();
        if (dialogueId == null) {
          continue;
        }
        if (dialogueId.isEmpty) {
          throw ValidationException(
            'Trainer $id ${entry.key} must not be empty when provided',
          );
        }
        if (!dialogueIds.contains(dialogueId)) {
          throw ValidationException(
            'Trainer $id ${entry.key} "$dialogueId" does not exist in '
            'project dialogues',
          );
        }
      }
      switch (trainer.templateKind) {
        case ProjectTrainerTemplateKind.gymLeader:
          if (rewardBadgeId == null || rewardBadgeId.isEmpty) {
            throw ValidationException(
              'Trainer $id gym leader template requires rewardBadgeId',
            );
          }
          if (trainer.victoryDialogueId?.trim().isEmpty ?? true) {
            throw ValidationException(
              'Trainer $id gym leader template requires victoryDialogueId',
            );
          }
          final badgeAbility = badgesById[rewardBadgeId]?.fieldAbilityUnlock;
          if (badgeAbility != null &&
              trainer.rewardFieldAbilityUnlock != badgeAbility) {
            throw ValidationException(
              'Trainer $id gym leader field ability must match badge '
              '$rewardBadgeId (${badgeAbility.moveId})',
            );
          }
        case ProjectTrainerTemplateKind.rival:
          if (trainer.preBattleDialogueId?.trim().isEmpty ?? true) {
            throw ValidationException(
              'Trainer $id rival template requires preBattleDialogueId',
            );
          }
          if (trainer.victoryDialogueId?.trim().isEmpty ?? true) {
            throw ValidationException(
              'Trainer $id rival template requires victoryDialogueId',
            );
          }
          if (trainer.rewardFlagIds.isEmpty) {
            throw ValidationException(
              'Trainer $id rival template requires a follow-up reward flag',
            );
          }
        case null:
          break;
      }
      final battleBackgroundRelativePath =
          trainer.battleBackgroundRelativePath?.trim();
      if (battleBackgroundRelativePath != null &&
          battleBackgroundRelativePath.isNotEmpty) {
        _validateRelativePath(
          battleBackgroundRelativePath,
          'Trainer $id battleBackgroundRelativePath',
        );
      }
      final characterId = trainer.characterId?.trim();
      if (characterId != null &&
          characterId.isNotEmpty &&
          !characterIds.contains(characterId)) {
        throw ValidationException(
          'Trainer $id characterId "$characterId" does not exist in project characters',
        );
      }
      final portraitId = trainer.portraitElementId?.trim();
      if (portraitId != null &&
          portraitId.isNotEmpty &&
          !elementIds.contains(portraitId)) {
        throw ValidationException(
          'Trainer $id portraitElementId "$portraitId" does not exist in project elements',
        );
      }
      for (var i = 0; i < trainer.team.length; i++) {
        final pokemon = trainer.team[i];
        if (pokemon.speciesId.trim().isEmpty) {
          throw ValidationException(
            'Trainer $id team[$i] has empty speciesId',
          );
        }
        if (pokemon.level <= 0) {
          throw ValidationException(
            'Trainer $id team[$i] level must be positive (got ${pokemon.level})',
          );
        }
      }
    }
  }

  static void _validateCharacters(ProjectManifest manifest) {
    _validateCharacterStudioCatalog(manifest.characterStudioCatalog);
    final portraitStateIds = manifest.characterStudioCatalog.portraitStates
        .map((definition) => definition.id)
        .toSet();
    final customDefinitionsById = <String, CharacterCustomAnimationDefinition>{
      for (final definition
          in manifest.characterStudioCatalog.customAnimationDefinitions)
        definition.id: definition,
    };
    final knownTilesetIds = manifest.tilesets.map((t) => t.id).toSet();
    for (final char in manifest.characters) {
      final id = char.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Character entry has an empty id');
      }
      if (char.name.trim().isEmpty) {
        throw ValidationException('Character $id has an empty name');
      }
      final tid = char.tilesetId.trim();
      if (tid.isEmpty) {
        throw ValidationException('Character $id has an empty tilesetId');
      }
      if (!knownTilesetIds.contains(tid)) {
        throw ValidationException(
          'Character $id references unknown tileset: $tid',
        );
      }
      if (char.frameWidth <= 0 || char.frameHeight <= 0) {
        throw ValidationException('Character $id has invalid frame dimensions');
      }
      final portraitSlots = <String>{};
      for (var i = 0; i < char.portraits.length; i++) {
        final portrait = char.portraits[i];
        if (!portraitStateIds.contains(portrait.portraitStateId)) {
          throw ValidationException(
            'Character $id portrait[$i] references unknown portrait state: '
            '${portrait.portraitStateId}',
            code: 'character_studio.portrait.state_unknown',
          );
        }
        if (!portraitSlots.add(portrait.portraitStateId)) {
          throw ValidationException(
            'Character $id has duplicate portrait state: '
            '${portrait.portraitStateId}',
            code: 'character_studio.portrait.duplicate_state',
          );
        }
        if (portrait.assetId.trim().isEmpty) {
          throw ValidationException(
            'Character $id portrait[$i] has an empty assetId',
            code: 'character_studio.portrait.asset_invalid',
          );
        }
      }
      final animationSlots = <String>{};
      for (var i = 0; i < char.animations.length; i++) {
        final anim = char.animations[i];
        final slot = '${anim.state.name}:${anim.direction.name}';
        if (!animationSlots.add(slot)) {
          throw ValidationException(
            'Character $id has duplicate animation slot: $slot',
            code: 'character_studio.animation.duplicate_slot',
          );
        }
        final sourceAssetId = anim.sourceAssetId?.trim();
        if (sourceAssetId != null && sourceAssetId.isEmpty) {
          throw ValidationException(
            'Character $id animation[$i] has an empty sourceAssetId',
            code: 'character_studio.animation.source_asset_invalid',
          );
        }
        _validateCharacterAnimationFrames(
          characterId: id,
          animationLabel: 'animation[$i]',
          frames: anim.frames,
        );
      }
      final customAnimationSlots = <String>{};
      for (var i = 0; i < char.customAnimations.length; i++) {
        final animation = char.customAnimations[i];
        final definition = customDefinitionsById[animation.definitionId];
        if (definition == null) {
          throw ValidationException(
            'Character $id customAnimations[$i] references unknown '
            'definition: ${animation.definitionId}',
            code: 'character_studio.custom_animation.definition_unknown',
          );
        }
        if (definition.mode == CharacterCustomAnimationMode.single &&
            animation.direction != null) {
          throw ValidationException(
            'Character $id custom animation ${definition.id} must not have '
            'a direction',
            code: 'character_studio.custom_animation.direction_forbidden',
          );
        }
        if (definition.mode == CharacterCustomAnimationMode.directional &&
            animation.direction == null) {
          throw ValidationException(
            'Character $id custom animation ${definition.id} requires a '
            'direction',
            code: 'character_studio.custom_animation.direction_required',
          );
        }
        if (animation.sourceAssetId.trim().isEmpty) {
          throw ValidationException(
            'Character $id customAnimations[$i] has an empty sourceAssetId',
            code: 'character_studio.custom_animation.source_asset_invalid',
          );
        }
        final slot =
            '${animation.definitionId}:'
            '${animation.direction?.name ?? 'single'}';
        if (!customAnimationSlots.add(slot)) {
          throw ValidationException(
            'Character $id has duplicate custom animation slot: $slot',
            code: 'character_studio.custom_animation.duplicate_slot',
          );
        }
        _validateCharacterAnimationFrames(
          characterId: id,
          animationLabel: 'customAnimations[$i]',
          frames: animation.frames,
        );
      }
    }
    final playerCharId = manifest.settings.defaultPlayerCharacterId?.trim();
    if (playerCharId != null && playerCharId.isNotEmpty) {
      final charIds = manifest.characters.map((c) => c.id).toSet();
      if (!charIds.contains(playerCharId)) {
        throw ValidationException(
          'Settings defaultPlayerCharacterId "$playerCharId" references unknown character',
        );
      }
    }
  }

  static void _validateCharacterStudioCatalog(
    ProjectCharacterStudioCatalog catalog,
  ) {
    final stableId = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$');
    final portraitStateIds = <String>{};
    for (var i = 0; i < catalog.portraitStates.length; i++) {
      final definition = catalog.portraitStates[i];
      if (!stableId.hasMatch(definition.id) ||
          definition.displayName.trim().isEmpty) {
        throw ValidationException(
          'Character Studio portrait state[$i] is invalid',
          code: 'character_studio.portrait_state.invalid',
        );
      }
      if (!portraitStateIds.add(definition.id)) {
        throw ValidationException(
          'Character Studio has duplicate portrait state id: '
          '${definition.id}',
          code: 'character_studio.portrait_state.duplicate_id',
        );
      }
    }
    const reservedAnimationIds = <String>{'base', 'idle', 'walk', 'run'};
    final animationDefinitionIds = <String>{};
    for (var i = 0; i < catalog.customAnimationDefinitions.length; i++) {
      final definition = catalog.customAnimationDefinitions[i];
      if (!stableId.hasMatch(definition.id) ||
          definition.displayName.trim().isEmpty) {
        throw ValidationException(
          'Character Studio custom animation definition[$i] is invalid',
          code: 'character_studio.animation_definition.invalid',
        );
      }
      if (reservedAnimationIds.contains(definition.id)) {
        throw ValidationException(
          'Character Studio custom animation id is reserved: '
          '${definition.id}',
          code: 'character_studio.animation_definition.id_reserved',
        );
      }
      if (!animationDefinitionIds.add(definition.id)) {
        throw ValidationException(
          'Character Studio has duplicate custom animation id: '
          '${definition.id}',
          code: 'character_studio.animation_definition.duplicate_id',
        );
      }
    }
  }

  static void _validateCharacterAnimationFrames({
    required String characterId,
    required String animationLabel,
    required List<CharacterAnimationFrame> frames,
  }) {
    for (var frameIndex = 0; frameIndex < frames.length; frameIndex++) {
      final frame = frames[frameIndex];
      final source = frame.source;
      if (source.x < 0 || source.y < 0) {
        throw ValidationException(
          'Character $characterId $animationLabel frame $frameIndex has '
          'invalid source coordinates',
          code: 'character_studio.animation.frame_source_invalid',
        );
      }
      if (source.width <= 0 || source.height <= 0) {
        throw ValidationException(
          'Character $characterId $animationLabel frame $frameIndex has '
          'invalid source size',
          code: 'character_studio.animation.frame_size_invalid',
        );
      }
      if (frame.durationMs <= 0) {
        throw ValidationException(
          'Character $characterId $animationLabel frame $frameIndex '
          'durationMs must be positive',
          code: 'character_studio.animation.frame_duration_invalid',
        );
      }
    }
  }

  static void _validateSettings(ProjectSettings settings) {
    if (settings.tileWidth <= 0 || settings.tileHeight <= 0) {
      throw const ValidationException('Tile size must be positive');
    }
    if (settings.displayScale <= 0) {
      throw const ValidationException('Display scale must be positive');
    }
    if (settings.defaultMapWidth <= 0 || settings.defaultMapHeight <= 0) {
      throw const ValidationException('Default map size must be positive');
    }
  }
}

void _requireScriptConditionReference(
  ScriptCondition condition,
  String paramName,
  String contextLabel,
) {
  final value = condition.params[paramName];
  if (value == null || value.trim().isEmpty) {
    throw ValidationException(
      '$contextLabel ${condition.type.name} requires a non-empty $paramName',
    );
  }
}

void _requireNonNegativeScriptConditionInteger(
  ScriptCondition condition,
  String paramName,
  String contextLabel,
) {
  final raw = condition.params[paramName];
  final value = raw == null ? null : int.tryParse(raw);
  if (value == null || value < 0 || value.toString() != raw) {
    throw ValidationException(
      '$contextLabel ${condition.type.name} requires a canonical, '
      'non-negative $paramName',
    );
  }
}

void _validateFactEqualsCondition(
  ScriptCondition condition,
  String contextLabel,
) {
  _requireScriptConditionReference(
    condition,
    ScriptConditionParams.factId,
    contextLabel,
  );
  final valueType = condition.params[ScriptConditionParams.valueType];
  final rawValue = condition.params[ScriptConditionParams.value];
  if (valueType == null || valueType.trim().isEmpty) {
    throw ValidationException(
      '$contextLabel factEquals requires a non-empty valueType',
    );
  }
  if (rawValue == null) {
    throw ValidationException('$contextLabel factEquals requires value');
  }

  late final NarrativeValueKind kind;
  try {
    kind = NarrativeValueKind.fromWireName(valueType);
  } on FormatException {
    throw ValidationException(
      '$contextLabel factEquals has unsupported valueType "$valueType"',
    );
  }

  switch (kind) {
    case NarrativeValueKind.boolean:
      if (rawValue != 'true' && rawValue != 'false') {
        throw ValidationException(
          '$contextLabel factEquals requires true or false for bool value',
        );
      }
    case NarrativeValueKind.integer:
      final value = int.tryParse(rawValue);
      if (value == null || value.toString() != rawValue) {
        throw ValidationException(
          '$contextLabel factEquals requires a canonical integer value',
        );
      }
      try {
        NarrativeValue.integer(value);
      } on ArgumentError {
        throw ValidationException(
          '$contextLabel factEquals integer exceeds the supported JSON range',
        );
      }
    case NarrativeValueKind.string:
      break;
  }
}

class MapValidator {
  /// [projectDialogueContext] : si fourni, les [DialogueRef] sans chemin legacy doivent pointer vers [ProjectManifest.dialogues].
  static void validate(
    MapData map, {
    ProjectManifest? projectDialogueContext,
  }) {
    final mapId = _requireNonBlank(map.id, 'Map ID cannot be empty');
    _requireNonBlank(map.name, 'Map name cannot be empty');
    if (map.size.width <= 0 || map.size.height <= 0) {
      throw ValidationException(
        'Map $mapId has invalid size: ${map.size.width}x${map.size.height}',
      );
    }
    if (map.version != ProjectVersion.v6) {
      throw const ValidationException(
        'Smart Tiles-only maps require ProjectVersion.v6',
        code: 'smart_tile_v6_map_required',
      );
    }
    final smartTileTerrainProviderIds = map.layers
        .whereType<SmartTileLayer>()
        .where((layer) => layer.usage == SmartTileUsage.terrain)
        .map((layer) => layer.id)
        .toList(growable: false);
    if (smartTileTerrainProviderIds.length > 1) {
      throw ValidationException(
        'A map can contain only one Smart Tile terrain provider; found: '
        '${smartTileTerrainProviderIds.join(', ')}',
        code: 'smart_tile_terrain_provider_already_exists',
        details: <String, Object?>{
          'layerIds': smartTileTerrainProviderIds,
        },
      );
    }
    final visualStack = map.visualStack;
    if (visualStack != null) {
      if (map.version != ProjectVersion.v6) {
        throw const ValidationException(
          'visualStack requires ProjectVersion.v6',
        );
      }
    }

    final expectedCellCount = map.size.width * map.size.height;
    for (final layer in map.layers) {
      _validateLayer(
        layer,
        expectedCellCount,
        map: map,
        projectContext: projectDialogueContext,
      );
    }

    _validateUniqueIds(
      map.layers,
      (layer) => layer.id,
      duplicateMessagePrefix: 'Duplicate layer ID',
    );

    for (final entity in map.entities) {
      final entityId = _requireNonBlank(entity.id, 'Entity ID cannot be empty');
      _requireNonBlank(entity.kind.name, 'Entity $entityId has invalid kind');
      if (entity.size.width <= 0 || entity.size.height <= 0) {
        throw ValidationException(
          'Entity $entityId has invalid size: (${entity.size.width}x${entity.size.height})',
        );
      }
      _validatePositionInBounds(
        entity.pos,
        map.size,
        errorLabel: 'Entity $entityId origin',
      );
      final entityRight = entity.pos.x + entity.size.width;
      final entityBottom = entity.pos.y + entity.size.height;
      if (entityRight > map.size.width || entityBottom > map.size.height) {
        throw ValidationException(
          'Entity $entityId has an invalid area extending outside map bounds',
        );
      }
      for (final key in entity.properties.keys) {
        if (key.trim().isEmpty) {
          throw ValidationException(
            'Entity $entityId has an empty property key',
          );
        }
      }
      assertValidMapEntityTypedPayloads(entity);
      if (projectDialogueContext != null) {
        assertEntityDialogueRefsAgainstProject(entity, projectDialogueContext);
        assertEntityTrainerRefsAgainstProject(entity, projectDialogueContext);
        assertEntityCharacterRefsAgainstProject(entity, projectDialogueContext);
        assertEntityEditorVisualAgainstProject(entity, projectDialogueContext);
      }
    }
    _validateUniqueIds(
      map.entities,
      (entity) => entity.id,
      duplicateMessagePrefix: 'Duplicate entity ID',
    );

    final layerById = <String, MapLayer>{
      for (final layer in map.layers) layer.id: layer,
    };
    final elementById = projectDialogueContext == null
        ? const <String, ProjectElementEntry>{}
        : {
            for (final element in projectDialogueContext.elements)
              element.id: element,
          };

    for (final instance in map.placedElements) {
      _validatePlacedElement(
        map: map,
        instance: instance,
        layerById: layerById,
        elementById: elementById,
        projectDialogueContext: projectDialogueContext,
      );
    }
    _validateUniqueIds(
      map.placedElements,
      (instance) => instance.id,
      duplicateMessagePrefix: 'Duplicate placed element instance ID',
    );

    final seenConnectionDirections = <MapConnectionDirection>{};
    for (final connection in map.connections) {
      final targetMapId = _requireNonBlank(
        connection.targetMapId,
        'Map connection ${connection.direction.name} has empty targetMapId',
      );
      if (targetMapId == mapId) {
        throw ValidationException(
          'Map connection ${connection.direction.name} cannot target its own map',
        );
      }
      if (!seenConnectionDirections.add(connection.direction)) {
        throw ValidationException(
          'Duplicate map connection direction: ${connection.direction.name}',
        );
      }
    }

    final scriptIds = projectDialogueContext == null
        ? null
        : {
            for (final script in projectDialogueContext.scripts) script.id,
          };
    final sceneIds = projectDialogueContext == null
        ? null
        : {
            for (final scene in projectDialogueContext.scenes) scene.id,
          };
    final layerIds = <String>{for (final layer in map.layers) layer.id};
    for (final event in map.events) {
      _validateMapEvent(
        map,
        event,
        layerIds: layerIds,
        knownScriptIds: scriptIds,
        knownSceneIds: sceneIds,
      );
    }
    _validateUniqueIds(
      map.events,
      (event) => event.id,
      duplicateMessagePrefix: 'Duplicate map event ID',
    );

    for (final warp in map.warps) {
      final warpId = _requireNonBlank(warp.id, 'Warp ID cannot be empty');
      _requireNonBlank(warp.targetMapId, 'Warp $warpId has empty targetMapId');
      _validatePositionInBounds(
        warp.pos,
        map.size,
        errorLabel: 'Warp $warpId',
      );
      if (warp.targetPos.x < 0 || warp.targetPos.y < 0) {
        throw ValidationException(
          'Warp $warpId has invalid target position: (${warp.targetPos.x}, ${warp.targetPos.y})',
        );
      }
      if (warp.triggerPadding.top < 0 ||
          warp.triggerPadding.right < 0 ||
          warp.triggerPadding.bottom < 0 ||
          warp.triggerPadding.left < 0) {
        throw ValidationException(
          'Warp $warpId has invalid negative trigger padding',
        );
      }
      final seenApproach = <EntityFacing>{};
      for (final facing in warp.allowedApproachFacings) {
        if (!seenApproach.add(facing)) {
          throw ValidationException(
            'Warp $warpId has duplicate allowed approach facing: ${facing.name}',
          );
        }
      }
    }
    _validateUniqueIds(
      map.warps,
      (warp) => warp.id,
      duplicateMessagePrefix: 'Duplicate warp ID',
    );

    for (final trigger in map.triggers) {
      final triggerId =
          _requireNonBlank(trigger.id, 'Trigger ID cannot be empty');
      _requireNonBlank(
          trigger.type.name, 'Trigger $triggerId has invalid type');
      for (final key in trigger.properties.keys) {
        if (key.trim().isEmpty) {
          throw ValidationException(
              'Trigger $triggerId has an empty property key');
        }
      }
      _validatePositionInBounds(
        trigger.area.pos,
        map.size,
        errorLabel: 'Trigger $triggerId area origin',
      );
      if (trigger.area.size.width <= 0 || trigger.area.size.height <= 0) {
        throw ValidationException(
          'Trigger $triggerId has invalid area size: (${trigger.area.size.width}x${trigger.area.size.height})',
        );
      }

      final zoneRight = trigger.area.pos.x + trigger.area.size.width;
      final zoneBottom = trigger.area.pos.y + trigger.area.size.height;
      if (zoneRight > map.size.width || zoneBottom > map.size.height) {
        throw ValidationException(
          'Trigger $triggerId has an invalid area extending outside map bounds',
        );
      }
    }
    _validateUniqueIds(
      map.triggers,
      (trigger) => trigger.id,
      duplicateMessagePrefix: 'Duplicate trigger ID',
    );

    final encounterTablesById = projectDialogueContext == null
        ? const <String, ProjectEncounterTable>{}
        : <String, ProjectEncounterTable>{
            for (final table in projectDialogueContext.encounterTables)
              table.id: table,
          };
    for (final zone in map.gameplayZones) {
      final zoneId =
          _requireNonBlank(zone.id, 'Gameplay zone ID cannot be empty');
      final smartTileProvenance = zone.smartTileProvenance;
      if (smartTileProvenance != null) {
        _requireNonBlank(
          smartTileProvenance.smartTileLayerId,
          'Gameplay zone $zoneId Smart Tile layer ID cannot be empty',
        );
        _requireNonBlank(
          smartTileProvenance.smartTilePresetId,
          'Gameplay zone $zoneId Smart Tile preset ID cannot be empty',
        );
        _requireNonBlank(
          smartTileProvenance.materialId,
          'Gameplay zone $zoneId Smart Tile material ID cannot be empty',
        );
        _requireNonBlank(
          smartTileProvenance.behaviorKey,
          'Gameplay zone $zoneId Smart Tile behavior key cannot be empty',
        );
      }
      _requireNonBlank(
          zone.kind.name, 'Gameplay zone $zoneId has invalid kind');
      final encounterBattleBackgroundRelativePath =
          zone.encounter?.battleBackgroundRelativePath?.trim();
      final encounterTableId = zone.encounter?.encounterTableId?.trim();
      if (encounterTableId != null && encounterTableId.isNotEmpty) {
        final table = encounterTablesById[encounterTableId];
        if (projectDialogueContext != null && table == null) {
          throw ValidationException(
            'Gameplay zone $zoneId references unknown encounter table: '
            '$encounterTableId',
            code: 'encounter.table_unknown',
            details: <String, Object?>{
              'zoneId': zoneId,
              'tableId': encounterTableId,
            },
          );
        }
        if (table != null &&
            table.encounterKind != zone.encounter!.encounterKind) {
          throw ValidationException(
            'Gameplay zone $zoneId encounter kind '
            '${zone.encounter!.encounterKind.name} does not match table '
            '$encounterTableId kind ${table.encounterKind.name}',
            code: 'encounter.kind_mismatch',
            details: <String, Object?>{
              'zoneId': zoneId,
              'tableId': encounterTableId,
              'zoneKind': zone.encounter!.encounterKind.name,
              'tableKind': table.encounterKind.name,
            },
          );
        }
      }
      if (encounterBattleBackgroundRelativePath != null &&
          encounterBattleBackgroundRelativePath.isNotEmpty) {
        ProjectValidator._validateRelativePath(
          encounterBattleBackgroundRelativePath,
          'Gameplay zone $zoneId encounter battleBackgroundRelativePath',
        );
      }
      final specialProps = zone.special?.properties;
      if (specialProps != null) {
        for (final key in specialProps.keys) {
          if (key.trim().isEmpty) {
            throw ValidationException(
              'Gameplay zone $zoneId has an empty special property key',
            );
          }
        }
      }
      final movementEffect = zone.movementEffect;
      if (zone.kind == GameplayZoneKind.movementEffect &&
          movementEffect == null) {
        throw ValidationException(
          'Gameplay zone $zoneId requires a movement effect payload',
        );
      }
      if (movementEffect != null && movementEffect.movementCost <= 0) {
        throw ValidationException(
          'Gameplay zone $zoneId movement effect movementCost must be positive',
        );
      }
      _validatePositionInBounds(
        zone.area.pos,
        map.size,
        errorLabel: 'Gameplay zone $zoneId area origin',
      );
      if (zone.area.size.width <= 0 || zone.area.size.height <= 0) {
        throw ValidationException(
          'Gameplay zone $zoneId has invalid area size: '
          '(${zone.area.size.width}x${zone.area.size.height})',
        );
      }
      final zoneRight = zone.area.pos.x + zone.area.size.width;
      final zoneBottom = zone.area.pos.y + zone.area.size.height;
      if (zoneRight > map.size.width || zoneBottom > map.size.height) {
        throw ValidationException(
          'Gameplay zone $zoneId area extends outside map bounds',
        );
      }
    }
    _validateUniqueIds(
      map.gameplayZones,
      (zone) => zone.id,
      duplicateMessagePrefix: 'Duplicate gameplay zone ID',
    );
    final encounterAmbiguities = findEncounterZoneAmbiguities(
      map.gameplayZones,
    );
    if (encounterAmbiguities.isNotEmpty) {
      final ambiguity = encounterAmbiguities.first;
      throw ValidationException(
        'Encounter zones ${ambiguity.zoneIds.join(', ')} overlap with '
        'equal priority ${ambiguity.priority} for '
        '${ambiguity.encounterKind.name}',
        code: 'encounter.zone_ambiguous',
        details: <String, Object?>{
          'zoneIds': ambiguity.zoneIds,
          'priority': ambiguity.priority,
          'encounterKind': ambiguity.encounterKind.name,
        },
      );
    }
    _validateMapMetadata(map);
  }

  static void _validateMapMetadata(MapData map) {
    final md = map.mapMetadata;
    if (md.musicId != null && md.musicId!.trim().isEmpty) {
      throw ValidationException(
        'Map metadata musicId must be null or a non-blank string',
      );
    }
    if (md.defaultSpawnId != null && md.defaultSpawnId!.trim().isEmpty) {
      throw ValidationException(
        'Map metadata defaultSpawnId must be null or a non-blank string',
      );
    }
    final seenTags = <String>{};
    for (final tag in md.tags) {
      final t = tag.trim();
      if (t.isEmpty) {
        throw ValidationException(
          'Map metadata tags must not contain empty or whitespace-only entries',
        );
      }
      if (tag != t) {
        throw ValidationException(
          'Map metadata tags must be stored without leading or trailing whitespace',
        );
      }
      if (!seenTags.add(t)) {
        throw ValidationException(
          'Map metadata tags must be unique (duplicate: "$t")',
        );
      }
    }
    final spawnId = md.defaultSpawnId?.trim();
    if (spawnId != null && spawnId.isNotEmpty) {
      final keys = <String>{};
      final entityIds = <String>{};
      for (final e in map.entities) {
        if (e.kind == MapEntityKind.spawn) {
          entityIds.add(e.id);
          final k = e.spawn?.spawnKey.trim() ?? '';
          if (k.isNotEmpty) keys.add(k);
        }
      }
      if (!keys.contains(spawnId) && !entityIds.contains(spawnId)) {
        throw ValidationException(
          'Map metadata defaultSpawnId "$spawnId" does not match any spawn key or spawn entity id on this map',
        );
      }
    }
  }

  static void _validateMapEvent(
    MapData map,
    MapEventDefinition event, {
    required Set<String> layerIds,
    required Set<String>? knownScriptIds,
    required Set<String>? knownSceneIds,
  }) {
    final eventId = _requireNonBlank(event.id, 'Map event ID cannot be empty');
    final layerId = _requireNonBlank(
      event.position.layerId,
      'Map event $eventId has empty layerId',
    );
    if (!layerIds.contains(layerId)) {
      throw ValidationException(
        'Map event $eventId references unknown layer: $layerId',
      );
    }
    _validatePositionInBounds(
      GridPos(x: event.position.x, y: event.position.y),
      map.size,
      errorLabel: 'Map event $eventId position',
    );
    if (event.pages.isEmpty) {
      throw ValidationException(
        'Map event $eventId must contain at least one page',
      );
    }
    for (final key in event.metadata.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException(
          'Map event $eventId has an empty metadata key',
        );
      }
    }

    final pageNumbers = <int>{};
    for (var pageIndex = 0; pageIndex < event.pages.length; pageIndex++) {
      final page = event.pages[pageIndex];
      if (page.pageNumber < 0) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] has negative pageNumber: ${page.pageNumber}',
        );
      }
      if (!pageNumbers.add(page.pageNumber)) {
        throw ValidationException(
          'Map event $eventId has duplicate pageNumber: ${page.pageNumber}',
        );
      }
      _validateMapEventPage(
        eventId: eventId,
        pageIndex: pageIndex,
        page: page,
        knownScriptIds: knownScriptIds,
        knownSceneIds: knownSceneIds,
      );
    }
  }

  static void _validateMapEventPage({
    required String eventId,
    required int pageIndex,
    required MapEventPage page,
    required Set<String>? knownScriptIds,
    required Set<String>? knownSceneIds,
  }) {
    for (final key in page.metadata.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] has an empty metadata key',
        );
      }
    }
    final script = page.script;
    if (script != null) {
      final scriptId = _requireNonBlank(
        script.scriptId,
        'Map event $eventId page[$pageIndex] has empty scriptId',
      );
      if (knownScriptIds != null && !knownScriptIds.contains(scriptId)) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] references unknown script: $scriptId',
        );
      }
      final startNode = script.startNode?.trim();
      if (startNode != null && startNode.isEmpty) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] startNode must be null or non-empty',
        );
      }
    }
    final sceneTarget = page.sceneTarget;
    if (sceneTarget != null) {
      final sceneId = _requireNonBlank(
        sceneTarget.sceneId,
        'Map event $eventId page[$pageIndex] has empty sceneTarget.sceneId',
      );
      if (knownSceneIds != null && !knownSceneIds.contains(sceneId)) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] references unknown scene: $sceneId',
        );
      }
    }
    final condition = page.condition;
    if (condition != null) {
      _validateScriptCondition(
        condition,
        contextLabel: 'Map event $eventId page[$pageIndex] condition',
      );
    }
  }

  static void _validateScriptCondition(
    ScriptCondition condition, {
    required String contextLabel,
  }) {
    for (final key in condition.params.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException('$contextLabel has an empty param key');
      }
    }
    switch (condition.type) {
      case ScriptConditionType.allOf:
      case ScriptConditionType.anyOf:
        if (condition.children.isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires at least one child',
          );
        }
        for (var i = 0; i < condition.children.length; i++) {
          _validateScriptCondition(
            condition.children[i],
            contextLabel: '$contextLabel.children[$i]',
          );
        }
        return;
      case ScriptConditionType.not:
        if (condition.children.length != 1) {
          throw ValidationException(
            '$contextLabel not requires exactly one child',
          );
        }
        _validateScriptCondition(
          condition.children.first,
          contextLabel: '$contextLabel.children[0]',
        );
        return;
      case ScriptConditionType.flagIsSet:
      case ScriptConditionType.flagIsUnset:
        final flagName = condition.params[ScriptConditionParams.flagName];
        if (flagName == null || flagName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty flagName',
          );
        }
        return;
      case ScriptConditionType.factEquals:
        _validateFactEqualsCondition(condition, contextLabel);
        return;
      case ScriptConditionType.stepCompleted:
        _requireScriptConditionReference(
          condition,
          ScriptConditionParams.stepId,
          contextLabel,
        );
        return;
      case ScriptConditionType.badgeOwned:
        _requireScriptConditionReference(
          condition,
          ScriptConditionParams.badgeId,
          contextLabel,
        );
        return;
      case ScriptConditionType.itemQuantityAtLeast:
        _requireScriptConditionReference(
          condition,
          ScriptConditionParams.itemId,
          contextLabel,
        );
        _requireNonNegativeScriptConditionInteger(
          condition,
          ScriptConditionParams.quantity,
          contextLabel,
        );
        return;
      case ScriptConditionType.moneyAtLeast:
        _requireNonNegativeScriptConditionInteger(
          condition,
          ScriptConditionParams.amount,
          contextLabel,
        );
        return;
      case ScriptConditionType.eventIsConsumed:
        final eventId = condition.params[ScriptConditionParams.eventId];
        if (eventId == null || eventId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel eventIsConsumed requires a non-empty eventId',
          );
        }
        return;
      case ScriptConditionType.playerOnMap:
        final mapId = condition.params[ScriptConditionParams.mapId];
        if (mapId == null || mapId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel playerOnMap requires a non-empty mapId',
          );
        }
        return;
      case ScriptConditionType.variableEquals:
      case ScriptConditionType.variableGreaterThan:
      case ScriptConditionType.variableLessThan:
        final variableName =
            condition.params[ScriptConditionParams.variableName];
        final value = condition.params[ScriptConditionParams.value];
        if (variableName == null || variableName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty variableName',
          );
        }
        if (value == null || value.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty value',
          );
        }
        return;
      case ScriptConditionType.fieldAbilityUnlocked:
        final ability = condition.params[ScriptConditionParams.ability];
        if (ability == null || ability.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel fieldAbilityUnlocked requires a non-empty ability',
          );
        }
        return;
      case ScriptConditionType.partyHasMove:
      case ScriptConditionType.partyHasUsableMove:
        final moveId = condition.params[ScriptConditionParams.moveId];
        if (moveId == null || moveId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty moveId',
          );
        }
        return;
    }
  }

  static void _validateLayer(
    MapLayer layer,
    int expectedCellCount, {
    required MapData map,
    ProjectManifest? projectContext,
  }) {
    final mapWidth = map.size.width;
    final mapHeight = map.size.height;
    final layerById = <String, MapLayer>{
      for (final l in map.layers) l.id: l,
    };

    final layerId = _requireNonBlank(layer.id, 'Layer ID cannot be empty');
    _requireNonBlank(layer.name, 'Layer $layerId name cannot be empty');
    if (layer.opacity < 0.0 || layer.opacity > 1.0) {
      throw ValidationException(
        'Layer $layerId has invalid opacity: ${layer.opacity}',
      );
    }

    layer.map<void>(
      tile: (tileLayer) {
        if (tileLayer.cells.length != expectedCellCount) {
          throw ValidationException(
            'Tile layer $layerId has invalid cell count: expected $expectedCellCount, got ${tileLayer.cells.length}',
          );
        }
        final paletteEntries = <TileLayerPaletteEntry>{};
        for (var i = 0; i < tileLayer.palette.length; i++) {
          final entry = tileLayer.palette[i];
          if (entry.tilesetId.trim().isEmpty ||
              entry.tilesetId != entry.tilesetId.trim() ||
              entry.localTileId < 0 ||
              entry.transform.quarterTurns < 0 ||
              entry.transform.quarterTurns > 3 ||
              !paletteEntries.add(entry)) {
            throw ValidationException(
              'Tile layer $layerId has invalid palette entry at index $i',
            );
          }
          final project = projectContext;
          if (project != null) {
            ProjectTilesetEntry? tileset;
            for (final candidate in project.tilesets) {
              if (candidate.id == entry.tilesetId) {
                tileset = candidate;
                break;
              }
            }
            if (tileset == null ||
                !_tilesetContainsLocalTileId(tileset, entry.localTileId)) {
              throw ValidationException(
                'Tile layer $layerId palette entry $i references an unknown tile',
              );
            }
          }
        }
        for (var i = 0; i < tileLayer.cells.length; i++) {
          final cell = tileLayer.cells[i];
          if (cell < 0 || cell > tileLayer.palette.length) {
            throw ValidationException(
              'Tile layer $layerId has invalid palette cell at index $i: $cell',
            );
          }
        }
      },
      collision: (collisionLayer) {
        if (collisionLayer.collisions.length != expectedCellCount) {
          throw ValidationException(
            'Collision layer $layerId has invalid collision count: expected $expectedCellCount, got ${collisionLayer.collisions.length}',
          );
        }
      },
      smartTile: (smartTileLayer) {
        final rawPresetId = smartTileLayer.presetId;
        final presetId = rawPresetId.trim();
        if (presetId.isEmpty) {
          throw ValidationException(
            'Smart Tile layer $layerId has an empty presetId',
          );
        }
        if (rawPresetId != presetId) {
          throw ValidationException(
            'Smart Tile layer $layerId presetId must be canonical',
            code: 'smart_tile_layer_identifier_not_canonical',
            details: <String, Object?>{
              'layerId': layerId,
              'field': 'presetId',
              'value': rawPresetId,
            },
          );
        }
        final palette = smartTileLayer.materialPalette;
        if (palette.isEmpty || palette.first.isNotEmpty) {
          throw ValidationException(
            'Smart Tile layer $layerId materialPalette must start with the empty material',
          );
        }
        final materialIds = <String>{};
        for (var i = 1; i < palette.length; i++) {
          final rawMaterialId = palette[i];
          final materialId = rawMaterialId.trim();
          if (materialId.isEmpty) {
            throw ValidationException(
              'Smart Tile layer $layerId has an empty material at palette index $i',
            );
          }
          if (rawMaterialId != materialId) {
            throw ValidationException(
              'Smart Tile layer $layerId materialPalette[$i] must be '
              'canonical',
              code: 'smart_tile_layer_identifier_not_canonical',
              details: <String, Object?>{
                'layerId': layerId,
                'field': 'materialPalette',
                'index': i,
                'value': rawMaterialId,
              },
            );
          }
          if (!materialIds.add(materialId)) {
            throw ValidationException(
              'Smart Tile layer $layerId has duplicate material: $materialId',
            );
          }
        }

        void validateLattice(
          String label,
          List<int> values,
          int expectedLength,
        ) {
          if (values.length != expectedLength) {
            throw ValidationException(
              'Smart Tile layer $layerId has invalid $label count: '
              'expected $expectedLength, got ${values.length}',
            );
          }
          for (var i = 0; i < values.length; i++) {
            final materialIndex = values[i];
            if (materialIndex < 0 || materialIndex >= palette.length) {
              throw ValidationException(
                'Smart Tile layer $layerId $label[$i] references invalid '
                'material palette index $materialIndex',
              );
            }
          }
        }

        switch (smartTileLayer.field) {
          case SmartTileCellField(:final semanticCells):
            validateLattice('semanticCells', semanticCells, expectedCellCount);
          case SmartTileCornerField(:final semanticCells, :final corners):
            validateLattice('semanticCells', semanticCells, expectedCellCount);
            validateLattice(
              'corners',
              corners,
              (mapWidth + 1) * (mapHeight + 1),
            );
          case SmartTileEdgeField(
              :final semanticCells,
              :final horizontalEdges,
              :final verticalEdges,
            ):
            validateLattice('semanticCells', semanticCells, expectedCellCount);
            validateLattice(
              'horizontalEdges',
              horizontalEdges,
              mapWidth * (mapHeight + 1),
            );
            validateLattice(
              'verticalEdges',
              verticalEdges,
              (mapWidth + 1) * mapHeight,
            );
          case SmartTileMixedField(
              :final semanticCells,
              :final horizontalEdges,
              :final verticalEdges,
              :final corners,
            ):
            validateLattice('semanticCells', semanticCells, expectedCellCount);
            validateLattice(
              'horizontalEdges',
              horizontalEdges,
              mapWidth * (mapHeight + 1),
            );
            validateLattice(
              'verticalEdges',
              verticalEdges,
              (mapWidth + 1) * mapHeight,
            );
            validateLattice(
              'corners',
              corners,
              (mapWidth + 1) * (mapHeight + 1),
            );
        }
        for (final key in smartTileLayer.properties.keys) {
          if (key.trim().isEmpty) {
            throw ValidationException(
              'Smart Tile layer $layerId has an empty property key',
            );
          }
        }

        final strokeIds = <String>{};
        for (final stroke in smartTileLayer.patternStrokes) {
          final strokeId = stroke.id.trim();
          final patternId = stroke.patternId.trim();
          if (strokeId.isEmpty || strokeId != stroke.id) {
            throw ValidationException(
              'Smart Tile layer $layerId has a non-canonical pattern stroke '
              'id.',
              code: 'smart_tile_pattern_stroke_identifier_not_canonical',
            );
          }
          if (!strokeIds.add(strokeId)) {
            throw ValidationException(
              'Smart Tile layer $layerId has duplicate pattern stroke id: '
              '$strokeId',
              code: 'smart_tile_pattern_stroke_duplicate',
            );
          }
          if (patternId.isEmpty || patternId != stroke.patternId) {
            throw ValidationException(
              'Smart Tile layer $layerId has a non-canonical patternId.',
              code: 'smart_tile_pattern_identifier_not_canonical',
            );
          }
          if (stroke.cells.isEmpty ||
              stroke.cells.length > smartTileMaximumCellsPerGesture) {
            throw ValidationException(
              'Smart Tile pattern stroke $strokeId must contain between 1 '
              'and $smartTileMaximumCellsPerGesture cells.',
              code: 'smart_tile_pattern_stroke_cell_count_invalid',
            );
          }
          final strokeCells = <GridPos>{};
          for (final cell in stroke.cells) {
            if (!strokeCells.add(cell)) {
              throw ValidationException(
                'Smart Tile pattern stroke $strokeId contains duplicate '
                'cell (${cell.x}, ${cell.y}).',
                code: 'smart_tile_pattern_stroke_cell_duplicate',
              );
            }
            if (cell.x < 0 ||
                cell.y < 0 ||
                cell.x >= mapWidth ||
                cell.y >= mapHeight) {
              throw ValidationException(
                'Smart Tile pattern stroke $strokeId contains an out-of-map '
                'cell (${cell.x}, ${cell.y}).',
                code: 'smart_tile_pattern_stroke_cell_out_of_bounds',
              );
            }
          }
        }

        final catalog = projectContext?.smartTileCatalog;
        if (catalog != null) {
          ProjectSmartTilePreset? preset;
          for (final candidate in catalog.presets) {
            if (candidate.id == presetId) {
              preset = candidate;
              break;
            }
          }
          if (preset == null) {
            throw ValidationException(
              'Smart Tile layer $layerId references unknown presetId: $presetId',
            );
          }
          if (preset.usage != smartTileLayer.usage) {
            throw ValidationException(
              'Smart Tile layer $layerId usage ${smartTileLayer.usage.name} '
              'does not match preset $presetId usage ${preset.usage.name}',
            );
          }
          if (!isSmartTileFieldCompatibleWithTopology(
            preset.topology,
            smartTileLayer.field,
          )) {
            throw ValidationException(
              'Smart Tile layer $layerId field is incompatible with preset '
              '$presetId topology ${preset.topology.name}',
              code: 'smart_tile_topology_field_incompatible',
            );
          }
          final patternsById = <String, ProjectSmartTilePattern>{
            for (final pattern in catalog.patterns) pattern.id: pattern,
          };
          for (final stroke in smartTileLayer.patternStrokes) {
            final pattern = patternsById[stroke.patternId];
            if (pattern == null) {
              throw ValidationException(
                'Smart Tile layer $layerId references unknown pattern: '
                '${stroke.patternId}',
                code: 'smart_tile_pattern_missing',
              );
            }
            if (pattern.usage != smartTileLayer.usage) {
              throw ValidationException(
                'Smart Tile layer $layerId usage '
                '${smartTileLayer.usage.name} does not match pattern '
                '${pattern.id} usage ${pattern.usage.name}.',
                code: 'smart_tile_pattern_usage_mismatch',
              );
            }
          }
          final knownMaterialIds =
              catalog.materials.map((material) => material.id).toSet();
          for (final materialId in materialIds) {
            if (!knownMaterialIds.contains(materialId)) {
              throw ValidationException(
                'Smart Tile layer $layerId references unknown material: '
                '$materialId',
              );
            }
            if (!preset.allowedMaterialIds.contains(materialId)) {
              throw ValidationException(
                'Smart Tile layer $layerId material $materialId is not '
                'allowed by preset $presetId',
                code: 'map.smart_tile_material_not_allowed',
                details: {
                  'layerId': layerId,
                  'field': 'materialPalette',
                  'materialId': materialId,
                  'presetId': presetId,
                },
                remediation: [
                  'Run smart_tile.layer.normalize for $layerId.',
                ],
              );
            }
          }
        }
      },
      object: (objectLayer) {
        final objectIds = <String>{};
        for (var index = 0; index < objectLayer.tileObjects.length; index++) {
          final object = objectLayer.tileObjects[index];
          final objectId = object.id.trim();
          final tile = object.tile;
          if (objectId.isEmpty ||
              objectId != object.id ||
              !objectIds.add(objectId)) {
            throw ValidationException(
              'Object layer $layerId has an invalid tile object ID at index $index',
            );
          }
          if (!object.anchorX.isFinite ||
              !object.anchorY.isFinite ||
              !object.width.isFinite ||
              !object.height.isFinite ||
              object.width <= 0 ||
              object.height <= 0 ||
              object.quarterTurns < 0 ||
              object.quarterTurns > 3 ||
              !object.opacity.isFinite ||
              object.opacity < 0 ||
              object.opacity > 1) {
            throw ValidationException(
              'Object layer $layerId has invalid visual geometry for $objectId',
            );
          }
          if (tile.tilesetId.trim().isEmpty ||
              tile.tilesetId != tile.tilesetId.trim() ||
              tile.localTileId < 0 ||
              tile.transform.quarterTurns < 0 ||
              tile.transform.quarterTurns > 3) {
            throw ValidationException(
              'Object layer $layerId has an invalid tile reference for $objectId',
            );
          }
          final project = projectContext;
          if (project != null) {
            ProjectTilesetEntry? tileset;
            for (final candidate in project.tilesets) {
              if (candidate.id == tile.tilesetId) {
                tileset = candidate;
                break;
              }
            }
            if (tileset == null ||
                !_tilesetContainsLocalTileId(tileset, tile.localTileId)) {
              throw ValidationException(
                'Object layer $layerId tile object $objectId references an unknown tile',
              );
            }
          }
        }
      },
      environment: (environmentLayer) {
        for (final key in environmentLayer.properties.keys) {
          if (key.trim().isEmpty) {
            throw ValidationException(
                'Environment layer $layerId has an empty property key');
          }
        }
        final tid = environmentLayer.content.targetTileLayerId;
        if (tid != null) {
          final target = layerById[tid];
          if (target == null) {
            throw ValidationException(
              'Environment layer $layerId references unknown targetTileLayerId: $tid',
            );
          }
          if (target is! TileLayer) {
            throw ValidationException(
              'Environment layer $layerId targetTileLayerId must reference a tile layer: $tid',
            );
          }
          if (tid == layerId) {
            throw ValidationException(
              'Environment layer $layerId cannot target itself as targetTileLayerId',
            );
          }
        }
        // One zone per Environment layer. Two presets on the same TileLayer
        // are two layers, which the stack already supports; a second zone
        // inside one layer would be a second way to say the same thing.
        if (environmentLayer.content.areas.length > 1) {
          throw ValidationException(
            'Environment layer $layerId carries '
            '${environmentLayer.content.areas.length} zones: a layer carries '
            'exactly one. Author a second Environment layer on the same '
            'TileLayer instead.',
          );
        }
        for (final area in environmentLayer.content.areas) {
          if (area.mask.width != mapWidth || area.mask.height != mapHeight) {
            throw ValidationException(
              'Environment layer $layerId area "${area.id}" mask size '
              '(${area.mask.width}x${area.mask.height}) must match map size (${mapWidth}x$mapHeight)',
            );
          }
        }
      },
      border: (borderLayer) {
        for (final key in borderLayer.properties.keys) {
          if (key.trim().isEmpty) {
            throw ValidationException(
              'Border layer $layerId has an empty property key',
            );
          }
        }
      },
    );
  }

  static bool _tilesetContainsLocalTileId(
    ProjectTilesetEntry tileset,
    int localTileId,
  ) {
    final source = tileset.source;
    if (source is ProjectRegularAtlasTilesetSource) {
      return localTileId >= 0 && localTileId < source.tileCount;
    }
    if (source is ProjectImageCollectionTilesetSource) {
      return source.tileDefinitions.any(
        (definition) => definition.tileId == localTileId,
      );
    }
    // A tileset authored before `source` existed declares no extent, so the
    // tile id cannot be disproved. Treating "unverifiable" as "invalid" would
    // fail every tile layer of a pre-existing project and block all painting.
    // Lower bounds stay enforced by the palette entry check itself.
    return true;
  }

  static String _requireNonBlank(String value, String message) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ValidationException(message);
    }
    return trimmed;
  }

  static void _validatePositionInBounds(
    GridPos pos,
    GridSize mapSize, {
    required String errorLabel,
  }) {
    if (pos.x < 0 ||
        pos.y < 0 ||
        pos.x >= mapSize.width ||
        pos.y >= mapSize.height) {
      throw ValidationException(
        '$errorLabel is out of map bounds at (${pos.x}, ${pos.y})',
      );
    }
  }

  static void validatePlacedElement(
    MapData map,
    MapPlacedElement instance, {
    ProjectManifest? projectDialogueContext,
  }) {
    final layerById = <String, MapLayer>{
      for (final layer in map.layers) layer.id: layer,
    };
    final elementById = projectDialogueContext == null
        ? const <String, ProjectElementEntry>{}
        : {
            for (final element in projectDialogueContext.elements)
              element.id: element,
          };
    _validatePlacedElement(
      map: map,
      instance: instance,
      layerById: layerById,
      elementById: elementById,
      projectDialogueContext: projectDialogueContext,
    );
  }

  static void _validatePlacedElement({
    required MapData map,
    required MapPlacedElement instance,
    required Map<String, MapLayer> layerById,
    required Map<String, ProjectElementEntry> elementById,
    required ProjectManifest? projectDialogueContext,
  }) {
    final instanceId = _requireNonBlank(
      instance.id,
      'Placed element instance ID cannot be empty',
    );
    final layerId = _requireNonBlank(
      instance.layerId,
      'Placed element instance $instanceId has empty layerId',
    );
    final elementId = _requireNonBlank(
      instance.elementId,
      'Placed element instance $instanceId has empty elementId',
    );
    final layer = layerById[layerId];
    if (layer == null) {
      throw ValidationException(
        'Placed element instance $instanceId references unknown layer: $layerId',
      );
    }
    if (layer is! TileLayer) {
      throw ValidationException(
        'Placed element instance $instanceId must reference a tile layer: $layerId',
      );
    }
    _validatePositionInBounds(
      instance.pos,
      map.size,
      errorLabel: 'Placed element instance $instanceId origin',
    );
    if (instance.quarterTurns < 0 || instance.quarterTurns > 3) {
      throw ValidationException(
        'Placed element instance $instanceId has invalid quarterTurns: '
        '${instance.quarterTurns}',
      );
    }
    if (instance.opacity < 0 || instance.opacity > 1) {
      throw ValidationException(
        'Placed element instance $instanceId has invalid opacity: ${instance.opacity}',
      );
    }
    for (final key in instance.properties.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException(
          'Placed element instance $instanceId has an empty property key',
        );
      }
    }
    final animation = instance.animation;
    if (animation != null) {
      if (animation.speed <= 0) {
        throw ValidationException(
          'Placed element instance $instanceId has invalid animation speed: ${animation.speed}',
        );
      }
      final startOffsetMs = animation.startOffsetMs;
      if (startOffsetMs != null && startOffsetMs < 0) {
        throw ValidationException(
          'Placed element instance $instanceId has negative animation startOffsetMs: $startOffsetMs',
        );
      }
    }
    for (var behaviorIndex = 0;
        behaviorIndex < instance.behaviors.length;
        behaviorIndex++) {
      final behavior = instance.behaviors[behaviorIndex];
      final behaviorId = behavior.id.trim();
      const maxBehaviorCooldownMs = 600000;
      if (behaviorId.isEmpty) {
        throw ValidationException(
          'Placed element instance $instanceId behavior[$behaviorIndex] has empty id',
        );
      }
      for (var i = behaviorIndex + 1; i < instance.behaviors.length; i++) {
        if (instance.behaviors[i].id.trim() == behaviorId) {
          throw ValidationException(
            'Placed element instance $instanceId has duplicate behavior id "$behaviorId"',
          );
        }
      }
      final trigger = behavior.trigger;
      final triggerScope = behavior.triggerScope;
      switch (triggerScope) {
        case MapPlacedElementTriggerScope.defaultScope:
          break;
        case MapPlacedElementTriggerScope.oncePerEnter:
          if (trigger != MapPlacedElementTriggerType.onEnter) {
            throw ValidationException(
              'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope oncePerEnter requires trigger onEnter',
            );
          }
          break;
        case MapPlacedElementTriggerScope.whileInsideSingleShot:
          if (trigger != MapPlacedElementTriggerType.onEnter &&
              trigger != MapPlacedElementTriggerType.onNear) {
            throw ValidationException(
              'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope whileInsideSingleShot requires trigger onEnter or onNear',
            );
          }
          break;
        case MapPlacedElementTriggerScope.facingOnly:
          if (trigger != MapPlacedElementTriggerType.onAction &&
              trigger != MapPlacedElementTriggerType.onNear) {
            throw ValidationException(
              'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope facingOnly requires trigger onAction or onNear',
            );
          }
          break;
        case MapPlacedElementTriggerScope.nearCardinalOnly:
          if (trigger != MapPlacedElementTriggerType.onNear) {
            throw ValidationException(
              'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope nearCardinalOnly requires trigger onNear',
            );
          }
          break;
      }
      final cooldownMs = behavior.cooldownMs;
      if (cooldownMs != null) {
        if (cooldownMs < 0) {
          throw ValidationException(
            'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] has negative cooldownMs: $cooldownMs',
          );
        }
        if (cooldownMs > maxBehaviorCooldownMs) {
          throw ValidationException(
            'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] has excessive cooldownMs: $cooldownMs (max $maxBehaviorCooldownMs)',
          );
        }
      }
      final effect = behavior.effect;
      final behaviorLabel =
          'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId]';
      switch (effect.type) {
        case MapPlacedElementEffectType.showMessage:
          final message = effect.message?.trim() ?? '';
          if (message.isEmpty) {
            throw ValidationException(
              '$behaviorLabel showMessage requires a non-empty message',
            );
          }
          break;
        case MapPlacedElementEffectType.openDialogue:
          final dialogue = effect.dialogue;
          if (dialogue == null) {
            throw ValidationException(
              '$behaviorLabel openDialogue requires a dialogue reference',
            );
          }
          final dialogueId = dialogue.dialogueId.trim();
          if (dialogueId.isEmpty) {
            throw ValidationException(
              '$behaviorLabel openDialogue requires a non-empty dialogueId',
            );
          }
          final scriptPath = dialogue.scriptPathRelative.trim();
          if (scriptPath.startsWith('/') || scriptPath.startsWith(r'\')) {
            throw ValidationException(
              '$behaviorLabel dialogue scriptPathRelative must be relative',
            );
          }
          if (scriptPath.contains('..')) {
            throw ValidationException(
              '$behaviorLabel dialogue scriptPathRelative must not contain ..',
            );
          }
          assertValidDialogueStartNode(
            dialogue.startNode,
            contextLabel: '$behaviorLabel dialogue',
          );
          if (projectDialogueContext != null && scriptPath.isEmpty) {
            final exists = projectDialogueContext.dialogues
                .any((entry) => entry.id == dialogueId);
            if (!exists) {
              throw ValidationException(
                '$behaviorLabel references unknown dialogue id "$dialogueId"',
              );
            }
          }
          break;
        case MapPlacedElementEffectType.setAnimationEnabled:
          if (effect.animationEnabled == null) {
            throw ValidationException(
              '$behaviorLabel setAnimationEnabled requires animationEnabled',
            );
          }
          break;
        case MapPlacedElementEffectType.playAnimationOnce:
          break;
      }
    }
    if (projectDialogueContext != null) {
      final element = elementById[elementId];
      if (element == null) {
        throw ValidationException(
          'Placed element instance $instanceId references unknown element: $elementId',
        );
      }
      final footprint = resolveMapPlacedElementFootprint(
        instance: instance,
        element: element,
      ).destinationSize;
      final right = instance.pos.x + footprint.width;
      final bottom = instance.pos.y + footprint.height;
      if (right > map.size.width || bottom > map.size.height) {
        throw ValidationException(
          'Placed element instance $instanceId footprint '
          '${footprint.width}x${footprint.height} exceeds map bounds from '
          'origin (${instance.pos.x}, ${instance.pos.y})',
        );
      }
      if (animation != null && animation.enabled && element.frames.isEmpty) {
        throw ValidationException(
          'Placed element instance $instanceId enables animation but source element $elementId has no frames',
        );
      }
    }
  }
}

void _validateUniqueIds<T>(
  List<T> items,
  String Function(T item) idSelector, {
  required String duplicateMessagePrefix,
}) {
  final ids = <String>{};
  for (final item in items) {
    final id = idSelector(item).trim();
    if (id.isEmpty) continue;
    if (!ids.add(id)) {
      throw ValidationException('$duplicateMessagePrefix: $id');
    }
  }
}
