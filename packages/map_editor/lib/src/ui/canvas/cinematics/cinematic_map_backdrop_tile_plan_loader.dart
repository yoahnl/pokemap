import 'package:map_core/map_core.dart';

import 'cinematic_map_backdrop_tile_render_plan.dart';
import 'cinematic_tileset_asset_registry.dart';

typedef ResolveCinematicBackdropTilesetPath = String? Function(
  String tilesetId,
);

final class CinematicMapBackdropTilePlanLoader {
  CinematicMapBackdropTilePlanLoader({
    CinematicTilesetAssetRegistry? registry,
  }) : _registry = registry ?? CinematicTilesetAssetRegistry();

  final CinematicTilesetAssetRegistry _registry;

  Future<CinematicMapBackdropTileRenderPlan?> load({
    required ProjectManifest manifest,
    required MapData? mapData,
    required CinematicMapBackdropPreviewModel? previewModel,
    required ResolveCinematicBackdropTilesetPath resolveTilesetPath,
  }) async {
    if (mapData == null || previewModel == null || !previewModel.isAvailable) {
      return null;
    }
    final tilesetIds = collectCinematicMapBackdropTileLayerTilesetIds(mapData);
    final resolvedTilesets = <String, CinematicResolvedTilesetAsset>{};
    for (final tilesetId in tilesetIds) {
      final tileset = _tilesetById(manifest, tilesetId);
      resolvedTilesets[tilesetId] = await _registry.resolve(
        tileset: tileset,
        absolutePath: tileset == null ? null : resolveTilesetPath(tilesetId),
        tileWidth: manifest.settings.tileWidth,
        tileHeight: manifest.settings.tileHeight,
      );
    }
    return buildCinematicMapBackdropTileRenderPlan(
      mapData: mapData,
      manifest: manifest,
      tilesets: resolvedTilesets,
    );
  }

  void invalidateTileset(String tilesetId) {
    _registry.invalidateTileset(tilesetId);
  }

  void clear() {
    _registry.clear();
  }
}

Set<String> collectCinematicMapBackdropTileLayerTilesetIds(MapData mapData) {
  final ids = <String>{};
  for (final layer in mapData.layers) {
    if (layer is! TileLayer || !layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    if (!layer.tiles.any((tileId) => tileId > 0)) {
      continue;
    }
    final tilesetId = (layer.tilesetId ?? mapData.tilesetId).trim();
    if (tilesetId.isNotEmpty) {
      ids.add(tilesetId);
    }
  }
  return ids;
}

ProjectTilesetEntry? _tilesetById(
  ProjectManifest manifest,
  String tilesetId,
) {
  for (final tileset in manifest.tilesets) {
    if (tileset.id.trim() == tilesetId) {
      return tileset;
    }
  }
  return null;
}
