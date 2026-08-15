import 'dart:math' as math;

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

enum PresentationFrameMediaKind {
  image,
  video,
  poster,
  voice,
  soundEffect,
  music,
}

final class PresentationFrameMediaBinding {
  const PresentationFrameMediaBinding({
    required this.clipId,
    required this.kind,
    this.landscapeResourceId,
    this.portraitResourceId,
    this.sharedResourceId,
  });

  final String clipId;
  final PresentationFrameMediaKind kind;
  final String? landscapeResourceId;
  final String? portraitResourceId;
  final String? sharedResourceId;

  String? resourceIdFor(PresentationFrameOrientation orientation) {
    if (kind == PresentationFrameMediaKind.music) return sharedResourceId;
    return switch (orientation) {
      PresentationFrameOrientation.landscape =>
        landscapeResourceId ?? sharedResourceId ?? portraitResourceId,
      PresentationFrameOrientation.portrait =>
        portraitResourceId ?? sharedResourceId ?? landscapeResourceId,
    };
  }
}

final class PresentationVisualOrientationOverride {
  const PresentationVisualOrientationOverride({
    this.landscape,
    this.portrait,
    this.reducedMotionLandscape,
    this.reducedMotionPortrait,
  });

  final PresentationVisualComposition? landscape;
  final PresentationVisualComposition? portrait;
  final PresentationVisualComposition? reducedMotionLandscape;
  final PresentationVisualComposition? reducedMotionPortrait;

  PresentationVisualComposition resolve({
    required PresentationFrameOrientation orientation,
    required PresentationVisualComposition fallback,
    required bool reduceMotion,
  }) {
    return switch ((orientation, reduceMotion)) {
      (PresentationFrameOrientation.landscape, true) =>
        reducedMotionLandscape ?? landscape ?? fallback,
      (PresentationFrameOrientation.portrait, true) =>
        reducedMotionPortrait ?? portrait ?? fallback,
      (PresentationFrameOrientation.landscape, false) => landscape ?? fallback,
      (PresentationFrameOrientation.portrait, false) => portrait ?? fallback,
    };
  }
}

final class PresentationFrameOrientationOverrides {
  const PresentationFrameOrientationOverrides({
    this.visualsByClipId =
        const <String, PresentationVisualOrientationOverride>{},
  });

  final Map<String, PresentationVisualOrientationOverride> visualsByClipId;

  PresentationVisualComposition resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
    required bool reduceMotion,
  }) {
    final fallback =
        reduceMotion ? clip.reducedMotionComposition : clip.composition;
    return visualsByClipId[clip.clipId]?.resolve(
          orientation: orientation,
          fallback: fallback,
          reduceMotion: reduceMotion,
        ) ??
        fallback;
  }

  PresentationVisualComposition resolveText({
    required PresentationTextFrameClip clip,
    required PresentationFrameOrientation orientation,
    required bool reduceMotion,
  }) {
    final fallback =
        reduceMotion ? clip.reducedMotionComposition : clip.composition;
    return visualsByClipId[clip.clipId]?.resolve(
          orientation: orientation,
          fallback: fallback,
          reduceMotion: reduceMotion,
        ) ??
        fallback;
  }
}

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

final class PresentationResponsiveFrameContentPort
    implements PresentationFrameContentPort {
  PresentationResponsiveFrameContentPort({
    required this.delegate,
    required Iterable<PresentationFrameMediaBinding> bindings,
  }) : bindings = Map<String, PresentationFrameMediaBinding>.unmodifiable(
          <String, PresentationFrameMediaBinding>{
            for (final binding in bindings) binding.clipId: binding,
          },
        );

  final PresentationFrameContentPort delegate;
  final Map<String, PresentationFrameMediaBinding> bindings;

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) {
    final resourceId = bindings[clip.clipId]?.resourceIdFor(orientation);
    return delegate.resolveVisual(
      clip: resourceId == null || resourceId == clip.resourceId
          ? clip
          : _visualWithResourceId(clip, resourceId),
      orientation: orientation,
    );
  }

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) =>
      delegate.resolveCaption(clip: clip, locale: locale);
}

