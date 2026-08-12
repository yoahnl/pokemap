import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/editor_performance_telemetry.dart';
import 'package:map_editor/src/application/services/fine_mask_performance_telemetry.dart';
import 'package:map_editor/src/ui/widgets/element_collision_triple_mask_editor.dart';

import 'support/vm_memory_probe.dart';

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profiles the real fine-mask editor across target extents', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixtureData = await rootBundle.load(
      'assets/cinematics/emotes/emotions.png',
    );
    final fixtureBytes = fixtureData.buffer.asUint8List(
      fixtureData.offsetInBytes,
      fixtureData.lengthInBytes,
    );
    final recorder = EditorPerformanceRecorder();
    final recording = EditorPerformanceTelemetry.startRecording(recorder);
    addTearDown(recording.close);
    final memoryProbe = await VmMemoryProbe.connect();
    addTearDown(memoryProbe.close);
    final timings = <FrameTiming>[];
    void captureTimings(List<FrameTiming> batch) => timings.addAll(batch);
    SchedulerBinding.instance.addTimingsCallback(captureTimings);
    addTearDown(
      () => SchedulerBinding.instance.removeTimingsCallback(captureTimings),
    );
    final results = <Map<String, Object?>>[];

    final memory = await memoryProbe.measure(() async {
      for (final extent in const <int>[64, 256, 512, 1024]) {
        final image = await _decodeFixture(fixtureBytes, extent);
        var callbackCount = 0;
        ElementCollisionProfile? committedProfile;
        final extentBefore = recorder.snapshot();
        final timingStart = timings.length;
        await tester.pumpWidget(
          CupertinoApp(
            home: SizedBox(
              width: 700,
              height: 900,
              child: ElementCollisionTripleMaskEditor(
                image: image,
                source: const TilesetSourceRect(
                  x: 0,
                  y: 0,
                  width: 1,
                  height: 1,
                ),
                tileWidth: extent,
                tileHeight: extent,
                profile: null,
                draftPadding: const WarpTriggerPadding(),
                onProfileChanged: (profile) {
                  callbackCount += 1;
                  committedProfile = profile;
                },
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        final beforeMove = recorder.snapshot();
        final surface = find.byType(CustomPaint).last;
        final rect = tester.getRect(surface);
        final gesture = await tester.startGesture(
          rect.topLeft + const Offset(8, 8),
        );
        for (var index = 1; index <= 30; index += 1) {
          final progress = index / 31;
          await gesture.moveTo(
            Offset(
              rect.left + 8 + (rect.width - 16) * progress,
              rect.top + 8 + (rect.height - 16) * progress,
            ),
          );
          await tester.pump(const Duration(milliseconds: 1));
        }
        final moveInstrumentation = recorder.deltaSince(beforeMove);
        expect(callbackCount, 0);
        for (final counter in EditorPerformanceCounterName.all) {
          expect(moveInstrumentation.counter(counter), 0);
        }
        expect(
          moveInstrumentation
              .spanSamples(FineMaskPerformanceSpanName.pointerMove)
              .length,
          30,
        );

        final beforeCommit = recorder.snapshot();
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 16));
        final commitInstrumentation = recorder.deltaSince(beforeCommit);
        expect(callbackCount, 1);
        expect(committedProfile?.collisionMask, isNotNull);
        expect(
          commitInstrumentation.counter(
            EditorPerformanceCounterName.base64Encode,
          ),
          3,
        );
        expect(
          commitInstrumentation.counter(
            EditorPerformanceCounterName.base64Decode,
          ),
          1,
        );

        await tester.pump(const Duration(milliseconds: 30));
        final extentInstrumentation = recorder.deltaSince(extentBefore);
        final frameSamples = timings
            .skip(timingStart)
            .map((timing) => timing.totalSpan.inMicroseconds)
            .toList(growable: false);
        expect(
          extentInstrumentation
              .spanSamples(FineMaskPerformanceSpanName.readback)
              .length,
          1,
        );
        expect(
          extentInstrumentation
              .spanSamples(FineMaskPerformanceSpanName.commit)
              .length,
          1,
        );
        expect(
          extentInstrumentation.spanSamples(FineMaskPerformanceSpanName.build),
          isNotEmpty,
        );
        expect(
          extentInstrumentation.spanSamples(FineMaskPerformanceSpanName.paint),
          isNotEmpty,
        );
        expect(frameSamples, isNotEmpty);
        results.add(<String, Object?>{
          'extent': extent,
          'pointerMoveCount': 30,
          'moveInstrumentation': <String, Object?>{
            'schemaVersion': 1,
            ...moveInstrumentation.toJson(),
          },
          'commitInstrumentation': <String, Object?>{
            'schemaVersion': 1,
            ...commitInstrumentation.toJson(),
          },
          'extentInstrumentation': <String, Object?>{
            'schemaVersion': 1,
            ...extentInstrumentation.toJson(),
          },
          'frameMetrics': <String, Object?>{
            'scope': 'flutter.frame_total',
            'policy': FineMaskPerformanceBudget.frameTimingPolicy,
            ..._metrics(frameSamples),
          },
        });
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        image.dispose();
      }
    });
    const soakCycles = 3;
    const soakHeapGrowthBudgetBytes = 32 * 1024 * 1024;
    final soakMemory = await memoryProbe.measure(() async {
      for (var cycle = 0; cycle < soakCycles; cycle += 1) {
        final image = await _decodeFixture(fixtureBytes, 1024);
        await tester.pumpWidget(
          CupertinoApp(
            home: SizedBox(
              width: 700,
              height: 900,
              child: ElementCollisionTripleMaskEditor(
                image: image,
                source: const TilesetSourceRect(
                  x: 0,
                  y: 0,
                  width: 1,
                  height: 1,
                ),
                tileWidth: 1024,
                tileHeight: 1024,
                profile: null,
                draftPadding: const WarpTriggerPadding(),
                onProfileChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        image.dispose();
      }
    });
    final soakHeapGrowthBytes =
        soakMemory.heapAfterGcBytes - memory.heapAfterGcBytes;
    final soakHeapStable = soakHeapGrowthBytes <= soakHeapGrowthBudgetBytes;
    expect(soakHeapStable, isTrue);

    binding.reportData = <String, dynamic>{
      'schemaVersion': 2,
      'generatorVersion': 2,
      'benchmark': 'editor_fine_mask_journey',
      'target': 'integration_test/editor_fine_mask_journey_test.dart',
      'requestedOutputPath': _requestedOutputPath,
      'executionMode': const bool.fromEnvironment('dart.vm.profile')
          ? 'flutter-profile'
          : 'flutter-debug',
      'fixture': 'assets/cinematics/emotes/emotions.png',
      'fixtureFingerprint': sha256.convert(fixtureBytes).toString(),
      'pointerMovesPerExtent': 30,
      'performanceBudgets': <String, Object?>{
        'schemaVersion': FineMaskPerformanceBudget.schemaVersion,
        'fineMask1024PointerMoveP95Us':
            FineMaskPerformanceBudget.pointerMove1024P95Us,
        'fineMask1024PaintP95Us': FineMaskPerformanceBudget.paint1024P95Us,
        'frameTimingPolicy': FineMaskPerformanceBudget.frameTimingPolicy,
      },
      'soakCycles': soakCycles,
      'soakMemory': soakMemory.toJson(),
      'soakHeapGrowthBudgetBytes': soakHeapGrowthBudgetBytes,
      'soakHeapStable': soakHeapStable,
      'results': results,
      'memory': <String, Object?>{
        'rssBytes': ProcessInfo.currentRss,
        ...memory.toJson(),
      },
      'instrumentation': <String, Object?>{
        'schemaVersion': 1,
        'coverage': 'element-collision-triple-mask-editor',
        ...recorder.snapshot().toJson(),
      },
    };
  });
}

Future<ui.Image> _decodeFixture(Uint8List bytes, int extent) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: extent,
    targetHeight: extent,
  );
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

Map<String, Object?> _metrics(List<int> samples) {
  final sorted = List<int>.of(samples)..sort();
  return <String, Object?>{
    'samplesUs': sorted,
    'p50Us': _percentile(sorted, 0.50),
    'p95Us': _percentile(sorted, 0.95),
    'p99Us': _percentile(sorted, 0.99),
    'maxUs': sorted.last,
  };
}

int _percentile(List<int> sorted, double percentile) {
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}
