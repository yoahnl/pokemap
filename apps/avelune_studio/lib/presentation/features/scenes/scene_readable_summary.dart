import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'scene_graph_canvas.dart';
import 'scene_inspector.dart';

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
    steps.add(
      node.kind == SceneNodeKind.end
          ? 'Fin · ${label(node)}'
          : '${sceneKindLabel(node.kind)} · ${label(node)}',
    );
  }
  return SceneReadableSummary(
    conditions,
    steps,
    graph.nodes.where((node) => !seen.contains(node.id)).length,
  );
}

class SceneReadableSummaryPanel extends StatelessWidget {
  const SceneReadableSummaryPanel({
    super.key,
    required this.scene,
    required this.label,
    required this.onClose,
  });

  final SceneAsset scene;
  final String Function(SceneNode node) label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final summary = sceneReadableSummary(scene, label);
    final small = Theme.of(context).textTheme.bodySmall;
    Widget section(String title, List<String> lines, String empty) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        if (lines.isEmpty) Text(empty, style: small),
        for (final line in lines) Text(line),
        const SizedBox(height: 8),
      ],
    );
    return StudioPanel(
      key: const ValueKey('scene-readable-summary'),
      title: 'Résumé de la scène',
      actions: [
        StudioTool(
          label: 'Replier le résumé',
          icon: Icons.close,
          onPressed: onClose,
        ),
      ],
      children: [
        Expanded(
          child: ListView(
            children: [
              Text(
                'Aide de lecture : le graphe reste la référence et se modifie seul.',
                style: small,
              ),
              const SizedBox(height: 8),
              section('Quand', const [
                'La scène est lancée par un événement, une autre scène ou un test.',
              ], ''),
              section('Si', summary.conditions, 'Aucune condition.'),
              section(
                'Alors',
                summary.steps,
                'Aucun bloc relié au départ pour le moment.',
              ),
              if (summary.unreached > 0)
                Text(
                  '${summary.unreached} ${summary.unreached > 1 ? 'blocs ne sont' : 'bloc n’est'} relié${summary.unreached > 1 ? 's' : ''} à aucun chemin depuis le départ.',
                  style: small,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
