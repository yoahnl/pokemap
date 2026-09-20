import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'story_view_state.dart';

Future<StoryGraphSelection?> showStoryCoherence(
  BuildContext context,
  ProjectManifest project,
  String storyId,
) {
  final projection = buildStorylineProgressionProjection(
    project: project,
    storylineId: storyId,
  );
  final links = diagnoseStorylineSceneLinks(
    project: project,
  ).diagnostics.where((d) => d.storylineId == storyId);
  final rows = <(String, String?, String?)>[
    for (final diagnostic in projection.diagnostics)
      (diagnostic.message, diagnostic.nodeId, diagnostic.edgeId),
    for (final diagnostic in links)
      (diagnostic.message, 'step:${diagnostic.stepId}', null),
  ];
  return showDialog<StoryGraphSelection>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cohérence de l’histoire'),
      content: SizedBox(
        width: 600,
        height: 380,
        child: ListView(
          children: [
            const StudioNotice(
              'Vérification du document et de ses références dans les brouillons actuels. Elle ne simule pas une partie jouée.',
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              const Text('Aucune anomalie détectée par ces vérifications.'),
            for (final row in rows) ...[
              Text(row.$1),
              Builder(
                builder: (context) {
                  final node = projection.nodes
                      .where((n) => n.id == row.$2)
                      .firstOrNull;
                  final edge = projection.edges
                      .where((e) => e.id == row.$3)
                      .firstOrNull;
                  return StudioButton(
                    label: 'Retrouver dans le graphe',
                    secondary: true,
                    onPressed: node == null && edge == null
                        ? null
                        : () => Navigator.pop(
                            context,
                            edge != null
                                ? StoryGraphSelection.edge(edge)
                                : StoryGraphSelection.node(node!),
                          ),
                  );
                },
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
      actions: [
        StudioButton(
          label: 'Fermer',
          secondary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
