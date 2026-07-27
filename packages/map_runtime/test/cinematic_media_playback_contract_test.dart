import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart'
    show RuntimeAudioMix, RuntimeAudioMixer;
import 'package:map_runtime/src/application/scene_runtime/cinematic_media_playback_port.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_fx_playback_adapter.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';

void main() {
  test('Flame adapter plays, checkpoints and restores audio and FX', () async {
    final driver = _RecordingAudioDriver();
    final fxHost = _RecordingFxHost();
    final adapter = FlameCinematicMediaPlaybackAdapter(
      mediaAssets: _assets,
      resolvePath: (asset) => '/project/${asset.relativePath}',
      fx: FlameCinematicFxPlaybackAdapter(host: fxHost),
      audioDriver: driver,
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
        commandId: 'fx',
        assetId: 'fx.fog',
        channel: 'atmosphere',
        durationMs: 800,
        intensity: 0.7,
      ),
    );

    final checkpoint = await adapter.captureCheckpoint();
    expect(checkpoint.activeChannels, {'music': 'music.mist'});
    expect(checkpoint.channelVolumes, {'music': 0.6});
    expect(checkpoint.loopingChannels, {'music'});
    expect(checkpoint.activeFxIds, {'fx.fog'});
    expect(driver.paths, ['/project/audio/mist.ogg']);
    expect(driver.volumes, [0.0, 0.6]);
    expect(fxHost.visible, {'fx.fog': 0.7});

    await adapter.restore(CinematicMediaPlaybackCheckpoint());
    expect(driver.stopped, ['audio-1']);
    expect(fxHost.visible, isEmpty);
  });

  test('runtime command translator keeps media defaults and excludes marker',
      () {
    final sound = CinematicTimelineStep(
      id: 'sound',
      kind: CinematicTimelineStepKind.sound,
      assetRef: 'sound.bell',
    );
    final marker = CinematicTimelineStep(
      id: 'marker',
      kind: CinematicTimelineStepKind.marker,
    );

    final command = cinematicMediaCommandForStep(
      sound,
      mediaAssets: _assets,
    )!;

    expect(command.kind, CinematicMediaPlaybackCommandKind.play);
    expect(command.assetId, 'sound.bell');
    expect(command.channel, 'effects');
    expect(cinematicMediaCommandForStep(marker, mediaAssets: _assets), isNull);
  });

  test('cinematic music and sound follow their live mixer buses', () async {
    final driver = _RecordingAudioDriver();
    final mixer = RuntimeAudioMixer(
      mix: const RuntimeAudioMix(
        masterVolume: 0.5,
        musicVolume: 0.4,
        effectsVolume: 0.2,
      ),
    );
    final adapter = FlameCinematicMediaPlaybackAdapter(
      mediaAssets: _assets,
      resolvePath: (asset) => '/project/${asset.relativePath}',
      fx: FlameCinematicFxPlaybackAdapter(host: _RecordingFxHost()),
      audioDriver: driver,
      audioMixer: mixer,
    );

    await adapter.execute(
      CinematicMediaPlaybackCommand.play(
        commandId: 'music',
        assetId: 'music.mist',
        channel: 'music',
        volume: 0.5,
        loop: true,
      ),
    );
    await adapter.execute(
      CinematicMediaPlaybackCommand.play(
        commandId: 'sound',
        assetId: 'sound.bell',
        channel: 'effects',
        volume: 0.5,
      ),
    );
    expect(driver.volumes, [0.1, 0.05]);

    await mixer.transitionTo(
      const RuntimeAudioMix(
        masterVolume: 0.8,
        musicVolume: 0.5,
        effectsVolume: 0.25,
      ),
    );
    expect(driver.volumes, [0.1, 0.05, 0.2, 0.1]);
  });
}

final _assets = <CinematicMediaAsset>[
  CinematicMediaAsset(
    id: 'sound.bell',
    label: 'Cloche',
    kind: CinematicMediaAssetKind.sound,
    relativePath: 'audio/bell.ogg',
    channel: 'effects',
  ),
  CinematicMediaAsset(
    id: 'music.mist',
    label: 'Brume',
    kind: CinematicMediaAssetKind.music,
    relativePath: 'audio/mist.ogg',
    channel: 'music',
  ),
  CinematicMediaAsset(
    id: 'fx.fog',
    label: 'Brume montante',
    kind: CinematicMediaAssetKind.cinematicFx,
    relativePath: 'fx/fog.json',
  ),
];

final class _RecordingAudioDriver implements FlameCinematicAudioDriver {
  final paths = <String>[];
  final volumes = <double>[];
  final stopped = <Object>[];
  int _next = 1;

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    paths.add(path);
    volumes.add(volume);
    return 'audio-${_next++}';
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> stop(Object handle) async {
    stopped.add(handle);
  }
}

final class _RecordingFxHost implements FlameCinematicFxHost {
  final visible = <String, double>{};

  @override
  void showCinematicFx(String assetId, {required double intensity}) {
    visible[assetId] = intensity;
  }

  @override
  void hideCinematicFx(String assetId) {
    visible.remove(assetId);
  }

  @override
  void clearCinematicFx() {
    visible.clear();
  }
}
