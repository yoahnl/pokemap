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
    this.filterRadius = 1,
    this.actorReceivers = false,
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
          filterRadius,
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
    if (filterRadius < 0 || filterRadius > 8) {
      throw ArgumentError('Invalid experimental shadow filter radius.');
    }
  }

  final Set<String> casterInstanceIds;
  final ({double x, double y, double z}) center;
  final double extent, depth, bias, opacity, receiverMinY, receiverMaxY;
  final int resolution;
  final double filterRadius;
  final bool actorReceivers;
}

({Vector3 right, Vector3 up, Vector3 forward}) spatialShadowBasis(
  ({double x, double y, double z}) direction,
) {
  final forward = Vector3(direction.x, direction.y, direction.z);
  if (!forward.length.isFinite || forward.length < .000001) {
    throw ArgumentError('Shadow map sunlight requires a finite direction.');
  }
  forward.normalize();
  final sign = forward.y >= 0 ? 1.0 : -1.0;
  final factor = -1 / (sign + forward.y);
  final right = Vector3(
    1 + sign * forward.x * forward.x * factor,
    -sign * forward.x,
    sign * forward.x * forward.z * factor,
  )..normalize();
  return (
    right: right,
    up: forward.cross(right)..normalize(),
    forward: forward,
  );
}

({Matrix4 view, Matrix4 projection, Matrix4 viewProjection})
spatialShadowProjection(
  SpatialShadowProfile profile,
  ({double x, double y, double z}) direction, {
  ({double x, double y, double z}) origin = (x: 0, y: 0, z: 0),
}) {
  final basis = spatialShadowBasis(direction);
  final sun = basis.forward;
  final center = Vector3(
    profile.center.x - origin.x,
    profile.center.y - origin.y,
    profile.center.z - origin.z,
  );
  final view = Matrix4.identity()
    ..setRow(
      0,
      Vector4(
        basis.right.x,
        basis.right.y,
        basis.right.z,
        -basis.right.dot(center),
      ),
    )
    ..setRow(
      1,
      Vector4(basis.up.x, basis.up.y, basis.up.z, -basis.up.dot(center)),
    )
    ..setRow(
      2,
      Vector4(sun.x, sun.y, sun.z, -sun.dot(center) - profile.depth / 2),
    );
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
  SpatialShadowFrame(
    this.texture,
    this.worldToLight,
    this.profile, {
    this.samples = 1,
    this.supersampled = false,
    this.origin = (x: 0, y: 0, z: 0),
    this.relativeWorldToLight,
  });
  final Texture texture;
  final Matrix4 worldToLight;
  final SpatialShadowProfile profile;
  final int samples;
  final bool supersampled;
  final ({double x, double y, double z}) origin;
  final Matrix4? relativeWorldToLight;
}

bool spatialShadowIntersectsBounds(Matrix4 worldToLight, Aabb3 bounds) {
  final projected = Aabb3.copy(bounds)..transform(worldToLight);
  return projected.max.x >= -1 &&
      projected.min.x <= 1 &&
      projected.max.y >= -1 &&
      projected.min.y <= 1 &&
      projected.max.z >= 0 &&
      projected.min.z <= 1;
}

final class SpatialShadowStats {
  const SpatialShadowStats({
    this.casterDrawCount = 0,
    this.receiverDrawCount = 0,
    this.targetAllocations = 0,
    this.hiddenDrawCount = 0,
    this.pointCasterDrawCount = 0,
    this.pointReceiverDrawCount = 0,
    this.pointTargetAllocations = 0,
    this.pointShadowLightCount = 0,
  });
  final int casterDrawCount,
      receiverDrawCount,
      targetAllocations,
      hiddenDrawCount;
  final int pointCasterDrawCount,
      pointReceiverDrawCount,
      pointTargetAllocations,
      pointShadowLightCount;
}
