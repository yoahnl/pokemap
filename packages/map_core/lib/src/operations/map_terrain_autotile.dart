import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';

int resolveTerrainCardinalMaskAt({
  required List<TerrainType> terrains,
  required GridSize mapSize,
  required GridPos pos,
  TerrainType terrain = TerrainType.path,
}) {
  if (mapSize.width <= 0 || mapSize.height <= 0) {
    throw const ValidationException('Map size must be positive');
  }
  final expectedLength = mapSize.width * mapSize.height;
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

  var mask = 0;
  if (_matchesTerrainAt(
    terrains: terrains,
    mapSize: mapSize,
    x: pos.x,
    y: pos.y - 1,
    terrain: terrain,
  )) {
    mask |= 1;
  }
  if (_matchesTerrainAt(
    terrains: terrains,
    mapSize: mapSize,
    x: pos.x + 1,
    y: pos.y,
    terrain: terrain,
  )) {
    mask |= 2;
  }
  if (_matchesTerrainAt(
    terrains: terrains,
    mapSize: mapSize,
    x: pos.x,
    y: pos.y + 1,
    terrain: terrain,
  )) {
    mask |= 4;
  }
  if (_matchesTerrainAt(
    terrains: terrains,
    mapSize: mapSize,
    x: pos.x - 1,
    y: pos.y,
    terrain: terrain,
  )) {
    mask |= 8;
  }

  return mask;
}

TerrainPathVariant resolveTerrainPathVariantFromMask(int mask) {
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
    _ => throw ValidationException('Invalid terrain cardinal mask: $mask'),
  };
}

TerrainPathVariant resolveTerrainPathVariantAt({
  required List<TerrainType> terrains,
  required GridSize mapSize,
  required GridPos pos,
  TerrainType terrain = TerrainType.path,
}) {
  final mask = resolveTerrainCardinalMaskAt(
    terrains: terrains,
    mapSize: mapSize,
    pos: pos,
    terrain: terrain,
  );
  return resolveTerrainPathVariantFromMask(mask);
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
