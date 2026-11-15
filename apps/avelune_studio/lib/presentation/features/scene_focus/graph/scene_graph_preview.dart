import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_checks.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_camera.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_world.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneGraphPreview extends StatefulWidget {
  const SceneGraphPreview({
    super.key,
    required this.scene,
    required this.project,
    required this.onOpen,
  });

  static const double height = 160;

  final SceneAsset scene;
  final ProjectManifest? project;
  final VoidCallback? onOpen;

  @override
  State<SceneGraphPreview> createState() => _SceneGraphPreviewState();
}

class _SceneGraphPreviewState extends State<SceneGraphPreview> {
  SceneAsset? _projected;
  late SceneGraphView _view;
  late SceneGraphChecks _checks;

  void _project() {
    if (identical(_projected, widget.scene)) return;
    _projected = widget.scene;
    _view = projectSceneGraph(widget.scene);
    _checks = checkSceneGraph(widget.scene);
  }

  @override
  Widget build(BuildContext context) {
    _project();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bounds = sceneGraphBounds(_view);
    final steps = _view.cards.length;
    return Column(
      key: ValueKey('scene-graph-preview-${widget.scene.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('scene-graph-preview-open'),
            onTap: widget.onOpen,
            child: SizedBox(
              height: SceneGraphPreview.height,
              child: bounds.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.all(StudioSpacing.m),
                      child: IgnorePointer(
                        child: FittedBox(
                          child: SizedBox(
                            width: bounds.width,
                            height: bounds.height,
                            child: SceneGraphWorld(
                              view: _view,
                              bounds: bounds,
                              scene: widget.scene,
                              project: widget.project,
                              selected: const {},
                              pathNodeIds: const {},
                              pathEdgeIds: const {},
                              dialogueNames: const {},
                              checks: _checks,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: StudioSpacing.s),
        Text(
          l10n.sceneGraphPreviewSummary(steps, _checks.problems.length),
          key: const ValueKey('scene-graph-preview-summary'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: _checks.blocking ? scheme.error : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
