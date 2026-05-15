import '../exceptions/map_exceptions.dart';
import '../models/element_collision_profile.dart';
import '../models/geometry.dart';
import 'element_collision_mask_codec.dart';

ElementCollisionProfile normalizeElementCollisionProfile(
  ElementCollisionProfile profile, {
  required int tileSize,
}) {
  _validateTileSize(tileSize);

  final collisionMask = profile.collisionMask;
  if (collisionMask != null) {
    return profile.copyWith(
      cells: _sortedCells(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: collisionMask,
          tileWidth: tileSize,
          tileHeight: tileSize,
          sourceWidthInTiles: _ceilDiv(collisionMask.widthPx, tileSize),
          sourceHeightInTiles: _ceilDiv(collisionMask.heightPx, tileSize),
        ),
      ),
    );
  }

  final legacyCells = _normalizeLegacyCells(profile);
  if (legacyCells == null) {
    return profile;
  }

  return profile.copyWith(cells: legacyCells);
}

void _validateTileSize(int tileSize) {
  if (tileSize <= 0) {
    throw ValidationException(
      'Element collision profile tileSize must be strictly positive, got $tileSize',
    );
  }
}

List<GridPos>? _normalizeLegacyCells(ElementCollisionProfile profile) {
  final hasAuthoringIntent = profile.shapeCells.isNotEmpty ||
      profile.manualAddedCells.isNotEmpty ||
      profile.manualRemovedCells.isNotEmpty;
  if (!hasAuthoringIntent) {
    return null;
  }

  final cells = <GridPos>{};
  if (profile.shapeCells.isNotEmpty) {
    cells.addAll(profile.shapeCells);
  } else if (profile.manualAddedCells.isNotEmpty) {
    cells.addAll(profile.manualAddedCells);
  } else {
    cells.addAll(profile.cells);
  }

  cells.addAll(profile.manualAddedCells);
  cells.removeAll(profile.manualRemovedCells);
  return _sortedCells(cells);
}

List<GridPos> _sortedCells(Iterable<GridPos> cells) {
  final sorted = cells.toList(growable: false);
  sorted.sort((a, b) {
    final y = a.y.compareTo(b.y);
    if (y != 0) {
      return y;
    }
    return a.x.compareTo(b.x);
  });
  return sorted;
}

int _ceilDiv(int value, int divisor) {
  if (value <= 0) {
    return 0;
  }
  return (value + divisor - 1) ~/ divisor;
}
