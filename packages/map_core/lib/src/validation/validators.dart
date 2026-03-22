import '../models/project_manifest.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../exceptions/map_exceptions.dart';

class ProjectValidator {
  static void validate(ProjectManifest manifest) {
    _validateUniqueness(manifest);
    _validateHierarchy(manifest);
    _validateSettings(manifest.settings);
  }

  static void _validateUniqueness(ProjectManifest manifest) {
    final mapIds = <String>{};
    for (final map in manifest.maps) {
      if (!mapIds.add(map.id))
        throw ValidationException('Duplicate map ID: ${map.id}');
    }

    final groupIds = <String>{};
    for (final group in manifest.groups) {
      if (!groupIds.add(group.id))
        throw ValidationException('Duplicate group ID: ${group.id}');
    }

    final tilesetIds = <String>{};
    for (final tileset in manifest.tilesets) {
      if (!tilesetIds.add(tileset.id)) {
        throw ValidationException('Duplicate tileset ID: ${tileset.id}');
      }
    }

    final categoryIds = <String>{};
    for (final category in manifest.elementCategories) {
      if (!categoryIds.add(category.id)) {
        throw ValidationException(
            'Duplicate element category ID: ${category.id}');
      }
    }

    final elementIds = <String>{};
    for (final element in manifest.elements) {
      if (!elementIds.add(element.id)) {
        throw ValidationException('Duplicate element ID: ${element.id}');
      }
    }
  }

  static void _validateHierarchy(ProjectManifest manifest) {
    final groupIds = manifest.groups.map((g) => g.id).toSet();

    for (final group in manifest.groups) {
      if (group.parentGroupId != null &&
          !groupIds.contains(group.parentGroupId)) {
        throw ValidationException(
            'Group ${group.id} references non-existent parent: ${group.parentGroupId}');
      }
      if (group.parentGroupId == group.id) {
        throw ValidationException('Group ${group.id} cannot be its own parent');
      }

      var current = group;
      final visited = {group.id};
      while (current.parentGroupId != null) {
        if (!groupIds.contains(current.parentGroupId)) break;
        if (!visited.add(current.parentGroupId!)) {
          throw ValidationException(
              'Cycle detected in group hierarchy at ${group.id}');
        }
        current =
            manifest.groups.firstWhere((g) => g.id == current.parentGroupId);
      }
    }

    for (final map in manifest.maps) {
      if (map.groupId != null && !groupIds.contains(map.groupId)) {
        throw ValidationException(
            'Map ${map.id} references non-existent group: ${map.groupId}');
      }
    }

    var worldTilesetCount = 0;
    final tilesetElementGroupIdsByTileset = <String, Set<String>>{};
    for (final tileset in manifest.tilesets) {
      _validateRelativePath(tileset.relativePath, 'Tileset ${tileset.id}');

      if (tileset.scope == TilesetScope.global) {
        if (tileset.groupId != null) {
          throw ValidationException(
              'Global tileset ${tileset.id} cannot have groupId');
        }
      } else {
        final groupId = tileset.groupId;
        if (groupId == null || !groupIds.contains(groupId)) {
          throw ValidationException(
              'Group-scoped tileset ${tileset.id} must reference an existing group');
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
              'Tileset ${tileset.id} has an internal group with empty ID');
        }
        if (group.name.trim().isEmpty) {
          throw ValidationException(
              'Tileset ${tileset.id} internal group ${group.id} has an empty name');
        }
        if (elementGroupById.containsKey(group.id)) {
          throw ValidationException(
              'Duplicate internal group ID in tileset ${tileset.id}: ${group.id}');
        }
        elementGroupById[group.id] = group;
      }

      for (final group in tileset.elementGroups) {
        final parentId = group.parentGroupId;
        if (parentId == null) continue;
        if (!elementGroupById.containsKey(parentId)) {
          throw ValidationException(
              'Tileset ${tileset.id} internal group ${group.id} references missing parent: $parentId');
        }
        if (parentId == group.id) {
          throw ValidationException(
              'Tileset ${tileset.id} internal group ${group.id} cannot be its own parent');
        }
        String? cursor = parentId;
        final visited = <String>{group.id};
        while (cursor != null) {
          if (!visited.add(cursor)) {
            throw ValidationException(
                'Cycle detected in tileset ${tileset.id} internal groups at ${group.id}');
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
              'Palette entry in tileset ${tileset.id} has an empty ID');
        }
        if (!paletteIds.add(entry.id)) {
          throw ValidationException(
              'Duplicate palette entry ID in tileset ${tileset.id}: ${entry.id}');
        }
        if (entry.source.x < 0 || entry.source.y < 0) {
          throw ValidationException(
              'Palette entry ${entry.id} in tileset ${tileset.id} has invalid source coordinates');
        }
        if (entry.source.width <= 0 || entry.source.height <= 0) {
          throw ValidationException(
              'Palette entry ${entry.id} in tileset ${tileset.id} has invalid source size');
        }
      }
    }

    if (worldTilesetCount > 1) {
      throw const ValidationException('Only one world tileset can be defined');
    }

    final categoryById = <String, ProjectElementCategory>{};
    for (final category in manifest.elementCategories) {
      if (category.id.trim().isEmpty) {
        throw const ValidationException('Element category ID cannot be empty');
      }
      if (category.name.trim().isEmpty) {
        throw ValidationException(
            'Element category ${category.id} has an empty name');
      }
      categoryById[category.id] = category;
    }

