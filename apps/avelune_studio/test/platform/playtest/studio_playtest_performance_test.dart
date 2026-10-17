import 'dart:ui';

import 'package:avelune_studio/platform/playtest/studio_playtest_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FrameTiming frame(int timestamp) => FrameTiming(
  vsyncStart: timestamp,
  buildStart: timestamp,
  buildFinish: timestamp + 4000,
  rasterStart: timestamp + 5000,
  rasterFinish: timestamp + 11000,
  rasterFinishWallTime: timestamp + 11000,
);

Widget host({bool active = true}) => MaterialApp(
  home: Scaffold(body: StudioPlaytestPerformance(active: active)),
);

void main() {
  testWidgets('reports real two fps rather than a target refresh rate', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(find.text('FPS —'), findsOneWidget);
    tester.binding.platformDispatcher.onReportTimings!([
      for (var i = 0; i < 5; i++) frame(i * 500000),
    ]);
    await tester.pump();
    expect(find.text('FPS 2.0 · UI 4.0 ms · rendu 6.0 ms'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ignores repeated and out of order engine reports', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    tester.binding.platformDispatcher.onReportTimings!([
      frame(0),
      frame(1000000),
      frame(1000000),
      frame(500000),
    ]);
    await tester.pump();
    expect(find.textContaining('FPS 1.0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('loading and restarting do not retain old fps samples', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    tester.binding.platformDispatcher.onReportTimings!([
      frame(0),
      frame(1000000),
    ]);
    await tester.pump();
    expect(find.textContaining('FPS 1.0'), findsOneWidget);
    await tester.pumpWidget(host(active: false));
    tester.binding.platformDispatcher.onReportTimings!([
      frame(2000000),
      frame(2100000),
    ]);
    await tester.pump();
    expect(find.text('FPS —'), findsOneWidget);
    await tester.pumpWidget(host());
    tester.binding.platformDispatcher.onReportTimings!([
      frame(3000000),
      frame(3100000),
    ]);
    await tester.pump();
    expect(find.textContaining('FPS 10.0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving the test releases the frame observer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpWidget(const SizedBox());
    tester.binding.platformDispatcher.onReportTimings?.call([
      frame(0),
      frame(500000),
    ]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
