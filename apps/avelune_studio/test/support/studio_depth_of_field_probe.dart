import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/widgets.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart'
    show SpatialSceneGame;

({int generation, Map<String, Object?> state})? readDepthOfFieldFrame(
  GlobalKey key,
) {
  final game = _findGame(key);
  return game == null
      ? null
      : (generation: game.renderedFrameCount, state: game.depthOfFieldFrame);
}

VoidCallback freezeSpatialCapture(GlobalKey key) {
  final game = _findGame(key)!;
  final paused = game.isPaused;
  game.pauseEngine();
  return () {
    if (!paused) game.resumeEngine();
  };
}

void updateSpatialCapture(GlobalKey key) => _findGame(key)!.update(0);

SpatialSceneGame? _findGame(GlobalKey key) {
  SpatialSceneGame? found;
  void visit(Element element) {
    if (element.widget case GameWidget(:final game)) {
      if (game is SpatialSceneGame) found = game;
    }
    element.visitChildren(visit);
  }

  key.currentContext?.visitChildElements(visit);
  return found;
}
