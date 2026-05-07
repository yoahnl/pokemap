import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/environment_mask_brush_footprint_resolver.dart';

void main() {
  group('resolveEnvironmentMaskBrushFootprint', () {
    test('size 1 retourne exactement la cellule centrale', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 5, height: 5),
        center: const GridPos(x: 2, y: 2),
        brushSize: 1,
      );

      expect(footprint.cells, const [GridPos(x: 2, y: 2)]);
    });

    test('size 3 retourne un carré 3x3 stable en ordre row-major', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 5, height: 5),
        center: const GridPos(x: 2, y: 2),
        brushSize: 3,
      );

      expect(footprint.cells, const [
        GridPos(x: 1, y: 1),
        GridPos(x: 2, y: 1),
        GridPos(x: 3, y: 1),
        GridPos(x: 1, y: 2),
        GridPos(x: 2, y: 2),
        GridPos(x: 3, y: 2),
        GridPos(x: 1, y: 3),
        GridPos(x: 2, y: 3),
        GridPos(x: 3, y: 3),
      ]);
    });

    test('size 5 retourne un carré 5x5 stable', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 7, height: 7),
        center: const GridPos(x: 3, y: 3),
        brushSize: 5,
      );

      expect(footprint.cells.length, 25);
      expect(footprint.cells.first, const GridPos(x: 1, y: 1));
      expect(footprint.cells[4], const GridPos(x: 5, y: 1));
      expect(footprint.cells[20], const GridPos(x: 1, y: 5));
      expect(footprint.cells.last, const GridPos(x: 5, y: 5));
    });

    test('size 7 retourne un carré 7x7 stable', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 9, height: 9),
        center: const GridPos(x: 4, y: 4),
        brushSize: 7,
      );

      expect(footprint.cells.length, 49);
      expect(footprint.cells.first, const GridPos(x: 1, y: 1));
      expect(footprint.cells[6], const GridPos(x: 7, y: 1));
      expect(footprint.cells[42], const GridPos(x: 1, y: 7));
      expect(footprint.cells.last, const GridPos(x: 7, y: 7));
    });

    test('bord de map clippe correctement', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 4, height: 4),
        center: const GridPos(x: 0, y: 0),
        brushSize: 5,
      );

      expect(footprint.cells, const [
        GridPos(x: 0, y: 0),
        GridPos(x: 1, y: 0),
        GridPos(x: 2, y: 0),
        GridPos(x: 0, y: 1),
        GridPos(x: 1, y: 1),
        GridPos(x: 2, y: 1),
        GridPos(x: 0, y: 2),
        GridPos(x: 1, y: 2),
        GridPos(x: 2, y: 2),
      ]);
    });

    test('centre hors map retourne vide', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 4, height: 4),
        center: const GridPos(x: -1, y: 0),
        brushSize: 3,
      );

      expect(footprint.cells, isEmpty);
    });

    test('tailles invalides refusées', () {
      for (final size in [0, 2, 4, 8]) {
        expect(
          () => resolveEnvironmentMaskBrushFootprint(
            mapSize: const GridSize(width: 4, height: 4),
            center: const GridPos(x: 1, y: 1),
            brushSize: size,
          ),
          throwsA(isA<EditorValidationException>()),
        );
      }
    });
  });
}
