import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_shadow_preview_projection_index.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/canvas/map_canvas/editor_canvas_repaint_clock.dart';

import 'support/vm_memory_probe.dart';

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');
const _target = 'integration_test/editor_canvas_projection_journey_test.dart';
const _viewportSize = ui.Size(512, 512);
const _warmups = 8;
const _samples = 90;
const _extents = <int>[128, 256, 512, 1024];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'profiles visible standard smart shadow and combined canvas projections',
    (tester) async {
      final tileImage = await _solidTileImage();
      addTearDown(tileImage.dispose);
      final memoryProbe = await VmMemoryProbe.connect();
      addTearDown(memoryProbe.close);
      final results = <Map<String, Object?>>[];
      final placementResults = <Map<String, Object?>>[];
      final cachedRepaintResults = <Map<String, Object?>>[];

      final memory = await memoryProbe.measure(() async {
        for (final mode in _CanvasProfileMode.values) {
          for (final extent in _extents) {
            final fixture = _CanvasProfileFixture.create(
              mode: mode,
              extent: extent,
            );
            results.add(
              _measurePainter(fixture: fixture, tileImage: tileImage),
            );
            await tester.pump();
          }
        }
        for (final placedElementCount in const <int>[100, 1000, 10000]) {
          final fixture = _CanvasProfileFixture.create(
            mode: _CanvasProfileMode.shadows,
            extent: 1024,
            placedElementCount: placedElementCount,
          );
          final result = _measurePainter(
            fixture: fixture,
            tileImage: tileImage,
          );
          expect(result['placedElementCount'], placedElementCount);
          placementResults.add(result);
          await tester.pump();
        }
        for (final extent in _extents) {
          final fixture = _CanvasProfileFixture.create(
            mode: _CanvasProfileMode.combined,
            extent: extent,
          );
          cachedRepaintResults.add(
            _measureCachedRepaint(fixture: fixture, tileImage: tileImage),
          );
          await tester.pump();
        }
      });

      Map<String, Object?> resultFor(_CanvasProfileMode mode, int extent) =>
          results.singleWhere(
            (result) =>
                result['mode'] == mode.name && result['extent'] == extent,
          );

      final standard1024 = resultFor(_CanvasProfileMode.standard, 1024);
      final combined128 = resultFor(_CanvasProfileMode.combined, 128);
      final combined1024 = resultFor(_CanvasProfileMode.combined, 1024);
      final standard1024P95 = standard1024['p95Us']! as int;
      final combined128P95 = combined128['p95Us']! as int;
      final combined1024P95 = combined1024['p95Us']! as int;
      final cachedRepaint1024 = cachedRepaintResults.singleWhere(
        (result) => result['extent'] == 1024,
      );
      final cachedRepaint1024P95 = cachedRepaint1024['p95Us']! as int;
      final combinedScaleRatio =
          combined1024P95 / (combined128P95 == 0 ? 1 : combined128P95);

      binding.reportData = <String, dynamic>{
        'schemaVersion': 2,
        'generatorVersion': 1,
        'benchmark': 'editor_canvas_visible_projections',
        'target': _target,
        'requestedOutputPath': _requestedOutputPath,
        'executionMode': const bool.fromEnvironment('dart.vm.profile')
            ? 'flutter-profile'
            : 'flutter-debug',
        'fixture': 'synthetic-visible-projections-128-to-1024',
        'warmups': _warmups,
        'sampleCountPerModeAndExtent': _samples,
        'viewport': <String, int>{
          'widthPx': _viewportSize.width.toInt(),
          'heightPx': _viewportSize.height.toInt(),
          'tileWidthPx': 32,
          'tileHeightPx': 32,
        },
        'measurementScope': <String, Object?>{
          'metric': 'canvas.paint_recording',
          'includesGpuRaster': false,
          'includesLayoutAndComposition': false,
          'uiThreadCanvasRecord': true,
          'pictureRasterization': false,
          'shadowProjectionWarmupExcluded': true,
          'constantViewport': true,
          'cachedRepaintMetric': 'animation_tick.static_picture_reuse',
          'animationClockStepMs': 110,
          'staticPictureWarmupExcluded': true,
          'cacheMaxEntries': 64,
        },
        'results': results,
        'placementResults': placementResults,
        'cachedRepaintResults': cachedRepaintResults,
        'memory': memory.toJson(),
        'summary': <String, Object?>{
          'standard1024P95Us': standard1024P95,
          'combined128P95Us': combined128P95,
          'combined1024P95Us': combined1024P95,
          'combined1024To128P95Ratio': combinedScaleRatio,
          'cachedRepaint1024P95Us': cachedRepaint1024P95,
          'rssBytesAfterRun': ProcessInfo.currentRss,
        },
        'performanceGates': <String, Object?>{
          'combined1024P95BudgetUs': 8000,
          'repaintP95BudgetUs': 16670,
          'combined1024To128P95RatioBudget': 1.5,
          'standard1024P95ObservationCeilingUs': 4000,
          'cachedRepaint1024P95BudgetUs': 8000,
          'combined1024P95Pass': combined1024P95 < 8000,
          'repaintP95Pass': combined1024P95 < 16670,
          'combinedScaleRatioPass': combinedScaleRatio < 1.5,
          'standardControlPass': standard1024P95 < 4000,
          'cachedRepaint1024P95Pass': cachedRepaint1024P95 < 8000,
        },
      };

      expect(combined1024P95, lessThan(8000));
      expect(combined1024P95, lessThan(16670));
      expect(combinedScaleRatio, lessThan(1.5));
      expect(standard1024P95, lessThan(4000));
      expect(cachedRepaint1024P95, lessThan(8000));
      expect(tester.takeException(), isNull);
    },
  );
}

