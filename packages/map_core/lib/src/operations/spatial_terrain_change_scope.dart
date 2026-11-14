import 'dart:math' as math;

import '../models/border_geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_spatial_scene.dart';

typedef SpatialWorldBounds = ({
  double left,
  double top,
  double right,
  double bottom,
});

SpatialWorldBounds? spatialTerrainChangeBounds(
  MapSpatialScene before,
  MapSpatialScene after,
) {
  if (before.width != after.width ||
      before.depth != after.depth ||
      before.levelHeight != after.levelHeight ||
      before.heightLevels.length != after.heightLevels.length) {
    return (
      left: 0,
      top: 0,
      right: math.max(before.width, after.width).toDouble(),
      bottom: math.max(before.depth, after.depth).toDouble(),
    );
  }
  SpatialWorldBounds? bounds;
  void include(double left, double top, double right, double bottom) {
    final current = bounds;
    bounds = current == null
        ? (left: left, top: top, right: right, bottom: bottom)
        : (
            left: math.min(current.left, left),
            top: math.min(current.top, top),
            right: math.max(current.right, right),
            bottom: math.max(current.bottom, bottom),
          );
  }

  if (before.terrainSurfaces != after.terrainSurfaces) {
    final previous = {
      for (final surface in before.terrainSurfaces.surfaces)
        surface.id: surface,
    };
    final next = {
      for (final surface in after.terrainSurfaces.surfaces) surface.id: surface,
    };
    for (final id in {...previous.keys, ...next.keys}) {
      if (previous[id] == next[id]) continue;
      for (final surface in [previous[id], next[id]]) {
        if (surface == null) continue;
        final b = surface.bounds;
        include(b.left, b.top, b.right, b.bottom);
      }
    }
  }
  for (var index = 0; index < after.heightLevels.length; index++) {
    if (before.heightLevels[index] == after.heightLevels[index]) continue;
    final x = (index % after.width).toDouble();
    final z = (index ~/ after.width).toDouble();
    include(x, z, x + 1, z + 1);
  }
  final previousRamps = before.navigation.ramps.toSet();
  final nextRamps = after.navigation.ramps.toSet();
  for (final ramp in {
    ...previousRamps.difference(nextRamps),
    ...nextRamps.difference(previousRamps),
  }) {
    include(ramp.x, ramp.z, ramp.x + ramp.width, ramp.z + ramp.depth);
  }
  return bounds;
}

Set<(String, String)> spatialBorderFeaturesNear(
  Iterable<MapData> maps,
  SpatialWorldBounds bounds, {
  double margin = 2,
}) {
  bool near(double x, double z) =>
      x >= bounds.left - margin &&
      x <= bounds.right + margin &&
      z >= bounds.top - margin &&
      z <= bounds.bottom + margin;
  final features = <(String, String)>{};
  for (final map in maps) {
    final positions = {
      for (final instance in map.spatialScene?.instances ?? const [])
        instance.id: instance.position,
    };
    for (final layer in map.layers.whereType<BorderLayer>()) {
      for (final feature in layer.content.features) {
        final key = (layer.id, feature.id);
        if (features.contains(key)) continue;
        final placed = feature.generatedPlacementIds.any((id) {
          final position = positions[id];
          return position != null && near(position.x, position.z);
        });
        final traced = switch (feature.geometry) {
          BorderStrokeGeometry(:final strokes) => strokes.any(
            (stroke) => stroke.points.any(
              (point) => near(point.x.toDouble(), point.y.toDouble()),
            ),
          ),
          BorderRegionGeometry(:final width, :final cells) => cells.indexed.any(
            (cell) =>
                cell.$2 &&
                near(
                  (cell.$1 % width).toDouble(),
                  (cell.$1 ~/ width).toDouble(),
                ),
          ),
        };
        if (placed || traced) features.add(key);
      }
    }
  }
  return features;
}
