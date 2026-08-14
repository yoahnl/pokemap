import '../models/presentation_cinematic_asset.dart';
import '../read_models/presentation_frame.dart';

final class PresentationCinematicEvaluator {
  const PresentationCinematicEvaluator();

  PresentationFrame evaluate(
    PresentationCinematicAsset asset, {
    required int timeUs,
  }) {
    final resolvedTimeUs = timeUs.clamp(0, asset.durationUs);
    final layerZIndexes = {
      for (final layer in asset.layers) layer.id: layer.zIndex,
    };
    final visuals = <PresentationVisualFrameClip>[];
    final audio = <PresentationAudioFrameClip>[];
    final captions = <PresentationCaptionFrameClip>[];
    final markers = <PresentationFrameMarker>[];

    for (final track in asset.tracks) {
      for (final clip in track.clips) {
        switch (clip) {
          case final PresentationVisualClip visualClip
              when _isActive(visualClip, resolvedTimeUs):
            final progress = _progress(visualClip, resolvedTimeUs);
            final easedProgress = _ease(progress, visualClip.easing);
            final elapsedUs = resolvedTimeUs - visualClip.startUs;
            visuals.add(
              PresentationVisualFrameClip(
                clipId: visualClip.id,
                trackId: track.id,
                layerId: visualClip.layerId,
                zIndex: layerZIndexes[visualClip.layerId]!,
                resourceId: visualClip.resourceId,
                startUs: visualClip.startUs,
                durationUs: visualClip.durationUs,
                elapsedUs: elapsedUs,
                progress: progress,
                easedProgress: easedProgress,
                easing: visualClip.easing,
                composition: _evaluateVisualComposition(
                  visualClip,
                  elapsedUs: elapsedUs,
                  easedProgress: easedProgress,
                  reduceMotion: false,
                ),
                reducedMotionComposition: _evaluateVisualComposition(
                  visualClip,
                  elapsedUs: elapsedUs,
                  easedProgress: easedProgress,
                  reduceMotion: true,
                ),
                reducedFlashOpacity: visualClip.to.opacity,
              ),
            );
          case final PresentationAudioClip audioClip
              when _isActive(audioClip, resolvedTimeUs):
            audio.add(
              PresentationAudioFrameClip(
                clipId: audioClip.id,
                trackId: track.id,
                resourceId: audioClip.resourceId,
                startUs: audioClip.startUs,
                durationUs: audioClip.durationUs,
                elapsedUs: resolvedTimeUs - audioClip.startUs,
                progress: _progress(audioClip, resolvedTimeUs),
              ),
            );
          case final PresentationCaptionClip captionClip
              when _isActive(captionClip, resolvedTimeUs):
            captions.add(
              PresentationCaptionFrameClip(
                clipId: captionClip.id,
                trackId: track.id,
                captionId: captionClip.captionId,
                startUs: captionClip.startUs,
                durationUs: captionClip.durationUs,
                elapsedUs: resolvedTimeUs - captionClip.startUs,
                progress: _progress(captionClip, resolvedTimeUs),
              ),
            );
          case final PresentationMarkerClip markerClip
              when markerClip.startUs == resolvedTimeUs:
            markers.add(
              PresentationFrameMarker(
                clipId: markerClip.id,
                trackId: track.id,
                label: markerClip.label,
                markerKind: markerClip.markerKind,
                timeUs: markerClip.startUs,
              ),
            );
          case _:
        }
      }
    }

    visuals.sort(_compareVisuals);
    audio.sort(_compareAudio);
    captions.sort(_compareCaptions);
    markers.sort(_compareMarkers);

    return PresentationFrame(
      cinematicId: asset.id,
      timeUs: resolvedTimeUs,
      durationUs: asset.durationUs,
      visuals: visuals,
      audio: audio,
      captions: captions,
      markers: markers,
    );
  }
}

bool _isActive(PresentationClip clip, int timeUs) =>
    clip.startUs <= timeUs && timeUs < clip.endUs;

double _progress(PresentationClip clip, int timeUs) =>
    (timeUs - clip.startUs) / clip.durationUs;

double _ease(double progress, PresentationEasing easing) => switch (easing) {
  PresentationEasing.linear => progress,
  PresentationEasing.easeIn => progress * progress,
  PresentationEasing.easeOut => 1 - (1 - progress) * (1 - progress),
  PresentationEasing.easeInOut =>
    progress < 0.5
        ? 2 * progress * progress
        : 1 - ((-2 * progress + 2) * (-2 * progress + 2)) / 2,
};

