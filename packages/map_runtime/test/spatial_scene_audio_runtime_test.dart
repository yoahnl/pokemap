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
  final owner = Object();
  setUp(() {
    driver = _Driver();
    mixer = RuntimeAudioMixer();
    music = RuntimeMusicService(driver: driver, mixer: mixer);
    audio = SpatialSceneAudioRuntime(
      mediaAssets: [
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
  test('map reset awaits release already started by natural completion', () async {
    driver.stopGate = Completer<void>();
    final cue = audio.execute(
      ScenePlaySoundEffectInteractiveCommand(volume: 1, mediaAssetId: 'cue',
        waitForCompletion: true),
      sceneOwner: owner);
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
  });
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
