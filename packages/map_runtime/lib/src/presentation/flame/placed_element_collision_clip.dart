import 'dart:ui';

import 'package:map_core/map_core.dart';

final class PlacedElementCollisionClip {
  const PlacedElementCollisionClip({
    required this.path,
    required this.sourceCellVisits,
    required this.validCollisionCellCount,
  });

  final Path path;
  final int sourceCellVisits;
  final int validCollisionCellCount;
}

PlacedElementCollisionClip buildPlacedElementCollisionClip({
  required Rect destinationRect,
  required GridSize sourceGridSize,
  required int quarterTurns,
  required Iterable<GridPos> collisionCells,
  required bool includeCollisionCells,
}) {
  final path = Path();
  if (!includeCollisionCells) {
    path
      ..fillType = PathFillType.evenOdd
      ..addRect(destinationRect);
  }
  if (destinationRect.isEmpty ||
      sourceGridSize.width <= 0 ||
      sourceGridSize.height <= 0) {
    return PlacedElementCollisionClip(
      path: path,
      sourceCellVisits: 0,
      validCollisionCellCount: 0,
    );
  }

  final transform = QuarterTurnGridTransform(
    sourceSize: sourceGridSize,
    quarterTurns: quarterTurns,
  );
  final destinationCellWidth =
      destinationRect.width / transform.destinationSize.width;
  final destinationCellHeight =
      destinationRect.height / transform.destinationSize.height;
  final destinations = <GridPos>{};
  var sourceCellVisits = 0;
  for (final source in collisionCells) {
    sourceCellVisits += 1;
    if (source.x < 0 ||
        source.y < 0 ||
        source.x >= sourceGridSize.width ||
        source.y >= sourceGridSize.height) {
      continue;
    }
    destinations.add(transform.sourceToDestination(source));
  }
  for (final destination in destinations) {
    path.addRect(
      Rect.fromLTWH(
        destinationRect.left + destination.x * destinationCellWidth,
        destinationRect.top + destination.y * destinationCellHeight,
        destinationCellWidth,
        destinationCellHeight,
      ),
    );
  }

  return PlacedElementCollisionClip(
    path: path,
    sourceCellVisits: sourceCellVisits,
    validCollisionCellCount: destinations.length,
  );
}
