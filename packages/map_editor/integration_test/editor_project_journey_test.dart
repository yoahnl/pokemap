import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind, kPrimaryButton;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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

import 'support/vm_memory_probe.dart';

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
    final fixtureData = await rootBundle.load(
      'assets/cinematics/emotes/emotions.png',
    );
    final fixture = await _EditorPerformanceFixture.create(
      fixtureData.buffer.asUint8List(
        fixtureData.offsetInBytes,
        fixtureData.lengthInBytes,
      ),
    );
    addTearDown(fixture.dispose);
    final container = ProviderContainer(retry: disableAutomaticProviderRetry);
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final performanceRecorder = EditorPerformanceRecorder();
    final performanceRecording = EditorPerformanceTelemetry.startRecording(
      performanceRecorder,
    );
    addTearDown(performanceRecording.close);
    final memoryProbe = await VmMemoryProbe.connect();
    addTearDown(memoryProbe.close);
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
    addTearDown(() {
      if (!timingsCallbackRegistered) return;
      SchedulerBinding.instance.removeTimingsCallback(captureTimings);
      timingsCallbackRegistered = false;
    });

    final phases = <Map<String, Object?>>[];
    final journeyMemory = await memoryProbe.measure(() async {
      phases.add(
        await _measure('project-open', performanceRecorder, () async {
          await notifier.loadProject(
            fixture.manifestPath,
            rememberAsRecent: false,
          );
          await tester.pump(const Duration(milliseconds: 16));
        }),
      );
      expect(notifier.state.project?.name, 'RM-00 editor profile');

      phases.add(
        await _measure('map-open', performanceRecorder, () async {
          await notifier.loadMap('maps/performance.json');
          await tester.pump(const Duration(milliseconds: 16));
        }),
      );
      expect(notifier.state.activeMap?.id, 'performance');

      notifier.setActiveLayer('objects');
      notifier.selectTool(EditorToolType.tilePaint);
      notifier.selectTilesetEditorContext('profile-tiles');
      notifier.selectPaletteTile(1);
      await tester.pump(const Duration(milliseconds: 16));
      phases.add(
        await _measureSamples(
          'tile-placement-90',
          performanceRecorder,
          samples: 90,
          action: (index) async {
            notifier.beginMapStroke();
            await notifier.paintSelectedBrushAt(
              GridPos(x: index % 64, y: (index * 11) % 64),
              tilesetColumnsById: const <String, int>{'profile-tiles': 1},
            );
            notifier.endMapStroke();
          },
        ),
      );
      final placementPhase = phases.last;
      expect(placementPhase['p95Us'], lessThan(16000));
      _expectNoPersistenceWork(placementPhase);

      notifier.selectProjectElement('profile-marker');
      phases.add(
        await _measure(
          'canonical-element-placement',
          performanceRecorder,
          () async {
            await notifier.placeSelectedProjectElementAt(
              const GridPos(x: 10, y: 10),
            );
          },
        ),
      );
      expect(
        notifier.state.activeMap?.placedElements.any(
          (element) =>
              element.pos == const GridPos(x: 10, y: 10) &&
              element.properties[pokemapPlacementOriginProperty] ==
                  pokemapPlacementOriginAuthored,
        ),
        isTrue,
      );

      notifier.setActiveLayer('collision');
      notifier.selectTool(EditorToolType.collisionPaint);
      await tester.pump(const Duration(milliseconds: 16));
      phases.add(
        await _measure('pointer-collision-drag', performanceRecorder, () async {
          final canvas = find.byType(MapCanvas);
          expect(canvas, findsOneWidget);
          final canvasRect = tester.getRect(canvas);
          final gesture = await tester.startGesture(
            canvasRect.center - const Offset(160, 0),
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryButton,
          );
          for (var index = 0; index < 90; index += 1) {
            await gesture.moveBy(Offset(index.isEven ? 160 : -160, 0));
            await tester.pump(const Duration(milliseconds: 1));
          }
          await gesture.up();
          await tester.pump(const Duration(milliseconds: 16));
        }),
      );
      final pointerPhase = phases.last;
      final pointerInstrumentation =
          pointerPhase['instrumentation']! as Map<String, Object?>;
      final pointerSpans =
          pointerInstrumentation['spans']! as Map<String, Object?>;
      expect(
        (pointerSpans[EditorPerformanceSpanName.pointerPreDispatch]!
            as Map<String, Object?>)['count'],
        90,
      );
      expect(
        (pointerSpans[EditorPerformanceSpanName.pointerToStatePublish]!
            as Map<String, Object?>)['count'],
        90,
      );
      expect(
        (pointerSpans[EditorPerformanceSpanName.pointerToStatePublish]!
            as Map<String, Object?>)['p95Us'],
        lessThan(8000),
      );
      _expectNoPersistenceWork(pointerPhase);

      expect(notifier.state.isDirty, isTrue);

      phases.add(
        await _measure('undo', performanceRecorder, () async {
          notifier.undoMap();
          await tester.pump(const Duration(milliseconds: 16));
        }),
      );

      phases.add(
        await _measure('post-undo-paint', performanceRecorder, () async {
          notifier.beginMapStroke();
          notifier.paintCollisionAt(const GridPos(x: 63, y: 63));
          notifier.endMapStroke();
          await tester.pump(const Duration(milliseconds: 16));
        }),
      );

      phases.add(
        await _measure('save', performanceRecorder, () async {
          final outcome = await notifier.saveActiveMap();
          expect(outcome.name, 'saved');
          await tester.pump(const Duration(milliseconds: 16));
        }),
      );
      for (final extent in const <int>[128, 256, 512, 1024]) {
        await notifier.loadMap('maps/collision-$extent.json');
        notifier.setActiveLayer('collision');
        notifier.selectTool(EditorToolType.collisionPaint);
        var nextCellIndex = 0;
        for (final strokeCount in const <int>[1, 10, 100, 1000]) {
          phases.add(
            await _measure(
              'collision-paint-${extent}x$extent-$strokeCount',
              performanceRecorder,
              () async {
                notifier.beginMapStroke();
                for (var index = 0; index < strokeCount; index += 1) {
                  final cellIndex = nextCellIndex + index;
                  notifier.paintCollisionAt(
                    GridPos(x: cellIndex % extent, y: cellIndex ~/ extent),
                  );
                  if (index % 100 == 99) {
                    await tester.pump(const Duration(milliseconds: 16));
                  }
                }
                nextCellIndex += strokeCount;
                notifier.endMapStroke();
                await tester.pump(const Duration(milliseconds: 16));
              },
            ),
          );
          final collisionPhase = phases.last;
          final collisionInstrumentation =
              collisionPhase['instrumentation']! as Map<String, Object?>;
          final collisionSpans =
              collisionInstrumentation['spans']! as Map<String, Object?>;
          expect(
            (collisionSpans[EditorPerformanceSpanName.mutationLocal]!
                as Map<String, Object?>)['count'],
            strokeCount,
          );
          _expectNoPersistenceWork(collisionPhase);
        }
      }
      for (final maskExtent in const <int>[64, 256, 512, 1024]) {
        phases.add(
          await _measureSamples(
            'mask-roundtrip-${maskExtent}x$maskExtent',
            performanceRecorder,
            samples: 10,
            action: (_) async {
              final solidPixels = List<bool>.generate(
                maskExtent * maskExtent,
                (index) => index % 7 == 0,
                growable: false,
              );
              final encoded =
                  EditorPerformanceTelemetry.encodePackedCollisionMask(
                    widthPx: maskExtent,
                    heightPx: maskExtent,
                    solidPixels: solidPixels,
                  );
              final decoded =
                  EditorPerformanceTelemetry.decodePackedCollisionMask(
                    widthPx: maskExtent,
                    heightPx: maskExtent,
                    dataBase64: encoded,
                  );
              expect(decoded.length, solidPixels.length);
            },
          ),
        );
      }
    });
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    SchedulerBinding.instance.removeTimingsCallback(captureTimings);
    timingsCallbackRegistered = false;
    final frameMetrics = _frameMetrics(timings);
    expect(frameMetrics['frameCount'], greaterThan(0));
    expect(tester.takeException(), isNull);

    binding.reportData = <String, dynamic>{
      'schemaVersion': 2,
      'generatorVersion': 2,
      'benchmark': 'editor_project_journey',
      'target': 'integration_test/editor_project_journey_test.dart',
      'requestedOutputPath': _requestedOutputPath,
      'executionMode': const bool.fromEnvironment('dart.vm.profile')
          ? 'flutter-profile'
          : 'flutter-debug',
      'fixture': 'synthetic-interactive-collision-matrix',
      'fixtureFingerprint': fixture.fingerprint,
      'warmups': 3,
      'sampleCount': timings.length,
      'iterations': <String, Object?>{
        'projectOpen': 1,
        'mapOpen': 1,
        'tilePlacement': 90,
        'canonicalElementPlacement': 1,
        'collisionPaintExtents': <int>[128, 256, 512, 1024],
        'collisionPaintCounts': <int>[1, 10, 100, 1000],
        'pointerCollisionDrag': 90,
        'maskExtents': <int>[64, 256, 512, 1024],
        'undo': 1,
        'postUndoPaint': 1,
        'save': 1,
      },
      'measurementScope': <String, Object?>{
        'pointerLatencyMetric': 'pointer.to_state_publish',
        'canvasPaintMetric': 'canvas.paint_recording',
        'frameMetric': 'flutter.frame_total',
        'framePolicy': 'observation',
        'flutterFrames': true,
        'pureCorePaint': false,
        'buildAndRasterCombined': false,
        'rebuildCount': null,
        'rebuildCountAvailability':
            'Flutter profile mode does not expose debug rebuild callbacks',
      },
      'memory': <String, Object?>{
        'rssBytes': ProcessInfo.currentRss,
        ...journeyMemory.toJson(),
      },
      'results': phases,
      'instrumentation': <String, Object?>{
        'schemaVersion': 1,
        'coverage':
            'instrumented editor and authoring application boundaries only',
        'canvasPaintScope': 'ui-thread picture recording, excludes GPU raster',
        ...performanceRecorder.snapshot().toJson(),
      },
      'frameMetrics': frameMetrics,
      'thresholdPolicy': <String, Object?>{
        'interactiveBudgetsRecalculatedByDriver': true,
        'placementP95BudgetUs': 16000,
        'pointerMoveP95BudgetUs': 8000,
        'flutterFrameTimingPolicy': 'observation',
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

Future<Map<String, Object?>> _measureSamples(
  String phase,
  EditorPerformanceRecorder performanceRecorder, {
  required int samples,
  required Future<void> Function(int index) action,
}) async {
  final before = performanceRecorder.snapshot();
  final samplesUs = <int>[];
  for (var index = 0; index < samples; index += 1) {
    final stopwatch = Stopwatch()..start();
    await action(index);
    stopwatch.stop();
    samplesUs.add(stopwatch.elapsedMicroseconds);
  }
  final sorted = List<int>.of(samplesUs)..sort();
  return <String, Object?>{
    'phase': phase,
    'samplesUs': samplesUs,
    'p50Us': _percentile(sorted, 0.50),
    'p95Us': _percentile(sorted, 0.95),
    'p99Us': _percentile(sorted, 0.99),
    'maxUs': sorted.last,
    'rssBytesAfterPhase': ProcessInfo.currentRss,
    'instrumentation': performanceRecorder.deltaSince(before).toJson(),
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
    'scope': 'flutter.frame_total',
    'policy': 'observation',
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

  static Future<_EditorPerformanceFixture> create(
    List<int> tilesetBytes,
  ) async {
    final root = await Directory.systemTemp.createTemp('pokemap-rm00-editor-');
    final manifestPath = p.join(root.path, 'project.json');
    final mapPath = p.join(root.path, 'maps', 'performance.json');
    final tilesetPath = p.join(root.path, 'tilesets', 'profile.png');
    final manifest = ProjectManifest(
      name: 'RM-00 editor profile',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'performance',
          name: 'Performance',
          relativePath: 'maps/performance.json',
        ),
        for (final extent in <int>[128, 256, 512, 1024])
          ProjectMapEntry(
            id: 'collision-$extent',
            name: 'Collision $extent',
            relativePath: 'maps/collision-$extent.json',
          ),
      ],
      tilesets: <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'profile-tiles',
          name: 'Profile tiles',
          relativePath: 'tilesets/profile.png',
          source: ProjectRegularAtlasTilesetSource(
            assetId: 'profile.png',
            pixelWidth: 128,
            pixelHeight: 48,
            tileWidth: 32,
            tileHeight: 32,
          ),
        ),
      ],
      elementCategories: <ProjectElementCategory>[
        ProjectElementCategory(id: 'profile', name: 'Profile'),
      ],
      elements: <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'profile-marker',
          name: 'Profile marker',
          tilesetId: 'profile-tiles',
          categoryId: 'profile',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            ),
          ],
        ),
      ],
    );
    final map = MapData(
      id: 'performance',
      name: 'Performance',
      size: const GridSize(width: 64, height: 64),
      layers: <MapLayer>[
        TileLayer(
          id: 'objects',
          name: 'Objects',
          cells: List<int>.filled(64 * 64, 0),
        ),
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
    await Directory(p.dirname(tilesetPath)).create(recursive: true);
    await File(tilesetPath).writeAsBytes(tilesetBytes, flush: true);
    final persistedTileset = await File(tilesetPath).readAsBytes();
    final codec = await ui.instantiateImageCodec(persistedTileset);
    final frame = await codec.getNextFrame();
    if (frame.image.width != 128 || frame.image.height != 48) {
      frame.image.dispose();
      codec.dispose();
      throw StateError('Performance fixture tileset must decode as 128x48.');
    }
    frame.image.dispose();
    codec.dispose();
    final collisionMaps = <MapData>[];
    for (final extent in <int>[128, 256, 512, 1024]) {
      final collisionMap = MapData(
        id: 'collision-$extent',
        name: 'Collision $extent',
        size: GridSize(width: extent, height: extent),
        layers: <MapLayer>[
          CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: List<bool>.filled(extent * extent, false),
          ),
        ],
      );
      collisionMaps.add(collisionMap);
      await FileMapRepository().saveMap(
        collisionMap,
        p.join(root.path, 'maps', 'collision-$extent.json'),
        projectDialogueContext: manifest,
      );
    }
    return _EditorPerformanceFixture(
      root: root,
      manifestPath: manifestPath,
      fingerprint: sha256
          .convert(
            utf8.encode(
              jsonEncode(<String, Object?>{
                'project': manifest.toJson(),
                'map': map.toJson(),
                'collisionMaps': collisionMaps
                    .map((collisionMap) => collisionMap.toJson())
                    .toList(growable: false),
                'tilesetSha256': sha256.convert(tilesetBytes).toString(),
              }),
            ),
          )
          .toString(),
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}
