import 'package:map_core/map_core.dart';

GridPos? resolveConnectedMapTargetPos({
  required GridPos sourcePos,
  required GridSize sourceSize,
  required GridSize targetSize,
  required MapConnectionDirection direction,
  required int offset,
}) {
  if (!_isSourceBorderCell(
    sourcePos: sourcePos,
    sourceSize: sourceSize,
    direction: direction,
  )) {
    return null;
  }

  final targetPos = switch (direction) {
    MapConnectionDirection.east => GridPos(
        x: 0,
        y: sourcePos.y - offset,
      ),
    MapConnectionDirection.west => GridPos(
        x: targetSize.width - 1,
        y: sourcePos.y - offset,
      ),
    MapConnectionDirection.north => GridPos(
        x: sourcePos.x - offset,
        y: targetSize.height - 1,
      ),
    MapConnectionDirection.south => GridPos(
        x: sourcePos.x - offset,
        y: 0,
      ),
  };

  if (!_isInBounds(targetPos, targetSize)) {
    return null;
  }
  return targetPos;
}

bool _isSourceBorderCell({
  required GridPos sourcePos,
  required GridSize sourceSize,
  required MapConnectionDirection direction,
}) {
  if (!_isInBounds(sourcePos, sourceSize)) {
    return false;
  }
  return switch (direction) {
    MapConnectionDirection.north => sourcePos.y == 0,
    MapConnectionDirection.south => sourcePos.y == sourceSize.height - 1,
    MapConnectionDirection.east => sourcePos.x == sourceSize.width - 1,
    MapConnectionDirection.west => sourcePos.x == 0,
  };
}

bool _isInBounds(GridPos pos, GridSize size) {
  return pos.x >= 0 && pos.y >= 0 && pos.x < size.width && pos.y < size.height;
}
