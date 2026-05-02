/// Returns which sub-tile within a W×H atlas block (in tile coordinates) maps
/// to the given map cell.
///
/// Uses row-major tessellation: moving right on the map advances the source X
/// within the block, wrapping every [frameWidthTiles]; moving down advances Y.
/// This matches author expectations for multi-tile frames (ordered mosaic).
///
/// Weighted [TerrainPresetVariant]s still provide randomness between variants;
/// within a single frame rectangle, layout is deterministic from map position.
(int offsetX, int offsetY) terrainPresetSubtileOffsetsForMapCell(
  int mapX,
  int mapY, {
  required int frameWidthTiles,
  required int frameHeightTiles,
}) {
  final w = frameWidthTiles <= 0 ? 1 : frameWidthTiles;
  final h = frameHeightTiles <= 0 ? 1 : frameHeightTiles;
  return (
    _positiveModulo(mapX, w),
    _positiveModulo(mapY, h),
  );
}

int _positiveModulo(int n, int m) {
  assert(m > 0);
  var r = n % m;
  if (r < 0) {
    r += m;
  }
  return r;
}
