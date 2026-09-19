import 'package:flutter/material.dart';
import '../../../theme/studio_tokens.dart';

enum StudioTone { neutral, info, success, warning, danger, feature }

class StudioBadge extends StatelessWidget {
  const StudioBadge(
    this.label, {
    super.key,
    this.tone = StudioTone.neutral,
    this.icon,
  });
  final String label;
  final StudioTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final studio = StudioColors.of(context);
    final color = switch (tone) {
      StudioTone.neutral => colors.onSurfaceVariant,
      StudioTone.info => studio.canvasSelection,
      StudioTone.success => studio.success,
      StudioTone.warning => studio.warning,
      StudioTone.danger => colors.error,
      StudioTone.feature => studio.featureAccent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
