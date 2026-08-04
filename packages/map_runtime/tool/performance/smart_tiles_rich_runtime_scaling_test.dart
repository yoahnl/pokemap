// This executable is a Flutter test harness stored under tool/ so normal test
// discovery does not run a multi-extent benchmark. It intentionally consumes
// the runtime component's test-only profiling snapshot.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import '../../../../tools/performance/benchmark_support.dart';
import '../../../../tools/performance/smart_tiles_performance_policy.dart';
import '../../../../tools/performance/smart_tiles_rich_map_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes rich Smart Tiles runtime loading and frame evidence', () async {
    final config = _RuntimeBenchmarkConfig.fromEnvironment();
    final results = <Map<String, Object?>>[];
    for (final extent in config.extents) {
      final fixture = generateSmartTilesRichMapFixture(extent: extent);
      final root = await Directory.systemTemp.createTemp(
        'pokemap-stn11-runtime-$extent-',
      );
      try {
        await Directory('${root.path}/maps').create(recursive: true);
        await File('${root.path}/project.json').writeAsString(
          jsonEncode(fixture.manifest.toJson()),
          flush: true,
        );
        await File('${root.path}/maps/${fixture.map.id}.json').writeAsString(
          jsonEncode(fixture.map.toJson()),
          flush: true,
        );

        for (var index = 0; index < config.warmups; index += 1) {
          await loadRuntimeMapBundle(
            projectFilePath: '${root.path}/project.json',
            mapId: fixture.map.id,
          );
        }
        final loadProfiles = <RuntimeMapBundleLoadProfile>[];
        RuntimeMapBundle? loadedBundle;
        for (var index = 0; index < config.samples; index += 1) {
          RuntimeMapBundleLoadProfile? profile;
          loadedBundle = await loadRuntimeMapBundle(
            projectFilePath: '${root.path}/project.json',
            mapId: fixture.map.id,
            profileSink: (value) => profile = value,
          );
          loadProfiles.add(profile!);
        }
        final bundle = loadedBundle!;

        final componentBuildUs = <int>[];
        final firstFrames = <MapLayersRenderProfile>[];
        for (var index = 0; index < config.samples; index += 1) {
          final profiles = <MapLayersRenderProfile>[];
          final buildStopwatch = Stopwatch()..start();
          final component = _component(bundle, profiles);
          buildStopwatch.stop();
          componentBuildUs.add(buildStopwatch.elapsedMicroseconds);
          component.setVisibleLocalRect(_Navigation.centered(extent).rect);
          firstFrames.add(_render(component, profiles));
        }

        final stableFrames = <MapLayersRenderProfile>[];
        final stableComponent = _component(bundle, stableFrames);
        final navigations = _Navigation.campaign(extent);
        for (var index = 0; index < config.warmups + 1; index += 1) {
          stableComponent.setVisibleLocalRect(
            navigations[index % navigations.length].rect,
          );
          _render(stableComponent, stableFrames);
        }
        stableFrames.clear();
        for (var index = 0; index < config.samples; index += 1) {
          for (final navigation in navigations) {
            stableComponent.setVisibleLocalRect(navigation.rect);
            _render(stableComponent, stableFrames);
          }
        }
        final workCounts = _maximumWorkCounts(stableFrames);
        final violations = smartTilesWorkBudgetViolations(
          actual: workCounts,
          budget: smartTilesRuntimeNavigationWorkBudget,
        );
        expect(violations, isEmpty, reason: violations.join('; '));
        results.add(<String, Object?>{
          'extent': extent,
          'fixtureChecksum': fixture.structuralChecksum,
          'rssBytesAfterSamples': ProcessInfo.currentRss,
          'workCounts': workCounts,
          'profiles': <String, Object?>{
            'bundleLoad': _loadProfile(loadProfiles),
            'manifestLoad': _loadPhaseProfile(
              loadProfiles,
              (profile) => profile.manifestLoadMicroseconds,
            ),
            'mapLoad': _loadPhaseProfile(
              loadProfiles,
              (profile) => profile.mapLoadMicroseconds,
            ),
            'tilesetResolution': _loadPhaseProfile(
              loadProfiles,
              (profile) => profile.tilesetResolutionMicroseconds,
            ),
            'componentBuild': <String, Object?>{
              ...percentileFields(componentBuildUs),
              'checksum': fixture.structuralChecksum,
            },
            'firstFrame': _frameProfile(firstFrames),
            'stableNavigation': _frameProfile(stableFrames),
          },
        });
      } finally {
        if (await root.exists()) await root.delete(recursive: true);
      }
    }

    final receipt = await performanceReceipt(
      benchmark: 'smart_tiles_rich_runtime_scaling',
      warmups: config.warmups,
      sampleCount: config.samples,
      arguments: const <String>[
        'flutter',
        'test',
        'tool/performance/smart_tiles_rich_runtime_scaling_test.dart',
      ],
      metadata: <String, Object?>{
        'extents': config.extents,
        'viewportCells': const <String, Object?>{
          'width': _Navigation.viewportWidth,
          'height': _Navigation.viewportHeight,
        },
        'navigationSamplesPerExtent':
            config.samples * _Navigation.campaign(128).length,
        'portableWorkBudget': smartTilesRuntimeNavigationWorkBudget,
      },
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: config.outputPath,
      packageName: 'map_runtime',
      receipt: receipt,
    );
  }, timeout: const Timeout(Duration(minutes: 30)));
}

