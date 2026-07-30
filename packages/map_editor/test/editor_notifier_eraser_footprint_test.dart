import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_tool_preview.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier independent eraser footprint', () {
    test('a multi-tile active brush still erases 1x1 by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'world',
            tiles: <int>[7, 7, 7, 7, 7, 7, 7, 7, 7],
          ),
        ],
      );
      notifier.state = const EditorState(
        project: _projectWithLargeBrush,
        activeMap: map,
        activeLayerId: 'ground',
        activeTool: EditorToolType.eraser,
        activeBrush: EditorBrush.projectElement(elementId: 'house'),
        savedMapSnapshot: map,
      );

      final preview = notifier.resolveMapToolPreview(
        hoveredTile: const GridPos(x: 1, y: 1),
        tilesetColumnsById: const <String, int>{},
      );
      expect(preview?.size, const GridSize(width: 1, height: 1));

      notifier.beginMapStroke();
      notifier.eraseAt(const GridPos(x: 1, y: 1));
      notifier.endMapStroke();

      final state = container.read(editorNotifierProvider);
      final layer = state.activeMap!.layers.single as TileLayer;
      expect(layer.tiles, const <int>[7, 7, 7, 7, 0, 7, 7, 7, 7]);
      expect(state.mapUndoStack, hasLength(1));
      expect(state.isDirty, isTrue);
    });

    test(
        'previous brush captures once and ignores later brush, layer, and collision size changes',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithLayers(
        const <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'world',
            tiles: <int>[
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
              7,
            ],
          ),
          CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: <bool>[
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
            ],
          ),
        ],
      );
      notifier.state = EditorState(
        project: _projectWithLargeBrush,
        activeMap: map,
        activeLayerId: 'ground',
        activeTool: EditorToolType.eraser,
        activeBrush: const EditorBrush.projectElement(elementId: 'house'),
        savedMapSnapshot: map,
      );

      expect(notifier.capturePreviousBrushEraserFootprint(), isTrue);
      expect(
        notifier.state.eraserFootprint,
        const EditorEraserFootprint.previousBrush(
          size: GridSize(width: 2, height: 3),
        ),
      );
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);

      notifier.state = notifier.state.copyWith(
        activeBrush: const EditorBrush.none(),
      );
      notifier.setCollisionBrushSizeMode(CollisionBrushSizeMode.singleTile);
      notifier.setActiveLayer('collision');

      final preview = notifier.resolveMapToolPreview(
        hoveredTile: const GridPos(x: 1, y: 0),
        tilesetColumnsById: const <String, int>{},
      );
      expect(preview?.size, const GridSize(width: 2, height: 3));

      notifier.beginMapStroke();
      notifier.eraseAt(const GridPos(x: 1, y: 0));
      notifier.endMapStroke();

      final layer = notifier.state.activeMap!.layers[1] as CollisionLayer;
      expect(
        layer.collisions,
        const <bool>[
          true,
          false,
          false,
          true,
          true,
          false,
          false,
          true,
          true,
          false,
          false,
          true,
          true,
          true,
          true,
          true,
        ],
      );
    });

    test('custom dimensions are validated without touching map history', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapFor(_LayerKind.tile);
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'layer',
        activeTool: EditorToolType.eraser,
        savedMapSnapshot: map,
      );

      expect(notifier.setCustomEraserFootprint(width: 1, height: 1), isTrue);
      expect(notifier.setCustomEraserFootprint(width: 0, height: 1), isFalse);
      expect(notifier.setCustomEraserFootprint(width: -1, height: 1), isFalse);
      expect(
        notifier.setCustomEraserFootprint(
          width: kMaxEditorEraserFootprintDimension + 1,
          height: 1,
        ),
        isFalse,
      );
      expect(
        notifier.setCustomEraserFootprint(
          width: kMaxEditorEraserFootprintDimension,
          height: kMaxEditorEraserFootprintDimension,
        ),
        isTrue,
      );

      expect(
        notifier.state.eraserFootprint,
        const EditorEraserFootprint.custom(
          size: GridSize(
            width: kMaxEditorEraserFootprintDimension,
            height: kMaxEditorEraserFootprintDimension,
          ),
        ),
      );
      expect(notifier.state.activeMap, map);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);
    });

    for (final kind in _LayerKind.values) {
      test('${kind.name} preview and commit share the custom rectangle', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(editorNotifierProvider.notifier);
        final map = _mapFor(kind);
        notifier.state = EditorState(
          activeMap: map,
          activeLayerId: 'layer',
          activeTool: EditorToolType.eraser,
          eraserFootprint: const EditorEraserFootprint.custom(
            size: GridSize(width: 2, height: 2),
          ),
          savedMapSnapshot: map,
        );

        final preview = notifier.resolveMapToolPreview(
          hoveredTile: const GridPos(x: 1, y: 1),
          tilesetColumnsById: const <String, int>{},
        );
        expect(preview?.size, const GridSize(width: 2, height: 2));

        notifier.beginMapStroke();
        notifier.eraseAt(const GridPos(x: 1, y: 1));
        notifier.endMapStroke();

        final layer = notifier.state.activeMap!.layers.single;
        for (var y = 0; y < 4; y++) {
          for (var x = 0; x < 4; x++) {
            final shouldRemain = x < 1 || x > 2 || y < 1 || y > 2;
            expect(
              _isFilled(layer, x: x, y: y),
              shouldRemain,
              reason: '${kind.name} cell ($x,$y)',
            );
          }
        }
        expect(notifier.state.mapUndoStack, hasLength(1));
      });

      test('${kind.name} erase clips at the lower-right map edge', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(editorNotifierProvider.notifier);
        final map = _mapFor(kind);
        notifier.state = EditorState(
          activeMap: map,
          activeLayerId: 'layer',
          activeTool: EditorToolType.eraser,
          eraserFootprint: const EditorEraserFootprint.custom(
            size: GridSize(width: 2, height: 3),
          ),
          savedMapSnapshot: map,
        );

        final preview = notifier.resolveMapToolPreview(
          hoveredTile: const GridPos(x: 3, y: 3),
          tilesetColumnsById: const <String, int>{},
        );
        expect(preview?.size, const GridSize(width: 2, height: 3));

        notifier.beginMapStroke();
        notifier.eraseAt(const GridPos(x: 3, y: 3));
        notifier.endMapStroke();

        final layer = notifier.state.activeMap!.layers.single;
        for (var y = 0; y < 4; y++) {
          for (var x = 0; x < 4; x++) {
            expect(
              _isFilled(layer, x: x, y: y),
              x != 3 || y != 3,
              reason: '${kind.name} clipped cell ($x,$y)',
            );
          }
        }
      });
    }

    test('collision brush sizing affects collision paint but never eraser', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapFor(_LayerKind.collision);
      notifier.state = EditorState(
        project: _projectWithLargeBrush,
        activeMap: map,
        activeLayerId: 'layer',
        activeTool: EditorToolType.eraser,
        activeBrush: const EditorBrush.projectElement(elementId: 'house'),
        collisionBrushSizeMode: CollisionBrushSizeMode.brushFootprint,
        savedMapSnapshot: map,
      );

      MapToolPreview? preview() => notifier.resolveMapToolPreview(
            hoveredTile: const GridPos(x: 0, y: 0),
            tilesetColumnsById: const <String, int>{},
          );

      expect(preview()?.size, const GridSize(width: 1, height: 1));
      notifier.toggleCollisionBrushSizeMode();
      expect(preview()?.size, const GridSize(width: 1, height: 1));

      notifier.setCollisionBrushSizeMode(
        CollisionBrushSizeMode.brushFootprint,
      );
      notifier.selectTool(EditorToolType.collisionPaint);
      expect(preview()?.size, const GridSize(width: 2, height: 3));
    });

    test('invalid injected footprint is rejected before preview or commit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapFor(_LayerKind.tile);
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'layer',
        activeTool: EditorToolType.eraser,
        eraserFootprint: const EditorEraserFootprint.previousBrush(
          size: GridSize(
            width: kMaxEditorEraserFootprintDimension + 1,
            height: 1,
          ),
        ),
        savedMapSnapshot: map,
      );

      expect(
        notifier.resolveMapToolPreview(
          hoveredTile: const GridPos(x: 0, y: 0),
          tilesetColumnsById: const <String, int>{},
        ),
        isNull,
      );
      notifier.eraseAt(const GridPos(x: 0, y: 0));

      expect(notifier.state.activeMap, map);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.errorMessage, contains('between 1 and'));
    });

    test('erasing an already empty rectangle is a clean no-op', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _emptyTileMap();
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'layer',
        activeTool: EditorToolType.eraser,
        eraserFootprint: const EditorEraserFootprint.custom(
          size: GridSize(width: 2, height: 2),
        ),
        savedMapSnapshot: map,
      );

      notifier.beginMapStroke();
      notifier.eraseAt(const GridPos(x: 1, y: 1));
      notifier.endMapStroke();

      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);
    });

    test('multiple erase samples in one stroke create one undo entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapFor(_LayerKind.tile);
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'layer',
        activeTool: EditorToolType.eraser,
        eraserFootprint: const EditorEraserFootprint.custom(
          size: GridSize(width: 2, height: 1),
        ),
        savedMapSnapshot: map,
      );

      notifier.beginMapStroke();
      notifier.eraseAt(const GridPos(x: 0, y: 0));
      notifier.eraseAt(const GridPos(x: 2, y: 0));
      notifier.endMapStroke();

      expect(notifier.state.mapUndoStack, hasLength(1));
      expect(notifier.state.isDirty, isTrue);
      expect(
        (notifier.state.activeMap!.layers.single as TileLayer).tiles.take(4),
        everyElement(0),
      );

      notifier.undoMap();
      expect(notifier.state.activeMap, map);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);
    });

    for (final kind in _LayerKind.values) {
      test(
          'eraseCellAt addresses exactly one ${kind.name} cell outside strokes',
          () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(editorNotifierProvider.notifier);
        final map = _mapFor(kind);
        notifier.state = EditorState(
          activeMap: map,
          activeLayerId: 'layer',
          activeTool: EditorToolType.selection,
          eraserFootprint: const EditorEraserFootprint.custom(
            size: GridSize(width: 3, height: 3),
          ),
          savedMapSnapshot: map,
        );

        expect(
          notifier.eraseCellAt(
            layerId: 'layer',
            pos: const GridPos(x: 1, y: 1),
          ),
          isTrue,
        );

        final state = notifier.state;
        final layer = state.activeMap!.layers.single;
        for (var y = 0; y < 4; y++) {
          for (var x = 0; x < 4; x++) {
            expect(
              _isFilled(layer, x: x, y: y),
              x != 1 || y != 1,
              reason: '${kind.name} cell ($x,$y)',
            );
          }
        }
        expect(
          state.eraserFootprint,
          const EditorEraserFootprint.custom(
            size: GridSize(width: 3, height: 3),
          ),
        );
        expect(state.mapStrokeStart, isNull);
        expect(state.mapUndoStack, hasLength(1));

        notifier.undoMap();
        expect(notifier.state.activeMap, map);
      });
    }

    test('eraseCellAt rejects stale, unsupported and no-op targets cleanly',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithLayers(
        const <MapLayer>[
          ObjectLayer(id: 'objects', name: 'Objects'),
          TileLayer(
            id: 'empty',
            name: 'Empty',
            tilesetId: 'world',
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
            ],
          ),
        ],
      );
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'objects',
        savedMapSnapshot: map,
      );

      expect(
        notifier.eraseCellAt(
          layerId: 'missing',
          pos: const GridPos(x: 0, y: 0),
        ),
        isFalse,
      );
      expect(
        notifier.eraseCellAt(
          layerId: 'objects',
          pos: const GridPos(x: 0, y: 0),
        ),
        isFalse,
      );
      expect(
        notifier.eraseCellAt(
          layerId: 'empty',
          pos: const GridPos(x: 0, y: 0),
        ),
        isFalse,
      );
      expect(
        notifier.eraseCellAt(
          layerId: 'empty',
          pos: const GridPos(x: -1, y: 0),
        ),
        isFalse,
      );

      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.mapStrokeStart, isNull);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);
    });
  });
}

