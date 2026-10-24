import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/runtime_audio_mixer.dart';
import 'package:map_runtime/src/player/runtime_music_service.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'package:map_runtime/src/spatial/spatial_scene_audio_runtime.dart';

void main() {
  late _Driver driver;
  late RuntimeAudioMixer mixer;
  late RuntimeMusicService music;
  late SpatialSceneAudioRuntime audio;
  var mapMusic = 'map.ogg';
  final owner = Object();
  setUp(() {
    mapMusic = 'map.ogg';
    driver = _Driver();
    mixer = RuntimeAudioMixer();
    music = RuntimeMusicService(driver: driver, mixer: mixer);
    audio = SpatialSceneAudioRuntime(
      captureMusicBaseline: () =>
          (route: RuntimeAudioRoute.overworld, path: mapMusic, volume: .8),
      mediaAssets: [
        CinematicMediaAsset(
          id: 'theme',
          label: 'Theme',
          kind: CinematicMediaAssetKind.music,
          relativePath: 'theme.ogg',
        ),
        CinematicMediaAsset(
          id: 'cue',
          label: 'Cue',
          kind: CinematicMediaAssetKind.sound,
          relativePath: 'assets/cue.wav',
        ),
      ],
      resolvePath: (asset) => asset.relativePath,
      mixer: mixer,
      music: music,
      driverFactory: () => driver,
    );
  });
  tearDown(() async {
    await audio.dispose();
    await music.dispose();
    for (final controller in driver.completions.values) {
      await controller.close();
    }
  });
  test('scene music is restored only when its owner terminates', () async {
    final play = SceneMusicInteractiveCommand(
      operation: SceneMusicOperation.play,
      mediaAssetId: 'theme',
      volume: .6,
    );
    expect(await audio.execute(play, sceneOwner: owner), 'completed');
    expect(music.playingPath, 'theme.ogg');
    await audio.releaseScene(Object());
    expect(music.playingPath, 'theme.ogg');
    await audio.reset();
    expect(music.playingPath, 'theme.ogg');
    await audio.releaseScene(owner);
    expect(music.playingPath, 'map.ogg');
  });
  test('scene termination uses the newly active map music after transfer', () async {
    await audio.execute(SceneMusicInteractiveCommand(operation: SceneMusicOperation.play,
      mediaAssetId: 'theme', volume: .6), sceneOwner: owner);
    mapMusic = 'arrival.ogg';
    await audio.reset();
    expect(music.playingPath, 'theme.ogg');
    await audio.releaseScene(owner);
    expect(music.playingPath, 'arrival.ogg');
  });

  test(
    'scene music supports memorizing, stopping and restoring a selection',
    () async {
      Future<String> execute(SceneMusicOperation operation) => audio.execute(
        SceneMusicInteractiveCommand(operation: operation),
        sceneOwner: owner,
      );
      expect(await execute(SceneMusicOperation.memorize), 'completed');
      expect(
        await audio.execute(
          SceneMusicInteractiveCommand(
            operation: SceneMusicOperation.play,
            mediaAssetId: 'theme',
            volume: .6,
          ),
          sceneOwner: owner,
        ),
        'completed',
      );
      expect(await execute(SceneMusicOperation.stop), 'completed');
      expect(music.playingPath, isNull);
      expect(await execute(SceneMusicOperation.restoreMemorized), 'completed');
      expect(music.playingPath, 'map.ogg');
      expect(await execute(SceneMusicOperation.restore), 'completed');
      expect(music.playingPath, 'map.ogg');
    },
  );
  test(
    'unsupported spatial audio combinations fail before claiming ownership',
    () async {
      for (final command in [
        SceneMusicInteractiveCommand(
          operation: SceneMusicOperation.stop,
          scope: SceneMusicScope.map,
        ),
        SceneMusicInteractiveCommand(
          operation: SceneMusicOperation.stop,
          channel: SceneMusicChannel.ambience,
        ),
        SceneMusicInteractiveCommand(
          operation: SceneMusicOperation.play,
          mediaAssetId: 'unknown',
          volume: .5,
        ),
      ]) {
        expect(await audio.execute(command, sceneOwner: Object()), 'blocked');
      }
      expect(
        await audio.execute(
          SceneMusicInteractiveCommand(
            operation: SceneMusicOperation.play,
            mediaAssetId: 'theme',
            volume: .6,
          ),
          sceneOwner: owner,
        ),
        'completed',
      );
      expect(
        await audio.execute(
          SceneMusicInteractiveCommand(operation: SceneMusicOperation.stop),
          sceneOwner: Object(),
        ),
        'blocked',
      );
      expect(music.playingPath, 'theme.ogg');
    },
  );
  test('terminating a fading scene cancels every later music update', () async {
    await audio.execute(
      SceneMusicInteractiveCommand(
        operation: SceneMusicOperation.play,
        mediaAssetId: 'theme',
        volume: .6,
      ),
      sceneOwner: owner,
    );
    expect(
      await audio.execute(
        SceneMusicInteractiveCommand(
          operation: SceneMusicOperation.fadeOut,
          durationMs: 600,
        ),
        sceneOwner: owner,
      ),
      'completed',
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await audio.releaseScene(owner);
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(music.playingPath, 'map.ogg');
    expect(audio.musicSelection, isNull);
  });
  test('blocking cue waits for natural audio completion', () async {
    var completed = false;
    final pending = audio
        .execute(
          ScenePlaySoundEffectInteractiveCommand(
            volume: 1,
            mediaAssetId: 'cue',
            waitForCompletion: true,
          ),
          sceneOwner: owner,
        )
        .then((value) {
          completed = true;
          return value;
        });
    await Future<void>.delayed(Duration.zero);
    expect(completed, false);
    driver.completions.values.single.add(null);
    expect(await pending, 'completed');
  });
  test('nonblocking sound returns while its voice remains active', () async {
    expect(
      await audio.execute(
        ScenePlaySoundEffectInteractiveCommand(volume: 1, mediaAssetId: 'cue'),
        sceneOwner: owner,
      ),
      'completed',
    );
    expect(driver.stopped, isEmpty);
  });
  test(
    'scene stop releases only its effects and leaves another scene playing',
    () async {
      final other = Object();
      final first = audio.execute(
        ScenePlaySoundEffectInteractiveCommand(
          volume: 1,
          mediaAssetId: 'cue',
          waitForCompletion: true,
        ),
        sceneOwner: owner,
      );
      final second = audio.execute(
        ScenePlaySoundEffectInteractiveCommand(
          volume: 1,
          mediaAssetId: 'cue',
          waitForCompletion: true,
        ),
        sceneOwner: other,
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        await audio.execute(
          const SceneStopSoundEffectsInteractiveCommand(
            scope: SceneMusicScope.scene,
          ),
          sceneOwner: owner,
        ),
        'completed',
      );
      expect(await first, 'blocked');
      expect(driver.stopped.length, 1);
      driver.completions.values.last.add(null);
      expect(await second, 'completed');
    },
  );
  test(
    'map replacement and disposal release pending completion waits',
    () async {
      final pending = audio.execute(
        ScenePlaySoundEffectInteractiveCommand(
          volume: 1,
          mediaAssetId: 'cue',
          waitForCompletion: true,
        ),
        sceneOwner: owner,
      );
      await Future<void>.delayed(Duration.zero);
      await audio.reset();
      expect(await pending, 'blocked');
      final next = audio.execute(
        ScenePlaySoundEffectInteractiveCommand(
          volume: 1,
          mediaAssetId: 'cue',
          waitForCompletion: true,
        ),
        sceneOwner: owner,
      );
      await Future<void>.delayed(Duration.zero);
      await audio.dispose();
      expect(await next, 'blocked');
    },
  );
  test(
    'map reset awaits release already started by natural completion',
    () async {
      driver.stopGate = Completer<void>();
      final cue = audio.execute(
        ScenePlaySoundEffectInteractiveCommand(
          volume: 1,
          mediaAssetId: 'cue',
          waitForCompletion: true,
        ),
        sceneOwner: owner,
      );
      await Future<void>.delayed(Duration.zero);
      driver.completions.values.single.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(driver.stopped, hasLength(1));
      var resetFinished = false;
      final reset = audio.reset().then((_) => resetFinished = true);
      await Future<void>.delayed(Duration.zero);
      try {
        expect(resetFinished, false);
      } finally {
        driver.stopGate!.complete();
        await reset;
        expect(await cue, 'blocked');
      }
    },
  );
  test('invalid media blocks without starting a voice', () async {
    expect(
      await audio.execute(
        ScenePlaySoundEffectInteractiveCommand(
          volume: 1,
          mediaAssetId: 'unknown',
          waitForCompletion: true,
        ),
        sceneOwner: owner,
      ),
      'blocked',
    );
    expect(driver.completions, isEmpty);
    expect(audio.lastFailure, isA<StateError>());
  });
  test('effects stop does not stop a fanfare using the music bus', () async {
    final fanfare = audio.execute(
      ScenePlayMusicEffectInteractiveCommand(
        volume: 1,
        bgmInterruption: DialogueBgmInterruption(fadeOutMs: 0, fadeInMs: 0),
        mediaAssetId: 'cue',
        waitForCompletion: true,
      ),
      sceneOwner: owner,
    );
    await Future<void>.delayed(Duration.zero);
    await audio.execute(
      const SceneStopSoundEffectsInteractiveCommand(scope: SceneMusicScope.map),
      sceneOwner: owner,
    );
    expect(audio.lastFailure, isNull);
    expect(driver.stopped, isEmpty);
    driver.completions.values.single.add(null);
    expect(await fanfare, 'completed');
  });
  test('map reset cancels a fanfare and stale completion cannot finish the next map cue', () async {
    final fanfare = audio.execute(
      ScenePlayMusicEffectInteractiveCommand(
        volume: 1,
        bgmInterruption: DialogueBgmInterruption(fadeOutMs: 0, fadeInMs: 0),
        mediaAssetId: 'cue',
        waitForCompletion: true,
      ),
      sceneOwner: owner,
    );
    await Future<void>.delayed(Duration.zero);
    expect(audio.lastFailure, isNull);
    final previous = driver.completions.values.single;
    await audio.reset();
    expect(await fanfare, 'blocked');
    var finished = false;
    final next = audio
        .execute(
          ScenePlaySoundEffectInteractiveCommand(
            volume: 1,
            mediaAssetId: 'cue',
            waitForCompletion: true,
          ),
          sceneOwner: owner,
        )
        .then((value) {
          finished = true;
          return value;
        });
    await Future<void>.delayed(Duration.zero);
    previous.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(finished, false);
    driver.completions.values.last.add(null);
    expect(await next, 'completed');
  });
}

final class _Driver
    implements
        FlameCinematicAudioDriver,
        FlameCinematicAudioLoopDriver,
        FlameCinematicAudioPausableDriver {
  final completions = <Object, StreamController<void>>{};
  final stopped = <Object>[];
  Completer<void>? stopGate;
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    final handle = Object();
    completions[handle] = StreamController<void>.broadcast(sync: true);
    return handle;
  }

  @override
  Future<void> stop(Object handle) async {
    stopped.add(handle);
    await stopGate?.future;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}
  @override
  Stream<void> onComplete(Object handle) => completions[handle]!.stream;
  @override
  Future<void> seekAndResume(Object handle, Duration position) async {}
  @override
  Future<void> pause(Object handle) async {}
  @override
  Future<void> resume(Object handle) async {}
}
