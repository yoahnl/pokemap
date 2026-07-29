import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  name: 'Canvas object selection',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _map = MapData(
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
