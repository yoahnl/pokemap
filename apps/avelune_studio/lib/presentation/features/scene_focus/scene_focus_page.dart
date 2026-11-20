import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/presentation/features/scene_focus/scene_focus_workspace.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneFocusPage extends StatelessWidget {
  const SceneFocusPage({
    super.key,
    required this.focus,
    required this.project,
    required this.map,
    required this.onClose,
    required this.onDetached,
    this.onOpenBehaviour,
  });

  final SceneFocusController focus;
  final ProjectManifest? project;
  final MapData? map;
  final VoidCallback onClose;
  final ValueChanged<String> onDetached;
  final Future<bool> Function(String eventId)? onOpenBehaviour;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scene = focus.scene;
    final state = gameMemoryResourceState(
      context,
      focus.document,
      loading: l10n.sceneFocusLoading,
      onRetry: focus.retry,
    );
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
      child: Focus(
        autofocus: true,
        child: Material(
          key: const ValueKey('scene-focus'),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(StudioSpacing.l),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('scene-focus-close'),
                      tooltip: l10n.sceneFocusClose,
                      onPressed: onClose,
                      icon: Icon(
                        Icons.close,
                        semanticLabel: l10n.sceneFocusClose,
                      ),
                    ),
                    const SizedBox(width: StudioSpacing.s),
                    Expanded(
                      child: Text(
                        scene?.name ?? l10n.sceneFocusLoading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    StudioButton(
                      key: const ValueKey('scene-focus-preview'),
                      label: focus.previewing
                          ? l10n.sceneFocusPreviewStop
                          : l10n.sceneFocusPreview,
                      icon: Icons.alt_route,
                      variant: StudioButtonVariant.secondary,
                      onPressed: scene == null ? null : focus.togglePreview,
                    ),
                  ],
                ),
              ),
              if (state == null && focus.shared)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StudioSpacing.l,
                    0,
                    StudioSpacing.l,
                    StudioSpacing.m,
                  ),
                  child: _SharedBanner(focus: focus, onDetached: onDetached),
                ),
              Expanded(
                child: switch ((state, scene, project)) {
                  (final state?, _, _) => state,
                  (null, final scene?, final project?) => SceneFocusWorkspace(
                    focus: focus,
                    scene: scene,
                    project: project,
                    map: map,
                    onOpenBehaviour: onOpenBehaviour,
                  ),
                  _ => StudioLoadingState(label: l10n.sceneFocusLoading),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SharedBanner extends StatelessWidget {
  const _SharedBanner({required this.focus, required this.onDetached});

  final SceneFocusController focus;
  final ValueChanged<String> onDetached;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = focus.scene?.name ?? '';
    return Column(
      key: const ValueKey('scene-focus-shared'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioNotice(l10n.sceneFocusShared(focus.launchers.length)),
        if (focus.canDetach) ...[
          const SizedBox(height: StudioSpacing.s),
          Row(
            children: [
              StudioButton(
                key: const ValueKey('scene-focus-detach'),
                label: l10n.sceneFocusDetach,
                icon: Icons.call_split,
                variant: StudioButtonVariant.secondary,
                onPressed: () {
                  if (focus.detach(l10n.sceneFocusCopyName(name))
                      case final id?) {
                    onDetached(id);
                  }
                },
              ),
              const SizedBox(width: StudioSpacing.m),
              Expanded(
                child: Text(
                  l10n.sceneFocusDetachHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
