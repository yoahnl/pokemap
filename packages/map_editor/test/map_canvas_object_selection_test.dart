import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  testWidgets(
    'Selection tool cycles canvas objects exclusively without map mutation',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(
        editorNotifierProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'objects',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _map,
        selectedEntityId: 'stale-entity',
        selectedMapEventId: 'stale-event',
        selectedTriggerId: 'stale-trigger',
      );
      final beforeJson = _map.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final overlap = canvas.topLeft + const Offset(144, 144);

      await tester.tapAt(overlap);
      await tester.pump();

      var state = container.read(editorNotifierProvider);
      expect(state.selectedWarpId, 'warp');
      expect(state.selectedTriggerId, isNull);
      expect(state.selectedMapEventId, isNull);
      expect(state.selectedEntityId, isNull);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(
        find.bySemanticsLabel(
          RegExp('Téléporteur warp sélectionné, x 4, y 4'),
        ),
        findsOneWidget,
      );

      await tester.tapAt(overlap);
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(state.selectedWarpId, isNull);
      expect(state.selectedTriggerId, 'trigger');
      expect(state.selectedMapEventId, isNull);
      expect(state.selectedEntityId, isNull);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);

      final adjacentOverlap = canvas.topLeft + const Offset(176, 144);
      await tester.tapAt(adjacentOverlap);
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(
        state.selectedTriggerId,
        'trigger',
        reason: 'a new hit stack must restart from its topmost target',
      );
      expect(state.selectedMapEventId, isNull);

      await tester.tapAt(adjacentOverlap);
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(state.selectedTriggerId, isNull);
      expect(state.selectedMapEventId, 'event-next');

      await tester.tapAt(canvas.topLeft + const Offset(208, 208));
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(state.selectedWarpId, isNull);
      expect(state.selectedTriggerId, isNull);
      expect(state.selectedMapEventId, isNull);
      expect(state.selectedEntityId, isNull);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
    },
  );

  testWidgets(
    'selection drag previews without mutation then commits one undoable move',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'objects',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _map,
      );
      final beforeJson = _map.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(144, 144),
      );
      await gesture.moveBy(const Offset(64, 32));
      await tester.pump();

      var state = container.read(editorNotifierProvider);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(
        find.byKey(
          const ValueKey<String>('map-canvas-object-move-preview'),
        ),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(
        state.activeMap!.warps.single.pos,
        const GridPos(x: 6, y: 5),
        reason: 'status=${state.statusMessage}; error=${state.errorMessage}; '
            'undo=${state.mapUndoStack.length}',
      );
      expect(state.selectedWarpId, 'warp');
      expect(state.mapUndoStack, hasLength(1));
      expect(state.mapRedoStack, isEmpty);
      expect(state.isDirty, isTrue);
      expect(
        find.byKey(
          const ValueKey<String>('map-canvas-object-move-preview'),
        ),
        findsNothing,
      );

      container.read(editorNotifierProvider.notifier).undoMap();
      state = container.read(editorNotifierProvider);
      expect(state.activeMap, _map);
      expect(state.selectedWarpId, 'warp');
      expect(state.mapUndoStack, isEmpty);
      expect(state.mapRedoStack, hasLength(1));

      container.read(editorNotifierProvider.notifier).redoMap();
      state = container.read(editorNotifierProvider);
      expect(state.activeMap!.warps.single.pos, const GridPos(x: 6, y: 5));
      expect(state.selectedWarpId, 'warp');
      expect(state.mapUndoStack, hasLength(1));
      expect(state.mapRedoStack, isEmpty);
    },
  );

  testWidgets(
    'selection drag keeps the selected overlap target and Escape rolls back',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'objects',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _map,
        selectedTriggerId: 'trigger',
      );
      final beforeJson = _map.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(144, 144),
      );
      await gesture.moveBy(const Offset(32, 64));
      await tester.pump();

      var state = container.read(editorNotifierProvider);
      expect(state.selectedTriggerId, 'trigger');
      expect(state.selectedWarpId, isNull);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.selectedTriggerId, 'trigger');
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(
        find.byKey(
          const ValueKey<String>('map-canvas-object-move-preview'),
        ),
        findsNothing,
      );
      await gesture.up();
      await tester.pump();
    },
  );

  testWidgets(
    'invalid selection destination never commits or creates history',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'objects',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _map,
      );
      final beforeJson = _map.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(144, 144),
      );
      await gesture.moveBy(const Offset(-192, 0));
      await tester.pump();
      expect(
        find.bySemanticsLabel(
          RegExp('Déplacement.*impossible.*destination dépasse la carte'),
        ),
        findsOneWidget,
      );
      await gesture.up();
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);
      expect(state.mapRedoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(state.errorMessage, contains('destination dépasse la carte'));
    },
  );

  testWidgets(
    'selection drag cancels when its map interaction context changes',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'objects',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _map,
      );
      final beforeJson = _map.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(144, 144),
      );
      await gesture.moveBy(const Offset(32, 0));
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('map-canvas-object-move-preview'),
        ),
        findsOneWidget,
      );

      final current = container.read(editorNotifierProvider);
      container.read(editorNotifierProvider.notifier).state = current.copyWith(
        activeTool: EditorToolType.eraser,
      );
      await gesture.moveBy(const Offset(32, 0));
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(
        find.byKey(
          const ValueKey<String>('map-canvas-object-move-preview'),
        ),
        findsNothing,
      );
      await gesture.up();
      await tester.pump();
    },
  );

  testWidgets(
    'Environment generated placement stays protected with explicit feedback',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _environmentProject,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _environmentMap,
        activeLayerId: 'decor',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _environmentMap,
      );
      final beforeJson = _environmentMap.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(80, 80),
      );
      await gesture.moveBy(const Offset(32, 0));
      await tester.pump();

      expect(
        find.bySemanticsLabel(
          RegExp('Déplacement.*impossible.*zone Environment'),
        ),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.selectedPlacedElementInstanceId, 'generated');
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(state.errorMessage, contains('généré par une zone Environment'));
    },
  );
}

