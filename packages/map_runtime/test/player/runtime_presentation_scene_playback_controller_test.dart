import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('evaluates frames and completes one Presentation run', () async {
    final frames = <PresentationFrame?>[];
    final media = RuntimePresentationMediaPlaybackController(
      catalog: ProjectMediaCatalog(),
      targetPlatform: PresentationMediaTargetPlatform.macos,
      resolveUri: (_) => Uri(),
      videoDriver: _UnusedVideoDriver(),
    );
    final execution = RuntimePresentationExecutionController(
      mediaController: media,
    );
    final player = RuntimePresentationScenePlaybackController(
      executionController: execution,
      onFrame: (_, frame) => frames.add(frame),
      frameDeltas: (_) => Stream<int>.fromIterable(<int>[500000, 500000]),
    );
    addTearDown(player.dispose);

    final terminal = await player.playPresentationCinematic(
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
    expect(frames.whereType<PresentationFrame>().map((frame) => frame.timeUs),
        <int>[0, 500000, 1000000]);
    expect(frames.last, isNull);
  });

  test('skip terminalizes the active run without a legacy fallback', () async {
    final execution = RuntimePresentationExecutionController(
      mediaController: RuntimePresentationMediaPlaybackController(
        catalog: ProjectMediaCatalog(),
        targetPlatform: PresentationMediaTargetPlatform.macos,
        resolveUri: (_) => Uri(),
        videoDriver: _UnusedVideoDriver(),
      ),
    );
    final tick = Stream<int>.multi((controller) {});
    final player = RuntimePresentationScenePlaybackController(
      executionController: execution,
      onFrame: (_, __) {},
      frameDeltas: (_) => tick,
    );
    addTearDown(player.dispose);
    final terminal = player.playPresentationCinematic(
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

    await player.skipActive();

    expect(
      (await terminal).result,
      RuntimePresentationExecutionResult.skipped,
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
