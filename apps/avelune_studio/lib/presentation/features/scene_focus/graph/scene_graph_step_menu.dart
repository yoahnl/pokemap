import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/steps/scene_step_families.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_templates.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_palette.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

typedef SceneGraphStepChoice = ({
  String id,
  String label,
  SceneGraphCategory category,
  SceneNodeKind? kind,
  SceneStepTemplate? template,
});

class SceneGraphStepMenu extends StatefulWidget {
  const SceneGraphStepMenu({
    super.key,
    required this.choices,
    required this.onChosen,
    required this.onDismiss,
    this.inline = false,
  });

  static const double width = 280;

  final List<SceneGraphStepChoice> choices;
  final ValueChanged<SceneStepTemplate> onChosen;
  final VoidCallback onDismiss;
  final bool inline;

  @override
  State<SceneGraphStepMenu> createState() => _SceneGraphStepMenuState();
}

class _SceneGraphStepMenuState extends State<SceneGraphStepMenu> {
  final _query = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.inline) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<SceneGraphStepChoice> get _matches {
    final query = _query.text.trim().toLowerCase();
    return [
      for (final choice in widget.choices)
        if (query.isEmpty ||
            choice.label.toLowerCase().contains(query) ||
            context.l10n
                .sceneGraphCategory(choice.category.name)
                .toLowerCase()
                .contains(query))
          choice,
    ];
  }

  void _chooseFirst() {
    final matches = _matches;
    for (final category in SceneGraphCategory.values) {
      for (final choice in matches) {
        if (choice.category == category && choice.template != null) {
          widget.onChosen(choice.template!);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = <SceneGraphCategory, List<SceneGraphStepChoice>>{};
    for (final choice in _matches) {
      (groups[choice.category] ??= []).add(choice);
    }
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.all(StudioSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioSearchField(
            key: const ValueKey('scene-graph-step-search'),
            controller: _query,
            focusNode: _focus,
            label: l10n.sceneGraphSearch,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: StudioSpacing.s),
          Flexible(
            child: ListView(
              shrinkWrap: !widget.inline,
              children: [
                if (groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(StudioSpacing.m),
                    child: Text(l10n.sceneGraphNoMatch),
                  ),
                for (final category in SceneGraphCategory.values)
                  if (groups[category] case final choices?) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        StudioSpacing.xs,
                        StudioSpacing.m,
                        StudioSpacing.xs,
                        StudioSpacing.xs,
                      ),
                      child: Text(
                        l10n.sceneGraphCategory(category.name),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    for (final choice in choices)
                      StudioChoice(
                        key: ValueKey('scene-graph-step-new-${choice.id}'),
                        dense: choice.template != null,
                        label: choice.label,
                        leading: Icon(
                          sceneGraphIcon(category, choice.kind),
                          size: 16,
                          color: sceneGraphAccent(
                            context,
                            category,
                            choice.kind,
                          ),
                        ),
                        subtitle: choice.template == null
                            ? l10n.sceneGraphUnavailable
                            : null,
                        onTap: switch (choice.template) {
                          final template? => () => widget.onChosen(template),
                          null => null,
                        },
                      ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
    return CallbackShortcuts(
      bindings: {
        if (!widget.inline)
          const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss,
        const SingleActivator(LogicalKeyboardKey.enter): _chooseFirst,
      },
      child: widget.inline
          ? content
          : Material(
              key: const ValueKey('scene-graph-step-menu'),
              elevation: 8,
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
              child: SizedBox(width: SceneGraphStepMenu.width, child: content),
            ),
    );
  }
}

List<SceneGraphStepChoice> sceneGraphStepChoices(
  BuildContext context,
  ProjectManifest? project,
  MapData? map, {
  bool enabled = true,
}) {
  final l10n = context.l10n;
  return [
    for (final family in sceneInsertableStepFamilies)
      (
        id: family.name,
        label: l10n.storyStepFamily(family.name),
        category: sceneGraphTemplateCategory(family),
        kind: family == SceneStepFamily.conditions
            ? SceneNodeKind.condition
            : null,
        template: !enabled || project == null
            ? null
            : sceneStepTemplateOf(family, project, map),
      ),
    (
      id: SceneNodeKind.end.name,
      label: l10n.sceneGraphKind(SceneNodeKind.end.name),
      category: SceneGraphCategory.flow,
      kind: SceneNodeKind.end,
      template: !enabled
          ? null
          : (
              kind: SceneNodeKind.end,
              payload: SceneEndPayload(
                outcomePolicy: SceneOutcomePolicy.progression,
              ),
            ),
    ),
  ];
}
