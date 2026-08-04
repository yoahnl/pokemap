// This executable is a Flutter test harness stored under tool/ so normal test
// discovery does not run a multi-extent benchmark. It intentionally consumes
// the painter's test-only profiling snapshot.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

import '../../../../tools/performance/benchmark_support.dart';
import '../../../../tools/performance/smart_tiles_performance_policy.dart';
import '../../../../tools/performance/smart_tiles_rich_map_fixture.dart';

const _viewportSize = Size(1280, 720);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes rich Smart Tiles editor navigation evidence', () async {
    final config = _EditorBenchmarkConfig.fromEnvironment();
    final results = <Map<String, Object?>>[];
    for (final extent in config.extents) {
      final firstPaints = <_PaintMeasurement>[];
      for (var index = 0; index < config.samples; index += 1) {
        final fixture = generateSmartTilesRichMapFixture(extent: extent);
        firstPaints.add(
          _paint(
            fixture,
            navigation: _Navigation.centered(extent, zoom: 1),
          ),
        );
      }

      final fixture = generateSmartTilesRichMapFixture(extent: extent);
      final navigations = _Navigation.campaign(extent);
      for (var index = 0; index < config.warmups; index += 1) {
        _paint(fixture, navigation: navigations[index % navigations.length]);
      }
      final stablePaints = <_PaintMeasurement>[];
      for (var index = 0; index < config.samples; index += 1) {
        for (final navigation in navigations) {
          stablePaints.add(_paint(fixture, navigation: navigation));
        }
      }
      final workCounts = _maximumWorkCounts(stablePaints);
      final violations = smartTilesWorkBudgetViolations(
        actual: workCounts,
        budget: smartTilesEditorNavigationWorkBudget,
      );
      expect(violations, isEmpty, reason: violations.join('; '));
      results.add(<String, Object?>{
        'extent': extent,
        'fixtureChecksum': fixture.structuralChecksum,
        'rssBytesAfterSamples': ProcessInfo.currentRss,
        'workCounts': workCounts,
        'profiles': <String, Object?>{
          'firstPaint': _paintProfile(firstPaints),
          'stableNavigation': _paintProfile(stablePaints),
        },
      });
    }

    final receipt = await performanceReceipt(
      benchmark: 'smart_tiles_rich_editor_scaling',
      warmups: config.warmups,
      sampleCount: config.samples,
      arguments: const <String>[
        'flutter',
        'test',
        'tool/performance/smart_tiles_rich_editor_scaling_test.dart',
      ],
      metadata: <String, Object?>{
        'extents': config.extents,
        'viewportPixels': <String, Object?>{
          'width': _viewportSize.width.toInt(),
          'height': _viewportSize.height.toInt(),
        },
        'navigationSamplesPerExtent':
            config.samples * _Navigation.campaign(128).length,
        'portableWorkBudget': smartTilesEditorNavigationWorkBudget,
      },
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: config.outputPath,
      packageName: 'map_editor',
      receipt: receipt,
    );
  }, timeout: const Timeout(Duration(minutes: 30)));
}

_PaintMeasurement _paint(
  SmartTilesRichMapFixture fixture, {
  required _Navigation navigation,
}) {
  MapGridCullingDebugSnapshot? snapshot;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final stopwatch = Stopwatch()..start();
  MapGridPainter(
    map: fixture.map,
    zoom: navigation.zoom,
    offset: navigation.offset,
    tileWidth: 32,
    tileHeight: 32,
    tilesetImagesById: const <String, ui.Image?>{},
    sourceTileWidth: 32,
    sourceTileHeight: 32,
    tilesPerRowById: const <String, int>{},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    project: fixture.manifest,
    showGrid: true,
    showEditorOverlays: false,
    debugOnCulling: (value) => snapshot = value,
  ).paint(canvas, _viewportSize);
  stopwatch.stop();
  recorder.endRecording().dispose();
  final captured = snapshot;
  if (captured == null) {
    throw StateError('Editor paint profile was not emitted.');
  }
  return _PaintMeasurement(
    elapsedUs: stopwatch.elapsedMicroseconds,
    workCounts: _workCounts(captured),
  );
}

Map<String, Object?> _paintProfile(List<_PaintMeasurement> measurements) =>
    <String, Object?>{
      ...percentileFields(
        measurements
            .map((measurement) => measurement.elapsedUs)
            .toList(growable: false),
      ),
      'checksum': stableFingerprint(<String, Object?>{
        'samples': <Object?>[
          for (final measurement in measurements) measurement.workCounts,
        ],
      }),
    };

