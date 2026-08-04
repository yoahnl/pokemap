import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/application/world_map_inspector_projector.dart';
import 'package:map_editor/src/features/editor/application/world_map_observed_tool_family.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_paint_inspection_intent.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/design_system/pokemap_desktop_layout.dart';

void main() {
  group('worldMapWorkspaceSessionProvider', () {
    test('starts with the planned typed defaults', () {
      final container = _createContainer();

      expect(
        container.read(worldMapWorkspaceSessionProvider),
        const WorldMapWorkspaceSession(),
      );
      final state = container.read(worldMapWorkspaceSessionProvider);
      expect(state.explorerExpanded, isTrue);
      expect(state.inspectorVisible, isTrue);
      expect(
        state.inspectorWidth,
        PokeMapDesktopLayoutTokens.inspectorWidth,
      );
      expect(state.activeFamily, WorldMapToolFamily.selection);
      expect(state.lastPaintSubtool, WorldMapPaintSubtool.tile);
      expect(state.lastPlacementSubtool, WorldMapPlacementSubtool.object);
      expect(state.lastPaintSubtoolByLayerId, isEmpty);
      expect(state.pinnedInspectorKind, isNull);
      expect(state.selectedCell, isNull);
      expect(state.selectedCellMapId, isNull);
    });

    test('owns chrome visibility and typed inspector width', () {
      final container = _createContainer();
      final controller =
          container.read(worldMapWorkspaceSessionProvider.notifier);

      controller.setExplorerExpanded(false);
      controller.setInspectorVisible(false);
      controller.setInspectorWidth(412);

      final state = container.read(worldMapWorkspaceSessionProvider);
      expect(state.explorerExpanded, isFalse);
      expect(state.inspectorVisible, isFalse);
      expect(state.inspectorWidth, 412);
    });

    test('pins an inspector and keeps cell ownership tied to one map', () {
      final container = _createContainer();
      final controller =
          container.read(worldMapWorkspaceSessionProvider.notifier);

      controller.pinInspector(WorldMapInspectorKind.objectSelection);
      controller.selectCell(
        mapId: 'map-a',
        cell: const GridPos(x: 2, y: 3),
      );

      var state = container.read(worldMapWorkspaceSessionProvider);
      expect(state.pinnedInspectorKind, WorldMapInspectorKind.objectSelection);
      expect(state.selectedCell, const GridPos(x: 2, y: 3));
      expect(state.selectedCellMapId, 'map-a');

      controller.resetForMap('map-a');
      state = container.read(worldMapWorkspaceSessionProvider);
      expect(state.selectedCell, const GridPos(x: 2, y: 3));

      controller.resetForMap('map-b');
      state = container.read(worldMapWorkspaceSessionProvider);
      expect(state.selectedCell, isNull);
      expect(state.selectedCellMapId, isNull);
      expect(state.pinnedInspectorKind, WorldMapInspectorKind.objectSelection);

      controller.pinInspector(null);
      expect(
        container.read(worldMapWorkspaceSessionProvider).pinnedInspectorKind,
        isNull,
      );
    });

    test('session-only changes preserve editor and serialized documents', () {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _mapA,
          activeLayerId: 'terrain-a',
          activeTool: EditorToolType.selection,
          mapUndoStack: <MapHistorySnapshot>[_undo],
          mapRedoStack: <MapHistorySnapshot>[_redo],
          canUndoMap: true,
          canRedoMap: true,
          isDirty: true,
          isProjectDirty: true,
        );
      final before = editor.state;
      final projectJson = before.project!.toJson();
      final mapJson = before.activeMap!.toJson();
      final controller =
          container.read(worldMapWorkspaceSessionProvider.notifier);

      controller.setExplorerExpanded(false);
      controller.setInspectorVisible(false);
      controller.setInspectorWidth(420);
      controller.pinInspector(WorldMapInspectorKind.layers);
      controller.selectCell(
        mapId: 'map-a',
        cell: const GridPos(x: 1, y: 1),
      );

      expect(editor.state, before);
      expect(editor.state.project!.toJson(), projectJson);
      expect(editor.state.activeMap!.toJson(), mapJson);
      expect(editor.state.mapUndoStack, const <MapHistorySnapshot>[_undo]);
      expect(editor.state.mapRedoStack, const <MapHistorySnapshot>[_redo]);
      expect(editor.state.canUndoMap, isTrue);
      expect(editor.state.canRedoMap, isTrue);
      expect(editor.state.isDirty, isTrue);
      expect(editor.state.isProjectDirty, isTrue);
    });

    test('rejected activation preserves complete editor and session snapshots',
        () {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _mapA,
          activeLayerId: 'terrain-a',
          activeTool: EditorToolType.entityPlacement,
          selectedEntityId: 'npc',
          mapUndoStack: <MapHistorySnapshot>[_undo],
          mapRedoStack: <MapHistorySnapshot>[_redo],
          canUndoMap: true,
          canRedoMap: true,
          statusMessage: 'status-sentinel',
          errorMessage: 'error-sentinel',
        );
      final controller =
          container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(controller.activateLayers(editor).accepted, isTrue);
      controller.pinInspector(WorldMapInspectorKind.layers);
      controller.selectCell(
        mapId: 'map-a',
        cell: const GridPos(x: 3, y: 2),
      );
      final editorBefore = editor.state;
      final sessionBefore = container.read(worldMapWorkspaceSessionProvider);

      final result = controller.activateTool(
        editor,
        const ActivateWorldMapPaint(WorldMapPaintSubtool.surface),
      );

      expect(result.accepted, isFalse);
      expect(result.rejectionReason, isNotEmpty);
      expect(editor.state, editorBefore);
      expect(container.read(worldMapWorkspaceSessionProvider), sessionBefore);
    });

    test(
        'paint, place, and erase publish the requested family only after '
        'clearing object and cell selections', () {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier);
      final controller =
          container.read(worldMapWorkspaceSessionProvider.notifier);
      final cases = <({
        WorldMapToolActivationRequest request,
        WorldMapToolFamily family,
      })>[
        (
          request: const ActivateWorldMapPaint(WorldMapPaintSubtool.terrain),
          family: WorldMapToolFamily.paint,
        ),
        (
          request: const ActivateWorldMapPlacement(
            WorldMapPlacementSubtool.event,
          ),
          family: WorldMapToolFamily.place,
        ),
        (
          request: const ActivateWorldMapErase(),
          family: WorldMapToolFamily.erase,
        ),
      ];

      for (final testCase in cases) {
        editor.state = const EditorState(
          project: _project,
          activeMap: _mapA,
          activeLayerId: 'terrain-a',
          activeTool: EditorToolType.selection,
          activeBrush: EditorBrush.tile(tileId: 1, tilesetId: 'world'),
          selectedEntityId: 'npc',
        );
        controller.selectCell(
          mapId: 'map-a',
          cell: const GridPos(x: 1, y: 2),
        );

        final result = controller.activateTool(editor, testCase.request);

        expect(
          result.accepted,
          isTrue,
          reason: testCase.request.runtimeType.toString(),
        );
        final session = container.read(worldMapWorkspaceSessionProvider);
        expect(session.activeFamily, testCase.family);
        expect(session.selectedCell, isNull);
        expect(session.selectedCellMapId, isNull);
        expect(editor.state.selectedEntityId, isNull);
      }

      final session = container.read(worldMapWorkspaceSessionProvider);
      expect(session.lastPaintSubtool, WorldMapPaintSubtool.terrain);
      expect(
        session.lastPaintSubtoolByLayerId,
        <String, WorldMapPaintSubtool>{
          'terrain-a': WorldMapPaintSubtool.terrain,
        },
      );
      expect(
        session.lastPlacementSubtool,
        WorldMapPlacementSubtool.event,
      );
    });

    test('A to B to A restores paint memory per layer', () {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _mapA,
          activeLayerId: 'terrain-a',
        );
      final controller =
          container.read(worldMapWorkspaceSessionProvider.notifier);
      controller.resetForMap('map-a');

      expect(
        controller
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.terrain),
            )
            .accepted,
        isTrue,
      );
      controller.setActiveLayer(editor, 'path-b');
      expect(
        controller
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.path),
            )
            .accepted,
        isTrue,
      );

      var emissions = <EditorState>[];
      var subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, next) => emissions.add(next),
      );
      controller.setActiveLayer(editor, 'terrain-a');
      subscription.close();
      expect(emissions, hasLength(1));
      expect(editor.state.activeTool, EditorToolType.terrainPaint);
      expect(
        container.read(worldMapWorkspaceSessionProvider).lastPaintSubtool,
        WorldMapPaintSubtool.terrain,
      );

      emissions = <EditorState>[];
      subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, next) => emissions.add(next),
      );
      controller.setActiveLayer(editor, 'path-b');
      subscription.close();
      expect(emissions, hasLength(1));
      expect(editor.state.activeTool, EditorToolType.terrainPaint);
      expect(
        container.read(worldMapWorkspaceSessionProvider).lastPaintSubtool,
        WorldMapPaintSubtool.path,
      );

      emissions = <EditorState>[];
      subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, next) => emissions.add(next),
      );
      controller.setActiveLayer(editor, 'terrain-a');
      subscription.close();
      expect(emissions, hasLength(1));
      expect(editor.state.activeTool, EditorToolType.terrainPaint);
      expect(
        container.read(worldMapWorkspaceSessionProvider).lastPaintSubtool,
        WorldMapPaintSubtool.terrain,
      );
    });

    test('map switching clears cell and prevents layer-id memory leaking', () {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _mapA,
          activeLayerId: 'terrain-a',
        );
      final controller =
          container.read(worldMapWorkspaceSessionProvider.notifier);
      controller.resetForMap('map-a');
      controller.selectCell(
        mapId: 'map-a',
        cell: const GridPos(x: 1, y: 1),
      );
      expect(
        controller
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.terrain),
            )
            .accepted,
        isTrue,
      );

      controller.resetForMap('map-b');

      final state = container.read(worldMapWorkspaceSessionProvider);
      expect(state.selectedCell, isNull);
      expect(state.selectedCellMapId, isNull);
      expect(state.lastPaintSubtoolByLayerId, isEmpty);
      expect(state.lastPaintSubtool, WorldMapPaintSubtool.tile);
    });

    test('layer coercion is one editor emission and reconciles the family', () {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _mapA,
          activeLayerId: 'tile',
          activeTool: EditorToolType.tilePaint,
          activeBrush: EditorBrush.tile(tileId: 1, tilesetId: 'world'),
        );
      final controller =
          container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(
        controller
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
            )
            .accepted,
        isTrue,
      );
      final emissions = <EditorState>[];
      final subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, next) => emissions.add(next),
      );

      controller.setActiveLayer(editor, 'terrain-a');

      subscription.close();
      expect(emissions, hasLength(1));
      expect(editor.state.activeLayerId, 'terrain-a');
      expect(editor.state.activeTool, EditorToolType.selection);
      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.selection,
      );
    });

    for (final rememberedBrush in const <String>['tile', 'palette entry']) {
      test(
          'Place remains brush-safe when a same-engine destination remembers '
          'a $rememberedBrush brush', () {
        final container = _createContainer();
        final editor = container.read(editorNotifierProvider.notifier)
          ..state = const EditorState(
            project: _project,
            activeMap: _mapA,
            activeLayerId: 'tile-b',
            activeTool: EditorToolType.selection,
          );
        final controller =
            container.read(worldMapWorkspaceSessionProvider.notifier);
        controller.resetForMap('map-a');

        if (rememberedBrush == 'tile') {
          editor.selectPaletteTile(3);
          expect(
            editor.state.activeBrush,
            const EditorBrush.tile(tileId: 3, tilesetId: 'details'),
          );
        } else {
          editor.selectPaletteEntry('detail-entry');
          expect(
            editor.state.activeBrush,
            const EditorBrush.paletteEntry(
              entryId: 'detail-entry',
              tilesetId: 'details',
            ),
          );
        }
        editor.setActiveLayer('tile');
        editor.selectProjectElement('tree');
        expect(
          controller
              .activateTool(
                editor,
                const ActivateWorldMapPlacement(
                  WorldMapPlacementSubtool.object,
                ),
              )
              .accepted,
          isTrue,
        );

        final emissions = <EditorState>[];
        final subscription = container.listen<EditorState>(
          editorNotifierProvider,
          (_, next) => emissions.add(next),
        );

        controller.setActiveLayer(editor, 'tile-b');

        subscription.close();
        expect(emissions, hasLength(1));
        expect(editor.state.activeLayerId, 'tile-b');
        expect(editor.state.activeTool, EditorToolType.tilePaint);
        expect(editor.state.activeBrush, const EditorBrush.none());
        expect(
          editor.state.activeBrush,
          isNot(anyOf(isA<TileEditorBrush>(), isA<PaletteEntryEditorBrush>())),
        );
        expect(
          container.read(worldMapWorkspaceSessionProvider).activeFamily,
          WorldMapToolFamily.place,
        );
      });
    }

    test(
        'Paint restores a compatible project element remembered by the '
        'destination layer', () {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _mapA,
          activeLayerId: 'tile-b',
          activeTool: EditorToolType.selection,
        );
      final controller =
          container.read(worldMapWorkspaceSessionProvider.notifier);
      controller.resetForMap('map-a');

      editor.selectProjectElement('lamp');
      expect(
        editor.state.activeBrush,
        const EditorBrush.projectElement(elementId: 'lamp'),
      );
      editor.setActiveLayer('tile');
      editor.selectPaletteTile(5);
      expect(
        controller
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
            )
            .accepted,
        isTrue,
      );

      final emissions = <EditorState>[];
      final subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, next) => emissions.add(next),
      );

      controller.setActiveLayer(editor, 'tile-b');

      subscription.close();
      expect(emissions, hasLength(1));
      expect(editor.state.activeLayerId, 'tile-b');
      expect(editor.state.activeTool, EditorToolType.tilePaint);
      expect(
        editor.state.activeBrush,
        const EditorBrush.projectElement(elementId: 'lamp'),
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.paint,
      );
    });

    test('Place retains a compatible destination project-element brush', () {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _mapA,
          activeLayerId: 'tile-b',
          activeTool: EditorToolType.selection,
        );
      final controller =
          container.read(worldMapWorkspaceSessionProvider.notifier);
      controller.resetForMap('map-a');

      editor.selectProjectElement('lamp');
      editor.setActiveLayer('tile');
      editor.selectProjectElement('tree');
      expect(
        controller
            .activateTool(
              editor,
              const ActivateWorldMapPlacement(
                WorldMapPlacementSubtool.object,
              ),
            )
            .accepted,
        isTrue,
      );

      final emissions = <EditorState>[];
      final subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, next) => emissions.add(next),
      );

      controller.setActiveLayer(editor, 'tile-b');

      subscription.close();
      expect(emissions, hasLength(1));
      expect(
        editor.state.activeBrush,
        const EditorBrush.projectElement(elementId: 'lamp'),
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.place,
      );
    });

    test('explicit Layers survives a layer change when no tool coercion occurs',
        () {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _mapA,
          activeLayerId: 'terrain-a',
          activeTool: EditorToolType.selection,
        );
      final controller =
          container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(controller.activateLayers(editor).accepted, isTrue);

      controller.setActiveLayer(editor, 'path-b');

      expect(editor.state.activeTool, EditorToolType.selection);
      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.layers,
      );
    });
  });

  group('WorldMapInspectorProjector', () {
    const projector = WorldMapInspectorProjector();
    const cell = GridPos(x: 1, y: 2);

    test('gives a valid pin priority over every live context', () {
      final snapshot = projector.project(
        editor: _inspectorInput(selectedEntityId: 'entity'),
        session: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.layers,
          pinnedInspectorKind: WorldMapInspectorKind.paint,
          selectedCell: cell,
          selectedCellMapId: 'map-a',
        ),
      );

      expect(snapshot.kind, WorldMapInspectorKind.paint);
      expect(snapshot.activeLayerId, 'tile');
      expect(snapshot.objectTarget, isNull);
      expect(snapshot.cell, isNull);
      expect(snapshot.pinned, isTrue);
    });

    test('gives explicit Layers priority over object and cell selections', () {
      final snapshot = projector.project(
        editor: _inspectorInput(selectedEntityId: 'entity'),
        session: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.layers,
          selectedCell: cell,
          selectedCellMapId: 'map-a',
        ),
      );

      expect(snapshot.kind, WorldMapInspectorKind.layers);
      expect(snapshot.objectTarget, isNull);
      expect(snapshot.cell, isNull);
      expect(snapshot.pinned, isFalse);
    });

    test('gives a selected object priority over a selected cell and tool', () {
      final snapshot = projector.project(
        editor: _inspectorInput(
          activeTool: EditorToolType.tilePaint,
          selectedEntityId: 'entity',
        ),
        session: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.paint,
          selectedCell: cell,
          selectedCellMapId: 'map-a',
        ),
      );

      expect(snapshot.kind, WorldMapInspectorKind.objectSelection);
      expect(snapshot.objectTarget?.kind, MapCanvasObjectKind.entity);
      expect(snapshot.objectTarget?.id, 'entity');
      expect(snapshot.cell, isNull);
    });

    test('gives a selected cell priority over the active tool family', () {
      final snapshot = projector.project(
        editor: _inspectorInput(activeTool: EditorToolType.eraser),
        session: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.erase,
          selectedCell: cell,
          selectedCellMapId: 'map-a',
        ),
      );

      expect(snapshot.kind, WorldMapInspectorKind.cellSelection);
      expect(snapshot.objectTarget, isNull);
      expect(snapshot.cell, cell);
    });

    test('projects Paint Erase and Place when no selection has priority', () {
      const expectations = <({
        EditorToolType tool,
        WorldMapToolFamily sessionFamily,
        WorldMapInspectorKind kind,
      })>[
        (
          tool: EditorToolType.tilePaint,
          sessionFamily: WorldMapToolFamily.paint,
          kind: WorldMapInspectorKind.paint,
        ),
        (
          tool: EditorToolType.eraser,
          sessionFamily: WorldMapToolFamily.layers,
          kind: WorldMapInspectorKind.erase,
        ),
        (
          tool: EditorToolType.entityPlacement,
          sessionFamily: WorldMapToolFamily.selection,
          kind: WorldMapInspectorKind.place,
        ),
      ];

      for (final entry in expectations) {
        final snapshot = projector.project(
          editor: _inspectorInput(activeTool: entry.tool),
          session: WorldMapWorkspaceSession(
            activeFamily: entry.sessionFamily,
          ),
        );

        expect(snapshot.kind, entry.kind, reason: entry.tool.name);
        expect(snapshot.pinned, isFalse, reason: entry.tool.name);
      }
    });

    test('uses session only to disambiguate tilePaint object placement', () {
      final snapshot = projector.project(
        editor: _inspectorInput(activeTool: EditorToolType.tilePaint),
        session: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.place,
          lastPlacementSubtool: WorldMapPlacementSubtool.object,
        ),
      );

      expect(snapshot.kind, WorldMapInspectorKind.place);
    });

    test('shares concrete brush disambiguation with the observed tool family',
        () {
      const placeObject = WorldMapWorkspaceSession(
        activeFamily: WorldMapToolFamily.place,
        lastPlacementSubtool: WorldMapPlacementSubtool.object,
      );
      const stalePaint = WorldMapWorkspaceSession(
        activeFamily: WorldMapToolFamily.paint,
        lastPlacementSubtool: WorldMapPlacementSubtool.object,
      );
      const stalePlaceEntity = WorldMapWorkspaceSession(
        activeFamily: WorldMapToolFamily.place,
        lastPlacementSubtool: WorldMapPlacementSubtool.entity,
      );
      const cases = <({
        EditorWorldMapBrushKind brushKind,
        WorldMapWorkspaceSession session,
        WorldMapToolFamily family,
      })>[
        (
          brushKind: EditorWorldMapBrushKind.projectElement,
          session: stalePaint,
          family: WorldMapToolFamily.paint,
        ),
        (
          brushKind: EditorWorldMapBrushKind.projectElement,
          session: placeObject,
          family: WorldMapToolFamily.place,
        ),
        (
          brushKind: EditorWorldMapBrushKind.projectElement,
          session: WorldMapWorkspaceSession(
            activeFamily: WorldMapToolFamily.selection,
          ),
          family: WorldMapToolFamily.place,
        ),
        (
          brushKind: EditorWorldMapBrushKind.tile,
          session: placeObject,
          family: WorldMapToolFamily.paint,
        ),
        (
          brushKind: EditorWorldMapBrushKind.paletteEntry,
          session: placeObject,
          family: WorldMapToolFamily.paint,
        ),
        (
          brushKind: EditorWorldMapBrushKind.none,
          session: placeObject,
          family: WorldMapToolFamily.place,
        ),
        (
          brushKind: EditorWorldMapBrushKind.none,
          session: stalePlaceEntity,
          family: WorldMapToolFamily.paint,
        ),
      ];

      for (final entry in cases) {
        final observed = resolveWorldMapObservedToolFamily(
          activeTool: EditorToolType.tilePaint,
          session: entry.session,
          brushKind: entry.brushKind,
        );
        final projected = WorldMapInspectorProjector(
          brushKind: entry.brushKind,
        ).project(
          editor: _inspectorInput(activeTool: EditorToolType.tilePaint),
          session: entry.session,
        );

        expect(observed, entry.family, reason: entry.brushKind.name);
        expect(
          projected.kind,
          entry.family == WorldMapToolFamily.place
              ? WorldMapInspectorKind.place
              : WorldMapInspectorKind.paint,
          reason: entry.brushKind.name,
        );
      }
    });

    test('keeps every non-object Place pin valid on a layerless map', () {
      const tools = <EditorToolType>[
        EditorToolType.entityPlacement,
        EditorToolType.eventPlacement,
        EditorToolType.triggerPlacement,
        EditorToolType.warpPlacement,
        EditorToolType.gameplayZonePlacement,
      ];
      const editor = (
        activeMap: _layerlessMap,
        project: null,
        activeTool: EditorToolType.entityPlacement,
        activeLayerId: null,
        activeLayerName: null,
        selectedEntityId: null,
        selectedMapEventId: null,
        selectedWarpId: null,
        selectedTriggerId: null,
        selectedGameplayZoneId: null,
        selectedPlacedElementInstanceId: null,
        assignedTilesetId: null,
      );

      for (final tool in tools) {
        final snapshot = projector.project(
          editor: (
            activeMap: editor.activeMap,
            project: editor.project,
            activeTool: tool,
            activeLayerId: editor.activeLayerId,
            activeLayerName: editor.activeLayerName,
            selectedEntityId: editor.selectedEntityId,
            selectedMapEventId: editor.selectedMapEventId,
            selectedWarpId: editor.selectedWarpId,
            selectedTriggerId: editor.selectedTriggerId,
            selectedGameplayZoneId: editor.selectedGameplayZoneId,
            selectedPlacedElementInstanceId:
                editor.selectedPlacedElementInstanceId,
            assignedTilesetId: editor.assignedTilesetId,
          ),
          session: const WorldMapWorkspaceSession(
            pinnedInspectorKind: WorldMapInspectorKind.place,
          ),
        );

        expect(snapshot.kind, WorldMapInspectorKind.place, reason: tool.name);
        expect(snapshot.activeLayerId, isNull, reason: tool.name);
        expect(snapshot.pinned, isTrue, reason: tool.name);
      }
    });

    test('projects empty guidance for Selection without a target', () {
      final snapshot = projector.project(
        editor: _inspectorInput(),
        session: const WorldMapWorkspaceSession(),
      );

      expect(snapshot.kind, WorldMapInspectorKind.empty);
      expect(snapshot.activeLayerId, 'tile');
      expect(snapshot.objectTarget, isNull);
      expect(snapshot.cell, isNull);
      expect(snapshot.pinned, isFalse);
    });

    test('falls back to live context when the pinned target is invalid', () {
      final snapshot = projector.project(
        editor: _inspectorInput(
          activeTool: EditorToolType.tilePaint,
          selectedEntityId: 'stale-entity',
        ),
        session: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.paint,
          pinnedInspectorKind: WorldMapInspectorKind.objectSelection,
        ),
      );

      expect(snapshot.kind, WorldMapInspectorKind.paint);
      expect(snapshot.objectTarget, isNull);
      expect(snapshot.pinned, isFalse);
    });
  });

  group('worldMapInspectorSnapshotProvider', () {
    test('composes only the narrow editor input and workspace session', () {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _project,
        activeMap: _mapWithObject,
        activeLayerId: 'tile',
        activeTool: EditorToolType.selection,
        selectedEntityId: 'entity',
      );

      expect(
        container.read(editorWorldMapInspectorInputSnapshotProvider),
        (
          activeMap: _mapWithObject,
          project: _project,
          activeTool: EditorToolType.selection,
          activeLayerId: 'tile',
          activeLayerName: 'Tile',
          selectedEntityId: 'entity',
          selectedMapEventId: null,
          selectedWarpId: null,
          selectedTriggerId: null,
          selectedGameplayZoneId: null,
          selectedPlacedElementInstanceId: null,
          assignedTilesetId: 'world',
        ),
      );
      final projected = container.read(worldMapInspectorSnapshotProvider);
      expect(projected.kind, WorldMapInspectorKind.objectSelection);
      expect(projected.objectTarget?.id, 'entity');
    });

    test('tracks concrete brush kind without widening the editor snapshot', () {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = EditorState(
          project: _project,
          activeMap: _mapWithObject,
          activeLayerId: 'tile',
          activeTool: EditorToolType.tilePaint,
          activeBrush: const EditorBrush.projectElement(elementId: 'tree'),
        );

      expect(
        container.read(worldMapInspectorSnapshotProvider).kind,
        WorldMapInspectorKind.place,
      );

      editor.state = editor.state.copyWith(
        activeBrush: const EditorBrush.tile(
          tileId: 1,
          tilesetId: 'world',
        ),
      );
      expect(
        container.read(worldMapInspectorSnapshotProvider).kind,
        WorldMapInspectorKind.paint,
      );

      editor.state = editor.state.copyWith(
        activeBrush: const EditorBrush.paletteEntry(
          entryId: 'detail-entry',
          tilesetId: 'details',
        ),
      );
      expect(
        container.read(worldMapInspectorSnapshotProvider).kind,
        WorldMapInspectorKind.paint,
      );
    });

    test('emits updated geometry when the selected entity keeps its identity',
        () async {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = EditorState(
          project: _project,
          activeMap: _mapWithObject,
          activeLayerId: 'tile',
          activeTool: EditorToolType.selection,
          selectedEntityId: 'entity',
        );
      final snapshots = <WorldMapInspectorSnapshot>[];
      final listener = container.listen<WorldMapInspectorSnapshot>(
        worldMapInspectorSnapshotProvider,
        (_, next) => snapshots.add(next),
        fireImmediately: true,
      );
      addTearDown(listener.close);

      editor.state = editor.state.copyWith(
        activeMap: _mapWithObject.copyWith(
          entities: const <MapEntity>[
            MapEntity(
              id: 'entity',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 1, y: 0),
              size: GridSize(width: 2, height: 3),
            ),
          ],
        ),
      );
      await container.pump();

      expect(snapshots, hasLength(2));
      expect(
        snapshots.last.objectTarget?.anchor,
        const GridPos(x: 1, y: 0),
      );
      expect(
        snapshots.last.objectTarget?.size,
        const GridSize(width: 2, height: 3),
      );
    });

    test('drops a stale object and clears the selected cell on map change', () {
      final container = _createContainer();
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = EditorState(
          project: _project,
          activeMap: _mapWithObject,
          activeLayerId: 'tile',
          activeTool: EditorToolType.selection,
          selectedEntityId: 'entity',
        );
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      session.selectCell(
        mapId: 'map-a',
        cell: const GridPos(x: 1, y: 1),
      );
      expect(
        container.read(worldMapInspectorSnapshotProvider).kind,
        WorldMapInspectorKind.objectSelection,
      );

      editor.state = editor.state.copyWith(
        activeMap: _mapB,
        activeLayerId: 'tile',
      );

      final workspace = container.read(worldMapWorkspaceSessionProvider);
      final projected = container.read(worldMapInspectorSnapshotProvider);
      expect(workspace.selectedCell, isNull);
      expect(workspace.selectedCellMapId, isNull);
      expect(projected.kind, WorldMapInspectorKind.empty);
      expect(projected.objectTarget, isNull);
      expect(projected.cell, isNull);
    });

    test('effective setup intent projects an unpinnable Paint inspector', () {
      final container = _createContainer();
      final setupMap = _mapA.copyWith(
        layers: <MapLayer>[
          ..._mapA.layers,
          const SmartTileLayer(
            id: 'surface',
            name: 'Surface',
            presetId: 'forest',
            usage: SmartTileUsage.forestSurface,
            field: SmartTileField.cell(semanticCells: <int>[]),
          ),
        ],
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _project,
        activeMap: setupMap,
        activeLayerId: 'surface',
        activeTool: EditorToolType.selection,
        selectedEntityId: 'stale-selection',
      );
      container.read(worldMapPaintInspectionIntentProvider.notifier).showSetup(
            mapId: 'map-a',
            layerId: 'surface',
            subtool: WorldMapPaintSubtool.surface,
          );

      final projected = container.read(worldMapInspectorSnapshotProvider);

      expect(projected.kind, WorldMapInspectorKind.paint);
      expect(projected.activeLayerId, 'surface');
      expect(projected.objectTarget, isNull);
      expect(projected.cell, isNull);
      expect(projected.pinned, isFalse);
      expect(container.read(worldMapInspectorCanPinProvider), isFalse);
    });

    test('valid pin keeps priority over an effective setup intent', () {
      final container = _createContainer();
      final setupMap = _mapA.copyWith(
        layers: <MapLayer>[
          ..._mapA.layers,
          const SmartTileLayer(
            id: 'surface',
            name: 'Surface',
            presetId: 'forest',
            usage: SmartTileUsage.forestSurface,
            field: SmartTileField.cell(semanticCells: <int>[]),
          ),
        ],
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _project,
        activeMap: setupMap,
        activeLayerId: 'surface',
        activeTool: EditorToolType.selection,
      );
      container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .pinInspector(WorldMapInspectorKind.layers);
      container.read(worldMapPaintInspectionIntentProvider.notifier).showSetup(
            mapId: 'map-a',
            layerId: 'surface',
            subtool: WorldMapPaintSubtool.surface,
          );

      final projected = container.read(worldMapInspectorSnapshotProvider);

      expect(projected.kind, WorldMapInspectorKind.layers);
      expect(projected.activeLayerId, 'surface');
      expect(projected.pinned, isTrue);
      expect(container.read(worldMapInspectorCanPinProvider), isTrue);
    });
  });
}

