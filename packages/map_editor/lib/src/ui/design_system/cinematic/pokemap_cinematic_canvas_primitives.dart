import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../pokemap_button.dart';

enum PokeMapCinematicComposition { landscape16x9, portrait9x16 }

enum PokeMapCinematicViewportState { ready, loading, error }

extension PokeMapCinematicCompositionX on PokeMapCinematicComposition {
  double get aspectRatio => switch (this) {
    PokeMapCinematicComposition.landscape16x9 => 16 / 9,
    PokeMapCinematicComposition.portrait9x16 => 9 / 16,
  };
}

class PokeMapCinematicViewport extends StatelessWidget {
  const PokeMapCinematicViewport({
    super.key,
    required this.composition,
    required this.semanticLabel,
    required this.child,
    this.showSafeArea = false,
    this.state = PokeMapCinematicViewportState.ready,
    this.statusLabel,
    this.retryLabel,
    this.onRetry,
    this.selected = false,
  });

  final PokeMapCinematicComposition composition;
  final String semanticLabel;
  final Widget child;
  final bool showSafeArea;
  final PokeMapCinematicViewportState state;
  final String? statusLabel;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      container: true,
      image: true,
      label: semanticLabel,
      child: Center(
        child: AspectRatio(
          key: const ValueKey('pokemap-cinematic-viewport-frame'),
          aspectRatio: composition.aspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.contentSurface,
              border: Border.all(
                color: selected
                    ? colors.brandPrimaryBorder
                    : colors.borderStrong,
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.scrimSoft,
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  if (showSafeArea)
                    Positioned.fill(
                      key: const ValueKey('pokemap-cinematic-safe-area'),
                      left: 24,
                      top: 24,
                      right: 24,
                      bottom: 24,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colors.info.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (state != PokeMapCinematicViewportState.ready)
                    _PokeMapCinematicViewportStatus(
                      state: state,
                      label: statusLabel ?? '',
                      retryLabel: retryLabel,
                      onRetry: onRetry,
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

class _PokeMapCinematicViewportStatus extends StatelessWidget {
  const _PokeMapCinematicViewportStatus({
    required this.state,
    required this.label,
    required this.retryLabel,
    required this.onRetry,
  });

  final PokeMapCinematicViewportState state;
  final String label;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isLoading = state == PokeMapCinematicViewportState.loading;
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ColoredBox(
        color: colors.scrimSoft,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              border: Border.all(
                color: isLoading ? colors.borderStrong : colors.errorBorder,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.brandPrimary,
                      ),
                    )
                  else
                    Icon(Icons.broken_image_outlined, color: colors.error),
                  if (label.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (!isLoading && retryLabel != null) ...[
                    const SizedBox(height: 12),
                    PokeMapButton(
                      onPressed: onRetry,
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      child: Text(retryLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PokeMapCinematicTransformHandle extends StatelessWidget {
  const PokeMapCinematicTransformHandle({
    super.key,
    required this.semanticLabel,
    required this.onDrag,
    this.size = 28,
  });

  final String semanticLabel;
  final ValueChanged<Offset>? onDrag;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      container: true,
      label: semanticLabel,
      enabled: onDrag != null,
      child: MouseRegion(
        cursor: onDrag == null
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.resizeUpLeftDownRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onDrag == null
              ? null
              : (details) => onDrag!(details.delta),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  border: Border.all(color: colors.brandPrimary, width: 2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
