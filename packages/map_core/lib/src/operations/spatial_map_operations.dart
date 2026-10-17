import '../models/enums.dart';
import '../exceptions/map_exceptions.dart';
import '../models/map_data.dart';
import '../models/map_spatial_scene.dart';
import '../models/spatial_navigation.dart';
import '../models/spatial_terrain_surface.dart';
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

  MapData upsertTerrainSurfaces(
    MapData map,
    List<SpatialTerrainSurface> surfaces, {
    bool reanchorInstances = true,
  }) {
    final scene = _scene(map);
    _surfaceIds(surfaces.map((surface) => surface.id).toList());
    final replacements = {for (final surface in surfaces) surface.id: surface};
    final existingIds = scene.terrainSurfaces.surfaces
        .map((surface) => surface.id)
        .toSet();
    final after = scene.copyWith(
      terrainSurfaces: SpatialTerrainSurfaceSet(
        surfaces: [
          for (final surface in scene.terrainSurfaces.surfaces)
            replacements[surface.id] ?? surface,
          for (final surface in surfaces)
            if (!existingIds.contains(surface.id)) surface,
        ],
      ),
    );
    return map.copyWith(
      spatialScene: reanchorInstances ? _reanchor(scene, after) : after,
    );
  }

  MapData deleteTerrainSurfaces(
    MapData map,
    List<String> surfaceIds, {
    bool reanchorInstances = true,
  }) {
    final scene = _scene(map);
    _surfaceIds(surfaceIds);
    final ids = surfaceIds.toSet();
    final existing = scene.terrainSurfaces.surfaces
        .map((surface) => surface.id)
        .toSet();
    if (!existing.containsAll(ids)) {
      throw const FormatException(
        'A continuous terrain surface does not exist.',
      );
    }
    final after = scene.copyWith(
      terrainSurfaces: SpatialTerrainSurfaceSet(
        surfaces: scene.terrainSurfaces.surfaces.where(
          (surface) => !ids.contains(surface.id),
        ),
      ),
    );
    return map.copyWith(
      spatialScene: reanchorInstances ? _reanchor(scene, after) : after,
    );
  }

  void _surfaceIds(List<String> ids) {
    if (ids.isEmpty ||
        ids.length > maximumSpatialTerrainSurfaces ||
        ids.toSet().length != ids.length ||
        ids.any((id) => !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id))) {
      throw const FormatException(
        'Terrain batches require 1 to 128 distinct surface identities.',
      );
    }
  }

  MapData setLevels(MapData map, List<SpatialCellLevel> cells) {
    final scene = _scene(map);
    final levels = scene.heightLevels.toList();
    for (final cell in cells) {
      if (cell.x < 0 ||
          cell.z < 0 ||
          cell.x >= scene.width ||
          cell.z >= scene.depth ||
          cell.level < 0 ||
          cell.level > MapSpatialScene.maximumTerrainLevel) {
        throw const FormatException(
          'Spatial cells must be inside the map with levels from 0 to 64.',
        );
      }
      final covered = scene.terrainSurfaces
          .candidatesAtCell(cell.x, cell.z)
          .where((surface) => surface.overlapsCell(cell.x, cell.z))
          .map((surface) => surface.id)
          .toList();
      if (covered.isNotEmpty) {
        throw ValidationException(
          'This cell belongs to a continuous terrain surface. Edit that surface instead of its underlying grid.',
          code: 'spatial.terrain.surface_grid_conflict',
          details: {'surfaceIds': covered, 'x': cell.x, 'z': cell.z},
        );
      }
      levels[cell.z * scene.width + cell.x] = cell.level;
    }
    return map.copyWith(
      spatialScene: _reanchor(scene, scene.copyWith(heightLevels: levels)),
    );
  }

  MapData upsertInstance(MapData map, SpatialModelInstance instance) {
    _requireAuthoredInstance(instance.id);
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
    _requireAuthoredInstance(instanceId);
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
    bool? generateCliffs,
  }) => map.copyWith(
    spatialScene: _scene(
      map,
    ).copyWith(cliffFrame: cliffFrame, generateCliffs: generateCliffs),
  );

  MapSpatialScene _reanchor(MapSpatialScene before, MapSpatialScene after) =>
      after.copyWith(
        instances: before.instances.map((instance) {
          final position = instance.position;
          final heightDelta =
              after.worldHeightAt(position.x, position.z) -
              before.worldHeightAt(position.x, position.z);
          if (heightDelta == 0) return instance;
          return instance.copyWith(
            position: Model3dVector3(
              x: position.x,
              y: position.y + heightDelta,
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

  void _requireAuthoredInstance(String id) {
    if (id.startsWith('smt_')) {
      throw const FormatException(
        'Smart Tile models must be edited through their painted layer.',
      );
    }
  }
}
