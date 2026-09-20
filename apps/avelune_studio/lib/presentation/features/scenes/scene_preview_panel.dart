import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_tool.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_view_state.dart';

class ScenePreviewPanel extends StatelessWidget {
  const ScenePreviewPanel({
    super.key,
    required this.scene,
    required this.view,
    required this.changed,
  });
  final SceneAsset scene;
  final SceneBuilderViewState view;
  final VoidCallback changed;
  @override
  Widget build(BuildContext context) {
    final result = view.preview;
    final awaiting = scene.graph.nodes
        .where((n) => n.id == result?.awaitingNodeId)
        .firstOrNull;
    return StudioPanel(
      compact: true,
      title: 'Prévisualisation du chemin',
      actions: [
        StudioTool(
          label: 'Replier la prévisualisation',
          icon: Icons.close,
          onPressed: () {
            view.previewOpen = false;
            changed();
          },
        ),
      ],
      children: [
        Expanded(
          child: ListView(
            children: [
              Text(
                'Entrées explicites · aucune partie ni document lié exécuté',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                view.previewError ??
                    (result == null
                        ? 'Aucune prévisualisation'
                        : switch (result.status) {
                            SceneDryRunPreviewStatus.completed =>
                              'Terminée · ${result.sceneOutcomeId ?? 'Fin'}',
                            SceneDryRunPreviewStatus.awaitingInput =>
                              'Choix attendu · ${awaiting?.title ?? awaiting?.id ?? ''}',
                            SceneDryRunPreviewStatus.failed =>
                              'Impossible · ${result.message ?? ''}',
                          }),
              ),
              if (awaiting != null) ...[
                const SizedBox(height: 12),
                StudioSelect(
                  label: 'Sortie à parcourir',
                  value: view.choices[awaiting.id],
                  options: {
                    for (final port in result!.acceptedOutputPortIds)
                      port: switch (port) {
                        'true' => 'Oui',
                        'false' => 'Non',
                        'completed' => 'Continuer',
                        _ => port,
                      },
                  },
                  onChanged: (port) {
                    view.choices[awaiting.id] = port;
                    view.calculate(scene);
                    changed();
                  },
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StudioButton(
                    label: 'Calculer le chemin',
                    secondary: true,
                    onPressed: () {
                      view.calculate(scene);
                      changed();
                    },
                  ),
                  StudioButton(
                    label: 'Effacer les choix',
                    secondary: true,
                    onPressed: () {
                      view.choices.clear();
                      view.calculate(scene);
                      changed();
                    },
                  ),
                ],
              ),
              if (result != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    result.trace
                        .map(
                          (entry) =>
                              scene.graph.nodes
                                  .firstWhere((n) => n.id == entry.nodeId)
                                  .title ??
                              entry.nodeId,
                        )
                        .join(' → '),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
