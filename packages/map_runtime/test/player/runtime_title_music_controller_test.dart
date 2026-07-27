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
}

final class _FakeAudioDriver implements FlameCinematicAudioDriver {
  _FakeAudioDriver({this.failPlayback = false});

  final bool failPlayback;
  final List<String> played = <String>[];
  var stopCount = 0;
  var looping = false;

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    played.add(path);
    looping = loop;
    if (failPlayback) throw StateError('decoder unavailable');
    return Object();
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async {
    stopCount += 1;
  }
}
