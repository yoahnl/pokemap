import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';

int resolvePathCardinalMaskAt({
  required List<bool> cells,
  required GridSize mapSize,
  required GridPos pos,
}) {
  _validatePathGrid(cells: cells, mapSize: mapSize, pos: pos);
  return _resolveCardinalMaskAt(
    pos: pos,
    matchesAt: (x, y) => _matchesPathCellAt(
      cells: cells,
      mapSize: mapSize,
      x: x,
      y: y,
    ),
  );
}

TerrainPathVariant resolvePathVariantFromMask(int mask) {
  return switch (mask) {
    0 => TerrainPathVariant.isolated,
    1 => TerrainPathVariant.endNorth,
    2 => TerrainPathVariant.endEast,
    3 => TerrainPathVariant.cornerNE,
    4 => TerrainPathVariant.endSouth,
    5 => TerrainPathVariant.vertical,
    6 => TerrainPathVariant.cornerSE,
    7 => TerrainPathVariant.teeEast,
    8 => TerrainPathVariant.endWest,
    9 => TerrainPathVariant.cornerNW,
    10 => TerrainPathVariant.horizontal,
    11 => TerrainPathVariant.teeNorth,
    12 => TerrainPathVariant.cornerSW,
    13 => TerrainPathVariant.teeWest,
    14 => TerrainPathVariant.teeSouth,
    15 => TerrainPathVariant.cross,
    _ => throw ValidationException('Invalid path cardinal mask: $mask'),
  };
}

TerrainPathVariant resolvePathVariantAt({
  required List<bool> cells,
  required GridSize mapSize,
  required GridPos pos,
}) {
  _validatePathGrid(cells: cells, mapSize: mapSize, pos: pos);
  return _resolvePathVariantAt(
    mapSize: mapSize,
    pos: pos,
    maskResolver: () => _resolveCardinalMaskAt(
      pos: pos,
      matchesAt: (x, y) => _matchesPathCellAt(
        cells: cells,
        mapSize: mapSize,
        x: x,
        y: y,
      ),
    ),
    matchesAt: (x, y) => _matchesPathCellAt(
      cells: cells,
      mapSize: mapSize,
      x: x,
      y: y,
    ),
  );
}

int resolveTerrainCardinalMaskAt({
  required List<TerrainType> terrains,
  required GridSize mapSize,
  required GridPos pos,
  TerrainType terrain = TerrainType.grass,
}) {
  _validateTerrainGrid(terrains: terrains, mapSize: mapSize, pos: pos);
  return _resolveCardinalMaskAt(
    pos: pos,
    matchesAt: (x, y) => _matchesTerrainAt(
      terrains: terrains,
      mapSize: mapSize,
      x: x,
      y: y,
      terrain: terrain,
    ),
  );
}

TerrainPathVariant resolveTerrainPathVariantFromMask(int mask) {
  return resolvePathVariantFromMask(mask);
}

TerrainPathVariant resolveTerrainPathVariantAt({
  required List<TerrainType> terrains,
  required GridSize mapSize,
  required GridPos pos,
  TerrainType terrain = TerrainType.grass,
}) {
  _validateTerrainGrid(terrains: terrains, mapSize: mapSize, pos: pos);
  return _resolvePathVariantAt(
    mapSize: mapSize,
    pos: pos,
    maskResolver: () => _resolveCardinalMaskAt(
      pos: pos,
      matchesAt: (x, y) => _matchesTerrainAt(
        terrains: terrains,
        mapSize: mapSize,
        x: x,
        y: y,
        terrain: terrain,
      ),
    ),
    matchesAt: (x, y) => _matchesTerrainAt(
      terrains: terrains,
      mapSize: mapSize,
      x: x,
      y: y,
      terrain: terrain,
    ),
  );
}

