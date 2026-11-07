import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

import '../scenes/scene_builder_view_state.dart';
import '../scenes/scene_canvas_types.dart';

bool focusSceneNode(
  SceneBuilderViewStore views,
  SceneAsset scene,
  String nodeId,
) {
  if (!scene.graph.nodes.any((node) => node.id == nodeId)) return false;
  final view = views.forScene(scene.id)
    ..nodeId = nodeId
    ..edgeId = null;
  final center = SceneCanvasGeometry(scene).nodeRect(nodeId, const {}).center;
  final viewport = view.viewport;
  if (!viewport.size.isEmpty) {
    viewport.centerOn(center);
    return true;
  }
  viewport.initialized = true;
  var attempts = 0;
  void centerOnceLaidOut(Duration _) {
    if (!viewport.size.isEmpty) {
      viewport.centerOn(center);
    } else if (++attempts < 4) {
      WidgetsBinding.instance.addPostFrameCallback(centerOnceLaidOut);
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  WidgetsBinding.instance.addPostFrameCallback(centerOnceLaidOut);
  return true;
}
