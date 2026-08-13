import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
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
import 'package:path/path.dart' as p;

import '../test_driver/performance_driver.dart' as performance_driver;
import 'support/vm_memory_probe.dart';

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');
const _extendedSoakMinutes = int.fromEnvironment('POKEMAP_PERF_SOAK_MINUTES');
const _minimumPaintUndoCycles = 10;
const _paintedCellsPerCycle = 100;
const _largeProjectPlacedElements = 10000;
const _largeProjectSaveCycles = 5;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profiles bounded paint undo and large project save soaks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixtureData = await rootBundle.load(
      'assets/cinematics/emotes/emotions.png',
    );
    final fixture = await _EditorPerformanceSoakFixture.create(
      fixtureData.buffer.asUint8List(
        fixtureData.offsetInBytes,
        fixtureData.lengthInBytes,
      ),
    );
    addTearDown(fixture.dispose);
    final container = ProviderContainer(retry: disableAutomaticProviderRetry);
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final recorder = EditorPerformanceRecorder(maxSamplesPerSpan: 500000);
    final recording = EditorPerformanceTelemetry.startRecording(recorder);
    addTearDown(recording.close);
    final memoryProbe = await VmMemoryProbe.connect();
    addTearDown(memoryProbe.close);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MapEditorApp(
          enableEditorUpdateHost: false,
          restoreLastOpenedProjectOnStartup: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 48));
    await notifier.loadProject(fixture.manifestPath, rememberAsRecent: false);
    await tester.pump(const Duration(milliseconds: 16));
    await notifier.loadMap('maps/soak.json');
    await tester.pump(const Duration(milliseconds: 16));
    expect(notifier.state.activeMap?.placedElements, hasLength(10000));

    notifier.setActiveLayer('collision');
    notifier.selectTool(EditorToolType.collisionPaint);
    await tester.pump(const Duration(milliseconds: 16));

    final paintUndoBaseline = await memoryProbe.measure(() async {});
    final paintUndoCycles = <Map<String, Object?>>[];
    final extendedDuration = Duration(minutes: _extendedSoakMinutes);
    final extendedStopwatch = Stopwatch()..start();
    final paintUndoMemory = await memoryProbe.measure(() async {
      var cycle = 0;
      while (cycle < _minimumPaintUndoCycles ||
          (_extendedSoakMinutes > 0 &&
              extendedStopwatch.elapsed < extendedDuration)) {
        final cycleStopwatch = Stopwatch()..start();
        final beforePaint = recorder.snapshot();
        final paintStopwatch = Stopwatch()..start();
        notifier.beginMapStroke();
        for (var index = 0; index < _paintedCellsPerCycle; index += 1) {
          final cellIndex = (cycle * 103 + index) % (128 * 128);
          notifier.paintCollisionAt(
            GridPos(x: cellIndex % 128, y: cellIndex ~/ 128),
          );
        }
        notifier.endMapStroke();
        paintStopwatch.stop();
        await tester.pump(const Duration(milliseconds: 16));
        final paintInstrumentation = recorder.deltaSince(beforePaint);
        expect(
          paintInstrumentation.spanSamples(
            EditorPerformanceSpanName.mutationLocal,
          ),
          hasLength(_paintedCellsPerCycle + 1),
        );
        _expectZeroCounters(paintInstrumentation);

        final undoStopwatch = Stopwatch()..start();
        notifier.undoMap();
        undoStopwatch.stop();
        await tester.pump(const Duration(milliseconds: 16));
        final collisionLayer = notifier.state.activeMap!.layers
            .whereType<CollisionLayer>()
            .single;
        expect(collisionLayer.collisions.where((value) => value), isEmpty);
        expect(notifier.state.isDirty, isFalse);
        paintUndoCycles.add(<String, Object?>{
          'cycle': cycle + 1,
          'paintedCells': _paintedCellsPerCycle,
          'paintUs': paintStopwatch.elapsedMicroseconds,
          'undoUs': undoStopwatch.elapsedMicroseconds,
          'paintInstrumentation': paintInstrumentation.toJson(),
        });
        cycle += 1;
        cycleStopwatch.stop();
        if (_extendedSoakMinutes > 0 &&
            extendedStopwatch.elapsed < extendedDuration &&
            cycleStopwatch.elapsed < const Duration(seconds: 1)) {
          await Future<void>.delayed(
            const Duration(seconds: 1) - cycleStopwatch.elapsed,
          );
        }
      }
    });
    extendedStopwatch.stop();

    final largeProjectBaseline = await memoryProbe.measure(() async {});
    final largeProjectCycles = <Map<String, Object?>>[];
    late MapData reloadedMap;
    final largeProjectMemory = await memoryProbe.measure(() async {
      for (var cycle = 0; cycle < _largeProjectSaveCycles; cycle += 1) {
        final beforeMutation = recorder.snapshot();
        final mutationStopwatch = Stopwatch()..start();
        notifier.setPlacedElementInstanceCollisionApplied(
          instanceId: 'instance-$cycle',
          applyCollision: true,
        );
        mutationStopwatch.stop();
        final mutationInstrumentation = recorder.deltaSince(beforeMutation);
        expect(
          mutationInstrumentation.spanSamples(
            EditorPerformanceSpanName.statePublish,
          ),
          hasLength(1),
        );
        _expectZeroCounters(mutationInstrumentation);

        final beforeSave = recorder.snapshot();
        final saveStopwatch = Stopwatch()..start();
        final outcome = await notifier.saveActiveMap();
        saveStopwatch.stop();
        expect(outcome.name, 'saved');
        final saveInstrumentation = recorder.deltaSince(beforeSave);
        expect(
          saveInstrumentation.spanSamples(EditorPerformanceSpanName.saveQueue),
          hasLength(1),
        );
        expect(
          saveInstrumentation.spanSamples(EditorPerformanceSpanName.saveEncode),
          hasLength(1),
        );
        expect(
          saveInstrumentation.counter(
            EditorPerformanceCounterName.filesystemWrite,
          ),
          greaterThan(0),
        );
        expect(
          saveInstrumentation.counter(EditorPerformanceCounterName.jsonEncode),
          greaterThan(0),
        );
        largeProjectCycles.add(<String, Object?>{
          'cycle': cycle + 1,
          'mutationUs': mutationStopwatch.elapsedMicroseconds,
          'saveUs': saveStopwatch.elapsedMicroseconds,
          'mutationInstrumentation': mutationInstrumentation.toJson(),
          'saveInstrumentation': saveInstrumentation.toJson(),
        });
        await tester.pump(const Duration(milliseconds: 16));
      }
      reloadedMap = await FileMapRepository().loadMap(fixture.mapPath);
    });
    expect(reloadedMap.placedElements, hasLength(10000));
    for (var index = 0; index < _largeProjectSaveCycles; index += 1) {
      expect(reloadedMap.placedElements[index].applyCollision, isTrue);
    }

    final mutationSamples = <int>[
      for (final cycle in paintUndoCycles)
        ...((((cycle['paintInstrumentation']! as Map)['spans']!
                        as Map)[EditorPerformanceSpanName.mutationLocal]!
                    as Map)['samplesUs']!
                as List)
            .cast<int>(),
    ];
    final paintSamples = <int>[
      for (final cycle in paintUndoCycles) cycle['paintUs']! as int,
    ];
    final undoSamples = <int>[
      for (final cycle in paintUndoCycles) cycle['undoUs']! as int,
    ];
    final largeMutationSamples = <int>[
      for (final cycle in largeProjectCycles) cycle['mutationUs']! as int,
    ];
    final saveSamples = <int>[
      for (final cycle in largeProjectCycles) cycle['saveUs']! as int,
    ];
    final paintUndoGrowth =
        paintUndoMemory.heapAfterGcBytes - paintUndoBaseline.heapAfterGcBytes;
    final largeProjectGrowth =
        largeProjectMemory.heapAfterGcBytes -
        largeProjectBaseline.heapAfterGcBytes;
    final paintMutationMetrics = _metrics(mutationSamples);
    final paintMetrics = _metrics(paintSamples);
    final undoMetrics = _metrics(undoSamples);
    final largeMutationMetrics = _metrics(largeMutationSamples);
    final largeSaveMetrics = _metrics(saveSamples);
    if (const bool.fromEnvironment('dart.vm.profile')) {
      debugPrint(
        'PERF-009 scenario A mutation=${_metricsSummary(paintMutationMetrics)} '
        'paint=${_metricsSummary(paintMetrics)} '
        'undo=${_metricsSummary(undoMetrics)} '
        'heapGrowthBytes=$paintUndoGrowth; scenario C '
        'mutation=${_metricsSummary(largeMutationMetrics)} '
        'save=${_metricsSummary(largeSaveMetrics)} '
        'heapBaseline=${largeProjectBaseline.heapAfterGcBytes} '
        'heapAfter=${largeProjectMemory.heapAfterGcBytes} '
        'heapGrowthBytes=$largeProjectGrowth',
      );
    }

    final report = <String, dynamic>{
      'schemaVersion': 2,
      'generatorVersion': 1,
      'benchmark': 'editor_performance_soak',
      'target': 'integration_test/editor_performance_soak_journey_test.dart',
      'requestedOutputPath': _requestedOutputPath,
      'executionMode': const bool.fromEnvironment('dart.vm.profile')
          ? 'flutter-profile'
          : 'flutter-debug',
      'fixture': 'synthetic-128-map-with-10000-placed-elements',
      'fixtureFingerprint': fixture.fingerprint,
      'iterations': <String, Object?>{
        'paintUndoCycles': paintUndoCycles.length,
        'paintedCellsPerCycle': _paintedCellsPerCycle,
        'configuredExtendedSoakMinutes': _extendedSoakMinutes,
        'largeProjectPlacedElements': _largeProjectPlacedElements,
        'largeProjectSaveCycles': _largeProjectSaveCycles,
      },
      'performanceBudgets': <String, Object?>{
        'mutationP95Us': 8000,
        'undoP95Us': 50000,
        'largeProjectMutationP95Us': 16000,
        'largeProjectSaveP95Us': 5000000,
        'paintUndoHeapGrowthBytes': 32 * 1024 * 1024,
        'largeProjectHeapGrowthBytes': 64 * 1024 * 1024,
      },
      'scenarioA': <String, Object?>{
        'name': 'paint-undo',
        'extent': 128,
        'cycles': paintUndoCycles,
        'mutationMetrics': paintMutationMetrics,
        'paintMetrics': paintMetrics,
        'undoMetrics': undoMetrics,
        'memoryBaseline': paintUndoBaseline.toJson(),
        'memoryAfterSoak': paintUndoMemory.toJson(),
        'heapGrowthBytes': paintUndoGrowth,
      },
      'scenarioB': <String, Object?>{
        'companionTarget':
            'integration_test/editor_fine_mask_journey_test.dart',
        'requiredByCertificationGate': true,
      },
      'scenarioC': <String, Object?>{
        'name': 'large-project-save',
        'placedElementCount': _largeProjectPlacedElements,
        'saveCycles': _largeProjectSaveCycles,
        'cycles': largeProjectCycles,
        'mutationMetrics': largeMutationMetrics,
        'saveMetrics': largeSaveMetrics,
        'memoryBaseline': largeProjectBaseline.toJson(),
        'memoryAfterSoak': largeProjectMemory.toJson(),
        'heapGrowthBytes': largeProjectGrowth,
        'reloadedPlacedElementCount': reloadedMap.placedElements.length,
      },
    };
    performance_driver.validatePerformancePayload(report);
    binding.reportData = report;
  });
}

