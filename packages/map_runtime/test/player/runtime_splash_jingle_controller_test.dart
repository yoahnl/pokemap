import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ships the premium splash jingle in the runtime bundle', () async {
    final data = await rootBundle.load(
      'packages/map_runtime/assets/audio/$runtimePremiumSplashJingleAsset',
    );

    expect(data.lengthInBytes, greaterThan(100000));
  });

  test('plays the runtime splash jingle once through the music bus', () async {
    final driver = _FakeAudioDriver();
    final mixer = RuntimeAudioMixer(
      mix: const RuntimeAudioMix(
        masterVolume: 0.5,
        musicVolume: 0.4,
        effectsVolume: 0.2,
      ),
    );
    final controller = RuntimeSplashJingleController(
      driver: driver,
      mixer: mixer,
    );

    await controller.playOnce();
    await controller.playOnce();

    expect(driver.played, <String>[runtimePremiumSplashJingleAsset]);
    expect(driver.looping, isFalse);
    expect(driver.playVolumes, <double>[0.12]);
    expect(controller.hasPlayed, isTrue);

    await mixer.transitionTo(
      const RuntimeAudioMix(
        masterVolume: 0.8,
        musicVolume: 0.5,
        effectsVolume: 0.1,
      ),
    );
    expect(driver.updatedVolumes.last, 0.24);

    await controller.dispose();
    expect(driver.stopCount, 1);
  });

  test('lifecycle pause stops the jingle without replaying it on resume',
      () async {
    final driver = _FakeAudioDriver();
    final controller = RuntimeSplashJingleController(driver: driver);

    await controller.playOnce();
    await controller.pauseForLifecycle();
    await controller.resumeFromLifecycle();
    await controller.playOnce();

    expect(driver.played, hasLength(1));
    expect(driver.stopCount, 1);
    expect(controller.isPlaying, isFalse);
  });

  test('playback failure is non-blocking and is never retried implicitly',
      () async {
    final driver = _FakeAudioDriver(failPlayback: true);
    final controller = RuntimeSplashJingleController(driver: driver);

    await controller.playOnce();
    await controller.playOnce();

    expect(driver.played, hasLength(1));
    expect(controller.lastFailure, isA<StateError>());
    expect(controller.isPlaying, isFalse);
  });
}

final class _FakeAudioDriver implements FlameCinematicAudioDriver {
  _FakeAudioDriver({this.failPlayback = false});

  final bool failPlayback;
  final List<String> played = <String>[];
  final List<double> playVolumes = <double>[];
  final List<double> updatedVolumes = <double>[];
  int stopCount = 0;
  bool looping = false;

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    played.add(path);
    playVolumes.add(volume);
    looping = loop;
    if (failPlayback) throw StateError('decoder unavailable');
    return Object();
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {
    updatedVolumes.add(volume);
  }

  @override
  Future<void> stop(Object handle) async {
    stopCount++;
  }
}
