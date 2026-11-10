import 'package:map_core/map_core_domain.dart';

ProjectTilesetEntry? mapPaletteAtlas(
  List<ProjectTilesetEntry> sources, {
  String? atlasId,
  TileLayerPaletteEntry? selected,
  List<TileLayerPaletteEntry> knownTiles = const [],
}) =>
    sources.where((entry) => entry.id == atlasId).firstOrNull ??
    sources.where((entry) => entry.id == selected?.tilesetId).firstOrNull ??
    sources
        .where((entry) => knownTiles.any((tile) => tile.tilesetId == entry.id))
        .firstOrNull ??
    sources.firstOrNull;

List<int> mapPaletteAtlasTileIds(
  ProjectTilesetEntry atlas,
  List<TileLayerPaletteEntry> knownTiles,
) => switch (atlas.source) {
  ProjectImageCollectionTilesetSource(:final tileDefinitions) =>
    tileDefinitions.map((tile) => tile.tileId).toList(),
  _ =>
    knownTiles
        .where((tile) => tile.tilesetId == atlas.id)
        .map((tile) => tile.localTileId)
        .toSet()
        .toList(),
};

TileLayerPaletteEntry mapPaletteAtlasSelection(
  String atlasId,
  ProjectRegularAtlasTilesetSource source,
  TilesetSourceRect selection,
) => TileLayerPaletteEntry(
  tilesetId: atlasId,
  localTileId: selection.y * source.columns + selection.x,
);
