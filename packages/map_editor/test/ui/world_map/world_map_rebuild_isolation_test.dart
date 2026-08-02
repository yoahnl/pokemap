import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/adaptive_map_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_toolbelt.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/canvas/map_canvas/editor_canvas_repaint_clock.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  test('document and viewport projections notify only their owned domain',
      () async {
    final container = _container();
    const map = MapData(
      id: 'semantic-projections',
      name: 'Semantic projections',
      size: GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        TileLayer(
          id: 'ground',
          name: 'Ground',
          tilesetId: 'tiles',
          tiles: <int>[0, 0, 0, 0],
        ),
      ],
    );
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        activeMap: map,
        activeLayerId: 'ground',
      );
    var documentNotifications = 0;
    var viewportNotifications = 0;
    final documentSubscription = container.listen(
      editorMapDocumentSnapshotProvider,
      (_, __) => documentNotifications += 1,
    );
    final viewportSubscription = container.listen(
      editorMapViewportSnapshotProvider,
      (_, __) => viewportNotifications += 1,
    );
    addTearDown(() {
      documentSubscription.close();
      viewportSubscription.close();
    });

    notifier.state = notifier.state.copyWith(
      zoom: 1.25,
      panOffset: const Offset(8, 12),
    );
    await container.pump();
    expect(documentNotifications, 0);
    expect(viewportNotifications, 1);

    notifier.state = notifier.state.copyWith(
      activeMap: paintTileOnLayer(
        map,
        layerId: 'ground',
        pos: const GridPos(x: 1, y: 1),
        tileId: 7,
      ),
    );
    await container.pump();
    expect(documentNotifications, 1);
    expect(viewportNotifications, 1);
  });

  testWidgets(
      'three 110 ms animation frames repaint without rebuilding canvas or inspector',
      (tester) async {
    final container = _container();
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      project: _animatedProject,
      activeMap: _animatedMap,
      activeLayerId: 'ground',
      activeTool: EditorToolType.selection,
      selectedEntityId: 'animated-entity',
    );
    var paints = 0;
    var canvasRebuilds = 0;
    var inspectorRebuilds = 0;
    await _pumpWorkspace(
      tester,
      container,
      canvas: MapCanvas(
        debugOnPaint: () => paints += 1,
        debugOnBuild: () => canvasRebuilds += 1,
      ),
      inspector: AdaptiveMapInspector(
        debugOnBuild: () => inspectorRebuilds += 1,
      ),
    );
    canvasRebuilds = 0;
    inspectorRebuilds = 0;
    paints = 0;

    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));

    expect(canvasRebuilds, 0);
    expect(inspectorRebuilds, 0);
    expect(paints, greaterThanOrEqualTo(2));
  });

  testWidgets(
      'production repaint clock follows only animation referenced by the visible active map',
      (tester) async {
    final container = _container();
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _projectWithAnimatedPath,
        activeMap: _staticPathMap,
        activeLayerId: 'ground',
      );
    final lifecycle = <EditorCanvasRepaintLifecycleEvent>[];
    var paints = 0;
    await _pumpWorkspace(
      tester,
      container,
      canvas: MapCanvas(
        debugOnPaint: () => paints += 1,
        debugOnRepaintLifecycle: lifecycle.add,
      ),
    );
    paints = 0;

    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));
    expect(
      paints,
      0,
      reason:
          'An unrelated animated project preset must not tick a static map.',
    );
    expect(
      lifecycle,
      isNot(contains(EditorCanvasRepaintLifecycleEvent.ownedTickerStarted)),
    );

    notifier.state = notifier.state.copyWith(
      activeMap: _animatedPathMap,
      activeLayerId: 'path',
    );
    await tester.pump();
    await tester.pump();
    paints = 0;
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));
    expect(paints, greaterThanOrEqualTo(2));
    expect(
      lifecycle.where(
        (event) =>
            event == EditorCanvasRepaintLifecycleEvent.ownedTickerStarted,
      ),
      hasLength(1),
    );

    notifier.state = notifier.state.copyWith(
      activeMap: _staticPathMap,
      activeLayerId: 'ground',
    );
    await tester.pump();
    await tester.pump();
    paints = 0;
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));
    expect(
      paints,
      0,
      reason: 'Switching to a static map must stop the production ticker.',
    );
    expect(
      lifecycle.where(
        (event) =>
            event == EditorCanvasRepaintLifecycleEvent.ownedTickerStopped,
      ),
      hasLength(1),
    );
    expect(
      lifecycle.where(
        (event) => event == EditorCanvasRepaintLifecycleEvent.ownedClockReset,
      ),
      hasLength(1),
    );

    notifier.state = notifier.state.copyWith(
      activeMap: _animatedPathMap,
      activeLayerId: 'path',
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    expect(paints, greaterThan(0));

    final hiddenPathMap = _animatedPathMap.copyWith(
      layers: <MapLayer>[
        (_animatedPathMap.layers.single as PathLayer).copyWith(
          isVisible: false,
        ),
      ],
    );
    notifier.state = notifier.state.copyWith(activeMap: hiddenPathMap);
    await tester.pump();
    await tester.pump();
    paints = 0;
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));
    expect(
      paints,
      0,
      reason: 'Hiding the last animated layer must stop the production ticker.',
    );
    expect(
      lifecycle.where(
        (event) =>
            event == EditorCanvasRepaintLifecycleEvent.ownedTickerStopped,
      ),
      hasLength(2),
    );
    expect(
      lifecycle.where(
        (event) => event == EditorCanvasRepaintLifecycleEvent.ownedClockReset,
      ),
      hasLength(2),
    );
  });

  testWidgets(
      'palette query filter and tab stay isolated; pan and zoom skip the real palette grid',
      (tester) async {
    final container = _container();
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _animatedProject,
        activeMap: _animatedMap,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
      );
    final clock = EditorCanvasRepaintClock();
    addTearDown(clock.dispose);
    var paints = 0;
    var canvasRebuilds = 0;
    var toolbeltRebuilds = 0;
    var inspectorRebuilds = 0;
    var inspectorBodyRebuilds = 0;
    var paletteGridRebuilds = 0;
    await _pumpWorkspace(
      tester,
      container,
      canvas: MapCanvas(
        repaintClock: clock,
        debugOnPaint: () => paints += 1,
        debugOnBuild: () => canvasRebuilds += 1,
      ),
      toolbelt: WorldMapToolbelt(
        debugOnBuild: () => toolbeltRebuilds += 1,
      ),
      inspector: AdaptiveMapInspector(
        debugOnBuild: () => inspectorRebuilds += 1,
        debugOnBodyBuild: (_) => inspectorBodyRebuilds += 1,
        debugOnPaletteBuild: () => paletteGridRebuilds += 1,
      ),
    );
    canvasRebuilds = 0;
    toolbeltRebuilds = 0;
    inspectorRebuilds = 0;
    inspectorBodyRebuilds = 0;
    paletteGridRebuilds = 0;
    paints = 0;

    const paletteKey = EditorPaletteContextKey(
      mapId: 'animated-map',
      layerId: 'ground',
    );
    notifier.state = notifier.state.copyWith(
      paletteCategoryFilter: PaletteCategory.trees,
      paletteSession: EditorPaletteSession(
        activeKey: paletteKey,
        contexts: <EditorPaletteContextKey, EditorLayerPaletteContext>{
          paletteKey: const EditorLayerPaletteContext(
            browserQuery: 'arbres',
            browserFolderId: 'nature',
            browserCollection: EditorPaletteAssetCollection.favorites,
          ),
        },
        recentTilesetIds: <String>['missing'],
        favoriteTilesetIds: <String>['missing'],
      ),
      tilesElementsPanelMode: TilesElementsPanelMode.placedInstances,
    );
    await tester.pump();

    expect(canvasRebuilds, 0);
    expect(paints, 0);
    expect(toolbeltRebuilds, 0);
    expect(inspectorRebuilds, 0);
    expect(inspectorBodyRebuilds, 0);
    expect(paletteGridRebuilds, 0);

    notifier.state = notifier.state.copyWith(
      zoom: 1.25,
      panOffset: const Offset(16, 24),
    );
    await tester.pump();

    expect(canvasRebuilds, 1);
    expect(paints, 1);
    expect(toolbeltRebuilds, 0);
    expect(inspectorRebuilds, 0);
    expect(inspectorBodyRebuilds, 0);
    expect(paletteGridRebuilds, 0);
  });

  testWidgets(
      'selected-object drag leaves toolbelt and unrelated inspector bodies stable before one history commit',
      (tester) async {
    final container = _container();
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      project: _animatedProject,
      activeMap: _animatedMap,
      activeLayerId: 'objects',
      activeTool: EditorToolType.selection,
      selectedWarpId: 'warp-1',
      savedMapSnapshot: _animatedMap,
    );
    final clock = EditorCanvasRepaintClock();
    addTearDown(clock.dispose);
    var toolbeltRebuilds = 0;
    final inspectorBodyRebuilds = <WorldMapInspectorKind, int>{};
    await _pumpWorkspace(
      tester,
      container,
      canvas: MapCanvas(repaintClock: clock),
      toolbelt: WorldMapToolbelt(
        debugOnBuild: () => toolbeltRebuilds += 1,
      ),
      inspector: AdaptiveMapInspector(
        debugOnBodyBuild: (kind) {
          inspectorBodyRebuilds.update(
            kind,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        },
      ),
    );
    toolbeltRebuilds = 0;
    inspectorBodyRebuilds.clear();

    final origin = tester.getTopLeft(find.byType(MapCanvas));
    final gesture = await tester.startGesture(
      origin + const Offset(144, 144),
    );
    await gesture.moveBy(const Offset(64, 32));
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey<String>('map-canvas-object-move-preview'),
      ),
      findsOneWidget,
    );
    expect(toolbeltRebuilds, 0);
    expect(inspectorBodyRebuilds, isEmpty);
    expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);

    await gesture.up();
    await tester.pump();

    final committedState = container.read(editorNotifierProvider);
    expect(
      committedState.mapUndoStack,
      hasLength(1),
      reason: 'status=${committedState.statusMessage}; '
          'error=${committedState.errorMessage}; '
          'position=${committedState.activeMap?.warps.single.pos}',
    );
    expect(
      inspectorBodyRebuilds.keys
          .where((kind) => kind != WorldMapInspectorKind.objectSelection),
      isEmpty,
    );
  });

  testWidgets(
      'injected clock never auto-advances or disposes and detaches its painter on unmount',
      (tester) async {
    final container = _container();
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      project: _animatedProject,
      activeMap: _animatedMap,
      activeLayerId: 'ground',
    );
    final clock = EditorCanvasRepaintClock();
    addTearDown(clock.dispose);
    final lifecycle = <EditorCanvasRepaintLifecycleEvent>[];
    var paints = 0;
    await _pumpWorkspace(
      tester,
      container,
      canvas: MapCanvas(
        repaintClock: clock,
        debugOnPaint: () => paints += 1,
        debugOnRepaintLifecycle: lifecycle.add,
      ),
    );
    paints = 0;

    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 110));

    expect(clock.elapsedMs, 0);
    expect(paints, 0);
    expect(lifecycle, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final paintsAfterUnmount = paints;
    var externalNotifications = 0;
    clock.addListener(() => externalNotifications += 1);
    clock.update(const Duration(milliseconds: 110));
    await tester.pump();

    expect(clock.elapsedMs, 110);
    expect(externalNotifications, 1);
    expect(paints, paintsAfterUnmount);
    expect(lifecycle, isEmpty);
  });

  testWidgets('production clock and ticker are created and disposed once',
      (tester) async {
    final container = _container();
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      project: _animatedProject,
      activeMap: _animatedMap,
      activeLayerId: 'ground',
    );
    final lifecycle = <EditorCanvasRepaintLifecycleEvent>[];
    await _pumpWorkspace(
      tester,
      container,
      canvas: MapCanvas(debugOnRepaintLifecycle: lifecycle.add),
    );

    expect(
      lifecycle,
      <EditorCanvasRepaintLifecycleEvent>[
        EditorCanvasRepaintLifecycleEvent.ownedClockCreated,
        EditorCanvasRepaintLifecycleEvent.ownedTickerCreated,
        EditorCanvasRepaintLifecycleEvent.ownedTickerStarted,
      ],
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(
      lifecycle,
      <EditorCanvasRepaintLifecycleEvent>[
        EditorCanvasRepaintLifecycleEvent.ownedClockCreated,
        EditorCanvasRepaintLifecycleEvent.ownedTickerCreated,
        EditorCanvasRepaintLifecycleEvent.ownedTickerStarted,
        EditorCanvasRepaintLifecycleEvent.ownedTickerDisposed,
        EditorCanvasRepaintLifecycleEvent.ownedClockDisposed,
      ],
    );
    await tester.pump();
    expect(
      lifecycle.where(
        (event) =>
            event == EditorCanvasRepaintLifecycleEvent.ownedTickerDisposed,
      ),
      hasLength(1),
    );
    expect(
      lifecycle.where(
        (event) =>
            event == EditorCanvasRepaintLifecycleEvent.ownedClockDisposed,
      ),
      hasLength(1),
    );
  });
}

