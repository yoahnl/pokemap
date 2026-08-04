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
  test('Smart Tile routing fixtures are valid native v5 maps', () {
    for (final map in const <MapData>[
      _allLayerKindsMap,
      _multiplePathMap,
      _smartTileTerrainMap,
      _smartTilePathMap,
      _routingMapA,
      _routingMapB,
      _sharedProjectMap,
      _uniquePathRoutingMap,
    ]) {
      expect(
        () => MapValidator.validate(map),
        returnsNormally,
        reason: map.id,
      );
    }
  });

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
        compatibleLayerId: 'smart-terrain',
      ),
      (
        subtool: WorldMapPaintSubtool.path,
        compatibleLayerId: 'smart-path',
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

    test('terrain keeps the current published Smart Tile terrain layer', () {
      final result = resolveWorldMapPaintLayerRouting(
        map: _smartTileTerrainMap,
        activeLayerId: 'smart-terrain',
        subtool: WorldMapPaintSubtool.terrain,
      );

      expect(result.kind, WorldMapPaintLayerRoutingKind.current);
      expect(result.targetLayerId, 'smart-terrain');
      expect(result.compatibleLayerIds, <String>['smart-terrain']);
    });

    test('path keeps the current published Smart Tile path layer', () {
      final result = resolveWorldMapPaintLayerRouting(
        map: _smartTilePathMap,
        activeLayerId: 'smart-path',
        subtool: WorldMapPaintSubtool.path,
      );

      expect(result.kind, WorldMapPaintLayerRoutingKind.current);
      expect(result.targetLayerId, 'smart-path');
      expect(result.compatibleLayerIds, <String>['smart-path']);
    });

    test('uses a remembered compatible layer before asking the user', () {
      final result = resolveWorldMapPaintLayerRouting(
        map: _multiplePathMap,
        activeLayerId: 'tile',
        subtool: WorldMapPaintSubtool.path,
        rememberedLayerId: 'path-b',
      );

      expect(result.kind, WorldMapPaintLayerRoutingKind.remembered);
      expect(result.targetLayerId, 'path-b');
      expect(
        result.compatibleLayerIds,
        <String>['path-a', 'path-b'],
      );
    });

    test('ignores stale memory and returns every compatible choice', () {
      final result = resolveWorldMapPaintLayerRouting(
        map: _multiplePathMap,
        activeLayerId: 'tile',
        subtool: WorldMapPaintSubtool.path,
        rememberedLayerId: 'path-deleted',
      );

      expect(result.kind, WorldMapPaintLayerRoutingKind.choice);
      expect(result.targetLayerId, isNull);
      expect(
        result.compatibleLayerIds,
        <String>['path-a', 'path-b'],
      );
    });

    test('selects the sole compatible layer', () {
      final result = resolveWorldMapPaintLayerRouting(
        map: _allLayerKindsMap,
        activeLayerId: 'tile',
        subtool: WorldMapPaintSubtool.path,
      );

      expect(result.kind, WorldMapPaintLayerRoutingKind.unique);
      expect(result.targetLayerId, 'smart-path');
      expect(result.compatibleLayerIds, <String>['smart-path']);
    });

    test('does not choose when several compatible layers exist', () {
      final result = resolveWorldMapPaintLayerRouting(
        map: _multiplePathMap,
        activeLayerId: 'tile',
        subtool: WorldMapPaintSubtool.path,
      );

      expect(result.kind, WorldMapPaintLayerRoutingKind.choice);
      expect(result.targetLayerId, isNull);
      expect(
        result.compatibleLayerIds,
        <String>['path-a', 'path-b'],
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
          activeLayerId: 'path-a',
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
        WorldMapPaintSubtool.path,
      );

      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(result.layerId, 'path-a');
      expect(emissions, hasLength(1));
      expect(editor.state.activeLayerId, 'path-a');
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
        WorldMapPaintSubtool.path,
      );

      expect(result.outcome, WorldMapPaintRoutingOutcome.choiceRequired);
      expect(result.layerId, isNull);
      expect(result.compatibleLayerIds, <String>['path-a', 'path-b']);
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
        WorldMapPaintSubtool.path,
        chosenLayerId: 'path-b',
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(editor.state.activeLayerId, 'path-b');

      editor.state = const EditorState(
        activeMap: _routingMapB,
        activeLayerId: 'tile-b',
      );
      result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.path,
        chosenLayerId: 'path-d',
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(editor.state.activeLayerId, 'path-d');

      editor.state = const EditorState(
        activeMap: _routingMapA,
        activeLayerId: 'tile-a',
      );
      result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.path,
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(editor.state.activeLayerId, 'path-b');

      editor.state = const EditorState(
        activeMap: _routingMapB,
        activeLayerId: 'tile-b',
      );
      result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.path,
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(editor.state.activeLayerId, 'path-d');
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
          WorldMapPaintSubtool.path,
          chosenLayerId: 'path-b',
        );
        expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
        expect(editor.state.activeLayerId, 'path-b');
        expect(
          container.read(worldMapWorkspaceSessionProvider).lastPaintSubtool,
          WorldMapPaintSubtool.path,
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
          WorldMapPaintSubtool.path,
        );
        expect(result.outcome, WorldMapPaintRoutingOutcome.choiceRequired);

        result = session.routePaintSubtool(
          editor,
          WorldMapPaintSubtool.path,
          chosenLayerId: 'path-a',
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
          WorldMapPaintSubtool.path,
        );
        expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
        expect(editor.state.activeLayerId, 'path-b');

        editor.state = const EditorState(
          projectRootPath: '/projects/beta',
          activeMapPath: '/projects/beta/maps/shared.json',
          activeMap: _sharedProjectMap,
          activeLayerId: 'tile',
        );
        result = session.routePaintSubtool(
          editor,
          WorldMapPaintSubtool.path,
        );
        expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
        expect(editor.state.activeLayerId, 'path-a');
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
          WorldMapPaintSubtool.path,
          chosenLayerId: 'path-b',
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
        WorldMapPaintSubtool.path,
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(result.layerId, 'path-b');

      editor.state = const EditorState(
        projectRootPath: '/projects/32',
        activeMapPath: '/projects/32/maps/shared.json',
        activeMap: _sharedProjectMap,
        activeLayerId: 'tile',
      );
      result = session.routePaintSubtool(
        editor,
        WorldMapPaintSubtool.path,
        chosenLayerId: 'path-a',
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
        WorldMapPaintSubtool.path,
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
        WorldMapPaintSubtool.path,
      );
      expect(result.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(result.layerId, 'path-b');
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
  version: ProjectVersion.v6,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Éléments',
      cells: _sixteenCells,
    ),
    SmartTileLayer(
      id: 'smart-terrain',
      name: 'Terrain',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
    SmartTileLayer(
      id: 'smart-path',
      name: 'Chemin',
      presetId: 'path',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
    SmartTileLayer(
      id: 'surface',
      name: 'Surface',
      presetId: 'surface',
      usage: SmartTileUsage.forestSurface,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
    BorderLayer(id: 'border', name: 'Bordures'),
    CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: _sixteenCollisions,
    ),
  ],
);

const _multiplePathMap = MapData(
  id: 'multiple-path',
  name: 'Plusieurs chemins',
  version: ProjectVersion.v6,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Éléments',
      cells: _sixteenCells,
    ),
    SmartTileLayer(
      id: 'path-a',
      name: 'Chemin A',
      presetId: 'path-a',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
    SmartTileLayer(
      id: 'path-b',
      name: 'Chemin B',
      presetId: 'path-b',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
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
      cells: _sixteenCells,
    ),
  ],
);

