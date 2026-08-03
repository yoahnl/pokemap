import 'dart:math' as math;

final class SmartTileGridDetectionInput {
  const SmartTileGridDetectionInput({
    required this.imageWidth,
    required this.imageHeight,
    this.columnAlphaCoverage,
    this.rowAlphaCoverage,
  });

  final int imageWidth;
  final int imageHeight;
  final List<double>? columnAlphaCoverage;
  final List<double>? rowAlphaCoverage;
}

final class SmartTileGridGeometry {
  const SmartTileGridGeometry({
    required this.imageWidth,
    required this.imageHeight,
    required this.cellWidth,
    required this.cellHeight,
    this.originX = 0,
    this.originY = 0,
    this.marginX = 0,
    this.marginY = 0,
    this.spacingX = 0,
    this.spacingY = 0,
    this.explicitColumns,
    this.explicitRows,
  })  : assert(explicitColumns == null || explicitColumns > 0),
        assert(explicitRows == null || explicitRows > 0);

  final int imageWidth;
  final int imageHeight;
  final int cellWidth;
  final int cellHeight;
  final int originX;
  final int originY;
  final int marginX;
  final int marginY;
  final int spacingX;
  final int spacingY;
  final int? explicitColumns;
  final int? explicitRows;

  int get usableWidth => math.max(0, imageWidth - originX - marginX);
  int get usableHeight => math.max(0, imageHeight - originY - marginY);

  int get columns =>
      explicitColumns ??
      _axisCellCount(
        usableExtent: usableWidth,
        cellExtent: cellWidth,
        spacing: spacingX,
      );

  int get rows =>
      explicitRows ??
      _axisCellCount(
        usableExtent: usableHeight,
        cellExtent: cellHeight,
        spacing: spacingY,
      );

  int get trailingX =>
      usableWidth -
      _usedExtent(
        count: columns,
        cellExtent: cellWidth,
        spacing: spacingX,
      );

  int get trailingY =>
      usableHeight -
      _usedExtent(
        count: rows,
        cellExtent: cellHeight,
        spacing: spacingY,
      );

  bool get hasPartialCells =>
      columns == 0 || rows == 0 || trailingX != marginX || trailingY != marginY;

  bool get isWithinImage =>
      columns > 0 && rows > 0 && trailingX >= 0 && trailingY >= 0;

  SmartTileGridGeometry copyWith({
    int? imageWidth,
    int? imageHeight,
    int? cellWidth,
    int? cellHeight,
    int? originX,
    int? originY,
    int? marginX,
    int? marginY,
    int? spacingX,
    int? spacingY,
    int? explicitColumns,
    int? explicitRows,
  }) {
    return SmartTileGridGeometry(
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      cellWidth: cellWidth ?? this.cellWidth,
      cellHeight: cellHeight ?? this.cellHeight,
      originX: originX ?? this.originX,
      originY: originY ?? this.originY,
      marginX: marginX ?? this.marginX,
      marginY: marginY ?? this.marginY,
      spacingX: spacingX ?? this.spacingX,
      spacingY: spacingY ?? this.spacingY,
      explicitColumns: explicitColumns ?? this.explicitColumns,
      explicitRows: explicitRows ?? this.explicitRows,
    );
  }
}

final class SmartTileGridCandidate {
  const SmartTileGridCandidate({
    required this.geometry,
    required this.confidence,
    required this.reason,
  });

  final SmartTileGridGeometry geometry;
  final double confidence;
  final String reason;
}

final class SmartTileGridDetector {
  const SmartTileGridDetector();

  static const List<int> _commonCellSizes = <int>[
    32,
    16,
    24,
    48,
    64,
    8,
    96,
    128,
  ];

  List<SmartTileGridCandidate> detect(SmartTileGridDetectionInput input) {
    _validateInput(input);
    final candidates = <SmartTileGridCandidate>[];
    final transparentCandidate = _fromTransparentSeparators(input);
    if (transparentCandidate != null) {
      candidates.add(transparentCandidate);
    }
    for (final cellSize in _commonCellSizes) {
      if (cellSize > input.imageWidth || cellSize > input.imageHeight) {
        continue;
      }
      final geometry = SmartTileGridGeometry(
        imageWidth: input.imageWidth,
        imageHeight: input.imageHeight,
        cellWidth: cellSize,
        cellHeight: cellSize,
      );
      final exact = !geometry.hasPartialCells;
      final commonBonus = cellSize == 32 ? 0.08 : 0;
      candidates.add(
        SmartTileGridCandidate(
          geometry: geometry,
          confidence: (exact ? 0.82 : 0.42) + commonBonus,
          reason: exact
              ? 'La taille de l’image est divisible par $cellSize px.'
              : 'Grille $cellSize px proposée avec cellules partielles.',
        ),
      );
    }
    candidates.sort((left, right) {
      final confidence = right.confidence.compareTo(left.confidence);
      if (confidence != 0) {
        return confidence;
      }
      return right.geometry.cellWidth.compareTo(left.geometry.cellWidth);
    });
    return List<SmartTileGridCandidate>.unmodifiable(candidates);
  }

