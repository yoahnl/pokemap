import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Offset, Size;

import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/main.dart' show MapEditorApp;
import 'package:map_editor/src/application/services/editor_performance_telemetry.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/riverpod_retry_policy.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:path/path.dart' as p;

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profiles a real open-paint-undo-save editor journey', (
    tester,
  ) async {
    // The benchmark must not inherit the host window's transient launch size:
    // the production desktop layout intentionally rejects viewports below its
    // 800x600 contract, which would measure an error screen instead of edits.
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = await _EditorPerformanceFixture.create();
    addTearDown(fixture.dispose);
    final container = ProviderContainer(retry: disableAutomaticProviderRetry);
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final performanceRecorder = EditorPerformanceRecorder();
    final performanceRecording =
        EditorPerformanceTelemetry.startRecording(performanceRecorder);
    addTearDown(performanceRecording.close);
    final timings = <FrameTiming>[];
    void captureTimings(List<FrameTiming> batch) => timings.addAll(batch);
    var timingsCallbackRegistered = false;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MapEditorApp(
          enableEditorUpdateHost: false,
          restoreLastOpenedProjectOnStartup: false,
        ),
      ),
    );
    for (var index = 0; index < 3; index += 1) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // FrameTiming.totalSpan is captured directly. Build+raster is not a valid
    // substitute because those pipeline phases can overlap.
    SchedulerBinding.instance.addTimingsCallback(captureTimings);
    timingsCallbackRegistered = true;
    addTearDown(
      () {
        if (!timingsCallbackRegistered) return;
        SchedulerBinding.instance.removeTimingsCallback(captureTimings);
        timingsCallbackRegistered = false;
      },
    );

    final phases = <Map<String, Object?>>[];
    phases.add(await _measure('project-open', performanceRecorder, () async {
      await notifier.loadProject(
        fixture.manifestPath,
        rememberAsRecent: false,
      );
      await tester.pump(const Duration(milliseconds: 16));
    }));
    expect(notifier.state.project?.name, 'RM-00 editor profile');

    phases.add(await _measure('map-open', performanceRecorder, () async {
      await notifier.loadMap('maps/performance.json');
      await tester.pump(const Duration(milliseconds: 16));
    }));
    expect(notifier.state.activeMap?.id, 'performance');

    notifier.setActiveLayer('collision');
    notifier.selectTool(EditorToolType.collisionPaint);
    await tester.pump(const Duration(milliseconds: 16));
    phases.add(await _measure('pointer-collision-drag', performanceRecorder,
        () async {
      final canvas = find.byType(MapCanvas);
      expect(canvas, findsOneWidget);
      final gesture = await tester.startGesture(
        tester.getTopLeft(canvas) + const Offset(16, 16),
        buttons: kPrimaryButton,
      );
      await gesture.moveBy(const Offset(160, 0));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 16));
    }));
    final pointerPhase = phases.last;
    final pointerInstrumentation =
        pointerPhase['instrumentation']! as Map<String, Object?>;
    final pointerSpans =
        pointerInstrumentation['spans']! as Map<String, Object?>;
    expect(
      (pointerSpans[EditorPerformanceSpanName.pointerToDispatch]!
          as Map<String, Object?>)['count'],
      1,
    );
    _expectNoPersistenceWork(pointerPhase);

    phases.add(await _measure(
        'collision-paint-100', performanceRecorder, () async {
      notifier.beginMapStroke();
      for (var index = 0; index < 100; index += 1) {
        notifier.paintCollisionAt(
          GridPos(x: index % 64, y: (index * 7) % 64),
        );
        if (index % 10 == 9) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      notifier.endMapStroke();
      await tester.pump(const Duration(milliseconds: 16));
    }));
    final collisionPhase = phases.last;
    final collisionInstrumentation =
        collisionPhase['instrumentation']! as Map<String, Object?>;
    final collisionSpans =
        collisionInstrumentation['spans']! as Map<String, Object?>;
    expect(
      (collisionSpans[EditorPerformanceSpanName.mutationLocal]!
          as Map<String, Object?>)['count'],
      100,
    );
    _expectNoPersistenceWork(collisionPhase);
    expect(notifier.state.isDirty, isTrue);

    phases.add(await _measure('undo', performanceRecorder, () async {
      notifier.undoMap();
      await tester.pump(const Duration(milliseconds: 16));
    }));

    phases.add(await _measure('post-undo-paint', performanceRecorder, () async {
      notifier.beginMapStroke();
      notifier.paintCollisionAt(const GridPos(x: 63, y: 63));
      notifier.endMapStroke();
      await tester.pump(const Duration(milliseconds: 16));
    }));

    phases.add(await _measure('save', performanceRecorder, () async {
      final outcome = await notifier.saveActiveMap();
      expect(outcome.name, 'saved');
      await tester.pump(const Duration(milliseconds: 16));
    }));
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    SchedulerBinding.instance.removeTimingsCallback(captureTimings);
    timingsCallbackRegistered = false;
    final frameMetrics = _frameMetrics(timings);
    expect(frameMetrics['frameCount'], greaterThan(0));
    expect(tester.takeException(), isNull);

    binding.reportData = <String, dynamic>{
      'schemaVersion': 2,
      'generatorVersion': 1,
      'benchmark': 'editor_project_journey',
      'target': 'integration_test/editor_project_journey_test.dart',
      'requestedOutputPath': _requestedOutputPath,
      'executionMode': const bool.fromEnvironment('dart.vm.profile')
          ? 'flutter-profile'
          : 'flutter-debug',
      'fixture': 'synthetic-collision-64x64',
      'fixtureFingerprint': fixture.fingerprint,
      'warmups': 3,
      'sampleCount': timings.length,
      'iterations': <String, Object?>{
        'projectOpen': 1,
        'mapOpen': 1,
        'collisionPaint': 100,
        'pointerCollisionDrag': 1,
        'undo': 1,
        'postUndoPaint': 1,
        'save': 1,
      },
      'measurementScope': <String, Object?>{
        'flutterFrames': true,
        'pureCorePaint': false,
        'buildAndRasterCombined': false,
        // Profile mode does not expose debug rebuild callbacks. Null plus an
        // availability reason is intentional; missing evidence is never zero.
        'rebuildCount': null,
        'rebuildCountAvailability':
            'Flutter profile mode does not expose debug rebuild callbacks',
      },
      'memory': <String, Object?>{
        'rssBytes': ProcessInfo.currentRss,
        'heapBytes': null,
        'heapAvailability': 'not exposed by dart:io',
      },
      'results': phases,
      'instrumentation': <String, Object?>{
        'schemaVersion': 1,
        'coverage': 'application-boundaries',
        'canvasPaintScope': 'ui-thread picture recording, excludes GPU raster',
        ...performanceRecorder.snapshot().toJson(),
      },
      'frameMetrics': frameMetrics,
      'thresholdPolicy': <String, Object?>{
        'observationOnly': true,
        'minimumHistoricalObservations': 10,
        'requiredConsecutiveRegressions': 2,
      },
    };
  });
}

