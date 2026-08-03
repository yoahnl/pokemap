import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'pokemap_button.dart';
import 'pokemap_icon_button.dart';
import 'pokemap_panel.dart';
import 'pokemap_tone.dart';

/// A compact action exposed by [PokeMapActionBanner].
@immutable
final class PokeMapActionBannerAction {
  const PokeMapActionBannerAction({
    required this.label,
    required this.onPressed,
    this.variant = PokeMapButtonVariant.primary,
    this.isLoading = false,
    this.semanticLabel,
    this.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final PokeMapButtonVariant variant;
  final bool isLoading;
  final String? semanticLabel;
  final Key? key;
}

/// Non-modal product feedback that keeps the current editor context visible.
///
/// The banner deliberately owns no feature colors. Its visual treatment comes
/// from semantic design-system tones and the current PokeMap theme.
class PokeMapActionBanner extends StatelessWidget {
  const PokeMapActionBanner({
    super.key,
    required this.title,
    required this.message,
    required this.tone,
    this.actions = const [],
    this.details,
    this.dismissLabel,
    this.onDismiss,
    this.dismissKey,
    this.semanticLabel,
    this.liveRegion = true,
  }) : assert(
          (dismissLabel == null) == (onDismiss == null),
          'dismissLabel and onDismiss must be provided together.',
        );

  final String title;
  final String message;
  final PokeMapTone tone;
  final List<PokeMapActionBannerAction> actions;
  final Widget? details;
  final String? dismissLabel;
  final VoidCallback? onDismiss;
  final Key? dismissKey;
  final String? semanticLabel;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = tone.resolve(context);
    final accessibleLabel = semanticLabel ?? '$title. $message';

    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: liveRegion,
      label: accessibleLabel,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: PokeMapPanel(
          accentTone: tone,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      _iconFor(tone),
                      color: toneColors.icon,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onDismiss != null) ...[
                    const SizedBox(width: 8),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(100),
                      child: PokeMapIconButton(
                        key: dismissKey ??
                            const ValueKey<String>(
                              'pokemap-action-banner-dismiss',
                            ),
                        onPressed: onDismiss,
                        tooltip: dismissLabel,
                        semanticLabel: dismissLabel,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ],
              ),
              if (details != null) ...[
                const SizedBox(height: 10),
                details!,
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < actions.length; index += 1)
                      FocusTraversalOrder(
                        order: NumericFocusOrder(index + 1),
                        child: PokeMapButton(
                          key: actions[index].key,
                          onPressed: actions[index].onPressed,
                          variant: actions[index].variant,
                          size: PokeMapButtonSize.small,
                          isLoading: actions[index].isLoading,
                          semanticLabel: actions[index].semanticLabel ??
                              actions[index].label,
                          child: Text(actions[index].label),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(PokeMapTone tone) => switch (tone) {
        PokeMapTone.success => Icons.check_circle_outline_rounded,
        PokeMapTone.warning => Icons.warning_amber_rounded,
        PokeMapTone.danger => Icons.error_outline_rounded,
        PokeMapTone.brand => Icons.auto_awesome_rounded,
        _ => Icons.info_outline_rounded,
      };
}
