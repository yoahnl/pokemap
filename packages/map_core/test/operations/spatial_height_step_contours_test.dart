import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'relief_height_step_characterization_test.dart' show edgesOf, reliefMap;

void main() {
  final twoPlateaus = reliefMap([
    (id: 'west', height: 2, rectangles: [(x: 1, y: 2, width: 3, height: 3)]),
    (id: 'east', height: 2, rectangles: [(x: 6, y: 2, width: 3, height: 3)]),
  ]);

  test('a region holding two plateaus traces both of them', () {
    final result = computeHeightStepEdges(
      twoPlateaus,
      lowerHeight: 1,
      upperHeight: 2,
      region: const MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 12, height: 10),
      ),
    );
    expect(result.strokes, hasLength(2));
  });

  test('painted cells trace only the plateau they belong to', () {
    final result = computeHeightStepEdges(
      twoPlateaus,
      lowerHeight: 1,
      upperHeight: 2,
      cells: const [GridPos(x: 2, y: 3)],
    );
    expect(result.status, SpatialIntentResolutionState.resolved);
    final stroke = result.strokes.single;
    expect(stroke.first, stroke.last);
    expect(stroke.length, 13);
    expect(stroke.every((point) => point.x <= 4), isTrue);
  });

  test('a lowered hole traces its own rim and the surrounding plateau', () {
    final map = reliefMap([
      (
        id: 'plateau',
        height: 2,
        rectangles: [(x: 2, y: 2, width: 7, height: 6)],
      ),
      (id: 'east', height: 2, rectangles: [(x: 10, y: 2, width: 2, height: 2)]),
    ]);
    final holed = paintTerrainCellsAtHeight(map, {
      for (var y = 4; y < 6; y++)
        for (var x = 4; x < 7; x++) GridPos(x: x, y: y),
    }, height: 1).map;
    final result = computeHeightStepEdges(
      holed,
      lowerHeight: 1,
      upperHeight: 2,
      cells: const [GridPos(x: 5, y: 4)],
    );
    expect(result.status, SpatialIntentResolutionState.resolved);
    expect(result.strokes.map((s) => s.length).toList()..sort(), [11, 27]);
    expect(
      result.strokes.expand((s) => s).every((point) => point.x <= 9),
      isTrue,
    );
  });

  test('cells away from the step report no source', () {
    final result = computeHeightStepEdges(
      twoPlateaus,
      lowerHeight: 1,
      upperHeight: 2,
      cells: const [GridPos(x: 11, y: 9)],
    );
    expect(result.status, SpatialIntentResolutionState.noSource);
    expect(result.reason, 'cells_outside_step');
  });

  test('exact steps split a terrace touching the outer contour', () {
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
    HeightStepContours trace(double lower, double upper) =>
        computeHeightStepEdges(
          map,
          lowerHeight: lower,
          upperHeight: upper,
          cells: const [GridPos(x: 3, y: 5)],
          exactHeights: true,
        );
    final low = trace(1, 2), high = trace(2, 3), both = trace(1, 3);
    for (final result in [low, high, both]) {
      expect(result.status, SpatialIntentResolutionState.resolved);
    }
    expect(edgesOf(both), {
      (const GridPos(x: 2, y: 7), const GridPos(x: 2, y: 6)),
      (const GridPos(x: 2, y: 6), const GridPos(x: 2, y: 5)),
      (const GridPos(x: 2, y: 5), const GridPos(x: 2, y: 4)),
    });
    expect(edgesOf(low).intersection(edgesOf(high)), isEmpty);
    expect(edgesOf(low).intersection(edgesOf(both)), isEmpty);
    expect(edgesOf(high).intersection(edgesOf(both)), isEmpty);
    final inclusive = {
      ...edgesOf(computeHeightStepEdges(map, lowerHeight: 1, upperHeight: 2)),
      ...edgesOf(computeHeightStepEdges(map, lowerHeight: 2, upperHeight: 3)),
    };
    expect({...edgesOf(low), ...edgesOf(high), ...edgesOf(both)}, inclusive);
    expect(low.strokes.single.first, const GridPos(x: 2, y: 4));
    expect(low.strokes.single.last, const GridPos(x: 2, y: 7));
    expect(high.strokes.single.first, const GridPos(x: 2, y: 4));
    expect(high.strokes.single.last, const GridPos(x: 2, y: 7));
  });
}