void _expectZeroCounters(EditorPerformanceSnapshot snapshot) {
  for (final counter in EditorPerformanceCounterName.all) {
    expect(snapshot.counter(counter), 0, reason: counter);
  }
}

Map<String, Object?> _metrics(List<int> samples) {
  final sorted = List<int>.of(samples)..sort();
  return <String, Object?>{
    'samplesUs': samples,
    'p50Us': _percentile(sorted, 0.50),
    'p95Us': _percentile(sorted, 0.95),
    'p99Us': _percentile(sorted, 0.99),
    'maxUs': sorted.last,
  };
}

String _metricsSummary(Map<String, Object?> metrics) {
  final samples = metrics['samplesUs']! as List<Object?>;
  return 'samples=${samples.length},p50Us=${metrics['p50Us']},'
      'p95Us=${metrics['p95Us']},p99Us=${metrics['p99Us']},'
      'maxUs=${metrics['maxUs']}';
}

int _percentile(List<int> sorted, double percentile) {
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

final class _EditorPerformanceSoakFixture {
  const _EditorPerformanceSoakFixture({
    required this.root,
    required this.manifestPath,
    required this.mapPath,
    required this.fingerprint,
  });

  final Directory root;
  final String manifestPath;
  final String mapPath;
  final String fingerprint;

  static Future<_EditorPerformanceSoakFixture> create(
    List<int> tilesetBytes,
  ) async {
    final root = await Directory.systemTemp.createTemp('pokemap-perf009-');
    final manifestPath = p.join(root.path, 'project.json');
    final mapPath = p.join(root.path, 'maps', 'soak.json');
    final tilesetPath = p.join(root.path, 'tilesets', 'profile.png');
    final manifest = ProjectManifest(
      name: 'PERF-009 soak fixture',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'soak',
          name: 'Soak',
          relativePath: 'maps/soak.json',
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
      elementCategories: const <ProjectElementCategory>[
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
      id: 'soak',
      name: 'Soak',
      size: const GridSize(width: 128, height: 128),
      layers: <MapLayer>[
        TileLayer(
          id: 'objects',
          name: 'Objects',
          cells: List<int>.filled(128 * 128, 0, growable: false),
        ),
        CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.filled(128 * 128, false, growable: false),
        ),
      ],
      placedElements: <MapPlacedElement>[
        for (var index = 0; index < _largeProjectPlacedElements; index += 1)
          MapPlacedElement(
            id: 'instance-$index',
            layerId: 'objects',
            elementId: 'profile-marker',
            pos: GridPos(x: index % 128, y: index ~/ 128),
            applyCollision: false,
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
    return _EditorPerformanceSoakFixture(
      root: root,
      manifestPath: manifestPath,
      mapPath: mapPath,
      fingerprint: sha256
          .convert(
            utf8.encode(
              jsonEncode(<String, Object?>{
                'project': manifest.toJson(),
                'map': map.toJson(),
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