ProviderContainer _createContainer() {
  final container = ProviderContainer();
  final editorKeepAlive = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  final sessionKeepAlive = container.listen<WorldMapWorkspaceSession>(
    worldMapWorkspaceSessionProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    sessionKeepAlive.close();
    editorKeepAlive.close();
    container.dispose();
  });
  return container;
}

const _project = ProjectManifest(
  name: 'Session project',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'map-a',
      name: 'Map A',
      relativePath: 'maps/map-a.json',
    ),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'World',
      relativePath: 'tilesets/world.png',
    ),
    ProjectTilesetEntry(
      id: 'details',
      name: 'Details',
      relativePath: 'tilesets/details.png',
      paletteEntries: <TilesetPaletteEntry>[
        TilesetPaletteEntry(
          id: 'detail-entry',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(source: TilesetSourceRect(x: 2, y: 0)),
          ],
        ),
      ],
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'tree',
      name: 'Tree',
      tilesetId: 'world',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
      ],
    ),
    ProjectElementEntry(
      id: 'lamp',
      name: 'Lamp',
      tilesetId: 'details',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
      ],
    ),
  ],
);

const _mapA = MapData(
  id: 'map-a',
  name: 'Map A',
  version: ProjectVersion.v6,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Tile',
      palette: <TileLayerPaletteEntry>[
        TileLayerPaletteEntry(tilesetId: 'world', localTileId: 0),
      ],
      cells: <int>[],
    ),
    TileLayer(
      id: 'tile-b',
      name: 'Tile B',
      palette: <TileLayerPaletteEntry>[
        TileLayerPaletteEntry(tilesetId: 'details', localTileId: 0),
      ],
      cells: <int>[],
    ),
    SmartTileLayer(
      id: 'terrain-a',
      name: 'Terrain A',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      field: SmartTileField.cell(semanticCells: <int>[]),
    ),
    SmartTileLayer(
      id: 'path-b',
      name: 'Path B',
      presetId: 'path',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: <int>[]),
    ),
  ],
);

