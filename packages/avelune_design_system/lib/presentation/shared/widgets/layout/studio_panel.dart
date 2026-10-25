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
    this.radius = StudioMetrics.panelRadius,
  });
  final List<Widget> children;
  final String? title;
  final IconData? icon;
  final StudioAccent? accent;
  final List<Widget> actions;
  final bool compact;
  final double radius;

  @override
  Widget build(BuildContext context) => Material(
    color: accent == null
        ? Theme.of(context).colorScheme.surface
        : Color.alphaBlend(
            accent!.color(context).withValues(alpha: 0.055),
            Theme.of(context).colorScheme.surface,
          ),
    shape: RoundedRectangleBorder(
      side: BorderSide(
        color:
            accent?.color(context).withValues(alpha: 0.4) ??
            Theme.of(context).colorScheme.outlineVariant,
      ),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Padding(
      padding: EdgeInsets.all(compact ? 12 : StudioMetrics.panelPadding),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (icon != null)
                    Icon(icon, size: 21, color: accent?.color(context)),
                  Text(title!, style: Theme.of(context).textTheme.titleMedium),
                  ...actions,
                ],
              ),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    ),
  );
}
