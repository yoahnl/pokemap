import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _VsyncTestBinding extends AutomatedTestWidgetsFlutterBinding
    with AveluneFrameRateBinding {
  _VsyncTestBinding() {
    addPersistentFrameCallback((_) {
      drawnFrames++;
      observeDraw?.call();
    });
  }

  Duration Function()? arrivalClock;
  VoidCallback? observeDraw;
  int drawnFrames = 0;

  Duration get framePacingElapsed => arrivalClock?.call() ?? Duration.zero;

  void lifecycle(AppLifecycleState state) =>
      handleAppLifecycleStateChanged(state);
}

void main() {
  final binding = _VsyncTestBinding();
  setUp(() {
    binding.lifecycle(AppLifecycleState.paused);
    AveluneFrameRate.setLimit(60);
    binding.lifecycle(AppLifecycleState.resumed);
  });
  tearDown(() {
    binding.lifecycle(AppLifecycleState.paused);
    binding.arrivalClock = null;
    binding.observeDraw = null;
    AveluneFrameRate.setLimit(60);
  });

  Future<void> verifyRate(
    WidgetTester tester,
    int limit,
    int refresh,
    int latencyUs,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final origin = binding.currentSystemFrameTimeStamp;
    final ticks = <Duration>[];
    final delivered = <Duration>[];
    final ticker = Ticker(ticks.add);
    final before = binding.drawnFrames;
    fakeAsync((clock) {
      binding.arrivalClock = () => clock.elapsed;
      binding.lifecycle(AppLifecycleState.paused);
      AveluneFrameRate.setLimit(limit);
      binding.lifecycle(AppLifecycleState.resumed);
      ticker.start();
      for (var index = 0; index < refresh * 2; index++) {
        final physical = Duration(
          microseconds: (index * 1000000 / refresh).round(),
        );
        clock.elapse(physical - clock.elapsed);
        final pending = binding.hasScheduledFrame;
        clock.elapse(Duration(microseconds: latencyUs));
        if (!pending) continue;
        final count = ticks.length;
        binding.handleBeginFrame(origin + physical);
        clock.flushMicrotasks();
        binding.handleDrawFrame();
        clock.flushMicrotasks();
        if (ticks.length != count) delivered.add(physical);
      }
      ticker.dispose();
      binding.lifecycle(AppLifecycleState.paused);
    });
    final expected = (limit < refresh ? limit : refresh) * 2;
    expect(ticks.length, closeTo(expected, 1));
    expect(binding.drawnFrames - before, ticks.length);
    expect(ticks.first, Duration.zero);
    expect(ticks.last - ticks.first, delivered.last - delivered.first);
    binding.arrivalClock = null;
    await tester.pump();
  }

  for (final refresh in [60, 120]) {
    for (final limit in AveluneFrameRate.supportedLimits) {
      for (final latencyUs in [250, 2000]) {
        testWidgets(
          '$limit FPS on $refresh Hz with ${latencyUs}us CPU delivery latency',
          (tester) => verifyRate(tester, limit, refresh, latencyUs),
        );
      }
    }
  }

  void frame(Duration timestamp) {
    binding.handleBeginFrame(timestamp);
    binding.handleDrawFrame();
  }

  testWidgets('skipped vsync retains the frame flag and transient callback', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final origin = binding.currentSystemFrameTimeStamp;
    AveluneFrameRate.setLimit(30);
    var calls = 0;
    binding.scheduleFrameCallback((_) => calls++);
    expect(binding.hasScheduledFrame, isTrue);
    final before = binding.drawnFrames;
    binding.handleBeginFrame(origin + const Duration(milliseconds: 8));
    binding.handleDrawFrame();
    expect(binding.hasScheduledFrame, isTrue);
    expect(binding.transientCallbackCount, 1);
    expect(calls, 0);
    expect(binding.drawnFrames, before);
    binding.handleBeginFrame(origin + const Duration(microseconds: 33333));
    binding.handleDrawFrame();
    expect(calls, 1);
    expect(binding.hasScheduledFrame, isFalse);
  });

  testWidgets('limit changes affect the next delivered vsync', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final origin = binding.currentSystemFrameTimeStamp;
    AveluneFrameRate.setLimit(30);
    var callbacks = 0;
    binding.scheduleFrameCallback((_) => callbacks++);
    frame(origin + const Duration(milliseconds: 8));
    expect(callbacks, 0);
    AveluneFrameRate.setLimit(120);
    frame(origin + const Duration(microseconds: 16667));
    expect(callbacks, 1);
    binding.scheduleFrameCallback((_) => callbacks++);
    AveluneFrameRate.setLimit(30);
    frame(origin + const Duration(milliseconds: 25));
    expect(callbacks, 1);
    frame(origin + const Duration(milliseconds: 50));
    expect(callbacks, 2);
  });

  testWidgets('forced frames bypass a skipped begin', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final origin = binding.currentSystemFrameTimeStamp;
    AveluneFrameRate.setLimit(30);
    var callbacks = 0;
    binding.scheduleFrameCallback((_) => callbacks++);
    final before = binding.drawnFrames;
    binding.handleBeginFrame(origin + const Duration(milliseconds: 8));
    binding.scheduleForcedFrame();
    binding.handleDrawFrame();
    expect(callbacks, 0);
    expect(binding.drawnFrames, before);
    expect(binding.hasScheduledFrame, isTrue);
    frame(origin + const Duration(milliseconds: 16));
    expect(callbacks, 1);
    expect(binding.drawnFrames, before + 1);
    expect(binding.hasScheduledFrame, isFalse);
  });

  testWidgets('deferred forced frames preserve the mid-frame microtask phase', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final origin = binding.currentSystemFrameTimeStamp;
    AveluneFrameRate.setLimit(30);
    var ready = false;
    final renderedStates = <bool>[];
    binding.observeDraw = () => renderedStates.add(ready);
    binding.scheduleFrameCallback((_) {
      Future<void>.microtask(() => ready = true);
    });
    binding.handleBeginFrame(origin + const Duration(milliseconds: 8));
    binding.scheduleForcedFrame();
    binding.handleDrawFrame();
    expect(renderedStates, isEmpty);
    binding.handleBeginFrame(origin + const Duration(milliseconds: 16));
    await tester.idle();
    binding.handleDrawFrame();
    expect(renderedStates, [true]);
    expect(binding.hasScheduledFrame, isFalse);
  });

  testWidgets('forced frames bypass the cap before begin', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final origin = binding.currentSystemFrameTimeStamp;
    AveluneFrameRate.setLimit(30);
    final before = binding.drawnFrames;
    binding.scheduleForcedFrame();
    frame(origin + const Duration(milliseconds: 8));
    expect(binding.drawnFrames, before + 1);
    expect(binding.hasScheduledFrame, isFalse);
  });

  testWidgets('pause between skipped begin and draw defers standard cleanup', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final origin = binding.currentSystemFrameTimeStamp;
    AveluneFrameRate.setLimit(30);
    binding.scheduleFrame();
    binding.handleBeginFrame(origin + const Duration(milliseconds: 8));
    binding.lifecycle(AppLifecycleState.paused);
    binding.handleDrawFrame();
    expect(binding.schedulerPhase, SchedulerPhase.idle);
    expect(binding.hasScheduledFrame, isTrue);
    frame(origin + const Duration(milliseconds: 16));
    expect(binding.hasScheduledFrame, isFalse);
    binding.lifecycle(AppLifecycleState.resumed);
    expect(binding.hasScheduledFrame, isTrue);
    frame(origin + const Duration(seconds: 10));
    expect(binding.hasScheduledFrame, isFalse);
  });

  testWidgets('resume after a skipped draw accepts the first returning frame', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final origin = binding.currentSystemFrameTimeStamp;
    AveluneFrameRate.setLimit(30);
    var callbacks = 0;
    binding.scheduleFrameCallback((_) => callbacks++);
    frame(origin + const Duration(milliseconds: 8));
    expect(callbacks, 0);
    binding.lifecycle(AppLifecycleState.paused);
    binding.lifecycle(AppLifecycleState.resumed);
    frame(origin + const Duration(milliseconds: 9));
    expect(callbacks, 1);
    expect(binding.hasScheduledFrame, isFalse);
  });

  testWidgets('warmup frames bypass the gate and retain a valid phase', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final origin = binding.currentSystemFrameTimeStamp;
    AveluneFrameRate.setLimit(30);
    binding.scheduleFrame();
    frame(origin + const Duration(milliseconds: 8));
    final before = binding.drawnFrames;
    binding.handleBeginFrame(null);
    binding.handleDrawFrame();
    expect(binding.drawnFrames, before + 1);
    expect(binding.hasScheduledFrame, isFalse);
    expect(binding.schedulerPhase, SchedulerPhase.idle);
  });

  testWidgets('backwards raw timestamps reset the pacing epoch', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final origin = binding.currentSystemFrameTimeStamp;
    AveluneFrameRate.setLimit(30);
    var callbacks = 0;
    binding.scheduleFrameCallback((_) => callbacks++);
    frame(origin + const Duration(milliseconds: 8));
    frame(origin - const Duration(seconds: 1));
    expect(callbacks, 1);
    expect(binding.hasScheduledFrame, isFalse);
  });

  testWidgets('backwards native timestamps keep active Ticker time monotone', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final origin = binding.currentSystemFrameTimeStamp;
    final elapsed = <Duration>[];
    final ticker = Ticker(elapsed.add)..start();
    frame(origin + const Duration(milliseconds: 20));
    frame(origin + const Duration(milliseconds: 40));
    frame(origin - const Duration(seconds: 1));
    frame(origin - const Duration(milliseconds: 980));
    ticker.dispose();
    expect(elapsed, [
      Duration.zero,
      const Duration(milliseconds: 20),
      const Duration(milliseconds: 20),
      const Duration(milliseconds: 40),
    ]);
    binding.lifecycle(AppLifecycleState.paused);
    await tester.pump();
  });

  testWidgets('idle apps do not request frames periodically', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final before = binding.drawnFrames;
    await tester.pump(const Duration(seconds: 10));
    expect(binding.hasScheduledFrame, isFalse);
    expect(binding.drawnFrames, before);
    expect(AveluneWidgetsFlutterBinding.ensureInitialized(), same(binding));
  });
}
