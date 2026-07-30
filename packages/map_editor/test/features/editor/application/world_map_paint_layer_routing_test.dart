import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('resolveWorldMapPaintLayerRouting', () {
    final cases = <({
      WorldMapPaintSubtool subtool,
      String compatibleLayerId,
    })>[
      (
        subtool: WorldMapPaintSubtool.tile,
        compatibleLayerId: 'tile',
      ),
      (
        subtool: WorldMapPaintSubtool.terrain,
        compatibleLayerId: 'terrain',
      ),
      (
        subtool: WorldMapPaintSubtool.path,
        compatibleLayerId: 'path',
      ),
      (
        subtool: WorldMapPaintSubtool.surface,
        compatibleLayerId: 'surface',
      ),
      (
        subtool: WorldMapPaintSubtool.border,
        compatibleLayerId: 'border',
      ),
      (
        subtool: WorldMapPaintSubtool.collision,
        compatibleLayerId: 'collision',
      ),
    ];

    for (final testCase in cases) {
      test(
        '${testCase.subtool.name} keeps the current compatible layer',
        () {
          final result = resolveWorldMapPaintLayerRouting(
            map: _allLayerKindsMap,
            activeLayerId: testCase.compatibleLayerId,
            subtool: testCase.subtool,
          );

          expect(result.kind, WorldMapPaintLayerRoutingKind.current);
          expect(result.targetLayerId, testCase.compatibleLayerId);
          expect(
            result.compatibleLayerIds,
            <String>[testCase.compatibleLayerId],
          );
        },
      );
    }

    test('uses a remembered compatible layer before asking the user', () {
      final result = resolveWorldMapPaintLayerRouting(
        map: _multipleTerrainMap,
        activeLayerId: 'tile',
        subtool: WorldMapPaintSubtool.terrain,
        rememberedLayerId: 'terrain-b',
      );

      expect(result.kind, WorldMapPaintLayerRoutingKind.remembered);
      expect(result.targetLayerId, 'terrain-b');
      expect(
        result.compatibleLayerIds,
        <String>['terrain-a', 'terrain-b'],
      );
    });

    test('ignores stale memory and returns every compatible choice', () {
      final result = resolveWorldMapPaintLayerRouting(
        map: _multipleTerrainMap,
        activeLayerId: 'tile',
        subtool: WorldMapPaintSubtool.terrain,
        rememberedLayerId: 'terrain-deleted',
      );

      expect(result.kind, WorldMapPaintLayerRoutingKind.choice);
      expect(result.targetLayerId, isNull);
      expect(
        result.compatibleLayerIds,
        <String>['terrain-a', 'terrain-b'],
      );
    });

    test('selects the sole compatible layer', () {
      final result = resolveWorldMapPaintLayerRouting(
        map: _allLayerKindsMap,
        activeLayerId: 'tile',
        subtool: WorldMapPaintSubtool.path,
      );

      expect(result.kind, WorldMapPaintLayerRoutingKind.unique);
      expect(result.targetLayerId, 'path');
      expect(result.compatibleLayerIds, <String>['path']);
    });

    test('does not choose when several compatible layers exist', () {
      final result = resolveWorldMapPaintLayerRouting(
        map: _multipleTerrainMap,
        activeLayerId: 'tile',
        subtool: WorldMapPaintSubtool.terrain,
      );

      expect(result.kind, WorldMapPaintLayerRoutingKind.choice);
      expect(result.targetLayerId, isNull);
      expect(
        result.compatibleLayerIds,
        <String>['terrain-a', 'terrain-b'],
      );
    });

    test('returns guided absence when no compatible layer exists', () {
      final result = resolveWorldMapPaintLayerRouting(
        map: _tileOnlyMap,
        activeLayerId: 'tile',
        subtool: WorldMapPaintSubtool.collision,
      );

      expect(result.kind, WorldMapPaintLayerRoutingKind.missing);
      expect(result.targetLayerId, isNull);
      expect(result.compatibleLayerIds, isEmpty);
    });
  });

  group('WorldMapWorkspaceSessionController.routePaintSubtool', () {
    test('activates on the current compatible layer without changing it', () {
      final container = _createContainer(
        const EditorState(
          activeMap: _routingMapA,
          activeLayerId: 'terrain-a',
        ),
      );
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      final emissions = <EditorState>[];
      final subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, next) => emissions.add(next),
      );
      addTearDown(subscription.close);

      final result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.terrain,
      );

      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(result.layerId, 'terrain-a');
      expect(emissions, hasLength(1));
      expect(editor.state.activeLayerId, 'terrain-a');
      expect(editor.state.activeTool, EditorToolType.terrainPaint);
      expect(
        container.read(worldMapWorkspaceSessionProvider).activeFamily,
        WorldMapToolFamily.paint,
      );
    });

    test('atomically activates the sole compatible destination layer', () {
      final container = _createContainer(
        const EditorState(
          activeMap: _uniquePathRoutingMap,
          activeLayerId: 'tile',
          savedMapSnapshot: _uniquePathRoutingMap,
          mapUndoStack: <MapHistorySnapshot>[_undo],
          mapRedoStack: <MapHistorySnapshot>[_redo],
          canUndoMap: true,
          canRedoMap: true,
        ),
      );
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      final beforeMap = editor.state.activeMap;
      final beforeUndo = editor.state.mapUndoStack;
      final beforeRedo = editor.state.mapRedoStack;
      final emissions = <EditorState>[];
      final subscription = container.listen<EditorState>(
        editorNotifierProvider,
        (_, next) => emissions.add(next),
      );
      addTearDown(subscription.close);

      final result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.path,
      );

      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(result.layerId, 'path');
      expect(emissions, hasLength(1));
      expect(editor.state.activeLayerId, 'path');
      expect(editor.state.activeTool, EditorToolType.terrainPaint);
      expect(editor.state.activeMap, same(beforeMap));
      expect(editor.state.mapUndoStack, beforeUndo);
      expect(editor.state.mapRedoStack, beforeRedo);
      expect(editor.state.canUndoMap, isTrue);
      expect(editor.state.canRedoMap, isTrue);
      expect(editor.state.isDirty, isFalse);
    });

    test('returns a choice without mutating editor or session', () {
      const initial = EditorState(
        activeMap: _routingMapA,
        activeLayerId: 'tile-a',
        activeTool: EditorToolType.selection,
      );
      final container = _createContainer(initial);
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      final sessionBefore = container.read(worldMapWorkspaceSessionProvider);

      final result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.terrain,
      );

      expect(result.outcome, WorldMapPaintRoutingOutcome.choiceRequired);
      expect(result.layerId, isNull);
      expect(result.compatibleLayerIds, <String>['terrain-a', 'terrain-b']);
      expect(editor.state, same(initial));
      expect(
        container.read(worldMapWorkspaceSessionProvider),
        same(sessionBefore),
      );
    });

    test('returns guided absence without mutating editor or session', () {
      const initial = EditorState(
        activeMap: _tileOnlyMap,
        activeLayerId: 'tile',
        activeTool: EditorToolType.selection,
      );
      final container = _createContainer(initial);
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);
      final sessionBefore = container.read(worldMapWorkspaceSessionProvider);

      final result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.collision,
      );

      expect(result.outcome, WorldMapPaintRoutingOutcome.missingLayer);
      expect(result.layerId, isNull);
      expect(result.compatibleLayerIds, isEmpty);
      expect(editor.state, same(initial));
      expect(
        container.read(worldMapWorkspaceSessionProvider),
        same(sessionBefore),
      );
    });

    test('remembers a chosen layer across A to B to A without leaking', () {
      final container = _createContainer(
        const EditorState(
          activeMap: _routingMapA,
          activeLayerId: 'tile-a',
        ),
      );
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);

      var result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.terrain,
        chosenLayerId: 'terrain-b',
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(editor.state.activeLayerId, 'terrain-b');

      editor.state = const EditorState(
        activeMap: _routingMapB,
        activeLayerId: 'tile-b',
      );
      result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.terrain,
        chosenLayerId: 'terrain-d',
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(editor.state.activeLayerId, 'terrain-d');

      editor.state = const EditorState(
        activeMap: _routingMapA,
        activeLayerId: 'tile-a',
      );
      result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.terrain,
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(editor.state.activeLayerId, 'terrain-b');

      editor.state = const EditorState(
        activeMap: _routingMapB,
        activeLayerId: 'tile-b',
      );
      result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.terrain,
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(editor.state.activeLayerId, 'terrain-d');
    });

    test(
      'isolates routing memory and session reset for identical maps in two projects',
      () {
        final container = _createContainer(
          const EditorState(
            projectRootPath: '/projects/alpha',
            activeMapPath: '/projects/alpha/maps/shared.json',
            activeMap: _sharedProjectMap,
            activeLayerId: 'tile',
          ),
        );
        final editor = container.read(editorNotifierProvider.notifier);
        final session =
            container.read(worldMapWorkspaceSessionProvider.notifier);

        var result = session.routePaintSubtool(
          editor,
          WorldMapPaintSubtool.terrain,
          chosenLayerId: 'terrain-b',
        );
        expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
        expect(editor.state.activeLayerId, 'terrain-b');
        expect(
          container.read(worldMapWorkspaceSessionProvider).lastPaintSubtool,
          WorldMapPaintSubtool.terrain,
        );

        editor.state = const EditorState(
          projectRootPath: '/projects/beta',
          activeMapPath: '/projects/beta/maps/shared.json',
          activeMap: _sharedProjectMap,
          activeLayerId: 'tile',
        );

        expect(
          container.read(worldMapWorkspaceSessionProvider).lastPaintSubtool,
          WorldMapPaintSubtool.tile,
        );
        expect(
          container
              .read(worldMapWorkspaceSessionProvider)
              .lastPaintSubtoolByLayerId,
          isEmpty,
        );
        result = session.routePaintSubtool(
          editor,
          WorldMapPaintSubtool.terrain,
        );
        expect(result.outcome, WorldMapPaintRoutingOutcome.choiceRequired);

        result = session.routePaintSubtool(
          editor,
          WorldMapPaintSubtool.terrain,
          chosenLayerId: 'terrain-a',
        );
        expect(result.outcome, WorldMapPaintRoutingOutcome.activated);

        editor.state = const EditorState(
          projectRootPath: '/projects/alpha',
          activeMapPath: '/projects/alpha/maps/shared.json',
          activeMap: _sharedProjectMap,
          activeLayerId: 'tile',
        );
        result = session.routePaintSubtool(
          editor,
          WorldMapPaintSubtool.terrain,
        );
        expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
        expect(editor.state.activeLayerId, 'terrain-b');

        editor.state = const EditorState(
          projectRootPath: '/projects/beta',
          activeMapPath: '/projects/beta/maps/shared.json',
          activeMap: _sharedProjectMap,
          activeLayerId: 'tile',
        );
        result = session.routePaintSubtool(
          editor,
          WorldMapPaintSubtool.terrain,
        );
        expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
        expect(editor.state.activeLayerId, 'terrain-a');
      },
    );

    test('bounds routing memory with deterministic least-recent eviction', () {
      final container = _createContainer(
        const EditorState(
          projectRootPath: '/projects/0',
          activeMapPath: '/projects/0/maps/shared.json',
          activeMap: _sharedProjectMap,
          activeLayerId: 'tile',
        ),
      );
      final editor = container.read(editorNotifierProvider.notifier);
      final session = container.read(worldMapWorkspaceSessionProvider.notifier);

      for (var index = 0; index < 32; index += 1) {
        editor.state = EditorState(
          projectRootPath: '/projects/$index',
          activeMapPath: '/projects/$index/maps/shared.json',
          activeMap: _sharedProjectMap,
          activeLayerId: 'tile',
        );
        final remembered = session.routePaintSubtool(
          editor,
          WorldMapPaintSubtool.terrain,
          chosenLayerId: 'terrain-b',
        );
        expect(remembered.outcome, WorldMapPaintRoutingOutcome.activated);
      }

      editor.state = const EditorState(
        projectRootPath: '/projects/0',
        activeMapPath: '/projects/0/maps/shared.json',
        activeMap: _sharedProjectMap,
        activeLayerId: 'tile',
      );
      var result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.terrain,
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(result.layerId, 'terrain-b');

      editor.state = const EditorState(
        projectRootPath: '/projects/32',
        activeMapPath: '/projects/32/maps/shared.json',
        activeMap: _sharedProjectMap,
        activeLayerId: 'tile',
      );
      result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.terrain,
        chosenLayerId: 'terrain-a',
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);

      editor.state = const EditorState(
        projectRootPath: '/projects/1',
        activeMapPath: '/projects/1/maps/shared.json',
        activeMap: _sharedProjectMap,
        activeLayerId: 'tile',
      );
      result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.terrain,
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.choiceRequired);

      editor.state = const EditorState(
        projectRootPath: '/projects/0',
        activeMapPath: '/projects/0/maps/shared.json',
        activeMap: _sharedProjectMap,
        activeLayerId: 'tile',
      );
      result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.terrain,
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(result.layerId, 'terrain-b');
    });
  });
}

