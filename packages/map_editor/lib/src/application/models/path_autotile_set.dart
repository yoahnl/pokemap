import 'package:map_core/map_core.dart';

class PathAutotileSet {
  const PathAutotileSet({
    required this.id,
    required this.tilesetId,
    required this.variants,
  });

  factory PathAutotileSet.defaultForTileset(String tilesetId) {
    return PathAutotileSet(
      id: 'default_$tilesetId',
      tilesetId: tilesetId,
      variants: const {
        TerrainPathVariant.isolated: TilesetSourceRect(x: 0, y: 0),
        TerrainPathVariant.endNorth: TilesetSourceRect(x: 1, y: 0),
        TerrainPathVariant.endEast: TilesetSourceRect(x: 2, y: 0),
        TerrainPathVariant.endSouth: TilesetSourceRect(x: 3, y: 0),
        TerrainPathVariant.endWest: TilesetSourceRect(x: 0, y: 1),
        TerrainPathVariant.horizontal: TilesetSourceRect(x: 1, y: 1),
        TerrainPathVariant.vertical: TilesetSourceRect(x: 2, y: 1),
        TerrainPathVariant.cornerNE: TilesetSourceRect(x: 3, y: 1),
        TerrainPathVariant.cornerSE: TilesetSourceRect(x: 0, y: 2),
        TerrainPathVariant.cornerSW: TilesetSourceRect(x: 1, y: 2),
        TerrainPathVariant.cornerNW: TilesetSourceRect(x: 2, y: 2),
        TerrainPathVariant.innerCornerNE: TilesetSourceRect(x: 3, y: 3),
        TerrainPathVariant.innerCornerSE: TilesetSourceRect(x: 3, y: 3),
        TerrainPathVariant.innerCornerSW: TilesetSourceRect(x: 3, y: 3),
        TerrainPathVariant.innerCornerNW: TilesetSourceRect(x: 3, y: 3),
        TerrainPathVariant.teeNorth: TilesetSourceRect(x: 3, y: 2),
        TerrainPathVariant.teeEast: TilesetSourceRect(x: 0, y: 3),
        TerrainPathVariant.teeSouth: TilesetSourceRect(x: 1, y: 3),
        TerrainPathVariant.teeWest: TilesetSourceRect(x: 2, y: 3),
        TerrainPathVariant.cross: TilesetSourceRect(x: 3, y: 3),
      },
    );
  }

  factory PathAutotileSet.fromPreset(ProjectPathPreset preset) {
    final mapping = <TerrainPathVariant, TilesetSourceRect>{};
    for (final entry in preset.variants) {
      mapping[entry.variant] = entry.frames.primarySource;
    }
    return PathAutotileSet(
      id: preset.id,
      tilesetId: preset.tilesetId.trim(),
      variants: mapping,
    );
  }

  final String id;
  final String tilesetId;
  final Map<TerrainPathVariant, TilesetSourceRect> variants;

  TilesetSourceRect? sourceForVariant(TerrainPathVariant variant) {
    return variants[variant];
  }
}
