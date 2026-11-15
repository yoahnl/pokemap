import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';

import 'scene_graph_metrics.dart';

final class SceneGraphPoint {
  const SceneGraphPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is SceneGraphPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x, $y)';
}

final class SceneGraphShape {
  const SceneGraphShape({
    required this.positions,
    required this.storedNodeIds,
    required this.loopEdgeIds,
    required this.unreachableNodeIds,
  });

  final Map<String, SceneGraphPoint> positions;
  final Set<String> storedNodeIds;
  final Set<String> loopEdgeIds;
  final Set<String> unreachableNodeIds;
}

SceneGraphShape layOutSceneGraph(
  SceneGraph graph, {
  required Map<String, double> heights,
  required Map<String, SceneGraphPoint> stored,
}) {
  final ids = [for (final node in graph.nodes) node.id];
  final known = ids.toSet();
  final edges = [
    for (final edge in graph.edges)
      if (known.contains(edge.fromNodeId) && known.contains(edge.toNodeId))
        edge,
  ];
  final outgoing = {for (final id in ids) id: <SceneEdge>[]};
  for (final edge in edges) {
    outgoing[edge.fromNodeId]!.add(edge);
  }
  final roots = [
    graph.startNodeId,
    ...ids.where((id) => id != graph.startNodeId),
  ];
  final loops = _loopEdgeIds(roots, outgoing);
  final reachable = _reachable(graph.startNodeId, outgoing);
  final auto = _autoPositions(ids, roots, edges, loops, heights);
  final storedIds = {
    for (final id in ids)
      if (stored.containsKey(id)) id,
  };
  return SceneGraphShape(
    positions: _merge(ids, auto, stored, storedIds, heights),
    storedNodeIds: storedIds,
    loopEdgeIds: loops,
    unreachableNodeIds: known.difference(reachable),
  );
}

Set<String> _loopEdgeIds(
  List<String> roots,
  Map<String, List<SceneEdge>> outgoing,
) {
  final state = <String, int>{};
  final loops = <String>{};
  for (final root in roots) {
    if (state.containsKey(root)) continue;
    final stack = <(String, int)>[(root, 0)];
    state[root] = 1;
    while (stack.isNotEmpty) {
      final (nodeId, next) = stack.removeLast();
      final edges = outgoing[nodeId]!;
      if (next >= edges.length) {
        state[nodeId] = 2;
        continue;
      }
      stack.add((nodeId, next + 1));
      final edge = edges[next];
      switch (state[edge.toNodeId]) {
        case 1:
          loops.add(edge.id);
        case 2:
          break;
        default:
          state[edge.toNodeId] = 1;
          stack.add((edge.toNodeId, 0));
      }
    }
  }
  return loops;
}

Set<String> _reachable(String startId, Map<String, List<SceneEdge>> outgoing) {
  final seen = <String>{startId};
  final queue = [startId];
  while (queue.isNotEmpty) {
    for (final edge in outgoing[queue.removeLast()]!) {
      if (seen.add(edge.toNodeId)) queue.add(edge.toNodeId);
    }
  }
  return seen;
}

Map<String, SceneGraphPoint> _autoPositions(
  List<String> ids,
  List<String> roots,
  List<SceneEdge> edges,
  Set<String> loops,
  Map<String, double> heights,
) {
  final forward = [
    for (final edge in edges)
      if (!loops.contains(edge.id)) edge,
  ];
  final layer = _layers(roots, forward);
  final columns = <int, List<String>>{};
  for (final id in roots) {
    columns.putIfAbsent(layer[id]!, () => []).add(id);
  }
  final rank = <String, double>{};
  final incoming = <String, List<SceneEdge>>{};
  for (final edge in forward) {
    incoming.putIfAbsent(edge.toNodeId, () => []).add(edge);
  }
  final portRank = <String, int>{};
  final seenFrom = <String, int>{};
  for (final edge in forward) {
    final index = seenFrom[edge.fromNodeId] ?? 0;
    portRank[edge.id] = index;
    seenFrom[edge.fromNodeId] = index + 1;
  }
  final order = ids.asMap().map((index, id) => MapEntry(id, index));
  final layerIndexes = columns.keys.toList()..sort();
  for (final index in layerIndexes) {
    final column = columns[index]!;
    double key(String id) {
      final preds = incoming[id] ?? const <SceneEdge>[];
      if (preds.isEmpty) return 1e9 + order[id]!;
      final total = preds
          .map((edge) => rank[edge.fromNodeId]! * 64 + portRank[edge.id]!)
          .reduce((a, b) => a + b);
      return total / preds.length;
    }

    final keys = {for (final id in column) id: key(id)};
    column.sort((a, b) {
      final byKey = keys[a]!.compareTo(keys[b]!);
      return byKey != 0 ? byKey : order[a]!.compareTo(order[b]!);
    });
    for (final (position, id) in column.indexed) {
      rank[id] = position.toDouble();
    }
  }
  double columnHeight(List<String> column) =>
      column.map((id) => heights[id]!).fold(0.0, (a, b) => a + b) +
      math.max(0, column.length - 1) * SceneGraphMetrics.rowGap;
  final tallest = columns.values.map(columnHeight).fold(0.0, math.max);
  final positions = <String, SceneGraphPoint>{};
  for (final index in layerIndexes) {
    final column = columns[index]!;
    var y = (tallest - columnHeight(column)) / 2;
    final x =
        index * (SceneGraphMetrics.cardWidth + SceneGraphMetrics.columnGap);
    for (final id in column) {
      positions[id] = SceneGraphPoint(x, y);
      y += heights[id]! + SceneGraphMetrics.rowGap;
    }
  }
  return positions;
}

Map<String, int> _layers(List<String> roots, List<SceneEdge> forward) {
  final indegree = {for (final id in roots) id: 0};
  final next = {for (final id in roots) id: <String>[]};
  for (final edge in forward) {
    indegree[edge.toNodeId] = indegree[edge.toNodeId]! + 1;
    next[edge.fromNodeId]!.add(edge.toNodeId);
  }
  final layer = {for (final id in roots) id: 0};
  final ready = [
    for (final id in roots)
      if (indegree[id] == 0) id,
  ];
  var cursor = 0;
  while (cursor < ready.length) {
    final id = ready[cursor++];
    for (final target in next[id]!) {
      layer[target] = math.max(layer[target]!, layer[id]! + 1);
      indegree[target] = indegree[target]! - 1;
      if (indegree[target] == 0) ready.add(target);
    }
  }
  return layer;
}

Map<String, SceneGraphPoint> _merge(
  List<String> ids,
  Map<String, SceneGraphPoint> auto,
  Map<String, SceneGraphPoint> stored,
  Set<String> storedIds,
  Map<String, double> heights,
) {
  if (storedIds.isEmpty) return auto;
  final missing = ids.where((id) => !storedIds.contains(id)).toList();
  final result = {for (final id in storedIds) id: stored[id]!};
  if (missing.isEmpty) return result;
  final bottom = storedIds
      .map((id) => stored[id]!.y + heights[id]!)
      .reduce(math.max);
  final left = storedIds.map((id) => stored[id]!.x).reduce(math.min);
  final top = missing.map((id) => auto[id]!.y).reduce(math.min);
  final shiftY = bottom + SceneGraphMetrics.rowGap * 2 - top;
  for (final id in missing) {
    final point = auto[id]!;
    result[id] = SceneGraphPoint(point.x + left, point.y + shiftY);
  }
  return result;
}
