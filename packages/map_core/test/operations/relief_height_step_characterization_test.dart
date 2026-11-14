import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

typedef Cells = ({int x, int y, int width, int height});

MapData reliefMap(
  List<({String id, double height, List<Cells> rectangles})> plateaus, {
  List<SpatialTerrainSurface> extra = const [],
  int width = 12,
  int depth = 10,
}) {
  final map = MapData(
    version: ProjectVersion.v9,
    id: 'relief',
    name: 'Relief',
    size: GridSize(width: width, height: depth),
    spatialScene: MapSpatialScene(width: width, depth: depth),
    layers: const [],
  );
  return const SpatialMapOperations().upsertTerrainSurfaces(map, [
    surface('base', 1, [(x: 0, y: 0, width: width, height: depth)]),
    for (final plateau in plateaus)
      surface(plateau.id, plateau.height, plateau.rectangles),
    ...extra,
  ]);
}

SpatialTerrainSurface surface(
  String id,
  double height,
  List<Cells> rectangles, {
  double gradientZ = 0,
  double originZ = 0,
}) => SpatialTerrainSurface(
  id: id,
  x: 0,
  z: originZ,
  height: height,
  gradientZ: gradientZ,
  footprints: [
    for (final r in rectangles)
      BorderGroundFootprint(
        points: [
          BorderGroundPoint(x: r.x.toDouble(), z: r.y - originZ),
          BorderGroundPoint(x: (r.x + r.width).toDouble(), z: r.y - originZ),
          BorderGroundPoint(
            x: (r.x + r.width).toDouble(),
            z: r.y + r.height - originZ,
          ),
          BorderGroundPoint(x: r.x.toDouble(), z: r.y + r.height - originZ),
        ],
      ),
  ],
);

Set<(GridPos, GridPos)> edgesOf(HeightStepContours contours) => {
  for (final stroke in contours.strokes)
    for (var i = 0; i + 1 < stroke.length; i++) (stroke[i], stroke[i + 1]),
};

({int left, int right}) turnsOf(List<GridPos> stroke) {
  var left = 0, right = 0;
  final closed = stroke.first == stroke.last;
  final points = closed ? stroke.sublist(0, stroke.length - 1) : stroke;
  for (var i = closed ? 0 : 1; i < points.length - (closed ? 0 : 1); i++) {
    final a = points[(i - 1 + points.length) % points.length];
    final b = points[i], c = points[(i + 1) % points.length];
    final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
    if (cross > 0) right++;
    if (cross < 0) left++;
  }
  return (left: left, right: right);
}

