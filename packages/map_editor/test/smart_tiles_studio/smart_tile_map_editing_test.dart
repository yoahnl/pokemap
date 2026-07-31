import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  test('Smart Tile layer creation and painting use normal map history', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v3,
      size: GridSize(width: 2, height: 2),
    );
    notifier.state = EditorState(
      project: _manifest,
      activeMap: map,
      savedMapSnapshot: map,
    );

    notifier.addSmartTileLayer(
      presetId: 'path',
      usage: SmartTileUsage.path,
      defaultMaterialId: 'dirt',
      name: 'Chemin',
    );

    expect(notifier.state.activeMap!.version, ProjectVersion.v4);
    expect(notifier.state.activeLayerId, isNotNull);
    expect(notifier.state.mapUndoStack, hasLength(1));
    expect(notifier.state.activeMap!.layers.single, isA<SmartTileLayer>());

    notifier.selectTool(EditorToolType.terrainPaint);
    notifier.beginMapStroke();
    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 1, y: 0),
      materialId: 'dirt',
    );
    notifier.endMapStroke();

    final painted = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(painted.materialCells, <int>[0, 1, 0, 0]);
    expect(notifier.state.mapUndoStack, hasLength(2));

    notifier.undoMap();
    final restored = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(restored.materialCells, everyElement(0));
  });

  test('painting can erase sparse layers but not the base terrain provider',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v4,
      size: GridSize(width: 1, height: 1),
    );
    notifier.state = EditorState(
      project: _manifest,
      activeMap: map,
      savedMapSnapshot: map,
    );
    notifier.addSmartTileLayer(
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      defaultMaterialId: 'grass',
      name: 'Terrain',
    );

    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 0, y: 0),
      materialId: null,
    );

    final layer = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(layer.materialCells, <int>[1]);
    expect(notifier.state.errorMessage, contains('terrain'));
  });
}

final _manifest = ProjectManifest(
  name: 'Project',
  version: ProjectVersion.v4,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'dirt',
        name: 'Dirt',
        connectionGroupId: 'dirt',
      ),
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'grass',
        terrainType: TerrainType.grass,
      ),
    ],
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'path',
        name: 'Path',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.cardinal4,
        defaultMaterialId: 'dirt',
        allowedMaterialIds: <String>['dirt'],
      ),
      ProjectSmartTilePreset(
        id: 'terrain',
        name: 'Terrain',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.cardinal4,
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
      ),
    ],
  ),
);
