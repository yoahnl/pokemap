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
}