Map<String, int> _workCounts(MapGridCullingDebugSnapshot snapshot) =>
    <String, int>{
      'visibleCell': snapshot.visibleBounds.cellCount,
      'tile': snapshot.tileCellVisits,
      'collision': snapshot.collisionCellVisits,
      'smartOwner': snapshot.smartTileOwnerCellVisits,
      'smartPattern': snapshot.smartTilePatternStrokeCellVisits,
      'objectCandidate': snapshot.objectTileCandidateVisits,
      'objectVisualCache': snapshot.objectVisualDefinitionCacheSize,
      'gridLine': snapshot.gridLineVisits,
    };

Map<String, int> _maximumWorkCounts(List<_PaintMeasurement> measurements) {
  final maximums = <String, int>{};
  for (final measurement in measurements) {
    for (final entry in measurement.workCounts.entries) {
      final current = maximums[entry.key];
      if (current == null || entry.value > current) {
        maximums[entry.key] = entry.value;
      }
    }
  }
  return maximums;
}

final class _PaintMeasurement {
  const _PaintMeasurement({required this.elapsedUs, required this.workCounts});

  final int elapsedUs;
  final Map<String, int> workCounts;
}

final class _Navigation {
  const _Navigation({required this.zoom, required this.offset});

  final double zoom;
  final Offset offset;

  factory _Navigation.centered(int extent, {required double zoom}) {
    final visibleWidth = _viewportSize.width / (32 * zoom);
    final visibleHeight = _viewportSize.height / (32 * zoom);
    final left = (extent - visibleWidth) / 2;
    final top = (extent - visibleHeight) / 2;
    return _Navigation(
      zoom: zoom,
      offset: Offset(-left * 32 * zoom, -top * 32 * zoom),
    );
  }

  static List<_Navigation> campaign(int extent) => <_Navigation>[
        const _Navigation(zoom: 1, offset: Offset(-8 * 32, -8 * 32)),
        _Navigation.centered(extent, zoom: 0.75),
        _Navigation.centered(extent, zoom: 1),
        _Navigation.centered(extent, zoom: 2),
        _Navigation(
          zoom: 1,
          offset: Offset(
            -(extent - 48).clamp(0, extent) * 32,
            -(extent - 32).clamp(0, extent) * 32,
          ),
        ),
      ];
}

final class _EditorBenchmarkConfig {
  const _EditorBenchmarkConfig({
    required this.warmups,
    required this.samples,
    required this.extents,
    required this.outputPath,
  });

  final int warmups;
  final int samples;
  final List<int> extents;
  final String outputPath;

  factory _EditorBenchmarkConfig.fromEnvironment() {
    final environment = Platform.environment;
    final warmups = _nonNegativeInt(
      environment['POKEMAP_STN11_WARMUPS'],
      fallback: 2,
      label: 'POKEMAP_STN11_WARMUPS',
    );
    final samples = _positiveInt(
      environment['POKEMAP_STN11_SAMPLES'],
      fallback: 5,
      label: 'POKEMAP_STN11_SAMPLES',
    );
    final extents = <int>[
      for (final token in (environment['POKEMAP_STN11_EXTENTS'] ??
              smartTilesRichMapExtents.join(','))
          .split(','))
        _positiveInt(token, fallback: -1, label: 'POKEMAP_STN11_EXTENTS'),
    ];
    if (extents.any((extent) => !smartTilesRichMapExtents.contains(extent))) {
      throw FormatException(
        'POKEMAP_STN11_EXTENTS must use '
        '${smartTilesRichMapExtents.join(', ')}',
      );
    }
    return _EditorBenchmarkConfig(
      warmups: warmups,
      samples: samples,
      extents: List<int>.unmodifiable(extents),
      outputPath: environment['POKEMAP_STN11_OUTPUT'] ??
          'build/performance/stn11_editor.json',
    );
  }
}

int _nonNegativeInt(String? source,
    {required int fallback, required String label}) {
  final value = int.tryParse(source ?? '$fallback');
  if (value == null || value < 0) throw FormatException('$label is invalid');
  return value;
}

int _positiveInt(String? source,
    {required int fallback, required String label}) {
  final value = int.tryParse(source ?? '$fallback');
  if (value == null || value <= 0) throw FormatException('$label is invalid');
  return value;
}
