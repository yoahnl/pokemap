import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  group('NS-EVENT-V2-24 independent map bridge highlight', () {
    test('entity highlight does not depend on normal editor selection', () {
      final focus = NarrativeEditorFocusTarget.entity(
        'map_a',
        'entity_a',
        const MapRect(
          pos: GridPos(x: 2, y: 3),
          size: GridSize(width: 1, height: 1),
        ),
      );

      expect(
        isNarrativeEventBridgeEntityHighlighted(
          entityId: 'entity_a',
          focus: focus,
        ),
        isTrue,
      );
      expect(
        isNarrativeEventBridgeEntityHighlighted(
          entityId: 'another_selection',
          focus: focus,
        ),
        isFalse,
      );
    });

    test('trigger and map highlights remain typed', () {
      final trigger = NarrativeEditorFocusTarget.trigger(
        'map_a',
        'trigger_a',
        const MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 3, height: 2),
        ),
      );
      final map = NarrativeEditorFocusTarget.map('map_a');

      expect(
        isNarrativeEventBridgeTriggerHighlighted(
          triggerId: 'trigger_a',
          focus: trigger,
        ),
        isTrue,
      );
      expect(
        isNarrativeEventBridgeTriggerHighlighted(
          triggerId: 'trigger_a',
          focus: map,
        ),
        isFalse,
      );
      expect(isNarrativeEventBridgeMapHighlighted(focus: map), isTrue);
      expect(isNarrativeEventBridgeMapHighlighted(focus: trigger), isFalse);
    });

    test('choose hit-test returns only one real authorable source', () {
      const map = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 8, height: 8),
        entities: [
          MapEntity(
            id: 'entity_a',
            name: 'Entity A',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 2),
          ),
          MapEntity(
            id: 'spawn_a',
            name: 'Spawn',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 6, y: 6),
          ),
        ],
        triggers: [
          MapTrigger(
            id: 'trigger_a',
            name: 'Trigger A',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 4, y: 3),
              size: GridSize(width: 2, height: 2),
            ),
          ),
        ],
      );

      expect(
        resolveNarrativeEventMapCandidateAt(
          map: map,
          pos: const GridPos(x: 2, y: 2),
        ),
        NarrativeEventSourceRef.entityInteract('map_a', 'entity_a'),
      );
      expect(
        resolveNarrativeEventMapCandidateAt(
          map: map,
          pos: const GridPos(x: 5, y: 4),
        ),
        NarrativeEventSourceRef.triggerEnter('map_a', 'trigger_a'),
      );
      expect(
        resolveNarrativeEventMapCandidateAt(
          map: map,
          pos: const GridPos(x: 0, y: 0),
        ),
        isNull,
      );
      expect(
        resolveNarrativeEventMapCandidateAt(
          map: map,
          pos: const GridPos(x: 6, y: 6),
        ),
        isNull,
      );

      final ambiguous = map.copyWith(
        triggers: [
          ...map.triggers,
          const MapTrigger(
            id: 'overlap',
            name: 'Overlap',
            type: TriggerType.custom,
            area: MapRect(
              pos: GridPos(x: 2, y: 2),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );
      expect(
        resolveNarrativeEventMapCandidateAt(
          map: ambiguous,
          pos: const GridPos(x: 2, y: 2),
        ),
        isNull,
      );
    });

    test('painter repaints when only the bridge focus changes', () {
      final before = _painter(
        focus: NarrativeEditorFocusTarget.map('map_a'),
      );
      final after = _painter(
        focus: NarrativeEditorFocusTarget.entity(
          'map_a',
          'entity_a',
          const MapRect(
            pos: GridPos(x: 2, y: 3),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      );

      expect(after.shouldRepaint(before), isTrue);
    });

    testWidgets('canvas applies each camera request once', (tester) async {
      const eventId = 'evt_019abcde-0000-7000-8000-000000000321';
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'entity_a');
      final project = ProjectManifest(
        name: 'Canvas focus project',
        maps: const [
          ProjectMapEntry(
            id: 'map_a',
            name: 'Map A',
            relativePath: 'maps/map_a.json',
          ),
        ],
        tilesets: const [],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.dualRead,
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: eventId,
                name: 'Event focus',
                source: source,
                conditions: const [],
                priority: 0,
                order: 0,
              ),
            ),
          ],
          legacyClaims: const [],
        ),
      );
      const map = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 10, height: 8),
        layers: [ObjectLayer(id: 'objects', name: 'Objects')],
        entities: [
          MapEntity(
            id: 'entity_a',
            name: 'Entity A',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 2),
          ),
        ],
      );
      final container = ProviderContainer();
      final editorSubscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );
      final bridgeSubscription = container.listen<NarrativeEventMapBridgeState>(
        narrativeEventMapBridgeControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(() {
        bridgeSubscription.close();
        editorSubscription.close();
        container.dispose();
      });
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        activeMap: map,
        savedMapSnapshot: map,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      await controller.openMapForEvent(
        eventId: eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.view,
        project: project,
        activeMap: map,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: notifier.focusNarrativeEventMapSource,
      );

      await tester.binding.setSurfaceSize(const Size(800, 600));
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

      final centeredPan = notifier.state.panOffset;
      expect(centeredPan, isNot(Offset.zero));
      expect(controller.state.focusRequest?.cameraApplied, isTrue);

      notifier.pan(const Offset(25, -10));
      await tester.pump();
      await tester.pump();
      expect(notifier.state.panOffset, centeredPan + const Offset(25, -10));
    });
  });

  group('NS-EVENT-V2-25 guided map drag guard', () {
    testWidgets('create mode ignores a tile-paint drag', (tester) async {
      const eventId = 'evt_019abcde-0000-7000-8000-000000000322';
      final map = _guidedDragMap();
      final project = _guidedDragProject(eventId: eventId);
      final container = _createGuidedDragContainer();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        activeMap: map,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
        activeBrush: const EditorBrush.tile(
          tileId: 7,
          tilesetId: 'primary',
        ),
        savedMapSnapshot: map,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      final opened = await controller.openMapForMissingSource(
        eventId: eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        project: project,
        activeMap: map,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
      );
      expect(opened.succeeded, isTrue);
      expect(
        controller.state.navigationMode,
        NarrativeEventMapNavigationMode.create,
      );
      expect(controller.state.pendingReturn, isNotNull);

      await _pumpGuidedDragCanvas(tester, container);
      await _dragAcrossCanvas(tester);

      final activeLayer = notifier.state.activeMap!.layers.single as TileLayer;
      expect(
        activeLayer.cells,
        everyElement(0),
        reason: 'Guided create mode must not leak into tile painting.',
      );
    });

    testWidgets('choose mode ignores a gameplay-zone drag', (tester) async {
      const eventId = 'evt_019abcde-0000-7000-8000-000000000323';
      final map = _guidedDragMap();
      final project = _guidedDragProject(
        eventId: eventId,
        source: NarrativeEventSourceRef.mapEnter('map_a'),
      );
      final container = _createGuidedDragContainer();
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: project,
        activeMap: map,
        activeLayerId: 'ground',
        activeTool: EditorToolType.gameplayZonePlacement,
        savedMapSnapshot: map,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      final opened = await controller.openMapForEvent(
        eventId: eventId,
        groupContext: const NarrativeEventGroupContext.map('map_a'),
        mode: NarrativeEventMapNavigationMode.choose,
        project: project,
        activeMap: map,
        mapDirty: false,
        loadMapSnapshot: (_) async => null,
        activateMapSnapshot: (_) => true,
        applyFocus: notifier.focusNarrativeEventMapSource,
      );
      expect(opened.succeeded, isTrue);
      expect(
        controller.state.navigationMode,
        NarrativeEventMapNavigationMode.choose,
      );
      expect(controller.state.pendingReturn, isNotNull);

      await _pumpGuidedDragCanvas(tester, container);
      await _dragAcrossCanvas(tester);

      expect(
        notifier.state.activeMap!.gameplayZones,
        isEmpty,
        reason: 'Guided choose mode must not create gameplay zones.',
      );
      expect(notifier.state.gameplayZoneDraftArea, isNull);
    });
  });
}

