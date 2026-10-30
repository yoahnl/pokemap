import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_spatial_scene.dart';
import 'map_visual_composition.dart';

final class SpatialBorderResolutionContext {
  SpatialBorderResolutionContext({
    required this.mapId,
    required this.size,
    required Iterable<MapLayer> layers,
    required Iterable<SpatialModelInstance> instances,
    required this.worldHeightAt,
    required this.fingerprintContext,
    this.paintsFirstLayerInFront = true,
    this.groundModeledAt,
  }) : layers = List.unmodifiable(layers),
       instances = List.unmodifiable(instances),
       isSpatial = true {
    if (size.width < 1 ||
        size.height < 1 ||
        size.width > 384 ||
        size.height > 384 ||
        this.instances.length > 10000) {
      throw const FormatException(
        'Spatial Border contexts require bounded visual terrain.',
      );
    }
  }

  SpatialBorderResolutionContext._({
    required this.mapId,
    required this.size,
    required this.layers,
    required this.instances,
    required this.worldHeightAt,
    required this.fingerprintContext,
    required this.paintsFirstLayerInFront,
    required this.isSpatial,
    required this.groundModeledAt,
  });

  factory SpatialBorderResolutionContext.fromMap(MapData map) {
    final scene = map.spatialScene;
    return SpatialBorderResolutionContext._(
      mapId: map.id,
      size: map.size,
      layers: map.layers,
      instances: scene?.instances ?? const [],
      worldHeightAt: (x, z) =>
          scene == null ? 0 : _sceneTerrainHeightAt(scene, x, z),
      groundModeledAt: scene == null
          ? null
          : (x, z) => _sceneGroundModeledAt(scene, x, z),
      paintsFirstLayerInFront: mapPaintsFirstLayerInFront(map),
      isSpatial: map.version == ProjectVersion.v9 && scene != null,
      fingerprintContext: () => {
        'mapId': map.id,
        'mapVersion': map.version.name,
        'mapSize': map.size.toJson(),
        'width': scene?.width,
        'depth': scene?.depth,
        'heightLevels': scene?.heightLevels,
        'levelHeight': scene?.levelHeight,
        'ramps': scene?.navigation.ramps.map((ramp) => ramp.toJson()).toList(),
      },
    );
  }

  final String mapId;
  final GridSize size;
  final List<MapLayer> layers;
  final List<SpatialModelInstance> instances;
  final double Function(double x, double z) worldHeightAt;
  final bool Function(double x, double z)? groundModeledAt;
  final Map<String, dynamic> Function() fingerprintContext;
  final bool paintsFirstLayerInFront;
  final bool isSpatial;
}

double _sceneTerrainHeightAt(MapSpatialScene scene, double x, double z) {
  for (final ramp in scene.navigation.ramps) {
    if (ramp.surfaceInstanceId == null && ramp.contains(x, z)) {
      return ramp.levelAt(x, z) * scene.levelHeight;
    }
  }
  return scene.terrainSurfaces.heightAt(x, z) ??
      scene.heightAt(
        x.floor().clamp(0, scene.width - 1),
        z.floor().clamp(0, scene.depth - 1),
      );
}

bool _sceneGroundModeledAt(MapSpatialScene scene, double x, double z) =>
    scene.terrainSurfaces.surfaces.isEmpty ||
    scene.terrainSurfaces.heightAt(x, z) != null ||
    scene.navigation.ramps.any(
      (ramp) => ramp.surfaceInstanceId == null && ramp.contains(x, z),
    ) ||
    scene.heightAt(
          x.floor().clamp(0, scene.width - 1),
          z.floor().clamp(0, scene.depth - 1),
        ) !=
        0;
