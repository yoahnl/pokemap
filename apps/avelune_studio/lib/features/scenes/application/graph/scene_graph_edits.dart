import 'package:map_core/map_core_domain.dart';

import '../steps/scene_step_ids.dart';
import 'scene_graph_layout.dart';
import 'scene_graph_metrics.dart';
import 'scene_graph_view.dart';

part 'scene_graph_clipboard.dart';

enum SceneGraphEditRefusal {
  unknownStep,
  unknownExit,
  startHasNoInput,
  intoItself,
  wouldLoop,
  startCannotBeRemoved,
  referencedElsewhere,
  invalid,
}

sealed class SceneGraphEditResult {
  const SceneGraphEditResult();
}

final class SceneGraphEdited extends SceneGraphEditResult {
  const SceneGraphEdited(this.scene, {this.createdNodeIds = const {}});

  final SceneAsset scene;
  final Set<String> createdNodeIds;
}

final class SceneGraphEditRefused extends SceneGraphEditResult {
  const SceneGraphEditRefused(this.reason);

  final SceneGraphEditRefusal reason;
}

typedef SceneGraphExit = ({String nodeId, String portId});

SceneGraphEditResult connectSceneGraphExit(
  SceneAsset scene, {
  required SceneGraphExit from,
  required String toNodeId,
  required SceneStepIds ids,
}) {
  final graph = scene.graph;
  final source = _node(graph, from.nodeId);
  final target = _node(graph, toNodeId);
  if (source == null || target == null) {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.unknownStep);
  }
  if (target.kind == SceneNodeKind.start) {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.startHasNoInput);
  }
  if (source.id == target.id) {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.intoItself);
  }
  final kind = _edgeKindOf(source, from.portId, graph);
  if (kind == null) {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.unknownExit);
  }
  final kept = [
    for (final edge in graph.edges)
      if (edge.fromNodeId != from.nodeId || edge.fromPortId != from.portId)
        edge,
  ];
  if (_reaches(kept, target.id, source.id)) {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.wouldLoop);
  }
  return _rebuild(
    scene,
    nodes: graph.nodes,
    edges: [
      ...kept,
      SceneEdge(
        id: ids.edge(),
        fromNodeId: from.nodeId,
        fromPortId: from.portId,
        toNodeId: toNodeId,
        kind: kind,
      ),
    ],
  );
}

SceneGraphEditResult addSceneGraphStep(
  SceneAsset scene, {
  required SceneNodeKind kind,
  SceneNodePayload? payload,
  required SceneGraphPoint at,
  SceneGraphExit? from,
  required SceneStepIds ids,
}) {
  final SceneNode node;
  try {
    node = SceneNode(id: ids.node(), kind: kind, payload: payload);
  } on ArgumentError {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.invalid);
  } on ValidationException {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.invalid);
  }
  final added = _rebuild(
    scene,
    nodes: [...scene.graph.nodes, node],
    edges: scene.graph.edges,
    positions: {node.id: at},
    created: {node.id},
  );
  if (from == null || added is! SceneGraphEdited) return added;
  return switch (connectSceneGraphExit(
    added.scene,
    from: from,
    toNodeId: node.id,
    ids: ids,
  )) {
    SceneGraphEdited(:final scene) => SceneGraphEdited(
      scene,
      createdNodeIds: {node.id},
    ),
    final SceneGraphEditRefused refused => refused,
  };
}

SceneGraphEditResult removeSceneGraphItems(
  SceneAsset scene, {
  Set<String> nodeIds = const {},
  Set<String> edgeIds = const {},
}) {
  final graph = scene.graph;
  if (nodeIds.contains(graph.startNodeId)) {
    return const SceneGraphEditRefused(
      SceneGraphEditRefusal.startCannotBeRemoved,
    );
  }
  for (final node in graph.nodes) {
    if (nodeIds.contains(node.id)) continue;
    final payload = node.payload;
    if (payload is SceneBranchByOutcomePayload &&
            nodeIds.contains(payload.sourceNodeId) ||
        payload is ScenePresentationCinematicPayload &&
            payload.interactionCueBindings.any(
              (binding) => nodeIds.contains(binding.awaitableNodeId),
            )) {
      return const SceneGraphEditRefused(
        SceneGraphEditRefusal.referencedElsewhere,
      );
    }
  }
  return _rebuild(
    scene,
    nodes: [
      for (final node in graph.nodes)
        if (!nodeIds.contains(node.id)) node,
    ],
    edges: [
      for (final edge in graph.edges)
        if (!edgeIds.contains(edge.id) &&
            !nodeIds.contains(edge.fromNodeId) &&
            !nodeIds.contains(edge.toNodeId))
          edge,
    ],
  );
}

