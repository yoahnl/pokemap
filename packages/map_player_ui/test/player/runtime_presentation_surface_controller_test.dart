import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('publishes runtime frames and clears them before completion', () async {
    final controller = RuntimePresentationSurfaceController(
      catalog: ProjectMediaCatalog(),
      mediaUris: const <String, Uri>{},
      targetPlatform: PresentationMediaTargetPlatform.macos,
      videoDriver: _UnusedVideoDriver(),
      frameDeltas: (_) => Stream<int>.value(1000000),
      beforeTerminal: () async {},
    );
    addTearDown(controller.close);
    final values = <RuntimePresentationFrameSnapshot?>[];
    controller.addListener(() => values.add(controller.value));

    final terminal = await controller.playPresentationCinematic(
      ScenePresentationCinematicRuntimeRequest(
        requestId: 'runtime:opening:1',
        createdAtEpochMs: 1,
        projectRevision:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        contentHash:
            'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        presentationCinematicId: 'opening',
        asset: PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 1000000,
          layers: <PresentationLayer>[
            PresentationLayer(id: 'title-layer', label: 'Title', zIndex: 0),
          ],
          tracks: <PresentationTrack>[
            PresentationTrack(
              id: 'visuals',
              label: 'Visuals',
              kind: PresentationTrackKind.visual,
              clips: <PresentationClip>[
                PresentationTextClip(
                  id: 'title',
                  startUs: 0,
                  durationUs: 1000000,
                  layerId: 'title-layer',
                  text: 'Opening',
                  landscapeCompositionOverride:
                      PresentationVisualComposition(translateX: -.2),
                  portraitCompositionOverride: PresentationVisualComposition(
                    translateY: .3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(terminal.result, RuntimePresentationExecutionResult.completed);
    final snapshot = values
        .whereType<RuntimePresentationFrameSnapshot>()
        .firstWhere((value) => value.frame.texts.isNotEmpty);
    final override = snapshot.orientationOverrides.visualsByClipId['title'];
    expect(override?.landscape?.translateX, -.2);
    expect(override?.portrait?.translateY, .3);
    expect(controller.value, isNull);
  });

  test('routes authored audio through the runtime playback pipeline', () async {
    final controller = RuntimePresentationSurfaceController(
      catalog: ProjectMediaCatalog(),
      mediaUris: const <String, Uri>{},
      targetPlatform: PresentationMediaTargetPlatform.macos,
      videoDriver: _UnusedVideoDriver(),
      frameDeltas: (_) => Stream<int>.value(1000000),
      beforeTerminal: () async {},
    );
    addTearDown(controller.close);

    final terminal = await controller.playPresentationCinematic(
      ScenePresentationCinematicRuntimeRequest(
        requestId: 'runtime:opening:missing-audio',
        createdAtEpochMs: 1,
        projectRevision:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        contentHash:
            'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        presentationCinematicId: 'opening',
        asset: PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 1000000,
          tracks: <PresentationTrack>[
            PresentationTrack(
              id: 'music',
              label: 'Music',
              kind: PresentationTrackKind.audio,
              clips: <PresentationClip>[
                PresentationAudioClip(
                  id: 'theme',
                  startUs: 0,
                  durationUs: 1000000,
                  resourceId: 'missing-theme',
                  audioKind: PresentationAudioKind.music,
                  bus: PresentationAudioBus.music,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    expect(terminal.result, RuntimePresentationExecutionResult.failed);
    expect(
      terminal.diagnosticCode,
      PresentationDiagnosticCodes.mediaMissing,
    );
  });

  test('resolves an installed image without network fallback', () async {
    final controller = RuntimePresentationSurfaceController(
      catalog: ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          ProjectMediaAsset(
            id: 'opening.poster',
            label: 'Opening',
            kind: ProjectMediaKind.poster,
            sourceAssetId: 'asset.opening.poster',
          ),
        ],
      ),
      mediaUris: <String, Uri>{
        'opening.poster': Uri.file('/tmp/opening.png'),
      },
      targetPlatform: PresentationMediaTargetPlatform.macos,
      videoDriver: _UnusedVideoDriver(),
      beforeTerminal: () async {},
    );
    addTearDown(controller.close);

    final resolution = controller.resolveVisual(
      clip: _visualFrame('opening.poster'),
      orientation: PresentationFrameOrientation.landscape,
    );

    expect(resolution, isA<PresentationVisualReady>());
    expect(
      (resolution as PresentationVisualReady).child,
      isA<Image>(),
    );
  });
}

PresentationVisualFrameClip _visualFrame(String resourceId) =>
    PresentationVisualFrameClip(
      clipId: 'visual',
      trackId: 'visuals',
      layerId: 'main',
      zIndex: 0,
      resourceId: resourceId,
      startUs: 0,
      durationUs: 1000000,
      elapsedUs: 0,
      progress: 0,
      easedProgress: 0,
      easing: PresentationEasing.linear,
      composition: PresentationVisualComposition.identity,
      reducedMotionComposition: PresentationVisualComposition.identity,
    );

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