void _expectNoPersistenceWork(Map<String, Object?> phase) {
  final instrumentation = phase['instrumentation']! as Map<String, Object?>;
  final counters = instrumentation['counters']! as Map<String, Object?>;
  for (final counter in EditorPerformanceCounterName.all) {
    expect(counters[counter], 0, reason: '${phase['phase']}: $counter');
  }
}

Future<Map<String, Object?>> _measure(
  String phase,
  EditorPerformanceRecorder performanceRecorder,
  Future<void> Function() action,
) async {
  final before = performanceRecorder.snapshot();
  final stopwatch = Stopwatch()..start();
  await action();
  stopwatch.stop();
  final instrumentation = performanceRecorder.deltaSince(before).toJson();
  return <String, Object?>{
    'phase': phase,
    'durationUs': stopwatch.elapsedMicroseconds,
    'rssBytesAfterPhase': ProcessInfo.currentRss,
    'instrumentation': instrumentation,
  };
}

Map<String, Object?> _frameMetrics(List<FrameTiming> timings) {
  final build = timings
      .map((timing) => timing.buildDuration.inMicroseconds)
      .toList(growable: false);
  final raster = timings
      .map((timing) => timing.rasterDuration.inMicroseconds)
      .toList(growable: false);
  final spans = timings
      .map((timing) => timing.totalSpan.inMicroseconds)
      .toList(growable: false);
  final sortedBuild = List<int>.of(build)..sort();
  final sortedRaster = List<int>.of(raster)..sort();
  final sortedSpans = List<int>.of(spans)..sort();
  final over16 = spans.where((value) => value > 16670).length;
  final over33 = spans.where((value) => value > 33300).length;
  return <String, Object?>{
    'frameCount': timings.length,
    'buildSamplesMicroseconds': build,
    'rasterSamplesMicroseconds': raster,
    'frameSpanSamplesMicroseconds': spans,
    'buildP50Us': _percentile(sortedBuild, 0.50),
    'buildP95Us': _percentile(sortedBuild, 0.95),
    'buildP99Us': _percentile(sortedBuild, 0.99),
    'rasterP50Us': _percentile(sortedRaster, 0.50),
    'rasterP95Us': _percentile(sortedRaster, 0.95),
    'rasterP99Us': _percentile(sortedRaster, 0.99),
    'frameSpanP50Us': _percentile(sortedSpans, 0.50),
    'frameSpanP95Us': _percentile(sortedSpans, 0.95),
    'frameSpanP99Us': _percentile(sortedSpans, 0.99),
    'framesOver16Point67Milliseconds': over16,
    'framesOver16Point67Rate': timings.isEmpty ? 0 : over16 / timings.length,
    'framesOver33Point3Milliseconds': over33,
    'framesOver33Point3Rate': timings.isEmpty ? 0 : over33 / timings.length,
  };
}

int _percentile(List<int> sorted, double percentile) {
  if (sorted.isEmpty) return 0;
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

final class _EditorPerformanceFixture {
  const _EditorPerformanceFixture({
    required this.root,
    required this.manifestPath,
    required this.fingerprint,
  });

  final Directory root;
  final String manifestPath;
  final String fingerprint;

  static Future<_EditorPerformanceFixture> create() async {
    final root = await Directory.systemTemp.createTemp('pokemap-rm00-editor-');
    final manifestPath = p.join(root.path, 'project.json');
    final mapPath = p.join(root.path, 'maps', 'performance.json');
    const manifest = ProjectManifest(
      name: 'RM-00 editor profile',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'performance',
          name: 'Performance',
          relativePath: 'maps/performance.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
    );
    final map = MapData(
      id: 'performance',
      name: 'Performance',
      size: const GridSize(width: 64, height: 64),
      layers: <MapLayer>[
        CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.filled(64 * 64, false),
        ),
      ],
    );
    await FileProjectRepository().saveProject(manifest, manifestPath);
    await FileMapRepository().saveMap(
      map,
      mapPath,
      projectDialogueContext: manifest,
    );
    return _EditorPerformanceFixture(
      root: root,
      manifestPath: manifestPath,
      fingerprint: sha256
          .convert(utf8.encode(jsonEncode(<String, Object?>{
            'project': manifest.toJson(),
            'map': map.toJson(),
          })))
          .toString(),
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}
