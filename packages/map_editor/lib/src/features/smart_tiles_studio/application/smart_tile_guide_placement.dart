import 'dart:collection';

import 'smart_tile_grid_detector.dart';
import 'smart_tile_guide.dart';

final class SmartTileGuidePlacedFrame {
  const SmartTileGuidePlacedFrame({
    required this.guideCell,
    required this.column,
    required this.row,
  });

  final SmartTileGuideCell guideCell;
  final int column;
  final int row;
}

final class SmartTileGuidePlacementResult {
  SmartTileGuidePlacementResult({
    required List<SmartTileGuidePlacedFrame> frames,
    required List<int> outOfBoundsNumbers,
  })  : frames = List<SmartTileGuidePlacedFrame>.unmodifiable(frames),
        outOfBoundsNumbers = List<int>.unmodifiable(outOfBoundsNumbers);

  final List<SmartTileGuidePlacedFrame> frames;
  final List<int> outOfBoundsNumbers;

  bool get isValid => outOfBoundsNumbers.isEmpty;

  ({int column, int row}) frameForNumber(int number) {
    final frame = frames.singleWhere(
      (candidate) => candidate.guideCell.number == number,
    );
    return (column: frame.column, row: frame.row);
  }
}

SmartTileGuidePlacementResult placeSmartTileGuide({
  required SmartTileGuideDefinition guide,
  required SmartTileGridGeometry geometry,
  required int anchorColumn,
  required int anchorRow,
}) {
  final projected = <SmartTileGuidePlacedFrame>[
    for (final cell in guide.cells)
      SmartTileGuidePlacedFrame(
        guideCell: cell,
        column: anchorColumn + cell.deltaColumn,
        row: anchorRow + cell.deltaRow,
      ),
  ];
  final outside = <int>[
    for (final frame in projected)
      if (frame.column < 0 ||
          frame.row < 0 ||
          frame.column >= geometry.columns ||
          frame.row >= geometry.rows)
        frame.guideCell.number,
  ]..sort();

  return SmartTileGuidePlacementResult(
    frames: outside.isEmpty ? projected : const <SmartTileGuidePlacedFrame>[],
    outOfBoundsNumbers: UnmodifiableListView<int>(outside),
  );
}
