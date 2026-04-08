import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/element_collision_shape_rasterizer_service.dart';

void main() {
  group('ElementCollisionShapeRasterizerService', () {
    const service = ElementCollisionShapeRasterizerService();

    test('rasterizes a simple rectangle polygon into cells', () {
      final cells = service.rasterizePolygon(
        vertices: const <Offset>[
          Offset(0.1, 0.1),
          Offset(2.9, 0.1),
          Offset(2.9, 1.9),
          Offset(0.1, 1.9),
        ],
        gridWidth: 4,
        gridHeight: 4,
      );

      expect(
        cells,
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
        ],
      );
    });

    test('supports a concave polygon without filling the hollow section', () {
      final cells = service.rasterizePolygon(
        vertices: const <Offset>[
          Offset(0, 0),
          Offset(3, 0),
          Offset(3, 1),
          Offset(1, 1),
          Offset(1, 3),
          Offset(0, 3),
        ],
        gridWidth: 4,
        gridHeight: 4,
      );

      expect(
        cells,
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 0, y: 2),
        ],
      );
    });

    test('keeps cells empty when the polygon only grazes them lightly', () {
      final cells = service.rasterizePolygon(
        vertices: const <Offset>[
          Offset(0.0, 0.0),
          Offset(3.0, 0.0),
          Offset(0.4, 0.35),
        ],
        gridWidth: 4,
        gridHeight: 3,
      );

      expect(
        cells,
        isEmpty,
      );
    });

    test('keeps a narrow silhouette tighter than a touch-based fill', () {
      final cells = service.rasterizePolygon(
        vertices: const <Offset>[
          Offset(1.5, 0.0),
          Offset(2.2, 0.4),
          Offset(2.8, 1.5),
          Offset(2.2, 2.6),
          Offset(1.5, 3.0),
          Offset(0.8, 2.6),
          Offset(0.2, 1.5),
          Offset(0.8, 0.4),
        ],
        gridWidth: 4,
        gridHeight: 4,
      );

      expect(
        cells,
        const <GridPos>[
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 1, y: 2),
        ],
      );
      expect(
        cells,
        isNot(
          containsAll(const <GridPos>[
            GridPos(x: 0, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 0, y: 2),
            GridPos(x: 2, y: 2),
          ]),
        ),
      );
    });

    test('rasterizes a brush stroke continuously across dragged cells', () {
      final cells = service.rasterizeBrushStroke(
        points: const <Offset>[
          Offset(0.2, 0.2),
          Offset(2.8, 0.2),
          Offset(2.8, 2.8),
        ],
        gridWidth: 4,
        gridHeight: 4,
      );

      expect(
        cells,
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 2, y: 1),
          GridPos(x: 2, y: 2),
        ],
      );
    });

    test('roof-like polygon on a 6x7 source resolves to a coarse top block',
        () {
      final cells = service.rasterizePolygon(
        vertices: const <Offset>[
          Offset(1.7, 0.2),
          Offset(4.3, 0.2),
          Offset(5.5, 2.1),
          Offset(4.9, 2.9),
          Offset(1.1, 2.9),
          Offset(0.5, 2.1),
        ],
        gridWidth: 6,
        gridHeight: 7,
      );

      // This test documents the real structural limit of the current system:
      // even with a visually sloped roof polygon, the runtime projection can
      // only choose whole cells on a 6x7 lattice. The resulting top roof area
      // therefore becomes a 4x3 block of GridPos, not a smooth slope.
      expect(
        cells,
        const <GridPos>[
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 3, y: 0),
          GridPos(x: 4, y: 0),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 4, y: 1),
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
          GridPos(x: 4, y: 2),
        ],
      );
      expect(cells.length, 12);
    });

    test('clamps out-of-bounds points and keeps output unique + sorted', () {
      final cells = service.rasterizeBrushStroke(
        points: const <Offset>[
          Offset(-5, -5),
          Offset(10, 10),
          Offset(10, 10),
        ],
        gridWidth: 3,
        gridHeight: 3,
      );

      expect(
        cells,
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 2),
        ],
      );
    });
  });
}
