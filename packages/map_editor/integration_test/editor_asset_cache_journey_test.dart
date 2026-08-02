import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/widgets/environment_element_thumbnail.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');
const _target = 'integration_test/editor_asset_cache_journey_test.dart';
const _assetCount = 100;
const _sourceImageCount = 10;
const _tilesPerSource = _assetCount ~/ _sourceImageCount;
const _cycleCount = 10;
const _duplicateCallers = 8;
const _cacheBudgetBytes = 512 * 1024;
const _memoryGrowthBudgetBytes = 50 * 1024 * 1024;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'profiles the project-scoped asset cache on macOS',
    (tester) async {
      final fixture = await _AssetCachePerformanceFixture.create();
      addTearDown(fixture.dispose);
      final timings = <FrameTiming>[];
      void captureTimings(List<FrameTiming> batch) => timings.addAll(batch);
      var timingsCallbackRegistered = false;

      await tester.pumpWidget(const CupertinoApp(home: SizedBox.shrink()));
      for (var index = 0; index < 3; index++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      SchedulerBinding.instance.addTimingsCallback(captureTimings);
      timingsCallbackRegistered = true;
      addTearDown(
        () {
          if (!timingsCallbackRegistered) return;
          SchedulerBinding.instance.removeTimingsCallback(captureTimings);
          timingsCallbackRegistered = false;
        },
      );

      final rssBeforeJourney = ProcessInfo.currentRss;
      final cycles = <Map<String, Object?>>[];
      var peakEstimatedDecodedBytes = 0;
      for (var cycle = 0; cycle < _cycleCount; cycle++) {
        final projectIndex = cycle % fixture.projectCount;
        final project = fixture.project(projectIndex);
        final cache = EditorImageCache(
          sessionKey: project.sessionKey,
          maximumDecodedBytes: _cacheBudgetBytes,
        );
        final rssBeforeCycle = ProcessInfo.currentRss;
        final stopwatch = Stopwatch()..start();

        Map<String, Object?>? duplicateEvidence;
        if (cycle == 0) {
          final duplicateResults = await Future.wait([
            for (var caller = 0; caller < _duplicateCallers; caller++)
              cache.load(project.assetPaths.first),
          ]);
          expect(
            duplicateResults.every((result) => result.image != null),
            isTrue,
          );
          for (final result in duplicateResults) {
            result.dispose();
          }
          final diagnostics = cache.diagnostics;
          duplicateEvidence = <String, Object?>{
            'callers': _duplicateCallers,
            'hits': diagnostics.hits,
            'misses': diagnostics.misses,
            'inFlightLoads': diagnostics.inFlightLoads,
          };
          expect(diagnostics.misses, 1);
          expect(diagnostics.hits, _duplicateCallers - 1);
          expect(diagnostics.inFlightLoads, 0);
        }

        await tester.pumpWidget(
          _AssetThumbnailJourney(
            cycle: cycle,
            project: project,
            cache: cache,
          ),
        );
        await _pumpUntilLoaded(
          tester,
          cache: cache,
          cycle: cycle,
        );

        expect(find.byType(RawImage), findsNWidgets(_assetCount));
        expect(find.byKey(ValueKey('missing-$cycle')), findsOneWidget);
        final firstPixel = await _firstPixelRgba(
          cache,
          project.assetPaths.first,
        );
        expect(firstPixel, project.firstPixelRgba);

        final loadedDiagnostics = cache.diagnostics;
        peakEstimatedDecodedBytes =
            peakEstimatedDecodedBytes < loadedDiagnostics.peakDecodedBytes
                ? loadedDiagnostics.peakDecodedBytes
                : peakEstimatedDecodedBytes;
        expect(loadedDiagnostics.inFlightLoads, 0);
        expect(
          loadedDiagnostics.residentDecodedBytes,
          lessThanOrEqualTo(_cacheBudgetBytes),
        );
        expect(loadedDiagnostics.evictions, greaterThan(0));
        expect(loadedDiagnostics.missingFiles, 1);
        final rssLoaded = ProcessInfo.currentRss;

        await tester.pumpWidget(
          const CupertinoApp(home: SizedBox.shrink()),
        );
        await tester.pump(const Duration(milliseconds: 16));
        cache.dispose();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        stopwatch.stop();

        final disposedDiagnostics = cache.diagnostics;
        expect(disposedDiagnostics.isDisposed, isTrue);
        expect(disposedDiagnostics.entries, 0);
        expect(disposedDiagnostics.residentDecodedBytes, 0);
        expect(disposedDiagnostics.inFlightLoads, 0);
        cycles.add(<String, Object?>{
          'cycle': cycle + 1,
          'project': project.label,
          'durationUs': stopwatch.elapsedMicroseconds,
          'rssBeforeBytes': rssBeforeCycle,
          'rssLoadedBytes': rssLoaded,
          'rssAfterReleaseBytes': ProcessInfo.currentRss,
          'maxRssBytes': ProcessInfo.maxRss,
          'firstPixelRgba': firstPixel,
          'expectedFirstPixelRgba': project.firstPixelRgba,
          'duplicateEvidence': duplicateEvidence,
          'loadedCache': _diagnosticsJson(loadedDiagnostics),
          'disposedCache': _diagnosticsJson(disposedDiagnostics),
        });
      }

      await tester.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      SchedulerBinding.instance.removeTimingsCallback(captureTimings);
      timingsCallbackRegistered = false;
      final frameMetrics = _frameMetrics(timings);
      expect(frameMetrics['frameCount'], greaterThan(0));
      expect(tester.takeException(), isNull);

      final stabilization = _memoryStabilization(cycles);
      expect(
        stabilization['withinBudget'],
        isTrue,
        reason: 'Released-cycle RSS must stabilize within 50 MiB or 10%.',
      );
      binding.reportData = <String, dynamic>{
        'schemaVersion': 2,
        'generatorVersion': 1,
        'benchmark': 'editor_asset_cache_journey',
        'target': _target,
        'requestedOutputPath': _requestedOutputPath,
        'executionMode': const bool.fromEnvironment('dart.vm.profile')
            ? 'flutter-profile'
            : 'flutter-debug',
        'fixture': 'synthetic-elements-two-projects-shared-tilesets-64x64',
        'fixtureFingerprint': fixture.fingerprint,
        'warmups': 3,
        'sampleCount': timings.length,
        'iterations': <String, Object?>{
          'assets': _assetCount,
          'sourceImages': _sourceImageCount,
          'duplicateCallers': _duplicateCallers,
          'missingFiles': _cycleCount,
          'cycles': _cycleCount,
          'projectSwitches': _cycleCount - 1,
        },
        'measurementScope': <String, Object?>{
          'flutterFrames': true,
          'renderedEnvironmentElementThumbnails': true,
          'projectScopedCaches': true,
          'buildAndRasterCombined': false,
          'forcedGarbageCollection': false,
        },
        'memory': <String, Object?>{
          'rssBeforeBytes': rssBeforeJourney,
          'rssAfterBytes': ProcessInfo.currentRss,
          'maxRssBytes': ProcessInfo.maxRss,
          'nativeImageBytes': null,
          'nativeImageAvailability':
              'No stable Flutter profile API attributes native CPU/GPU image '
                  'allocations to EditorImageCache.',
          'estimatedResidentDecodedBytes': peakEstimatedDecodedBytes,
          'estimatedResidentDecodedBytesMethod':
              'EditorImageCache sum(width * height * 4); logical estimate, '
                  'not native allocation.',
        },
        'results': cycles,
        'memoryStabilization': stabilization,
        'frameMetrics': frameMetrics,
        'thresholdPolicy': <String, Object?>{
          'frameTimingsObservationOnly': true,
          'memoryGateBytes': _memoryGrowthBudgetBytes,
          'memoryGateRatio': 0.10,
          'memoryGateRequiresEachProcess': true,
        },
      };
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

Future<void> _pumpUntilLoaded(
  WidgetTester tester, {
  required EditorImageCache cache,
  required int cycle,
}) async {
  for (var frame = 0; frame < 300; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (cache.diagnostics.inFlightLoads == 0 &&
        find.byType(RawImage).evaluate().length == _assetCount &&
        find.byKey(ValueKey('missing-$cycle')).evaluate().length == 1) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw StateError(
    'Asset cache cycle ${cycle + 1} did not settle within 300 frames: '
    '${_diagnosticsJson(cache.diagnostics)}',
  );
}

Future<List<int>> _firstPixelRgba(
  EditorImageCache cache,
  String path,
) async {
  final result = await cache.load(path);
  final image = result.image;
  if (image == null) {
    throw StateError(
        'Unable to decode the project-switch probe: ${result.failure}');
  }
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null || data.lengthInBytes < 4) {
      throw StateError('The project-switch probe returned no RGBA bytes.');
    }
    return data.buffer.asUint8List(data.offsetInBytes, 4).toList();
  } finally {
    result.dispose();
  }
}

Map<String, Object?> _diagnosticsJson(
  EditorImageCacheDiagnostics diagnostics,
) =>
    <String, Object?>{
      'entries': diagnostics.entries,
      'hits': diagnostics.hits,
      'misses': diagnostics.misses,
      'invalidations': diagnostics.invalidations,
      'missingFiles': diagnostics.missingFiles,
      'readFailures': diagnostics.readFailures,
      'decodeFailures': diagnostics.decodeFailures,
      'disposedImages': diagnostics.disposedImages,
      'maximumDecodedBytes': diagnostics.maximumDecodedBytes,
      'residentDecodedBytes': diagnostics.residentDecodedBytes,
      'peakDecodedBytes': diagnostics.peakDecodedBytes,
      'evictions': diagnostics.evictions,
      'inFlightLoads': diagnostics.inFlightLoads,
      'isDisposed': diagnostics.isDisposed,
    };

Map<String, Object?> _memoryStabilization(
  List<Map<String, Object?>> cycles,
) {
  final released = cycles
      .map((cycle) => cycle['rssAfterReleaseBytes']! as int)
      .toList(growable: false);
  final earlyMedian = _median(released.take(3).toList());
  final lateMedian = _median(released.skip(released.length - 3).toList());
  final growth = lateMedian - earlyMedian;
  final growthRatio = earlyMedian == 0 ? 0.0 : growth / earlyMedian;
  return <String, Object?>{
    'earlyCycles': const <int>[1, 2, 3],
    'lateCycles': const <int>[8, 9, 10],
    'earlyMedianRssBytes': earlyMedian,
    'lateMedianRssBytes': lateMedian,
    'growthBytes': growth,
    'growthRatio': growthRatio,
    'withinByteBudget': growth <= _memoryGrowthBudgetBytes,
    'withinRatioBudget': growthRatio <= 0.10,
    'withinBudget': growth <= _memoryGrowthBudgetBytes || growthRatio <= 0.10,
  };
}

int _median(List<int> values) {
  final sorted = List<int>.of(values)..sort();
  return sorted[sorted.length ~/ 2];
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

final class _AssetThumbnailJourney extends StatelessWidget {
  const _AssetThumbnailJourney({
    required this.cycle,
    required this.project,
    required this.cache,
  });

  final int cycle;
  final _AssetProjectFixture project;
  final EditorImageCache cache;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: SingleChildScrollView(
          child: Wrap(
            children: <Widget>[
              for (var index = 0; index < _assetCount; index++)
                EnvironmentElementThumbnail(
                  manifest: project.manifest,
                  element: project.elements[index],
                  elementId: project.elements[index].id,
                  resolveTilesetPathById: project.resolveTilesetPath,
                  projectRootPath: project.sessionKey,
                  imageCache: cache,
                  size: 32,
                  previewKey: ValueKey('preview-$cycle-$index'),
                  fallbackKey: ValueKey('unexpected-fallback-$cycle-$index'),
                ),
              EnvironmentElementThumbnail(
                manifest: project.manifest,
                element: project.missingElement,
                elementId: project.missingElement.id,
                resolveTilesetPathById: project.resolveTilesetPath,
                projectRootPath: project.sessionKey,
                imageCache: cache,
                size: 32,
                previewKey: ValueKey('unexpected-missing-preview-$cycle'),
                fallbackKey: ValueKey('missing-$cycle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _AssetCachePerformanceFixture {
  const _AssetCachePerformanceFixture({
    required this.root,
    required this.projects,
    required this.fingerprint,
  });

  final Directory root;
  final List<_AssetProjectFixture> projects;
  final String fingerprint;

  int get projectCount => projects.length;

  _AssetProjectFixture project(int index) => projects[index];

  static Future<_AssetCachePerformanceFixture> create() async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap-rm08-assets-',
    );
    final projects = <_AssetProjectFixture>[];
    final fixtureHashes = <String>[];
    for (var projectIndex = 0; projectIndex < 2; projectIndex++) {
      final directory = await Directory(
        '${root.path}/project_${projectIndex == 0 ? 'a' : 'b'}',
      ).create();
      final assetPaths = <String>[];
      final elements = <ProjectElementEntry>[];
      final pathByTilesetId = <String, String>{};
      for (var sourceIndex = 0;
          sourceIndex < _sourceImageCount;
          sourceIndex++) {
        final tilesetId = 'tileset-$sourceIndex';
        final bytes = _tilesetPng(projectIndex, sourceIndex);
        final path = '${directory.path}/$tilesetId.png';
        await File(path).writeAsBytes(bytes, flush: true);
        assetPaths.add(path);
        pathByTilesetId[tilesetId] = path;
        fixtureHashes.add(sha256.convert(bytes).toString());
        for (var tileIndex = 0; tileIndex < _tilesPerSource; tileIndex++) {
          final assetIndex = sourceIndex * _tilesPerSource + tileIndex;
          elements.add(
            ProjectElementEntry(
              id: 'element-$assetIndex',
              name: 'Element $assetIndex',
              tilesetId: tilesetId,
              categoryId: 'profile',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  tilesetId: tilesetId,
                  source: TilesetSourceRect(x: tileIndex, y: 0),
                ),
              ],
            ),
          );
        }
      }
      const missingTilesetId = 'missing';
      pathByTilesetId[missingTilesetId] = '${directory.path}/missing.png';
      const missingElement = ProjectElementEntry(
        id: 'missing-element',
        name: 'Missing element',
        tilesetId: missingTilesetId,
        categoryId: 'profile',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            tilesetId: missingTilesetId,
            source: TilesetSourceRect(x: 0, y: 0),
          ),
        ],
      );
      final manifest = ProjectManifest(
        name: 'RM-08 project ${projectIndex == 0 ? 'A' : 'B'}',
        settings: const ProjectSettings(tileWidth: 64, tileHeight: 64),
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        elements: elements,
      );
      projects.add(
        _AssetProjectFixture(
          label: projectIndex == 0 ? 'A' : 'B',
          sessionKey: directory.path,
          manifest: manifest,
          elements: elements,
          missingElement: missingElement,
          assetPaths: assetPaths,
          pathByTilesetId: pathByTilesetId,
          firstPixelRgba: _pixel(projectIndex, 0),
        ),
      );
    }
    return _AssetCachePerformanceFixture(
      root: root,
      projects: projects,
      fingerprint:
          sha256.convert(utf8.encode(jsonEncode(fixtureHashes))).toString(),
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _AssetProjectFixture {
  const _AssetProjectFixture({
    required this.label,
    required this.sessionKey,
    required this.manifest,
    required this.elements,
    required this.missingElement,
    required this.assetPaths,
    required this.pathByTilesetId,
    required this.firstPixelRgba,
  });

  final String label;
  final String sessionKey;
  final ProjectManifest manifest;
  final List<ProjectElementEntry> elements;
  final ProjectElementEntry missingElement;
  final List<String> assetPaths;
  final Map<String, String> pathByTilesetId;
  final List<int> firstPixelRgba;

  String? resolveTilesetPath(String tilesetId) => pathByTilesetId[tilesetId];
}

Uint8List _tilesetPng(int projectIndex, int sourceIndex) {
  final image = img.Image(width: 64 * _tilesPerSource, height: 64);
  for (var tileIndex = 0; tileIndex < _tilesPerSource; tileIndex++) {
    final assetIndex = sourceIndex * _tilesPerSource + tileIndex;
    final rgba = _pixel(projectIndex, assetIndex);
    for (var y = 0; y < 64; y++) {
      for (var x = tileIndex * 64; x < (tileIndex + 1) * 64; x++) {
        image.setPixelRgba(x, y, rgba[0], rgba[1], rgba[2], rgba[3]);
      }
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

List<int> _pixel(int projectIndex, int assetIndex) => <int>[
      projectIndex == 0 ? (17 + assetIndex) % 255 : (211 + assetIndex) % 255,
      projectIndex == 0
          ? (101 + assetIndex * 3) % 255
          : (47 + assetIndex * 3) % 255,
      projectIndex == 0
          ? (203 + assetIndex * 7) % 255
          : (89 + assetIndex * 7) % 255,
      255,
    ];
