import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
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

  test('authored 128x128 elements never expand into projection caches', () {
    final component = MapLayersComponent(
      bundle: _authoredLargeElementBundle(
        sourceSize: const GridSize(width: 128, height: 128),
        mapSize: const GridSize(width: 256, height: 256),
        filledTileLayer: true,
      ),
      tileImagesByTilesetId: const {},
    );

    expect(component.debugForegroundProjectionCellCount, 0);
    expect(component.debugAnimatedProjectionCellCount, 0);
  });

  test('large-map candidate work follows visible instances, not footprint', () {
    final profiles = <MapLayersRenderProfile>[];
    final component = MapLayersComponent(
      bundle: _authoredLargeElementBundle(
        sourceSize: const GridSize(width: 192, height: 192),
        mapSize: const GridSize(width: 4096, height: 256),
        instanceCount: 20,
      ),
      tileImagesByTilesetId: const {},
      debugOnRenderProfile: profiles.add,
    )..setVisibleLocalRect(const Rect.fromLTWH(0, 0, 32, 32));

    final recorder = ui.PictureRecorder();
    component.render(Canvas(recorder));
    recorder.endRecording().dispose();

    expect(profiles, hasLength(1));
    expect(profiles.single.placedElementCandidateVisits, 1);
    expect(component.debugForegroundProjectionCellCount, 0);
    expect(component.debugAnimatedProjectionCellCount, 0);
  });

  test('tile-index compatibility placements retain their projected cells', () {
    final component = MapLayersComponent(
      bundle: _authoredLargeElementBundle(
        sourceSize: const GridSize(width: 2, height: 2),
        mapSize: const GridSize(width: 4, height: 4),
        filledTileLayer: true,
        placementOrigin: pokemapPlacementOriginTileIndex,
      ),
      tileImagesByTilesetId: const {},
    );

    expect(component.debugForegroundProjectionCellCount, 3);
    expect(component.debugAnimatedProjectionCellCount, 4);
  });
}

RuntimeMapBundle _authoredLargeElementBundle({
  required GridSize sourceSize,
  required GridSize mapSize,
  bool filledTileLayer = false,
  int instanceCount = 1,
  String placementOrigin = pokemapPlacementOriginAuthored,
}) {
  final cellCount = mapSize.width * mapSize.height;
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Authored large element performance',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'atlas',
          name: 'Atlas',
          relativePath: 'atlas.png',
        ),
      ],
      settings: const ProjectSettings(
        tileWidth: 1,
        tileHeight: 1,
        displayScale: 1,
      ),
      elements: <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'building',
          name: 'Building',
          tilesetId: 'atlas',
          categoryId: 'buildings',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(
                x: 0,
                y: 0,
                width: sourceSize.width,
                height: sourceSize.height,
              ),
            ),
            TilesetVisualFrame(
              source: TilesetSourceRect(
                x: 0,
                y: sourceSize.height,
                width: sourceSize.width,
                height: sourceSize.height,
              ),
            ),
          ],
          collisionProfile: const ElementCollisionProfile(
            cells: <GridPos>[GridPos(x: 0, y: 0)],
          ),
        ),
      ],
    ),
    map: MapData(
      id: 'large-performance-map',
      name: 'Large performance map',
      size: mapSize,
      layers: <MapLayer>[
        MapLayer.tile(
          id: 'decor',
          name: 'Decor',
          palette: const <TileLayerPaletteEntry>[
            TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0),
          ],
          cells:
              filledTileLayer ? List<int>.filled(cellCount, 1) : const <int>[],
        ),
      ],
      placedElements: <MapPlacedElement>[
        for (var index = 0; index < instanceCount; index += 1)
          MapPlacedElement(
            id: 'building-$index',
            layerId: 'decor',
            elementId: 'building',
            pos: GridPos(x: index * 200, y: 0),
            properties: <String, String>{
              pokemapPlacementOriginProperty: placementOrigin,
            },
          ),
      ],
    ),
    projectRootDirectory: '/tmp/large-element-performance',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}