const _projectWithLargeBrush = ProjectManifest(
  name: 'Eraser Test',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'house',
      name: 'House',
      tilesetId: 'world',
      categoryId: 'buildings',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
        ),
      ],
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

enum _LayerKind { tile, collision, terrain, path, surface }

MapData _mapFor(_LayerKind kind) {
  const filledTiles = <int>[
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
  ];
  const filledFlags = <bool>[
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
  ];
  const filledTerrain = <TerrainType>[
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
    TerrainType.rock,
  ];
  final layer = switch (kind) {
    _LayerKind.tile => const MapLayer.tile(
        id: 'layer',
        name: 'Tiles',
        tilesetId: 'world',
        tiles: filledTiles,
      ),
    _LayerKind.collision => const MapLayer.collision(
        id: 'layer',
        name: 'Collision',
        collisions: filledFlags,
      ),
    _LayerKind.terrain => const MapLayer.terrain(
        id: 'layer',
        name: 'Terrain',
        terrains: filledTerrain,
      ),
    _LayerKind.path => const MapLayer.path(
        id: 'layer',
        name: 'Path',
        presetId: 'road',
        cells: filledFlags,
      ),
    _LayerKind.surface => MapLayer.surface(
        id: 'layer',
        name: 'Surface',
        placements: <SurfaceCellPlacement>[
          for (var y = 0; y < 4; y++)
            for (var x = 0; x < 4; x++)
              SurfaceCellPlacement(
                x: x,
                y: y,
                surfacePresetId: 'water',
              ),
        ],
      ),
  };
  return _mapWithLayers(<MapLayer>[layer]);
}

MapData _emptyTileMap() {
  return _mapWithLayers(
    const <MapLayer>[
      MapLayer.tile(
        id: 'layer',
        name: 'Tiles',
        tilesetId: 'world',
        tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
  );
}

MapData _mapWithLayers(List<MapLayer> layers) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 4),
    layers: layers,
  );
}

bool _isFilled(MapLayer layer, {required int x, required int y}) {
  final index = y * 4 + x;
  return switch (layer) {
    TileLayer(:final tiles) => tiles[index] != 0,
    CollisionLayer(:final collisions) => collisions[index],
    TerrainLayer(:final terrains) => terrains[index] != TerrainType.none,
    PathLayer(:final cells) => cells[index],
    SurfaceLayer(:final placements) =>
      placements.any((placement) => placement.x == x && placement.y == y),
    _ => throw StateError('Unsupported layer: ${layer.runtimeType}'),
  };
}