TerrainPathVariant _resolvePathVariantAt({
  required GridSize mapSize,
  required GridPos pos,
  required int Function() maskResolver,
  required bool Function(int x, int y) matchesAt,
}) {
  final mask = maskResolver();
  final base = resolvePathVariantFromMask(mask);
  final edgeCornerReplacement = _resolveEdgeCornerAsBorderVariant(
    mapSize: mapSize,
    pos: pos,
    base: base,
  );
  if (edgeCornerReplacement != null) {
    return edgeCornerReplacement;
  }
  final connectionCount = _countCardinalConnections(mask);
  if (_shouldUseBorderFillVariant(
    mapSize: mapSize,
    pos: pos,
    mask: mask,
    base: base,
    connectionCount: connectionCount,
  )) {
    return TerrainPathVariant.cross;
  }
  if (mask != 15) {
    return base;
  }

  final hasNE = matchesAt(pos.x + 1, pos.y - 1);
  final hasSE = matchesAt(pos.x + 1, pos.y + 1);
  final hasSW = matchesAt(pos.x - 1, pos.y + 1);
  final hasNW = matchesAt(pos.x - 1, pos.y - 1);

  if (!hasNE && hasSE && hasSW && hasNW) {
    return TerrainPathVariant.innerCornerNE;
  }
  if (hasNE && !hasSE && hasSW && hasNW) {
    return TerrainPathVariant.innerCornerSE;
  }
  if (hasNE && hasSE && !hasSW && hasNW) {
    return TerrainPathVariant.innerCornerSW;
  }
  if (hasNE && hasSE && hasSW && !hasNW) {
    return TerrainPathVariant.innerCornerNW;
  }

  return base;
}

TerrainPathVariant? _resolveEdgeCornerAsBorderVariant({
  required GridSize mapSize,
  required GridPos pos,
  required TerrainPathVariant base,
}) {
  final isCorner = base == TerrainPathVariant.cornerNE ||
      base == TerrainPathVariant.cornerSE ||
      base == TerrainPathVariant.cornerSW ||
      base == TerrainPathVariant.cornerNW;
  if (!isCorner) {
    return null;
  }

  final touchesNorth = pos.y == 0;
  final touchesEast = pos.x == mapSize.width - 1;
  final touchesSouth = pos.y == mapSize.height - 1;
  final touchesWest = pos.x == 0;
  final touchedEdges = (touchesNorth ? 1 : 0) +
      (touchesEast ? 1 : 0) +
      (touchesSouth ? 1 : 0) +
      (touchesWest ? 1 : 0);

  if (touchedEdges != 1) {
    return null;
  }

  if (touchesNorth) {
    if (base == TerrainPathVariant.cornerSE) {
      return TerrainPathVariant.endEast;
    }
    if (base == TerrainPathVariant.cornerSW) {
      return TerrainPathVariant.endWest;
    }
  }
  if (touchesEast) {
    if (base == TerrainPathVariant.cornerSW) {
      return TerrainPathVariant.endSouth;
    }
    if (base == TerrainPathVariant.cornerNW) {
      return TerrainPathVariant.endNorth;
    }
  }
  if (touchesSouth) {
    if (base == TerrainPathVariant.cornerNE) {
      return TerrainPathVariant.endEast;
    }
    if (base == TerrainPathVariant.cornerNW) {
      return TerrainPathVariant.endWest;
    }
  }
  if (touchesWest) {
    if (base == TerrainPathVariant.cornerSE) {
      return TerrainPathVariant.endSouth;
    }
    if (base == TerrainPathVariant.cornerNE) {
      return TerrainPathVariant.endNorth;
    }
  }
  return null;
}

int _countCardinalConnections(int mask) {
  var count = 0;
  if ((mask & 1) != 0) count++;
  if ((mask & 2) != 0) count++;
  if ((mask & 4) != 0) count++;
  if ((mask & 8) != 0) count++;
  return count;
}

