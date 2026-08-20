import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'package:map_runtime/map_runtime.dart';

/// Les captions runtime pendant Presentation interactive — BETA-CIN-078.
///
/// Le contrôleur de surface runtime charge les fichiers WebVTT référencés
/// par les clips caption via le MÊME décodeur que le Studio, suit le temps
/// évalué, reste stable pendant un hold (le playhead figé fige le segment),
/// et produit des diagnostics explicites pour un média absent ou un fichier
/// invalide — jamais un texte indéfini.
void main() {
  const clipAt = PresentationCaptionFrameClip(
    clipId: 'cap_1',
    trackId: 'captions',
    captionId: 'media_captions',
    startUs: 0,
    durationUs: 4000000,
    elapsedUs: 500000,
    progress: 0.125,
  );

  PresentationCinematicAsset asset() => PresentationCinematicAsset(
        id: 'opening',
        title: 'Opening',
        durationUs: 4000000,
        tracks: [
          PresentationTrack(
            id: 'captions',
            label: 'Sous-titres',
            kind: PresentationTrackKind.caption,
            clips: [
              PresentationCaptionClip(
                id: 'cap_1',
                startUs: 0,
                durationUs: 4000000,
                captionId: 'media_captions',
              ),
            ],
          ),
        ],
      );

  RuntimePresentationSurfaceController controller({
    required Map<String, Uri> mediaUris,
    ProjectMediaCatalog? catalog,
  }) =>
      RuntimePresentationSurfaceController(
        catalog: catalog ??
            ProjectMediaCatalog(
              entries: [
                ProjectMediaAsset(
                  id: 'media_captions',
                  label: 'Sous-titres',
                  kind: ProjectMediaKind.captions,
                  sourceAssetId: 'asset_captions',
                ),
              ],
            ),
        mediaUris: mediaUris,
        targetPlatform: PresentationMediaTargetPlatform.macos,
        videoDriver: _UnusedVideoDriver(),
      );

  ScenePresentationCinematicRuntimeRequest request() =>
      ScenePresentationCinematicRuntimeRequest(
        requestId: 'runtime:opening:captions',
        createdAtEpochMs: 1,
        projectRevision:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        contentHash:
            'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        presentationCinematicId: 'opening',
        asset: asset(),
      );

  test('resolves the active segment through the shared decoder', () async {
    final directory =
        await Directory.systemTemp.createTemp('pokemap-captions-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/captions.vtt');
    await file.writeAsString('''
WEBVTT

00:00.000 --> 00:01.000
Première ligne.

00:01.000 --> 00:02.000
Deuxième ligne.
''');
    final surface = controller(mediaUris: {'media_captions': file.uri});
    addTearDown(surface.close);

    expect(
      surface.resolveCaption(clip: clipAt, locale: const Locale('fr')),
      isA<PresentationCaptionUnavailable>().having(
        (resolution) => resolution.message,
        'message',
        contains('en cours de chargement'),
      ),
      reason: 'before the preload lands, the state is explicit — never an '
          'undefined text',
    );

    await surface.playPresentationCinematic(request());

    final early = surface.resolveCaption(
      clip: clipAt,
      locale: const Locale('fr'),
    );
    expect((early as PresentationCaptionReady).text, 'Première ligne.');

    final later = surface.resolveCaption(
      clip: const PresentationCaptionFrameClip(
        clipId: 'cap_1',
        trackId: 'captions',
        captionId: 'media_captions',
        startUs: 0,
        durationUs: 4000000,
        elapsedUs: 1500000,
        progress: 0.375,
      ),
      locale: const Locale('fr'),
    );
    expect((later as PresentationCaptionReady).text, 'Deuxième ligne.');

    final gap = surface.resolveCaption(
      clip: const PresentationCaptionFrameClip(
        clipId: 'cap_1',
        trackId: 'captions',
        captionId: 'media_captions',
        startUs: 0,
        durationUs: 4000000,
        elapsedUs: 3500000,
        progress: 0.875,
      ),
      locale: const Locale('fr'),
    );
    expect(
      (gap as PresentationCaptionReady).text,
      isEmpty,
      reason: 'a gap between segments renders an empty caption, like the '
          'Studio',
    );

    final held = surface.resolveCaption(
      clip: clipAt,
      locale: const Locale('fr'),
    );
    expect(
      (held as PresentationCaptionReady).text,
      'Première ligne.',
      reason: 'the frozen playhead of a hold resolves the same segment '
          'deterministically — captions stay stable during the wait',
    );
  });

  test('a media missing from the catalog is an explicit diagnostic',
      () async {
    final surface = controller(
      mediaUris: const {},
      catalog: ProjectMediaCatalog(),
    );
    addTearDown(surface.close);
    await surface.playPresentationCinematic(request());

    final resolution = surface.resolveCaption(
      clip: clipAt,
      locale: const Locale('fr'),
    );
    expect(
      resolution,
      isA<PresentationCaptionUnavailable>()
          .having(
            (unavailable) => unavailable.reason,
            'reason',
            PresentationContentUnavailableReason.missing,
          )
          .having(
            (unavailable) => unavailable.message,
            'message',
            contains('introuvable'),
          ),
    );
  });

  test('an invalid WebVTT file surfaces the decoder message', () async {
    final directory =
        await Directory.systemTemp.createTemp('pokemap-captions-bad-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/captions.vtt');
    await file.writeAsString('PAS DU VTT');
    final surface = controller(mediaUris: {'media_captions': file.uri});
    addTearDown(surface.close);
    await surface.playPresentationCinematic(request());

    final resolution = surface.resolveCaption(
      clip: clipAt,
      locale: const Locale('fr'),
    );
    expect(
      resolution,
      isA<PresentationCaptionUnavailable>()
          .having(
            (unavailable) => unavailable.reason,
            'reason',
            PresentationContentUnavailableReason.unsupported,
          )
          .having(
            (unavailable) => unavailable.message,
            'message',
            'Fichier captions WEBVTT invalide.',
          ),
    );
  });
}

final class _UnusedVideoDriver
    implements RuntimePresentationVideoPlaybackDriver {
  @override
  Future<Object> prepare(Uri source, {required double initialVolume}) =>
      Future<Object>.error(StateError('unused'));

  @override
  Future<void> play(Object handle) async {}

  @override
  Future<void> pause(Object handle) async {}

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> dispose(Object handle) async {}
}
