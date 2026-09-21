import 'package:map_core/map_core_domain.dart';

String presentationClipLabel(PresentationClip clip) => switch (clip) {
  PresentationTextClip(:final text) => text,
  PresentationVisualClip(:final resourceId) => resourceId,
  PresentationAudioClip(:final resourceId) => resourceId,
  PresentationCaptionClip(:final captionId) => captionId,
  PresentationMarkerClip(:final label) => label,
};

String presentationClipKind(PresentationClip clip) => switch (clip) {
  PresentationTextClip() => 'Texte',
  PresentationVisualClip(:final mediaKind) => switch (mediaKind) {
    PresentationVisualMediaKind.image => 'Image',
    PresentationVisualMediaKind.video => 'Vidéo',
    PresentationVisualMediaKind.poster => 'Poster',
  },
  PresentationAudioClip() => 'Audio',
  PresentationCaptionClip() => 'Sous-titres',
  PresentationMarkerClip() => 'Repère',
};

String? presentationClipLayer(PresentationClip clip) => switch (clip) {
  PresentationTextClip(:final layerId) => layerId,
  PresentationVisualClip(:final layerId) => layerId,
  _ => null,
};

String presentationTime(int microseconds) =>
    '${(microseconds / 1000000).toStringAsFixed(3)} s';
