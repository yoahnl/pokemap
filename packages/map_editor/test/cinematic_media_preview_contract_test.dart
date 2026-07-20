import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/preview/flutter_cinematic_media_preview_adapter.dart';

void main() {
  test('Flutter adapter keeps typed audio and FX checkpoints', () async {
    final driver = _RecordingAudioDriver();
    final fxSnapshots = <Set<String>>[];
    final adapter = FlutterCinematicMediaPreviewAdapter(
      mediaAssets: _assets,
      resolvePath: (asset) => '/project/${asset.relativePath}',
      driver: driver,
      onFxChanged: (active) => fxSnapshots.add(active),
    );

    await adapter.execute(
      CinematicMediaPlaybackCommand.play(
        commandId: 'music',
        assetId: 'music.mist',
        channel: 'music',
        volume: 0.6,
        loop: true,
        fadeMs: 500,
      ),
    );
    await adapter.execute(
      CinematicMediaPlaybackCommand.spawnFx(
        commandId: 'fog',
        assetId: 'fx.fog',
        channel: 'atmosphere',
        durationMs: 800,
        intensity: 0.5,
      ),
    );

    final checkpoint = await adapter.captureCheckpoint();
    expect(checkpoint.activeChannels, {'music': 'music.mist'});
    expect(checkpoint.channelVolumes, {'music': 0.6});
    expect(checkpoint.loopingChannels, {'music'});
    expect(checkpoint.activeFxIds, {'fx.fog'});
    expect(driver.paths, ['/project/audio/mist.ogg']);
    expect(driver.volumes, [0.0, 0.6]);
    expect(fxSnapshots.last, {'fx.fog'});

    await adapter.restore(CinematicMediaPlaybackCheckpoint());
    expect(driver.stoppedHandles, ['handle-1']);
    expect(fxSnapshots.last, isEmpty);
  });

  test('Flutter adapter rejects an unknown media reference', () async {
    final adapter = FlutterCinematicMediaPreviewAdapter(
      mediaAssets: _assets,
      resolvePath: (asset) => asset.relativePath,
      driver: _RecordingAudioDriver(),
    );

    await expectLater(
      adapter.execute(
        CinematicMediaPlaybackCommand.play(
          commandId: 'missing',
          assetId: 'sound.missing',
          channel: 'effects',
        ),
      ),
      throwsStateError,
    );
  });
}

final _assets = <CinematicMediaAsset>[
  CinematicMediaAsset(
    id: 'music.mist',
    label: 'Brume matinale',
    kind: CinematicMediaAssetKind.music,
    relativePath: 'audio/mist.ogg',
    channel: 'music',
  ),
  CinematicMediaAsset(
    id: 'fx.fog',
    label: 'Brume montante',
    kind: CinematicMediaAssetKind.cinematicFx,
    relativePath: 'fx/fog.json',
    channel: 'atmosphere',
  ),
];

final class _RecordingAudioDriver implements FlutterCinematicAudioDriver {
  final paths = <String>[];
  final volumes = <double>[];
  final stoppedHandles = <Object>[];
  var _nextHandle = 1;

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    paths.add(path);
    volumes.add(volume);
    return 'handle-${_nextHandle++}';
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> stop(Object handle) async {
    stoppedHandles.add(handle);
  }
}
