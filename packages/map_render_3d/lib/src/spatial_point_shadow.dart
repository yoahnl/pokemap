import 'dart:math' as math;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';

import 'spatial_point_light.dart';

const spatialPointShadowFaceResolution = 256;

int spatialPointShadowFace(Vector3 delta) {
  final x = delta.x.abs(), y = delta.y.abs(), z = delta.z.abs();
  if (x >= y && x >= z) return delta.x >= 0 ? 0 : 1;
  if (y >= z) return delta.y >= 0 ? 2 : 3;
  return delta.z >= 0 ? 4 : 5;
}

Vector3 spatialPointShadowRay(Vector2 uv, int face) {
  final x = uv.x * 2 - 1, y = 1 - uv.y * 2;
  return (switch (face) {
    0 => Vector3(1, -y, -x),
    1 => Vector3(-1, -y, x),
    2 => Vector3(x, 1, y),
    3 => Vector3(x, -1, -y),
    4 => Vector3(x, -y, 1),
    5 => Vector3(-x, -y, -1),
    _ => throw RangeError.range(face, 0, 5),
  })..normalize();
}

double spatialPointShadowReceiverBias(
  double distance,
  double cosine,
  int resolution,
  double radius,
) {
  final footprint = 2 * distance / resolution;
  return math.min(
    math.min(.02, radius * .005),
    .001 + footprint * (.1 + .1 * (1 - cosine.abs().clamp(0.0, 1.0))),
  );
}

double spatialPointShadowReferenceDistance(
  Vector3 receiver,
  Vector3 normal,
  Vector3 ray, {
  required double radius,
  int resolution = spatialPointShadowFaceResolution,
}) {
  final distance = receiver.length;
  final denominator = normal.dot(ray);
  final planeDistance = denominator.abs() > .000001
      ? normal.dot(receiver) / denominator
      : -1.0;
  final expected = planeDistance > 0
      ? math.min(radius, planeDistance)
      : distance;
  final cosine = (normal.dot(receiver) / (normal.length * distance))
      .abs()
      .clamp(0.0, 1.0);
  return math.max(
    0,
    expected -
        spatialPointShadowReceiverBias(distance, cosine, resolution, radius),
  );
}

Vector2 spatialPointShadowAtlasUv(
  Vector3 delta,
  int face,
  int lightCount, {
  int lightIndex = 0,
}) {
  if (!delta.dot(delta).isFinite || delta.dot(delta) == 0)
    throw ArgumentError(
      'A point shadow ray requires a finite nonzero direction.',
    );
  final (x, y, distance) = switch (face) {
    0 => (-delta.z, -delta.y, delta.x.abs()),
    1 => (delta.z, -delta.y, delta.x.abs()),
    2 => (delta.x, delta.z, delta.y.abs()),
    3 => (delta.x, -delta.z, delta.y.abs()),
    4 => (delta.x, -delta.y, delta.z.abs()),
    5 => (-delta.x, -delta.y, delta.z.abs()),
    _ => throw RangeError.range(face, 0, 5),
  };
  return Vector2(
    (face % 3 + x / distance * .5 + .5) / 3,
    (lightIndex * 2 + face ~/ 3 + .5 - y / distance * .5) / (lightCount * 2),
  );
}

({Matrix4 view, Matrix4 projection, Matrix4 viewProjection})
spatialPointShadowProjection(SpatialPointLight light, int face) {
  final (direction, up) = switch (face) {
    0 => (Vector3(1, 0, 0), Vector3(0, -1, 0)),
    1 => (Vector3(-1, 0, 0), Vector3(0, -1, 0)),
    2 => (Vector3(0, 1, 0), Vector3(0, 0, 1)),
    3 => (Vector3(0, -1, 0), Vector3(0, 0, -1)),
    4 => (Vector3(0, 0, 1), Vector3(0, -1, 0)),
    5 => (Vector3(0, 0, -1), Vector3(0, -1, 0)),
    _ => throw RangeError.range(face, 0, 5),
  };
  final position = Vector3(
    light.position.x,
    light.position.y,
    light.position.z,
  );
  final view = Matrix4.zero()
    ..setAsViewMatrix(position, position + direction, up);
  final projection = Matrix4.zero()
    ..setAsPerspective(90, 1, math.min(.02, light.radius * .01), light.radius);
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
    viewProjection: projection * view,
  );
}

bool spatialPointShadowIntersects(SpatialPointLight light, Aabb3 bounds) {
  final p = light.position;
  final dx = p.x - _clamp(p.x, bounds.min.x, bounds.max.x);
  final dy = p.y - _clamp(p.y, bounds.min.y, bounds.max.y);
  final dz = p.z - _clamp(p.z, bounds.min.z, bounds.max.z);
  return dx * dx + dy * dy + dz * dz <= light.radius * light.radius;
}

double _clamp(double value, double lower, double upper) =>
    value < lower ? lower : (value > upper ? upper : value);

bool spatialPointShadowIntersectsFace(Matrix4 worldToClip, Aabb3 bounds) {
  final m = worldToClip.storage;
  for (var plane = 0; plane < 6; plane++) {
    final axis = plane ~/ 2;
    final sign = plane.isEven ? 1.0 : -1.0;
    final w = plane == 4 ? 0.0 : 1.0;
    final x = w * m[3] + sign * m[axis];
    final y = w * m[7] + sign * m[4 + axis];
    final z = w * m[11] + sign * m[8 + axis];
    final d = w * m[15] + sign * m[12 + axis];
    final distance =
        x * (x >= 0 ? bounds.max.x : bounds.min.x) +
        y * (y >= 0 ? bounds.max.y : bounds.min.y) +
        z * (z >= 0 ? bounds.max.z : bounds.min.z) +
        d;
    if (distance < -.00001) return false;
  }
  return true;
}

final class SpatialPointShadowFrame {
  const SpatialPointShadowFrame(
    this.texture,
    this.lightCount, {
    this.faceResolution = spatialPointShadowFaceResolution,
    this.samples = 1,
    this.supersampled = false,
  });
  final Texture texture;
  final int lightCount, faceResolution, samples;
  final bool supersampled;
}
