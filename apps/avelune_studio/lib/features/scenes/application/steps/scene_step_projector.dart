part of 'scene_step_projection.dart';

typedef _Group = ({List<String> portIds, String? target});

final class _Projector {
  _Projector(this.index) : routers = index.routers();

  final SceneStepGraphIndex index;
  final Map<String, String> routers;
  final claimedNodes = <String>{};
  final claimedEdges = <String>{};
  final startPortIds = <String>[];

  SceneStepSequence root() {
    final start = index.graph.startNodeId;
    claimedNodes.add(start);
    for (final edge in index.outgoing[start]!) {
      claimedEdges.add(edge.id);
      startPortIds.add(edge.fromPortId);
    }
    return _sequence(index.targets(start).firstOrNull, null);
  }

  SceneStepSequence _sequence(String? entry, String? continuation) {
    final steps = <SceneStep>[];
    var current = entry;
    while (true) {
      if (current == null) {
        return SceneStepSequence(steps: steps, tail: const SceneStepTailOpen());
      }
      if (current == continuation) return SceneStepSequence(steps: steps);
      final node = index.nodes[current]!;
      if (node.kind == SceneNodeKind.end) {
        claimedNodes.add(current);
        return SceneStepSequence(steps: steps, tail: SceneStepTailEnd(current));
      }
      if (!claimedNodes.add(current)) {
        throw _NotAList(SceneStepGraphReason.sharedStep, [current]);
      }
      final router = routers[current];
      if (router != null) {
        claimedNodes.add(router);
        for (final edge in index.outgoing[current]!) {
          claimedEdges.add(edge.id);
        }
      }
      final exit = router ?? current;
      final edges = index.orderedOutgoing(exit);
      final groups = _groups(node, edges);
      if (groups == null) {
        for (final edge in edges) {
          claimedEdges.add(edge.id);
        }
        steps.add(
          SceneLeafStep(
            nodeId: current,
            routerNodeId: router,
            portIds: [for (final edge in edges) edge.fromPortId],
          ),
        );
        current = edges.firstOrNull?.toNodeId;
        continue;
      }
      for (final edge in edges) {
        claimedEdges.add(edge.id);
      }
      final kind = sceneStepBlockKindOf(node);
      final mainPort = sceneStepMainPortOf(node);
      final join = _join(groups, mainPort, continuation);
      final merge = join != null && join != continuation
          ? _absorbableMerge(join)
          : null;
      final branchStop = join ?? continuation;
      final branches = [
        for (final group in groups)
          SceneStepBranch(
            portIds: group.portIds,
            role: sceneStepBranchRoleOf(kind, mainPort, group.portIds),
            sequence: _sequence(group.target, branchStop),
          ),
      ];
      final block = SceneBlockStep(
        nodeId: current,
        routerNodeId: router,
        kind: kind,
        branches: branches,
        mergeNodeId: merge?.id,
        mergePortIds: [
          if (merge != null)
            for (final edge in index.outgoing[merge.id]!) edge.fromPortId,
        ],
      );
      steps.add(block);
      if (!block.flowsOn) {
        return SceneStepSequence(steps: steps, tail: const SceneStepTailOpen());
      }
      if (join == null) return SceneStepSequence(steps: steps);
      if (merge != null) {
        claimedNodes.add(merge.id);
        for (final edge in index.outgoing[merge.id]!) {
          claimedEdges.add(edge.id);
        }
        current = index.targets(merge.id).firstOrNull;
      } else {
        current = join;
      }
    }
  }

  List<_Group>? _groups(SceneNode node, List<SceneEdge> edges) {
    if (node.kind == SceneNodeKind.condition) {
      String? target(String portId) => edges
          .where((edge) => edge.fromPortId == portId)
          .firstOrNull
          ?.toNodeId;
      return [
        (portIds: const ['true'], target: target('true')),
        (portIds: const ['false'], target: target('false')),
        for (final edge in edges)
          if (edge.fromPortId != 'true' && edge.fromPortId != 'false')
            (portIds: [edge.fromPortId], target: edge.toNodeId),
      ];
    }
    final byTarget = <String, List<String>>{};
    for (final edge in edges) {
      byTarget.putIfAbsent(edge.toNodeId, () => []).add(edge.fromPortId);
    }
    if (byTarget.length < 2) return null;
    return [
      for (final entry in byTarget.entries)
        (portIds: entry.value, target: entry.key),
    ];
  }

  String? _join(List<_Group> groups, String? mainPort, String? continuation) {
    final hits = <String, int>{};
    for (final group in groups) {
      final target = group.target;
      if (target == null) continue;
      for (final id in index.reach(target)) {
        hits[id] = (hits[id] ?? 0) + 1;
      }
    }
    final candidates = {
      for (final entry in hits.entries)
        if (entry.value >= 2 &&
            index.nodes[entry.key]!.kind != SceneNodeKind.end)
          entry.key,
    };
    if (candidates.isEmpty) {
      if (mainPort == null) return null;
      final main = groups
          .where((group) => group.portIds.contains(mainPort))
          .firstOrNull
          ?.target;
      if (main == null ||
          main == continuation ||
          index.nodes[main]!.kind == SceneNodeKind.end) {
        return null;
      }
      final escapes =
          continuation != null &&
          groups.any(
            (group) =>
                !group.portIds.contains(mainPort) &&
                group.target != null &&
                index.reach(group.target!).contains(continuation),
          );
      return escapes ? null : main;
    }
    final first = [
      for (final candidate in candidates)
        if (!candidates.any(
          (other) =>
              other != candidate && index.reach(other).contains(candidate),
        ))
          candidate,
    ];
    if (first.length != 1) {
      throw _NotAList(SceneStepGraphReason.ambiguousJoin, first);
    }
    return first.single;
  }

  SceneNode? _absorbableMerge(String join) {
    final node = index.nodes[join]!;
    if (node.kind != SceneNodeKind.merge) return null;
    if (index.targets(join).length > 1) return null;
    return node;
  }
}
