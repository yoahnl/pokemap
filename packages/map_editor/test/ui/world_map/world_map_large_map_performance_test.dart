import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  testWidgets(
      '128×128 selected-object drag: 12 moves use at most 14 paints including preview start and terminal clear',
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
    final start = canvasOrigin + const Offset(48, 48);
    final gesture = await tester.startGesture(start);
    for (var move = 1; move <= 12; move += 1) {
      await gesture.moveTo(start + Offset(move * 32, 0));
      await tester.pump();
    }

    expect(toolbeltBuilds, 0);
    expect(inspectorBuilds, 0);
    expect(inspectorBodyBuilds, isEmpty);
    expect(canvasBuilds, lessThanOrEqualTo(13));
    expect(paints, lessThanOrEqualTo(13));

    await gesture.up();
    await tester.pump();

    final committed = container.read(editorNotifierProvider);
    final committedPosition = committed.activeMap!.warps.single.pos;
    expect(committedPosition, isNot(const GridPos(x: 1, y: 1)));
    expect(committed.mapUndoStack, hasLength(1));
    expect(committed.mapRedoStack, isEmpty);
    expect(toolbeltBuilds, lessThanOrEqualTo(1));
    expect(inspectorBuilds, lessThanOrEqualTo(1));
    expect(
      inspectorBodyBuilds.keys
          .where((kind) => kind != WorldMapInspectorKind.objectSelection),
      isEmpty,
    );
    expect(canvasBuilds, lessThanOrEqualTo(14));
    expect(paints, lessThanOrEqualTo(14));

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
