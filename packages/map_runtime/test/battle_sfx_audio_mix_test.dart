import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_sfx_player.dart';

void main() {
  test('accelerated battle effects bound live voices without changing pitch', () async {
    final voices = <_Voice>[];
    final player = FlameAudioBattleSfxPlayer(
      manifest: const {'hit': 'hit.wav'},
      maxConcurrentVoices: 4,
      playerFactory: () { final voice = _Voice(); voices.add(voice); return voice; },
    );
    addTearDown(player.dispose);
    for (var i = 0; i < 50; i++) {
      player.play('hit', volume: 100, pitch: 100);
      player.playProjectFile('/project/cry.ogg');
    }
    await Future<void>.delayed(Duration.zero);
    expect(player.livePlayerCount, 4);
    expect(voices, hasLength(4));
    expect(voices.every((voice) => voice.rates.isEmpty), isTrue);
    voices.first.complete.add(null);
    await Future<void>.delayed(Duration.zero);
    player.play('hit', volume: 100, pitch: 100);
    await Future<void>.delayed(Duration.zero);
    expect(voices, hasLength(5));
    expect(player.livePlayerCount, 4);
    player.maxConcurrentVoices = null;
    player.play('hit', volume: 100, pitch: 100);
    expect(player.livePlayerCount, 5);
  });

  test('effects and cries use the mix and update active voices without replay',
      () async {
    final mixer = RuntimeAudioMixer(
      mix: const RuntimeAudioMix(masterVolume: 0.5, effectsVolume: 0.4),
    );
    final voices = <_Voice>[];
    final player = FlameAudioBattleSfxPlayer(
      mixer: mixer,
      manifest: const {'hit': 'hit.wav'},
      playerFactory: () {
        final voice = _Voice();
        voices.add(voice);
        return voice;
      },
    );
    addTearDown(player.dispose);
    player.play('hit', volume: 50, pitch: 100);
    player.playProjectFile('/project/cry.ogg');
    await Future<void>.delayed(Duration.zero);
    expect(voices, hasLength(2));
    expect(voices[0].playVolumes, [0.1]);
    expect(voices[1].playVolumes, [0.2]);
    await mixer.transitionTo(const RuntimeAudioMix(masterVolume: 0));
    expect(voices.map((voice) => voice.volumes.last), everyElement(0));
    expect(voices.map((voice) => voice.playVolumes.length), everyElement(1));
    await player.dispose();
    final writes = voices.map((voice) => voice.volumes.length).toList();
    await mixer.transitionTo(const RuntimeAudioMix());
    expect(voices.map((voice) => voice.volumes.length), writes);
    expect(player.livePlayerCount, 0);
  });
}

final class _Voice implements AudioPlayer {
  final complete = StreamController<void>.broadcast();
  final playVolumes = <double?>[];
  final volumes = <double>[];
  final rates = <double>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #onPlayerComplete) return complete.stream;
    if (invocation.isSetter) return null;
    if (invocation.memberName == #play) {
      playVolumes.add(invocation.namedArguments[#volume] as double?);
    }
    if (invocation.memberName == #setPlaybackRate) {
      rates.add(invocation.positionalArguments.single as double);
    }
    if (invocation.memberName == #setVolume) {
      volumes.add(invocation.positionalArguments.single as double);
    }
    if (invocation.memberName == #dispose) return complete.close();
    return Future<void>.value();
  }
}
