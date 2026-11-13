import 'dart:ui';

import 'package:avelune_studio/presentation/features/map_builder/studio_playtest_performance.dart';
import 'package:flutter_test/flutter_test.dart';

FrameTiming frame(int timestamp) => FrameTiming(
  vsyncStart: timestamp,
  buildStart: timestamp,
  buildFinish: timestamp + 4000,
  rasterStart: timestamp + 5000,
  rasterFinish: timestamp + 11000,
  rasterFinishWallTime: timestamp + 11000,
);

void main() {
  testWidgets('reports real two fps rather than a target refresh rate', (
    tester,
  ) async {
    final monitor = StudioPlaytestPerformanceMonitor();
    addTearDown(monitor.dispose);
    expect(monitor.sample, isNull);
    tester.binding.platformDispatcher.onReportTimings!([
      for (var i = 0; i < 5; i++) frame(i * 500000),
    ]);
    await tester.pump();
    expect(monitor.sample!.fps, 2);
    expect(monitor.sample!.buildMs, 4);
    expect(monitor.sample!.rasterMs, 6);
    monitor.dispose();
  });

  testWidgets('ignores repeated and out of order engine reports', (
    tester,
  ) async {
    final monitor = StudioPlaytestPerformanceMonitor();
    addTearDown(monitor.dispose);
    tester.binding.platformDispatcher.onReportTimings!([
      frame(0),
      frame(1000000),
      frame(1000000),
      frame(500000),
    ]);
    await tester.pump();
    expect(monitor.sample!.fps, 1);
    monitor.dispose();
  });

  testWidgets('loading and restarting do not retain old fps samples', (
    tester,
  ) async {
    final monitor = StudioPlaytestPerformanceMonitor();
    addTearDown(monitor.dispose);
    tester.binding.platformDispatcher.onReportTimings!([
      frame(0),
      frame(1000000),
    ]);
    await tester.pump();
    expect(monitor.sample!.fps, 1);
    monitor.setActive(false);
    tester.binding.platformDispatcher.onReportTimings!([
      frame(2000000),
      frame(2100000),
    ]);
    await tester.pump();
    expect(monitor.sample, isNull);
    monitor.setActive(true);
    tester.binding.platformDispatcher.onReportTimings!([
      frame(3000000),
      frame(3100000),
    ]);
    await tester.pump();
    expect(monitor.sample!.fps, 10);
    monitor.dispose();
  });

  testWidgets('leaving the test releases the frame observer', (tester) async {
    final monitor = StudioPlaytestPerformanceMonitor();
    addTearDown(monitor.dispose);
    monitor.dispose();
    tester.binding.platformDispatcher.onReportTimings?.call([
      frame(0),
      frame(500000),
    ]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
