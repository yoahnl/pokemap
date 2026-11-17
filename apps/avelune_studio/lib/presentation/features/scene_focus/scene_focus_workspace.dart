import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_checks.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_edits.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_inspector.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_sidebar.dart';
import 'package:avelune_studio/presentation/features/scene_focus/scene_focus_side.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneFocusWorkspace extends StatefulWidget {
  const SceneFocusWorkspace({
    super.key,
    required this.focus,
    required this.scene,
    required this.project,
    required this.map,
    this.onOpenBehaviour,
  });

  static const double sideWidth = 304;
  static const double outlineWidth = 204;
  static const double _compactSideWidth = 246;
  static const double _preferredCanvasWidth = 764;

  final SceneFocusController focus;
  final SceneAsset scene;
  final ProjectManifest project;
  final MapData? map;
  final Future<bool> Function(String eventId)? onOpenBehaviour;

  @override
  State<SceneFocusWorkspace> createState() => _SceneFocusWorkspaceState();
}

class _SceneFocusWorkspaceState extends State<SceneFocusWorkspace> {
  final _canvas = GlobalKey<SceneGraphCanvasState>();
  Set<String> _selection = const {};
  SceneAsset? _checked;
  late SceneGraphChecks _checks;
  var _active = false;
  var _palette = false;
  List<NarrativeTitle>? _facts;
  Map<String, String> _factNames = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _active) _canvas.currentState?.requestFocus();
      });
    }
    _active = active;
  }

  SceneGraphChecks get _currentChecks {
    if (!identical(_checked, widget.scene)) {
      _checked = widget.scene;
      _checks = checkSceneGraph(widget.scene);
    }
    return _checks;
  }

  bool get _editable => widget.focus.draft.editable && !widget.focus.previewing;

  Map<String, String> get _currentFactNames {
    final facts = widget.focus.facts.value;
    if (!identical(facts, _facts)) {
      _facts = facts;
      _factNames = {
        for (final fact in facts ?? const <NarrativeTitle>[])
          fact.id: fact.title,
      };
    }
    return _factNames;
  }

  void _showStep(String id) {
    _canvas.currentState?.show(id);
    _canvas.currentState?.requestFocus();
  }

  void _setPalette(bool value) {
    _canvas.currentState?.dismissStepMenu();
    setState(() => _palette = value);
  }

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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
          child: Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: StudioSpacing.s),
              Expanded(
                child: Text(
                  l10n.sceneGraphSummary(
                    scene.graph.nodes.length,
                    scene.graph.edges.length,
                  ),
                  style: theme.textTheme.labelMedium,
                ),
              ),
              StudioButton(
                key: const ValueKey('scene-graph-open-palette'),
                label: l10n.sceneGraphSearch,
                icon: Icons.add,
                variant: StudioButtonVariant.quiet,
                onPressed: _editable ? () => _setPalette(true) : null,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: SceneFocusWorkspace.outlineWidth,
                  child: SceneGraphSidebar(
                    scene: scene,
                    project: widget.project,
                    map: widget.map,
                    selection: _selection,
                    palette: _palette,
                    onTab: _setPalette,
                    onShow: _showStep,
                    onAdd: _editable
                        ? (template) =>
                              _canvas.currentState?.addFromPalette(template)
                        : null,
                  ),
                ),
                const VerticalDivider(width: 1),
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
                      dialogues: {
                        for (final dialogue
                            in focus.document.value?.dialogues ??
                                const <StoryDialogueSource>[])
                          dialogue.id: dialogue.entry,
                      },
                      factNames: _currentFactNames,
                      onChanged: _editable ? focus.edit : null,
                      onSelectionChanged: (ids) =>
                          setState(() => _selection = ids),
                      preparing: focus.draft.preparing,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width:
                      (constraints.maxWidth -
                              SceneFocusWorkspace.outlineWidth -
                              SceneFocusWorkspace._preferredCanvasWidth -
                              2)
                          .clamp(
                            SceneFocusWorkspace._compactSideWidth,
                            SceneFocusWorkspace.sideWidth,
                          )
                          .toDouble(),
                  child: SceneFocusSide(
                    focus: focus,
                    onOpenBehaviour: widget.onOpenBehaviour,
                    leading: SceneGraphInspector(
                      scene: scene,
                      project: widget.project,
                      map: widget.map,
                      selection: _selection,
                      checks: checks,
                      editable: _editable,
                      onEdit: _editStep,
                      onShow: _showStep,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
