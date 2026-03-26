import 'dart:ui' as ui;

import 'package:flame/game.dart';

import '../../application/runtime_map_bundle.dart';
import 'map_layers_component.dart';

class RuntimeMapGame extends FlameGame {
  RuntimeMapGame({
    required this.bundle,
    required this.tileImagesByTilesetId,
  });

  final RuntimeMapBundle bundle;
  final Map<String, ui.Image> tileImagesByTilesetId;

  @override
  Future<void> onLoad() async {
    await world.add(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: tileImagesByTilesetId,
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
}
