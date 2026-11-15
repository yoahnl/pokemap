import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_steps.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

enum SceneFocusView { graph, steps }

class SceneFocusWorkspace extends StatefulWidget {
  const SceneFocusWorkspace({
    super.key,
    required this.focus,
    required this.scene,
    required this.project,
    required this.map,
  });

  final SceneFocusController focus;
  final SceneAsset scene;
  final ProjectManifest project;
  final MapData? map;

  @override
  State<SceneFocusWorkspace> createState() => _SceneFocusWorkspaceState();
}

class _SceneFocusWorkspaceState extends State<SceneFocusWorkspace> {
  var _view = SceneFocusView.graph;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final focus = widget.focus;
    final scene = widget.scene;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioTabBar<SceneFocusView>(
          key: const ValueKey('scene-focus-views'),
          height: StudioMetrics.controlHeight,
          tabs: [
            StudioTab(
              key: const ValueKey('scene-focus-view-graph'),
              value: SceneFocusView.graph,
              label: l10n.sceneFocusGraphTab,
            ),
            StudioTab(
              key: const ValueKey('scene-focus-view-steps'),
              value: SceneFocusView.steps,
              label: l10n.sceneFocusStepsTab,
            ),
          ],
          selected: _view,
          onSelected: (view) => setState(() => _view = view),
        ),
        Expanded(
          child: IndexedStack(
            index: _view.index,
            sizing: StackFit.expand,
            children: [
              SceneGraphCanvas(
                key: ValueKey('scene-focus-graph-${scene.id}'),
                scene: scene,
                project: widget.project,
                pathNodeIds: focus.path?.nodeIds ?? const [],
                pathChoices: focus.choices,
                dialogueNames: {
                  for (final dialogue
                      in focus.document.value?.dialogues ??
                          const <StoryDialogueSource>[])
                    dialogue.id: dialogue.entry.name,
                },
              ),
              ListView(
                padding: const EdgeInsets.all(StudioSpacing.l),
                children: [
                  MapBuilderStorySteps(
                    key: ValueKey('scene-focus-steps-${scene.id}'),
                    scene: scene,
                    project: widget.project,
                    map: widget.map,
                    enabled: focus.draft.editable && !focus.previewing,
                    highlighted: focus.path?.nodeIds.toSet(),
                    onChanged: focus.edit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
