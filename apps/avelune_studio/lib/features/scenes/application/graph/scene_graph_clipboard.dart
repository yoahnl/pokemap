part of 'scene_graph_edits.dart';

final class SceneGraphFragment {
  SceneGraphFragment({
    required List<SceneNode> nodes,
    required List<SceneEdge> edges,
    required Map<String, SceneGraphPoint> offsets,
  }) : nodes = List.unmodifiable(nodes),
       edges = List.unmodifiable(edges),
       offsets = Map.unmodifiable(offsets);

  final List<SceneNode> nodes;
  final List<SceneEdge> edges;
  final Map<String, SceneGraphPoint> offsets;

  double get height {
    final byId = {for (final node in nodes) node.id: node};
    var bottom = 0.0;
    for (final node in nodes) {
      final exits = sceneOutputPortSpecsOf(node, byId)?.length ?? 0;
      final end = offsets[node.id]!.y + SceneGraphMetrics.cardHeight(exits);
      if (end > bottom) bottom = end;
    }
    return bottom;
  }
}

const _nodeReferenceKeys = {'sourceNodeId', 'awaitableNodeId'};

SceneGraphFragment? copySceneGraphSteps(SceneAsset scene, Set<String> ids) {
  final cards = {
    for (final card in projectSceneGraph(scene).cards) card.id: card.position,
  };
  final nodes = [
    for (final node in scene.graph.nodes)
      if (ids.contains(node.id) && node.kind != SceneNodeKind.start) node,
  ];
  if (nodes.isEmpty) return null;
  final kept = {for (final node in nodes) node.id};
  final positions = [for (final id in kept) cards[id]!];
  final left = positions.map((p) => p.x).reduce((a, b) => a < b ? a : b);
  final top = positions.map((p) => p.y).reduce((a, b) => a < b ? a : b);
  return SceneGraphFragment(
    nodes: nodes,
    edges: [
      for (final edge in scene.graph.edges)
        if (kept.contains(edge.fromNodeId) && kept.contains(edge.toNodeId))
          edge,
    ],
    offsets: {
      for (final id in kept)
        id: SceneGraphPoint(cards[id]!.x - left, cards[id]!.y - top),
    },
  );
}

SceneGraphEditResult pasteSceneGraphSteps(
  SceneAsset scene,
  SceneGraphFragment fragment, {
  required SceneGraphPoint at,
  required SceneStepIds ids,
}) {
  final renamed = {for (final node in fragment.nodes) node.id: ids.node()};
  final List<SceneNode> nodes;
  try {
    nodes = [
      for (final node in fragment.nodes)
        SceneNode.fromJson({
          ...node.toJson(),
          'id': renamed[node.id],
          'payload': _renamedReferences(node.toJson()['payload'], renamed),
        }),
    ];
  } on Object {
    return const SceneGraphEditRefused(SceneGraphEditRefusal.invalid);
  }
  return _rebuild(
    scene,
    nodes: [...scene.graph.nodes, ...nodes],
    edges: [
      ...scene.graph.edges,
      for (final edge in fragment.edges)
        SceneEdge(
          id: ids.edge(),
          fromNodeId: renamed[edge.fromNodeId]!,
          fromPortId: edge.fromPortId,
          toNodeId: renamed[edge.toNodeId]!,
          kind: edge.kind,
          label: edge.label,
        ),
    ],
    positions: {
      for (final MapEntry(:key, :value) in fragment.offsets.entries)
        renamed[key]!: SceneGraphPoint(at.x + value.x, at.y + value.y),
    },
    created: {...renamed.values},
  );
}

Object? _renamedReferences(Object? json, Map<String, String> renamed) =>
    switch (json) {
      Map() => {
        for (final MapEntry(:key, :value) in json.entries)
          key: _nodeReferenceKeys.contains(key) && renamed.containsKey(value)
              ? renamed[value]
              : _renamedReferences(value, renamed),
      },
      List() => [for (final item in json) _renamedReferences(item, renamed)],
      _ => json,
    };
