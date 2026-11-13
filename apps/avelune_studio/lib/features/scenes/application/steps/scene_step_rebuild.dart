import 'package:map_core/map_core_domain.dart';

import 'scene_step_list.dart';
import 'scene_step_projection.dart';

SceneGraph rebuildSceneStepGraph(SceneStepList list) => buildSceneStepGraph(
  original: list.graph,
  root: list.root,
  startPortIds: list.startPortIds,
);

SceneGraph buildSceneStepGraph({
  required SceneGraph original,
  required SceneStepSequence root,
  List<String> startPortIds = const [],
  List<SceneNode> addedNodes = const [],
  Set<String> removedNodeIds = const {},
  String Function()? newEdgeId,
}) {
  final nodes = [
    for (final node in original.nodes)
      if (!removedNodeIds.contains(node.id)) node,
    ...addedNodes,
  ];
  final shape = SceneGraph(startNodeId: original.startNodeId, nodes: nodes);
  final nodesById = {for (final node in nodes) node.id: node};
  final connections = <String, ({String from, String port, String to})>{};

  void connect(String from, List<String> ports, String? to) {
    if (to == null) return;
    final effective = ports.isEmpty
        ? sceneStepPortOrder(nodesById[from]!, shape)
        : ports;
    for (final port in effective) {
      connections['$from\u0000$port'] = (from: from, port: port, to: to);
    }
  }

  String? tailTarget(SceneStepTail tail, String? continuation) =>
      switch (tail) {
        SceneStepTailEnd(:final endNodeId) => endNodeId,
        SceneStepTailContinue() => continuation,
        SceneStepTailOpen() => null,
      };

  String? entryOf(SceneStepSequence sequence, String? continuation) =>
      sequence.steps.firstOrNull?.nodeId ??
      tailTarget(sequence.tail, continuation);

  late void Function(SceneStepSequence, String?) walk;

  void emit(SceneStep step, String? next) {
    final router = step.routerNodeId;
    if (router != null) {
      for (final edge in original.edges) {
        if (edge.fromNodeId == step.nodeId && edge.toNodeId == router) {
          connect(step.nodeId, [edge.fromPortId], router);
        }
      }
    }
    switch (step) {
      case SceneLeafStep():
        connect(step.exitNodeId, step.portIds, next);
      case SceneBlockStep():
        final merge = step.mergeNodeId;
        if (merge != null) connect(merge, step.mergePortIds, next);
        final stop = merge ?? next;
        for (final branch in step.branches) {
          connect(
            step.exitNodeId,
            branch.portIds,
            entryOf(branch.sequence, stop),
          );
          walk(branch.sequence, stop);
        }
    }
  }

  walk = (sequence, continuation) {
    final steps = sequence.steps;
    for (var index = 0; index < steps.length; index++) {
      final next = index + 1 < steps.length
          ? steps[index + 1].nodeId
          : tailTarget(sequence.tail, continuation);
      emit(steps[index], next);
    }
  };

  connect(
    original.startNodeId,
    startPortIds.isEmpty ? const ['completed'] : startPortIds,
    entryOf(root, null),
  );
  walk(root, null);

  final edges = <SceneEdge>[];
  for (final edge in original.edges) {
    final connection = connections.remove(
      '${edge.fromNodeId}\u0000${edge.fromPortId}',
    );
    if (connection == null ||
        removedNodeIds.contains(edge.fromNodeId) ||
        !nodesById.containsKey(connection.to)) {
      continue;
    }
    edges.add(
      connection.to == edge.toNodeId
          ? edge
          : SceneEdge(
              id: edge.id,
              fromNodeId: edge.fromNodeId,
              fromPortId: edge.fromPortId,
              toNodeId: connection.to,
              kind: edge.kind,
              label: edge.label,
            ),
    );
  }
  for (final connection in connections.values) {
    final id = newEdgeId?.call();
    if (id == null) {
      throw StateError('A new scene edge needs an identity generator.');
    }
    edges.add(
      SceneEdge(
        id: id,
        fromNodeId: connection.from,
        fromPortId: connection.port,
        toNodeId: connection.to,
        kind: _edgeKind(nodesById[connection.from]!, connection.port, shape),
      ),
    );
  }
  return SceneGraph(
    startNodeId: original.startNodeId,
    nodes: nodes,
    edges: edges,
  );
}

SceneEdgeKind _edgeKind(SceneNode node, String port, SceneGraph shape) {
  for (final candidate in authorableSceneOutputPortsForNodeInGraph(
    node,
    shape,
  )) {
    if (candidate.id == port) return candidate.edgeKind;
  }
  return switch (node.kind) {
    SceneNodeKind.action => SceneEdgeKind.actionCompleted,
    SceneNodeKind.branchByOutcome => SceneEdgeKind.branchOutcome,
    SceneNodeKind.yarnDialogue => SceneEdgeKind.dialogueOutcome,
    SceneNodeKind.battle => SceneEdgeKind.branchOutcome,
    _ => SceneEdgeKind.defaultFlow,
  };
}
