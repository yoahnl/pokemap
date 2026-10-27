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
  });

  factory SpatialBorderResolutionContext.fromMap(MapData map) {
    final scene = map.spatialScene;
    return SpatialBorderResolutionContext._(
      mapId: map.id,
      size: map.size,
      layers: map.layers,
      instances: scene?.instances ?? const [],
      worldHeightAt: (x, z) => scene?.worldHeightAt(x, z) ?? 0,
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
  final Map<String, dynamic> Function() fingerprintContext;
  final bool paintsFirstLayerInFront;
  final bool isSpatial;
}
