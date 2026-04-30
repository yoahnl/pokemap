import 'project_manifest.dart';

/// Local size of a repeated path center pattern.
final class PathCenterPatternSize {
  factory PathCenterPatternSize({
    required int width,
    required int height,
  }) {
    if (width <= 0) {
      throw ArgumentError.value(
        width,
        'width',
        'PathCenterPatternSize width must be positive.',
      );
    }
    if (height <= 0) {
      throw ArgumentError.value(
        height,
        'height',
        'PathCenterPatternSize height must be positive.',
      );
    }
    return PathCenterPatternSize._(width: width, height: height);
  }

  const PathCenterPatternSize._({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;

  int get tileCount => width * height;

  bool contains(int localX, int localY) {
    return localX >= 0 && localY >= 0 && localX < width && localY < height;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathCenterPatternSize &&
            width == other.width &&
            height == other.height;
  }

  @override
  int get hashCode => Object.hash(width, height);
}

/// One local cell of a path center pattern.
final class PathCenterPatternCell {
  factory PathCenterPatternCell({
    required int localX,
    required int localY,
    required List<TilesetVisualFrame> frames,
  }) {
    if (localX < 0) {
      throw ArgumentError.value(
        localX,
        'localX',
        'PathCenterPatternCell localX must be non-negative.',
      );
    }
    if (localY < 0) {
      throw ArgumentError.value(
        localY,
        'localY',
        'PathCenterPatternCell localY must be non-negative.',
      );
    }
    if (frames.isEmpty) {
      throw ArgumentError.value(
        frames,
        'frames',
        'PathCenterPatternCell frames must not be empty.',
      );
    }
    return PathCenterPatternCell._(
      localX: localX,
      localY: localY,
      frames: List.unmodifiable(frames),
    );
  }

  const PathCenterPatternCell._({
    required this.localX,
    required this.localY,
    required this.frames,
  });

  final int localX;
  final int localY;
  final List<TilesetVisualFrame> frames;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathCenterPatternCell &&
            localX == other.localX &&
            localY == other.localY &&
            _listEquals(frames, other.frames);
  }

  @override
  int get hashCode => Object.hash(localX, localY, Object.hashAll(frames));
}

/// Complete local pattern used for the fill center of a path surface.
final class PathCenterPattern {
  factory PathCenterPattern({
    required PathCenterPatternSize size,
    required List<PathCenterPatternCell> cells,
  }) {
    if (cells.isEmpty) {
      throw ArgumentError.value(
        cells,
        'cells',
        'PathCenterPattern cells must not be empty.',
      );
    }

    final cellsByIndex = <int, PathCenterPatternCell>{};
    for (final cell in cells) {
      if (!size.contains(cell.localX, cell.localY)) {
        throw ArgumentError.value(
          cell,
          'cells',
          'PathCenterPattern has cell outside size at '
              '${cell.localX},${cell.localY}.',
        );
      }

      final index = _cellIndex(size, cell.localX, cell.localY);
      if (cellsByIndex.containsKey(index)) {
        throw ArgumentError.value(
          cell,
          'cells',
          'PathCenterPattern has duplicate cell at '
              '${cell.localX},${cell.localY}.',
        );
      }
      cellsByIndex[index] = cell;
    }

    final orderedCells = <PathCenterPatternCell>[];
    for (var y = 0; y < size.height; y += 1) {
      for (var x = 0; x < size.width; x += 1) {
        final index = _cellIndex(size, x, y);
        final cell = cellsByIndex[index];
        if (cell == null) {
          throw ArgumentError.value(
            cells,
            'cells',
            'PathCenterPattern has missing cell at $x,$y.',
          );
        }
        orderedCells.add(cell);
      }
    }

    return PathCenterPattern._(
      size: size,
      cells: List.unmodifiable(orderedCells),
      cellsByIndex: Map.unmodifiable(cellsByIndex),
    );
  }

  const PathCenterPattern._({
    required this.size,
    required this.cells,
    required Map<int, PathCenterPatternCell> cellsByIndex,
  }) : _cellsByIndex = cellsByIndex;

  final PathCenterPatternSize size;
  final List<PathCenterPatternCell> cells;
  final Map<int, PathCenterPatternCell> _cellsByIndex;

  bool get isSingleCell => size.tileCount == 1;

  bool get isMultiCell => size.tileCount > 1;

  PathCenterPatternCell cellAt(int localX, int localY) {
    if (!size.contains(localX, localY)) {
      throw ArgumentError.value(
        '$localX,$localY',
        'local coordinate',
        'PathCenterPattern cellAt coordinate is outside size.',
      );
    }
    return _cellsByIndex[_cellIndex(size, localX, localY)]!;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathCenterPattern &&
            size == other.size &&
            _listEquals(cells, other.cells);
  }

  @override
  int get hashCode => Object.hash(size, Object.hashAll(cells));
}

int _cellIndex(PathCenterPatternSize size, int localX, int localY) {
  return localY * size.width + localX;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
