import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/enums.dart';
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
    }
  }
}

class MapValidator {
  static void validate(MapData map) {
    if (map.size.width <= 0 || map.size.height <= 0) {
      throw const ValidationException('Map dimensions must be positive');
    }

    for (final layer in map.layers) {
      if (layer.type == LayerType.tile) {
        if (layer.tiles.length != map.size.width * map.size.height) {
          throw ValidationException('Tile layer "${layer.id}" size mismatch with map dimensions');
        }
      } else if (layer.type == LayerType.collision) {
         if (layer.collisions.length != map.size.width * map.size.height) {
          throw ValidationException('Collision layer "${layer.id}" size mismatch with map dimensions');
        }
      }
    }

    for (final entity in map.entities) {
      if (!_isWithinBounds(entity.pos.x, entity.pos.y, map.size.width, map.size.height)) {
        throw ValidationException('Entity "${entity.id}" is out of bounds');
      }
    }
  }

  static bool _isWithinBounds(int x, int y, int width, int height) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }
}
