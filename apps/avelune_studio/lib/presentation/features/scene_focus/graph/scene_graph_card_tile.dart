import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_metrics.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneGraphCardTile extends StatelessWidget {
  const SceneGraphCardTile({
    super.key,
    required this.card,
    required this.scene,
    required this.project,
    required this.selected,
    required this.onPath,
    this.dialogueNames = const {},
  });

  static const double portRadius = 5;

  final SceneGraphCard card;
  final SceneAsset scene;
  final ProjectManifest? project;
  final bool selected;
  final bool onPath;
  final Map<String, String> dialogueNames;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = sceneGraphFamilyColor(context, card.family);
    final studio = StudioColors.of(context);
    final title = card.node.title?.trim();
    final detail = sceneGraphCardDetail(
      l10n,
      card.node,
      scene,
      project,
      dialogueNames,
    );
    final named = title != null && title.isNotEmpty;
    final border = selected
        ? BorderSide(color: studio.canvasSelection, width: 2)
        : onPath
        ? BorderSide(color: studio.featureAccent, width: 2)
        : BorderSide(color: scheme.outlineVariant);
    return SizedBox(
      width: SceneGraphMetrics.cardWidth,
      height: card.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
                border: Border.fromBorderSide(border),
              ),
              child: _background(
                scheme.surfaceContainerHigh,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: SceneGraphMetrics.headerHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: StudioSpacing.l,
                      ),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .28),
                      ),
                      child: _line(
                        l10n.sceneGraphKind(card.node.kind.name),
                        theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      height: SceneGraphMetrics.bodyHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: StudioSpacing.l,
                        vertical: StudioSpacing.xs,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (named) _line(title, theme.textTheme.bodyMedium),
                          if (detail != null)
                            _line(
                              detail,
                              theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              maxLines: named ? 1 : 2,
                            ),
                        ],
                      ),
                    ),
                    for (final port in card.outputs)
                      Container(
                        key: ValueKey('scene-graph-port-${card.id}-${port.id}'),
                        height: SceneGraphMetrics.portRowHeight,
                        padding: const EdgeInsets.only(right: StudioSpacing.l),
                        alignment: Alignment.centerRight,
                        child: _line(
                          l10n.sceneGraphPort(port.id),
                          theme.textTheme.labelSmall?.copyWith(
                            color: port.declared ? null : studio.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (card.acceptsInput)
            _dot(
              left: -portRadius,
              top: SceneGraphMetrics.inputPortY - portRadius,
              color: scheme.onSurfaceVariant,
              filled: true,
            ),
          for (final (index, port) in card.outputs.indexed)
            _dot(
              left: SceneGraphMetrics.cardWidth - portRadius,
              top: SceneGraphMetrics.outputPortY(index) - portRadius,
              color: port.declared ? accent : studio.warning,
              filled: port.connected,
            ),
        ],
      ),
    );
  }

  Widget _background(Color color, Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
    child: ColoredBox(color: color, child: child),
  );

  Widget _line(String text, TextStyle? style, {int maxLines = 1}) => Text(
    text,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    style: style,
  );

  Widget _dot({
    required double left,
    required double top,
    required Color color,
    required bool filled,
  }) => Positioned(
    left: left,
    top: top,
    width: portRadius * 2,
    height: portRadius * 2,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : null,
        border: Border.all(color: color, width: 1.5),
      ),
    ),
  );
}
