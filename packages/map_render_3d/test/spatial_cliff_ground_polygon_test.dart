import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_terrain_geometry.dart';

import 'spatial_cliff_ground_replacement_test.dart' show cliffFixture;

void main() {
  test(
    'stacked footprints split walls wherever the adjacent floor changes',
    () {
      final scene = MapSpatialScene(width: 1, depth: 1, heightLevels: [2]);
      BorderGroundFootprint shape(List<(double, double)> points) =>
          BorderGroundFootprint(
            points: [
              for (final point in points)
                BorderGroundPoint(x: point.$1, z: point.$2),
            ],
          );
      final index = indexSpatialBorderGroundReplacements(
        scene: scene,
        replacements: [
          SpatialBorderGroundReplacement(
            left: 0,
            top: 0,
            right: 1,
            bottom: 1,
            lowerHeight: 1,
            upperHeight: 2,
            footprints: [
              shape([(0, 0), (.5, 0), (.5, 1), (0, 1)]),
            ],
          ),
          SpatialBorderGroundReplacement(
            left: 0,
            top: 0,
            right: 1,
            bottom: 1,
            lowerHeight: 0,
            upperHeight: 1,
            footprints: [
              shape([(0, 1), (1, 0), (1, 1)]),
            ],
          ),
        ],
      );
      final walls =
          spatialTerrainFaces(
                scene,
                groundReplacements: index,
                repeatWalls: false,
              )
              .where(
                (face) =>
                    !face.isTop &&
                    face.positions.every((p) => (p.x - .5).abs() < 1e-9),
              )
              .toList();
      final lower = walls
          .where((face) => face.positions.every((p) => p.z >= .5 - 1e-9))
          .toList();
      expect(lower, hasLength(1));
      expect(lower.single.positions.map((p) => p.y).toSet(), {0.0, 2.0});
    },
  );

  test('generated cliffs close the exact diagonal ground boundary', () {
    final scene = MapSpatialScene(width: 1, depth: 1, heightLevels: [4]);
    final index = indexSpatialBorderGroundReplacements(
      scene: scene,
      replacements: [
        SpatialBorderGroundReplacement(
          left: 0,
          top: 0,
          right: 1,
          bottom: 1,
          lowerHeight: 1,
          upperHeight: 4,
          footprints: [
            BorderGroundFootprint(
              points: [
                BorderGroundPoint(x: 0, z: 0),
                BorderGroundPoint(x: 1, z: 0),
                BorderGroundPoint(x: 0, z: 1),
              ],
            ),
          ],
        ),
      ],
    );
    final walls =
        spatialTerrainFaces(
              scene,
              groundReplacements: index,
              repeatWalls: false,
            )
            .where(
              (face) =>
                  !face.isTop &&
                  face.positions.every((p) => (p.x + p.z - 1).abs() < 1e-9),
            )
            .toList();
    expect(walls, hasLength(1));
    expect(walls.single.positions.map((p) => p.y).toSet(), {1.0, 4.0});
  });

  test(
    'overlapping footprint pieces lower their union without duplicate ground',
    () {
      final scene = MapSpatialScene(
        width: 1,
        depth: 1,
        heightLevels: [4],
        generateCliffs: false,
      );
      BorderGroundFootprint rectangle(double right, double bottom) =>
          BorderGroundFootprint(
            points: [
              BorderGroundPoint(x: 0, z: 0),
              BorderGroundPoint(x: right, z: 0),
              BorderGroundPoint(x: right, z: bottom),
              BorderGroundPoint(x: 0, z: bottom),
            ],
          );
      final index = indexSpatialBorderGroundReplacements(
        scene: scene,
        replacements: [
          SpatialBorderGroundReplacement(
            left: 0,
            top: 0,
            right: 1,
            bottom: 1,
            lowerHeight: 1,
            upperHeight: 4,
            footprints: [rectangle(1, .5), rectangle(.5, 1)],
          ),
        ],
      );
      final patches = spatialSurfacePatches(
        scene,
        groundReplacements: index,
      ).toList();
      double area(Iterable<SpatialSurfacePatch> values) =>
          values.fold(0.0, (sum, patch) {
            final p = patch.corners;
            var cross = 0.0;
            for (var i = 0; i < p.length; i++) {
              cross +=
                  p[i].x * p[(i + 1) % p.length].z -
                  p[(i + 1) % p.length].x * p[i].z;
            }
            return sum + cross.abs() / 2;
          });
      expect(
        area(patches.where((p) => p.groundHeight == 1)),
        closeTo(.75, 1e-9),
      );
      expect(
        area(patches.where((p) => p.groundHeight == 4)),
        closeTo(.25, 1e-9),
      );
      expect(area(patches), closeTo(1, 1e-9));
    },
  );

  test('a cliff corner lowers only its triangular footprint', () {
    final fixture = cliffFixture();
    final raw = fixture.project.toJson();
    raw['borderCatalog']['formatVersion'] = 8;
    final record = (raw['borderCatalog']['records'] as List).single as Map;
    for (final revision in ['draft', 'latestPublished']) {
      final primitives = record[revision]['definition']['primitives'] as List;
      for (final primitive in primitives) {
        primitive['groundFootprints'] = [
          [
            {'x': -.5, 'z': -.5},
            {'x': .5, 'z': -.5},
            {'x': -.5, 'z': .5},
          ],
        ];
      }
    }
    final project = ProjectManifest.fromJson(raw);
    final plan = SpatialGroundPlan(fixture.map, project);
    final patches = spatialSurfacePatches(
      fixture.map.spatialScene!,
      groundReplacements: plan.borderGroundReplacements,
    ).where((patch) => patch.cell == (1, 1)).toList();
    double area(Iterable<SpatialSurfacePatch> values) => values.fold(0.0, (
      sum,
      patch,
    ) {
      final p = patch.corners;
      var cross = 0.0;
      for (var i = 0; i < p.length; i++) {
        cross +=
            p[i].x * p[(i + 1) % p.length].z - p[(i + 1) % p.length].x * p[i].z;
      }
      return sum + cross.abs() / 2;
    });
    expect(
      area(patches.where((p) => p.groundHeight == 1.0625)),
      closeTo(.5, 1e-9),
    );
    expect(
      area(patches.where((p) => p.groundHeight == 8.75)),
      closeTo(.5, 1e-9),
    );
    expect(area(patches), closeTo(1, 1e-9));
    expect(fixture.map.spatialScene!.heightAt(1, 1), 8.75);
  });
}