bool _shouldUseBorderFillVariant({
  required GridSize mapSize,
  required GridPos pos,
  required int mask,
  required TerrainPathVariant base,
  required int connectionCount,
}) {
  if (connectionCount <= 1) {
    return false;
  }
  if (!_isMidPathVariant(base)) {
    return false;
  }

  final northConnected = (mask & 1) != 0;
  final eastConnected = (mask & 2) != 0;
  final southConnected = (mask & 4) != 0;
  final westConnected = (mask & 8) != 0;

  final touchesNorth = pos.y == 0;
  final touchesEast = pos.x == mapSize.width - 1;
  final touchesSouth = pos.y == mapSize.height - 1;
  final touchesWest = pos.x == 0;

  return (touchesNorth && !northConnected) ||
      (touchesEast && !eastConnected) ||
      (touchesSouth && !southConnected) ||
      (touchesWest && !westConnected);
}

bool _isMidPathVariant(TerrainPathVariant variant) {
  return variant == TerrainPathVariant.horizontal ||
      variant == TerrainPathVariant.vertical ||
      variant == TerrainPathVariant.teeNorth ||
      variant == TerrainPathVariant.teeEast ||
      variant == TerrainPathVariant.teeSouth ||
      variant == TerrainPathVariant.teeWest;
}

void _validatePathGrid({
  required List<bool> cells,
  required GridSize mapSize,
  required GridPos pos,
}) {
  if (mapSize.width <= 0 || mapSize.height <= 0) {
    throw const ValidationException('Map size must be positive');
  }
  final expectedLength = mapSize.width * mapSize.height;
  if (cells.length < expectedLength) {
    throw ValidationException(
      'Path grid is incomplete: expected $expectedLength cells, got ${cells.length}',
    );
  }
  if (pos.x < 0 ||
      pos.y < 0 ||
      pos.x >= mapSize.width ||
      pos.y >= mapSize.height) {
    throw ValidationException(
        'Position is outside map bounds: (${pos.x}, ${pos.y})');
  }
}

bool _matchesPathCellAt({
  required List<bool> cells,
  required GridSize mapSize,
  required int x,
  required int y,
}) {
  if (x < 0 || y < 0 || x >= mapSize.width || y >= mapSize.height) {
    return false;
  }
  final index = y * mapSize.width + x;
  if (index < 0 || index >= cells.length) {
    return false;
  }
  return cells[index];
}

void _validateTerrainGrid({
  required List<TerrainType> terrains,
  required GridSize mapSize,
  required GridPos pos,
}) {
  final expectedLength = mapSize.width * mapSize.height;
  if (mapSize.width <= 0 || mapSize.height <= 0) {
    throw const ValidationException('Map size must be positive');
  }
  if (terrains.length < expectedLength) {
    throw ValidationException(
      'Terrain grid is incomplete: expected $expectedLength cells, got ${terrains.length}',
    );
  }
  if (pos.x < 0 ||
      pos.y < 0 ||
      pos.x >= mapSize.width ||
      pos.y >= mapSize.height) {
    throw ValidationException(
        'Position is outside map bounds: (${pos.x}, ${pos.y})');
  }
}

bool _matchesTerrainAt({
  required List<TerrainType> terrains,
  required GridSize mapSize,
  required int x,
  required int y,
  required TerrainType terrain,
}) {
  if (x < 0 || y < 0 || x >= mapSize.width || y >= mapSize.height) {
    return false;
  }
  final index = y * mapSize.width + x;
  if (index < 0 || index >= terrains.length) {
    return false;
  }
  return terrains[index] == terrain;
}

int _resolveCardinalMaskAt({
  required GridPos pos,
  required bool Function(int x, int y) matchesAt,
}) {
  var mask = 0;
  if (matchesAt(pos.x, pos.y - 1)) {
    mask |= 1;
  }
  if (matchesAt(pos.x + 1, pos.y)) {
    mask |= 2;
  }
  if (matchesAt(pos.x, pos.y + 1)) {
    mask |= 4;
  }
  if (matchesAt(pos.x - 1, pos.y)) {
    mask |= 8;
  }
  return mask;
}