final _mapWithObject = _mapA.copyWith(
  entities: const <MapEntity>[
    MapEntity(
      id: 'entity',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 2, y: 1),
    ),
  ],
);

const _mapB = MapData(
  id: 'map-b',
  name: 'Map B',
  version: ProjectVersion.v6,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Tile',
      palette: <TileLayerPaletteEntry>[
        TileLayerPaletteEntry(tilesetId: 'world', localTileId: 0),
      ],
      cells: <int>[],
    ),
  ],
);

const _layerlessMap = MapData(
  id: 'layerless',
  name: 'Layerless',
  size: GridSize(width: 4, height: 4),
);

const _undoMap = MapData(
  id: 'undo',
  name: 'Undo',
  size: GridSize(width: 1, height: 1),
);

const _redoMap = MapData(
  id: 'redo',
  name: 'Redo',
  size: GridSize(width: 1, height: 1),
);

const _undo = MapHistorySnapshot(
  map: _undoMap,
  activeLayerId: 'undo-layer',
);

const _redo = MapHistorySnapshot(
  map: _redoMap,
  activeLayerId: 'redo-layer',
);

EditorWorldMapInspectorInputSnapshot _inspectorInput({
  EditorToolType activeTool = EditorToolType.selection,
  String? selectedEntityId,
  String? selectedMapEventId,
  String? selectedWarpId,
  String? selectedTriggerId,
  String? selectedGameplayZoneId,
  String? selectedPlacedElementInstanceId,
}) {
  return (
    activeMap: _mapWithObject,
    project: _project,
    activeTool: activeTool,
    activeLayerId: 'tile',
    activeLayerName: 'Tile',
    selectedEntityId: selectedEntityId,
    selectedMapEventId: selectedMapEventId,
    selectedWarpId: selectedWarpId,
    selectedTriggerId: selectedTriggerId,
    selectedGameplayZoneId: selectedGameplayZoneId,
    selectedPlacedElementInstanceId: selectedPlacedElementInstanceId,
    assignedTilesetId: 'world',
  );
}
