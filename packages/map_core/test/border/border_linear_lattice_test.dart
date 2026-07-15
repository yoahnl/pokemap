import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/border_linear_stroke_golden.dart';

void main() {
  group('buildBorderLinearLatticeV1', () {
    test('builds canonical edges and rectangular pixel abscissas', () {
      final stroke = BorderStroke(
        id: 'elbow',
        points: const <GridPos>[
          GridPos(x: 2, y: 3),
          GridPos(x: 2, y: 2),
          GridPos(x: 2, y: 1),
          GridPos(x: 1, y: 1),
        ],
        closed: false,
      );

      final lattice = buildBorderLinearLatticeV1(
        stroke: stroke,
        tileSizePx: const GridSize(width: 7, height: 11),
      );

      expect(lattice.strokeId, 'elbow');
      expect(lattice.closed, isFalse);
      expect(lattice.totalLengthPx, 29);
      expect(
        lattice.edges.map(
          (edge) => (
            edge.startCell,
            edge.endCell,
            edge.direction,
            edge.startAbscissaPx,
            edge.endAbscissaPx,
          ),
        ),
        borderRectangularElbowLatticeGolden,
      );
      expect(lattice.nodes.map((node) => node.cell),
          borderCanonicalOpenElbowGolden);
      expect(lattice.nodes.map((node) => node.kind), <BorderLinearNodeKind>[
        BorderLinearNodeKind.endpoint,
        BorderLinearNodeKind.corner,
        BorderLinearNodeKind.straight,
        BorderLinearNodeKind.endpoint,
      ]);
      expect(
        lattice.nodes.map((node) => node.termination),
        <BorderLinearTerminationNeed>[
          BorderLinearTerminationNeed.startCap,
          BorderLinearTerminationNeed.none,
          BorderLinearTerminationNeed.none,
          BorderLinearTerminationNeed.endCap,
        ],
      );
      expect(
        lattice.nodes.map((node) => node.abscissaPx),
        <int>[0, 7, 18, 29],
      );
      expect(lattice.nodes.first.incomingDirection, isNull);
      expect(
        lattice.nodes.first.outgoingDirection,
        BorderCardinalDirection.east,
      );
      expect(
        lattice.nodes.last.incomingDirection,
        BorderCardinalDirection.south,
      );
      expect(lattice.nodes.last.outgoingDirection, isNull);
      expect(() => lattice.edges.clear(), throwsUnsupportedError);
      expect(() => lattice.nodes.clear(), throwsUnsupportedError);
    });

    test('adds the implicit closing edge on a circular domain', () {
      final lattice = buildBorderLinearLatticeV1(
        stroke: BorderStroke(
          id: 'loop',
          points: const <GridPos>[
            GridPos(x: 1, y: 1),
            GridPos(x: 2, y: 1),
            GridPos(x: 2, y: 2),
            GridPos(x: 1, y: 2),
          ],
          closed: true,
        ),
        tileSizePx: const GridSize(width: 5, height: 9),
      );

      expect(lattice.edges, hasLength(4));
      expect(lattice.totalLengthPx, 28);
      expect(lattice.edges.last.startCell, const GridPos(x: 1, y: 2));
      expect(lattice.edges.last.endCell, const GridPos(x: 1, y: 1));
      expect(
        lattice.edges.last.direction,
        BorderCardinalDirection.north,
      );
      expect(lattice.edges.last.startAbscissaPx, 19);
      expect(lattice.edges.last.endAbscissaPx, 28);
      expect(lattice.edges.last.endNodeIndex, 0);
      expect(
        lattice.nodes.map((node) => node.kind),
        everyElement(BorderLinearNodeKind.corner),
      );
      expect(
        lattice.nodes.map((node) => node.termination),
        everyElement(BorderLinearTerminationNeed.none),
      );
      expect(
        lattice.nodes.first.incomingDirection,
        BorderCardinalDirection.north,
      );
      expect(
        lattice.nodes.first.outgoingDirection,
        BorderCardinalDirection.east,
      );
    });

    test('rejects non-positive tile dimensions', () {
      final stroke = BorderStroke(
        id: 'line',
        points: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
        ],
        closed: false,
      );

      for (final size in const <GridSize>[
        GridSize(width: 0, height: 16),
        GridSize(width: 16, height: 0),
        GridSize(width: -1, height: 16),
      ]) {
        expect(
          () => buildBorderLinearLatticeV1(
            stroke: stroke,
            tileSizePx: size,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('exposes only endpoint, straight, corner, and cap needs', () {
      expect(
        BorderLinearNodeKind.values,
        <BorderLinearNodeKind>[
          BorderLinearNodeKind.endpoint,
          BorderLinearNodeKind.straight,
          BorderLinearNodeKind.corner,
        ],
      );
      expect(
        BorderLinearTerminationNeed.values,
        <BorderLinearTerminationNeed>[
          BorderLinearTerminationNeed.none,
          BorderLinearTerminationNeed.startCap,
          BorderLinearTerminationNeed.endCap,
        ],
      );
    });
  });
}
