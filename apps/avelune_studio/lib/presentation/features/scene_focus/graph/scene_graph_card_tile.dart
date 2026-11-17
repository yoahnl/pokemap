import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_checks.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_metrics.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_labels.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_palette.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneGraphCardTile extends StatelessWidget {
  const SceneGraphCardTile({
    super.key,
    required this.card,
    required this.selected,
    required this.onPath,
    this.problem,
    this.dialogue,
    this.choiceLabels = const {},
    this.detail,
  });

  static const double portRadius = 5;

  final SceneGraphCard card;
  final bool selected;
  final bool onPath;
  final SceneGraphProblemLevel? problem;
  final ProjectDialogueEntry? dialogue;
  final Map<String, String> choiceLabels;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = sceneGraphNodeAccent(context, card.node);
    final studio = StudioColors.of(context);
    final title = sceneGraphNodeTitle(l10n, card.node);
    final detail = this.detail;
    final category = l10n.sceneGraphCategory(
      sceneGraphCategory(card.node).name,
    );
    final radius = BorderRadius.circular(StudioMetrics.controlRadius);
    final surface = scheme.surface;
    final roomy = MediaQuery.textScalerOf(context).scale(12) <= 14;
    final border = selected
        ? BorderSide(color: studio.canvasSelection, width: 2)
        : onPath
        ? BorderSide(color: studio.featureAccent, width: 2)
        : switch (problem) {
            SceneGraphProblemLevel.blocking => BorderSide(
              color: scheme.error,
              width: 2,
            ),
            SceneGraphProblemLevel.warning => BorderSide(
              color: studio.warning,
              width: 2,
            ),
            null => BorderSide(color: scheme.outlineVariant),
          };
    return Semantics(
      container: true,
      label: category,
      selected: selected,
      child: SizedBox(
        width: SceneGraphMetrics.cardWidth,
        height: card.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.fromBorderSide(border),
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: ColoredBox(
                    color: surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: SceneGraphMetrics.headerHeight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: StudioSpacing.l,
                          ),
                          color: Color.alphaBlend(
                            accent.withValues(alpha: .37),
                            surface,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                sceneGraphNodeIcon(card.node),
                                size: 15,
                                color: accent,
                              ),
                              const SizedBox(width: StudioSpacing.s),
                              Expanded(
                                child: _line(
                                  title,
                                  theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (problem case final level?) ...[
                                const SizedBox(width: StudioSpacing.xs),
                                Icon(
                                  level == SceneGraphProblemLevel.blocking
                                      ? Icons.error_outline
                                      : Icons.warning_amber_outlined,
                                  size: 14,
                                  color:
                                      level == SceneGraphProblemLevel.blocking
                                      ? scheme.error
                                      : studio.warning,
                                ),
                              ],
                            ],
                          ),
                        ),
                        for (final port in card.outputs)
                          Container(
                            key: ValueKey(
                              'scene-graph-port-${card.id}-${port.id}',
                            ),
                            height: SceneGraphMetrics.portRowHeight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: StudioSpacing.l,
                            ),
                            alignment: Alignment.centerRight,
                            child: _line(
                              sceneGraphPortLabel(
                                l10n,
                                port.id,
                                dialogue,
                                choiceLabels: choiceLabels,
                              ),
                              theme.textTheme.labelMedium?.copyWith(
                                color: _portColor(
                                  port,
                                  scheme.onSurface,
                                  studio,
                                ),
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
                              if (detail == null || roomy)
                                _line(
                                  category,
                                  theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              if (detail != null)
                                _line(
                                  detail,
                                  theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (card.acceptsInput)
              _socket(
                left: -portRadius,
                top: SceneGraphMetrics.inputPortY - portRadius,
                color: scheme.onSurface,
                filled: true,
              ),
            for (final (index, port) in card.outputs.indexed)
              _socket(
                left: SceneGraphMetrics.cardWidth - portRadius,
                top: SceneGraphMetrics.outputPortY(index) - portRadius,
                color: _portColor(port, scheme.onSurface, studio),
                filled: port.connected,
              ),
          ],
        ),
      ),
    );
  }

  Color _portColor(SceneGraphPort port, Color idle, StudioColors studio) =>
      switch (port) {
        SceneGraphPort(declared: false) => studio.warning,
        SceneGraphPort(required: true, connected: false) => studio.warning,
        _ => idle,
      };

  Widget _line(String text, TextStyle? style, {int maxLines = 1}) => Text(
    text,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    style: style,
  );

  Widget _socket({
    required double left,
    required double top,
    required Color color,
    required bool filled,
  }) => Positioned(
    left: left,
    top: top,
    width: portRadius * 2,
    height: portRadius * 2,
    child: CustomPaint(painter: _SceneSocketPainter(color, filled)),
  );
}

class _SceneSocketPainter extends CustomPainter {
  const _SceneSocketPainter(this.color, this.filled);

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..moveTo(1, 1)
      ..lineTo(size.width * .55, 1)
      ..lineTo(size.width - 1, size.height / 2)
      ..lineTo(size.width * .55, size.height - 1)
      ..lineTo(1, size.height - 1)
      ..close();
    canvas.drawPath(
      outline,
      Paint()
        ..color = color
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.25,
    );
  }

  @override
  bool shouldRepaint(_SceneSocketPainter oldDelegate) =>
      oldDelegate.filled != filled || oldDelegate.color != color;
}