void main() {
  test('a painted 6x4 plateau traces one closed clockwise loop', () {
    final map = reliefMap([
      (
        id: 'plateau',
        height: 2,
        rectangles: [(x: 3, y: 3, width: 6, height: 4)],
      ),
    ]);
    final result = computeHeightStepEdges(map, lowerHeight: 1, upperHeight: 2);
    expect(result.status, SpatialIntentResolutionState.resolved);
    final stroke = result.strokes.single;
    expect(stroke.first, stroke.last);
    expect(stroke.length, 21);
    expect(turnsOf(stroke), (left: 0, right: 4));
    expect(stroke.take(2), const [GridPos(x: 3, y: 3), GridPos(x: 4, y: 3)]);
  });

  test('an L plateau keeps one loop with five outer and one inner corner', () {
    final map = reliefMap([
      (
        id: 'plateau',
        height: 2,
        rectangles: [
          (x: 2, y: 2, width: 6, height: 3),
          (x: 2, y: 5, width: 3, height: 3),
        ],
      ),
    ]);
    final result = computeHeightStepEdges(map, lowerHeight: 1, upperHeight: 2);
    expect(result.status, SpatialIntentResolutionState.resolved);
    final stroke = result.strokes.single;
    expect(stroke.first, stroke.last);
    expect(stroke.length, 2 * (6 + 6) + 1);
    expect(turnsOf(stroke), (left: 1, right: 5));
  });

  test('a plateau touching the map border yields an open stroke', () {
    final map = reliefMap([
      (
        id: 'plateau',
        height: 2,
        rectangles: [(x: 0, y: 3, width: 4, height: 4)],
      ),
    ]);
    final result = computeHeightStepEdges(map, lowerHeight: 1, upperHeight: 2);
    expect(result.status, SpatialIntentResolutionState.resolved);
    final stroke = result.strokes.single;
    expect(stroke.first, const GridPos(x: 0, y: 3));
    expect(stroke.last, const GridPos(x: 0, y: 7));
    expect(turnsOf(stroke), (left: 0, right: 2));
  });

  test('plateaus touching only at a corner are refused as branching', () {
    final map = reliefMap([
      (
        id: 'plateau',
        height: 2,
        rectangles: [
          (x: 2, y: 2, width: 2, height: 2),
          (x: 4, y: 4, width: 2, height: 2),
        ],
      ),
    ]);
    final result = computeHeightStepEdges(map, lowerHeight: 1, upperHeight: 2);
    expect(result.status, SpatialIntentResolutionState.ambiguous);
    expect(result.reason, 'branching_height_step');
    expect(result.ambiguousVertices, const [GridPos(x: 4, y: 4)]);
  });

  test(
    'an inner terrace traces only its own step and keeps the outer loop',
    () {
      final outer = reliefMap([
        (
          id: 'plateau',
          height: 2,
          rectangles: [(x: 2, y: 2, width: 8, height: 6)],
        ),
      ]);
      final terrace = reliefMap([
        (
          id: 'plateau',
          height: 2,
          rectangles: [(x: 2, y: 2, width: 8, height: 6)],
        ),
        (
          id: 'terrace',
          height: 3,
          rectangles: [(x: 4, y: 4, width: 3, height: 2)],
        ),
      ]);
      final low = computeHeightStepEdges(
        terrace,
        lowerHeight: 1,
        upperHeight: 2,
      );
      final high = computeHeightStepEdges(
        terrace,
        lowerHeight: 2,
        upperHeight: 3,
      );
      expect(
        low.strokes,
        computeHeightStepEdges(outer, lowerHeight: 1, upperHeight: 2).strokes,
      );
      expect(high.strokes.single.length, 2 * (3 + 2) + 1);
      expect(edgesOf(low).intersection(edgesOf(high)), isEmpty);
    },
  );

  test('a terrace touching the outer contour is traced by both steps', () {
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
    final low = computeHeightStepEdges(map, lowerHeight: 1, upperHeight: 2);
    final high = computeHeightStepEdges(map, lowerHeight: 2, upperHeight: 3);
    expect(low.status, SpatialIntentResolutionState.resolved);
    expect(high.status, SpatialIntentResolutionState.resolved);
    expect(edgesOf(low).intersection(edgesOf(high)), {
      (const GridPos(x: 2, y: 7), const GridPos(x: 2, y: 6)),
      (const GridPos(x: 2, y: 6), const GridPos(x: 2, y: 5)),
      (const GridPos(x: 2, y: 5), const GridPos(x: 2, y: 4)),
    });
  });

  test('a gradient ramp splits the loop and its flanks stay untraced', () {
    final map = reliefMap(
      [
        (
          id: 'plateau',
          height: 2,
          rectangles: [(x: 4, y: 3, width: 4, height: 4)],
        ),
      ],
      extra: [
        surface(
          'ramp',
          2,
          [(x: 5, y: 7, width: 2, height: 2)],
          gradientZ: -.5,
          originZ: 7,
        ),
      ],
    );
    expect(map.spatialScene!.worldHeightAt(5.5, 7.5), 1.75);
    final result = computeHeightStepEdges(map, lowerHeight: 1, upperHeight: 2);
    expect(result.status, SpatialIntentResolutionState.resolved);
    final stroke = result.strokes.single;
    expect(stroke.first, const GridPos(x: 5, y: 7));
    expect(stroke.last, const GridPos(x: 7, y: 7));
    final touched = {
      for (final edge in edgesOf(result)) ...[edge.$1, edge.$2],
    };
    for (final vertex in const [
      GridPos(x: 5, y: 8),
      GridPos(x: 5, y: 9),
      GridPos(x: 6, y: 7),
      GridPos(x: 7, y: 8),
      GridPos(x: 7, y: 9),
    ]) {
      expect(touched, isNot(contains(vertex)));
    }
  });
}
