import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';

void main() {
  test(
    'one-shot title music emits once and ignores stale completion after stop',
    () async {
      final driver = _CompletionAudioDriver();
      final controller = RuntimeTitleMusicController(driver: driver);
      var completions = 0;
      controller.completions.listen((_) => completions++);
      await controller.update(
        path: '/title.ogg',
        titleVisible: true,
        endBehavior: ProjectTitleMusicEndBehavior.replayIntro,
      );
      expect(driver.looping, isFalse);
      driver.events.add(null);
      driver.events.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(completions, 1);
      await controller.update(
        path: '/title.ogg',
        titleVisible: true,
        endBehavior: ProjectTitleMusicEndBehavior.replayIntro,
      );
      expect(driver.played, hasLength(1));
      await controller.update(path: null, titleVisible: false);
      driver.events.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(completions, 1);
      await controller.dispose();
      driver.events.add(null);
      await driver.events.close();
    },
  );

  test('pausable title music resumes the same handle and defers background completion', () async {
    final driver = _CompletionAudioDriver();
    final controller = RuntimeTitleMusicController(driver: driver);
    var completions = 0;
    controller.completions.listen((_) => completions++);
    await controller.update(
      path: '/title.ogg',
      titleVisible: true,
      endBehavior: ProjectTitleMusicEndBehavior.replayIntro,
    );
    await controller.pauseForLifecycle();
    expect(driver.pauseCount, 1);
    expect(driver.stopCount, 0);
    await controller.resumeFromLifecycle();
    expect(driver.resumeCount, 1);
    expect(driver.played, hasLength(1));
    await controller.pauseForLifecycle();
    driver.events.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(completions, 0);
    await controller.resumeFromLifecycle();
    await Future<void>.delayed(Duration.zero);
    expect(completions, 1);
    expect(driver.played, hasLength(1));
    await controller.dispose();
    await driver.events.close();
  });

  test(
    'a changed title policy cancels completion while stopping audio',
    () async {
      final gate = Completer<void>();
      final driver = _CompletionAudioDriver(stopGate: gate);
      final controller = RuntimeTitleMusicController(driver: driver);
      var completions = 0;
      controller.completions.listen((_) => completions++);
      await controller.update(
        path: '/title.ogg',
        titleVisible: true,
        endBehavior: ProjectTitleMusicEndBehavior.replayIntro,
      );
      driver.events.add(null);
      await Future<void>.delayed(Duration.zero);
      final update = controller.update(path: '/title.ogg', titleVisible: true);
      gate.complete();
      await update;
      await Future<void>.delayed(Duration.zero);
      expect(completions, 0);
      expect(driver.looping, isTrue);
      await controller.dispose();
      await driver.events.close();
    },
  );

  test(
    'a changed policy invalidates completion before its queue begins',
    () async {
      final driver = _CompletionAudioDriver();
      final controller = RuntimeTitleMusicController(driver: driver);
      var completions = 0;
      controller.completions.listen((_) => completions++);
      await controller.update(
        path: '/title.ogg',
        titleVisible: true,
        endBehavior: ProjectTitleMusicEndBehavior.replayIntro,
      );
      driver.events.add(null);
      await controller.update(path: '/title.ogg', titleVisible: true);
      await Future<void>.delayed(Duration.zero);
      expect(completions, 0);
      expect(driver.looping, isTrue);
      await controller.dispose();
      await driver.events.close();
    },
  );

  test(
    'title music follows title visibility and lifecycle without trapping',
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
    },
  );

  test('missing or failing optional music keeps the title usable', () async {
    final driver = _FakeAudioDriver(failPlayback: true);
    final controller = RuntimeTitleMusicController(driver: driver);

    await controller.update(path: null, titleVisible: true);
    expect(driver.played, isEmpty);

    await controller.update(path: '/broken.ogg', titleVisible: true);
    expect(controller.lastFailure, isA<StateError>());
    expect(controller.isPlaying, isFalse);
    await controller.update(path: '/broken.ogg', titleVisible: true);
    await controller.resumeFromLifecycle();
    expect(driver.played, ['/broken.ogg']);
    await controller.dispose();
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

  test('a stale completion error cannot suppress replacement music', () async {
    final driver = _CompletionAudioDriver();
    final controller = RuntimeTitleMusicController(driver: driver);
    await controller.update(path: '/old.ogg', titleVisible: true, endBehavior: ProjectTitleMusicEndBehavior.replayIntro);
    driver.events.addError(StateError('old decoder failed'));
    await controller.update(path: '/replacement.ogg', titleVisible: true);
    expect(controller.lastFailure, isNull);
    expect(driver.played, ['/old.ogg', '/replacement.ogg']);
    expect(controller.isPlaying, isTrue);
    await controller.dispose();
    await driver.events.close();
  });

  test('an obsolete title request never starts after a gated stop', () async {
    final gate = Completer<void>();
    final driver = _CompletionAudioDriver(stopGate: gate);
    final controller = RuntimeTitleMusicController(driver: driver);
    await controller.update(path: '/initial.ogg', titleVisible: true);
    final obsolete = controller.update(path: '/obsolete.ogg', titleVisible: true);
    await Future<void>.delayed(Duration.zero);
    final current = controller.update(path: '/current.ogg', titleVisible: true);
    gate.complete();
    await obsolete;
    await current;
    expect(driver.played, ['/initial.ogg', '/current.ogg']);
    await controller.dispose();
    await driver.events.close();
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

class _FakeAudioDriver implements FlameCinematicAudioDriver {
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

final class _CompletionAudioDriver extends _FakeAudioDriver
    implements
        FlameCinematicAudioLoopDriver,
        FlameCinematicAudioPausableDriver {
  _CompletionAudioDriver({super.stopGate});
  final events = StreamController<void>.broadcast(sync: true);
  int pauseCount = 0;
  int resumeCount = 0;
  @override
  Stream<void> onComplete(Object handle) => events.stream;
  @override
  Future<void> pause(Object handle) async {
    pauseCount++;
  }

  @override
  Future<void> resume(Object handle) async {
    resumeCount++;
  }

  @override
  Future<void> seekAndResume(Object handle, Duration position) async {}
}
