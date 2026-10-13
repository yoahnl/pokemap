import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/runtime_audio_mixer.dart';
import 'package:map_runtime/src/player/runtime_music_service.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'package:map_runtime/src/presentation/flame/flame_dialogue_feedback_playback_adapter.dart';

void main() {
  test(
    'ME uses the music bus and starts before the BGM fade completes',
    () async {
      final driver = _Driver();
      final fades = <Completer<void>>[];
      final mixer = RuntimeAudioMixer(
        mix: const RuntimeAudioMix(
          masterVolume: .5,
          musicVolume: .4,
          effectsVolume: .1,
        ),
      );
      final music = RuntimeMusicService(
        driver: driver,
        mixer: mixer,
        fadeSteps: 2,
        fadeDelay: (_) {
          final gate = Completer<void>();
          fades.add(gate);
          return gate.future;
        },
      );
      final player = _player(driver, mixer, music);
      await music.update(
        route: RuntimeAudioRoute.overworld,
        path: 'map.ogg',
        volume: .8,
      );
      final bgm = driver.handles.last;
      await player.playCue(
        _cue(fadeOutMs: 200, fadeInMs: 0),
        playbackId: 'first',
      );
      final me = driver.handles.last;
      expect(driver.initialVolumes[me], closeTo(.128, 1e-12));
      expect(fades, hasLength(1));
      expect(driver.paused, isEmpty);
      fades.removeAt(0).complete();
      await _flush();
      expect(driver.volumes[bgm], closeTo(.08, 1e-12));
      expect(driver.volumes[me], closeTo(.128, 1e-12));
      fades.removeAt(0).complete();
      await _flush();
      expect(driver.paused, [bgm]);
      await mixer.transitionTo(
        const RuntimeAudioMix(
          masterVolume: .5,
          musicVolume: .6,
          effectsVolume: .1,
        ),
      );
      expect(driver.volumes[bgm], 0);
      expect(driver.volumes[me], closeTo(.192, 1e-12));
      driver.complete(me);
      await _flush();
      expect(driver.resumed, [bgm]);
      expect(driver.volumes[bgm], closeTo(.24, 1e-12));
      await player.dispose();
      await music.dispose();
    },
  );

  test(
    'ME completion resumes BGM independently of any dialogue duration',
    () async {
      final driver = _Driver();
      final mixer = RuntimeAudioMixer();
      final music = RuntimeMusicService(
        driver: driver,
        mixer: mixer,
        fadeDelay: (_) async {},
      );
      final player = _player(driver, mixer, music);
      await music.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final bgm = driver.handles.last;
      await player.playCue(_cue(), playbackId: 'first');
      final me = driver.handles.last;
      await _flush();
      expect(driver.paused, [bgm]);
      expect(driver.stopped, isEmpty);
      expect(driver.resumed, isEmpty);
      driver.complete(me);
      await _flush();
      expect(driver.stopped, [me]);
      expect(driver.resumed, [bgm]);
      driver.complete(me);
      await _flush();
      expect(driver.resumed, [bgm]);
      await player.dispose();
      await music.dispose();
    },
  );

  test(
    'two independent fanfares cannot release each other BGM lease',
    () async {
      final driver = _Driver();
      final mixer = RuntimeAudioMixer();
      final music = RuntimeMusicService(
        driver: driver,
        mixer: mixer,
        fadeDelay: (_) async {},
      );
      final player = _player(driver, mixer, music);
      await music.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final bgm = driver.handles.last;
      await player.playCue(_cue(), playbackId: 'first');
      final first = driver.handles.last;
      await player.playCue(_cue(), playbackId: 'second');
      final second = driver.handles.last;
      await _flush();
      driver.complete(first);
      await _flush();
      expect(driver.resumed, isEmpty);
      expect(driver.volumes[bgm], 0);
      driver.complete(second);
      await _flush();
      expect(driver.resumed, [bgm]);
      expect(driver.stopped, [first, second]);
      await player.dispose();
      await music.dispose();
    },
  );

  test(
    'ME startup failure releases its BGM lease and propagates the error',
    () async {
      final driver = _Driver();
      final mixer = RuntimeAudioMixer();
      final music = RuntimeMusicService(
        driver: driver,
        mixer: mixer,
        fadeDelay: (_) async {},
      );
      final player = _player(driver, mixer, music);
      await music.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final bgm = driver.handles.last;
      driver.failNext = true;
      await expectLater(
        player.playCue(_cue(), playbackId: 'failed'),
        throwsStateError,
      );
      await _flush();
      expect(driver.volumes[bgm], .8);
      expect(driver.playCalls, 2);
      expect(driver.volumes.values, hasLength(1));
      await player.dispose();
      await music.dispose();
    },
  );

  test(
    'dispose releases active ME and stale completion cannot resume a new track',
    () async {
      final driver = _Driver();
      final mixer = RuntimeAudioMixer();
      final music = RuntimeMusicService(
        driver: driver,
        mixer: mixer,
        fadeDelay: (_) async {},
      );
      final player = _player(driver, mixer, music);
      await music.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final bgm = driver.handles.last;
      await player.playCue(_cue(), playbackId: 'first');
      final me = driver.handles.last;
      await _flush();
      await music.dispose();
      await player.dispose();
      driver.complete(me);
      await _flush();
      expect(driver.stopped.toSet(), {bgm, me});
      expect(driver.resumed, isEmpty);
    },
  );

  test(
    'a late ME handle on shutdown is stopped and releases the BGM lease',
    () async {
      final driver = _Driver();
      final mixer = RuntimeAudioMixer();
      final music = RuntimeMusicService(
        driver: driver,
        mixer: mixer,
        fadeDelay: (_) async {},
      );
      final player = _player(driver, mixer, music);
      await music.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final bgm = driver.handles.last;
      driver.playGate = Completer<Object>();
      final first = player.playCue(_cue(), playbackId: 'late');
      final duplicate = player.playCue(_cue(), playbackId: 'late');
      await _flush();
      final me = driver.handles.last;
      expect(driver.playCalls, 2);
      expect(driver.paused, [bgm]);
      final closing = player.dispose();
      driver.playGate!.complete(me);
      await Future.wait([first, duplicate, closing]);
      expect(driver.stopped, [me]);
      expect(driver.resumed, [bgm]);
      expect(driver.volumes[bgm], .8);
      driver.complete(me);
      await _flush();
      expect(driver.resumed, [bgm]);
      await music.dispose();
    },
  );

  test(
    'an interrupting cue without a BGM service is rejected before playback',
    () async {
      final driver = _Driver();
      final player = FlameDialogueFeedbackPlaybackAdapter(
        mediaAssets: [
          CinematicMediaAsset(
            id: 'fanfare',
            label: 'Original fanfare',
            kind: CinematicMediaAssetKind.sound,
            relativePath: 'original.wav',
            durationMs: 1000,
          ),
        ],
        resolvePath: (asset) => asset.relativePath,
        audioDriver: driver,
      );
      await expectLater(
        player.playCue(_cue(), playbackId: 'missing-service'),
        throwsStateError,
      );
      expect(driver.playCalls, 0);
      await player.dispose();
    },
  );

  test('an audio stream failure releases ME ownership without inventing completion', () async {
    final driver = _Driver();
    final mixer = RuntimeAudioMixer();
    final music = RuntimeMusicService(
      driver: driver,
      mixer: mixer,
      fadeDelay: (_) async {},
    );
    final player = _player(driver, mixer, music);
    await music.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
    final bgm = driver.handles.last;
    await player.playCue(_cue(), playbackId: 'stream-failure');
    final me = driver.handles.last;
    await _flush();
    final failure = StateError('Original backend stream failure');
    driver.completions[me]!.addError(failure);
    await _flush();
    expect(player.lastFailure, same(failure));
    expect(driver.stopped, [me]);
    expect(driver.resumed, [bgm]);
    expect(driver.volumes[bgm], .8);
    await player.dispose();
    await music.dispose();
  });

  test(
    'real driver retains completion emitted before its play future returns',
    () async {
      final bgmDriver = _Driver();
      final mixer = RuntimeAudioMixer();
      final music = RuntimeMusicService(
        driver: bgmDriver,
        mixer: mixer,
        fadeDelay: (_) async {},
      );
      final voice = _NativeVoice()..playGate = Completer<void>();
      final driver = FlameAudioCinematicRuntimeDriver(
        playerFactory: () => voice,
      );
      final player = FlameDialogueFeedbackPlaybackAdapter(
        mediaAssets: [
          CinematicMediaAsset(
            id: 'fanfare',
            label: 'Original fanfare',
            kind: CinematicMediaAssetKind.sound,
            relativePath: 'original.wav',
            durationMs: 1000,
          ),
        ],
        resolvePath: (asset) => asset.relativePath,
        audioDriver: driver,
        mixer: mixer,
        musicService: music,
      );
      await music.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      final bgm = bgmDriver.handles.last;
      final starting = player.playCue(
        _cue(),
        playbackId: 'pre-return-completion',
      );
      await _flush();
      expect(voice.playCalls, 1);
      voice.completed.add(null);
      voice.playGate!.complete();
      await starting;
      await _flush();
      expect(voice.stopCalls, 1);
      expect(voice.disposeCalls, 1);
      expect(bgmDriver.resumed, [bgm]);
      expect(bgmDriver.volumes[bgm], .8);
      await player.dispose();
      await music.dispose();
    },
  );

  test(
    'real driver retains early completion and all subsequent loop completions',
    () async {
      final voice = _NativeVoice()..playGate = Completer<void>();
      final driver = FlameAudioCinematicRuntimeDriver(
        playerFactory: () => voice,
      );
      final starting = driver.play('original.ogg', volume: .64, loop: false);
      await _flush();
      voice.completed.add(null);
      voice.playGate!.complete();
      final handle = await starting;
      var completions = 0;
      final subscription = driver
          .onComplete(handle)
          .listen((_) => completions += 1);
      await _flush();
      expect(completions, 1);
      voice.completed.add(null);
      voice.completed.add(null);
      await _flush();
      expect(completions, 3);
      await subscription.cancel();
      await driver.stop(handle);
      expect(voice.disposeCalls, 1);
      expect(voice.completed.hasListener, isFalse);
    },
  );

  test('real driver disposes allocated players on release-mode or playback failure', () async {
    for (final stage in ['release-mode', 'play']) {
      final failure = StateError('Original native $stage failure');
      final voice = _NativeVoice();
      if (stage == 'release-mode') {
        voice.modeFailure = failure;
      } else {
        voice.playFailure = failure;
      }
      final driver = FlameAudioCinematicRuntimeDriver(
        playerFactory: () => voice,
      );
      await expectLater(
        driver.play('original.wav', volume: .64, loop: false),
        throwsA(same(failure)),
      );
      expect(voice.disposeCalls, 1);
      expect(voice.completed.hasListener, isFalse);
      await voice.completed.close();
    }
  });

  test(
    'real driver keeps the startup error when player disposal also fails',
    () async {
      final failure = StateError('Original native playback failure');
      final voice = _NativeVoice()
        ..playFailure = failure
        ..disposeFailure = StateError('Original disposal failure');
      final driver = FlameAudioCinematicRuntimeDriver(
        playerFactory: () => voice,
      );
      await expectLater(
        driver.play('original.wav', volume: .64, loop: false),
        throwsA(same(failure)),
      );
      expect(voice.disposeCalls, 1);
      expect(voice.completed.hasListener, isFalse);
      await voice.completed.close();
    },
  );

  test(
    'ordinary effects preserve the effects route and never interrupt BGM',
    () async {
      final driver = _Driver();
      final mixer = RuntimeAudioMixer(
        mix: const RuntimeAudioMix(musicVolume: .4, effectsVolume: .1),
      );
      final music = RuntimeMusicService(
        driver: driver,
        mixer: mixer,
        fadeDelay: (_) async {},
      );
      final player = _player(driver, mixer, music);
      await music.update(route: RuntimeAudioRoute.overworld, path: 'map.ogg');
      await player.playCue(
        DialogueAudioCue(mediaAssetId: 'fanfare', cueId: 'effect', volume: .64),
        playbackId: 'effect',
      );
      final effect = driver.handles.last;
      expect(driver.initialVolumes[effect], closeTo(.064, 1e-12));
      expect(driver.paused, isEmpty);
      driver.complete(effect);
      await _flush();
      expect(driver.resumed, isEmpty);
      await player.dispose();
      await music.dispose();
    },
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

DialogueAudioCue _cue({int fadeOutMs = 0, int fadeInMs = 0}) =>
    DialogueAudioCue(
      mediaAssetId: 'fanfare',
      cueId: 'item',
      volume: .64,
      role: DialogueAudioCueRole.musicEffect,
      bgmInterruption: DialogueBgmInterruption(
        fadeOutMs: fadeOutMs,
        fadeInMs: fadeInMs,
      ),
    );

FlameDialogueFeedbackPlaybackAdapter _player(
  _Driver driver,
  RuntimeAudioMixer mixer,
  RuntimeMusicService music,
) => FlameDialogueFeedbackPlaybackAdapter(
  mediaAssets: [
    CinematicMediaAsset(
      id: 'fanfare',
      label: 'Original fanfare',
      kind: CinematicMediaAssetKind.sound,
      relativePath: 'original.wav',
      durationMs: 1000,
    ),
  ],
  resolvePath: (asset) => asset.relativePath,
  audioDriver: driver,
  mixer: mixer,
  musicService: music,
);

final class _Driver
    implements
        FlameCinematicAudioDriver,
        FlameCinematicAudioLoopDriver,
        FlameCinematicAudioPausableDriver {
  final handles = <Object>[];
  final volumes = <Object, double>{};
  final initialVolumes = <Object, double>{};
  final paused = <Object>[];
  final resumed = <Object>[];
  final stopped = <Object>[];
  final completions = <Object, StreamController<void>>{};
  Completer<Object>? playGate;
  var failNext = false;
  var playCalls = 0;
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    playCalls += 1;
    if (failNext) {
      failNext = false;
      throw StateError('Original playback refusal');
    }
    final handle = Object();
    handles.add(handle);
    volumes[handle] = volume;
    initialVolumes[handle] = volume;
    completions[handle] = StreamController<void>.broadcast(sync: true);
    return playGate?.future ?? handle;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async =>
      volumes[handle] = volume;
  @override
  Future<void> pause(Object handle) async => paused.add(handle);
  @override
  Future<void> resume(Object handle) async => resumed.add(handle);
  @override
  Future<void> stop(Object handle) async => stopped.add(handle);
  @override
  Stream<void> onComplete(Object handle) => completions[handle]!.stream;
  @override
  Future<void> seekAndResume(Object handle, Duration position) async {}
  void complete(Object handle) => completions[handle]!.add(null);
}

final class _NativeVoice implements AudioPlayer {
  final completed = StreamController<void>.broadcast(sync: true);
  Completer<void>? playGate;
  Object? modeFailure;
  Object? playFailure;
  Object? disposeFailure;
  int playCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #onPlayerComplete) return completed.stream;
    if (invocation.memberName == #setReleaseMode) {
      final failure = modeFailure;
      return failure == null
          ? Future<void>.value()
          : Future<void>.error(failure);
    }
    if (invocation.memberName == #play) {
      playCalls += 1;
      final failure = playFailure;
      if (failure != null) return Future<void>.error(failure);
      return playGate?.future ?? Future<void>.value();
    }
    if (invocation.memberName == #stop) {
      stopCalls += 1;
      return Future<void>.value();
    }
    if (invocation.memberName == #dispose) {
      disposeCalls += 1;
      final failure = disposeFailure;
      if (failure != null) return Future<void>.error(failure);
      return completed.close();
    }
    if (invocation.memberName == #setVolume) return Future<void>.value();
    throw UnsupportedError('Unexpected native voice operation');
  }
}
