import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/design_system/foundation/avelune_shape_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_spacing_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/theme/avelune_theme_extensions.dart';
import 'package:pokemap_hub/presentation/design_system/components/avelune_inset_panel.dart';
import 'package:pokemap_hub/presentation/design_system/components/avelune_pressable.dart';
import 'package:pokemap_hub/presentation/design_system/foundation/avelune_icon_tokens.dart';

enum AveluneStateMessageKind { empty, info, error, loading }

class AveluneStateMessage extends StatelessWidget {
  const AveluneStateMessage({
    super.key,
    required this.kind,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final AveluneStateMessageKind kind;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final icon = switch (kind) {
      AveluneStateMessageKind.empty => AveluneIcons.storage,
      AveluneStateMessageKind.info => AveluneIcons.details,
      AveluneStateMessageKind.error => AveluneIcons.error,
      AveluneStateMessageKind.loading => AveluneIcons.pending,
    };
    final foreground = switch (kind) {
      AveluneStateMessageKind.error => colors.error,
      AveluneStateMessageKind.loading => colors.accentBright,
      _ => colors.textSecondary,
    };
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;

    return Semantics(
      container: true,
      liveRegion: kind == AveluneStateMessageKind.error ||
          kind == AveluneStateMessageKind.loading,
      child: AveluneInsetPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: AveluneSpacing.xxs),
              child: Icon(icon, color: foreground, size: 24),
            ),
            const SizedBox(width: AveluneSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AveluneSpacing.xxs),
                  Text(
                    message,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.textSecondary),
                  ),
                  if (actionLabel != null && onAction != null) ...<Widget>[
                    const SizedBox(height: AveluneSpacing.md),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AvelunePressable(
                        semanticLabel: actionLabel,
                        onPressed: onAction,
                        borderRadius: AveluneShapes.pill,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AveluneShapes.minimumTouchTarget,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AveluneSpacing.lg,
                            ),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                actionLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: colors.accentBright),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
