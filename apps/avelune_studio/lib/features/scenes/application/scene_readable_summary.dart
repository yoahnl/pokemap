import 'package:map_core/map_core_domain.dart';

import 'scene_labels.dart';

final class SceneReadableSummary {
  const SceneReadableSummary(this.conditions, this.steps, this.unreached);

  final List<String> conditions, steps;
  final int unreached;
}

SceneReadableSummary sceneReadableSummary(
  SceneAsset scene,
  String Function(SceneNode node) label,
) {
  final graph = scene.graph;
  final nodes = {for (final node in graph.nodes) node.id: node};
  final conditions = <String>[];
  final steps = <String>[];
  final seen = <String>{graph.startNodeId};
  final queue = [graph.startNodeId];
  while (queue.isNotEmpty) {
    final id = queue.removeAt(0);
    final outgoing = [
      for (final edge in graph.edges)
        if (edge.fromNodeId == id) edge,
    ];
    for (final edge in outgoing) {
      if (seen.add(edge.toNodeId)) queue.add(edge.toNodeId);
    }
    final node = nodes[id];
    if (node == null || node.kind == SceneNodeKind.start) continue;
    if (node.kind == SceneNodeKind.condition) {
      conditions.add(
        'Si ${label(node)} : ${outgoing.isEmpty ? 'aucune suite' : outgoing.map((edge) => '${scenePortLabel(edge.fromPortId)} → ${sceneNodeName(graph, edge.toNodeId)}').join(' · ')}',
      );
      continue;
    }
    final title = node.title?.trim();
    final name = title == null || title.isEmpty ? label(node) : title;
    steps.add(
      node.kind == SceneNodeKind.end
          ? 'Fin · $name'
          : '${sceneKindLabel(node.kind)} · $name',
    );
  }
  return SceneReadableSummary(
    conditions,
    steps,
    graph.nodes.where((node) => !seen.contains(node.id)).length,
  );
}
