import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';

import 'spatial_lighting_preview.dart';
import 'spatial_shadow_profile.dart';

String spatialShadowInstanceId(String mapId, String instanceId) =>
    '$mapId:$instanceId';

double spatialShadowReceiverMinimumHeight(MapSpatialScene scene) {
  var minimum = scene.heightLevels
      .map((level) => level * scene.levelHeight)
      .reduce(math.min);
  for (final ramp in scene.navigation.ramps) {
    minimum = math.min(minimum, ramp.lowLevel * scene.levelHeight);
  }
  for (final surface in scene.terrainSurfaces.surfaces) {
    for (final footprint in surface.footprints) {
      for (final point in footprint.points) {
        minimum = math.min(
          minimum,
          surface.height +
              surface.gradientX * point.x +
              surface.gradientZ * point.z,
        );
      }
    }
  }
  return minimum;
}

final class SpatialAuthoredShadowCaster {
  SpatialAuthoredShadowCaster({
    required this.id,
    required Model3dBounds bounds,
    required Matrix4 worldTransform,
  }) : worldCorners = List.unmodifiable([
         for (final x in [bounds.min.x, bounds.max.x])
           for (final y in [bounds.min.y, bounds.max.y])
             for (final z in [bounds.min.z, bounds.max.z])
               worldTransform.transform3(Vector3(x, y, z)),
       ]);
  final String id;
  final List<Vector3> worldCorners;
}

SpatialAuthoredShadowCaster? spatialAuthoredShadowCaster({
  required String mapId,
  required SpatialModelInstance instance,
  required ProjectModel3dEntry definition,
  required Model3dBounds bounds,
  required Matrix4 worldTransform,
}) => instance.effectiveCastsShadows(definition)
    ? SpatialAuthoredShadowCaster(
        id: spatialShadowInstanceId(mapId, instance.id),
        bounds: bounds,
        worldTransform: worldTransform,
      )
    : null;

SpatialLightingProfile spatialAuthoredShadowLighting(
  List<SpatialAuthoredShadowCaster> casters, {
  required double receiverMinY,
  required double receiverMaxY,
  ({double x, double y, double z}) sunDirection = (x: -.45, y: 1, z: -.3),
}) {
  if (casters.isEmpty) return SpatialLightingProfile.disabled;
  final sun = Vector3(sunDirection.x, sunDirection.y, sunDirection.z);
  if (!sun.length.isFinite || sun.length < .000001 || sun.y <= 0) {
    throw ArgumentError.value(sunDirection, 'sunDirection');
  }
  sun.normalize();
  final right = (sun.y.abs() > .99 ? Vector3(0, 0, 1) : Vector3(0, 1, 0)).cross(
    sun,
  )..normalize();
  final up = sun.cross(right)..normalize();
  final corners = [for (final caster in casters) ...caster.worldCorners];
  final minimumY = math.min(
    receiverMinY,
    corners.map((p) => p.y).reduce(math.min),
  );
  final maximumY =
      math.max(receiverMaxY, corners.map((p) => p.y).reduce(math.max)) + 2;
  final points = [
    for (final corner in corners) ...[
      corner,
      corner - sun * ((corner.y - minimumY) / sun.y),
    ],
  ];
  (double, double) range(Vector3 axis) {
    final values = points.map((point) => axis.dot(point));
    return (values.reduce(math.min), values.reduce(math.max));
  }

  final horizontal = range(right), vertical = range(up), distance = range(sun);
  final center =
      right * ((horizontal.$1 + horizontal.$2) / 2) +
      up * ((vertical.$1 + vertical.$2) / 2) +
      sun * ((distance.$1 + distance.$2) / 2);
  final extent = math.max(
    8.0,
    math.max(horizontal.$2 - horizontal.$1, vertical.$2 - vertical.$1) + 4,
  );
  final depth = math.max(16.0, distance.$2 - distance.$1 + 8);
  return SpatialLightingProfile.stylized(
    ambientColor: const Color(0xffffffff),
    sunColor: const Color(0xffffffff),
    ambientStrength: .78,
    sunStrength: (.22 / sun.y).clamp(0.0, 2.0),
    sunDirection: (x: sun.x, y: sun.y, z: sun.z),
    surfaceStrength: 0,
    groundStrength: 1,
    actorStrength: 1,
    shadow: SpatialShadowProfile(
      casterInstanceIds: {for (final caster in casters) caster.id},
      center: (x: center.x, y: center.y, z: center.z),
      extent: extent,
      depth: depth,
      bias: (.02 / depth).clamp(.000001, .002),
      opacity: .85,
      filterRadius: 2.5,
      actorReceivers: true,
      receiverMinY: minimumY,
      receiverMaxY: maximumY,
    ),
  );
}
