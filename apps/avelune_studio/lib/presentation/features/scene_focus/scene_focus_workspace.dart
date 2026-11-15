import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_checks.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_edits.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_inspector.dart';
import 'package:avelune_studio/presentation/features/scene_focus/scene_focus_side.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneFocusWorkspace extends StatefulWidget {
  const SceneFocusWorkspace({
    super.key,
    required this.focus,
    required this.scene,
    required this.project,
    required this.map,
  });

  static const double sideWidth = 380;

  final SceneFocusController focus;
  final SceneAsset scene;
  final ProjectManifest project;
  final MapData? map;

  @override
  State<SceneFocusWorkspace> createState() => _SceneFocusWorkspaceState();
}

class _SceneFocusWorkspaceState extends State<SceneFocusWorkspace> {
  final _canvas = GlobalKey<SceneGraphCanvasState>();
  Set<String> _selection = const {};
  SceneAsset? _checked;
  late SceneGraphChecks _checks;

  SceneGraphChecks get _currentChecks {
    if (!identical(_checked, widget.scene)) {
      _checked = widget.scene;
      _checks = checkSceneGraph(widget.scene);
    }
    return _checks;
  }

  bool get _editable => widget.focus.draft.editable && !widget.focus.previewing;

  void _editStep(SceneNode node) {
    switch (editSceneGraphStep(widget.scene, node)) {
      case SceneGraphEdited(:final scene):
        widget.focus.edit(scene);
      case SceneGraphEditRefused(:final reason):
        ScaffoldMessenger.maybeOf(context)
          ?..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.sceneGraphRefused(reason.name)),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final focus = widget.focus;
    final scene = widget.scene;
    final checks = _currentChecks;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: KeyedSubtree(
            key: ValueKey('scene-focus-graph-${scene.id}'),
            child: SceneGraphCanvas(
              key: _canvas,
              scene: scene,
              project: widget.project,
              map: widget.map,
              checks: checks,
              pathNodeIds: focus.path?.nodeIds ?? const [],
              pathChoices: focus.choices,
              dialogueNames: {
                for (final dialogue
                    in focus.document.value?.dialogues ??
                        const <StoryDialogueSource>[])
                  dialogue.id: dialogue.entry.name,
              },
              onChanged: _editable ? focus.edit : null,
              onSelectionChanged: (ids) => setState(() => _selection = ids),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: SceneFocusWorkspace.sideWidth,
          child: SceneFocusSide(
            focus: focus,
            leading: SceneGraphInspector(
              scene: scene,
              project: widget.project,
              map: widget.map,
              selection: _selection,
              checks: checks,
              editable: _editable,
              onEdit: _editStep,
              onShow: (id) => _canvas.currentState?.show(id),
            ),
          ),
        ),
      ],
    );
  }
}
