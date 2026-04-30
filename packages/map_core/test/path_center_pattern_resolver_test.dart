import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolvePathCenterPatternCell 1x1', () {
    test('always resolves to the single local cell', () {
      final pattern = _pattern(width: 1, height: 1);

      _expectResolution(pattern, mapX: 0, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 1, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 0, mapY: 1, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 99, mapY: 42, localX: 0, localY: 0);
    });
  });

  group('resolvePathCenterPatternCell 2x2', () {
    test('uses absolute map coordinates modulo pattern size', () {
      final pattern = _pattern(width: 2, height: 2);

      _expectResolution(pattern, mapX: 0, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 1, mapY: 0, localX: 1, localY: 0);
      _expectResolution(pattern, mapX: 0, mapY: 1, localX: 0, localY: 1);
      _expectResolution(pattern, mapX: 1, mapY: 1, localX: 1, localY: 1);
      _expectResolution(pattern, mapX: 2, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 3, mapY: 0, localX: 1, localY: 0);
      _expectResolution(pattern, mapX: 2, mapY: 1, localX: 0, localY: 1);
      _expectResolution(pattern, mapX: 3, mapY: 1, localX: 1, localY: 1);
      _expectResolution(pattern, mapX: 4, mapY: 4, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 5, mapY: 4, localX: 1, localY: 0);
    });
  });

  group('resolvePathCenterPatternCell rectangular 3x2', () {
    test('does not assume square patterns', () {
      final pattern = _pattern(width: 3, height: 2);

      _expectResolution(pattern, mapX: 0, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 1, mapY: 0, localX: 1, localY: 0);
      _expectResolution(pattern, mapX: 2, mapY: 0, localX: 2, localY: 0);
      _expectResolution(pattern, mapX: 3, mapY: 0, localX: 0, localY: 0);
      _expectResolution(pattern, mapX: 4, mapY: 1, localX: 1, localY: 1);
      _expectResolution(pattern, mapX: 5, mapY: 1, localX: 2, localY: 1);
      _expectResolution(pattern, mapX: 5, mapY: 2, localX: 2, localY: 0);
    });
  });

  group('resolvePathCenterPatternCell invalid coordinates', () {
    test('rejects negative map coordinates', () {
      final pattern = _pattern(width: 2, height: 2);

      expect(
        () => resolvePathCenterPatternCell(
          pattern: pattern,
          mapX: -1,
          mapY: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => resolvePathCenterPatternCell(
          pattern: pattern,
          mapX: 0,
          mapY: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => resolvePathCenterPatternCell(
          pattern: pattern,
          mapX: -1,
          mapY: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('PathCenterPatternCellResolution', () {
    test('keeps map coordinates, local coordinates, and selected cell', () {
      final pattern = _pattern(width: 2, height: 2);

      final resolution = resolvePathCenterPatternCell(
        pattern: pattern,
        mapX: 5,
        mapY: 4,
      );

      expect(resolution.mapX, 5);
      expect(resolution.mapY, 4);
      expect(resolution.localX, 1);
      expect(resolution.localY, 0);
      expect(resolution.cell, pattern.cellAt(1, 0));
      expect(resolution.cell.frames.single.source.x, 1);
    });

    test('uses value equality and stable hashCode', () {
      final pattern = _pattern(width: 2, height: 2);
      final cell = pattern.cellAt(1, 0);

      final a = resolvePathCenterPatternCell(
        pattern: pattern,
        mapX: 5,
        mapY: 4,
      );
      final b = PathCenterPatternCellResolution(
        mapX: 5,
        mapY: 4,
        localX: 1,
        localY: 0,
        cell: cell,
      );
      final c = PathCenterPatternCellResolution(
        mapX: 4,
        mapY: 4,
        localX: 0,
        localY: 0,
        cell: pattern.cellAt(0, 0),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}

void _expectResolution(
  PathCenterPattern pattern, {
  required int mapX,
  required int mapY,
  required int localX,
  required int localY,
}) {
  final resolution = resolvePathCenterPatternCell(
    pattern: pattern,
    mapX: mapX,
    mapY: mapY,
  );

  expect(resolution.mapX, mapX);
  expect(resolution.mapY, mapY);
  expect(resolution.localX, localX);
  expect(resolution.localY, localY);
  expect(resolution.cell, pattern.cellAt(localX, localY));
  expect(resolution.cell.frames.single.source.x, _sourceX(localX, localY));
}

PathCenterPattern _pattern({required int width, required int height}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: width, height: height),
    cells: [
      for (var y = 0; y < height; y += 1)
        for (var x = 0; x < width; x += 1) _cell(x, y),
    ],
  );
}

PathCenterPatternCell _cell(int localX, int localY) {
  return PathCenterPatternCell(
    localX: localX,
    localY: localY,
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: _sourceX(localX, localY), y: 0),
        durationMs: 100,
      ),
    ],
  );
}

int _sourceX(int localX, int localY) => localY * 10 + localX;
