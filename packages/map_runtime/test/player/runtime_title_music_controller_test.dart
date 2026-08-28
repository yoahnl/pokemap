import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('title music follows title visibility and lifecycle without trapping',
      () async {
    final driver = _FakeAudioDriver();
    final controller = RuntimeTitleMusicController(driver: driver);

    await controller.update(
      path: '/installed/project/assets/title.ogg',
      titleVisible: true,
      volume: 0.7,
    );
    expect(driver.played, <String>['/installed/project/assets/title.ogg']);
    expect(driver.looping, isTrue);

    await controller.pauseForLifecycle();
    expect(driver.stopCount, 1);

    await controller.resumeFromLifecycle();
    expect(driver.played, hasLength(2));

    await controller.update(
      path: '/installed/project/assets/title.ogg',
      titleVisible: false,
    );
    expect(driver.stopCount, 2);

    await controller.dispose();
  });

  test('missing or failing optional music keeps the title usable', () async {
    final driver = _FakeAudioDriver(failPlayback: true);
    final controller = RuntimeTitleMusicController(driver: driver);

    await controller.update(path: null, titleVisible: true);
    expect(driver.played, isEmpty);

    await controller.update(path: '/broken.ogg', titleVisible: true);
    expect(controller.lastFailure, isA<StateError>());
    expect(controller.isPlaying, isFalse);
  });

  test('a stuck audio stop never traps the title transition', () async {
    final stopGate = Completer<void>();
    final driver = _FakeAudioDriver(stopGate: stopGate);
    final controller = RuntimeTitleMusicController(
      driver: driver,
      stopTimeout: const Duration(milliseconds: 10),
    );

    await controller.update(path: '/title.ogg', titleVisible: true);
    await controller
        .update(path: null, titleVisible: false)
        .timeout(const Duration(milliseconds: 100));

    expect(driver.stopCount, 1);
    expect(controller.isPlaying, isFalse);
    expect(controller.lastFailure, isA<TimeoutException>());
  });

  test('title music follows live master and music bus transitions', () async {
    final driver = _FakeAudioDriver();
    final mixer = RuntimeAudioMixer(
      mix: const RuntimeAudioMix(
        masterVolume: 0.5,
        musicVolume: 0.4,
        effectsVolume: 0.2,
      ),
    );
    final controller = RuntimeTitleMusicController(
      driver: driver,
      mixer: mixer,
    );

    await controller.update(
      path: '/installed/project/assets/title.ogg',
      titleVisible: true,
      volume: 0.5,
    );
    expect(driver.playVolumes, [0.1]);

    await mixer.transitionTo(
      const RuntimeAudioMix(
        masterVolume: 0.8,
        musicVolume: 0.5,
        effectsVolume: 0.1,
      ),
    );
    expect(driver.updatedVolumes.last, 0.2);

    await controller.dispose();
  });
}

final class _FakeAudioDriver implements FlameCinematicAudioDriver {
  _FakeAudioDriver({this.failPlayback = false, this.stopGate});

  final bool failPlayback;
  final Completer<void>? stopGate;
  final List<String> played = <String>[];
  final List<double> playVolumes = <double>[];
  final List<double> updatedVolumes = <double>[];
  var stopCount = 0;
  var looping = false;

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
    stopCount += 1;
    await stopGate?.future;
  }
}
