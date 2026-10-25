import 'dart:math' as math;

import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_shadow_coverage.dart';
import 'package:map_render_3d/src/spatial_shadow_profile.dart';

void main() {
  test('empty coverage is lit and adding distant bounds retains the gap', () {
    final coverage = SpatialShadowCoverage(resolution: 1024, filterRadius: 2.5);
    expect(spatialShadowCoverageContains(coverage.mask, .5, .5), isFalse);
    coverage.add(
      Matrix4.identity(),
      Aabb3.minMax(Vector3(-.8, -.8, 0), Vector3(-.7, -.7, 1)),
    );
    coverage.add(
      Matrix4.identity(),
      Aabb3.minMax(Vector3(.7, .7, 0), Vector3(.8, .8, 1)),
    );
    expect(spatialShadowCoverageContains(coverage.mask, .125, .875), isTrue);
    expect(spatialShadowCoverageContains(coverage.mask, .875, .125), isTrue);
    expect(spatialShadowCoverageContains(coverage.mask, .5, .5), isFalse);
    coverage.fill();
    expect(coverage.mask, spatialFullShadowCoverage);
  });

  test(
    'filter footprints cross grid edges without dropping neighboring texels',
    () {
      final coverage = SpatialShadowCoverage(resolution: 64, filterRadius: 8);
      coverage.add(
        Matrix4.identity(),
        Aabb3.minMax(Vector3(-.0001, -.0001, 0), Vector3(.0001, .0001, 1)),
      );
      for (var y = -8; y <= 8; y++) {
        for (var x = -8; x <= 8; x++) {
          expect(
            spatialShadowCoverageContains(
              coverage.mask,
              .5 + x / 64,
              .5 + y / 64,
            ),
            isTrue,
          );
        }
      }
    },
  );

  test('random translated projections retain every filtered caster sample', () {
    final random = math.Random(317);
    for (final offset in [0.0, 10000.0, -10000.0]) {
      final profile = SpatialShadowProfile(
        casterInstanceIds: {'generic'},
        center: (x: offset, y: 0, z: offset),
        filterRadius: 2.5,
      );
      final matrix = spatialShadowProjection(profile, (
        x: -.6,
        y: .8,
        z: -.4,
      )).viewProjection;
      final coverage = SpatialShadowCoverage(
        resolution: 1024,
        filterRadius: 2.5,
      );
      final boxes = <Aabb3>[];
      for (var i = 0; i < 12; i++) {
        final center = Vector3(
          offset + random.nextDouble() * 24 - 12,
          random.nextDouble() * 5,
          offset + random.nextDouble() * 24 - 12,
        );
        boxes.add(
          Aabb3.minMax(center - Vector3.all(.15), center + Vector3.all(.15)),
        );
        coverage.add(matrix, boxes.last);
      }
      for (final box in boxes) {
        for (var i = 0; i < 40; i++) {
          final point = Vector3(
            box.min.x + random.nextDouble() * (box.max.x - box.min.x),
            box.min.y + random.nextDouble() * (box.max.y - box.min.y),
            box.min.z + random.nextDouble() * (box.max.z - box.min.z),
          );
          matrix.transform3(point);
          final u = point.x * .5 + .5 + (random.nextDouble() * 7 - 3.5) / 1024;
          final v = .5 - point.y * .5 + (random.nextDouble() * 7 - 3.5) / 1024;
          if (u >= 0 && u <= 1 && v >= 0 && v <= 1) {
            expect(spatialShadowCoverageContains(coverage.mask, u, v), isTrue);
          }
        }
      }
    }
  });
}
