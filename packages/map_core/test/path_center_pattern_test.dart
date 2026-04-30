import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PathCenterPatternSize', () {
    test('accepts 1x1 and 2x2 sizes', () {
      final single = PathCenterPatternSize(width: 1, height: 1);
      final square = PathCenterPatternSize(width: 2, height: 2);

      expect(single.width, 1);
      expect(single.height, 1);
      expect(square.width, 2);
      expect(square.height, 2);
    });

    test('rejects non-positive dimensions', () {
      expect(
        () => PathCenterPatternSize(width: 0, height: 1),
        throwsArgumentError,
      );
      expect(
        () => PathCenterPatternSize(width: 1, height: 0),
        throwsArgumentError,
      );
      expect(
        () => PathCenterPatternSize(width: -1, height: 1),
        throwsArgumentError,
      );
      expect(
        () => PathCenterPatternSize(width: 1, height: -1),
        throwsArgumentError,
      );
    });

    test('reports tile count and coordinate containment', () {
      final single = PathCenterPatternSize(width: 1, height: 1);
      final square = PathCenterPatternSize(width: 2, height: 2);

      expect(single.tileCount, 1);
      expect(square.tileCount, 4);
      expect(single.contains(0, 0), isTrue);
      expect(single.contains(1, 0), isFalse);
      expect(single.contains(0, 1), isFalse);
      expect(square.contains(1, 1), isTrue);
      expect(square.contains(-1, 0), isFalse);
      expect(square.contains(2, 0), isFalse);
    });

    test('uses value equality and stable hashCode', () {
      final a = PathCenterPatternSize(width: 2, height: 3);
      final b = PathCenterPatternSize(width: 2, height: 3);
      final c = PathCenterPatternSize(width: 3, height: 2);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('PathCenterPatternCell', () {
    test('accepts non-negative local coordinates and frames', () {
      final cell = PathCenterPatternCell(
        localX: 1,
        localY: 2,
        frames: [_frame(sourceX: 4)],
      );

      expect(cell.localX, 1);
      expect(cell.localY, 2);
      expect(cell.frames, [_frame(sourceX: 4)]);
    });

    test('rejects negative coordinates and empty frames', () {
      expect(
        () => PathCenterPatternCell(
          localX: -1,
          localY: 0,
          frames: [_frame()],
        ),
        throwsArgumentError,
      );
      expect(
        () => PathCenterPatternCell(
          localX: 0,
          localY: -1,
          frames: [_frame()],
        ),
        throwsArgumentError,
      );
      expect(
        () => PathCenterPatternCell(localX: 0, localY: 0, frames: []),
        throwsArgumentError,
      );
    });

    test('defensively copies frames and exposes an immutable list', () {
      final frames = [_frame(sourceX: 1)];
      final cell = PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: frames,
      );

      frames.add(_frame(sourceX: 2));

      expect(cell.frames, [_frame(sourceX: 1)]);
      expect(() => cell.frames.add(_frame(sourceX: 3)), throwsUnsupportedError);
    });

    test('uses value equality and stable hashCode', () {
      final a = PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: [_frame(sourceX: 7)],
      );
      final b = PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: [_frame(sourceX: 7)],
      );
      final c = PathCenterPatternCell(
        localX: 1,
        localY: 0,
        frames: [_frame(sourceX: 7)],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('PathCenterPattern 1x1', () {
    test('accepts a complete single-cell grid', () {
      final cell = _cell(0, 0, sourceX: 3);
      final pattern = PathCenterPattern(
        size: PathCenterPatternSize(width: 1, height: 1),
        cells: [cell],
      );

      expect(pattern.cells, [cell]);
      expect(pattern.cellAt(0, 0), cell);
      expect(pattern.isSingleCell, isTrue);
      expect(pattern.isMultiCell, isFalse);
    });
  });

  group('PathCenterPattern 2x2', () {
    test('accepts a complete grid and exposes cells in row-major order', () {
      final topLeft = _cell(0, 0, sourceX: 0);
      final topRight = _cell(1, 0, sourceX: 1);
      final bottomLeft = _cell(0, 1, sourceX: 2);
      final bottomRight = _cell(1, 1, sourceX: 3);

      final pattern = PathCenterPattern(
        size: PathCenterPatternSize(width: 2, height: 2),
        cells: [bottomRight, topLeft, bottomLeft, topRight],
      );

      expect(pattern.cells, [topLeft, topRight, bottomLeft, bottomRight]);
      expect(pattern.cellAt(0, 0), topLeft);
      expect(pattern.cellAt(1, 0), topRight);
      expect(pattern.cellAt(0, 1), bottomLeft);
      expect(pattern.cellAt(1, 1), bottomRight);
      expect(pattern.isSingleCell, isFalse);
      expect(pattern.isMultiCell, isTrue);
    });

    test('defensively copies cells and exposes an immutable list', () {
      final cells = [
        _cell(0, 0, sourceX: 0),
        _cell(1, 0, sourceX: 1),
        _cell(0, 1, sourceX: 2),
        _cell(1, 1, sourceX: 3),
      ];
      final pattern = PathCenterPattern(
        size: PathCenterPatternSize(width: 2, height: 2),
        cells: cells,
      );

      cells[0] = _cell(0, 0, sourceX: 99);

      expect(pattern.cellAt(0, 0), _cell(0, 0, sourceX: 0));
      expect(() => pattern.cells.add(_cell(0, 0)), throwsUnsupportedError);
    });

    test('uses value equality and stable hashCode', () {
      final a = PathCenterPattern(
        size: PathCenterPatternSize(width: 2, height: 2),
        cells: [
          _cell(0, 0, sourceX: 0),
          _cell(1, 0, sourceX: 1),
          _cell(0, 1, sourceX: 2),
          _cell(1, 1, sourceX: 3),
        ],
      );
      final b = PathCenterPattern(
        size: PathCenterPatternSize(width: 2, height: 2),
        cells: [
          _cell(1, 1, sourceX: 3),
          _cell(0, 1, sourceX: 2),
          _cell(1, 0, sourceX: 1),
          _cell(0, 0, sourceX: 0),
        ],
      );
      final c = PathCenterPattern(
        size: PathCenterPatternSize(width: 1, height: 1),
        cells: [_cell(0, 0, sourceX: 0)],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('PathCenterPattern invalid grids', () {
    test('rejects an empty cell list', () {
      expect(
        () => PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a missing cell', () {
      expect(
        () => PathCenterPattern(
          size: PathCenterPatternSize(width: 2, height: 2),
          cells: [
            _cell(0, 0),
            _cell(1, 0),
            _cell(0, 1),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a cell outside the grid', () {
      expect(
        () => PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [_cell(0, 0), _cell(1, 0)],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate coordinates', () {
      expect(
        () => PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [_cell(0, 0, sourceX: 0), _cell(0, 0, sourceX: 1)],
        ),
        throwsArgumentError,
      );
    });

    test('cellAt rejects coordinates outside the grid', () {
      final pattern = PathCenterPattern(
        size: PathCenterPatternSize(width: 1, height: 1),
        cells: [_cell(0, 0)],
      );

      expect(() => pattern.cellAt(-1, 0), throwsArgumentError);
      expect(() => pattern.cellAt(1, 0), throwsArgumentError);
      expect(() => pattern.cellAt(0, 1), throwsArgumentError);
    });
  });
}

PathCenterPatternCell _cell(int localX, int localY, {int sourceX = 0}) {
  return PathCenterPatternCell(
    localX: localX,
    localY: localY,
    frames: [_frame(sourceX: sourceX)],
  );
}

TilesetVisualFrame _frame({int sourceX = 0}) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(x: sourceX, y: 0),
    durationMs: 100,
  );
}
