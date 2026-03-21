import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/map_layer.dart';
import '../exceptions/map_exceptions.dart';

class ProjectValidator {
  static void validate(ProjectManifest project) {
    if (project.name.isEmpty) {
      throw const ValidationException('Project name cannot be empty');
    }
    
    final mapIds = <String>{};
    for (final map in project.maps) {
      if (!mapIds.add(map.id)) {
        throw ValidationException('Duplicate map ID found: ${map.id}');
      }
      if (map.relativePath.isEmpty) {
        throw ValidationException('Map path cannot be empty for map: ${map.id}');
      }
    }

    final tilesetIds = <String>{};
    for (final ts in project.tilesets) {
      if (!tilesetIds.add(ts.id)) {
        throw ValidationException('Duplicate tileset ID found: ${ts.id}');
      }
      if (ts.relativePath.isEmpty) {
        throw ValidationException('Tileset path cannot be empty for tileset: ${ts.id}');
      }
    }
  }
}

class MapValidator {
  static void validate(MapData map) {
    if (map.size.width <= 0 || map.size.height <= 0) {
      throw const ValidationException('Map dimensions must be positive');
    }
    if (map.tilesetId.isEmpty) {
      throw const ValidationException('Map must have a tilesetId');
    }

    final layerIds = <String>{};
    for (final layer in map.layers) {
      if (!layerIds.add(layer.id)) {
        throw ValidationException('Duplicate layer ID found: ${layer.id}');
      }
      
      _validateLayer(layer, map.size.width * map.size.height);
    }

    final entityIds = <String>{};
    for (final entity in map.entities) {
      if (!entityIds.add(entity.id)) {
        throw ValidationException('Duplicate entity ID found: ${entity.id}');
      }
      if (!_isWithinBounds(entity.pos.x, entity.pos.y, map.size.width, map.size.height)) {
        throw ValidationException('Entity "${entity.id}" is out of bounds');
      }
    }

    final warpIds = <String>{};
    for (final warp in map.warps) {
      if (!warpIds.add(warp.id)) {
        throw ValidationException('Duplicate warp ID found: ${warp.id}');
      }
    }

    final triggerIds = <String>{};
    for (final trigger in map.triggers) {
      if (!triggerIds.add(trigger.id)) {
        throw ValidationException('Duplicate trigger ID found: ${trigger.id}');
      }
      if (!_isWithinBounds(trigger.pos.x, trigger.pos.y, map.size.width, map.size.height)) {
        throw ValidationException('Trigger "${trigger.id}" is out of bounds');
      }
    }
  }

  static void _validateLayer(MapLayer layer, int expectedSize) {
    layer.map(
      tile: (l) {
        if (l.tiles.length != expectedSize) {
          throw ValidationException('Tile layer "${l.id}" size mismatch');
        }
      },
      collision: (l) {
        if (l.collisions.length != expectedSize) {
          throw ValidationException('Collision layer "${l.id}" size mismatch');
        }
      },
      object: (l) {
        // No size constraint on object layer itself
      },
    );
  }

  static bool _isWithinBounds(int x, int y, int width, int height) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }
}