Map<String, Object?> _measurePainter({
  required _CanvasProfileFixture fixture,
  required ui.Image tileImage,
}) {
  final projectionOwner = EditorShadowPreviewProjectionOwner();
  final painter = _painter(
    fixture: fixture,
    tileImage: tileImage,
    projectionOwner: projectionOwner,
  );
  for (var index = 0; index < _warmups; index += 1) {
    _recordPaint(painter);
  }

  final samplesUs = <int>[];
  for (var index = 0; index < _samples; index += 1) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final stopwatch = Stopwatch()..start();
    painter.paint(canvas, _viewportSize);
    stopwatch.stop();
    samplesUs.add(stopwatch.elapsedMicroseconds);
    recorder.endRecording().dispose();
  }

  MapGridCullingDebugSnapshot? debugSnapshot;
  _recordPaint(
    _painter(
      fixture: fixture,
      tileImage: tileImage,
      projectionOwner: projectionOwner,
      debugOnCulling: (snapshot) => debugSnapshot = snapshot,
    ),
  );
  final sorted = List<int>.of(samplesUs)..sort();
  final snapshot = debugSnapshot!;
  return <String, Object?>{
    'mode': fixture.mode.name,
    'extent': fixture.extent,
    'mapCellCount': fixture.extent * fixture.extent,
    'placedElementCount': fixture.map.placedElements.length,
    'samplesUs': samplesUs,
    'p50Us': _percentile(sorted, 0.50),
    'p95Us': _percentile(sorted, 0.95),
    'p99Us': _percentile(sorted, 0.99),
    'maxUs': sorted.last,
    'visibleCellCount': snapshot.visibleBounds.cellCount,
    'tileCellVisits': snapshot.tileCellVisits,
    'smartTileVisualVisits': snapshot.smartTileVisualVisits,
    'staticShadowInstructionVisits': snapshot.staticShadowInstructionVisits,
    'projectedBuildingShadowInstructionVisits':
        snapshot.projectedBuildingShadowInstructionVisits,
    'visiblePlacedElementCount': snapshot.placedElementIds.length,
    'rssBytesAfterFixture': ProcessInfo.currentRss,
  };
}

