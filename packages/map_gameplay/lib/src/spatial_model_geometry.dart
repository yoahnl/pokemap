import 'dart:math' as math;

import 'package:map_core/map_core.dart';

({
  List<({double x, double z})> polygon,
  double minY,
  double maxY,
  double cos,
  double sin,
}) spatialModelWorldGeometry(
    SpatialModelInstance instance, ProjectModel3dEntry model,
    {bool useCollisionBounds = false, SpatialModelRuntimeState? runtimeState}) {
  final scale = model.scale * instance.scale;
  final bounds = useCollisionBounds
      ? model.collisionBounds ?? model.inspection.bounds
      : model.inspection.bounds;
  final angle = instance.rotationDegrees * math.pi / 180;
  final cos = math.cos(angle), sin = math.sin(angle);
  return (
    polygon: [
      for (final corner in [
        (bounds.min.x, bounds.min.z),
        (bounds.max.x, bounds.min.z),
        (bounds.max.x, bounds.max.z),
        (bounds.min.x, bounds.max.z),
      ])
        (
          x: instance.position.x + (runtimeState?.translationX ?? 0) +
              cos * (corner.$1 - model.pivot.x) * scale +
              sin * (corner.$2 - model.pivot.z) * scale,
          z: instance.position.z + (runtimeState?.translationZ ?? 0) -
              sin * (corner.$1 - model.pivot.x) * scale +
              cos * (corner.$2 - model.pivot.z) * scale,
        ),
    ],
    minY: instance.position.y + (runtimeState?.translationY ?? 0) + (bounds.min.y - model.pivot.y) * scale,
    maxY: instance.position.y + (runtimeState?.translationY ?? 0) + (bounds.max.y - model.pivot.y) * scale,
    cos: cos,
    sin: sin,
  );
}
