import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_checks.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_card_tile.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_labels.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_painters.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneGraphWorld extends StatefulWidget {
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
    required this.checks,
    this.dialogues = const {},
    this.factNames = const {},
    this.map,
  });

  final SceneGraphView view;
  final Rect bounds;
  final SceneAsset scene;
  final ProjectManifest? project;
  final Set<String> selected;
  final Set<String> pathNodeIds;
  final Set<String> pathEdgeIds;
  final Map<String, String> dialogueNames;
  final Map<String, ProjectDialogueEntry> dialogues;
  final Map<String, String> factNames;
  final MapData? map;
  final SceneGraphChecks checks;

  @override
  State<SceneGraphWorld> createState() => _SceneGraphWorldState();
}

class _SceneGraphWorldState extends State<SceneGraphWorld> {
  final _details = <SceneNode, String?>{};
  final _dialogues = <String, ProjectDialogueEntry?>{};

  @override
  void didUpdateWidget(SceneGraphWorld oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.scene, widget.scene) ||
        !identical(oldWidget.project, widget.project) ||
        !identical(oldWidget.map, widget.map) ||
        !identical(oldWidget.factNames, widget.factNames) ||
        oldWidget.dialogues.length != widget.dialogues.length ||
        oldWidget.dialogues.entries.any(
          (entry) => widget.dialogues[entry.key] != entry.value,
        ) ||
        oldWidget.dialogueNames.length != widget.dialogueNames.length ||
        oldWidget.dialogueNames.entries.any(
          (entry) => widget.dialogueNames[entry.key] != entry.value,
        )) {
      _details.clear();
      _dialogues.clear();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _details.clear();
  }

  String? _detail(SceneNode node, ProjectDialogueEntry? dialogue) =>
      _details.putIfAbsent(
        node,
        () => sceneGraphCardDetail(
          context.l10n,
          node,
          widget.scene,
          widget.project,
          switch (node.payload) {
            SceneYarnDialoguePayload(:final dialogueId) =>
              widget.dialogueNames[dialogueId] ?? dialogue?.name,
            _ => null,
          },
          map: widget.map,
          factNames: widget.factNames,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final SceneGraphWorld(
      :view,
      :bounds,
      :selected,
      :pathNodeIds,
      :pathEdgeIds,
      :checks,
    ) = widget;
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
                  faultyEdgeIds: {
                    for (final wire in view.wires)
                      if (checks.levelOfEdge(wire.id) ==
                          SceneGraphProblemLevel.blocking)
                        wire.id,
                  },
                  colors: SceneGraphWireColors(
                    idle: scheme.onSurface.withValues(alpha: .86),
                    path: studio.featureAccent,
                    loop: scheme.error,
                    undeclared: studio.warning,
                  ),
                ),
              ),
            ),
            for (final card in view.cards)
              _card(card, bounds, selected, pathNodeIds, checks),
          ],
        ),
      ),
    );
  }

  Widget _card(
    SceneGraphCard card,
    Rect bounds,
    Set<String> selected,
    Set<String> pathNodeIds,
    SceneGraphChecks checks,
  ) {
    final dialogue = switch (card.node.payload) {
      SceneYarnDialoguePayload(:final dialogueId) => _dialogues.putIfAbsent(
        dialogueId,
        () =>
            widget.dialogues[dialogueId] ??
            widget.project?.dialogues
                .where((entry) => entry.id == dialogueId)
                .firstOrNull,
      ),
      _ => null,
    };
    return Positioned(
      left: card.position.x - bounds.left,
      top: card.position.y - bounds.top,
      child: SceneGraphCardTile(
        key: ValueKey('scene-graph-card-${card.id}'),
        card: card,
        selected: selected.contains(card.id),
        onPath: pathNodeIds.contains(card.id),
        problem: checks.levelOfNode(card.id),
        dialogue: dialogue,
        detail: _detail(card.node, dialogue),
      ),
    );
  }
}
