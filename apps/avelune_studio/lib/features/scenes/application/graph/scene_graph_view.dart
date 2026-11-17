import 'package:map_core/map_core_domain.dart';

import 'scene_graph_layout.dart';
import 'scene_graph_metrics.dart';

final class SceneGraphPort {
  const SceneGraphPort({
    required this.id,
    required this.required,
    required this.connected,
    required this.declared,
  });

  final String id;
  final bool required;
  final bool connected;
  final bool declared;
}

final class SceneGraphCard {
  const SceneGraphCard({
    required this.node,
    required this.outputs,
    required this.position,
    required this.storedPosition,
  });

  final SceneNode node;
  final List<SceneGraphPort> outputs;
  final SceneGraphPoint position;
  final bool storedPosition;

  String get id => node.id;
  bool get acceptsInput => node.kind != SceneNodeKind.start;
  double get height => SceneGraphMetrics.cardHeight(outputs.length);
}

final class SceneGraphWire {
  const SceneGraphWire({
    required this.edge,
    required this.loop,
    required this.declared,
  });

  final SceneEdge edge;
  final bool loop;
  final bool declared;

  String get id => edge.id;
}

final class SceneGraphView {
  const SceneGraphView({
    required this.cards,
    required this.wires,
    required this.unreachableNodeIds,
  });

  final List<SceneGraphCard> cards;
  final List<SceneGraphWire> wires;
  final Set<String> unreachableNodeIds;

  bool get hasLoop => wires.any((wire) => wire.loop);
  bool get needsLayoutSave => cards.any((card) => !card.storedPosition);

  SceneGraphCard? card(String nodeId) =>
      cards.where((card) => card.id == nodeId).firstOrNull;

  SceneGraphView withPositions(Map<String, SceneGraphPoint> moved) =>
      moved.isEmpty
      ? this
      : SceneGraphView(
          cards: [
            for (final card in cards)
              switch (moved[card.id]) {
                final position? => SceneGraphCard(
                  node: card.node,
                  outputs: card.outputs,
                  position: position,
                  storedPosition: true,
                ),
                null => card,
              },
          ],
          wires: wires,
          unreachableNodeIds: unreachableNodeIds,
        );
}

SceneGraphView projectSceneGraph(SceneAsset scene) {
  final graph = scene.graph;
  final nodeById = {for (final node in graph.nodes) node.id: node};
  final outputs = {
    for (final node in graph.nodes) node.id: _outputsOf(node, graph, nodeById),
  };
  final shape = layOutSceneGraph(
    graph,
    heights: {
      for (final node in graph.nodes)
        node.id: SceneGraphMetrics.cardHeight(outputs[node.id]!.length),
    },
    stored: {
      for (final layout in scene.layout.nodeLayouts)
        layout.nodeId: SceneGraphPoint(layout.x, layout.y),
    },
  );
  return SceneGraphView(
    cards: [
      for (final node in graph.nodes)
        SceneGraphCard(
          node: node,
          outputs: outputs[node.id]!,
          position: shape.positions[node.id]!,
          storedPosition: shape.storedNodeIds.contains(node.id),
        ),
    ],
    wires: [
      for (final edge in graph.edges)
        if (nodeById.containsKey(edge.toNodeId))
          SceneGraphWire(
            edge: edge,
            loop: shape.loopEdgeIds.contains(edge.id),
            declared: outputs[edge.fromNodeId]!
                .where((port) => port.id == edge.fromPortId)
                .every((port) => port.declared),
          ),
    ],
    unreachableNodeIds: shape.unreachableNodeIds,
  );
}

List<SceneGraphPort> _outputsOf(
  SceneNode node,
  SceneGraph graph,
  Map<String, SceneNode> nodeById,
) {
  final specs = sceneOutputPortSpecsOf(node, nodeById) ?? const [];
  final usedPortIds = [
    for (final edge in graph.edges)
      if (edge.fromNodeId == node.id) edge.fromPortId,
  ];
  final declaredIds = {for (final spec in specs) spec.id};
  return [
    for (final spec in specs)
      SceneGraphPort(
        id: spec.id,
        required: spec.required,
        connected: usedPortIds.contains(spec.id),
        declared: true,
      ),
    for (final portId in {...usedPortIds})
      if (!declaredIds.contains(portId))
        SceneGraphPort(
          id: portId,
          required: false,
          connected: true,
          declared: false,
        ),
  ];
}
