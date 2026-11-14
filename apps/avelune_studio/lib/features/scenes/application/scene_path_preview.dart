import 'package:map_core/map_core_domain.dart';

import 'steps/scene_step_projection.dart';

final class ScenePathExit {
  const ScenePathExit(this.portId, this.targetNodeId);

  final String portId;
  final String targetNodeId;
}

final class ScenePath {
  ScenePath({
    required List<String> nodeIds,
    this.choiceNodeId,
    List<ScenePathExit> exits = const [],
    this.looped = false,
  }) : nodeIds = List.unmodifiable(nodeIds),
       exits = List.unmodifiable(exits);

  final List<String> nodeIds;
  final String? choiceNodeId;
  final List<ScenePathExit> exits;
  final bool looped;

  bool get ended => choiceNodeId == null && !looped;
}

ScenePath previewScenePath(SceneGraph graph, Map<String, String> choices) {
  final nodes = {for (final node in graph.nodes) node.id: node};
  final path = <String>[];
  String? current = graph.startNodeId;
  while (current != null) {
    if (path.contains(current)) return ScenePath(nodeIds: path, looped: true);
    path.add(current);
    final exits = _exits(graph, nodes[current], current);
    if (exits.isEmpty) return ScenePath(nodeIds: path);
    if (exits.length == 1) {
      current = exits.single.targetNodeId;
      continue;
    }
    final chosen = exits
        .where((exit) => exit.portId == choices[current])
        .firstOrNull;
    if (chosen == null) {
      return ScenePath(nodeIds: path, choiceNodeId: current, exits: exits);
    }
    current = chosen.targetNodeId;
  }
  return ScenePath(nodeIds: path);
}

List<ScenePathExit> _exits(SceneGraph graph, SceneNode? node, String id) {
  final targets = <String, String>{};
  for (final edge in graph.edges.where((edge) => edge.fromNodeId == id)) {
    targets.putIfAbsent(edge.fromPortId, () => edge.toNodeId);
  }
  final order = node == null
      ? const <String>[]
      : sceneStepPortOrder(node, graph);
  return [
    for (final port in [
      ...order.where(targets.containsKey),
      ...targets.keys.where((port) => !order.contains(port)),
    ])
      ScenePathExit(port, targets[port]!),
  ];
}