Map<String, Object?> _measureCachedRepaint({
  required _CanvasProfileFixture fixture,
  required ui.Image tileImage,
}) {
  final projectionOwner = EditorShadowPreviewProjectionOwner();
  final pictureCacheOwner = EditorCanvasPictureCacheOwner();
  final clock = EditorCanvasRepaintClock();
  try {
    final painter = _painter(
      fixture: fixture,
      tileImage: tileImage,
      projectionOwner: projectionOwner,
      pictureCacheOwner: pictureCacheOwner,
      animationClock: clock,
    );
    final dirtyBounds = resolveEditorMapVisibleCellBounds(
      viewportSize: _viewportSize,
      mapSize: fixture.map.size,
      zoom: 1,
      offset: ui.Offset.zero,
      tileWidth: 32,
      tileHeight: 32,
    );
    for (var index = 0; index < _warmups; index += 1) {
      clock.update(Duration(milliseconds: (index + 1) * 110));
      _recordPaint(painter);
    }
    final hitsBeforeSamples = pictureCacheOwner.hitCount;
    final missesBeforeSamples = pictureCacheOwner.missCount;
    final samplesUs = <int>[];
    for (var index = 0; index < _samples; index += 1) {
      clock.update(Duration(milliseconds: (_warmups + index + 1) * 110));
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final stopwatch = Stopwatch()..start();
      painter.paint(canvas, _viewportSize);
      stopwatch.stop();
      samplesUs.add(stopwatch.elapsedMicroseconds);
      recorder.endRecording().dispose();
    }
    final sorted = List<int>.of(samplesUs)..sort();
    return <String, Object?>{
      'mode': 'animationTick',
      'extent': fixture.extent,
      'mapCellCount': fixture.extent * fixture.extent,
      'placedElementCount': fixture.map.placedElements.length,
      'samplesUs': samplesUs,
      'p50Us': _percentile(sorted, 0.50),
      'p95Us': _percentile(sorted, 0.95),
      'p99Us': _percentile(sorted, 0.99),
      'maxUs': sorted.last,
      'staticCacheHitsDuringSamples':
          pictureCacheOwner.hitCount - hitsBeforeSamples,
      'staticCacheMissesDuringSamples':
          pictureCacheOwner.missCount - missesBeforeSamples,
      'cacheEntryCount': pictureCacheOwner.entryCount,
      'dirtyRegion': <String, Object?>{
        'policy': 'visibleViewport',
        'leftCell': dirtyBounds.left,
        'topCell': dirtyBounds.top,
        'rightCell': dirtyBounds.right,
        'bottomCell': dirtyBounds.bottom,
        'cellCount':
            (dirtyBounds.right - dirtyBounds.left) *
            (dirtyBounds.bottom - dirtyBounds.top),
      },
      'rssBytesAfterFixture': ProcessInfo.currentRss,
    };
  } finally {
    clock.dispose();
    pictureCacheOwner.dispose();
  }
}

MapGridPainter _painter({
  required _CanvasProfileFixture fixture,
  required ui.Image tileImage,
  required EditorShadowPreviewProjectionOwner projectionOwner,
  MapGridCullingDebugObserver? debugOnCulling,
  EditorCanvasPictureCacheOwner? pictureCacheOwner,
  EditorCanvasRepaintClock? animationClock,
}) {
  return MapGridPainter(
    map: fixture.map,
    shadowProjectionOwner: projectionOwner,
    zoom: 1,
    offset: ui.Offset.zero,
    activeLayerId: 'base',
    tileWidth: 32,
    tileHeight: 32,
    tilesetImagesById: <String, ui.Image?>{'tiles': tileImage},
    sourceTileWidth: 32,
    sourceTileHeight: 32,
    tilesPerRowById: const <String, int>{'tiles': 1},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    project: _profileProject,
    animationClock: animationClock,
    pictureCacheOwner: pictureCacheOwner,
    editorEntityAnimationMs: 220,
    showGrid: false,
    showEntityEditorChrome: false,
    showEditorOverlays: false,
    debugOnCulling: debugOnCulling,
  );
}

void _recordPaint(MapGridPainter painter) {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), _viewportSize);
  recorder.endRecording().dispose();
}

int _percentile(List<int> sorted, double percentile) {
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

Future<ui.Image> _solidTileImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 32, 32),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(32, 32);
  } finally {
    picture.dispose();
  }
}

enum _CanvasProfileMode {
  standard,
  smart,
  shadows,
  combined;

  bool get includesStandard =>
      this == _CanvasProfileMode.standard ||
      this == _CanvasProfileMode.combined;

  bool get includesSmart =>
      this == _CanvasProfileMode.smart || this == _CanvasProfileMode.combined;

  bool get includesShadows =>
      this == _CanvasProfileMode.shadows || this == _CanvasProfileMode.combined;
}

final class _CanvasProfileFixture {
  const _CanvasProfileFixture({
    required this.mode,
    required this.extent,
    required this.map,
  });

  final _CanvasProfileMode mode;
  final int extent;
  final MapData map;

  factory _CanvasProfileFixture.create({
    required _CanvasProfileMode mode,
    required int extent,
    int? placedElementCount,
  }) {
    final cellCount = extent * extent;
    final layers = <MapLayer>[];
    if (mode.includesStandard || mode.includesShadows) {
      layers.add(
        TileLayer(
          id: 'base',
          name: 'Base',
          palette: const <TileLayerPaletteEntry>[
            TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 0),
          ],
          cells: List<int>.filled(
            cellCount,
            mode.includesStandard ? 1 : 0,
            growable: false,
          ),
        ),
      );
    }
    if (mode.includesSmart) {
      layers.add(
        SmartTileLayer(
          id: 'smart',
          name: 'Smart',
          presetId: 'smart-terrain',
          usage: SmartTileUsage.terrain,
          materialPalette: const <String>['', 'grass'],
          field: SmartTileField.cell(
            semanticCells: List<int>.filled(cellCount, 1, growable: false),
          ),
        ),
      );
    }