ProviderContainer _createContainer(EditorState initial) {
  final container = ProviderContainer();
  final keepAlive = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  container.read(editorNotifierProvider.notifier).state = initial;
  addTearDown(() {
    keepAlive.close();
    container.dispose();
  });
  return container;
}

const _allLayerKindsMap = MapData(
  id: 'all-layer-kinds',
  name: 'Tous les calques',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Éléments',
      tilesetId: 'world',
      tiles: <int>[],
    ),
    TerrainLayer(id: 'terrain', name: 'Terrain'),
    PathLayer(id: 'path', name: 'Chemin'),
    SurfaceLayer(id: 'surface', name: 'Surface'),
    BorderLayer(id: 'border', name: 'Bordures'),
    CollisionLayer(id: 'collision', name: 'Collision'),
  ],
);

const _multipleTerrainMap = MapData(
  id: 'multiple-terrain',
  name: 'Plusieurs terrains',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Éléments',
      tilesetId: 'world',
      tiles: <int>[],
    ),
    TerrainLayer(id: 'terrain-a', name: 'Terrain A'),
    TerrainLayer(id: 'terrain-b', name: 'Terrain B'),
  ],
);

const _tileOnlyMap = MapData(
  id: 'tile-only',
  name: 'Éléments uniquement',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Éléments',
      tilesetId: 'world',
      tiles: <int>[],
    ),
  ],
);

