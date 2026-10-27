import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

import 'spatial_picking.dart';

final class SpatialSceneAuthoringTarget {
  const SpatialSceneAuthoringTarget({
    required this.map,
    required this.offset,
    this.decorationKey,
  });

  final MapData map;
  final Offset offset;
  final String? decorationKey;
}

SpatialSurfaceHit? pickSpatialAuthoringSurface(
  SpatialSceneAuthoringTarget target,
  Vector3 origin,
  Vector3 direction,
) {
  final scene = target.map.spatialScene;
  if (scene == null) return null;
  return pickSpatialSurface(
    scene,
    origin - Vector3(target.offset.dx, 0, target.offset.dy),
    direction,
  );
}
