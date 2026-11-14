import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'relief_height_step_characterization_test.dart' show reliefMap;

final _manifest = ProjectManifest(name: 'Slope', maps: [], tilesets: []);

MapData _plateau() => reliefMap([
  (id: 'plateau', height: 2, rectangles: [(x: 4, y: 3, width: 4, height: 4)]),
], depth: 12);

Matcher _refused(String code) =>
    throwsA(isA<ValidationException>().having((e) => e.code, 'code', code));

TerrainSlopePaint _slope(MapData map, GridPos from, GridPos to) =>
    paintTerrainSlope(manifest: _manifest, map: map, from: from, to: to);

void main() {
  test('dragging from the low ground onto a plateau slopes the low cells', () {
    final map = _plateau();
    final result = _slope(
      map,
      const GridPos(x: 5, y: 9),
      const GridPos(x: 6, y: 5),
    );
    final plan = result.plan;
    expect(plan.direction, SpatialRampDirection.north);
    expect((plan.lowerHeight, plan.upperHeight), (1.0, 2.0));
    expect(plan.cells, {
      for (var y = 7; y <= 9; y++)
        for (var x = 5; x <= 6; x++) GridPos(x: x, y: y),
    });
    final scene = result.map.spatialScene!;
    final surface = scene.terrainSurfaces.surfaces.singleWhere(
      (surface) => surface.id == result.surfaceId,
    );
    expect(surface.closedFlanks, isTrue);
    expect(scene.worldHeightAt(5.5, 7), closeTo(2, 1e-9));
    expect(scene.worldHeightAt(6.5, 8.5), closeTo(1.5, 1e-9));
    expect(scene.worldHeightAt(5.5, 9.999), closeTo(1, 1e-3));
    expect(scene.worldHeightAt(4.5, 8.5), 1);
    expect(scene.worldHeightAt(5.5, 6.5), 2);
    expect(map.spatialScene!.worldHeightAt(5.5, 8.5), 1);
  });

  test('the four drag directions read both heights from the terrain', () {
    final map = reliefMap(
      [
        (
          id: 'plateau',
          height: 3,
          rectangles: [(x: 4, y: 4, width: 4, height: 4)],
        ),
      ],
      width: 14,
      depth: 14,
    );
    for (final (from, to, direction, cells) in [
      (
        const GridPos(x: 5, y: 1),
        const GridPos(x: 5, y: 4),
        SpatialRampDirection.south,
        {for (var y = 1; y <= 3; y++) GridPos(x: 5, y: y)},
      ),
      (
        const GridPos(x: 10, y: 6),
        const GridPos(x: 7, y: 6),
        SpatialRampDirection.west,
        {for (var x = 8; x <= 10; x++) GridPos(x: x, y: 6)},
      ),
      (
        const GridPos(x: 2, y: 5),
        const GridPos(x: 4, y: 5),
        SpatialRampDirection.east,
        {for (var x = 2; x <= 3; x++) GridPos(x: x, y: 5)},
      ),
    ]) {
      final result = _slope(map, from, to);
      expect(result.plan.direction, direction);
      expect(result.plan.cells, cells);
      expect((result.plan.lowerHeight, result.plan.upperHeight), (1.0, 3.0));
      final scene = result.map.spatialScene!;
      final climb = switch (direction) {
        SpatialRampDirection.north => (0, -1),
        SpatialRampDirection.south => (0, 1),
        SpatialRampDirection.east => (1, 0),
        SpatialRampDirection.west => (-1, 0),
      };
      final low = (
        from.x + .5 - climb.$1 * .4999,
        from.y + .5 - climb.$2 * .4999,
      );
      expect(scene.worldHeightAt(low.$1, low.$2), closeTo(1, 1e-3));
    }
  });

  test('on flat ground the slope climbs one level over the dragged cells', () {
    final map = reliefMap([], depth: 12);
    final result = _slope(
      map,
      const GridPos(x: 1, y: 1),
      const GridPos(x: 1, y: 3),
    );
    expect(result.plan.direction, SpatialRampDirection.south);
    expect((result.plan.lowerHeight, result.plan.upperHeight), (1.0, 2.0));
    expect(result.plan.cells, {
      for (var y = 1; y <= 3; y++) GridPos(x: 1, y: y),
    });
    expect(
      result.map.spatialScene!.worldHeightAt(1.5, 3.999),
      closeTo(2, 1e-3),
    );
  });

  test('unclear or impossible drags are refused without changes', () {
    final map = _plateau();
    expect(
      () => _slope(map, const GridPos(x: 5, y: 9), const GridPos(x: 7, y: 7)),
      _refused('spatial.slope.direction_ambiguous'),
    );
    expect(
      () => _slope(map, const GridPos(x: 5, y: 9), const GridPos(x: 5, y: 9)),
      _refused('spatial.slope.direction_ambiguous'),
    );
    expect(
      () => _slope(map, const GridPos(x: 5, y: 5), const GridPos(x: 5, y: 9)),
      _refused('spatial.slope.downhill'),
    );
    expect(
      () => _slope(map, const GridPos(x: 3, y: 9), const GridPos(x: 5, y: 4)),
      _refused('spatial.slope.ground_not_flat'),
    );
    expect(
      () => _slope(map, const GridPos(x: 5, y: 9), const GridPos(x: 5, y: 40)),
      _refused('spatial.slope.cells_invalid'),
    );
  });
}