    for (final category in manifest.elementCategories) {
      final parentId = category.parentCategoryId;
      if (parentId == null) continue;
      if (!categoryById.containsKey(parentId)) {
        throw ValidationException(
            'Element category ${category.id} references missing parent: $parentId');
      }
      if (parentId == category.id) {
        throw ValidationException(
            'Element category ${category.id} cannot be its own parent');
      }
      String? cursor = parentId;
      final visited = <String>{category.id};
      while (cursor != null) {
        if (!visited.add(cursor)) {
          throw ValidationException(
              'Cycle detected in element categories at ${category.id}');
        }
        cursor = categoryById[cursor]?.parentCategoryId;
      }
    }

    final tilesetIds = manifest.tilesets.map((t) => t.id).toSet();
    for (final element in manifest.elements) {
      if (element.id.trim().isEmpty) {
        throw const ValidationException('Element ID cannot be empty');
      }
      if (element.name.trim().isEmpty) {
        throw ValidationException('Element ${element.id} has an empty name');
      }
      if (!tilesetIds.contains(element.tilesetId)) {
        throw ValidationException(
            'Element ${element.id} references missing tileset: ${element.tilesetId}');
      }
      if (!categoryById.containsKey(element.categoryId)) {
        throw ValidationException(
            'Element ${element.id} references missing category: ${element.categoryId}');
      }
      if (element.groupId != null && !groupIds.contains(element.groupId)) {
        throw ValidationException(
            'Element ${element.id} references missing group: ${element.groupId}');
      }
      if (element.tilesetGroupId != null &&
          element.tilesetGroupId!.trim().isEmpty) {
        throw ValidationException(
            'Element ${element.id} has an empty tilesetGroupId');
      }
      if (element.tilesetGroupId != null) {
        final tilesetGroups =
            tilesetElementGroupIdsByTileset[element.tilesetId] ?? const {};
        if (!tilesetGroups.contains(element.tilesetGroupId)) {
          throw ValidationException(
              'Element ${element.id} references missing tileset group ${element.tilesetGroupId} in tileset ${element.tilesetId}');
        }
      }
      if (element.source.x < 0 || element.source.y < 0) {
        throw ValidationException(
            'Element ${element.id} has invalid source coordinates');
      }
      if (element.source.width <= 0 || element.source.height <= 0) {
        throw ValidationException('Element ${element.id} has invalid size');
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

class MapValidator {
  static void validate(MapData map) {
    final mapId = _requireNonBlank(map.id, 'Map ID cannot be empty');
    _requireNonBlank(map.name, 'Map name cannot be empty');
    if (map.size.width <= 0 || map.size.height <= 0) {
      throw ValidationException(
          'Map $mapId has invalid size: ${map.size.width}x${map.size.height}');
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
      _validatePositionInBounds(
        entity.pos,
        map.size,
        errorLabel: 'Entity $entityId',
      );
    }
    _validateUniqueIds(
      map.entities,
      (entity) => entity.id,
      duplicateMessagePrefix: 'Duplicate entity ID',
    );

    for (final warp in map.warps) {
      final warpId = _requireNonBlank(warp.id, 'Warp ID cannot be empty');
      _requireNonBlank(
        warp.targetMapId,
        'Warp $warpId has empty targetMapId',
      );
      _validatePositionInBounds(
        warp.pos,
        map.size,
        errorLabel: 'Warp $warpId',
      );
      if (warp.targetPos.x < 0 || warp.targetPos.y < 0) {
        throw ValidationException(
            'Warp $warpId has invalid target position: (${warp.targetPos.x}, ${warp.targetPos.y})');
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
      _validatePositionInBounds(
        trigger.pos,
        map.size,
        errorLabel: 'Trigger $triggerId',
      );
      _validatePositionInBounds(
        trigger.zone.pos,
        map.size,
        errorLabel: 'Trigger $triggerId zone origin',
      );
      if (trigger.zone.size.width <= 0 || trigger.zone.size.height <= 0) {
        throw ValidationException(
            'Trigger $triggerId has invalid zone size: (${trigger.zone.size.width}x${trigger.zone.size.height})');
      }

      final zoneRight = trigger.zone.pos.x + trigger.zone.size.width;
      final zoneBottom = trigger.zone.pos.y + trigger.zone.size.height;
      if (zoneRight > map.size.width || zoneBottom > map.size.height) {
        throw ValidationException(
            'Trigger $triggerId has an invalid zone extending outside map bounds');
      }
    }
    _validateUniqueIds(
      map.triggers,
      (trigger) => trigger.id,
      duplicateMessagePrefix: 'Duplicate trigger ID',
    );
  }

  static void _validateLayer(MapLayer layer, int expectedCellCount) {
    final layerId = _requireNonBlank(layer.id, 'Layer ID cannot be empty');
    _requireNonBlank(layer.name, 'Layer $layerId name cannot be empty');
    if (layer.opacity < 0.0 || layer.opacity > 1.0) {
      throw ValidationException(
          'Layer $layerId has invalid opacity: ${layer.opacity}');
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
              'Tile layer $layerId has invalid tile count: expected $expectedCellCount, got ${tileLayer.tiles.length}');
        }
        for (var i = 0; i < tileLayer.tiles.length; i++) {
          if (tileLayer.tiles[i] < 0) {
            throw ValidationException(
                'Tile layer $layerId has negative tile ID at index $i: ${tileLayer.tiles[i]}');
          }
        }
      },
      collision: (collisionLayer) {
        if (collisionLayer.collisions.length != expectedCellCount) {
          throw ValidationException(
              'Collision layer $layerId has invalid collision count: expected $expectedCellCount, got ${collisionLayer.collisions.length}');
        }
      },
      terrain: (terrainLayer) {
        if (terrainLayer.terrains.length != expectedCellCount) {
          throw ValidationException(
              'Terrain layer $layerId has invalid terrain count: expected $expectedCellCount, got ${terrainLayer.terrains.length}');
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
          '$errorLabel is out of map bounds at (${pos.x}, ${pos.y})');
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
