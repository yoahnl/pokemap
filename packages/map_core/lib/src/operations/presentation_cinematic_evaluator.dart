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
            visuals.add(
              PresentationVisualFrameClip(
                clipId: visualClip.id,
                trackId: track.id,
                layerId: visualClip.layerId,
                zIndex: layerZIndexes[visualClip.layerId]!,
                resourceId: visualClip.resourceId,
                startUs: visualClip.startUs,
                durationUs: visualClip.durationUs,
                elapsedUs: resolvedTimeUs - visualClip.startUs,
                progress: progress,
                easedProgress: _ease(progress, visualClip.easing),
                easing: visualClip.easing,
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
