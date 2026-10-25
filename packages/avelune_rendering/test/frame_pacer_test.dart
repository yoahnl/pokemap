import 'dart:math' as math;

import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final refreshRate in [60, 120]) {
    for (final limit in [30, 45, 60, 90, 120]) {
      test('$limit FPS keeps its absolute cadence on $refreshRate Hz', () {
        final frames = _simulate(limit: limit, refreshRate: refreshRate);
        expect(frames.length, closeTo(math.min(limit, refreshRate) * 10, 1));
        expect(frames.toSet().length, frames.length);
        expect(frames.first, Duration.zero);
      });
    }
  }

  test('45 FPS on 60 Hz distributes work across one and two vsync gaps', () {
    final frames = _simulate(limit: 45, refreshRate: 60);
    final gaps = {
      for (var index = 1; index < frames.length; index++)
        ((frames[index] - frames[index - 1]).inMicroseconds / (1000000 / 60))
            .round(),
    };
    expect(gaps, {1, 2});
  });

  test('90 FPS on 120 Hz distributes work across one and two vsync gaps', () {
    final frames = _simulate(limit: 90, refreshRate: 120);
    final gaps = {
      for (var index = 1; index < frames.length; index++)
        ((frames[index] - frames[index - 1]).inMicroseconds / (1000000 / 120))
            .round(),
    };
    expect(gaps, {1, 2});
  });

  test('a late frame advances directly to a future deadline', () {
    final pacer = AveluneFramePacer(limit: 30);
    pacer.frameStarted(Duration.zero);
    pacer.frameStarted(const Duration(seconds: 8));
    expect(
      pacer.delay(const Duration(seconds: 8)),
      const Duration(microseconds: 33333),
    );
  });

  test('changing the limit uses the last frame without replaying time', () {
    final pacer = AveluneFramePacer(limit: 30);
    pacer.frameStarted(Duration.zero);
    pacer.setLimit(120);
    expect(
      pacer.delay(const Duration(milliseconds: 2)),
      const Duration(microseconds: 6333),
    );
    pacer.setLimit(45);
    expect(
      pacer.delay(const Duration(milliseconds: 2)),
      const Duration(microseconds: 20222),
    );
  });

  test('reset makes the next requested frame immediately available', () {
    final pacer = AveluneFramePacer(limit: 30);
    pacer.frameStarted(Duration.zero);
    pacer.reset();
    expect(pacer.delay(const Duration(seconds: 10)), Duration.zero);
    pacer.frameStarted(const Duration(seconds: 10));
    expect(
      pacer.delay(const Duration(seconds: 10)),
      const Duration(microseconds: 33333),
    );
  });
}

List<Duration> _simulate({required int limit, required int refreshRate}) {
  final pacer = AveluneFramePacer(limit: limit);
  final frames = <Duration>[Duration.zero];
  pacer.frameStarted(Duration.zero);
  var tick = 0;
  while (true) {
    final requested = frames.last + pacer.delay(frames.last);
    var nextTick = math.max(
      tick + 1,
      (requested.inMicroseconds * refreshRate / 1000000).floor(),
    );
    while ((nextTick * 1000000 / refreshRate).round() <
        requested.inMicroseconds) {
      nextTick++;
    }
    final frame = Duration(
      microseconds: (nextTick * 1000000 / refreshRate).round(),
    );
    if (frame >= const Duration(seconds: 10)) return frames;
    frames.add(frame);
    pacer.frameStarted(frame);
    tick = nextTick;
  }
}
