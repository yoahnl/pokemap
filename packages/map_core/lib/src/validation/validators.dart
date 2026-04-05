import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/script_conditions.dart';
import '../operations/map_entities.dart';
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
    _validateUniqueness(manifest);
    _validateHierarchy(manifest);
    _validateEncounterTables(manifest.encounterTables);
    _validateProjectDialogues(manifest);
    _validateTrainers(manifest);
    _validateCharacters(manifest);
    _validateSettings(manifest.settings);
  }

  static void _validateUniqueness(ProjectManifest manifest) {
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
      manifest.terrainCategories,
      (category) => category.id,
      duplicateMessagePrefix: 'Duplicate terrain category ID',
    );
    _validateUniqueIds(
      manifest.pathCategories,
      (category) => category.id,
      duplicateMessagePrefix: 'Duplicate path category ID',
    );
    _validateUniqueIds(
      manifest.terrainPresets,
      (preset) => preset.id,
      duplicateMessagePrefix: 'Duplicate terrain preset ID',
    );
    _validateUniqueIds(
      manifest.pathPresets,
      (preset) => preset.id,
      duplicateMessagePrefix: 'Duplicate path preset ID',
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
    _validatePresetCategories(
      manifest.terrainCategories,
      label: 'terrain category',
    );
    _validatePresetCategories(
      manifest.pathCategories,
      label: 'path category',
    );
    _validateTerrainPresets(manifest);
    _validatePathPresets(manifest);
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
    final seen = <String>{};
    for (final cell in profile.cells) {
      if (cell.x < 0 || cell.y < 0) {
        throw ValidationException(
          'Element ${element.id} collision profile contains negative cell coordinates',
        );
      }
      if (cell.x >= source.width || cell.y >= source.height) {
        throw ValidationException(
          'Element ${element.id} collision cell (${cell.x}, ${cell.y}) is outside source bounds ${source.width}x${source.height}',
        );
      }
      final key = '${cell.x}:${cell.y}';
      if (!seen.add(key)) {
        throw ValidationException(
          'Element ${element.id} collision profile contains duplicate cell ($key)',
        );
      }
    }
  }

  static void _validatePresetCategories(
    List<ProjectPresetCategory> categories, {
    required String label,
  }) {
    final byId = <String, ProjectPresetCategory>{};
    for (final category in categories) {
      if (category.id.trim().isEmpty) {
        throw ValidationException('${_capitalize(label)} ID cannot be empty');
      }
      if (category.name.trim().isEmpty) {
        throw ValidationException(
          '${_capitalize(label)} ${category.id} has an empty name',
        );
      }
      byId[category.id] = category;
    }

    for (final category in categories) {
      final parentId = category.parentCategoryId;
      if (parentId == null) continue;
      if (!byId.containsKey(parentId)) {
        throw ValidationException(
          '${_capitalize(label)} ${category.id} references missing parent: $parentId',
        );
      }
      if (parentId == category.id) {
        throw ValidationException(
          '${_capitalize(label)} ${category.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final visited = <String>{category.id};
      while (cursor != null) {
        if (!visited.add(cursor)) {
          throw ValidationException(
            'Cycle detected in ${label}s at ${category.id}',
          );
        }
        cursor = byId[cursor]?.parentCategoryId;
      }
    }
  }

  static void _validateTerrainPresets(ProjectManifest manifest) {
    final tilesetIds = manifest.tilesets.map((tileset) => tileset.id).toSet();
    final categoryIds =
        manifest.terrainCategories.map((category) => category.id).toSet();

    for (final preset in manifest.terrainPresets) {
      if (preset.id.trim().isEmpty) {
        throw const ValidationException('Terrain preset ID cannot be empty');
      }
      if (preset.name.trim().isEmpty) {
        throw ValidationException(
          'Terrain preset ${preset.id} has an empty name',
        );
      }
      if (preset.terrainType == TerrainType.none) {
        throw ValidationException(
          'Terrain preset ${preset.id} cannot target terrain type "none"',
        );
      }
      final tilesetId = preset.tilesetId.trim();
      if (tilesetId.isNotEmpty && !tilesetIds.contains(tilesetId)) {
        throw ValidationException(
          'Terrain preset ${preset.id} references missing tileset: $tilesetId',
        );
      }
      final categoryId = preset.categoryId?.trim();
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          !categoryIds.contains(categoryId)) {
        throw ValidationException(
          'Terrain preset ${preset.id} references missing terrain category: $categoryId',
        );
      }
      for (var vi = 0; vi < preset.variants.length; vi++) {
        final variant = preset.variants[vi];
        if (variant.weight <= 0) {
          throw ValidationException(
            'Terrain preset ${preset.id} has an invalid variant weight',
          );
        }
        _validateVisualFrames(
          variant.frames,
          context: 'Terrain preset ${preset.id} variant index $vi',
          knownTilesetIds: tilesetIds,
        );
      }
    }
  }

  static void _validatePathPresets(ProjectManifest manifest) {
    final tilesetIds = manifest.tilesets.map((tileset) => tileset.id).toSet();
    final categoryIds =
        manifest.pathCategories.map((category) => category.id).toSet();

    for (final preset in manifest.pathPresets) {
      if (preset.id.trim().isEmpty) {
        throw const ValidationException('Path preset ID cannot be empty');
      }
      if (preset.name.trim().isEmpty) {
        throw ValidationException('Path preset ${preset.id} has an empty name');
      }
      final tilesetId = preset.tilesetId.trim();
      if (tilesetId.isNotEmpty && !tilesetIds.contains(tilesetId)) {
        throw ValidationException(
          'Path preset ${preset.id} references missing tileset: $tilesetId',
        );
      }
      final categoryId = preset.categoryId?.trim();
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          !categoryIds.contains(categoryId)) {
        throw ValidationException(
          'Path preset ${preset.id} references missing path category: $categoryId',
        );
      }
      final variants = <TerrainPathVariant>{};
      for (final mapping in preset.variants) {
        if (!variants.add(mapping.variant)) {
          throw ValidationException(
            'Path preset ${preset.id} has duplicate variant mapping: ${mapping.variant.name}',
          );
        }
        _validateVisualFrames(
          mapping.frames,
          context: 'Path preset ${preset.id} variant ${mapping.variant.name}',
          knownTilesetIds: tilesetIds,
        );
      }
    }

    final terrainTilesetIds = manifest.terrainPresets
        .map((preset) => preset.tilesetId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    for (final preset in manifest.pathPresets) {
      final tilesetId = preset.tilesetId.trim();
      if (tilesetId.isNotEmpty && terrainTilesetIds.contains(tilesetId)) {
        throw ValidationException(
          'Tileset $tilesetId cannot be shared between terrain and path presets',
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
      for (var i = 0; i < table.entries.length; i++) {
        final entry = table.entries[i];
        if (entry.speciesId.trim().isEmpty) {
          throw ValidationException(
            'Encounter table $id entry $i has empty speciesId',
          );
        }
        if (entry.minLevel <= 0 || entry.maxLevel <= 0) {
          throw ValidationException(
            'Encounter table $id entry $i levels must be positive',
          );
        }
        if (entry.minLevel > entry.maxLevel) {
          throw ValidationException(
            'Encounter table $id entry $i minLevel (${entry.minLevel}) > maxLevel (${entry.maxLevel})',
          );
        }
        if (entry.weight <= 0) {
          throw ValidationException(
            'Encounter table $id entry $i weight must be positive (got ${entry.weight})',
          );
        }
      }
    }
  }

  static void _validateTrainers(ProjectManifest manifest) {
    final elementIds = manifest.elements.map((e) => e.id).toSet();
    final characterIds = manifest.characters.map((c) => c.id).toSet();
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
        throw ValidationException(
          'Character $id has invalid frame dimensions',
        );
      }
      for (var i = 0; i < char.animations.length; i++) {
        final anim = char.animations[i];
        for (var j = 0; j < anim.frames.length; j++) {
          final frame = anim.frames[j];
          final src = frame.source;
          if (src.x < 0 || src.y < 0) {
            throw ValidationException(
              'Character $id animation[$i] frame $j has invalid source coordinates',
            );
          }
          if (src.width <= 0 || src.height <= 0) {
            throw ValidationException(
              'Character $id animation[$i] frame $j has invalid source size',
            );
          }
          if (frame.durationMs <= 0) {
            throw ValidationException(
              'Character $id animation[$i] frame $j durationMs must be positive',
            );
          }
        }
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

  static void _validateUniqueIds<T>(
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

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
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

    final expectedCellCount = map.size.width * map.size.height;
    for (final layer in map.layers) {
      _validateLayer(layer, expectedCellCount);
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
        final layerTilesetId = (layer.tilesetId ?? map.tilesetId).trim();
        final elementTilesetId = _resolveElementPrimaryTilesetId(element);
        if (layerTilesetId.isNotEmpty &&
            elementTilesetId.isNotEmpty &&
            layerTilesetId != elementTilesetId) {
          throw ValidationException(
            'Placed element instance $instanceId references element $elementId from tileset $elementTilesetId, but layer $layerId uses tileset $layerTilesetId',
          );
        }
        final source = element.frames.primarySource;
        final width = source.width <= 0 ? 1 : source.width;
        final height = source.height <= 0 ? 1 : source.height;
        final right = instance.pos.x + width;
        final bottom = instance.pos.y + height;
        if (right > map.size.width || bottom > map.size.height) {
          throw ValidationException(
            'Placed element instance $instanceId footprint ${width}x$height exceeds map bounds from origin (${instance.pos.x}, ${instance.pos.y})',
          );
        }
        if (animation != null && animation.enabled && element.frames.isEmpty) {
          throw ValidationException(
            'Placed element instance $instanceId enables animation but source element $elementId has no frames',
          );
        }
      }
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
    final layerIds = <String>{for (final layer in map.layers) layer.id};
    for (final event in map.events) {
      _validateMapEvent(
        map,
        event,
        layerIds: layerIds,
        knownScriptIds: scriptIds,
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

    for (final zone in map.gameplayZones) {
      final zoneId =
          _requireNonBlank(zone.id, 'Gameplay zone ID cannot be empty');
      _requireNonBlank(
          zone.kind.name, 'Gameplay zone $zoneId has invalid kind');
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
      );
    }
  }

  static void _validateMapEventPage({
    required String eventId,
    required int pageIndex,
    required MapEventPage page,
    required Set<String>? knownScriptIds,
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

  static void _validateLayer(MapLayer layer, int expectedCellCount) {
    final layerId = _requireNonBlank(layer.id, 'Layer ID cannot be empty');
    _requireNonBlank(layer.name, 'Layer $layerId name cannot be empty');
    if (layer.opacity < 0.0 || layer.opacity > 1.0) {
      throw ValidationException(
        'Layer $layerId has invalid opacity: ${layer.opacity}',
      );
    }

    layer.map<void>(
      tile: (tileLayer) {
        final layerTilesetId = tileLayer.tilesetId?.trim();
        if (layerTilesetId != null && layerTilesetId.isEmpty) {
          throw ValidationException(
              'Tile layer $layerId has an empty tilesetId');
        }
        if (tileLayer.tiles.length != expectedCellCount) {
          throw ValidationException(
            'Tile layer $layerId has invalid tile count: expected $expectedCellCount, got ${tileLayer.tiles.length}',
          );
        }
        for (var i = 0; i < tileLayer.tiles.length; i++) {
          if (tileLayer.tiles[i] < 0) {
            throw ValidationException(
              'Tile layer $layerId has negative tile ID at index $i: ${tileLayer.tiles[i]}',
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
      terrain: (terrainLayer) {
        if (terrainLayer.terrains.length != expectedCellCount) {
          throw ValidationException(
            'Terrain layer $layerId has invalid terrain count: expected $expectedCellCount, got ${terrainLayer.terrains.length}',
          );
        }
      },
      path: (pathLayer) {
        if (pathLayer.cells.length != expectedCellCount) {
          throw ValidationException(
            'Path layer $layerId has invalid cell count: expected $expectedCellCount, got ${pathLayer.cells.length}',
          );
        }
        for (final key in pathLayer.properties.keys) {
          if (key.trim().isEmpty) {
            throw ValidationException(
                'Path layer $layerId has an empty property key');
          }
        }
        final triggerIds = <String>{};
        for (var i = 0; i < pathLayer.animationTriggers.length; i++) {
          final trigger = pathLayer.animationTriggers[i];
          final resolvedId =
              trigger.id.trim().isEmpty ? 'rule_$i' : trigger.id.trim();
          if (!triggerIds.add(resolvedId)) {
            throw ValidationException(
              'Path layer $layerId has duplicate animation trigger id: $resolvedId',
            );
          }
          if (trigger.mode == PathAnimationPlaybackMode.loopWhileActive &&
              trigger.trigger != PathAnimationTriggerType.whileInside) {
            throw ValidationException(
              'Path layer $layerId trigger[$resolvedId] mode loopWhileActive requires trigger whileInside',
            );
          }
          if (trigger.trigger == PathAnimationTriggerType.whileInside &&
              trigger.mode != PathAnimationPlaybackMode.loopWhileActive) {
            throw ValidationException(
              'Path layer $layerId trigger[$resolvedId] trigger whileInside requires mode loopWhileActive',
            );
          }
        }
      },
      object: (_) {},
    );
  }

  static String _resolveElementPrimaryTilesetId(ProjectElementEntry element) {
    final frameTilesetId = element.frames.primaryFrame.tilesetId.trim();
    if (frameTilesetId.isNotEmpty) {
      return frameTilesetId;
    }
    return element.tilesetId.trim();
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

  static void _validateUniqueIds<T>(
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
}
