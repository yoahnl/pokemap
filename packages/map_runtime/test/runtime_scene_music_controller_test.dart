import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/player/runtime_audio_mixer.dart';
import 'package:map_runtime/src/player/runtime_scene_music_controller.dart';

void main() {
  test(
    'play persists, replace retains the first baseline, restore recaptures',
    () async {
      final fixture = _Fixture();
      final music = fixture.music;
      expect(await music.play(path: '/rival.ogg', volume: .7), isTrue);
      expect(music.selection?.path, '/rival.ogg');
      await Future<void>.delayed(Duration.zero);
      expect(music.selection?.path, '/rival.ogg');
      fixture.baseline = (
        route: RuntimeAudioRoute.overworld,
        path: '/next.ogg',
        volume: .5,
      );
      await music.play(path: '/second.ogg', volume: .9);
      await music.restore();
      expect(music.selection?.path, '/map.ogg');
      expect(fixture.captures, 1);
      await music.play(path: '/third.ogg', volume: .6);
      await music.restore();
      expect(music.selection?.path, '/next.ogg');
      expect(fixture.captures, 2);
      await music.close();
      expect(music.selection, isNull);
    },
  );

  test(
    'fade is scheduled without blocking and close cancels all owned callbacks',
    () async {
      final fixture = _Fixture();
      await fixture.music.play(path: '/rival.ogg', volume: .8);
      expect(
        await fixture.music.fadeOut(duration: const Duration(seconds: 2)),
        isTrue,
      );
      expect(fixture.timers.single.isActive, isTrue);
      expect(fixture.music.selection?.volume, .8);
      fixture.timers.single.fire();
      await Future<void>.delayed(Duration.zero);
      expect(fixture.music.selection?.volume, closeTo(.6, .001));
      final pending = fixture.timers.last;
      await fixture.music.close();
      expect(pending.isActive, isFalse);
      final count = fixture.published.length;
      pending.fireEvenIfCancelled();
      await Future<void>.delayed(Duration.zero);
      expect(fixture.published.length, count);
      expect(fixture.music.selection, isNull);
    },
  );

  test('fade reaches silence and restore stops an obsolete fade', () async {
    final fixture = _Fixture();
    await fixture.music.play(path: '/rival.ogg', volume: .8);
    await fixture.music.fadeOut(duration: const Duration(milliseconds: 400));
    for (var i = 0; i < 4; i++) {
      fixture.timers.last.fire();
      await Future<void>.delayed(Duration.zero);
    }
    expect(fixture.music.selection?.volume, 0);
    expect(fixture.timers.where((timer) => timer.isActive), isEmpty);
    await fixture.music.restore();
    expect(fixture.music.selection?.path, '/map.ogg');
    await fixture.music.play(path: '/rival.ogg', volume: .8);
    await fixture.music.fadeOut(duration: const Duration(seconds: 2));
    final stale = fixture.timers.last;
    await fixture.music.restore();
    stale.fireEvenIfCancelled();
    await Future<void>.delayed(Duration.zero);
    expect(fixture.music.selection?.path, '/map.ogg');
    expect(fixture.music.selection?.volume, .4);
    await fixture.music.close();
  });

  test(
    'stale owner and pending starts cannot publish into a newer transaction',
    () async {
      final fixture = _Fixture();
      final release = Completer<void>();
      fixture.barrier = release.future;
      final started = fixture.music.play(path: '/rival.ogg', volume: .8);
      await Future<void>.delayed(Duration.zero);
      fixture.current = Object();
      release.complete();
      expect(await started, isFalse);
      final count = fixture.published.length;
      expect(await fixture.music.play(path: '/late.ogg', volume: 1), isFalse);
      expect(await fixture.music.restore(), isFalse);
      expect(await fixture.music.fadeOut(duration: Duration.zero), isFalse);
      await fixture.music.close();
      expect(fixture.published.length, count);
    },
  );

  test(
    'failed start restores the preceding selection without losing ownership',
    () async {
      final fixture = _Fixture();
      await fixture.music.play(path: '/first.ogg', volume: .8);
      fixture.failure = StateError('Driver failed');
      await expectLater(
        fixture.music.play(path: '/broken.ogg', volume: .9),
        throwsStateError,
      );
      expect(fixture.music.selection?.path, '/first.ogg');
      expect(fixture.music.lastFailure, isA<StateError>());
      await fixture.music.restore();
      expect(fixture.music.selection?.path, '/map.ogg');
      expect(fixture.music.lastFailure, isNull);
      await fixture.music.close();
    },
  );

  test(
    'fade without play captures map ambience and restore releases it',
    () async {
      final fixture = _Fixture();
      expect(await fixture.music.fadeOut(duration: Duration.zero), isTrue);
      expect(fixture.music.selection?.path, '/map.ogg');
      expect(fixture.music.selection?.volume, 0);
      await fixture.music.restore();
      expect(fixture.music.selection?.volume, .4);
      expect(fixture.captures, 1);
      await fixture.music.close();
    },
  );

  test(
    'close observes an already pending fade failure before returning',
    () async {
      final fixture = _Fixture();
      await fixture.music.play(path: '/rival.ogg', volume: .8);
      final release = Completer<void>();
      fixture.barrier = release.future;
      await fixture.music.fadeOut(duration: const Duration(seconds: 2));
      fixture.timers.single.fire();
      await Future<void>.delayed(Duration.zero);
      fixture.afterBarrierFailure = StateError('Late fade error');
      final closed = fixture.music.close();
      release.complete();
      await closed;
      await Future<void>.delayed(Duration.zero);
      expect(fixture.music.lastFailure, isA<StateError>());
      expect(fixture.music.transactionFailure, isA<StateError>());
      expect(fixture.music.selection, isNull);
    },
  );

  test('zero fade applies once and refuses invalid arguments', () async {
    final fixture = _Fixture();
    await expectLater(
      fixture.music.play(path: '', volume: .5),
      throwsArgumentError,
    );
    await expectLater(
      fixture.music.play(path: '/a', volume: double.nan),
      throwsArgumentError,
    );
    await fixture.music.play(path: '/rival.ogg', volume: .8);
    await expectLater(
      fixture.music.fadeOut(duration: const Duration(milliseconds: -1)),
      throwsRangeError,
    );
    await fixture.music.fadeOut(duration: Duration.zero);
    expect(fixture.music.selection?.volume, 0);
    expect(fixture.timers, isEmpty);
    await fixture.music.close();
  });
}