ProviderContainer _container() {
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
  return container;
}

Future<void> _pumpWorkspace(
  WidgetTester tester,
  ProviderContainer container, {
  required MapCanvas canvas,
  WorldMapToolbelt? toolbelt,
  AdaptiveMapInspector inspector = const AdaptiveMapInspector(),
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 700));
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
                if (toolbelt != null) toolbelt,
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: canvas),
                      SizedBox(width: 300, child: inspector),
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
}

const _animatedProject = ProjectManifest(
  name: 'Animation isolation',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'animated',
      name: 'Animated',
      tilesetId: 'missing',
      categoryId: 'test',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
          durationMs: 110,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 1, y: 0, width: 1, height: 1),
          durationMs: 110,
        ),
      ],
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _animatedMap = MapData(
  id: 'animated-map',
  name: 'Animated map',
  size: GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tiles: <int>[
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ],
    ),
    ObjectLayer(id: 'objects', name: 'Objects'),
  ],
  entities: <MapEntity>[
    MapEntity(
      id: 'animated-entity',
      name: 'Animated entity',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 2, y: 2),
      editorVisual: MapEntityEditorVisual(elementId: 'animated'),
    ),
  ],
  warps: <MapWarp>[
    MapWarp(
      id: 'warp-1',
      pos: GridPos(x: 4, y: 4),
      targetMapId: 'animated-map',
      targetPos: GridPos(x: 0, y: 0),
    ),
  ],
);

const _projectWithAnimatedPath = ProjectManifest(
  name: 'Referenced animation isolation',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'missing',
      name: 'Missing test tileset',
      relativePath: 'missing.png',
    ),
  ],
  pathPresets: <ProjectPathPreset>[
    ProjectPathPreset(
      id: 'animated-path',
      name: 'Animated path',
      tilesetId: 'missing',
      variants: <PathPresetVariantMapping>[
        PathPresetVariantMapping(
          variant: TerrainPathVariant.isolated,
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0),
              durationMs: 110,
            ),
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 1, y: 0),
              durationMs: 110,
            ),
          ],
        ),
      ],
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _staticPathMap = MapData(
  id: 'static-path-map',
  name: 'Static path map',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tiles: <int>[0, 0, 0, 0],
    ),
  ],
);

const _animatedPathMap = MapData(
  id: 'animated-path-map',
  name: 'Animated path map',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    PathLayer(
      id: 'path',
      name: 'Path',
      presetId: 'animated-path',
      cells: <bool>[true, false, false, false],
      animationMode: PathAnimationMode.alwaysActive,
    ),
  ],
);
