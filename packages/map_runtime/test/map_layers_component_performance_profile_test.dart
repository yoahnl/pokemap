import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import '../../../tools/performance/smart_tiles_rich_map_fixture.dart';
import '../../../tools/performance/smart_tiles_performance_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('visible-frame work stays bounded from 128² to 1024²', () {
    List<MapLayersRenderProfile> render(int extent) {
      final fixture = generateSmartTilesRichMapFixture(extent: extent);
      final profiles = <MapLayersRenderProfile>[];
      final component = MapLayersComponent(
        bundle: RuntimeMapBundle(
          manifest: fixture.manifest,
          map: fixture.map,
          projectRootDirectory: '.',
          tilesetAbsolutePathsById: const <String, String>{},
        ),
        tileImagesByTilesetId: const {},
        showCollisionOverlay: true,
        debugOnRenderProfile: profiles.add,
      )..setVisibleLocalRect(
          const Rect.fromLTWH(11 * 32, 11 * 32, 3 * 32, 3 * 32),
        );
      for (var frame = 0; frame < 2; frame += 1) {
        final recorder = ui.PictureRecorder();
        component
          ..update(1 / 60)
          ..render(Canvas(recorder));
        recorder.endRecording().dispose();
      }
      return profiles;
    }

    final small = render(128);
    final large = render(1024);
    expect(small, hasLength(2));
    expect(large, hasLength(2));
    expect(small.first.isFirstFrame, isTrue);
    expect(small.last.isFirstFrame, isFalse);
    expect(large.first.totalMapCellCount, 1024 * 1024);
    expect(large.last.renderMicroseconds, isNonNegative);

    Map<String, int> boundedWork(MapLayersRenderProfile profile) =>
        <String, int>{
          'tile': profile.tileCellVisits,
          'collision': profile.collisionCellVisits,
          'smartOwner': profile.smartTileOwnerCellVisits,
          'smartPattern': profile.smartTilePatternStrokeCellVisits,
          'objectCandidate': profile.objectTileCandidateVisits,
          'placedCandidate': profile.placedElementCandidateVisits,
          'entityCandidate': profile.entityCandidateVisits,
        };
    expect(boundedWork(large.first), boundedWork(small.first));
    expect(boundedWork(large.last), boundedWork(small.last));
    expect(
      large.last.smartTileOwnerCellVisits,
      lessThan(large.last.totalMapCellCount),
    );
    expect(
      large.last.regularTileVisualCacheSize,
      lessThanOrEqualTo(large.last.regularTileVisualCacheCapacity),
    );
    expect(
      large.last.objectVisualDefinitionCacheSize,
      lessThanOrEqualTo(large.last.objectVisualDefinitionCacheCapacity),
    );
    expect(large.last.tilesetImageCount, 0);
    expect(
      smartTilesWorkBudgetViolations(
        actual: <String, int>{
          'visibleCell': large.last.visibleCellCount,
          'tile': large.last.tileCellVisits,
          'collision': large.last.collisionCellVisits,
          'smartOwner': large.last.smartTileOwnerCellVisits,
          'smartPattern': large.last.smartTilePatternStrokeCellVisits,
          'objectCandidate': large.last.objectTileCandidateVisits,
          'placedCandidate': large.last.placedElementCandidateVisits,
          'entityCandidate': large.last.entityCandidateVisits,
          'regularVisualCache': large.last.regularTileVisualCacheSize,
          'objectVisualCache': large.last.objectVisualDefinitionCacheSize,
        },
        budget: smartTilesRuntimeNavigationWorkBudget,
      ),
      isEmpty,
    );
  });
}
