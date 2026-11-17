import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/steps/scene_step_templates.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'scene_graph_step_menu.dart';

class SceneGraphSidebar extends StatelessWidget {
  const SceneGraphSidebar({
    super.key,
    required this.outline,
    required this.project,
    required this.map,
    required this.palette,
    required this.onTab,
    required this.onAdd,
  });

  final Widget outline;
  final ProjectManifest project;
  final MapData? map;
  final bool palette;
  final ValueChanged<bool> onTab;
  final ValueChanged<SceneStepTemplate>? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioTabBar<bool>(
            fill: true,
            height: StudioMetrics.controlHeight,
            tabs: [
              StudioTab(
                value: false,
                label: l10n.sceneGraphOutline,
                key: const ValueKey('scene-graph-outline-tab'),
              ),
              StudioTab(
                value: true,
                label: l10n.sceneGraphPalette,
                key: const ValueKey('scene-graph-palette-tab'),
              ),
            ],
            selected: palette,
            onSelected: onTab,
          ),
          Expanded(
            child: palette
                ? SceneGraphStepMenu(
                    inline: true,
                    choices: sceneGraphStepChoices(
                      context,
                      project,
                      map,
                      enabled: onAdd != null,
                    ),
                    onChosen: onAdd ?? (_) {},
                    onDismiss: () => onTab(false),
                  )
                : outline,
          ),
        ],
      ),
    );
  }
}
