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
        ),
      ),
    );
    expect(terminal.result, RuntimePresentationExecutionResult.completed);
    expect(values.whereType<RuntimePresentationFrameSnapshot>(), isNotEmpty);
    expect(controller.value, isNull);
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
