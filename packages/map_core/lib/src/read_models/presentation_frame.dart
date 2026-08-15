import 'package:meta/meta.dart' show immutable;

import '../models/presentation_cinematic_asset.dart';

@immutable
final class PresentationFrame {
  PresentationFrame({
    required this.cinematicId,
    required this.timeUs,
    required this.durationUs,
    List<PresentationVisualFrameClip> visuals =
        const <PresentationVisualFrameClip>[],
    List<PresentationTextFrameClip> texts = const <PresentationTextFrameClip>[],
    List<PresentationAudioFrameClip> audio =
        const <PresentationAudioFrameClip>[],
    List<PresentationCaptionFrameClip> captions =
        const <PresentationCaptionFrameClip>[],
    List<PresentationFrameMarker> markers = const <PresentationFrameMarker>[],
  }) : visuals = List<PresentationVisualFrameClip>.unmodifiable(visuals),
       texts = List<PresentationTextFrameClip>.unmodifiable(texts),
       audio = List<PresentationAudioFrameClip>.unmodifiable(audio),
       captions = List<PresentationCaptionFrameClip>.unmodifiable(captions),
       markers = List<PresentationFrameMarker>.unmodifiable(markers);

  final String cinematicId;
  final int timeUs;
  final int durationUs;
  final List<PresentationVisualFrameClip> visuals;
  final List<PresentationTextFrameClip> texts;
  final List<PresentationAudioFrameClip> audio;
  final List<PresentationCaptionFrameClip> captions;
  final List<PresentationFrameMarker> markers;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationFrame &&
          other.cinematicId == cinematicId &&
          other.timeUs == timeUs &&
          other.durationUs == durationUs &&
          _listEquals(other.visuals, visuals) &&
          _listEquals(other.texts, texts) &&
          _listEquals(other.audio, audio) &&
          _listEquals(other.captions, captions) &&
          _listEquals(other.markers, markers);

  @override
  int get hashCode => Object.hash(
    cinematicId,
    timeUs,
    durationUs,
    Object.hashAll(visuals),
    Object.hashAll(texts),
    Object.hashAll(audio),
    Object.hashAll(captions),
    Object.hashAll(markers),
  );
}

@immutable
final class PresentationTextFrameClip {
  const PresentationTextFrameClip({
    required this.clipId,
    required this.trackId,
    required this.layerId,
    required this.zIndex,
    required this.text,
    required this.localizationKey,
    required this.style,
    required this.startUs,
    required this.durationUs,
    required this.elapsedUs,
    required this.progress,
    required this.easedProgress,
    required this.easing,
    required this.composition,
    required this.reducedMotionComposition,
    this.reducedFlashOpacity = 1,
  });

  final String clipId;
  final String trackId;
  final String layerId;
  final int zIndex;
  final String text;
  final String? localizationKey;
  final PresentationTextStyle style;
  final int startUs;
  final int durationUs;
  final int elapsedUs;
  final double progress;
  final double easedProgress;
  final PresentationEasing easing;
  final PresentationVisualComposition composition;
  final PresentationVisualComposition reducedMotionComposition;
  final double reducedFlashOpacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationTextFrameClip &&
          other.clipId == clipId &&
          other.trackId == trackId &&
          other.layerId == layerId &&
          other.zIndex == zIndex &&
          other.text == text &&
          other.localizationKey == localizationKey &&
          other.style == style &&
          other.startUs == startUs &&
          other.durationUs == durationUs &&
          other.elapsedUs == elapsedUs &&
          other.progress == progress &&
          other.easedProgress == easedProgress &&
          other.easing == easing &&
          other.composition == composition &&
          other.reducedMotionComposition == reducedMotionComposition &&
          other.reducedFlashOpacity == reducedFlashOpacity;

  @override
  int get hashCode => Object.hash(
    clipId,
    trackId,
    layerId,
    zIndex,
    text,
    localizationKey,
    style,
    startUs,
    durationUs,
    elapsedUs,
    progress,
    easedProgress,
    easing,
    composition,
    reducedMotionComposition,
    reducedFlashOpacity,
  );
}

