import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_card_tile.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_painters.dart';

class SceneGraphWorld extends StatelessWidget {
  const SceneGraphWorld({
    super.key,
    required this.view,
    required this.bounds,
    required this.scene,
    required this.project,
    required this.selected,
    required this.pathNodeIds,
    required this.pathEdgeIds,
    required this.dialogueNames,
  });

  final SceneGraphView view;
  final Rect bounds;
  final SceneAsset scene;
  final ProjectManifest? project;
  final Set<String> selected;
  final Set<String> pathNodeIds;
  final Set<String> pathEdgeIds;
  final Map<String, String> dialogueNames;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final studio = StudioColors.of(context);
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: 0,
      minHeight: 0,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: SizedBox(
        width: bounds.width,
        height: bounds.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: SceneGraphWirePainter(
                  view: view,
                  origin: bounds.topLeft,
                  pathEdgeIds: pathEdgeIds,
                  colors: SceneGraphWireColors(
                    idle: scheme.onSurfaceVariant,
                    path: studio.featureAccent,
                    loop: scheme.error,
                    undeclared: studio.warning,
                  ),
                ),
              ),
            ),
            for (final card in view.cards)
              Positioned(
                left: card.position.x - bounds.left,
                top: card.position.y - bounds.top,
                child: SceneGraphCardTile(
                  key: ValueKey('scene-graph-card-${card.id}'),
                  card: card,
                  scene: scene,
                  project: project,
                  selected: selected.contains(card.id),
                  onPath: pathNodeIds.contains(card.id),
                  dialogueNames: dialogueNames,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
