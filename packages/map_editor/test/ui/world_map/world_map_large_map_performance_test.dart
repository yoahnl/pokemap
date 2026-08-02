import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/adaptive_map_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_toolbelt.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/canvas/map_canvas/editor_canvas_repaint_clock.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  group('resolveEditorMapVisibleCellBounds', () {
    test('uses half-open right and bottom edges with zero margin', () {
      final bounds = _visibleBounds(
        viewportSize: const Size(64, 64),
        marginCells: 0,
      );

      expect(_boundsTuple(bounds), (0, 0, 2, 2));
      expect(
        bounds.intersectsCellArea(x: 1, y: 1, width: 1, height: 1),
        isTrue,
      );
      expect(
        bounds.intersectsCellArea(x: 2, y: 1, width: 1, height: 1),
        isFalse,
      );
      expect(
        bounds.intersectsCellArea(x: 1, y: 2, width: 1, height: 1),
        isFalse,
      );
    });

    test('clamps partial and fully off-map viewports on all four sides', () {
      expect(
        _boundsTuple(
          _visibleBounds(
            viewportSize: const Size(64, 64),
            offset: const Offset(16, 16),
            marginCells: 0,
          ),
        ),
        (0, 0, 2, 2),
      );
      expect(
        _boundsTuple(
          _visibleBounds(
            viewportSize: const Size(64, 64),
            offset: const Offset(-96, -96),
            marginCells: 0,
          ),
        ),
        (3, 3, 4, 4),
      );
      expect(
        _boundsTuple(
          _visibleBounds(
            viewportSize: const Size(32, 32),
            offset: const Offset(64, 64),
            marginCells: 0,
          ),
        ),
        (0, 0, 0, 0),
      );
      expect(
        _boundsTuple(
          _visibleBounds(
            viewportSize: const Size(32, 32),
            offset: const Offset(-160, -160),
            marginCells: 0,
          ),
        ),
        (4, 4, 4, 4),
      );
    });

    test('normalizes negative margin to zero', () {
      final zero = _visibleBounds(
        viewportSize: const Size(64, 64),
        marginCells: 0,
      );
      final negative = _visibleBounds(
        viewportSize: const Size(64, 64),
        marginCells: -5,
      );

      expect(_boundsTuple(negative), _boundsTuple(zero));
    });

    test('returns empty bounds for invalid viewport transforms', () {
      for (final bounds in <EditorMapVisibleCellBounds>[
        _visibleBounds(viewportSize: Size.zero),
        _visibleBounds(viewportSize: const Size(double.infinity, 64)),
        _visibleBounds(viewportSize: const Size(double.nan, 64)),
        _visibleBounds(viewportSize: const Size(64, double.infinity)),
        _visibleBounds(viewportSize: const Size(64, double.nan)),
        _visibleBounds(offset: const Offset(double.infinity, 0)),
        _visibleBounds(offset: const Offset(double.nan, 0)),
        _visibleBounds(offset: const Offset(0, double.infinity)),
        _visibleBounds(offset: const Offset(0, double.nan)),
        _visibleBounds(zoom: 0),
        _visibleBounds(zoom: -1),
        _visibleBounds(zoom: double.infinity),
        _visibleBounds(zoom: double.nan),
      ]) {
        expect(_boundsTuple(bounds), (0, 0, 0, 0));
      }
    });
  });

  test(
    '128x128 painter only visits visible dense cells and overlapping placed elements',
    () async {
      final image = await _solidImage(width: 96, height: 64);
      addTearDown(image.dispose);

      final origin = _paintCullingFixture(
        image: image,
        zoom: 1,
        offset: Offset.zero,
      );
      final panned = _paintCullingFixture(
        image: image,
        zoom: 1,
        offset: const Offset(-2048, -2048),
      );
      final zoomed = _paintCullingFixture(
        image: image,
        zoom: 2,
        offset: const Offset(-4096, -4096),
      );

      for (final snapshot in <MapGridCullingDebugSnapshot>[
        origin,
        panned,
        zoomed,
      ]) {
        expect(snapshot.totalMapCellCount, 128 * 128);
        expect(snapshot.visibleBounds.cellCount, lessThanOrEqualTo(25));
        expect(
          snapshot.tileCellVisits,
          snapshot.visibleBounds.cellCount,
        );
        expect(
          snapshot.collisionCellVisits,
          snapshot.visibleBounds.cellCount,
        );
        expect(
          snapshot.terrainCellVisits,
          snapshot.visibleBounds.cellCount,
        );
        expect(
          snapshot.pathCellVisits,
          snapshot.visibleBounds.cellCount,
        );
        expect(
          snapshot.placedElementPassVisits,
          lessThanOrEqualTo(snapshot.placedElementIds.length * 2),
        );
        expect(snapshot.placedElementIds.length, lessThan(5));
      }

      expect(origin.placedElementIds, <String>{'placed-origin'});
      expect(
        panned.placedElementIds,
        <String>{
          'placed-middle-overlap',
          'placed-middle-rotated-overlap',
          'placed-middle',
        },
      );
      expect(zoomed.placedElementIds, panned.placedElementIds);
      expect(origin.placedElementIds, isNot(panned.placedElementIds));
      expect(zoomed.visibleBounds.cellCount,
          lessThan(panned.visibleBounds.cellCount));
    },
  );

  test(
    'rotated foreground placed element at viewport edge masks its tile exactly once',
    () async {
      final alpha = await _renderRotatedEdgePixelAlpha();

      // The placed element is painted at 50% opacity on a transparent canvas.
      // Alpha near 128 proves the matching opaque tile stayed masked in both
      // passes; 255 would expose a double-paint and 0 a culling cut-off.
      expect(alpha, inInclusiveRange(120, 136));
    },
  );

  testWidgets(
      '128×128 long pan zoom hover and drag sequence stays within deterministic work budgets',
      (tester) async {
    final map = _largeMap();
    final container = ProviderContainer();
    final subscription = container.listen<EditorState>(
      editorNotifierProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(() {
      subscription.close();
      container.dispose();
    });
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = EditorState(
        project: _project,
        activeMap: map,
        activeLayerId: 'objects',
        activeTool: EditorToolType.selection,
        selectedWarpId: 'warp-1',
        savedMapSnapshot: map,
      );
    final clock = EditorCanvasRepaintClock();
    addTearDown(clock.dispose);
    var paints = 0;
    var canvasBuilds = 0;
    var toolbeltBuilds = 0;
    var inspectorBuilds = 0;
    final inspectorBodyBuilds = <WorldMapInspectorKind, int>{};

    await tester.binding.setSurfaceSize(const Size(1100, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: Column(
                children: [
                  WorldMapToolbelt(
                    debugOnBuild: () => toolbeltBuilds += 1,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: MapCanvas(
                            repaintClock: clock,
                            debugOnPaint: () => paints += 1,
                            debugOnBuild: () => canvasBuilds += 1,
                          ),
                        ),
                        SizedBox(
                          width: 300,
                          child: AdaptiveMapInspector(
                            debugOnBuild: () => inspectorBuilds += 1,
                            debugOnBodyBuild: (kind) {
                              inspectorBodyBuilds.update(
                                kind,
                                (count) => count + 1,
                                ifAbsent: () => 1,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    paints = 0;
    canvasBuilds = 0;
    toolbeltBuilds = 0;
    inspectorBuilds = 0;
    inspectorBodyBuilds.clear();

    final canvasOrigin = tester.getTopLeft(find.byType(MapCanvas));
    final canvasCenter = tester.getCenter(find.byType(MapCanvas));
    final hover = await tester.createGesture(
      kind: ui.PointerDeviceKind.mouse,
    );
    await hover.addPointer(location: canvasOrigin + const Offset(16, 16));
    for (var move = 0; move < 16; move += 1) {
      await hover.moveTo(
        canvasOrigin + Offset(16 + move * 8, 24 + (move % 4) * 8),
      );
      await tester.pump();
    }
    await hover.removePointer();

    for (var event = 0; event < 8; event += 1) {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: canvasCenter,
          kind: ui.PointerDeviceKind.mouse,
          scrollDelta: event.isEven ? const Offset(4, -3) : const Offset(-4, 3),
        ),
      );
      await tester.pump();
    }
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    try {
      for (var event = 0; event < 8; event += 1) {
        tester.binding.handlePointerEvent(
          PointerScrollEvent(
            position: canvasCenter,
            kind: ui.PointerDeviceKind.mouse,
            scrollDelta: Offset(0, event.isEven ? -10 : 10),
          ),
        );
        await tester.pump();
      }
    } finally {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    final afterNavigation = container.read(editorNotifierProvider);
    expect(afterNavigation.activeMap, same(map));
    expect(afterNavigation.mapUndoStack, isEmpty);
    expect(afterNavigation.mapRedoStack, isEmpty);
    expect(afterNavigation.isDirty, isFalse);

    final start = canvasOrigin +
        afterNavigation.panOffset +
        Offset(
          48 * afterNavigation.zoom,
          48 * afterNavigation.zoom,
        );
    final gesture = await tester.startGesture(start);
    for (var move = 1; move <= 12; move += 1) {
      await gesture.moveTo(start + Offset(move * 8, 0));
      await tester.pump();
    }

    expect(toolbeltBuilds, lessThanOrEqualTo(16));
    expect(inspectorBuilds, lessThanOrEqualTo(16));
    expect(
      inspectorBodyBuilds.keys
          .where((kind) => kind != WorldMapInspectorKind.objectSelection),
      isEmpty,
    );
    expect(canvasBuilds, lessThanOrEqualTo(49));
    expect(paints, lessThanOrEqualTo(49));

    await gesture.up();
    await tester.pump();

    final committed = container.read(editorNotifierProvider);
    final committedPosition = committed.activeMap!.warps.single.pos;
    expect(committedPosition, isNot(const GridPos(x: 1, y: 1)));
    expect(committed.mapUndoStack, hasLength(1));
    expect(committed.mapRedoStack, isEmpty);
    expect(toolbeltBuilds, lessThanOrEqualTo(17));
    expect(inspectorBuilds, lessThanOrEqualTo(17));
    expect(
      inspectorBodyBuilds.keys
          .where((kind) => kind != WorldMapInspectorKind.objectSelection),
      isEmpty,
    );
    expect(canvasBuilds, lessThanOrEqualTo(50));
    expect(paints, lessThanOrEqualTo(50));

    notifier.undoMap();
    await tester.pump();
    expect(
      container.read(editorNotifierProvider).activeMap!.warps.single.pos,
      const GridPos(x: 1, y: 1),
    );
    notifier.redoMap();
    await tester.pump();
    expect(
      container.read(editorNotifierProvider).activeMap!.warps.single.pos,
      committedPosition,
    );
  });

  test('smart tile work stays bounded to the same viewport from 128² to 1024²',
      () {
    final small = _paintSmartTileCullingFixture(mapExtent: 128);
    final large = _paintSmartTileCullingFixture(mapExtent: 1024);

    expect(
        _boundsTuple(large.visibleBounds), _boundsTuple(small.visibleBounds));
    expect(large.smartTileVisualVisits, small.smartTileVisualVisits);
    expect(large.smartTileVisualVisits, large.visibleBounds.cellCount);
    expect(large.smartTileVisualVisits, lessThan(large.totalMapCellCount));
  });
}

EditorMapVisibleCellBounds _visibleBounds({
  Size viewportSize = const Size(32, 32),
  Offset offset = Offset.zero,
  double zoom = 1,
  int marginCells = 1,
}) {
  return resolveEditorMapVisibleCellBounds(
    viewportSize: viewportSize,
    mapSize: const GridSize(width: 4, height: 4),
    zoom: zoom,
    offset: offset,
    tileWidth: 32,
    tileHeight: 32,
    marginCells: marginCells,
  );
}

(int, int, int, int) _boundsTuple(EditorMapVisibleCellBounds bounds) =>
    (bounds.left, bounds.top, bounds.right, bounds.bottom);

MapGridCullingDebugSnapshot _paintCullingFixture({
  required ui.Image image,
  required double zoom,
  required Offset offset,
}) {
  MapGridCullingDebugSnapshot? snapshot;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  MapGridPainter(
    map: _cullingMap(),
    zoom: zoom,
    offset: offset,
    activeLayerId: 'collision',
    tileWidth: 32,
    tileHeight: 32,
    tilesetImagesById: <String, ui.Image?>{'tiles': image},
    sourceTileWidth: 32,
    sourceTileHeight: 32,
    tilesPerRowById: const <String, int>{'tiles': 3},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: const {},
    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
    project: _cullingProject,
    showGrid: false,
    showEditorOverlays: false,
    debugOnCulling: (value) => snapshot = value,
  ).paint(canvas, const Size(96, 96));
  recorder.endRecording().dispose();
  return snapshot!;
}

MapGridCullingDebugSnapshot _paintSmartTileCullingFixture({
  required int mapExtent,
}) {
  final cellCount = mapExtent * mapExtent;
  final layer = SmartTileLayer(
    id: 'smart-terrain',
    name: 'Smart terrain',
    presetId: 'smart-terrain',
    usage: SmartTileUsage.terrain,
    materialPalette: const <String>['', 'grass'],
    field: SmartTileField.cell(
      semanticCells: List<int>.filled(cellCount, 1, growable: false),
    ),
  );
  final map = MapData(
    id: 'smart-$mapExtent',
    name: 'Smart $mapExtent',
    version: ProjectVersion.v5,
    size: GridSize(width: mapExtent, height: mapExtent),
    layers: <MapLayer>[layer],
  );
  MapGridCullingDebugSnapshot? snapshot;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  MapGridPainter(
    map: map,
    zoom: 1,
    offset: Offset.zero,
    tileWidth: 32,
    tileHeight: 32,
    tilesetImagesById: const <String, ui.Image?>{},
    sourceTileWidth: 32,
    sourceTileHeight: 32,
    tilesPerRowById: const <String, int>{},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: const {},
    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
    project: _smartTileProject,
    showGrid: false,
    showEditorOverlays: false,
    debugOnCulling: (value) => snapshot = value,
  ).paint(canvas, const Size(96, 96));
  recorder.endRecording().dispose();
  return snapshot!;
}

Future<ui.Image> _solidImage({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = Colors.white,
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}

Future<int> _renderRotatedEdgePixelAlpha() async {
  final sourceImage = await _solidImage(width: 96, height: 64);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final tiles = List<int>.filled(16, 0, growable: false)
    ..[2] = 1
    ..[1] = 4
    ..[6] = 2
    ..[5] = 5
    ..[10] = 3
    ..[9] = 6;
  final map = MapData(
    id: 'rotated-edge-mask',
    name: 'Rotated edge mask',
    size: const GridSize(width: 4, height: 4),
    layers: <MapLayer>[
      TileLayer(
        id: 'objects',
        name: 'Objects',
        tilesetId: 'tiles',
        tiles: tiles,
      ),
    ],
    placedElements: const <MapPlacedElement>[
      MapPlacedElement(
        id: 'rotated-edge',
        layerId: 'objects',
        elementId: 'wide-tree-with-base',
        pos: GridPos(x: 1, y: 0),
        quarterTurns: 1,
        opacity: 0.5,
      ),
    ],
  );
  MapGridPainter(
    map: map,
    zoom: 1,
    offset: Offset.zero,
    activeLayerId: 'objects',
    tileWidth: 32,
    tileHeight: 32,
    tilesetImagesById: <String, ui.Image?>{'tiles': sourceImage},
    sourceTileWidth: 32,
    sourceTileHeight: 32,
    tilesPerRowById: const <String, int>{'tiles': 3},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: const {},
    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
    project: _rotatedEdgeProject,
    showGrid: false,
    showEditorOverlays: false,
  ).paint(canvas, const Size(64, 64));
  final picture = recorder.endRecording();
  try {
    final rendered = await picture.toImage(64, 64);
    try {
      final bytes = await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (bytes == null) throw StateError('Could not read rendered pixels.');
      const sampleX = 48;
      const sampleY = 16;
      return bytes.getUint8((sampleY * 64 + sampleX) * 4 + 3);
    } finally {
      rendered.dispose();
    }
  } finally {
    picture.dispose();
    sourceImage.dispose();
  }
}

const _rotatedEdgeProject = ProjectManifest(
  name: 'Rotated edge mask',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'wide-tree-with-base',
      name: 'Wide tree with base',
      tilesetId: 'tiles',
      categoryId: 'test',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 3, height: 2),
        ),
      ],
      collisionProfile: ElementCollisionProfile(
        cells: <GridPos>[GridPos(x: 0, y: 0)],
      ),
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _cullingProject = ProjectManifest(
  name: 'Large map culling',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'wide-tree',
      name: 'Wide tree',
      tilesetId: 'tiles',
      categoryId: 'test',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 3, height: 2),
        ),
      ],
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

MapData _cullingMap() {
  const size = GridSize(width: 128, height: 128);
  final cells = size.width * size.height;
  return MapData(
    id: 'culling-map',
    name: 'Culling map',
    size: size,
    layers: <MapLayer>[
      TerrainLayer(
        id: 'terrain',
        name: 'Terrain',
        terrains: List<TerrainType>.filled(cells, TerrainType.grass),
      ),
      PathLayer(
        id: 'path',
        name: 'Path',
        cells: List<bool>.filled(cells, true),
      ),
      TileLayer(
        id: 'objects',
        name: 'Objects',
        tilesetId: 'tiles',
        tiles: List<int>.filled(cells, 1),
      ),
      CollisionLayer(
        id: 'collision',
        name: 'Collision',
        collisions: List<bool>.filled(cells, true),
      ),
    ],
    placedElements: const <MapPlacedElement>[
      MapPlacedElement(
        id: 'placed-origin',
        layerId: 'objects',
        elementId: 'wide-tree',
        pos: GridPos(x: 0, y: 0),
      ),
      MapPlacedElement(
        id: 'placed-middle-overlap',
        layerId: 'objects',
        elementId: 'wide-tree',
        pos: GridPos(x: 61, y: 63),
      ),
      MapPlacedElement(
        id: 'placed-middle-rotated-overlap',
        layerId: 'objects',
        elementId: 'wide-tree',
        pos: GridPos(x: 62, y: 61),
        quarterTurns: 1,
      ),
      MapPlacedElement(
        id: 'placed-middle',
        layerId: 'objects',
        elementId: 'wide-tree',
        pos: GridPos(x: 65, y: 65),
      ),
      MapPlacedElement(
        id: 'placed-far',
        layerId: 'objects',
        elementId: 'wide-tree',
        pos: GridPos(x: 120, y: 120),
      ),
    ],
  );
}

const _project = ProjectManifest(
  name: 'Large map performance',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'tree',
      name: 'Tree',
      tilesetId: 'missing',
      categoryId: 'test',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

final _smartTileProject = ProjectManifest(
  name: 'Smart tile performance',
  version: ProjectVersion.v5,
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  surfaceCatalog: const ProjectSurfaceCatalog.empty(),
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
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'smart-atlas',
                        column: 0,
                        row: 0,
                      ),
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
);

MapData _largeMap() {
  const size = GridSize(width: 128, height: 128);
  final cells = size.width * size.height;
  return MapData(
    id: 'large-map',
    name: 'Large map',
    size: size,
    layers: <MapLayer>[
      TileLayer(
        id: 'objects',
        name: 'Objects',
        tiles: List<int>.filled(cells, 0, growable: false),
      ),
      CollisionLayer(
        id: 'collision',
        name: 'Collision',
        collisions: List<bool>.filled(cells, false, growable: false),
      ),
    ],
    placedElements: const <MapPlacedElement>[
      MapPlacedElement(
        id: 'tree-1',
        layerId: 'objects',
        elementId: 'tree',
        pos: GridPos(x: 4, y: 4),
      ),
    ],
    warps: const <MapWarp>[
      MapWarp(
        id: 'warp-1',
        pos: GridPos(x: 1, y: 1),
        targetMapId: 'large-map',
        targetPos: GridPos(x: 0, y: 0),
      ),
    ],
  );
}
