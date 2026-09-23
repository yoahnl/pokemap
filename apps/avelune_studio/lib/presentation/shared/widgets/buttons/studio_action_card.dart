import 'package:flutter/material.dart';
import '../../../theme/studio_tokens.dart';
import '../feedback/studio_badge.dart';
import '../feedback/studio_icon_tile.dart';

class StudioActionCard extends StatelessWidget {
  const StudioActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onPressed,
    this.leading,
    this.selected = false,
    this.compact = false,
  });

  final String title, subtitle;
  final IconData icon;
  final StudioTone tone;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: .35)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(compact ? 9 : 12),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          leading ??
                              StudioIconTile(icon: icon, tone: tone, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Icon(
                            selected ? Icons.check_circle : Icons.chevron_right,
                            size: 16,
                            color: selected
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      leading ??
                          StudioIconTile(icon: icon, tone: tone, size: 38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        selected ? Icons.check_circle : Icons.chevron_right,
                        size: 18,
                        color: selected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