MapLayersComponent _component(
  RuntimeMapBundle bundle,
  List<MapLayersRenderProfile> profiles,
) =>
    MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: const {},
      showCollisionOverlay: true,
      debugOnRenderProfile: profiles.add,
    );

MapLayersRenderProfile _render(
  MapLayersComponent component,
  List<MapLayersRenderProfile> profiles,
) {
  final before = profiles.length;
  component.update(1 / 60);
  final recorder = ui.PictureRecorder();
  component.render(Canvas(recorder));
  recorder.endRecording().dispose();
  if (profiles.length != before + 1) {
    throw StateError('Runtime render profile was not emitted exactly once.');
  }
  return profiles.last;
}

Map<String, Object?> _loadProfile(
  List<RuntimeMapBundleLoadProfile> profiles,
) =>
    _loadPhaseProfile(profiles, (profile) => profile.totalMicroseconds);

Map<String, Object?> _loadPhaseProfile(
  List<RuntimeMapBundleLoadProfile> profiles,
  int Function(RuntimeMapBundleLoadProfile profile) select,
) =>
    <String, Object?>{
      ...percentileFields(profiles.map(select).toList(growable: false)),
      'checksum': stableFingerprint(<String, Object?>{
        'mapCellCount': profiles.first.mapCellCount,
        'mapLayerCount': profiles.first.mapLayerCount,
        'resolvedTilesetPathCount': profiles.first.resolvedTilesetPathCount,
      }),
    };

Map<String, Object?> _frameProfile(List<MapLayersRenderProfile> profiles) =>
    <String, Object?>{
      ...percentileFields(
        profiles
            .map((profile) => profile.renderMicroseconds)
            .toList(growable: false),
      ),
      'checksum': stableFingerprint(<String, Object?>{
        'samples': <Object?>[
          for (final profile in profiles) _workCounts(profile),
        ],
      }),
    };

Map<String, int> _workCounts(MapLayersRenderProfile profile) => <String, int>{
      'visibleCell': profile.visibleCellCount,
      'tile': profile.tileCellVisits,
      'collision': profile.collisionCellVisits,
      'smartOwner': profile.smartTileOwnerCellVisits,
      'smartPattern': profile.smartTilePatternStrokeCellVisits,
      'objectCandidate': profile.objectTileCandidateVisits,
      'placedCandidate': profile.placedElementCandidateVisits,
      'entityCandidate': profile.entityCandidateVisits,
      'regularVisualCache': profile.regularTileVisualCacheSize,
      'objectVisualCache': profile.objectVisualDefinitionCacheSize,
    };

Map<String, int> _maximumWorkCounts(List<MapLayersRenderProfile> profiles) {
  final maximums = <String, int>{};
  for (final profile in profiles) {
    for (final entry in _workCounts(profile).entries) {
      final current = maximums[entry.key];
      if (current == null || entry.value > current) {
        maximums[entry.key] = entry.value;
      }
    }
  }
  return maximums;
}

final class _Navigation {
  const _Navigation(this.rect);

  static const viewportWidth = 40;
  static const viewportHeight = 23;

  final Rect rect;

  factory _Navigation.centered(int extent) {
    final left = ((extent - viewportWidth) / 2).clamp(0, extent).toDouble();
    final top = ((extent - viewportHeight) / 2).clamp(0, extent).toDouble();
    return _Navigation(
      Rect.fromLTWH(
        left * 32,
        top * 32,
        viewportWidth * 32,
        viewportHeight * 32,
      ),
    );
  }

  static List<_Navigation> campaign(int extent) => <_Navigation>[
        const _Navigation(
          Rect.fromLTWH(
              8 * 32, 8 * 32, viewportWidth * 32, viewportHeight * 32),
        ),
        _Navigation.centered(extent),
        _Navigation(
          Rect.fromLTWH(
            (extent - viewportWidth - 4).clamp(0, extent).toDouble() * 32,
            (extent - viewportHeight - 4).clamp(0, extent).toDouble() * 32,
            viewportWidth * 32,
            viewportHeight * 32,
          ),
        ),
      ];
}

final class _RuntimeBenchmarkConfig {
  const _RuntimeBenchmarkConfig({
    required this.warmups,
    required this.samples,
    required this.extents,
    required this.outputPath,
  });

  final int warmups;
  final int samples;
  final List<int> extents;
  final String outputPath;

  factory _RuntimeBenchmarkConfig.fromEnvironment() {
    final environment = Platform.environment;
    final warmups = _nonNegativeInt(
      environment['POKEMAP_STN11_WARMUPS'],
      fallback: 1,
      label: 'POKEMAP_STN11_WARMUPS',
    );
    final samples = _positiveInt(
      environment['POKEMAP_STN11_SAMPLES'],
      fallback: 3,
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
    return _RuntimeBenchmarkConfig(
      warmups: warmups,
      samples: samples,
      extents: List<int>.unmodifiable(extents),
      outputPath: environment['POKEMAP_STN11_OUTPUT'] ??
          'build/performance/stn11_runtime.json',
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
