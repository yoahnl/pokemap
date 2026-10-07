import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_spatial_scene.dart';
import '../models/spatial_navigation.dart';
import '../models/project_model3d.dart';
import '../models/smart_tile.dart';

final class SpatialCellLevel {
  const SpatialCellLevel({
    required this.x,
    required this.z,
    required this.level,
  });
  final int x, z, level;
}

final class SpatialMapOperations {
  const SpatialMapOperations();

  MapData setLevels(MapData map, List<SpatialCellLevel> cells) {
    final scene = _scene(map);
    final levels = scene.heightLevels.toList();
    for (final cell in cells) {
      if (cell.x < 0 ||
          cell.z < 0 ||
          cell.x >= scene.width ||
          cell.z >= scene.depth ||
          cell.level < 0 ||
          cell.level > 32) {
        throw const FormatException(
          'Spatial cells must be inside the map with levels from 0 to 32.',
        );
      }
      levels[cell.z * scene.width + cell.x] = cell.level;
    }
    return map.copyWith(
      spatialScene: _reanchor(scene, scene.copyWith(heightLevels: levels)),
    );
  }

  MapData upsertInstance(MapData map, SpatialModelInstance instance) {
    final scene = _scene(map);
    final exists = scene.instances.any((value) => value.id == instance.id);
    return map.copyWith(
      spatialScene: scene.copyWith(
        instances: [
          for (final value in scene.instances)
            value.id == instance.id ? instance : value,
          if (!exists) instance,
        ],
      ),
    );
  }

  MapData deleteInstance(MapData map, String instanceId) {
    final scene = _scene(map);
    if (!scene.instances.any((value) => value.id == instanceId)) {
      throw const FormatException('The spatial instance does not exist.');
    }
    return map.copyWith(
      spatialScene: scene.copyWith(
        instances: scene.instances.where((value) => value.id != instanceId),
      ),
    );
  }

  MapData configureCamera(MapData map, SpatialCameraProfile camera) =>
      map.copyWith(spatialScene: _scene(map).copyWith(camera: camera));

  MapData configureNavigation(
    MapData map,
    SpatialNavigationProfile navigation,
  ) {
    final scene = _scene(map);
    return map.copyWith(
      spatialScene: _reanchor(scene, scene.copyWith(navigation: navigation)),
    );
  }

  MapData configureTerrainAppearance(
    MapData map, {
    SmartTileFrameRef? cliffFrame,
  }) =>
      map.copyWith(spatialScene: _scene(map).copyWith(cliffFrame: cliffFrame));

  MapSpatialScene _reanchor(MapSpatialScene before, MapSpatialScene after) =>
      after.copyWith(
        instances: before.instances.map((instance) {
          final position = instance.position;
          return instance.copyWith(
            position: Model3dVector3(
              x: position.x,
              y:
                  position.y +
                  after.worldHeightAt(position.x, position.z) -
                  before.worldHeightAt(position.x, position.z),
              z: position.z,
            ),
          );
        }),
      );

  MapSpatialScene _scene(MapData map) {
    if (map.version != ProjectVersion.v9 || map.spatialScene == null) {
      throw const FormatException('This operation requires a 3D map.');
    }
    validateSpatialMapStructure(map);
    return map.spatialScene!;
  }
}