SceneGraphEditResult editSceneGraphStep(SceneAsset scene, SceneNode node) {
  final previous = _node(scene.graph, node.id);
  if (previous == null) {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.unknownStep);
  }
  if (previous.kind != node.kind) {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.invalid);
  }
  return _rebuild(
    scene,
    nodes: [
      for (final each in scene.graph.nodes) each.id == node.id ? node : each,
    ],
    edges: scene.graph.edges,
  );
}

SceneGraphEditResult moveSceneGraphSteps(
  SceneAsset scene,
  Map<String, SceneGraphPoint> positions,
) {
  if (positions.keys.any((id) => _node(scene.graph, id) == null)) {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.unknownStep);
  }
  return _rebuild(
    scene,
    nodes: scene.graph.nodes,
    edges: scene.graph.edges,
    positions: positions,
  );
}

SceneGraphEditResult _rebuild(
  SceneAsset scene, {
  required List<SceneNode> nodes,
  required List<SceneEdge> edges,
  Map<String, SceneGraphPoint> positions = const {},
  Set<String> created = const {},
}) {
  final current = {
    for (final card in projectSceneGraph(scene).cards) card.id: card.position,
    ...positions,
  };
  final nodeIds = {for (final node in nodes) node.id};
  final edgeIds = {for (final edge in edges) edge.id};
  try {
    return SceneGraphEdited(
      SceneAsset(
        id: scene.id,
        name: scene.name,
        executionProfile: scene.executionProfile,
        description: scene.description,
        storylineId: scene.storylineId,
        chapterId: scene.chapterId,
        tags: scene.tags,
        graph: SceneGraph(
          startNodeId: scene.graph.startNodeId,
          nodes: nodes,
          edges: edges,
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [
            for (final node in nodes)
              if (current[node.id] case final point?)
                SceneNodeLayout(nodeId: node.id, x: point.x, y: point.y),
          ],
          edgeLayouts: [
            for (final layout in scene.layout.edgeLayouts)
              if (edgeIds.contains(layout.edgeId)) layout,
          ],
        ),
        declaredOutcomes: scene.declaredOutcomes,
        metadata: scene.metadata,
      ),
      createdNodeIds: {...created.where(nodeIds.contains)},
    );
  } on ArgumentError {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.invalid);
  } on ValidationException {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.invalid);
  }
}

SceneNode? _node(SceneGraph graph, String id) =>
    graph.nodes.where((node) => node.id == id).firstOrNull;

SceneEdgeKind? _edgeKindOf(SceneNode node, String portId, SceneGraph graph) {
  for (final port in authorableSceneOutputPortsForNodeInGraph(node, graph)) {
    if (port.id == portId) return port.edgeKind;
  }
  final nodeById = {for (final node in graph.nodes) node.id: node};
  for (final spec in sceneOutputPortSpecsOf(node, nodeById) ?? const []) {
    if (spec.id == portId) return spec.edgeKinds.first;
  }
  return null;
}

bool _reaches(List<SceneEdge> edges, String from, String target) {
  final next = <String, List<String>>{};
  for (final edge in edges) {
    next.putIfAbsent(edge.fromNodeId, () => []).add(edge.toNodeId);
  }
  final seen = <String>{};
  final stack = [from];
  while (stack.isNotEmpty) {
    final id = stack.removeLast();
    if (id == target) return true;
    if (seen.add(id)) stack.addAll(next[id] ?? const []);
  }
  return false;
}
