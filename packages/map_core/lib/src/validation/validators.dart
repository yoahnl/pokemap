import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../operations/map_entities.dart';
import 'dialogue_validation.dart';
import 'entity_editor_visual_validation.dart';

class ProjectValidator {
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
    for (final d in manifest.dialogues) {
      final id = d.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Dialogue entry has an empty id');
      }
      if (d.name.trim().isEmpty) {
        throw ValidationException('Dialogue $id has an empty name');
      }
      assertValidProjectDialogueRelativePath(d.relativePath, dialogueId: id);
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
      if (projectDialogueContext != null) {
        final hasElement = projectDialogueContext.elements
            .any((candidate) => candidate.id == elementId);
        if (!hasElement) {
          throw ValidationException(
            'Placed element instance $instanceId references unknown element: $elementId',
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
      },
      object: (_) {},
    );
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
