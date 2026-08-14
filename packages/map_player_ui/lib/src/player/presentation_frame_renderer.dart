import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../theme/pokemap_player_theme.dart';

enum PresentationFrameOrientation {
  landscape(16 / 9),
  portrait(9 / 16);

  const PresentationFrameOrientation(this.aspectRatio);

  final double aspectRatio;
}

enum PresentationContentUnavailableReason { missing, unsupported }

sealed class PresentationVisualResolution {
  const PresentationVisualResolution();
}

final class PresentationVisualReady extends PresentationVisualResolution {
  const PresentationVisualReady({required this.child});

  final Widget child;
}

final class PresentationVisualUnavailable extends PresentationVisualResolution {
  const PresentationVisualUnavailable({
    required this.reason,
    required this.message,
  });

  final PresentationContentUnavailableReason reason;
  final String message;
}

sealed class PresentationCaptionResolution {
  const PresentationCaptionResolution();
}

final class PresentationCaptionReady extends PresentationCaptionResolution {
  const PresentationCaptionReady({required this.text});

  final String text;
}

final class PresentationCaptionUnavailable
    extends PresentationCaptionResolution {
  const PresentationCaptionUnavailable({
    required this.reason,
    required this.message,
  });

  final PresentationContentUnavailableReason reason;
  final String message;
}

abstract interface class PresentationFrameContentPort {
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  });

  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  });
}

class PresentationFrameRenderer extends StatelessWidget {
  const PresentationFrameRenderer({
    super.key,
    required this.frame,
    required this.orientation,
    required this.contentPort,
  });

  final PresentationFrame frame;
  final PresentationFrameOrientation orientation;
  final PresentationFrameContentPort contentPort;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    return ColoredBox(
      color: colors.background,
      child: Center(
        child: AspectRatio(
          key: ValueKey<String>(
            'presentation-frame-canvas-${orientation.name}',
          ),
          aspectRatio: orientation.aspectRatio,
          child: ClipRect(
            child: ColoredBox(
              color: colors.background,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (final visual in frame.visuals)
                    _PresentationVisualLayer(
                      clip: visual,
                      resolution: contentPort.resolveVisual(
                        clip: visual,
                        orientation: orientation,
                      ),
                    ),
                  if (frame.captions.isNotEmpty)
                    SafeArea(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(PlayerSpacing.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final caption in frame.captions)
                                _PresentationCaption(
                                  clip: caption,
                                  resolution: contentPort.resolveCaption(
                                    clip: caption,
                                    locale: locale,
                                  ),
                                ),
                            ],
                          ),
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

class _PresentationVisualLayer extends StatelessWidget {
  const _PresentationVisualLayer({
    required this.clip,
    required this.resolution,
  });

  final PresentationVisualFrameClip clip;
  final PresentationVisualResolution resolution;

  @override
  Widget build(BuildContext context) => switch (resolution) {
        PresentationVisualReady(:final child) => KeyedSubtree(
            key: ValueKey<String>('presentation-visual-${clip.clipId}'),
            child: SizedBox.expand(child: child),
          ),
        PresentationVisualUnavailable(:final reason, :final message) =>
          _PresentationUnavailableContent(
            key: ValueKey<String>(
              'presentation-visual-unavailable-${clip.clipId}',
            ),
            reason: reason,
            message: message,
          ),
      };
}

class _PresentationCaption extends StatelessWidget {
  const _PresentationCaption({
    required this.clip,
    required this.resolution,
  });

  final PresentationCaptionFrameClip clip;
  final PresentationCaptionResolution resolution;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final (key, text, unavailable, reason) = switch (resolution) {
      PresentationCaptionReady(:final text) => (
          ValueKey<String>('presentation-caption-${clip.clipId}'),
          text,
          false,
          null,
        ),
      PresentationCaptionUnavailable(:final reason, :final message) => (
          ValueKey<String>(
            'presentation-caption-unavailable-${clip.clipId}',
          ),
          message,
          true,
          reason.name,
        ),
    };
    return Semantics(
      key: key,
      liveRegion: unavailable,
      label: text,
      value: reason,
      child: Container(
        margin: const EdgeInsets.only(top: PlayerSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: PlayerSpacing.md,
          vertical: PlayerSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:
              unavailable ? colors.danger.withValues(alpha: .84) : colors.scrim,
          borderRadius: BorderRadius.circular(PlayerRadii.sm),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.textPrimary,
              ),
        ),
      ),
    );
  }
}

class _PresentationUnavailableContent extends StatelessWidget {
  const _PresentationUnavailableContent({
    super.key,
    required this.reason,
    required this.message,
  });

  final PresentationContentUnavailableReason reason;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    return Semantics(
      liveRegion: true,
      label: message,
      value: reason.name,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.danger.withValues(alpha: .18),
          border: Border.all(color: colors.danger),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PlayerSpacing.md,
              vertical: PlayerSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.scrim,
              borderRadius: BorderRadius.circular(PlayerRadii.sm),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
