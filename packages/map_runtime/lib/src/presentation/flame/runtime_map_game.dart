import 'package:flame/game.dart';
import 'package:map_core/map_core.dart';

import '../../application/runtime_map_bundle.dart';
import '../../infrastructure/tile_image_loader.dart';
import 'map_layers_component.dart';

class RuntimeMapGame extends FlameGame {
  RuntimeMapGame({required this.bundle});

  final RuntimeMapBundle bundle;

  @override
  Future<void> onLoad() async {
    final images = await loadTilesetImagesById(
      bundle.tilesetAbsolutePathsById,
      transparentColorByTilesetId: _transparentColorByTilesetId(
        bundle.manifest,
      ),
    );
    await world.add(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: images,
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