class PresentationFrameRenderer extends StatelessWidget {
  const PresentationFrameRenderer({
    super.key,
    required this.frame,
    required this.orientation,
    required this.contentPort,
    this.reduceMotion,
    this.reduceFlashes = false,
    this.showCaptions = true,
    this.orientationOverrides = const PresentationFrameOrientationOverrides(),
  });

  final PresentationFrame frame;
  final PresentationFrameOrientation orientation;
  final PresentationFrameContentPort contentPort;
  final bool? reduceMotion;
  final bool reduceFlashes;
  final bool showCaptions;
  final PresentationFrameOrientationOverrides orientationOverrides;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    final resolvedReduceMotion =
        reduceMotion ?? MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
                  ..._orderedContentLayers(
                    reduceMotion: resolvedReduceMotion,
                  ),
                  if (showCaptions && frame.captions.isNotEmpty)
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

  List<Widget> _orderedContentLayers({required bool reduceMotion}) {
    final layers = <({String id, int zIndex, Widget child})>[
      for (final visual in frame.visuals)
        (
          id: visual.clipId,
          zIndex: visual.zIndex,
          child: _PresentationVisualLayer(
            clip: visual,
            orientation: orientation,
            composition: orientationOverrides.resolveVisual(
              clip: visual,
              orientation: orientation,
              reduceMotion: reduceMotion,
            ),
            reduceFlashes: reduceFlashes,
            resolution: contentPort.resolveVisual(
              clip: visual,
              orientation: orientation,
            ),
          ),
        ),
      for (final text in frame.texts)
        (
          id: text.clipId,
          zIndex: text.zIndex,
          child: _PresentationTextLayer(
            clip: text,
            composition: orientationOverrides.resolveText(
              clip: text,
              orientation: orientation,
              reduceMotion: reduceMotion,
            ),
            reduceFlashes: reduceFlashes,
          ),
        ),
    ]..sort((left, right) {
        final zOrder = left.zIndex.compareTo(right.zIndex);
        return zOrder != 0 ? zOrder : left.id.compareTo(right.id);
      });
    return <Widget>[for (final layer in layers) layer.child];
  }
}

PresentationVisualFrameClip _visualWithResourceId(
  PresentationVisualFrameClip clip,
  String resourceId,
) =>
    PresentationVisualFrameClip(
      clipId: clip.clipId,
      trackId: clip.trackId,
      layerId: clip.layerId,
      zIndex: clip.zIndex,
      resourceId: resourceId,
      startUs: clip.startUs,
      durationUs: clip.durationUs,
      elapsedUs: clip.elapsedUs,
      progress: clip.progress,
      easedProgress: clip.easedProgress,
      easing: clip.easing,
      composition: clip.composition,
      reducedMotionComposition: clip.reducedMotionComposition,
      reducedFlashOpacity: clip.reducedFlashOpacity,
    );

class _PresentationVisualLayer extends StatelessWidget {
  const _PresentationVisualLayer({
    required this.clip,
    required this.orientation,
    required this.composition,
    required this.reduceFlashes,
    required this.resolution,
  });

  final PresentationVisualFrameClip clip;
  final PresentationFrameOrientation orientation;
  final PresentationVisualComposition composition;
  final bool reduceFlashes;
  final PresentationVisualResolution resolution;

