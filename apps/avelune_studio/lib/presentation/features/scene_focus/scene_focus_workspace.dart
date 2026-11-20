import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_choice_preview.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/map_workspace/coordination/editor_shortcuts.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_checks.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_edits.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_inspector.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_outline.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_sidebar.dart';
import 'package:avelune_studio/presentation/features/scene_focus/scene_focus_side.dart';
import 'package:avelune_studio/presentation/features/story/story_dialogue_link.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

part 'scene_focus_dialogues.dart';

class SceneFocusWorkspace extends StatefulWidget {
  const SceneFocusWorkspace({
    super.key,
    required this.focus,
    required this.scene,
    required this.project,
    required this.map,
    this.onOpenBehaviour,
  });

  static const double sideWidth = 248;
  static const double outlineWidth = 204;

  final SceneFocusController focus;
  final SceneAsset scene;
  final ProjectManifest project;
  final MapData? map;
  final Future<bool> Function(String eventId)? onOpenBehaviour;

  @override
  State<SceneFocusWorkspace> createState() => _SceneFocusWorkspaceState();
}

class _SceneFocusWorkspaceState extends State<SceneFocusWorkspace>
    with _SceneFocusDialogues {
  final _canvas = GlobalKey<SceneGraphCanvasState>();
  final _outlineSearch = TextEditingController();
  final _outlineFocus = FocusNode(debugLabel: 'scene-outline-search');
  Set<String> _selection = const {};
  SceneAsset? _checked;
  late SceneGraphChecks _checks;
  var _active = false;
  var _initialFocusPlaced = false;
  var _palette = false;
  List<NarrativeTitle>? _facts;
  Map<String, String> _factNames = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_active) return;
        if ((_initialFocusPlaced, widget.focus.initialNodeId) case (
          false,
          final id?,
        )) {
          _initialFocusPlaced = true;
          _canvas.currentState?.show(id);
        }
        _canvas.currentState?.requestFocus();
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

  void _findStep() {
    _setPalette(false);
    _outlineFocus.requestFocus();
  }

  @override
  void dispose() {
    _outlineSearch.dispose();
    _outlineFocus.dispose();
    super.dispose();
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
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: textAwareEditorShortcuts({
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _findStep,
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): _findStep,
    }),
    child: FutureBuilder<DialogueCatalogLanguages>(
      future: _languages,
      builder: (context, snapshot) => _buildGraph(
        context,
        _dialoguePreview(snapshot.data ?? const DialogueCatalogLanguages()),
      ),
    ),
  );

  Widget _buildGraph(BuildContext context, _SceneDialoguePreview dialogues) {
    final focus = widget.focus;
    final scene = widget.scene;
    final checks = _currentChecks;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (outlineWidth, detailsWidth) = switch (MediaQuery.sizeOf(context)
        .width) {
      <= 850 => (150.0, 205.0),
      <= 1150 => (180.0, 228.0),
      _ => (SceneFocusWorkspace.outlineWidth, SceneFocusWorkspace.sideWidth),
    };
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
              if (dialogues.options.length > 1) ...[
                SizedBox(
                  width: 160,
                  child: StudioSelect(
                    key: const ValueKey('scene-graph-preview-language'),
                    label: l10n.dialogueCatalogPreviewLanguage,
                    value: dialogues.language,
                    options: dialogues.options,
                    onChanged: (value) => setState(() => _language = value),
                    compact: true,
                  ),
                ),
                const SizedBox(width: StudioSpacing.s),
              ],
              if (dialogues.fallbackLocales.isNotEmpty)
                StudioBadge(
                  l10n.dialogueCatalogFallback(
                    dialogues.fallbackLocales.join(', ').toUpperCase(),
                  ),
                  tone: StudioTone.warning,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: outlineWidth,
                child: SceneGraphSidebar(
                  outline: SceneGraphOutline(
                    scene: scene,
                    selection: _selection,
                    dialogues: dialogues.entries,
                    factNames: _currentFactNames,
                    search: _outlineSearch,
                    searchFocus: _outlineFocus,
                    onShow: _showStep,
                  ),
                  project: widget.project,
                  map: widget.map,
                  palette: _palette,
                  onTab: _setPalette,
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
                    dialogues: dialogues.entries,
                    choiceLabels: dialogues.labels,
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
                key: const ValueKey('scene-graph-details-pane'),
                width: detailsWidth,
                child: SceneFocusSide(
                  focus: focus,
                  dialogues: dialogues.entries,
                  choiceLabels: dialogues.labels,
                  dialogueNotices: [
                    for (final MapEntry(:key, :value)
                        in dialogues.notices.entries)
                      Text(
                        value == DialogueChoicePreviewStatus.unavailable
                            ? l10n.sceneGraphDialogueUnavailable(
                                dialogues.entries[key]!.name,
                              )
                            : l10n.sceneGraphDialogueSource(
                                dialogues.entries[key]!.name,
                              ),
                        key: ValueKey(
                          'scene-graph-dialogue-${value.name}-$key',
                        ),
                      ),
                  ],
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
                    dialogueLanguage: dialogues.language,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