const _smartTileTerrainMap = MapData(
  id: 'smart-tile-terrain',
  name: 'Terrain intelligent',
  version: ProjectVersion.v6,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    SmartTileLayer(
      id: 'smart-terrain',
      name: 'Prairie intelligente',
      presetId: 'prairie',
      usage: SmartTileUsage.terrain,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
  ],
);

const _smartTilePathMap = MapData(
  id: 'smart-tile-path',
  name: 'Chemin intelligent',
  version: ProjectVersion.v6,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    SmartTileLayer(
      id: 'smart-path',
      name: 'Chemin intelligent',
      presetId: 'path',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
  ],
);

const _routingMapA = MapData(
  id: 'map-a',
  name: 'Map A',
  version: ProjectVersion.v6,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile-a',
      name: 'Éléments A',
      cells: _sixteenCells,
    ),
    SmartTileLayer(
      id: 'path-a',
      name: 'Chemin A',
      presetId: 'path-a',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
    SmartTileLayer(
      id: 'path-b',
      name: 'Chemin B',
      presetId: 'path-b',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
  ],
);

const _routingMapB = MapData(
  id: 'map-b',
  name: 'Map B',
  version: ProjectVersion.v6,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile-b',
      name: 'Éléments B',
      cells: _sixteenCells,
    ),
    SmartTileLayer(
      id: 'path-c',
      name: 'Chemin C',
      presetId: 'path-c',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
    SmartTileLayer(
      id: 'path-d',
      name: 'Chemin D',
      presetId: 'path-d',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
  ],
);

const _sharedProjectMap = MapData(
  id: 'shared-map',
  name: 'Carte partagée',
  version: ProjectVersion.v6,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Éléments',
      cells: _sixteenCells,
    ),
    SmartTileLayer(
      id: 'path-a',
      name: 'Chemin A',
      presetId: 'path-a',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
    SmartTileLayer(
      id: 'path-b',
      name: 'Chemin B',
      presetId: 'path-b',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
  ],
);

const _uniquePathRoutingMap = MapData(
  id: 'unique-path',
  name: 'Chemin unique',
  version: ProjectVersion.v6,
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'tile',
      name: 'Éléments',
      cells: _sixteenCells,
    ),
    SmartTileLayer(
      id: 'path',
      name: 'Chemin',
      presetId: 'path',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: _sixteenCells),
    ),
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

const _sixteenCells = <int>[
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
];

const _sixteenCollisions = <bool>[
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
  false,
];
