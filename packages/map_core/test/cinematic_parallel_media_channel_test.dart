import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('different media kinds on the same physical channel conflict', () {
    final asset = _cinematic();
    final media = _media(shared: true);
    expect(
      preflightCinematicPlayback(cinematic: asset, mediaAssets: media).isReady,
      isFalse,
    );
    final project = ProjectManifest(
      name: 'Media',
      maps: const [],
      tilesets: const [],
      cinematicMediaAssets: media,
    );
    expect(() => addCinematicAsset(project, asset), throwsArgumentError);
    expect(
      buildCinematicPreviewPlaybackPlan(
        cinematic: asset,
        mediaAssets: media,
      ).schedule.isValid,
      isFalse,
    );
  });

  test('same media kind on distinct physical channels can run together', () {
    final asset = _cinematic(sameKind: true);
    final media = _media(shared: false, sameKind: true);
    expect(
      preflightCinematicPlayback(cinematic: asset, mediaAssets: media).isReady,
      isTrue,
    );
    final project = ProjectManifest(
      name: 'Media',
      maps: const [],
      tilesets: const [],
      cinematicMediaAssets: media,
    );
    expect(addCinematicAsset(project, asset).cinematic, asset);
    expect(
      buildCinematicPreviewPlaybackPlan(
        cinematic: asset,
        mediaAssets: media,
      ).schedule.isValid,
      isTrue,
    );
  });
}

CinematicAsset _cinematic({bool sameKind = false}) => CinematicAsset(
  id: 'media',
  title: 'Media',
  mapId: 'room',
  timeline: CinematicTimeline(
    steps: [
      CinematicTimelineStep(
        id: 'a',
        kind: CinematicTimelineStepKind.sound,
        assetRef: 'a',
        durationMs: 1000,
        parallelGroupId: 'pair',
      ),
      CinematicTimelineStep(
        id: 'b',
        kind: sameKind
            ? CinematicTimelineStepKind.sound
            : CinematicTimelineStepKind.music,
        assetRef: 'b',
        durationMs: 1000,
        parallelGroupId: 'pair',
      ),
    ],
  ),
);

List<CinematicMediaAsset> _media({
  required bool shared,
  bool sameKind = false,
}) => [
  CinematicMediaAsset(
    id: 'a',
    label: 'A',
    kind: CinematicMediaAssetKind.sound,
    relativePath: 'audio/a.ogg',
    channel: shared ? 'shared' : 'a',
  ),
  CinematicMediaAsset(
    id: 'b',
    label: 'B',
    kind: sameKind
        ? CinematicMediaAssetKind.sound
        : CinematicMediaAssetKind.music,
    relativePath: 'audio/b.ogg',
    channel: shared ? 'shared' : 'b',
  ),
];
