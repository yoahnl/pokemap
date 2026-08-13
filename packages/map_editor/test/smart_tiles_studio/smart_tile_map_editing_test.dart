import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_tool_preview.dart';
import 'package:map_editor/src/application/services/editor_performance_telemetry.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  test('EditorNotifier requires the canonical Smart Tile layer action', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 1, height: 1),
    );
    notifier.state = EditorState(
      project: _project,
      activeMap: map,
      savedMapSnapshot: map,
    );

    notifier.addSmartTileLayer(
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      defaultMaterialId: 'grass',
      name: 'Terrain',
    );

    expect(notifier.state.activeMap, map);
    expect(notifier.state.activeMap!.layers, isEmpty);
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.mapRedoStack, isEmpty);
    expect(notifier.state.isDirty, isFalse);
    expect(
      notifier.state.errorMessage,
      smartTileCanonicalLayerActionRequiredCode,
    );
  });

  test('cell Smart Tile fields keep paint, preview, erase, and history', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    const layer = MapLayer.smartTile(
      id: 'smart',
      name: 'Smart',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: ['', 'grass'],
      field: SmartTileField.cell(semanticCells: [0]),
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 1, height: 1),
      layers: [layer],
    );
    notifier.state = EditorState(
      project: _project,
      activeMap: map,
      savedMapSnapshot: map,
      activeLayerId: 'smart',
      activeTool: EditorToolType.terrainPaint,
    );

    final paintPreview = notifier.resolveMapToolPreview(
      hoveredTile: const GridPos(x: 0, y: 0),
      tilesetColumnsById: const <String, int>{},
    );
    expect(paintPreview?.validity, MapToolPreviewValidity.valid);
    expect(paintPreview?.reason, isNull);
    expect(
      notifier.resolveCurrentPaintFootprintForEraser(),
      const GridSize(width: 1, height: 1),
    );

    notifier.beginMapStroke();
    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 0, y: 0),
      materialId: 'grass',
    );
    expect(notifier.state.activeMap, same(map));
    expect(
      notifier.activeMapCellStrokePreview!.smartTileMaterialAt(0, 0),
      'grass',
    );
    expect(notifier.state.errorMessage, isNull);
    notifier.endMapStroke();
    var edited = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(smartTileSemanticCells(edited), [1]);
    expect(notifier.state.mapUndoStack, hasLength(1));
    expect(notifier.state.isDirty, isTrue);

    notifier.state = notifier.state.copyWith(activeTool: EditorToolType.eraser);
    final erasePreview = notifier.resolveMapToolPreview(
      hoveredTile: const GridPos(x: 0, y: 0),
      tilesetColumnsById: const <String, int>{},
    );
    expect(erasePreview?.validity, MapToolPreviewValidity.valid);
    expect(erasePreview?.reason, isNull);

    expect(
      notifier.eraseCellAt(
        layerId: 'smart',
        pos: const GridPos(x: 0, y: 0),
      ),
      isTrue,
    );
    edited = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(smartTileSemanticCells(edited), [0]);
    expect(notifier.state.mapUndoStack, hasLength(2));
    expect(notifier.state.mapRedoStack, isEmpty);
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.errorMessage, isNull);

    notifier.undoMap();
    edited = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(smartTileSemanticCells(edited), [1]);
  });

  test('Smart Tile drag validates and materializes only on release', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 128, height: 128),
      layers: <MapLayer>[
        MapLayer.smartTile(
          id: 'smart',
          name: 'Smart',
          presetId: 'terrain',
          usage: SmartTileUsage.terrain,
          materialPalette: const <String>['', 'grass'],
          field: SmartTileField.cell(
            semanticCells: List<int>.filled(128 * 128, 0, growable: false),
          ),
        ),
      ],
    );
    notifier.state = EditorState(
      project: _project,
      activeMap: source,
      savedMapSnapshot: source,
      activeLayerId: 'smart',
      activeTool: EditorToolType.terrainPaint,
    );
    final recorder = EditorPerformanceRecorder();
    final recording = EditorPerformanceTelemetry.startRecording(recorder);
    addTearDown(recording.close);

    notifier.beginMapStroke();
    for (var x = 0; x < 100; x++) {
      notifier.paintSmartTileMaterialAt(
        GridPos(x: x, y: 8),
        materialId: 'grass',
      );
    }

    final buffer = notifier.activeMapCellStrokePreview!;
    expect(notifier.state.activeMap, same(source));
    expect(buffer.touchedCellCount, 100);
    expect(buffer.fullLayerCopyCount, 0);
    expect(buffer.mapMaterializationCount, 0);
    expect(buffer.validationCount, 0);
    expect(
      recorder.snapshot().spanSamples(
        EditorPerformanceSpanName.mapFullValidation,
      ),
      isEmpty,
    );

    notifier.endMapStroke();

    expect(buffer.fullLayerCopyCount, 1);
    expect(buffer.mapMaterializationCount, 1);
    expect(buffer.validationCount, 1);
    expect(
      recorder.snapshot().spanSamples(
        EditorPerformanceSpanName.mapIncrementalValidation,
      ),
      hasLength(1),
    );
    expect(
      recorder.snapshot().spanSamples(
        EditorPerformanceSpanName.mapFullValidation,
      ),
      isEmpty,
    );
    expect(notifier.state.mapUndoStack, hasLength(1));
  });

  test('edge Smart Tile fields keep paint, preview, erase, and history', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    const layer = MapLayer.smartTile(
      id: 'smart',
      name: 'Smart',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: ['', 'grass'],
      field: SmartTileField.edge(
        semanticCells: [0],
        horizontalEdges: [0, 0],
        verticalEdges: [0, 0],
      ),
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 1, height: 1),
      layers: [layer],
    );
    notifier.state = EditorState(
      project: _wangProject,
      activeMap: map,
      savedMapSnapshot: map,
      activeLayerId: 'smart',
      activeTool: EditorToolType.terrainPaint,
    );

    final paintPreview = notifier.resolveMapToolPreview(
      hoveredTile: const GridPos(x: 0, y: 0),
      tilesetColumnsById: const <String, int>{},
    );
    expect(paintPreview?.validity, MapToolPreviewValidity.valid);
    expect(paintPreview?.reason, isNull);
    expect(
      notifier.resolveCurrentPaintFootprintForEraser(),
      const GridSize(width: 1, height: 1),
    );

    notifier.beginMapStroke();
    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 0, y: 0),
      materialId: 'grass',
    );
    notifier.endMapStroke();
    var edited = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(notifier.state.errorMessage, isNull);
    expect(smartTileSemanticCells(edited), <int>[1]);
    expect(smartTileHorizontalEdges(edited), <int>[1, 1]);
    expect(smartTileVerticalEdges(edited), <int>[1, 1]);
    expect(notifier.state.mapUndoStack, hasLength(1));

    notifier.state = notifier.state.copyWith(activeTool: EditorToolType.eraser);
    final erasePreview = notifier.resolveMapToolPreview(
      hoveredTile: const GridPos(x: 0, y: 0),
      tilesetColumnsById: const <String, int>{},
    );
    expect(erasePreview?.validity, MapToolPreviewValidity.valid);
    expect(erasePreview?.reason, isNull);

    expect(
      notifier.eraseCellAt(
        layerId: 'smart',
        pos: const GridPos(x: 0, y: 0),
      ),
      isTrue,
    );
    edited = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(smartTileSemanticCells(edited), <int>[0]);
    expect(smartTileHorizontalEdges(edited), <int>[0, 0]);
    expect(smartTileVerticalEdges(edited), <int>[0, 0]);
    expect(notifier.state.mapUndoStack, hasLength(2));
    expect(notifier.state.errorMessage, isNull);

    notifier.undoMap();
    edited = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(smartTileHorizontalEdges(edited), <int>[1, 1]);
  });

  test('line, rectangle and flood fill each create one editor undo boundary',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    const layer = MapLayer.smartTile(
      id: 'smart',
      name: 'Smart',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(
        semanticCells: <int>[
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
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 4, height: 3),
      layers: <MapLayer>[layer],
    );
    notifier.state = EditorState(
      project: _project,
      activeMap: map,
      savedMapSnapshot: map,
      activeLayerId: 'smart',
      activeTool: EditorToolType.terrainPaint,
    );

    notifier.applyActiveSmartTileSelection(
      const SmartTileGestureSelection.line(
        start: GridPos(x: 0, y: 0),
        end: GridPos(x: 1, y: 0),
      ),
    );
    expect(
      smartTileSemanticCells(
        notifier.state.activeMap!.layers.single as SmartTileLayer,
      ),
      <int>[1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    );
    expect(notifier.state.mapUndoStack, hasLength(1));

    notifier.applyActiveSmartTileSelection(
      const SmartTileGestureSelection.rectangle(
        start: GridPos(x: 2, y: 1),
        end: GridPos(x: 3, y: 2),
      ),
    );
    expect(notifier.state.mapUndoStack, hasLength(2));

    notifier.state = notifier.state.copyWith(activeTool: EditorToolType.eraser);
    notifier.applyActiveSmartTileSelection(
      const SmartTileGestureSelection.floodFill(
        seed: GridPos(x: 0, y: 0),
      ),
    );
    final edited = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(
      smartTileSemanticCells(edited),
      <int>[0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1],
    );
    expect(notifier.state.mapUndoStack, hasLength(3));

    notifier.undoMap();
    expect(
      smartTileSemanticCells(
        notifier.state.activeMap!.layers.single as SmartTileLayer,
      ),
      <int>[1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1],
    );
  });

  test('rectangle paints a whole map beyond the explicit payload limit', () {
    const mapSize = GridSize(width: 65, height: 64);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final layer = MapLayer.smartTile(
      id: 'smart',
      name: 'Smart',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: const <String>['', 'grass'],
      field: SmartTileField.cell(
        semanticCells: List<int>.filled(mapSize.width * mapSize.height, 0),
      ),
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: mapSize,
      layers: <MapLayer>[layer],
    );
    notifier.state = EditorState(
      project: _project,
      activeMap: map,
      savedMapSnapshot: map,
      activeLayerId: 'smart',
      activeTool: EditorToolType.terrainPaint,
    );

    notifier.applyActiveSmartTileSelection(
      const SmartTileGestureSelection.rectangle(
        start: GridPos(x: 0, y: 0),
        end: GridPos(x: 64, y: 63),
      ),
    );

    final edited = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(notifier.state.errorMessage, isNull);
    expect(smartTileSemanticCells(edited), hasLength(4160));
    expect(smartTileSemanticCells(edited).every((cell) => cell == 1), isTrue);
    expect(notifier.state.mapUndoStack, hasLength(1));
  });
}

final _project = ProjectManifest(
  name: 'Project',
  version: ProjectVersion.v6,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
    ],
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'terrain',
        name: 'Terrain',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        coveragePolicy: SmartTileCoveragePolicy.complete,
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

final _wangProject = _project.copyWith(
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: _project.smartTileCatalog.materials,
    presets: <ProjectSmartTilePreset>[
      _project.smartTileCatalog.presets.single.copyWith(
        topology: SmartTileTopology.wangEdge4,
        templateHint: SmartTileTemplateHint.edge16,
      ),
    ],
  ),
);