final class _Fixture {
  _Fixture() {
    current = owner;
    music = RuntimeSceneMusicController(
      owner: owner,
      isOwnerCurrent: (candidate) => identical(candidate, current),
      captureBaseline: () {
        captures++;
        return baseline;
      },
      onChanged: () async {
        published.add(music.selection);
        final nextFailure = failure;
        failure = null;
        if (nextFailure != null) throw nextFailure;
        await barrier;
        final lateFailure = afterBarrierFailure;
        afterBarrierFailure = null;
        if (lateFailure != null) throw lateFailure;
      },
      fadeSteps: 4,
      timerFactory: (delay, callback) {
        final timer = _ManualTimer(callback);
        timers.add(timer);
        return timer;
      },
    );
  }
  final owner = Object();
  late Object current;
  late RuntimeSceneMusicController music;
  RuntimeSceneMusicSelection baseline = (
    route: RuntimeAudioRoute.overworld,
    path: '/map.ogg',
    volume: .4,
  );
  final published = <RuntimeSceneMusicSelection?>[];
  final timers = <_ManualTimer>[];
  int captures = 0;
  Object? failure;
  Object? afterBarrierFailure;
  Future<void>? barrier;
}

final class _ManualTimer implements Timer {
  _ManualTimer(this.callback);
  final void Function() callback;
  bool _active = true;
  int _tick = 0;
  @override
  bool get isActive => _active;
  @override
  int get tick => _tick;
  @override
  void cancel() => _active = false;
  void fire() {
    if (!_active) return;
    _active = false;
    _tick++;
    callback();
  }

  void fireEvenIfCancelled() => callback();
}
