import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/border_linear_stroke_golden.dart';

void main() {
  group('rasterizeBorderStrokePairV1', () {
    test('is symmetric and walks horizontal then vertical from (y, x) min', () {
      const low = GridPos(x: 1, y: 2);
      const high = GridPos(x: 3, y: 4);
      const expected = <GridPos>[
        GridPos(x: 1, y: 2),
        GridPos(x: 2, y: 2),
        GridPos(x: 3, y: 2),
        GridPos(x: 3, y: 3),
        GridPos(x: 3, y: 4),
      ];

      expect(rasterizeBorderStrokePairV1(low, high), expected);
      expect(
        rasterizeBorderStrokePairV1(high, low),
        expected.reversed,
      );
      expect(
        rasterizeBorderStrokePairV1(high, low),
        rasterizeBorderStrokePairV1(low, high).reversed,
      );
    });

    test('orders equal-row endpoints by x and owns its output', () {
      const right = GridPos(x: 4, y: 3);
      const left = GridPos(x: 1, y: 3);

      final result = rasterizeBorderStrokePairV1(right, left);

      expect(
        result,
        const <GridPos>[
          GridPos(x: 4, y: 3),
          GridPos(x: 3, y: 3),
          GridPos(x: 2, y: 3),
          GridPos(x: 1, y: 3),
        ],
      );
      expect(() => result.add(left), throwsUnsupportedError);
    });
  });

  group('canonicalizeBorderStrokeV1', () {
    test('rasterizes samples, merges joins, and chooses the open minimum', () {
      final samples = <GridPos>[
        const GridPos(x: 3, y: 2),
        const GridPos(x: 1, y: 2),
        const GridPos(x: 1, y: 0),
      ];

      final stroke = canonicalizeBorderStrokeV1(
        id: 'open-west',
        sampledPoints: samples,
        closed: false,
      );
      samples.clear();

      expect(stroke.id, 'open-west');
      expect(stroke.closed, isFalse);
      expect(
        stroke.points,
        const <GridPos>[
          GridPos(x: 1, y: 0),
          GridPos(x: 1, y: 1),
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
        ],
      );
    });

    test('chooses the minimum cyclic rotation across both closed directions',
        () {
      final clockwise = canonicalizeBorderStrokeV1(
        id: 'loop',
        sampledPoints: const <GridPos>[
          GridPos(x: 2, y: 1),
          GridPos(x: 2, y: 2),
          GridPos(x: 1, y: 2),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
        ],
        closed: true,
      );
      final counterClockwise = canonicalizeBorderStrokeV1(
        id: 'loop',
        sampledPoints: const <GridPos>[
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 2, y: 1),
          GridPos(x: 1, y: 1),
        ],
        closed: true,
      );

      expect(clockwise.points, borderCanonicalUnitLoopGolden);
      expect(counterClockwise.points, borderCanonicalUnitLoopGolden);
      expect(clockwise, counterClockwise);
      expect(clockwise.points.first, isNot(clockwise.points.last));
    });

    test('rejects fragments, invalid closure, repeats, crossings, and branches',
        () {
      final invalidCases = <({bool closed, List<GridPos> points})>[
        (
          closed: false,
          points: const <GridPos>[GridPos(x: 0, y: 0)],
        ),
        (
          closed: true,
          points: const <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 2, y: 1),
          ],
        ),
        (
          closed: false,
          points: const <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 1, y: 0),
          ],
        ),
        (
          closed: false,
          points: const <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 2, y: 2),
            GridPos(x: 1, y: 2),
            GridPos(x: 1, y: 1),
          ],
        ),
        (
          closed: false,
          points: const <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 2, y: 1),
            GridPos(x: 1, y: 1),
          ],
        ),
      ];

      for (final invalid in invalidCases) {
        expect(
          () => canonicalizeBorderStrokeV1(
            id: 'invalid',
            sampledPoints: invalid.points,
            closed: invalid.closed,
          ),
          throwsA(isA<ValidationException>()),
          reason: '${invalid.closed}: ${invalid.points}',
        );
      }
    });

    test('preserves the self-cross and implicit-branch diagnostics', () {
      const invalidCases =
          <({bool closed, List<GridPos> points, String message})>[
        (
          closed: false,
          points: <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 2, y: 2),
            GridPos(x: 1, y: 2),
            GridPos(x: 1, y: -1),
          ],
          message:
              'Border V1 strokes must not repeat cells, backtrack, or self-cross',
        ),
        (
          closed: false,
          points: <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 2, y: 1),
            GridPos(x: 1, y: 1),
          ],
          message:
              'Border V1 strokes must not contain implicit branches or crossings',
        ),
        (
          closed: true,
          points: <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 2, y: 1),
            GridPos(x: 1, y: 1),
            GridPos(x: 1, y: 2),
            GridPos(x: 0, y: 2),
            GridPos(x: 0, y: 1),
          ],
          message:
              'Border V1 strokes must not contain implicit branches or crossings',
        ),
      ];

      for (final invalid in invalidCases) {
        expect(
          () => canonicalizeBorderStrokeV1(
            id: 'invalid-diagnostic',
            sampledPoints: invalid.points,
            closed: invalid.closed,
          ),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.message,
              'message',
              invalid.message,
            ),
          ),
        );
      }
    });

    test('validates a 100000-cell open chain within a bounded stress run', () {
      const cellCount = 100000;
      final points = List<GridPos>.generate(
        cellCount,
        (index) => GridPos(x: index, y: 0),
        growable: false,
      );

      final stroke = canonicalizeBorderStrokeV1(
        id: 'stress-open',
        sampledPoints: points,
        closed: false,
      );

      expect(stroke.points, orderedEquals(points));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('canonicalizeBorderStrokeGeometryV1', () {
    test('preserves stroke ids/order and does not mutate input', () {
      final strokes = <BorderStroke>[
        BorderStroke(
          id: 'second-drawn',
          points: const <GridPos>[
            GridPos(x: 4, y: 2),
            GridPos(x: 3, y: 2),
          ],
          closed: false,
        ),
        BorderStroke(
          id: 'first-drawn',
          points: const <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 0, y: 1),
          ],
          closed: false,
        ),
      ];

      final geometry = canonicalizeBorderStrokeGeometryV1(strokes);

      expect(geometry.strokes.map((stroke) => stroke.id),
          <String>['second-drawn', 'first-drawn']);
      expect(
        geometry.strokes.first.points,
        const <GridPos>[GridPos(x: 3, y: 2), GridPos(x: 4, y: 2)],
      );
      expect(strokes.first.points.first, const GridPos(x: 4, y: 2));
      expect(() => geometry.strokes.clear(), throwsUnsupportedError);
    });

    test('rejects strokes with shared cells or edges', () {
      final horizontal = BorderStroke(
        id: 'horizontal',
        points: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
        ],
        closed: false,
      );
      final crossing = BorderStroke(
        id: 'crossing',
        points: const <GridPos>[
          GridPos(x: 1, y: -1),
          GridPos(x: 1, y: 0),
          GridPos(x: 1, y: 1),
        ],
        closed: false,
      );
      final sharedEdge = BorderStroke(
        id: 'shared-edge',
        points: const <GridPos>[
          GridPos(x: 2, y: 0),
          GridPos(x: 1, y: 0),
        ],
        closed: false,
      );

      expect(
        () => canonicalizeBorderStrokeGeometryV1(
          <BorderStroke>[horizontal, crossing],
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => canonicalizeBorderStrokeGeometryV1(
          <BorderStroke>[horizontal, sharedEdge],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
