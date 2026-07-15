import 'package:flame/game.dart';
import 'package:map_core/map_core.dart';

import '../../application/runtime_map_bundle.dart';
import '../../border/border_runtime_asset_cache.dart';
import '../../border/border_runtime_readiness.dart';
import '../../infrastructure/tile_image_loader.dart';
import '../../shadow/shadow_runtime_collection_provider.dart';
import 'map_layers_component.dart';

class RuntimeMapGame extends FlameGame {
  RuntimeMapGame({
    required this.bundle,
    this.shadowCollectionProvider,
  });

  RuntimeMapBundle bundle;
  final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;
  final BorderRuntimeAssetCache _borderAssetCache = BorderRuntimeAssetCache();

  @override
  Future<void> onLoad() async {
    bundle = await prepareBorderRuntimeBundle(bundle);
    final borderAssets = await _borderAssetCache.loadCollection(
      projectRoot: bundle.projectRootDirectory,
      collection: bundle.borderRuntimePreparation!.assetCollection,
    );
    final images = await loadTilesetImagesById(
      bundle.tilesetAbsolutePathsById,
      transparentColorByTilesetId: _transparentColorByTilesetId(
        bundle.manifest,
      ),
    );
    bundle = await prepareBorderRuntimeBundle(bundle);
    await world.add(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: images,
        shadowCollectionProvider: shadowCollectionProvider,
        borderAssets: borderAssets,
      ),
    );
    _applyView();
    return super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _applyView();
  }

  void _applyView() {
    final mw = bundle.map.size.width * bundle.cellWidth;
    final mh = bundle.map.size.height * bundle.cellHeight;
    camera.viewfinder.visibleGameSize = Vector2(mw, mh);
    camera.viewfinder.position = Vector2(mw / 2, mh / 2);
  }

  Map<String, TilesetTransparentColor> _transparentColorByTilesetId(
    ProjectManifest manifest,
  ) {
    return <String, TilesetTransparentColor>{
      for (final tileset in manifest.tilesets)
        if (tileset.transparentColor != null)
          tileset.id: tileset.transparentColor!,
    };
  }
}
