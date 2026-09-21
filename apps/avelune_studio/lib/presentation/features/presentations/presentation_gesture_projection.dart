import 'package:map_core/map_core_domain.dart';

PresentationCinematicAsset projectPresentationGesture(
  PresentationCinematicAsset asset,
  PresentationClip clip,
  Map<String, Object?> patch,
) {
  final layerId = switch (clip) {
    PresentationTextClip(:final layerId) => layerId,
    PresentationVisualClip(:final layerId) => layerId,
    _ => null,
  };
  final encoded = encodePresentationCinematicAsset(
    PresentationCinematicAsset(
      id: asset.id,
      title: asset.title,
      durationUs: asset.durationUs,
      layers: asset.layers.where((layer) => layer.id == layerId).toList(),
      tracks: [
        PresentationTrack(
          id: 'gesture',
          label: 'Gesture',
          kind: clip.trackKind,
          clips: [clip],
        ),
      ],
    ),
  );
  final track = (encoded['tracks']! as List).single as Map;
  track['clips'] = [
    {...encodePresentationClip(clip), ...patch},
  ];
  final projected = decodePresentationCinematicAsset(
    encoded,
  ).tracks.single.clips.single;
  return PresentationCinematicAsset(
    id: asset.id,
    title: asset.title,
    description: asset.description,
    durationUs: asset.durationUs,
    layers: asset.layers,
    visualFolders: asset.visualFolders,
    tracks: [
      for (final source in asset.tracks)
        if (source.clips.any((value) => value.id == clip.id))
          PresentationTrack(
            id: source.id,
            label: source.label,
            kind: source.kind,
            holdPolicy: source.holdPolicy,
            clips: [
              for (final value in source.clips)
                value.id == clip.id ? projected : value,
            ],
          )
        else
          source,
    ],
  );
}
