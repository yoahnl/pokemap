import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/application/world_map_inspector_projector.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/adaptive_map_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_cell_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_erase_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_layers_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_paint_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_place_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_selection_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('AdaptiveMapInspector', () {
    testWidgets('owns exactly one real body for every projected kind',
        (tester) async {
      const cases = <({
        WorldMapInspectorSnapshot snapshot,
        String title,
        Type? bodyType,
      })>[
        (
          snapshot: (
            kind: WorldMapInspectorKind.paint,
            activeLayerId: 'tile',
            objectTarget: null,
            cell: null,
            pinned: false,
          ),
          title: 'Peindre',
          bodyType: WorldMapPaintInspector,
        ),
        (
          snapshot: (
            kind: WorldMapInspectorKind.erase,
            activeLayerId: 'tile',
            objectTarget: null,
            cell: null,
            pinned: false,
          ),
          title: 'Effacer',
          bodyType: WorldMapEraseInspector,
        ),
        (
          snapshot: (
            kind: WorldMapInspectorKind.place,
            activeLayerId: 'tile',
            objectTarget: null,
            cell: null,
            pinned: false,
          ),
          title: 'Placer',
          bodyType: WorldMapPlaceInspector,
        ),
        (
          snapshot: (
            kind: WorldMapInspectorKind.objectSelection,
            activeLayerId: 'tile',
            objectTarget: MapCanvasObjectTarget(
              kind: MapCanvasObjectKind.entity,
              id: 'npc',
              anchor: GridPos(x: 1, y: 1),
              size: GridSize(width: 1, height: 1),
            ),
            cell: null,
            pinned: false,
          ),
          title: 'Objet sélectionné',
          bodyType: WorldMapSelectionInspector,
        ),
        (
          snapshot: (
            kind: WorldMapInspectorKind.cellSelection,
            activeLayerId: 'tile',
            objectTarget: null,
            cell: GridPos(x: 2, y: 3),
            pinned: false,
          ),
          title: 'Cellule sélectionnée',
          bodyType: WorldMapCellInspector,
        ),
        (
          snapshot: (
            kind: WorldMapInspectorKind.layers,
            activeLayerId: 'tile',
            objectTarget: null,
            cell: null,
            pinned: false,
          ),
          title: 'Calques',
          bodyType: WorldMapLayersInspector,
        ),
        (
          snapshot: (
            kind: WorldMapInspectorKind.empty,
            activeLayerId: 'tile',
            objectTarget: null,
            cell: null,
            pinned: false,
          ),
          title: 'Aucune sélection',
          bodyType: null,
        ),
      ];

      for (final entry in cases) {
        final container = ProviderContainer(
          overrides: [
            worldMapInspectorSnapshotProvider.overrideWith(
              (ref) => entry.snapshot,
            ),
          ],
        );
        final keepAlive = container.listen<EditorState>(
          editorNotifierProvider,
          (_, __) {},
          fireImmediately: true,
        );
        container.read(editorNotifierProvider.notifier).state =
            const EditorState(
          activeMap: _map,
          activeLayerId: 'tile',
          selectedEntityId: 'npc',
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            key: ValueKey<String>('scope-${entry.snapshot.kind.name}'),
            container: container,
            child: MaterialApp(
              theme: PokeMapTheme.dark(),
              home: const Scaffold(
                body: SizedBox(
                  width: 400,
                  height: 600,
                  child: AdaptiveMapInspector(),
                ),
              ),
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey<String>('adaptive-map-inspector')),
          findsOneWidget,
        );
        expect(find.text(entry.title), findsAtLeastNWidgets(1));
        final body = find.byKey(
          ValueKey<String>(
            'world-map-inspector-body-${entry.snapshot.kind.name}',
          ),
        );
        expect(body, findsOneWidget);
        expect(
          _mountedRoutedBodyCount(),
          entry.bodyType == null ? 0 : 1,
          reason: entry.snapshot.kind.name,
        );
        if (entry.bodyType case final bodyType?) {
          expect(find.byType(bodyType), findsOneWidget);
        } else {
          expect(
            find.descendant(
              of: body,
              matching: find.byType(PokeMapEmptyState),
            ),
            findsOneWidget,
          );
        }

        await tester.pumpWidget(const SizedBox.shrink());
        keepAlive.close();
        container.dispose();
      }
    });

    testWidgets(
        'owns pin unpin and close actions through the workspace session',
        (tester) async {
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
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          activeMap: _map,
          activeLayerId: 'tile',
          activeTool: EditorToolType.selection,
        );
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(
        session
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
            )
            .accepted,
        isTrue,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.dark(),
            home: const Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: AdaptiveMapInspector(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Peindre'), findsOneWidget);
      expect(
        tester
            .widget<PokeMapIconButton>(
              find.byKey(
                const ValueKey<String>('world-map-inspector-pin'),
              ),
            )
            .tooltip,
        'Épingler l’inspecteur',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-inspector-pin')),
      );
      await tester.pump();
      expect(
        container.read(worldMapWorkspaceSessionProvider).pinnedInspectorKind,
        WorldMapInspectorKind.paint,
      );
      expect(
        tester
            .widget<PokeMapIconButton>(
              find.byKey(
                const ValueKey<String>('world-map-inspector-pin'),
              ),
            )
            .tooltip,
        'Désépingler l’inspecteur',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-inspector-pin')),
      );
      await tester.pump();
      expect(
        container.read(worldMapWorkspaceSessionProvider).pinnedInspectorKind,
        isNull,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-inspector-close')),
      );
      await tester.pump();
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorVisible,
        isFalse,
      );
    });

    testWidgets('paint header returns to the canonical layers inspector',
        (tester) async {
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
      final editor = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          activeMap: _map,
          activeLayerId: 'tile',
          activeTool: EditorToolType.selection,
        );
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      expect(
        session
            .activateTool(
              editor,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
            )
            .accepted,
        isTrue,
      );
      session.pinInspector(WorldMapInspectorKind.paint);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.dark(),
            home: const Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: AdaptiveMapInspector(),
              ),
            ),
          ),
        ),
      );

      final back = find.byKey(
        const ValueKey<String>('world-map-inspector-back-to-layers'),
      );
      expect(back, findsOneWidget);
      expect(
        tester.widget<PokeMapIconButton>(back).tooltip,
        'Retour à la liste des calques',
      );

      await tester.tap(back);
      await tester.pump();

      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.layers,
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider).pinnedInspectorKind,
        isNull,
      );
      expect(
        container.read(editorNotifierProvider).activeTool,
        EditorToolType.selection,
      );
      expect(find.byType(WorldMapLayersInspector), findsOneWidget);
      expect(back, findsNothing);
    });

    testWidgets('environment header returns to the canonical layers inspector',
        (tester) async {
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
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        activeMap: _map,
        activeLayerId: 'tile',
        activeTool: EditorToolType.selection,
      );
      final session = container.read(worldMapWorkspaceSessionProvider.notifier)
        ..pinInspector(WorldMapInspectorKind.environment);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.dark(),
            home: const Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: AdaptiveMapInspector(),
              ),
            ),
          ),
        ),
      );

      final back = find.byKey(
        const ValueKey<String>('world-map-inspector-back-to-layers'),
      );
      expect(back, findsOneWidget);

      await tester.tap(back);
      await tester.pump();

      expect(
        container.read(worldMapWorkspaceSessionProvider).pinnedInspectorKind,
        isNull,
      );
      expect(find.byType(WorldMapLayersInspector), findsOneWidget);
      expect(back, findsNothing);
      expect(session, isNotNull);
    });

    testWidgets(
        'pins and unpins layerless non-object Place without a stale no-op',
        (tester) async {
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
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        activeMap: _layerlessMap,
        activeTool: EditorToolType.entityPlacement,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.dark(),
            home: const Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: AdaptiveMapInspector(),
              ),
            ),
          ),
        ),
      );

      final pin = find.byKey(
        const ValueKey<String>('world-map-inspector-pin'),
      );
      expect(find.text('Placer'), findsOneWidget);
      expect(tester.widget<PokeMapIconButton>(pin).tooltip,
          'Épingler l’inspecteur');

      await tester.tap(pin);
      await tester.pump();
      expect(
        container.read(worldMapWorkspaceSessionProvider).pinnedInspectorKind,
        WorldMapInspectorKind.place,
      );
      expect(
        container.read(worldMapInspectorSnapshotProvider).pinned,
        isTrue,
      );
      expect(tester.widget<PokeMapIconButton>(pin).tooltip,
          'Désépingler l’inspecteur');

      await tester.tap(pin);
      await tester.pump();
      expect(
        container.read(worldMapWorkspaceSessionProvider).pinnedInspectorKind,
        isNull,
      );
      expect(
        container.read(worldMapInspectorSnapshotProvider).pinned,
        isFalse,
      );
    });

    testWidgets('disables pin when the visible tool context cannot stay pinned',
        (tester) async {
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
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        activeMap: _layerlessMap,
        activeTool: EditorToolType.tilePaint,
        activeBrush: EditorBrush.tile(tileId: 1, tilesetId: 'world'),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.dark(),
            home: const Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: AdaptiveMapInspector(),
              ),
            ),
          ),
        ),
      );

      final pin = find.byKey(
        const ValueKey<String>('world-map-inspector-pin'),
      );
      expect(find.text('Peindre'), findsOneWidget);
      expect(tester.widget<PokeMapIconButton>(pin).onPressed, isNull);

      await tester.tap(pin);
      await tester.pump();
      expect(
        container.read(worldMapWorkspaceSessionProvider).pinnedInspectorKind,
        isNull,
      );
    });
  });
}

int _mountedRoutedBodyCount() {
  return <Type>[
    WorldMapPaintInspector,
    WorldMapEraseInspector,
    WorldMapPlaceInspector,
    WorldMapSelectionInspector,
    WorldMapCellInspector,
    WorldMapLayersInspector,
  ].map((type) => find.byType(type).evaluate().length).reduce((a, b) => a + b);
}

const _map = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Tile',
      cells: <int>[],
    ),
  ],
  entities: <MapEntity>[
    MapEntity(
      id: 'npc',
      name: 'NPC',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 1),
    ),
  ],
);

const _layerlessMap = MapData(
  id: 'layerless',
  name: 'Layerless',
  size: GridSize(width: 4, height: 4),
);
