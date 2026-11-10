export '../../../features/scenes/application/scene_labels.dart';

import 'package:avelune_studio/features/scenes/coordination/scene_graph_viewport.dart';
export 'package:avelune_studio/features/scenes/coordination/scene_graph_viewport.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

class SceneBlockDragData {
  const SceneBlockDragData({
    required this.kind,
    required this.label,
    this.payload,
  });
  final SceneNodeKind kind;
  final String label;
  final SceneNodePayload? payload;
}

typedef SceneCanvasAdd = void Function(
  SceneBlockDragData block,
  Offset position, {
  String? fromNodeId,
  String? fromPortId,
});

class SceneCanvasGeometry {
  SceneCanvasGeometry(this.scene) {
    nodes = {for (final node in scene.graph.nodes) node.id: node};
    ports = {
      for (final node in scene.graph.nodes)
        node.id: authorableSceneOutputPortsForNodeInGraph(node, scene.graph),
    };
    final layouts = {
      for (final layout in scene.layout.nodeLayouts)
        layout.nodeId: Offset(layout.x, layout.y),
    };
    positions = {
      for (var i = 0; i < scene.graph.nodes.length; i++)
        scene.graph.nodes[i].id:
            layouts[scene.graph.nodes[i].id] ??
            Offset(40 + (i % 4) * 280, 40 + (i ~/ 4) * 230),
    };
    occupied = {
      for (final edge in scene.graph.edges)
        '${edge.fromNodeId}:${edge.fromPortId}',
    };
  }
  final SceneAsset scene;
  late final Map<String, SceneNode> nodes;
  late final Map<String, List<SceneAuthorableOutputPort>> ports;
  late final Map<String, Offset> positions;
  late final Set<String> occupied;
  Size nodeSize(String id) => switch (nodes[id]?.kind) {
    SceneNodeKind.start || SceneNodeKind.end => const Size(128, 128),
    _ => Size(208, math.max(176, 120 + (ports[id]?.length ?? 0) * 26)),
  };
  Rect nodeRect(String id, Map<String, Offset> overrides) =>
      (overrides[id] ?? positions[id]!) & nodeSize(id);
  Offset input(String id, Map<String, Offset> overrides) =>
      nodeRect(id, overrides).centerLeft;
  Offset output(String id, String port, Map<String, Offset> overrides) {
    final rect = nodeRect(id, overrides);
    final list = ports[id] ?? [];
    final index = list.indexWhere((p) => p.id == port);
    return Offset(
      rect.right,
      rect.bottom - 18 - (list.length - 1 - index) * 26,
    );
  }

  Rect bounds(Map<String, Offset> overrides) {
    if (nodes.isEmpty) return const Rect.fromLTWH(0, 0, 400, 300);
    return nodes.keys
        .map((id) => nodeRect(id, overrides))
        .reduce((a, b) => a.expandToInclude(b));
  }

  String? targetAt(
    Offset local,
    SceneGraphViewport view,
    Map<String, Offset> overrides,
    String source,
  ) {
    for (final node in nodes.values) {
      if (node.id == source || node.kind == SceneNodeKind.start) continue;
      if ((view.worldToLocal(input(node.id, overrides)) - local).distance <=
          24) {
        return node.id;
      }
    }
    return null;
  }
}
