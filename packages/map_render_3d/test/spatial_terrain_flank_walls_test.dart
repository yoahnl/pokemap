import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_terrain_geometry.dart';

void main() {
  test('a one-cell closed-flank slope gets a wall on each flank', () {
    final walls = wallsOf(slopeScene(left: 2, width: 1));
    expect(walls, hasLength(6));
    expect(flank(walls, 2), hasLength(3));
    expect(flank(walls, 3), hasLength(3));
    expect(area(flank(walls, 2)), closeTo(2, 1e-9));
    expect(area(flank(walls, 3)), closeTo(2, 1e-9));
    for (final point in walls.expand((face) => face.positions)) {
      expect(point.z, inInclusiveRange(1, 3));
      expect(point.y, inInclusiveRange(0, 3 - point.z + 1e-9));
    }
  });

  test(
    'a three-cell closed-flank slope gets walls on its outer flanks only',
    () {
      final walls = wallsOf(slopeScene(left: 1, width: 3));
      expect(walls, hasLength(6));
      expect(flank(walls, 1), hasLength(3));
      expect(flank(walls, 4), hasLength(3));
      expect(area(flank(walls, 1)), closeTo(2, 1e-9));
      expect(area(flank(walls, 4)), closeTo(2, 1e-9));
      expect(walls.map((face) => face.cell).toSet(), {
        (1, 1),
        (1, 2),
        (3, 1),
        (3, 2),
      });
    },
  );

  test('flank walls match the cliffs a map with cliffs draws there', () {
    for (final (left, width) in [(2, 1), (1, 3)]) {
      final walls = wallsOf(slopeScene(left: left, width: width));
      final cliffs = wallsOf(
        slopeScene(left: left, width: width, generateCliffs: true),
      );
      for (final x in [left, left + width]) {
        expect(
          describe(flank(walls, x.toDouble())),
          describe(flank(cliffs, x.toDouble())),
        );
      }
    }
  });

  test('a flank wall stops at a neighbouring terrace', () {
    final walls = wallsOf(
      slopeScene(left: 2, width: 1, terraceOnTheLeft: true),
    );
    final left = flank(walls, 2);
    expect(left, hasLength(1));
    expect(area(left), closeTo(.5, 1e-9));
    expect(
      left.single.positions.map((point) => point.y),
      everyElement(greaterThanOrEqualTo(1 - 1e-9)),
    );
    expect(area(flank(walls, 3)), closeTo(2, 1e-9));
  });

  test('the slope ends never get a wall', () {
    final walls = wallsOf(slopeScene(left: 2, width: 1));
    expect(walls, isNotEmpty);
    expect(
      walls.expand((face) => face.positions).map((point) => point.x),
      everyElement(anyOf(closeTo(2, 1e-12), closeTo(3, 1e-12))),
    );
  });

  test('a slope without closed flanks stays open on a map without cliffs', () {
    final open = spatialTerrainFaces(
      slopeScene(left: 2, width: 1, closedFlanks: false),
    ).toList();
    final closed = spatialTerrainFaces(slopeScene(left: 2, width: 1)).toList();
    expect(open.where((face) => !face.isTop), isEmpty);
    expect(
      describe(closed.where((face) => face.isTop)),
      describe(open.where((face) => face.isTop)),
    );
  });

  test('closed flanks change nothing on a map that generates cliffs', () {
    for (final width in [1, 3]) {
      expect(
        describe(
          spatialTerrainFaces(
            slopeScene(left: 1, width: width, generateCliffs: true),
          ),
        ),
        describe(
          spatialTerrainFaces(
            slopeScene(
              left: 1,
              width: width,
              generateCliffs: true,
              closedFlanks: false,
            ),
          ),
        ),
      );
    }
  });
}

List<SpatialTerrainFace> wallsOf(MapSpatialScene scene) =>
    spatialTerrainFaces(scene).where((face) => !face.isTop).toList();

List<SpatialTerrainFace> flank(List<SpatialTerrainFace> walls, double x) =>
    walls
        .where(
          (face) =>
              face.positions.every((point) => (point.x - x).abs() < 1e-12),
        )
        .toList();

double area(Iterable<SpatialTerrainFace> faces) {
  var total = 0.0;
  for (final face in faces) {
    final normal = Vector3.zero();
    for (var i = 0; i < face.positions.length; i++) {
      normal.add(
        face.positions[i].cross(
          face.positions[(i + 1) % face.positions.length],
        ),
      );
    }
    total += normal.length / 2;
  }
  return total;
}

List<String> describe(Iterable<SpatialTerrainFace> faces) => [
  for (final face in faces)
    '${face.cell} ${face.isTop} '
        '${face.positions.map((p) => '(${p.x},${p.y},${p.z})').join()} '
        '${face.uvs.map((uv) => '(${uv.x},${uv.y})').join()}',
];

MapSpatialScene slopeScene({
  required int left,
  required int width,
  bool closedFlanks = true,
  bool generateCliffs = false,
  bool terraceOnTheLeft = false,
}) => MapSpatialScene(
  width: 6,
  depth: 4,
  heightLevels: [for (var i = 0; i < 24; i++) i < 6 ? 2 : 0],
  generateCliffs: generateCliffs,
  terrainSurfaces: SpatialTerrainSurfaceSet(
    surfaces: [
      SpatialTerrainSurface(
        id: 'slope',
        x: left.toDouble(),
        z: 1,
        height: 2,
        gradientZ: -1,
        closedFlanks: closedFlanks,
        footprints: [rectangle(width, 2)],
      ),
      if (terraceOnTheLeft)
        SpatialTerrainSurface(
          id: 'terrace',
          x: left - 1.0,
          z: 1,
          height: 1,
          footprints: [rectangle(1, 2)],
        ),
    ],
  ),
);

BorderGroundFootprint rectangle(int width, int depth) => BorderGroundFootprint(
  points: [
    BorderGroundPoint(x: 0, z: 0),
    BorderGroundPoint(x: width.toDouble(), z: 0),
    BorderGroundPoint(x: width.toDouble(), z: depth.toDouble()),
    BorderGroundPoint(x: 0, z: depth.toDouble()),
  ],
);
