import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'relief_height_step_characterization_test.dart' show reliefMap, surface;

Set<GridPos> rect(int x, int y, int width, int height) => {
  for (var dy = 0; dy < height; dy++)
    for (var dx = 0; dx < width; dx++) GridPos(x: x + dx, y: y + dy),
};

double at(MapData map, int x, int y) =>
    map.spatialScene!.worldHeightAt(x + .5, y + .5);

SpatialTerrainSurface surfaceOf(MapData map, String id) =>
    map.spatialScene!.terrainSurfaces.surfaces.singleWhere((s) => s.id == id);

void main() {
  test('painting cells at a height creates one flat surface over them', () {
    final map = reliefMap([]);
    final painted = paintTerrainCellsAtHeight(map, rect(3, 3, 4, 2), height: 2);
    expect(painted.surfaceId, 'terrain_surface_1');
    final created = surfaceOf(painted.map, 'terrain_surface_1');
    expect(created.footprints, hasLength(1));
    expect((created.gradientX, created.gradientZ), (0.0, 0.0));
    expect(at(painted.map, 3, 3), 2);
    expect(at(painted.map, 6, 4), 2);
    expect(at(painted.map, 7, 4), 1);
    expect(at(painted.map, 3, 5), 1);
  });

  test('cells painted next to a surface of the same height merge into it', () {
    final map = reliefMap([
      (
        id: 'plateau',
        height: 2,
        rectangles: [(x: 3, y: 3, width: 4, height: 2)],
      ),
      (id: 'other', height: 2, rectangles: [(x: 3, y: 6, width: 2, height: 1)]),
    ]);
    final painted = paintTerrainCellsAtHeight(map, rect(3, 5, 2, 1), height: 2);
    expect(painted.surfaceId, 'plateau');
    expect(painted.deletedSurfaceIds, ['other']);
    final merged = surfaceOf(painted.map, 'plateau');
    expect(merged.footprints, hasLength(2));
    for (final cell in [...rect(3, 3, 4, 2), ...rect(3, 5, 2, 2)]) {
      expect(
        merged.contains(cell.x + .5, cell.y + .5),
        isTrue,
        reason: '$cell',
      );
    }
    expect(at(painted.map, 5, 5), 1);
  });

  test('painting a lower height cuts the higher surface it covers', () {
    final map = reliefMap([
      (
        id: 'plateau',
        height: 2,
        rectangles: [(x: 2, y: 2, width: 6, height: 5)],
      ),
    ]);
    final added = const SpatialMapOperations().upsertTerrainSurfaces(map, [
      surface('low', 1, [(x: 4, y: 4, width: 2, height: 1)]),
    ]);
    expect(at(added, 4, 4), 2);

    final painted = paintTerrainCellsAtHeight(map, rect(4, 4, 2, 1), height: 1);
    expect(at(painted.map, 4, 4), 1);
    expect(at(painted.map, 5, 4), 1);
    expect(at(painted.map, 3, 4), 2);
    expect(at(painted.map, 6, 4), 2);
    expect(at(painted.map, 4, 3), 2);
    expect(at(painted.map, 4, 5), 2);
    expect(painted.upsertedSurfaceIds, contains('plateau'));
    expect(surfaceOf(painted.map, 'plateau').footprints.length, greaterThan(1));
  });

  test('lowering every cell of a surface removes it', () {
    final map = reliefMap([
      (
        id: 'plateau',
        height: 2,
        rectangles: [(x: 2, y: 2, width: 3, height: 2)],
      ),
    ]);
    final painted = paintTerrainCellsAtHeight(map, rect(2, 2, 3, 2), height: 1);
    expect(painted.deletedSurfaceIds, ['plateau']);
    expect(
      painted.map.spatialScene!.terrainSurfaces.surfaces.map((s) => s.id),
      ['base'],
    );
    expect(at(painted.map, 3, 3), 1);
  });

  test('a cut gradient surface keeps its slope on the remaining cells', () {
    final map = reliefMap(
      [],
      extra: [
        surface(
          'ramp',
          2,
          [(x: 4, y: 2, width: 2, height: 4)],
          gradientZ: -.25,
          originZ: 2,
        ),
      ],
    );
    final painted = paintTerrainCellsAtHeight(map, rect(4, 2, 2, 1), height: 1);
    expect(at(painted.map, 4, 2), 1);
    expect(at(painted.map, 4, 4), at(map, 4, 4));
    expect(surfaceOf(painted.map, 'ramp').gradientZ, -.25);
  });

  test('a shape needing more than 32 rectangles is refused', () {
    final map = reliefMap([], width: 20, depth: 20);
    final checkerboard = {
      for (var y = 0; y < 10; y++)
        for (var x = 0; x < 10; x++)
          if ((x + y).isEven) GridPos(x: x, y: y),
    };
    expect(
      () => paintTerrainCellsAtHeight(map, checkerboard, height: 2),
      throwsA(
        isA<ValidationException>()
            .having(
              (e) => e.code,
              'code',
              'spatial.terrain.paint.footprint_limit',
            )
            .having((e) => e.details['footprintCount'], 'count', 50),
      ),
    );
  });

  test('a new surface beyond 128 per map is refused', () {
    final map = reliefMap(
      [
        for (var i = 0; i < 127; i++)
          (
            id: 's$i',
            height: 2.0 + i,
            rectangles: [(x: i % 16, y: i ~/ 16, width: 1, height: 1)],
          ),
      ],
      width: 16,
      depth: 16,
    );
    expect(
      () => paintTerrainCellsAtHeight(map, {
        const GridPos(x: 0, y: 12),
      }, height: 300),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.code,
          'code',
          'spatial.terrain.paint.surface_limit',
        ),
      ),
    );
  });

  test('cutting a surface that does not follow the grid is refused', () {
    final map = reliefMap(
      [],
      extra: [
        SpatialTerrainSurface(
          id: 'shard',
          x: 2,
          z: 2,
          height: 3,
          footprints: [
            BorderGroundFootprint(
              points: [
                BorderGroundPoint(x: 0, z: 0),
                BorderGroundPoint(x: 3.5, z: 0),
                BorderGroundPoint(x: 0, z: 3.5),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      () => paintTerrainCellsAtHeight(map, {
        const GridPos(x: 2, y: 2),
      }, height: 2),
      throwsA(
        isA<ValidationException>()
            .having(
              (e) => e.code,
              'code',
              'spatial.terrain.paint.surface_not_cell_aligned',
            )
            .having((e) => e.details['surfaceId'], 'surface', 'shard'),
      ),
    );
  });

  test('the steps around painted cells list each height pair once', () {
    final map = reliefMap([
      (
        id: 'plateau',
        height: 2,
        rectangles: [(x: 2, y: 2, width: 8, height: 6)],
      ),
      (
        id: 'terrace',
        height: 3,
        rectangles: [(x: 2, y: 4, width: 3, height: 3)],
      ),
    ]);
    expect(terrainHeightStepsAround(map, rect(2, 4, 3, 3)), [
      (lower: 1.0, upper: 3.0),
      (lower: 2.0, upper: 3.0),
    ]);
  });
}
