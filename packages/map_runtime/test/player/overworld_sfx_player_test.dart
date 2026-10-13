import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'jump uses its embedded asset and effects volume with one reusable voice',
    () async {
      final mixer = RuntimeAudioMixer(
        mix: const RuntimeAudioMix(
          masterVolume: .5,
          musicVolume: 0,
          effectsVolume: .4,
        ),
      );
      final voice = _Voice();
      var created = 0;
      final player = FlameAudioOverworldSfxPlayer(
        mixer: mixer,
        playerFactory: () {
          created++;
          return voice;
        },
      );
      await player.playJump();
      await player.playJump();
      expect(created, 1);
      expect(
        voice.sources,
        everyElement(
          isA<AssetSource>().having(
            (source) => source.path,
            'path',
            FlameAudioOverworldSfxPlayer.jumpAsset,
          ),
        ),
      );
      expect(voice.effectivePlayVolumes, [.2, .2]);
      await mixer.transitionTo(const RuntimeAudioMix(masterVolume: 0));
      expect(voice.volumes.last, 0);
      await player.dispose();
      expect(voice.stops, 1);
      expect(voice.disposals, 1);
      final writes = voice.volumes.length;
      await mixer.transitionTo(const RuntimeAudioMix());
      await player.playJump();
      await player.dispose();
      expect(voice.volumes, hasLength(writes));
      expect(voice.sources, hasLength(2));
    },
  );

  test('disposal during player preparation prevents stale playback', () async {
    final release = Completer<void>();
    final voice = _Voice(prepareRelease: release.future);
    final player = FlameAudioOverworldSfxPlayer(playerFactory: () => voice);
    final playback = player.playJump();
    await player.dispose();
    release.complete();
    await playback;
    expect(voice.sources, isEmpty);
    expect(voice.disposals, 1);
  });

  test(
    'effects ducking already active also applies to the first jump',
    () async {
      final mixer = RuntimeAudioMixer(
        mix: const RuntimeAudioMix(masterVolume: .5, effectsVolume: .4),
      );
      await mixer.setDucking(
        owner: 'muted-effects',
        bus: RuntimeAudioBus.effects,
        gain: 0,
      );
      final voice = _Voice();
      final player = FlameAudioOverworldSfxPlayer(
        mixer: mixer,
        playerFactory: () => voice,
      );
      await player.playJump();
      expect(voice.effectivePlayVolumes, [0]);
      await player.dispose();
    },
  );

  test('failed stop and dispose cannot escape runtime teardown', () async {
    final mixer = RuntimeAudioMixer();
    final voice = _Voice(failStop: true, failDispose: true);
    final player = FlameAudioOverworldSfxPlayer(
      mixer: mixer,
      playerFactory: () => voice,
    );
    await player.playJump();
    await expectLater(player.dispose(), completes);
    final writes = voice.volumes.length;
    await mixer.transitionTo(const RuntimeAudioMix(masterVolume: 0));
    expect(voice.volumes, hasLength(writes));
    expect(voice.stops, 1);
    expect(voice.disposals, 1);
  });

  test(
    'missing audio device is contained without interrupting gameplay',
    () async {
      final voice = _Voice(failPlayback: true);
      final player = FlameAudioOverworldSfxPlayer(playerFactory: () => voice);
      await player.playJump();
      await player.dispose();
      expect(voice.disposals, 1);
    },
  );

  test('jump WAV is included in the runtime asset bundle', () async {
    final bytes = await rootBundle.load(FlameAudioOverworldSfxPlayer.jumpAsset);
    expect(bytes.lengthInBytes, 29612);
    expect(String.fromCharCodes(bytes.buffer.asUint8List(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.buffer.asUint8List(8, 4)), 'WAVE');
  });
}

final class _Voice implements AudioPlayer {
  _Voice({
    this.prepareRelease,
    this.failPlayback = false,
    this.failStop = false,
    this.failDispose = false,
  });

  final Future<void>? prepareRelease;
  final bool failPlayback;
  final bool failStop;
  final bool failDispose;
  final sources = <Source>[];
  final playVolumes = <double?>[];
  final volumes = <double>[];
  final effectivePlayVolumes = <double>[];
  double currentVolume = 1;
  int stops = 0;
  int disposals = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isSetter) return null;
    if (invocation.memberName == #setReleaseMode) {
      return prepareRelease ?? Future<void>.value();
    }
    if (invocation.memberName == #play) {
      if (failPlayback) throw StateError('No audio device');
      sources.add(invocation.positionalArguments.single as Source);
      playVolumes.add(invocation.namedArguments[#volume] as double?);
      effectivePlayVolumes.add(
        invocation.namedArguments[#volume] as double? ?? currentVolume,
      );
    }
    if (invocation.memberName == #setVolume) {
      volumes.add(invocation.positionalArguments.single as double);
      currentVolume = invocation.positionalArguments.single as double;
    }
    if (invocation.memberName == #stop) {
      stops++;
      if (failStop) throw StateError('Audio backend already closed');
    }
    if (invocation.memberName == #dispose) {
      disposals++;
      if (failDispose) throw StateError('Audio backend disposal failed');
    }
    return Future<void>.value();
  }
}
