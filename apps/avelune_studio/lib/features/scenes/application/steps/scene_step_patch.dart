import 'package:map_core/map_core_domain.dart';

const sceneGraphPatchActionId = 'scene.graph.patch';

enum SceneGraphPatchUnsupportedReason {
  startNodeChanged,
  nodeOrderChanged,
  edgeOrderChanged,
}

sealed class SceneGraphPatchResult {
  const SceneGraphPatchResult();
}

final class SceneGraphPatchReady extends SceneGraphPatchResult {
  const SceneGraphPatchReady(this.patch);

  final SceneGraphPatch patch;
}

final class SceneGraphPatchUnsupported extends SceneGraphPatchResult {
  const SceneGraphPatchUnsupported(this.reason);

  final SceneGraphPatchUnsupportedReason reason;
}

final class SceneGraphPatch {
  SceneGraphPatch({
    required this.sceneId,
    List<SceneNode> upsertNodes = const [],
    List<String> removeNodeIds = const [],
    List<SceneEdge> upsertEdges = const [],
    List<String> removeEdgeIds = const [],
  }) : upsertNodes = List.unmodifiable(upsertNodes),
       removeNodeIds = List.unmodifiable(removeNodeIds),
       upsertEdges = List.unmodifiable(upsertEdges),
       removeEdgeIds = List.unmodifiable(removeEdgeIds);

  final String sceneId;
  final List<SceneNode> upsertNodes;
  final List<String> removeNodeIds;
  final List<SceneEdge> upsertEdges;
  final List<String> removeEdgeIds;

  bool get isEmpty =>
      upsertNodes.isEmpty &&
      removeNodeIds.isEmpty &&
      upsertEdges.isEmpty &&
      removeEdgeIds.isEmpty;

  Map<String, Object?> toParameters() => {
    'sceneId': sceneId,
    'upsertNodes': [for (final node in upsertNodes) node.toJson()],
    'removeNodeIds': removeNodeIds,
    'upsertEdges': [for (final edge in upsertEdges) edge.toJson()],
    'removeEdgeIds': removeEdgeIds,
  };
}

SceneGraphPatchResult sceneGraphPatchBetween({
  required String sceneId,
  required SceneGraph before,
  required SceneGraph after,
}) {
  if (before.startNodeId != after.startNodeId) {
    return const SceneGraphPatchUnsupported(
      SceneGraphPatchUnsupportedReason.startNodeChanged,
    );
  }
  final nodes = _difference(before.nodes, after.nodes, (node) => node.id);
  if (nodes == null) {
    return const SceneGraphPatchUnsupported(
      SceneGraphPatchUnsupportedReason.nodeOrderChanged,
    );
  }
  final edges = _difference(before.edges, after.edges, (edge) => edge.id);
  if (edges == null) {
    return const SceneGraphPatchUnsupported(
      SceneGraphPatchUnsupportedReason.edgeOrderChanged,
    );
  }
  return SceneGraphPatchReady(
    SceneGraphPatch(
      sceneId: sceneId,
      upsertNodes: nodes.upserts,
      removeNodeIds: nodes.removals,
      upsertEdges: edges.upserts,
      removeEdgeIds: edges.removals,
    ),
  );
}

({List<T> upserts, List<String> removals})? _difference<T>(
  List<T> before,
  List<T> after,
  String Function(T) idOf,
) {
  final afterById = {for (final item in after) idOf(item): item};
  final beforeIds = {for (final item in before) idOf(item)};
  final removals = [
    for (final item in before)
      if (!afterById.containsKey(idOf(item))) idOf(item),
  ];
  final upserts = <T>[
    for (final item in before)
      if (afterById[idOf(item)] case final next? when next != item) next,
    for (final item in after)
      if (!beforeIds.contains(idOf(item))) item,
  ];
  final replayed = [
    for (final item in before)
      if (afterById.containsKey(idOf(item))) idOf(item),
    for (final item in after)
      if (!beforeIds.contains(idOf(item))) idOf(item),
  ];
  for (var index = 0; index < after.length; index++) {
    if (replayed[index] != idOf(after[index])) return null;
  }
  return (upserts: upserts, removals: removals);
}
