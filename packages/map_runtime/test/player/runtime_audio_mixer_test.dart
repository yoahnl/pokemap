import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('routes every runtime identity through the expected audio bus', () {
    const mix = RuntimeAudioMix(
      masterVolume: 0.5,
      musicVolume: 0.4,
      effectsVolume: 0.2,
    );

    expect(mix.volumeFor(RuntimeAudioRoute.splash, sourceVolume: 0.5), 0.1);
    expect(mix.volumeFor(RuntimeAudioRoute.title, sourceVolume: 0.5), 0.1);
    expect(mix.volumeFor(RuntimeAudioRoute.overworld), 0.2);
    expect(mix.volumeFor(RuntimeAudioRoute.battle), 0.2);
    expect(mix.volumeFor(RuntimeAudioRoute.cinematicMusic), 0.2);
    expect(mix.volumeFor(RuntimeAudioRoute.cinematicEffects), 0.1);
  });

  test('mix transitions update every registered bus and preserve source volume',
      () async {
    final mixer = RuntimeAudioMixer(
      mix: const RuntimeAudioMix(
        masterVolume: 0.8,
        musicVolume: 0.5,
        effectsVolume: 0.25,
      ),
    );
    final musicVolumes = <double>[];
    final effectsVolumes = <double>[];

    await mixer.register(
      channel: 'overworld',
      route: RuntimeAudioRoute.overworld,
      sourceVolume: 0.5,
      setVolume: (volume) async => musicVolumes.add(volume),
    );
    await mixer.register(
      channel: 'effects',
      route: RuntimeAudioRoute.cinematicEffects,
      setVolume: (volume) async => effectsVolumes.add(volume),
    );

    expect(musicVolumes, [0.2]);
    expect(effectsVolumes, [0.2]);

    await mixer.transitionTo(
      const RuntimeAudioMix(
        masterVolume: 0.5,
        musicVolume: 0.4,
        effectsVolume: 0.8,
      ),
    );

    expect(musicVolumes, [0.2, 0.1]);
    expect(effectsVolumes, [0.2, 0.4]);

    await mixer.updateSourceVolume('overworld', 0.25);
    expect(musicVolumes, [0.2, 0.1, 0.05]);

    mixer.unregister('effects');
    await mixer.transitionTo(const RuntimeAudioMix());
    expect(effectsVolumes, [0.2, 0.4]);
  });

  test('invalid persisted mix values are rejected', () {
    expect(
      () => RuntimeAudioMix(masterVolume: double.nan),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => RuntimeAudioMix(effectsVolume: 1.1),
      throwsA(isA<AssertionError>()),
    );
  });

  test('ducking is deterministic across owners and updates only its bus',
      () async {
    final mixer = RuntimeAudioMixer();
    final musicVolumes = <double>[];
    final effectsVolumes = <double>[];

    await mixer.register(
      channel: 'music',
      route: RuntimeAudioRoute.cinematicMusic,
      setVolume: (volume) async => musicVolumes.add(volume),
    );
    await mixer.register(
      channel: 'effects',
      route: RuntimeAudioRoute.cinematicEffects,
      setVolume: (volume) async => effectsVolumes.add(volume),
    );

    await mixer.setDucking(
      owner: 'voice-a',
      bus: RuntimeAudioBus.music,
      gain: 0.4,
    );
    await mixer.setDucking(
      owner: 'voice-b',
      bus: RuntimeAudioBus.music,
      gain: 0.6,
    );
    await mixer.clearDucking('voice-a');
    await mixer.clearDucking('voice-b');

    expect(musicVolumes, [1, 0.4, 0.4, 0.6, 1]);
    expect(effectsVolumes, [1]);
  });

  test('failed initial volume application does not retain the channel',
      () async {
    final mixer = RuntimeAudioMixer();
    var calls = 0;

    await expectLater(
      mixer.register(
        channel: 'broken',
        route: RuntimeAudioRoute.cinematicMusic,
        setVolume: (_) async {
          calls++;
          throw StateError('decoder rejected volume');
        },
      ),
      throwsStateError,
    );

    await mixer.transitionTo(const RuntimeAudioMix(masterVolume: 0.5));

    expect(calls, 1);
  });
}
