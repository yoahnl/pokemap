import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_region_editing.dart';

void main() {
  group('editBorderRegionCell', () {
    test('paints and erases one row-major cell immutably', () {
      final source = BorderRegionGeometry(
        width: 3,
        height: 2,
        cells: const <bool>[false, false, false, false, false, false],
      );

      final painted = editBorderRegionCell(
        source,
        const GridPos(x: 1, y: 1),
        filled: true,
      );
      final erased = editBorderRegionCell(
        painted,
        const GridPos(x: 1, y: 1),
        filled: false,
      );

      expect(source.cells, everyElement(isFalse));
      expect(painted.cells, <bool>[false, false, false, false, true, false]);
      expect(erased, source);
    });

    test('returns identity for unchanged cells and rejects out-of-map input',
        () {
      final source = BorderRegionGeometry(
        width: 2,
        height: 2,
        cells: const <bool>[true, false, false, false],
      );

      expect(
        editBorderRegionCell(
          source,
          const GridPos(x: 0, y: 0),
          filled: true,
        ),
        same(source),
      );
      expect(
        () => editBorderRegionCell(
          source,
          const GridPos(x: 2, y: 0),
          filled: true,
        ),
        throwsRangeError,
      );
    });
  });

  group('editBorderRegionSegment', () {
    test('rasterizes a fast diagonal drag without cardinal gaps', () {
      final source = BorderRegionGeometry(
        width: 5,
        height: 5,
        cells: List<bool>.filled(25, false),
      );

      final painted = editBorderRegionSegment(
        source,
        const GridPos(x: 0, y: 0),
        const GridPos(x: 4, y: 4),
        filled: true,
      );
      final cells = <GridPos>[
        for (var y = 0; y < 5; y += 1)
          for (var x = 0; x < 5; x += 1)
            if (painted.cells[y * 5 + x]) GridPos(x: x, y: y),
      ];

      expect(cells.first, const GridPos(x: 0, y: 0));
      expect(cells.last, const GridPos(x: 4, y: 4));
      for (var index = 1; index < cells.length; index += 1) {
        final dx = (cells[index].x - cells[index - 1].x).abs();
        final dy = (cells[index].y - cells[index - 1].y).abs();
        expect(dx + dy, 1,
            reason: 'gap at ${cells[index - 1]} -> ${cells[index]}');
      }
      expect(source.cells, everyElement(isFalse));
    });

    test('erases the entire traversed segment immutably', () {
      final source = BorderRegionGeometry(
        width: 5,
        height: 1,
        cells: List<bool>.filled(5, true),
      );

      final erased = editBorderRegionSegment(
        source,
        const GridPos(x: 1, y: 0),
        const GridPos(x: 4, y: 0),
        filled: false,
      );

      expect(erased.cells, const <bool>[true, false, false, false, false]);
      expect(source.cells, everyElement(isTrue));
    });
  });
}
