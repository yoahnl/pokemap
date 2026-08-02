import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/main.dart' show MapEditorApp;
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profiles a real open-paint-undo-save editor journey', (
    tester,
  ) async {
    final fixture = await _EditorPerformanceFixture.create();
    addTearDown(fixture.dispose);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final timings = <FrameTiming>[];
    void captureTimings(List<FrameTiming> batch) => timings.addAll(batch);
    var timingsCallbackRegistered = false;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MapEditorApp(),
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
    phases.add(await _measure('project-open', () async {
      await notifier.loadProject(
        fixture.manifestPath,
        rememberAsRecent: false,
      );
      await tester.pump(const Duration(milliseconds: 16));
    }));
    expect(notifier.state.project?.name, 'RM-00 editor profile');

    phases.add(await _measure('map-open', () async {
      await notifier.loadMap('maps/performance.json');
      await tester.pump(const Duration(milliseconds: 16));
    }));
    expect(notifier.state.activeMap?.id, 'performance');

    phases.add(await _measure('collision-paint-100', () async {
      notifier.setActiveLayer('collision');
      notifier.selectTool(EditorToolType.collisionPaint);
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
    expect(notifier.state.isDirty, isTrue);

    phases.add(await _measure('undo', () async {
      notifier.undoMap();
      await tester.pump(const Duration(milliseconds: 16));
    }));

    phases.add(await _measure('post-undo-paint', () async {
      notifier.beginMapStroke();
      notifier.paintCollisionAt(const GridPos(x: 63, y: 63));
      notifier.endMapStroke();
      await tester.pump(const Duration(milliseconds: 16));
    }));

    phases.add(await _measure('save', () async {
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
      'frameMetrics': frameMetrics,
      'thresholdPolicy': <String, Object?>{
        'observationOnly': true,
        'minimumHistoricalObservations': 10,
        'requiredConsecutiveRegressions': 2,
      },
    };
  });
}

Future<Map<String, Object?>> _measure(
  String phase,
  Future<void> Function() action,
) async {
  final stopwatch = Stopwatch()..start();
  await action();
  stopwatch.stop();
  return <String, Object?>{
    'phase': phase,
    'durationUs': stopwatch.elapsedMicroseconds,
    'rssBytesAfterPhase': ProcessInfo.currentRss,
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
      version: ProjectVersion.v3,
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