PresentationVisualComposition _evaluateVisualComposition(
  PresentationVisualClip clip, {
  required int elapsedUs,
  required double easedProgress,
  required bool reduceMotion,
}) {
  final from = clip.from;
  final to = clip.to;
  var translateX = reduceMotion
      ? to.translateX
      : _lerp(from.translateX, to.translateX, easedProgress);
  var translateY = reduceMotion
      ? to.translateY
      : _lerp(from.translateY, to.translateY, easedProgress);
  final scaleX = reduceMotion
      ? to.scaleX
      : _lerp(from.scaleX, to.scaleX, easedProgress);
  final scaleY = reduceMotion
      ? to.scaleY
      : _lerp(from.scaleY, to.scaleY, easedProgress);
  final rotationTurns = reduceMotion
      ? to.rotationTurns
      : _lerp(from.rotationTurns, to.rotationTurns, easedProgress);
  var opacity = _lerp(from.opacity, to.opacity, easedProgress);
  final cropLeft = reduceMotion
      ? to.cropLeft
      : _lerp(from.cropLeft, to.cropLeft, easedProgress);
  final cropTop = reduceMotion
      ? to.cropTop
      : _lerp(from.cropTop, to.cropTop, easedProgress);
  final cropRight = reduceMotion
      ? to.cropRight
      : _lerp(from.cropRight, to.cropRight, easedProgress);
  final cropBottom = reduceMotion
      ? to.cropBottom
      : _lerp(from.cropBottom, to.cropBottom, easedProgress);

  final entryProgress = _entryTransitionProgress(clip, elapsedUs);
  final exitProgress = _exitTransitionProgress(clip, elapsedUs);
  opacity *= _transitionOpacity(clip.transitionIn, entryProgress);
  opacity *= _transitionOpacity(clip.transitionOut, exitProgress);
  if (!reduceMotion) {
    final entryOffset = _transitionOffset(clip.transitionIn, entryProgress);
    final exitOffset = _transitionOffset(clip.transitionOut, exitProgress);
    translateX += entryOffset.$1 + exitOffset.$1;
    translateY += entryOffset.$2 + exitOffset.$2;
  }

  return PresentationVisualComposition(
    translateX: translateX,
    translateY: translateY,
    scaleX: scaleX,
    scaleY: scaleY,
    rotationTurns: rotationTurns,
    opacity: opacity.clamp(0, 1),
    cropLeft: cropLeft,
    cropTop: cropTop,
    cropRight: cropRight,
    cropBottom: cropBottom,
  );
}

double _entryTransitionProgress(PresentationVisualClip clip, int elapsedUs) {
  final transition = clip.transitionIn;
  if (transition.kind == PresentationVisualTransitionKind.none) {
    return 1;
  }
  return _ease((elapsedUs / transition.durationUs).clamp(0, 1), clip.easing);
}

double _exitTransitionProgress(PresentationVisualClip clip, int elapsedUs) {
  final transition = clip.transitionOut;
  if (transition.kind == PresentationVisualTransitionKind.none) {
    return 1;
  }
  return _ease(
    ((clip.durationUs - elapsedUs) / transition.durationUs).clamp(0, 1),
    clip.easing,
  );
}

double _transitionOpacity(
  PresentationVisualTransition transition,
  double progress,
) => transition.kind == PresentationVisualTransitionKind.fade ? progress : 1;

(double, double) _transitionOffset(
  PresentationVisualTransition transition,
  double progress,
) {
  final remaining = 1 - progress;
  return switch (transition.kind) {
    PresentationVisualTransitionKind.slideLeft => (-remaining, 0),
    PresentationVisualTransitionKind.slideRight => (remaining, 0),
    PresentationVisualTransitionKind.slideUp => (0, -remaining),
    PresentationVisualTransitionKind.slideDown => (0, remaining),
    PresentationVisualTransitionKind.none ||
    PresentationVisualTransitionKind.fade => (0, 0),
  };
}

double _lerp(double from, double to, double progress) =>
    from + (to - from) * progress;

int _compareVisuals(
  PresentationVisualFrameClip left,
  PresentationVisualFrameClip right,
) => _compareValues(
  <Comparable<Object>>[
    left.zIndex,
    left.layerId,
    left.trackId,
    left.startUs,
    left.clipId,
  ],
  <Comparable<Object>>[
    right.zIndex,
    right.layerId,
    right.trackId,
    right.startUs,
    right.clipId,
  ],
);

int _compareAudio(
  PresentationAudioFrameClip left,
  PresentationAudioFrameClip right,
) => _compareValues(
  <Comparable<Object>>[left.trackId, left.startUs, left.clipId],
  <Comparable<Object>>[right.trackId, right.startUs, right.clipId],
);

int _compareCaptions(
  PresentationCaptionFrameClip left,
  PresentationCaptionFrameClip right,
) => _compareValues(
  <Comparable<Object>>[left.trackId, left.startUs, left.clipId],
  <Comparable<Object>>[right.trackId, right.startUs, right.clipId],
);

int _compareMarkers(
  PresentationFrameMarker left,
  PresentationFrameMarker right,
) => _compareValues(
  <Comparable<Object>>[left.trackId, left.clipId],
  <Comparable<Object>>[right.trackId, right.clipId],
);

int _compareValues(
  List<Comparable<Object>> left,
  List<Comparable<Object>> right,
) {
  for (var index = 0; index < left.length; index += 1) {
    final comparison = left[index].compareTo(right[index]);
    if (comparison != 0) {
      return comparison;
    }
  }
  return 0;
}