    final placedElements = <MapPlacedElement>[];
    if (mode.includesShadows) {
      if (placedElementCount != null) {
        for (var index = 0; index < placedElementCount; index += 1) {
          placedElements.add(
            MapPlacedElement(
              id: 'placed-$index',
              layerId: 'base',
              elementId: index.isEven ? 'static-caster' : 'building-caster',
              pos: GridPos(x: (index * 37) % extent, y: (index * 101) % extent),
              quarterTurns: index % 4,
            ),
          );
        }
      } else {
        placedElements.add(
          const MapPlacedElement(
            id: 'visible-projected-building',
            layerId: 'base',
            elementId: 'building-caster',
            pos: GridPos(x: 8, y: 8),
            quarterTurns: 1,
          ),
        );
        var index = 0;
        for (var y = 4; y < extent; y += 16) {
          for (var x = 4; x < extent; x += 16) {
            placedElements.add(
              MapPlacedElement(
                id: 'placed-$index',
                layerId: 'base',
                elementId: index.isEven ? 'static-caster' : 'building-caster',
                pos: GridPos(x: x, y: y),
                quarterTurns: index % 4,
              ),
            );
            index += 1;
          }
        }
      }
    }

    return _CanvasProfileFixture(
      mode: mode,
      extent: extent,
      map: MapData(
        id: '${mode.name}-$extent',
        name: '${mode.name} $extent',
        version: ProjectVersion.v6,
        size: GridSize(width: extent, height: extent),
        layers: layers,
        placedElements: placedElements,
      ),
    );
  }
}

final _profileProject = ProjectManifest(
  name: 'Canvas projection profile',
  version: ProjectVersion.v6,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: const <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'smart-atlas',
        name: 'Smart atlas',
        tilesetId: 'tiles',
        columns: 1,
        rows: 1,
      ),
    ],
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
    ],
    animations: const <ProjectSmartTileAnimation>[
      ProjectSmartTileAnimation(
        id: 'grass-wave',
        name: 'Grass wave',
        frames: <ProjectSmartTileAnimationFrame>[
          ProjectSmartTileAnimationFrame(
            frame: SmartTileFrameRef(atlasId: 'smart-atlas', column: 0, row: 0),
            durationMs: 110,
          ),
          ProjectSmartTileAnimationFrame(
            frame: SmartTileFrameRef(atlasId: 'smart-atlas', column: 0, row: 0),
            durationMs: 110,
          ),
        ],
      ),
    ],
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'smart-terrain',
        name: 'Smart terrain',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.cardinal4,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'ground',
            centerMatch: SmartTileSlotMatch.any(),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'ground',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.animation(
                      animationId: 'grass-wave',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  shadowCatalog: ProjectShadowCatalog(
    profiles: <ProjectShadowProfile>[
      ProjectShadowProfile(
        id: 'static-shadow',
        name: 'Static shadow',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
      ),
    ],
  ),
  projectedBuildingShadowCatalog: ProjectBuildingShadowPresetCatalog(
    presets: <ProjectBuildingShadowPreset>[
      ProjectBuildingShadowPreset(
        id: 'building-shadow',
        name: 'Building shadow',
        direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
        shape: ProjectedShadowShapeTuning(
          lengthRatio: 0.32,
          nearWidthRatio: 0.9,
          farWidthRatio: 0.72,
        ),
        appearance: ProjectedShadowAppearance(
          opacity: 0.3,
          colorHexRgb: '606060',
        ),
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
      ),
    ],
  ),
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'static-caster',
      name: 'Static caster',
      tilesetId: 'tiles',
      categoryId: 'profile',
      frames: <TilesetVisualFrame>[
        const TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
        ),
      ],
      shadow: ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'static-shadow',
      ),
    ),
    ProjectElementEntry(
      id: 'building-caster',
      name: 'Building caster',
      tilesetId: 'tiles',
      categoryId: 'profile',
      frames: <TilesetVisualFrame>[
        const TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 3, height: 4),
        ),
      ],
      projectedBuildingShadow: ProjectElementProjectedBuildingShadowConfig(
        enabled: true,
        presetId: 'building-shadow',
        anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
        localOffset: ProjectedShadowOffset(x: 0, y: 0),
      ),
    ),
  ],
);