Future<void> _pumpCanvas(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
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
        child: const MaterialApp(
          home: CupertinoPageScaffold(
            child: SizedBox.expand(child: MapCanvas()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _project = ProjectManifest(
  version: ProjectVersion.v3,
  name: 'Canvas object selection',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _map = MapData(
  version: ProjectVersion.v3,
  id: 'map',
  name: 'Map',
  visualStack: MapVisualStackConfig.canonicalV1,
  size: GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    ObjectLayer(id: 'objects', name: 'Objects'),
  ],
  entities: <MapEntity>[
    MapEntity(
      id: 'entity',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 4, y: 4),
    ),
  ],
  events: <MapEventDefinition>[
    MapEventDefinition(
      id: 'event',
      pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
      position: EventPosition(layerId: 'objects', x: 4, y: 4),
    ),
    MapEventDefinition(
      id: 'event-next',
      pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
      position: EventPosition(layerId: 'objects', x: 5, y: 4),
    ),
  ],
  triggers: <MapTrigger>[
    MapTrigger(
      id: 'trigger',
      type: TriggerType.custom,
      area: MapRect(
        pos: GridPos(x: 4, y: 4),
        size: GridSize(width: 2, height: 1),
      ),
    ),
  ],
  warps: <MapWarp>[
    MapWarp(
      id: 'warp',
      pos: GridPos(x: 4, y: 4),
      targetMapId: 'map',
      targetPos: GridPos(x: 0, y: 0),
    ),
  ],
);

const _environmentProject = ProjectManifest(
  version: ProjectVersion.v3,
  name: 'Environment generated selection',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'tiles',
      name: 'Tiles',
      relativePath: 'assets/tiles.png',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'tree',
      name: 'Tree',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

final _environmentMap = MapData(
  version: ProjectVersion.v3,
  id: 'environment-map',
  name: 'Environment map',
  visualStack: MapVisualStackConfig.canonicalV1,
  size: const GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    const TileLayer(id: 'decor', name: 'Decor'),
    EnvironmentLayer(
      id: 'environment',
      name: 'Environment',
      content: EnvironmentLayerContent(
        targetTileLayerId: 'decor',
        areas: <EnvironmentArea>[
          EnvironmentArea(
            id: 'forest',
            name: 'Forest',
            presetId: 'forest',
            mask: EnvironmentAreaMask(
              width: 8,
              height: 8,
              cells: List<bool>.filled(64, true),
            ),
            seed: 1,
            generatedPlacementIds: <String>['generated'],
          ),
        ],
      ),
    ),
  ],
  placedElements: <MapPlacedElement>[
    const MapPlacedElement(
      id: 'generated',
      layerId: 'decor',
      elementId: 'tree',
      pos: GridPos(x: 2, y: 2),
      properties: <String, String>{
        'pokemapPlacementOrigin': 'environment',
      },
    ),
  ],
);
