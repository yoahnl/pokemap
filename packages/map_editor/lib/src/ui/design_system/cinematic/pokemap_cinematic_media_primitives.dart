import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../pokemap_asset_card.dart';
import '../pokemap_badge.dart';
import '../pokemap_button.dart';
import '../pokemap_progress_bar.dart';
import '../pokemap_tone.dart';

enum PokeMapCinematicMediaOrientation { landscape, portrait, shared }

enum PokeMapCinematicMediaSlotState {
  empty,
  ready,
  importing,
  missing,
  corrupt,
  unsupported,
  error,
}

extension PokeMapCinematicMediaOrientationX
    on PokeMapCinematicMediaOrientation {
  IconData get icon => switch (this) {
    PokeMapCinematicMediaOrientation.landscape =>
      Icons.stay_current_landscape_outlined,
    PokeMapCinematicMediaOrientation.portrait =>
      Icons.stay_current_portrait_outlined,
    PokeMapCinematicMediaOrientation.shared => Icons.link_rounded,
  };
}

extension PokeMapCinematicMediaSlotStateX on PokeMapCinematicMediaSlotState {
  IconData get icon => switch (this) {
    PokeMapCinematicMediaSlotState.empty => Icons.add_photo_alternate_outlined,
    PokeMapCinematicMediaSlotState.ready => Icons.check_circle_outline,
    PokeMapCinematicMediaSlotState.importing => Icons.download_rounded,
    PokeMapCinematicMediaSlotState.missing => Icons.link_off_rounded,
    PokeMapCinematicMediaSlotState.corrupt => Icons.broken_image_outlined,
    PokeMapCinematicMediaSlotState.unsupported => Icons.block_rounded,
    PokeMapCinematicMediaSlotState.error => Icons.error_outline_rounded,
  };

  PokeMapTone get tone => switch (this) {
    PokeMapCinematicMediaSlotState.empty => PokeMapTone.neutral,
    PokeMapCinematicMediaSlotState.ready => PokeMapTone.success,
    PokeMapCinematicMediaSlotState.importing => PokeMapTone.info,
    PokeMapCinematicMediaSlotState.missing => PokeMapTone.warning,
    PokeMapCinematicMediaSlotState.corrupt => PokeMapTone.danger,
    PokeMapCinematicMediaSlotState.unsupported => PokeMapTone.warning,
    PokeMapCinematicMediaSlotState.error => PokeMapTone.danger,
  };
}

class PokeMapCinematicMediaSlot extends StatelessWidget {
  const PokeMapCinematicMediaSlot({
    super.key,
    required this.orientation,
    required this.title,
    required this.state,
    this.sourceLabel,
    this.statusLabel,
    this.fallbackLabel,
    this.progress,
    this.actionLabel,
    this.onAction,
    this.cancelLabel,
    this.onCancel,
    this.preview,
  });

  final PokeMapCinematicMediaOrientation orientation;
  final String title;
  final PokeMapCinematicMediaSlotState state;
  final String? sourceLabel;
  final String? statusLabel;
  final String? fallbackLabel;
  final double? progress;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = state.tone.resolve(context);
    final source = sourceLabel?.trim();
    final status = statusLabel?.trim();
    final fallback = fallbackLabel?.trim();
    final semanticParts = [
      title,
      if (source != null && source.isNotEmpty) source,
      if (status != null && status.isNotEmpty) status,
      if (fallback != null && fallback.isNotEmpty) fallback,
    ];
    return Semantics(
      container: true,
      liveRegion:
          state == PokeMapCinematicMediaSlotState.importing ||
          state == PokeMapCinematicMediaSlotState.error,
      label: semanticParts.join('. '),
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          border: Border.all(color: tone.border),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: tone.soft,
                border: Border.all(color: tone.border),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: preview ?? Icon(state.icon, color: tone.icon, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(orientation.icon, size: 15, color: colors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (fallback != null && fallback.isNotEmpty)
                        PokeMapBadge(
                          label: fallback,
                          variant: PokeMapBadgeVariant.info,
                          icon: const Icon(Icons.swap_horiz_rounded),
                        ),
                    ],
                  ),
                  if (source != null && source.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (status != null && status.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(state.icon, size: 14, color: tone.icon),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            status,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tone.text,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (state == PokeMapCinematicMediaSlotState.importing &&
                      progress != null) ...[
                    const SizedBox(height: 8),
                    PokeMapProgressBar(
                      value: progress!,
                      semanticLabel: status ?? title,
                      tone: PokeMapTone.info,
                    ),
                  ],
                  if (actionLabel != null || cancelLabel != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (actionLabel != null)
                          PokeMapButton(
                            onPressed: onAction,
                            size: PokeMapButtonSize.small,
                            variant: PokeMapButtonVariant.secondary,
                            child: Text(actionLabel!),
                          ),
                        if (cancelLabel != null)
                          PokeMapButton(
                            onPressed: onCancel,
                            size: PokeMapButtonSize.small,
                            variant: PokeMapButtonVariant.ghost,
                            child: Text(cancelLabel!),
                          ),
                      ],
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

class PokeMapCinematicMediaCatalogCard extends StatelessWidget {
  const PokeMapCinematicMediaCatalogCard({
    super.key,
    required this.title,
    required this.metadata,
    required this.preview,
    required this.onPressed,
    this.selected = false,
    this.status,
    this.disabledReason,
  });

  final String title;
  final String metadata;
  final Widget preview;
  final VoidCallback? onPressed;
  final bool selected;
  final Widget? status;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapAssetCard(
      label: title,
      description: metadata,
      selected: selected,
      onPressed: onPressed,
      disabledReason: disabledReason,
      trailing: status,
      thumbnail: Container(
        width: 64,
        height: 44,
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          border: Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: preview,
      ),
    );
  }
}
