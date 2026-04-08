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
