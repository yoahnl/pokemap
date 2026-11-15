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
    this.editable = false,
  });

  final ValueListenable<SceneGraphCamera> camera;
  final VoidCallback onShowAll;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Row(
      children: [
        StudioButton(
          key: const ValueKey('scene-graph-show-all'),
          label: l10n.sceneGraphFit,
          icon: Icons.fit_screen,
          variant: StudioButtonVariant.secondary,
          onPressed: onShowAll,
        ),
        const SizedBox(width: StudioSpacing.m),
        ValueListenableBuilder(
          valueListenable: camera,
          builder: (context, value, _) => Text(
            l10n.sceneGraphZoom((value.scale * 100).round()),
            key: const ValueKey('scene-graph-zoom'),
            style: theme.textTheme.labelMedium,
          ),
        ),
        const SizedBox(width: StudioSpacing.l),
        Expanded(
          child: Text(
            editable
                ? '${l10n.sceneGraphEditHint}\n${l10n.sceneGraphNavigationHint}'
                : l10n.sceneGraphNavigationHint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