@immutable
final class PresentationVisualFrameClip {
  const PresentationVisualFrameClip({
    required this.clipId,
    required this.trackId,
    required this.layerId,
    required this.zIndex,
    required this.resourceId,
    required this.startUs,
    required this.durationUs,
    required this.elapsedUs,
    required this.progress,
    required this.easedProgress,
    required this.easing,
    required this.composition,
    required this.reducedMotionComposition,
    this.reducedFlashOpacity = 1,
  });

  final String clipId;
  final String trackId;
  final String layerId;
  final int zIndex;
  final String resourceId;
  final int startUs;
  final int durationUs;
  final int elapsedUs;
  final double progress;
  final double easedProgress;
  final PresentationEasing easing;
  final PresentationVisualComposition composition;
  final PresentationVisualComposition reducedMotionComposition;
  final double reducedFlashOpacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationVisualFrameClip &&
          other.clipId == clipId &&
          other.trackId == trackId &&
          other.layerId == layerId &&
          other.zIndex == zIndex &&
          other.resourceId == resourceId &&
          other.startUs == startUs &&
          other.durationUs == durationUs &&
          other.elapsedUs == elapsedUs &&
          other.progress == progress &&
          other.easedProgress == easedProgress &&
          other.easing == easing &&
          other.composition == composition &&
          other.reducedMotionComposition == reducedMotionComposition &&
          other.reducedFlashOpacity == reducedFlashOpacity;

  @override
  int get hashCode => Object.hash(
    clipId,
    trackId,
    layerId,
    zIndex,
    resourceId,
    startUs,
    durationUs,
    elapsedUs,
    progress,
    easedProgress,
    easing,
    composition,
    reducedMotionComposition,
    reducedFlashOpacity,
  );
}

@immutable
final class PresentationAudioFrameClip {
  const PresentationAudioFrameClip({
    required this.clipId,
    required this.trackId,
    required this.resourceId,
    required this.startUs,
    required this.durationUs,
    required this.elapsedUs,
    required this.progress,
  });

  final String clipId;
  final String trackId;
  final String resourceId;
  final int startUs;
  final int durationUs;
  final int elapsedUs;
  final double progress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationAudioFrameClip &&
          other.clipId == clipId &&
          other.trackId == trackId &&
          other.resourceId == resourceId &&
          other.startUs == startUs &&
          other.durationUs == durationUs &&
          other.elapsedUs == elapsedUs &&
          other.progress == progress;

  @override
  int get hashCode => Object.hash(
    clipId,
    trackId,
    resourceId,
    startUs,
    durationUs,
    elapsedUs,
    progress,
  );
}

@immutable
final class PresentationCaptionFrameClip {
  const PresentationCaptionFrameClip({
    required this.clipId,
    required this.trackId,
    required this.captionId,
    required this.startUs,
    required this.durationUs,
    required this.elapsedUs,
    required this.progress,
  });

  final String clipId;
  final String trackId;
  final String captionId;
  final int startUs;
  final int durationUs;
  final int elapsedUs;
  final double progress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationCaptionFrameClip &&
          other.clipId == clipId &&
          other.trackId == trackId &&
          other.captionId == captionId &&
          other.startUs == startUs &&
          other.durationUs == durationUs &&
          other.elapsedUs == elapsedUs &&
          other.progress == progress;

  @override
  int get hashCode => Object.hash(
    clipId,
    trackId,
    captionId,
    startUs,
    durationUs,
    elapsedUs,
    progress,
  );
}

@immutable
final class PresentationFrameMarker {
  const PresentationFrameMarker({
    required this.clipId,
    required this.trackId,
    required this.label,
    required this.markerKind,
    required this.timeUs,
  });

  final String clipId;
  final String trackId;
  final String label;
  final PresentationMarkerKind markerKind;
  final int timeUs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationFrameMarker &&
          other.clipId == clipId &&
          other.trackId == trackId &&
          other.label == label &&
          other.markerKind == markerKind &&
          other.timeUs == timeUs;

  @override
  int get hashCode => Object.hash(clipId, trackId, label, markerKind, timeUs);
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
