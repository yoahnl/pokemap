import 'package:map_core/map_core_domain.dart';

import 'scene_step_list.dart';

part 'scene_step_projector.dart';

SceneStepProjection projectSceneSteps(SceneGraph graph) {
  final index = SceneStepGraphIndex(graph);
  final cycle = index.findCycle();
  if (cycle != null) return SceneStepLoop(graph, cycleNodeIds: cycle);
  final problem = index.findShapeProblem();
  if (problem != null) {
    return SceneStepTrueGraph(
      graph,
      reason: problem.reason,
      nodeIds: problem.nodeIds,
    );
  }
  final projector = _Projector(index);
  try {
    final root = projector.root();
    final unusedEnds = index.isolatedEndNodeIds();
    final unclaimedNodes = [
      for (final node in graph.nodes)
        if (!projector.claimedNodes.contains(node.id) &&
            !unusedEnds.contains(node.id))
          node.id,
    ];
    if (unclaimedNodes.isNotEmpty) {
      return SceneStepTrueGraph(
        graph,
        reason: SceneStepGraphReason.unreachableNodes,
        nodeIds: unclaimedNodes,
      );
    }
    final unclaimedEdges = [
      for (final edge in graph.edges)
        if (!projector.claimedEdges.contains(edge.id)) edge,
    ];
    if (unclaimedEdges.isNotEmpty) {
      return SceneStepTrueGraph(
        graph,
        reason: SceneStepGraphReason.unclaimedEdges,
        nodeIds: {for (final edge in unclaimedEdges) edge.toNodeId}.toList(),
      );
    }
    return SceneStepList(
      graph,
      root: root,
      startPortIds: projector.startPortIds,
      unusedEndNodeIds: unusedEnds.toList(),
    );
  } on _NotAList catch (failure) {
    return SceneStepTrueGraph(
      graph,
      reason: failure.reason,
      nodeIds: failure.nodeIds,
    );
  }
}

List<String> sceneStepPortOrder(SceneNode node, SceneGraph graph) {
  if (node.payload is SceneBranchByOutcomePayload) {
    return [
      for (final port in authorableSceneOutputPortsForNodeInGraph(node, graph))
        port.id,
    ];
  }
  final declared = declaredSceneNodeOutcomePorts(node);
  if (declared.isNotEmpty) return declared;
  return [for (final port in authorableSceneOutputPortsForNode(node)) port.id];
}

SceneStepBlockKind sceneStepBlockKindOf(SceneNode node) {
  if (node.kind == SceneNodeKind.condition) return SceneStepBlockKind.condition;
  final payload = node.payload;
  if (payload is SceneActionPayload && payload.interactiveCommand != null) {
    return SceneStepBlockKind.failure;
  }
  return SceneStepBlockKind.outcomes;
}

String? sceneStepMainPortOf(SceneNode node) => switch (node.payload) {
  SceneActionPayload(:final interactiveCommand?) =>
    interactiveCommand.outputPortIds.firstOrNull,
  SceneBattlePayload() => 'victory',
  _ => null,
};

SceneStepBranchRole sceneStepBranchRoleOf(
  SceneStepBlockKind kind,
  String? mainPort,
  List<String> portIds,
) {
  if (kind == SceneStepBlockKind.condition) {
    if (portIds.contains('true')) return SceneStepBranchRole.whenTrue;
    if (portIds.contains('false')) return SceneStepBranchRole.whenFalse;
    return SceneStepBranchRole.outcome;
  }
  if (mainPort != null && portIds.contains(mainPort)) {
    return SceneStepBranchRole.main;
  }
  return kind == SceneStepBlockKind.failure
      ? SceneStepBranchRole.failure
      : SceneStepBranchRole.outcome;
}

final class _NotAList implements Exception {
  const _NotAList(this.reason, this.nodeIds);

  final SceneStepGraphReason reason;
  final List<String> nodeIds;
}

final class SceneStepGraphIndex {
  SceneStepGraphIndex(this.graph) {
    for (final node in graph.nodes) {
      nodes[node.id] = node;
      outgoing[node.id] = [];
      incoming[node.id] = [];
    }
    for (final edge in graph.edges) {
      outgoing[edge.fromNodeId]!.add(edge);
      incoming[edge.toNodeId]!.add(edge);
    }
  }

  final SceneGraph graph;
  final nodes = <String, SceneNode>{};
  final outgoing = <String, List<SceneEdge>>{};
  final incoming = <String, List<SceneEdge>>{};
  final _reach = <String, Set<String>>{};

