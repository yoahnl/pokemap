import 'dart:math' as math;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';

final class SpatialShadowProfile {
  SpatialShadowProfile({
    required Set<String> casterInstanceIds,
    this.center = (x: 0, y: 0, z: 0),
    this.extent = 16,
    this.depth = 32,
    this.resolution = 1024,
    this.bias = .0015,
    this.opacity = .65,
    this.receiverMinY = -.5,
    this.receiverMaxY = .5,
  }) : casterInstanceIds = Set.unmodifiable(casterInstanceIds) {
    if (![
          center.x,
          center.y,
          center.z,
          extent,
          depth,
          bias,
          opacity,
          receiverMinY,
          receiverMaxY,
        ].every((v) => v.isFinite) ||
        extent <= 0 ||
        depth <= 1 ||
        bias < 0 ||
        bias > .05 ||
        opacity < 0 ||
        opacity > 1 ||
        resolution < 64 ||
        resolution > 2048 ||
        receiverMinY > receiverMaxY) {
      throw ArgumentError('Invalid experimental shadow map profile.');
    }
  }

  final Set<String> casterInstanceIds;
  final ({double x, double y, double z}) center;
  final double extent, depth, bias, opacity, receiverMinY, receiverMaxY;
  final int resolution;
}

({Matrix4 view, Matrix4 projection, Matrix4 viewProjection})
spatialShadowProjection(
  SpatialShadowProfile profile,
  ({double x, double y, double z}) direction,
) {
  final sun = Vector3(direction.x, direction.y, direction.z);
  if (!sun.length.isFinite || sun.length < .000001) {
    throw ArgumentError('Shadow map sunlight requires a finite direction.');
  }
  sun.normalize();
  final center = Vector3(profile.center.x, profile.center.y, profile.center.z);
  final up = sun.y.abs() > .99 ? Vector3(0, 0, 1) : Vector3(0, 1, 0);
  final view = Matrix4.zero()
    ..setAsViewMatrix(center + sun * (profile.depth / 2), center, up);
  final projection = Matrix4.zero()
    ..setAsOrthographic(profile.extent, 1, .1, profile.depth);
  for (var column = 0; column < 4; column++) {
    projection.setEntry(
      2,
      column,
      (projection.entry(2, column) + projection.entry(3, column)) / 2,
    );
  }
  return (
    view: view,
    projection: projection,
    viewProjection: projection.multiplied(view),
  );
}

final class SpatialShadowFrame {
  SpatialShadowFrame(this.texture, this.worldToLight, this.profile);
  final Texture texture;
  final Matrix4 worldToLight;
  final SpatialShadowProfile profile;
}

final class SpatialShadowStats {
  const SpatialShadowStats({
    this.casterDrawCount = 0,
    this.receiverDrawCount = 0,
    this.targetAllocations = 0,
    this.hiddenDrawCount = 0,
  });
  final int casterDrawCount,
      receiverDrawCount,
      targetAllocations,
      hiddenDrawCount;
}

double spatialShadowVisibility({
  required double receiverDepth,
  required double storedDepth,
  required double bias,
}) => receiverDepth - math.max(0, bias) <= storedDepth ? 1 : 0;
