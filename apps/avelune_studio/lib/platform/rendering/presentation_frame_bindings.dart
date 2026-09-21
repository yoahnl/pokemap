import 'package:map_core/map_core_domain.dart';
import 'package:map_player_ui/presentation_renderer.dart';

List<PresentationFrameMediaBinding> presentationMediaBindings(
  PresentationCinematicAsset asset,
) => [
  for (final track in asset.tracks)
    for (final clip in track.clips)
      if (clip is PresentationVisualClip)
        PresentationFrameMediaBinding(
          clipId: clip.id,
          kind: switch (clip.mediaKind) {
            PresentationVisualMediaKind.image =>
              PresentationFrameMediaKind.image,
            PresentationVisualMediaKind.video =>
              PresentationFrameMediaKind.video,
            PresentationVisualMediaKind.poster =>
              PresentationFrameMediaKind.poster,
          },
          sharedResourceId: clip.resourceId,
          landscapeResourceId: clip.landscapeResourceId,
          portraitResourceId: clip.portraitResourceId,
        ),
];

PresentationFrameOrientationOverrides presentationOrientationOverrides(
  PresentationCinematicAsset asset,
) => PresentationFrameOrientationOverrides(
  visualsByClipId: {
    for (final track in asset.tracks)
      for (final clip in track.clips)
        if (clip is PresentationVisualClip || clip is PresentationTextClip)
          clip.id: PresentationVisualOrientationOverride(
            landscape: _landscape(clip),
            portrait: _portrait(clip),
            reducedMotionLandscape: _landscape(clip),
            reducedMotionPortrait: _portrait(clip),
          ),
  },
);

PresentationVisualComposition? _landscape(PresentationClip clip) =>
    switch (clip) {
      PresentationVisualClip() => clip.landscapeCompositionOverride,
      PresentationTextClip() => clip.landscapeCompositionOverride,
      _ => null,
    };
PresentationVisualComposition? _portrait(PresentationClip clip) =>
    switch (clip) {
      PresentationVisualClip() => clip.portraitCompositionOverride,
      PresentationTextClip() => clip.portraitCompositionOverride,
      _ => null,
    };