  @override
  Widget build(BuildContext context) {
    final child = switch (resolution) {
      PresentationVisualReady(:final child) => KeyedSubtree(
          key: ValueKey<String>(
            'presentation-visual-resource-${clip.clipId}-${clip.resourceId}-'
            '${orientation.name}',
          ),
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
    return Opacity(
      key: ValueKey<String>('presentation-visual-opacity-${clip.clipId}'),
      opacity: reduceFlashes ? clip.reducedFlashOpacity : composition.opacity,
      child: FractionalTranslation(
        key: ValueKey<String>(
          'presentation-visual-translation-${clip.clipId}',
        ),
        translation: Offset(composition.translateX, composition.translateY),
        child: Transform.rotate(
          key: ValueKey<String>('presentation-visual-rotation-${clip.clipId}'),
          angle: composition.rotationTurns * math.pi * 2,
          alignment: Alignment.center,
          child: Transform(
            key: ValueKey<String>('presentation-visual-scale-${clip.clipId}'),
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(
              composition.scaleX,
              composition.scaleY,
              1,
            ),
            child: ClipRect(
              key: ValueKey<String>('presentation-visual-crop-${clip.clipId}'),
              clipper: _PresentationCropClipper(composition),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresentationTextLayer extends StatelessWidget {
  const _PresentationTextLayer({
    required this.clip,
    required this.composition,
    required this.reduceFlashes,
  });

  final PresentationTextFrameClip clip;
  final PresentationVisualComposition composition;
  final bool reduceFlashes;

  @override
  Widget build(BuildContext context) {
    final style = clip.style;
    Widget text = Align(
      alignment: switch (style.alignment) {
        PresentationTextAlignment.start => Alignment.centerLeft,
        PresentationTextAlignment.center => Alignment.center,
        PresentationTextAlignment.end => Alignment.centerRight,
      },
      child: Text(
        clip.text,
        key: ValueKey<String>('presentation-text-${clip.clipId}'),
        maxLines: style.wrapping == PresentationTextWrapping.noWrap ? 1 : null,
        overflow: style.wrapping == PresentationTextWrapping.noWrap
            ? TextOverflow.clip
            : null,
        textAlign: switch (style.alignment) {
          PresentationTextAlignment.start => TextAlign.start,
          PresentationTextAlignment.center => TextAlign.center,
          PresentationTextAlignment.end => TextAlign.end,
        },
        style: TextStyle(
          color: _colorFromHex(style.colorHex),
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: switch (style.weight) {
            PresentationTextWeight.regular => FontWeight.w400,
            PresentationTextWeight.medium => FontWeight.w500,
            PresentationTextWeight.bold => FontWeight.w700,
          },
        ),
      ),
    );
    if (style.respectSafeArea) text = SafeArea(child: text);
    return Opacity(
      key: ValueKey<String>('presentation-text-opacity-${clip.clipId}'),
      opacity: reduceFlashes ? clip.reducedFlashOpacity : composition.opacity,
      child: FractionalTranslation(
        translation: Offset(composition.translateX, composition.translateY),
        child: Transform.rotate(
          angle: composition.rotationTurns * math.pi * 2,
          alignment: Alignment.center,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(
              composition.scaleX,
              composition.scaleY,
              1,
            ),
            child: ClipRect(
              clipper: _PresentationCropClipper(composition),
              child: Padding(
                padding: const EdgeInsets.all(PlayerSpacing.md),
                child: text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _colorFromHex(String value) {
  final hex = value.substring(1);
  final rgb = int.parse(hex.substring(0, 6), radix: 16);
  final alpha = hex.length == 8 ? int.parse(hex.substring(6), radix: 16) : 255;
  return Color.fromARGB(alpha, rgb >> 16, (rgb >> 8) & 0xFF, rgb & 0xFF);
}

final class _PresentationCropClipper extends CustomClipper<Rect> {
  const _PresentationCropClipper(this.composition);

  final PresentationVisualComposition composition;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
        size.width * composition.cropLeft,
        size.height * composition.cropTop,
        size.width * (1 - composition.cropRight),
        size.height * (1 - composition.cropBottom),
      );

  @override
  bool shouldReclip(_PresentationCropClipper oldClipper) =>
      oldClipper.composition != composition;
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
