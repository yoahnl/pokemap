import '../models/enums.dart';

/// Returns which sub-tile within a W×H atlas block (in tile coordinates) maps
/// to the given map cell.
///
/// [layout] `tessellated` (default): row-major repeat on the map.
/// [layout] `stableRandom`: legacy hash-based pick for visual variety.
///
/// [subtileSalt] is only used for [TerrainVariantMultiTileLayout.stableRandom]
/// (typically frame origin mix; keeps picks stable when the frame moves).
(int offsetX, int offsetY) terrainPresetSubtileOffsetsForMapCell(
  int mapX,
  int mapY, {
  required int frameWidthTiles,
  required int frameHeightTiles,
  TerrainVariantMultiTileLayout layout =
      TerrainVariantMultiTileLayout.tessellated,
  int subtileSalt = 0,
}) {
  final w = frameWidthTiles <= 0 ? 1 : frameWidthTiles;
  final h = frameHeightTiles <= 0 ? 1 : frameHeightTiles;
  if (w == 1 && h == 1) {
    return (0, 0);
  }
  switch (layout) {
    case TerrainVariantMultiTileLayout.tessellated:
      return (
        _positiveModulo(mapX, w),
        _positiveModulo(mapY, h),
      );
    case TerrainVariantMultiTileLayout.stableRandom:
      final cellSeed = _stableCellSeedForSubtile(mapX, mapY, subtileSalt);
      final tileIndex = cellSeed % (w * h);
      return (tileIndex % w, tileIndex ~/ w);
  }
}

int _positiveModulo(int n, int m) {
  assert(m > 0);
  var r = n % m;
  if (r < 0) {
    r += m;
  }
  return r;
}

int _stableCellSeedForSubtile(int x, int y, int salt) {
  final raw = ((x + 1) * 73856093) ^ ((y + 1) * 19349663) ^ salt;
  return raw & 0x7fffffff;
}
