import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/application/world_map_inspector_projector.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/adaptive_map_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('AdaptiveMapInspector', () {
    testWidgets('renders exactly one injected body with the active title',
        (tester) async {
      const cases = <({
        WorldMapInspectorSnapshot snapshot,
        String title,
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
        ),
      ];

      for (final entry in cases) {
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey<String>('scope-${entry.snapshot.kind.name}'),
            overrides: [
              worldMapInspectorSnapshotProvider.overrideWith(
                (ref) => entry.snapshot,
              ),
            ],
            child: MaterialApp(
              theme: PokeMapTheme.dark(),
              home: Scaffold(
                body: SizedBox(
                  width: 400,
                  height: 600,
                  child: AdaptiveMapInspector(
                    bodyBuilder: (context, snapshot) => SizedBox(
                      key: ValueKey<String>(
                        'stub-inspector-${snapshot.kind.name}',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey<String>('adaptive-map-inspector')),
          findsOneWidget,
        );
        expect(find.text(entry.title), findsOneWidget);
        expect(
          find.byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> &&
                key.value.startsWith('stub-inspector-');
          }),
          findsOneWidget,
        );
        expect(
          find.byKey(
            ValueKey<String>('stub-inspector-${entry.snapshot.kind.name}'),
          ),
          findsOneWidget,
        );
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
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: AdaptiveMapInspector(
                  bodyBuilder: (context, snapshot) => SizedBox(
                    key: ValueKey<String>(
                      'stub-inspector-${snapshot.kind.name}',
                    ),
                  ),
                ),
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
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: AdaptiveMapInspector(
                  bodyBuilder: (context, snapshot) => SizedBox(
                    key: ValueKey<String>(
                      'stub-inspector-${snapshot.kind.name}',
                    ),
                  ),
                ),
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
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: AdaptiveMapInspector(
                  bodyBuilder: (context, snapshot) => SizedBox(
                    key: ValueKey<String>(
                      'stub-inspector-${snapshot.kind.name}',
                    ),
                  ),
                ),
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

const _map = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Tile',
      tilesetId: 'world',
      tiles: <int>[],
    ),
  ],
);

const _layerlessMap = MapData(
  id: 'layerless',
  name: 'Layerless',
  size: GridSize(width: 4, height: 4),
);
