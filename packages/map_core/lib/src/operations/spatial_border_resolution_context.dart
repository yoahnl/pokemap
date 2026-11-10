import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';
import '../models/smart_tile.dart';
import 'map_visual_composition.dart';
import 'smart_tile_layer_visual_resolver.dart';
import 'smart_tile_sprite_geometry.dart';

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
    this.groundVisualHeightAt,
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
    required this.groundVisualHeightAt,
  });

  factory SpatialBorderResolutionContext.fromMap(
    MapData map, {
    ProjectManifest? manifest,
  }) {
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
      groundVisualHeightAt: scene == null || manifest == null
          ? null
          : _visualGroundSampler(map, manifest),
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
  final double? Function(double x, double z)? groundVisualHeightAt;
  final Map<String, dynamic> Function() fingerprintContext;
  final bool paintsFirstLayerInFront;
  final bool isSpatial;
}

double? Function(double, double) _visualGroundSampler(
  MapData map,
  ProjectManifest manifest,
) {
  final cache = <(int, int), List<SmartTileLayerVisual>>{};
  late final layers = [
    for (final layer in map.layers.whereType<SmartTileLayer>())
      if (layer.isVisible && layer.opacity > 0) layer,
  ];
  late final plans = {
    for (final layer in layers)
      layer.id: buildSmartTileLayerVisualPlan(
        map: map,
        layer: layer,
        catalog: manifest.smartTileCatalog,
        pass: SmartTileVisualPass.background,
        sourceCellWidth: manifest.settings.tileWidth.toDouble(),
        sourceCellHeight: manifest.settings.tileHeight.toDouble(),
      ),
  };
  late final presetIds = layers.map((layer) => layer.presetId).toSet();
  late final patternIds = {
    for (final layer in layers)
      for (final stroke in layer.patternStrokes) stroke.patternId,
  };
  late final hasModelGround =
      [
        for (final preset in manifest.smartTileCatalog.presets)
          if (presetIds.contains(preset.id))
            for (final rule in preset.rules)
              for (final candidate in rule.candidates) ...candidate.parts,
        for (final pattern in manifest.smartTileCatalog.patterns)
          if (patternIds.contains(pattern.id))
            for (final cell in pattern.cells) ...cell.parts,
      ].any(
        (part) =>
            part.channel == SmartTileRenderChannel.ground &&
            part.source is SmartTileModel3dSource,
      );
  return (x, z) {
    if (hasModelGround) return null;
    final cx = x.floor(), cz = z.floor();
    final visuals = cache.putIfAbsent(
      (cx, cz),
      () => [
        for (final layer in layers)
          ...plans[layer.id]!
              .resolveBatch(
                viewportBounds: SmartTileGeometryRect(
                  left: cx.toDouble(),
                  top: cz.toDouble(),
                  width: 1,
                  height: 1,
                ),
              )
              .visuals,
      ],
    );
    double? height;
    for (final visual in visuals) {
      if (visual.channel != SmartTileRenderChannel.ground) continue;
      final bounds = visual.geometry.visualBounds;
      if (x < bounds.left ||
          x >= bounds.right ||
          z < bounds.top ||
          z >= bounds.bottom) {
        continue;
      }
      final clip = visual.spatialClip;
      if (clip != null) {
        if (visual.geometry.transform != const SmartTileSpriteTransform()) {
          return null;
        }
        final u = (x - bounds.left) / bounds.width;
        final v = (z - bounds.top) / bounds.height;
        if (u < clip.left ||
            u >= clip.right ||
            v < clip.top ||
            v >= clip.bottom) {
          continue;
        }
      }
      final h =
          (visual.spatialFollowTerrain
              ? _sceneTerrainHeightAt(map.spatialScene!, x, z)
              : 0) +
          visual.spatialHeightOffset;
      if (height == null || h > height) height = h;
    }
    return height;
  };
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
