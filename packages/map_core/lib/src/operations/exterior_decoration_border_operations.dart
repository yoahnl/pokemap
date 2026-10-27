import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;
import '../exceptions/map_exceptions.dart';
import '../models/border_feature.dart';
import '../models/border_layer.dart';
import '../models/exterior_decoration_border.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_exterior_decoration.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import 'spatial_border_resolution.dart';
import 'spatial_border_resolution_context.dart';

SpatialBorderResolutionContext createExteriorDecorationBorderContext({
  required MapExteriorDecoration decoration,
  required ExteriorDecorationBorder border,
  required MapData playableMap,
}) {
  decoration.validateForMap(playableMap);
  if (!decoration.outerBounds.containsRect(
    ExteriorDecorationRect(
      x: border.originX,
      z: border.originZ,
      width: border.width,
      depth: border.depth,
    ),
  )) {
    throw const FormatException(
      'Logical Border terrain must remain inside exterior bounds.',
    );
  }
  final samples = <(double, double), Map<String, dynamic>>{};
  double heightAt(double x, double z) {
    final cached = samples[(x, z)];
    if (cached != null) return cached['height'] as double;
    final worldX = border.originX + x, worldZ = border.originZ + z;
    var height = 0.0;
    var source = 'empty';
    if (decoration.playableBounds.contains(worldX, worldZ)) {
      source = 'map:${decoration.mapId}';
      height = playableMap.spatialScene!.worldHeightAt(worldX, worldZ);
    } else {
      for (final sector in decoration.sectors) {
        if (!sector.bounds.contains(worldX, worldZ)) continue;
        source = 'sector:${sector.id}';
        height = sector.scene.worldHeightAt(
          worldX - sector.originX,
          worldZ - sector.originZ,
        );
        break;
      }
    }
    samples[(x, z)] = Map.unmodifiable({
      'x': x,
      'z': z,
      'height': height,
      'source': source,
    });
    return height;
  }

  return SpatialBorderResolutionContext(
    mapId: decoration.mapId,
    size: GridSize(width: border.width, height: border.depth),
    layers: [
      MapLayer.border(
        id: border.layerId,
        name: border.feature.name,
        content: BorderLayerContent(
          formatVersion: 4,
          features: [border.feature],
        ),
      ),
    ],
    instances: border.instances,
    worldHeightAt: heightAt,
    fingerprintContext: () {
      final ordered = samples.values.toList()
        ..sort((a, b) {
          final row = (a['z'] as double).compareTo(b['z'] as double);
          return row != 0
              ? row
              : (a['x'] as double).compareTo(b['x'] as double);
        });
      return {
        'scope': 'exterior-border',
        'mapId': decoration.mapId,
        'borderId': border.id,
        'originX': border.originX,
        'originZ': border.originZ,
        'width': border.width,
        'depth': border.depth,
        'samples': ordered,
      };
    },
  );
}

SpatialBorderResolutionResult resolveExteriorDecorationBorder({
  required ProjectManifest manifest,
  required MapExteriorDecoration decoration,
  required ExteriorDecorationBorder border,
  required MapData playableMap,
}) => resolveSpatialBorderFeatureInContext(
  manifest: manifest,
  context: createExteriorDecorationBorderContext(
    decoration: decoration,
    border: border,
    playableMap: playableMap,
  ),
  layerId: border.layerId,
  featureId: border.id,
);

ExteriorDecorationBorder applyExteriorDecorationBorderResolution(
  ExteriorDecorationBorder border,
  SpatialBorderResolutionResult result,
) {
  final source = result.sourceContext;
  final sourceFeature = source?.layers
      .whereType<BorderLayer>()
      .where((layer) => layer.id == border.layerId)
      .firstOrNull
      ?.content
      .featureById(border.id);
  final sourceFingerprint = source?.fingerprintContext();
  if (!result.result.canApply ||
      result.layerId != border.layerId ||
      result.featureId != border.id ||
      source == null ||
      source.size.width != border.width ||
      source.size.height != border.depth ||
      sourceFeature != border.feature ||
      !const DeepCollectionEquality().equals(
        source.instances,
        border.instances,
      ) ||
      (sourceFingerprint?['scope'] == 'exterior-border' &&
          (sourceFingerprint?['originX'] != border.originX ||
              sourceFingerprint?['originZ'] != border.originZ))) {
    throw const ValidationException(
      'Native Border diagnostics prevent exterior materialization.',
    );
  }
  final feature = border.feature;
  return ExteriorDecorationBorder(
    id: border.id,
    layerId: border.layerId,
    originX: border.originX,
    originZ: border.originZ,
    width: border.width,
    depth: border.depth,
    feature: BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: feature.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      lineSide: feature.lineSide,
      spatialOffsetWorld: feature.spatialOffsetWorld,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: result.result.materialization,
    ),
    instances: result.modelInstances,
  );
}