ProviderContainer _createGuidedDragContainer() {
  final container = ProviderContainer();
  final editorSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  final bridgeSubscription = container.listen<NarrativeEventMapBridgeState>(
    narrativeEventMapBridgeControllerProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    bridgeSubscription.close();
    editorSubscription.close();
    container.dispose();
  });
  return container;
}

Future<void> _pumpGuidedDragCanvas(
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

Future<void> _dragAcrossCanvas(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(MapCanvas)),
  );
  await gesture.moveBy(const Offset(48, 0));
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

ProjectManifest _guidedDragProject({
  required String eventId,
  NarrativeEventSourceRef? source,
}) {
  return ProjectManifest(
    name: 'Guided drag project',
    maps: const [
      ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
    ],
    tilesets: const [],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: eventId,
            name: 'Guided drag Event',
            source: source,
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

MapData _guidedDragMap() {
  return MapData(
    id: 'map_a',
    name: 'Map A',
    size: const GridSize(width: 20, height: 15),
    layers: [
      TileLayer(
        id: 'ground',
        name: 'Ground',
        cells: List<int>.filled(20 * 15, 0),
      ),
    ],
  );
}

MapGridPainter _painter({required NarrativeEditorFocusTarget focus}) {
  return MapGridPainter(
    map: const MapData(
      id: 'map_a',
      name: 'Map A',
      size: GridSize(width: 8, height: 6),
    ),
    zoom: 1,
    offset: Offset.zero,
    tileWidth: 32,
    tileHeight: 32,
    tilesetImagesById: const {},
    sourceTileWidth: 16,
    sourceTileHeight: 16,
    tilesPerRowById: const {},
    warps: const [],
    gameplayZones: const [],
    connectionLabelsByDirection: const {},
    narrativeEventFocusTarget: focus,
    narrativeEventHighlightColor: const Color(0xFF815BFF),
  );
}
