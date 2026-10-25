import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

Map<String, Object?> renderPerformanceGameState(Game game) {
  final scene = game is SpatialSceneGame ? game : null;
  final render = scene?.context as SpatialRenderContext?;
  final shadows = render?.shadowStats;
  return {
    'identity': identityHashCode(game),
    'type': game.runtimeType.toString(),
    'paused': game.isPaused,
    if (scene != null) ...{
      'generation': scene.generation,
      'ready': scene.sceneReady,
      'refreshing': scene.refreshing,
      'frames': scene.renderedFrameCount,
      'solarDraws': shadows!.casterDrawCount,
      'pointDraws': shadows.pointCasterDrawCount,
      'pointLights': shadows.pointShadowLightCount,
      'solarAllocations': shadows.targetAllocations,
      'pointAllocations': shadows.pointTargetAllocations,
      'coverage': render!.shadowFrame == null
          ? null
          : {
              'a': render.shadowFrame!.coverage.a,
              'b': render.shadowFrame!.coverage.b,
              'c': render.shadowFrame!.coverage.c,
              'd': render.shadowFrame!.coverage.d,
            },
      'depthOfField': scene.depthOfFieldFrame,
    },
  };
}

void setRenderPerformanceCoverage(Iterable<Game> games, bool enabled) {
  for (final game in games.whereType<SpatialSceneGame>()) {
    (game.context as SpatialRenderContext).shadowCoverageEnabled = enabled;
  }
}

Future<Map<String, Object?>> captureRenderPerformance(
  Iterable<Game> games,
) async {
  final active = games.where((game) => !game.isPaused).toList();
  final scene = active.whereType<SpatialSceneGame>().single;
  final render = scene.context as SpatialRenderContext;
  final previous = render.shadowCoverageEnabled;
  final frames = <Map<String, Object?>>[];
  for (final game in active) {
    game.pauseEngine();
  }
  try {
    final box = scene.renderBox;
    RenderObject? node = box.parent;
    while (node != null && node is! RenderRepaintBoundary) {
      node = node.parent;
    }
    if (node is! RenderRepaintBoundary) {
      throw StateError('The isolated capture boundary is unavailable.');
    }
    final bounds = MatrixUtils.transformRect(
      box.getTransformTo(node),
      ui.Offset.zero & box.size,
    );
    for (final optimized in [false, true, false]) {
      render.shadowCoverageEnabled = optimized;
      box.markNeedsPaint();
      await WidgetsBinding.instance.endOfFrame;
      final image = await node.toImage(pixelRatio: 1);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) {
          throw StateError('The native pixels are unavailable.');
        }
        frames.add({
          'optimized': optimized,
          'png': base64Encode(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          ),
          'width': image.width,
          'height': image.height,
          'bounds': {
            'x': bounds.left,
            'y': bounds.top,
            'width': bounds.width,
            'height': bounds.height,
          },
          'game': renderPerformanceGameState(scene),
        });
      } finally {
        image.dispose();
      }
    }
    return {'frames': frames};
  } finally {
    render.shadowCoverageEnabled = previous;
    for (final game in active) {
      game.resumeEngine();
    }
  }
}
