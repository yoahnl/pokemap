import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/embedding/avelune_runtime_diagnostics.dart';
import 'package:pokemap_hub/embedding/avelune_debug_hud.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.avelune.runtime/diagnostics');
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  test(
    'counts actual frame cadence and render latency, then expires stale frames',
    () {
      final frames = AveluneFrameWindow();
      frames.record([
        for (var i = 0; i < 61; i++) frame(i * 16667),
      ], Duration.zero);
      final sample = frames.read(const Duration(seconds: 1));
      expect(sample.fps, closeTo(60, .01));
      expect(sample.latencyMs, 8);
      expect(sample.p95Ms, 8);
      expect(sample.buildMs, 2);
      expect(sample.rasterMs, 4);
      final expired = frames.read(const Duration(seconds: 4));
      expect(expired.fps, 0);
      expect(expired.latencyMs, isNull);
    },
  );

  test('retains only a bounded recent frame window and computes p95', () {
    final frames = AveluneFrameWindow();
    frames.record([
      for (var i = 0; i < 2000; i++) frame(i * 1000),
    ], Duration.zero);
    expect(frames.sampleCount, lessThanOrEqualTo(512));
    expect(frames.read(Duration.zero).intervals.count, lessThanOrEqualTo(512));
    frames.clear();
    frames.record([
      for (var i = 0; i < 100; i++)
        frame(i * 16667, latency: i >= 94 ? 30000 : 8000),
    ], Duration.zero);
    expect(frames.read(Duration.zero).p95Ms, 30);
    frames.clear();
    expect(frames.read(Duration.zero).fps, isNull);
  });

  test(
    'reports separate duration distributions and cadence budget overruns',
    () {
      final frames = AveluneFrameWindow();
      frames.record([
        frame(0),
        frame(16667),
        frame(50001, latency: 40000),
        frame(100002),
        frame(116669),
      ], Duration.zero);
      final sample = frames.read(Duration.zero);

      expect(sample.frameCount, 5);
      expect(sample.intervals.count, 4);
      expect(sample.intervals.p50Ms, 16.667);
      expect(sample.intervals.p95Ms, 50.001);
      expect(sample.intervals.p99Ms, 50.001);
      expect(sample.intervals.maxMs, 50.001);
      expect(sample.build.p99Ms, 2);
      expect(sample.raster.p99Ms, 4);
      expect(sample.latency.p99Ms, 40);
      expect(sample.budget60.overruns, 2);
      expect(sample.budget60.overrunFraction, .5);
      expect(sample.budget60.longestRun, 2);
      expect(sample.budget60.totalExcessMs, closeTo(50, .002));
      expect(sample.budget30.overruns, 1);
      expect(sample.budget30.longestRun, 1);
      expect(sample.budget30.totalExcessMs, closeTo(16.667, .002));
      final json = sample.toJson();
      expect(json['cadenceSource'], 'flutterVsyncStart');
      expect(json['presentation'], isNull);
      expect(json['gpu'], isNull);
      expect(json['frameCount'], 5);
    },
  );

  test(
    'budget counts preserve cadence gaps at nominal timestamp precision',
    () {
      expect(
        () => AveluneFrameBudget.fromIntervals([], framesPerSecond: 0),
        throwsArgumentError,
      );
      expect(
        () => AveluneFrameBudget.fromIntervals([], framesPerSecond: -30),
        throwsArgumentError,
      );
      final frames = AveluneFrameWindow();
      frames.record([
        frame(0),
        frame(33333),
        frame(66667),
        frame(100000),
      ], Duration.zero);
      final sample = frames.read(Duration.zero);
      expect(sample.budget30.overruns, 0);
      expect(sample.budget60.overruns, 3);
      expect(sample.budget60.longestRun, 3);
      frames.record([frame(100000), frame(99999)], Duration.zero);
      expect(frames.read(Duration.zero).intervals.count, 3);
      expect(frames.read(const Duration(seconds: 4)).intervals.count, 0);
      frames.clear();
      expect(frames.read(Duration.zero).toJson()['frameCount'], 0);
      expect(frames.read(Duration.zero).budget30.overrunFraction, isNull);
    },
  );

  test('retains a long cadence stall after its starting frame is pruned', () {
    final frames = AveluneFrameWindow();
    frames.record([frame(0)], Duration.zero);
    frames.record([frame(5000000)], const Duration(seconds: 5));
    final sample = frames.read(const Duration(seconds: 5));
    expect(sample.frameCount, 1);
    expect(sample.intervals.count, 1);
    expect(sample.intervals.maxMs, 5000);
    expect(sample.budget30.overruns, 1);
    expect(sample.toJson()['window'], {
      'retentionMs': 2000,
      'sampleLimit': 512,
      'intervalSelection': 'endTimestamp',
      'observedIntervalSpanMs': 5000.0,
    });
    expect(sample.fps, closeTo(.2, .001));
    frames.clear();
    frames.record([frame(6000000)], const Duration(seconds: 6));
    expect(frames.read(const Duration(seconds: 6)).intervals.count, 0);
  });

  testWidgets('native snapshot exposes typed metrics with unknown GPU fields', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'cpuSeconds': 1, 'uptimeSeconds': 2, 'memoryBytes': 128},
    );
    final diagnostics = AveluneRuntimeDiagnostics(channel: channel)..attach();
    addTearDown(() {
      diagnostics.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });
    diagnostics.setPlaying(true);
    diagnostics.setEnabled(true);
    await tester.pump();
    final response = Completer<ByteData?>();
    messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(const MethodCall('snapshot')),
      response.complete,
    );
    final snapshot = codec.decodeEnvelope((await response.future)!);
    expect(snapshot['schemaVersion'], 1);
    expect(snapshot['frames']['cadenceSource'], 'flutterVsyncStart');
    expect(snapshot['frames']['gpu'], isNull);
    expect(snapshot['frames']['presentation'], isNull);
    expect(snapshot['process']['memoryBytes'], 128);
    expect(snapshot['collection']['enabled'], true);
    expect(snapshot['collection']['active'], true);
    expect(snapshot['collection']['playing'], true);
    diagnostics.setEnabled(false);
  });

  test(
    'CPU uses elapsed process counters and represents missing data honestly',
    () {
      final previous = AveluneProcessSample.fromPayload({
        'cpuSeconds': 10,
        'uptimeSeconds': 20,
      });
      final next = AveluneProcessSample.fromPayload({
        'cpuSeconds': 11.5,
        'uptimeSeconds': 21,
        'memoryBytes': 256 * 1024 * 1024,
      });
      expect(next.cpuPercentSince(previous), 150);
      expect(next.memoryMiB, 256);
      expect(next.cpuPercentSince(next), isNull);
      expect(
        AveluneProcessSample.fromPayload({
          'cpuSeconds': double.nan,
          'memoryBytes': -1,
        }).memoryMiB,
        isNull,
      );
      expect(
        AveluneProcessSample.fromPayload(null).cpuPercentSince(previous),
        isNull,
      );
    },
  );

  testWidgets(
    'native toggle activates only during a game and stops on background/disable',
    (tester) async {
      var queries = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        queries++;
        return {
          'cpuSeconds': queries / 2,
          'uptimeSeconds': queries,
          'memoryBytes': 128 * 1024 * 1024,
        };
      });
      final diagnostics = AveluneRuntimeDiagnostics(channel: channel)..attach();
      addTearDown(() {
        diagnostics.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      });
      Future<void> enabled(bool value) async {
        final done = Completer<void>();
        messenger.handlePlatformMessage(
          channel.name,
          codec.encodeMethodCall(MethodCall('setEnabled', {'enabled': value})),
          (_) => done.complete(),
        );
        await done.future;
      }

      await enabled(true);
      await tester.pump(const Duration(seconds: 2));
      expect(queries, 0);
      diagnostics.setPlaying(true);
      await tester.pump();
      expect(diagnostics.visible, isTrue);
      expect(queries, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(diagnostics.snapshot.cpuPercent, 50);
      expect(diagnostics.snapshot.process.memoryMiB, 128);
      diagnostics.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(diagnostics.visible, isFalse);
      final paused = queries;
      await tester.pump(const Duration(seconds: 3));
      expect(queries, paused);
      diagnostics.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(diagnostics.snapshot.cpuPercent, isNull);
      await enabled(false);
      expect(diagnostics.visible, isFalse);
      final stopped = queries;
      await tester.pump(const Duration(seconds: 3));
      expect(queries, stopped);
    },
  );

  testWidgets('late native replies cannot revive a disabled HUD', (
    tester,
  ) async {
    final pending = Completer<Object?>();
    messenger.setMockMethodCallHandler(channel, (_) => pending.future);
    final diagnostics = AveluneRuntimeDiagnostics(channel: channel)..attach();
    addTearDown(() {
      diagnostics.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });
    diagnostics.setPlaying(true);
    diagnostics.setEnabled(true);
    await tester.pump();
    diagnostics.setEnabled(false);
    pending.complete({'memoryBytes': 512 * 1024 * 1024});
    await tester.pump();
    expect(diagnostics.visible, isFalse);
    expect(diagnostics.snapshot.process.memoryMiB, isNull);
  });

  testWidgets(
    'HUD appears only when enabled and leaves gameplay touches intact',
    (tester) async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'memoryBytes': 128 * 1024 * 1024,
          'thermalState': 'serious',
        },
      );
      final diagnostics = AveluneRuntimeDiagnostics(channel: channel)..attach();
      addTearDown(() {
        diagnostics.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      });
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 15,
                  right: 15,
                  child: TextButton(
                    onPressed: () => taps++,
                    child: const Text('world'),
                  ),
                ),
                AveluneDebugHud(diagnostics: diagnostics),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('avelune-debug-hud')), findsNothing);
      diagnostics.setPlaying(true);
      diagnostics.setEnabled(true);
      await tester.pump();
      expect(find.text('RAM 128.0 MiB'), findsOneWidget);
      expect(find.text('Chauffe : élevée'), findsOneWidget);
      await tester.tap(find.text('world'));
      expect(taps, 1);
      diagnostics.setEnabled(false);
      await tester.pump();
      expect(find.byKey(const ValueKey('avelune-debug-hud')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('HUD fits a short landscape viewport with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(667, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final diagnostics = _LandscapeDiagnostics();
    addTearDown(diagnostics.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(667, 320),
            padding: EdgeInsets.only(top: 24, bottom: 34),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(body: AveluneDebugHud(diagnostics: diagnostics)),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Chauffe : élevée'), findsOneWidget);
    expect(find.textContaining('intervalle p99'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('unavailable native measurements do not break frame collection', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'unavailable'),
    );
    final diagnostics = AveluneRuntimeDiagnostics(channel: channel)..attach();
    addTearDown(() {
      diagnostics.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });
    diagnostics.setPlaying(true);
    diagnostics.setEnabled(true);
    await tester.pump();
    expect(diagnostics.visible, isTrue);
    expect(diagnostics.snapshot.process.memoryMiB, isNull);
    diagnostics.setPlaying(false);
    await tester.pump(const Duration(seconds: 3));
    expect(diagnostics.visible, isFalse);
  });
}

FrameTiming frame(int vsync, {int latency = 8000}) => FrameTiming(
  vsyncStart: vsync,
  buildStart: vsync + 1000,
  buildFinish: vsync + 3000,
  rasterStart: vsync + latency - 4000,
  rasterFinish: vsync + latency,
  rasterFinishWallTime: vsync + latency,
);

class _LandscapeDiagnostics extends AveluneRuntimeDiagnostics {
  @override
  bool get visible => true;

  @override
  AveluneDiagnosticSnapshot get snapshot => const AveluneDiagnosticSnapshot(
    frames: AveluneFrameSample(
      fps: 15,
      latencyMs: 120,
      p95Ms: 150,
      buildMs: 40,
      rasterMs: 65,
      intervals: AveluneFrameDistribution(p99Ms: 180, maxMs: 5000),
    ),
    process: AveluneProcessSample(
      memoryBytes: 4294967296,
      memoryKind: 'footprint',
      thermalState: 'serious',
      lowPowerMode: false,
    ),
    cpuPercent: 250,
  );
}
