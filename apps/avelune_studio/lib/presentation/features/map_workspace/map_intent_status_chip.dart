import 'package:flutter/material.dart';

import '../../theme/studio_tokens.dart';
import 'map_palette_intent.dart';

class MapIntentStatusChip extends StatelessWidget {
  const MapIntentStatusChip({super.key, required this.intent});

  final MapPaletteIntent intent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final resource = intent.resource;
    final action = resource == null
        ? intent.action
        : '${intent.action} · $resource';
    final title = intent.target == null ? action : '${intent.target} · $action';
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        label: '$title. ${intent.next}',
        excludeSemantics: true,
        child: ConstrainedBox(
          key: const ValueKey('map-intent-status'),
          constraints: const BoxConstraints(maxWidth: 560),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow.withValues(alpha: .92),
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    intent.armed
                        ? Icons.touch_app_outlined
                        : Icons.info_outline,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' — ${intent.next}'),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
