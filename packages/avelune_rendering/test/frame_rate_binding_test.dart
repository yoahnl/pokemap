import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _PacedTestBinding extends AutomatedTestWidgetsFlutterBinding
    with AveluneFrameRateBinding {
  Duration now = Duration.zero;
  int frames = 0;

  @override
  Duration get framePacingElapsed => now;

  @override
  void handleBeginFrame(Duration? rawTimeStamp) {
    if (rawTimeStamp != null) frames++;
    super.handleBeginFrame(rawTimeStamp);
  }

  void lifecycle(AppLifecycleState state) =>
      handleAppLifecycleStateChanged(state);
}

void main() {
  final binding = _PacedTestBinding();

  setUp(() {
    binding.lifecycle(AppLifecycleState.paused);
    binding.now = Duration.zero;
    AveluneFrameRate.setLimit(30);
    binding.lifecycle(AppLifecycleState.resumed);
  });

  tearDown(() {
    binding.lifecycle(AppLifecycleState.paused);
    AveluneFrameRate.setLimit(AveluneFrameRate.defaultLimit);
  });

  testWidgets('coalesces frame requests without submitting early frames', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    binding.scheduleFrame();
    await tester.pump();
    final before = binding.frames;
    for (var index = 0; index < 25; index++) {
      binding.scheduleFrame();
    }
    expect(binding.hasScheduledFrame, isFalse);
    binding.now = const Duration(milliseconds: 20);
    await tester.pump(const Duration(milliseconds: 20));
    expect(binding.frames, before);
    binding.now = const Duration(microseconds: 33333);
    await tester.pump(const Duration(microseconds: 13333));
    expect(binding.frames, before + 1);
  });

  testWidgets('faster limits reschedule a waiting frame', (tester) async {
    await tester.pumpWidget(const SizedBox());
    binding.scheduleFrame();
    await tester.pump();
    final before = binding.frames;
    binding.scheduleFrame();
    binding.now = const Duration(milliseconds: 10);
    await tester.pump(const Duration(milliseconds: 10));
    AveluneFrameRate.setLimit(120);
    await tester.pump();
    expect(binding.frames, before + 1);
  });

  testWidgets('backgrounding cancels pending work and resumes immediately', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    binding.scheduleFrame();
    await tester.pump();
    final before = binding.frames;
    binding.scheduleFrame();
    binding.lifecycle(AppLifecycleState.paused);
    binding.now = const Duration(seconds: 10);
    await tester.pump(const Duration(seconds: 10));
    expect(binding.frames, before);
    binding.lifecycle(AppLifecycleState.resumed);
    await tester.pump();
    expect(binding.frames, before + 1);
  });

  testWidgets('slower limits postpone the waiting frame', (tester) async {
    AveluneFrameRate.setLimit(120);
    await tester.pumpWidget(const SizedBox());
    binding.scheduleFrame();
    await tester.pump();
    final before = binding.frames;
    binding.scheduleFrame();
    binding.now = const Duration(milliseconds: 2);
    await tester.pump(const Duration(milliseconds: 2));
    AveluneFrameRate.setLimit(30);
    binding.now = const Duration(milliseconds: 10);
    await tester.pump(const Duration(milliseconds: 8));
    expect(binding.frames, before);
    binding.now = const Duration(microseconds: 33333);
    await tester.pump(const Duration(microseconds: 23333));
    expect(binding.frames, before + 1);
  });

  testWidgets('system forced frames remain available', (tester) async {
    await tester.pumpWidget(const SizedBox());
    binding.scheduleFrame();
    await tester.pump();
    final before = binding.frames;
    binding.scheduleFrame();
    expect(binding.hasScheduledFrame, isFalse);
    binding.scheduleForcedFrame();
    expect(binding.hasScheduledFrame, isTrue);
    binding.now = const Duration(milliseconds: 5);
    await tester.pump(const Duration(milliseconds: 5));
    expect(binding.frames, before + 1);
    binding.now = const Duration(milliseconds: 60);
    await tester.pump(const Duration(milliseconds: 55));
    expect(binding.frames, before + 1);
  });

  testWidgets('idle apps do not schedule periodic frames', (tester) async {
    await tester.pumpWidget(const SizedBox());
    binding.scheduleFrame();
    binding.now = const Duration(milliseconds: 34);
    await tester.pump(const Duration(milliseconds: 34));
    final before = binding.frames;
    binding.now = const Duration(seconds: 5);
    await tester.pump(const Duration(seconds: 5));
    expect(binding.frames, before);
  });

  testWidgets('initialization preserves the existing test binding', (
    tester,
  ) async {
    expect(AveluneWidgetsFlutterBinding.ensureInitialized(), same(binding));
    expect(AveluneWidgetsFlutterBinding.ensureInitialized(), same(binding));
    await tester.pumpWidget(const SizedBox());
  });
}
