import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/steps/scene_step_templates.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

typedef SceneGraphStepChoice = ({
  String id,
  String label,
  SceneStepTemplate? template,
});

class SceneGraphStepMenu extends StatefulWidget {
  const SceneGraphStepMenu({
    super.key,
    required this.choices,
    required this.onChosen,
    required this.onDismiss,
  });

  static const double width = 280;

  final List<SceneGraphStepChoice> choices;
  final ValueChanged<SceneStepTemplate> onChosen;
  final VoidCallback onDismiss;

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
      if (mounted) _focus.requestFocus();
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
        if (query.isEmpty || choice.label.toLowerCase().contains(query)) choice,
    ];
  }

  void _chooseFirst() {
    final template = _matches
        .map((choice) => choice.template)
        .whereType<SceneStepTemplate>()
        .firstOrNull;
    if (template != null) widget.onChosen(template);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matches = _matches;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss,
        const SingleActivator(LogicalKeyboardKey.enter): _chooseFirst,
      },
      child: Material(
        key: const ValueKey('scene-graph-step-menu'),
        elevation: 8,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
        child: SizedBox(
          width: SceneGraphStepMenu.width,
          child: Padding(
            padding: const EdgeInsets.all(StudioSpacing.m),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                if (matches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(StudioSpacing.m),
                    child: Text(l10n.sceneGraphNoMatch),
                  ),
                for (final choice in matches)
                  StudioChoice(
                    key: ValueKey('scene-graph-step-new-${choice.id}'),
                    dense: choice.template != null,
                    label: choice.label,
                    subtitle: choice.template == null
                        ? l10n.sceneGraphUnavailable
                        : null,
                    onTap: switch (choice.template) {
                      final template? => () => widget.onChosen(template),
                      null => null,
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<SceneGraphStepChoice> sceneGraphStepChoices(
  BuildContext context,
  ProjectManifest? project,
  MapData? map,
) {
  final l10n = context.l10n;
  return [
    for (final family in sceneInsertableStepFamilies)
      (
        id: family.name,
        label: l10n.storyStepFamily(family.name),
        template: project == null
            ? null
            : sceneStepTemplateOf(family, project, map),
      ),
    (
      id: SceneNodeKind.end.name,
      label: l10n.sceneGraphKind(SceneNodeKind.end.name),
      template: (
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ),
  ];
}