const _routingMapA = MapData(
  id: 'map-a',
  name: 'Map A',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile-a',
      name: 'Éléments A',
      tilesetId: 'world',
      tiles: <int>[],
    ),
    TerrainLayer(id: 'terrain-a', name: 'Terrain A'),
    TerrainLayer(id: 'terrain-b', name: 'Terrain B'),
  ],
);

const _routingMapB = MapData(
  id: 'map-b',
  name: 'Map B',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile-b',
      name: 'Éléments B',
      tilesetId: 'world',
      tiles: <int>[],
    ),
    TerrainLayer(id: 'terrain-c', name: 'Terrain C'),
    TerrainLayer(id: 'terrain-d', name: 'Terrain D'),
  ],
);

const _sharedProjectMap = MapData(
  id: 'shared-map',
  name: 'Carte partagée',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Éléments',
      tilesetId: 'world',
      tiles: <int>[],
    ),
    TerrainLayer(id: 'terrain-a', name: 'Terrain A'),
    TerrainLayer(id: 'terrain-b', name: 'Terrain B'),
  ],
);

const _uniquePathRoutingMap = MapData(
  id: 'unique-path',
  name: 'Chemin unique',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Éléments',
      tilesetId: 'world',
      tiles: <int>[],
    ),
    PathLayer(id: 'path', name: 'Chemin'),
  ],
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
