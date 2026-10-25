import 'package:flame_3d/core.dart';

typedef SpatialShadowCoverageMask = ({int a, int b, int c, int d});

const spatialFullShadowCoverage = (a: 65535, b: 65535, c: 65535, d: 65535);

final class SpatialShadowCoverage {
  SpatialShadowCoverage({required this.resolution, required this.filterRadius});

  final int resolution;
  final double filterRadius;
  final _chunks = List<int>.filled(4, 0);

  SpatialShadowCoverageMask get mask =>
      (a: _chunks[0], b: _chunks[1], c: _chunks[2], d: _chunks[3]);

  void add(Matrix4 worldToLight, Aabb3 bounds) {
    if (_chunks.every((chunk) => chunk == 65535)) return;
    final projected = Aabb3.copy(bounds)..transform(worldToLight);
    if (![
      projected.min.x,
      projected.min.y,
      projected.max.x,
      projected.max.y,
    ].every((value) => value.isFinite)) {
      fill();
      return;
    }
    final x = bounds.min.x.abs() > bounds.max.x.abs()
        ? bounds.min.x.abs()
        : bounds.max.x.abs();
    final y = bounds.min.y.abs() > bounds.max.y.abs()
        ? bounds.min.y.abs()
        : bounds.max.y.abs();
    final z = bounds.min.z.abs() > bounds.max.z.abs()
        ? bounds.min.z.abs()
        : bounds.max.z.abs();
    final m = worldToLight.storage;
    final errorX =
        m[12].abs() + m[0].abs() * x + m[4].abs() * y + m[8].abs() * z;
    final errorY =
        m[13].abs() + m[1].abs() * x + m[5].abs() * y + m[9].abs() * z;
    final padding =
        (filterRadius + 2) / resolution +
        (errorX > errorY ? errorX : errorY) * .000001;
    final minU = projected.min.x * .5 + .5 - padding;
    final maxU = projected.max.x * .5 + .5 + padding;
    final minV = .5 - projected.max.y * .5 - padding;
    final maxV = .5 - projected.min.y * .5 + padding;
    if (maxU < 0 || minU > 1 || maxV < 0 || minV > 1) return;
    final left = (minU * 8).floor().clamp(0, 7);
    final right = (maxU * 8).floor().clamp(0, 7);
    final top = (minV * 8).floor().clamp(0, 7);
    final bottom = (maxV * 8).floor().clamp(0, 7);
    for (var row = top; row <= bottom; row++) {
      for (var column = left; column <= right; column++) {
        final index = row * 8 + column;
        _chunks[index ~/ 16] |= 1 << (index % 16);
      }
    }
  }

  void fill() => _chunks.fillRange(0, 4, 65535);
}

bool spatialShadowCoverageContains(
  SpatialShadowCoverageMask mask,
  double u,
  double v,
) {
  final column = (u * 8).floor().clamp(0, 7);
  final row = (v * 8).floor().clamp(0, 7);
  final index = row * 8 + column;
  final chunk = switch (index ~/ 16) {
    0 => mask.a,
    1 => mask.b,
    2 => mask.c,
    _ => mask.d,
  };
  return chunk & (1 << (index % 16)) != 0;
}
