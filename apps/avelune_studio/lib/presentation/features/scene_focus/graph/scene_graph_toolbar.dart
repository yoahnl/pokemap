import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_camera.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneGraphToolbar extends StatelessWidget {
  const SceneGraphToolbar({
    super.key,
    required this.camera,
    required this.onShowAll,
    required this.onZoom,
    this.editable = false,
    this.preparing = false,
  });

  final ValueListenable<SceneGraphCamera> camera;
  final VoidCallback? onShowAll;
  final ValueChanged<double?> onZoom;
  final bool editable;
  final bool preparing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hint = switch ((editable, preparing)) {
      (true, _) =>
        '${l10n.sceneGraphEditHint}\n${l10n.sceneGraphNavigationHint}',
      (false, true) =>
        '${l10n.sceneGraphPreparing}\n${l10n.sceneGraphNavigationHint}',
      (false, false) => l10n.sceneGraphNavigationHint,
    };
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StudioSpacing.s,
          vertical: StudioSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onShowAll case final fit?) ...[
              StudioButton(
                key: const ValueKey('scene-graph-show-all'),
                label: l10n.sceneGraphFit,
                icon: Icons.fit_screen,
                variant: StudioButtonVariant.quiet,
                onPressed: fit,
              ),
              const SizedBox(width: StudioSpacing.m),
            ],
            StudioTool(
              key: const ValueKey('scene-graph-zoom-out'),
              label: l10n.sceneGraphZoomOut,
              icon: Icons.remove,
              onPressed: () => onZoom(1 / 1.2),
            ),
            ValueListenableBuilder(
              valueListenable: camera,
              builder: (context, value, _) => StudioButton(
                key: const ValueKey('scene-graph-zoom'),
                label: l10n.sceneGraphZoom((value.scale * 100).round()),
                variant: StudioButtonVariant.quiet,
                onPressed: () => onZoom(null),
              ),
            ),
            StudioTool(
              key: const ValueKey('scene-graph-zoom-in'),
              label: l10n.sceneGraphZoomIn,
              icon: Icons.add,
              onPressed: () => onZoom(1.2),
            ),
            if (preparing && !editable) ...[
              const SizedBox(width: StudioSpacing.m),
              Text(l10n.sceneGraphPreparing, style: theme.textTheme.labelSmall),
            ],
            Tooltip(
              message: hint,
              triggerMode: TooltipTriggerMode.tap,
              child: SizedBox.square(
                dimension: StudioMetrics.controlHeight,
                child: Icon(
                  Icons.help_outline,
                  size: 17,
                  semanticLabel: l10n.sceneGraphHelp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