  void _validateInput(SmartTileGridDetectionInput input) {
    if (input.imageWidth <= 0 || input.imageHeight <= 0) {
      throw ArgumentError('Image dimensions must be positive.');
    }
    final columns = input.columnAlphaCoverage;
    if (columns != null && columns.length != input.imageWidth) {
      throw ArgumentError(
        'columnAlphaCoverage must contain one value per image column.',
      );
    }
    final rows = input.rowAlphaCoverage;
    if (rows != null && rows.length != input.imageHeight) {
      throw ArgumentError(
        'rowAlphaCoverage must contain one value per image row.',
      );
    }
  }

  SmartTileGridCandidate? _fromTransparentSeparators(
    SmartTileGridDetectionInput input,
  ) {
    final columns = input.columnAlphaCoverage;
    final rows = input.rowAlphaCoverage;
    if (columns == null || rows == null) {
      return null;
    }
    final horizontal = _analyzeAxis(columns);
    final vertical = _analyzeAxis(rows);
    if (horizontal == null || vertical == null) {
      return null;
    }
    return SmartTileGridCandidate(
      geometry: SmartTileGridGeometry(
        imageWidth: input.imageWidth,
        imageHeight: input.imageHeight,
        cellWidth: horizontal.cellExtent,
        cellHeight: vertical.cellExtent,
        marginX: horizontal.leadingMargin,
        marginY: vertical.leadingMargin,
        spacingX: horizontal.spacing,
        spacingY: vertical.spacing,
      ),
      confidence: 0.98,
      reason: 'Marges et séparateurs transparents réguliers détectés.',
    );
  }
}

final class _AxisPattern {
  const _AxisPattern({
    required this.cellExtent,
    required this.leadingMargin,
    required this.spacing,
  });

  final int cellExtent;
  final int leadingMargin;
  final int spacing;
}

_AxisPattern? _analyzeAxis(List<double> coverage) {
  const threshold = 0.01;
  final occupiedRuns = <({int start, int end})>[];
  var index = 0;
  while (index < coverage.length) {
    while (index < coverage.length && coverage[index] <= threshold) {
      index += 1;
    }
    if (index >= coverage.length) {
      break;
    }
    final start = index;
    while (index < coverage.length && coverage[index] > threshold) {
      index += 1;
    }
    occupiedRuns.add((start: start, end: index));
  }
  if (occupiedRuns.length < 2) {
    return null;
  }
  final cellExtents =
      occupiedRuns.map((run) => run.end - run.start).toList(growable: false);
  final gaps = <int>[
    for (var run = 1; run < occupiedRuns.length; run += 1)
      occupiedRuns[run].start - occupiedRuns[run - 1].end,
  ];
  final cellExtent = _mode(cellExtents);
  final spacing = _mode(gaps);
  if (cellExtent <= 0 || spacing < 0) {
    return null;
  }
  final regularCells = cellExtents.every((value) => value == cellExtent);
  final regularGaps = gaps.every((value) => value == spacing);
  if (!regularCells || !regularGaps) {
    return null;
  }
  return _AxisPattern(
    cellExtent: cellExtent,
    leadingMargin: occupiedRuns.first.start,
    spacing: spacing,
  );
}

int _mode(List<int> values) {
  final counts = <int, int>{};
  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts.entries.reduce((left, right) {
    if (right.value > left.value) {
      return right;
    }
    if (right.value == left.value && right.key < left.key) {
      return right;
    }
    return left;
  }).key;
}

int _axisCellCount({
  required int usableExtent,
  required int cellExtent,
  required int spacing,
}) {
  if (usableExtent <= 0 || cellExtent <= 0 || spacing < 0) {
    return 0;
  }
  return (usableExtent + spacing) ~/ (cellExtent + spacing);
}

int _usedExtent({
  required int count,
  required int cellExtent,
  required int spacing,
}) {
  if (count <= 0) {
    return 0;
  }
  return count * cellExtent + (count - 1) * spacing;
}
