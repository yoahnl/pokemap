import 'package:map_core/map_core.dart';

import 'cinematic_map_backdrop_layer_render_plan.dart';
import 'cinematic_map_backdrop_tile_plan_loader.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';
import 'cinematic_tileset_asset_registry.dart';

final class CinematicMapBackdropLayerPlanLoader {
  CinematicMapBackdropLayerPlanLoader({
    CinematicTilesetAssetRegistry? registry,
  }) : _registry = registry ?? CinematicTilesetAssetRegistry();

  final CinematicTilesetAssetRegistry _registry;

  CinematicTilesetAssetRegistry get registry => _registry;

  Future<CinematicMapBackdropLayerRenderPlan?> load({
    required ProjectManifest manifest,
    required MapData? mapData,
    required CinematicMapBackdropPreviewModel? previewModel,
    required ResolveCinematicBackdropTilesetPath resolveTilesetPath,
    Set<String> additionalTilesetIds = const {},
  }) async {
    if (mapData == null || previewModel == null || !previewModel.isAvailable) {
      return null;
    }
    final tilesetIds = collectCinematicMapBackdropLayerTilesetIds(
      mapData: mapData,
      manifest: manifest,
    );
    final allTilesetIds = <String>{...tilesetIds, ...additionalTilesetIds};
    final resolvedTilesets = <String, CinematicResolvedTilesetAsset>{};
    for (final tilesetId in allTilesetIds) {
      final tileset = _tilesetById(manifest, tilesetId);
      resolvedTilesets[tilesetId] = await _registry.resolve(
        tileset: tileset,
        absolutePath: tileset == null ? null : resolveTilesetPath(tilesetId),
        tileWidth: manifest.settings.tileWidth,
        tileHeight: manifest.settings.tileHeight,
      );
    }
    return buildCinematicMapBackdropLayerRenderPlan(
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
