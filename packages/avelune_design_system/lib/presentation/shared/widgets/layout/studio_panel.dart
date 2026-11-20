import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';

class StudioPanel extends StatelessWidget {
  const StudioPanel({
    super.key,
    required this.children,
    this.title,
    this.icon,
    this.accent,
    this.actions = const [],
    this.compact = false,
    this.bandedHeader = false,
    this.radius = StudioMetrics.panelRadius,
  });
  final List<Widget> children;
  final String? title;
  final IconData? icon;
  final StudioAccent? accent;
  final List<Widget> actions;
  final bool compact;
  final bool bandedHeader;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tint = accent?.color(context);
    final heading = title;
    final band = bandedHeader && heading != null;
    final inset = compact ? StudioSpacing.l : StudioMetrics.panelPadding;
    final header = heading == null
        ? null
        : Wrap(
            spacing: StudioSpacing.l,
            runSpacing: StudioSpacing.m,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (icon != null) Icon(icon, size: 21, color: tint),
              Text(
                heading,
                style: band
                    ? theme.textTheme.labelLarge?.copyWith(color: tint)
                    : theme.textTheme.titleMedium,
              ),
              ...actions,
            ],
          );
    final content = Padding(
      padding: EdgeInsets.all(inset),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!band && header != null) ...[
              header,
              const SizedBox(height: StudioSpacing.l),
            ],
            ...children,
          ],
        ),
      ),
    );
    return Material(
      color: tint == null || band
          ? colors.surface
          : Color.alphaBlend(tint.withValues(alpha: .055), colors.surface),
      clipBehavior: band ? Clip.antiAlias : Clip.none,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: tint?.withValues(alpha: .4) ?? colors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: band
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(
                  color: tint == null
                      ? colors.surfaceContainer
                      : Color.alphaBlend(
                          tint.withValues(alpha: .12),
                          colors.surface,
                        ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: inset,
                      vertical: StudioSpacing.m,
                    ),
                    child: header,
                  ),
                ),
                content,
              ],
            )
          : content,
    );
  }
}
