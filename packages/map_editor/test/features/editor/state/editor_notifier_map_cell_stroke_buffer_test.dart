import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/placed_element_instance_indexer.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  test(
    'tile stroke publishes one immutable map and one undo entry on release',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final source = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 8, height: 8),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            cells: List<int>.filled(64, 0, growable: false),
          ),
        ],
      );
      notifier.state = EditorState(
        activeMap: source,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
        activeBrush: const EditorBrush.tile(tileId: 7, tilesetId: 'world'),
        savedMapSnapshot: source,
      );

      notifier.beginMapStroke();
      await notifier.paintSelectedBrushAt(
        const GridPos(x: 1, y: 2),
        tilesetColumnsById: const <String, int>{},
        partOfStroke: true,
      );
      await notifier.paintSelectedBrushAt(
        const GridPos(x: 5, y: 2),
        tilesetColumnsById: const <String, int>{},
        partOfStroke: true,
      );

      expect(notifier.state.activeMap, same(source));
      expect(notifier.state.mapUndoStack, isEmpty);
      final preview = notifier.activeMapCellStrokePreview!;
      expect(preview.fullLayerCopyCount, 0);
      expect(preview.mapMaterializationCount, 0);
      expect(preview.validationCount, 0);

      notifier.endMapStroke();

      expect(preview.fullLayerCopyCount, 1);
      expect(preview.mapMaterializationCount, 1);
      expect(preview.validationCount, 1);
      final committed = notifier.state.activeMap!;
      expect(committed, isNot(same(source)));
      expect(notifier.state.mapUndoStack, hasLength(1));
      expect(notifier.state.isDirty, isTrue);
      final layer = committed.layers.single as TileLayer;
      expect(resolveTileLayerCell(layer, 2 * 8 + 1), isNotNull);
      expect(resolveTileLayerCell(layer, 2 * 8 + 5), isNotNull);

      notifier.undoMap();
      expect(notifier.state.activeMap, source);
      notifier.redoMap();
      expect(notifier.state.activeMap, committed);
    },
  );

  test(
    'tile stroke commit matches canonical placed-element indexing',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      const project = ProjectManifest(
        name: 'Project',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'world',
            name: 'World',
            relativePath: 'tilesets/world.png',
            source: ProjectRegularAtlasTilesetSource(
              assetId: 'tilesets/world.png',
              pixelWidth: 32,
              pixelHeight: 32,
              tileWidth: 32,
              tileHeight: 32,
            ),
          ),
        ],
        elements: <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'world',
            categoryId: 'nature',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
        ],
      );
      final source = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 2, height: 1),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            cells: List<int>.filled(2, 0, growable: false),
          ),
        ],
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'authored',
            layerId: 'ground',
            elementId: 'sign',
            pos: GridPos(x: 1, y: 0),
          ),
        ],
      );
      notifier.state = EditorState(
        project: project,
        activeMap: source,
        activeLayerId: 'ground',
        activeTool: EditorToolType.tilePaint,
        activeBrush: const EditorBrush.tile(tileId: 1, tilesetId: 'world'),
        savedMapSnapshot: source,
      );

      notifier.beginMapStroke();
      await notifier.paintSelectedBrushAt(
        const GridPos(x: 0, y: 0),
        tilesetColumnsById: const <String, int>{},
        partOfStroke: true,
      );
      notifier.endMapStroke();

      final painted = paintTilePatternOnLayer(
        source,
        layerId: 'ground',
        pos: const GridPos(x: 0, y: 0),
        patternSize: const GridSize(width: 1, height: 1),
        tiles: const <TileLayerPaletteEntry?>[
          TileLayerPaletteEntry(tilesetId: 'world', localTileId: 0),
        ],
      );
      final expected = const PlacedElementInstanceIndexer().syncLayer(
        map: painted,
        project: project,
        layerId: 'ground',
      );

      expect(notifier.state.activeMap, expected);
      expect(notifier.state.activeMap!.placedElements, hasLength(2));
      expect(notifier.state.mapUndoStack, hasLength(1));
    },
  );

  test('collision stroke cancel discards its sparse preview', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.filled(64, false, growable: false),
        ),
      ],
    );
    notifier.state = EditorState(
      activeMap: source,
      activeLayerId: 'collision',
      activeTool: EditorToolType.collisionPaint,
      savedMapSnapshot: source,
    );

    notifier.beginMapStroke();
    notifier.paintCollisionAt(const GridPos(x: 2, y: 2));
    notifier.paintCollisionAt(const GridPos(x: 5, y: 2));

    expect(notifier.state.activeMap, same(source));
    expect(notifier.activeMapCellStrokePreview, isNotNull);
    expect(notifier.activeMapCellStrokePreview!.collisionAt(2 * 8 + 4), isTrue);

    notifier.cancelMapStroke();

    expect(notifier.activeMapCellStrokePreview, isNull);
    expect(notifier.state.activeMap, same(source));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.isDirty, isFalse);
  });

  test('collision stroke commits once and remains atomic through history', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.filled(64, false, growable: false),
        ),
      ],
    );
    notifier.state = EditorState(
      activeMap: source,
      activeLayerId: 'collision',
      activeTool: EditorToolType.collisionPaint,
      savedMapSnapshot: source,
    );

    notifier.beginMapStroke();
    notifier.paintCollisionAt(const GridPos(x: 1, y: 4));
    notifier.paintCollisionAt(const GridPos(x: 6, y: 4));
    final preview = notifier.activeMapCellStrokePreview!;
    notifier.endMapStroke();

    final committed = notifier.state.activeMap!;
    expect(preview.fullLayerCopyCount, 1);
    expect(preview.mapMaterializationCount, 1);
    expect(preview.validationCount, 1);
    expect(notifier.state.mapUndoStack, hasLength(1));
    final collisions = (committed.layers.single as CollisionLayer).collisions;
    for (var x = 1; x <= 6; x++) {
      expect(collisions[4 * 8 + x], isTrue);
    }

    notifier.undoMap();
    expect(notifier.state.activeMap, source);
    notifier.redoMap();
    expect(notifier.state.activeMap, committed);
  });

  test('Smart Tile stroke cancel discards its sparse preview', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final project = ProjectManifest(
      name: 'Project',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'terrain',
            name: 'Terrain',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.uniform,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: <String>['grass'],
          ),
        ],
      ),
    );
    final source = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.smartTile(
          id: 'smart',
          name: 'Smart',
          presetId: 'terrain',
          usage: SmartTileUsage.terrain,
          materialPalette: const <String>['', 'grass'],
          field: SmartTileField.cell(semanticCells: List<int>.filled(64, 0)),
        ),
      ],
    );
    notifier.state = EditorState(
      project: project,
      activeMap: source,
      activeLayerId: 'smart',
      activeTool: EditorToolType.terrainPaint,
      savedMapSnapshot: source,
    );

    notifier.beginMapStroke();
    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 1, y: 3),
      materialId: 'grass',
    );
    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 6, y: 3),
      materialId: 'grass',
    );

    final preview = notifier.activeMapCellStrokePreview!;
    expect(preview.touchedCellCount, 6);
    expect(preview.smartTileMaterialAt(4, 3), 'grass');
    expect(notifier.state.activeMap, same(source));

    notifier.cancelMapStroke();

    expect(notifier.activeMapCellStrokePreview, isNull);
    expect(notifier.state.activeMap, same(source));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.isDirty, isFalse);
  });

  test('canonical adoption rebases an active Smart Tile stroke', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final project = ProjectManifest(
      name: 'Project',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'terrain',
            name: 'Terrain',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.uniform,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: <String>['grass'],
          ),
        ],
      ),
    );
    const sourceLayer = SmartTileLayer(
      id: 'smart',
      name: 'Smart',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(semanticCells: <int>[0, 0]),
    );
    const source = MapData(
      id: 'map',
      name: 'Map',
      size: GridSize(width: 2, height: 1),
      layers: <MapLayer>[sourceLayer],
    );
    final adoptedLayer = applySmartTileMaterialGesture(
      sourceLayer,
      mapSize: source.size,
      cells: const <GridPos>[GridPos(x: 0, y: 0)],
      materialId: 'grass',
    );
    final adopted = replaceSmartTileLayer(source, layer: adoptedLayer);
    notifier.state = EditorState(
      project: project,
      activeMap: source,
      activeMapPath: 'maps/map.json',
      activeLayerId: 'smart',
      activeTool: EditorToolType.terrainPaint,
      savedMapSnapshot: source,
    );

    notifier.beginMapStroke();
    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 1, y: 0),
      materialId: 'grass',
    );
    final preview = notifier.activeMapCellStrokePreview!;

    expect(
      notifier.acceptCanonicalSmartTilePublication(
        manifest: project,
        map: adopted,
        mapRevision: 'revision-2',
        layerId: 'smart',
        preservePaintTool: true,
        preserveCanonicalGestureHistory: true,
      ),
      isTrue,
    );

    expect(notifier.state.mapStrokeStart?.map, same(adopted));
    expect(preview.sourceMap, same(adopted));
    expect(preview.smartTileMaterialAt(0, 0), 'grass');
    expect(preview.smartTileMaterialAt(1, 0), 'grass');

    notifier.endMapStroke();

    expect(
      smartTileSemanticCells(
        notifier.state.activeMap!.layers.single as SmartTileLayer,
      ),
      <int>[1, 1],
    );
    notifier.undoMap();
    expect(notifier.state.activeMap, adopted);
  });
}