  List<String> targets(String nodeId) {
    final seen = <String>{};
    return [
      for (final edge in outgoing[nodeId]!)
        if (seen.add(edge.toNodeId)) edge.toNodeId,
    ];
  }

  Set<String> reach(String nodeId) {
    final known = _reach[nodeId];
    if (known != null) return known;
    final result = <String>{nodeId};
    for (final target in targets(nodeId)) {
      result.addAll(reach(target));
    }
    return _reach[nodeId] = result;
  }

  Set<String> isolatedEndNodeIds() => {
    for (final node in graph.nodes)
      if (node.kind == SceneNodeKind.end &&
          node.id != graph.startNodeId &&
          outgoing[node.id]!.isEmpty &&
          incoming[node.id]!.isEmpty)
        node.id,
  };

  List<String>? findCycle() {
    final state = <String, int>{};
    final stack = <String>[];
    List<String>? visit(String id) {
      state[id] = 1;
      stack.add(id);
      for (final target in targets(id)) {
        final seen = state[target];
        if (seen == 1) return stack.sublist(stack.indexOf(target));
        if (seen == null) {
          final found = visit(target);
          if (found != null) return found;
        }
      }
      stack.removeLast();
      state[id] = 2;
      return null;
    }

    for (final id in [graph.startNodeId, ...nodes.keys]) {
      if (state[id] != null) continue;
      final found = visit(id);
      if (found != null) return found;
    }
    return null;
  }

  ({SceneStepGraphReason reason, List<String> nodeIds})? findShapeProblem() {
    final fanOut = <String>[];
    final leakingEnds = <String>[];
    final entries = <String>[];
    for (final node in graph.nodes) {
      final edges = outgoing[node.id]!;
      final ports = <String>{};
      if (edges.any((edge) => !ports.add(edge.fromPortId))) {
        fanOut.add(node.id);
      }
      if (node.kind == SceneNodeKind.end && edges.isNotEmpty) {
        leakingEnds.add(node.id);
      }
      if (node.kind == SceneNodeKind.start && node.id != graph.startNodeId) {
        entries.add(node.id);
      }
    }
    if (fanOut.isNotEmpty) {
      return (reason: SceneStepGraphReason.portFanOut, nodeIds: fanOut);
    }
    if (leakingEnds.isNotEmpty) {
      return (
        reason: SceneStepGraphReason.endWithOutgoingEdge,
        nodeIds: leakingEnds,
      );
    }
    if (targets(graph.startNodeId).length > 1) {
      entries.insert(0, graph.startNodeId);
    }
    if (entries.isNotEmpty) {
      return (reason: SceneStepGraphReason.multipleEntry, nodeIds: entries);
    }
    final reached = reach(graph.startNodeId);
    final isolatedEnds = isolatedEndNodeIds();
    final unreachable = [
      for (final node in graph.nodes)
        if (!reached.contains(node.id) && !isolatedEnds.contains(node.id))
          node.id,
    ];
    if (unreachable.isNotEmpty) {
      return (
        reason: SceneStepGraphReason.unreachableNodes,
        nodeIds: unreachable,
      );
    }
    return null;
  }

  Map<String, String> routers() {
    final result = <String, String>{};
    for (final node in graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneBranchByOutcomePayload) continue;
      final sourceId = payload.sourceNodeId;
      final source = sourceId == null ? null : nodes[sourceId];
      if (source == null ||
          source.kind == SceneNodeKind.start ||
          source.kind == SceneNodeKind.end) {
        continue;
      }
      final sourceEdges = outgoing[source.id]!;
      if (sourceEdges.isEmpty ||
          sourceEdges.any((edge) => edge.toNodeId != node.id) ||
          incoming[node.id]!.any((edge) => edge.fromNodeId != source.id)) {
        continue;
      }
      result[source.id] = node.id;
    }
    return result;
  }

  List<SceneEdge> orderedOutgoing(String exitNodeId) {
    final order = sceneStepPortOrder(nodes[exitNodeId]!, graph);
    final edges = outgoing[exitNodeId]!;
    int rank(SceneEdge edge) {
      final declared = order.indexOf(edge.fromPortId);
      return declared >= 0 ? declared : order.length + edges.indexOf(edge);
    }

    return [...edges]..sort((a, b) => rank(a).compareTo(rank(b)));
  }
}
