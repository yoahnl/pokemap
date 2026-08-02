import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_authoring_controller.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_grid_detector.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide_placement.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_publication_service.dart';

void main() {
  test('guided ERW preset paints and resolves through normal map history', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v3,
      size: GridSize(width: 5, height: 5),
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
      const GridPos(x: 2, y: 2),
      materialId: 'dirt',
    );
    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 1, y: 1),
      materialId: 'dirt',
    );
    notifier.endMapStroke();

    final firstShape =
        notifier.state.activeMap!.layers.single as SmartTileLayer;
    final preset = _manifest.smartTileCatalog.presets
        .singleWhere((candidate) => candidate.id == 'path');
    final firstResolution = _resolveLayerCell(
      layer: firstShape,
      preset: preset,
      x: 2,
      y: 2,
      width: 5,
      height: 5,
    );
    expect(firstResolution.status, SmartTileResolutionStatus.resolved);
    expect(notifier.state.mapUndoStack, hasLength(2));

    notifier.beginMapStroke();
    for (final position in const <GridPos>[
      GridPos(x: 3, y: 1),
      GridPos(x: 3, y: 3),
    ]) {
      notifier.paintSmartTileMaterialAt(position, materialId: 'dirt');
    }
    notifier.endMapStroke();

    final connected = notifier.state.activeMap!.layers.single as SmartTileLayer;
    final connectedResolution = _resolveLayerCell(
      layer: connected,
      preset: preset,
      x: 2,
      y: 2,
      width: 5,
      height: 5,
    );
    expect(connectedResolution.status, SmartTileResolutionStatus.resolved);
    expect(connectedResolution.ruleId, isNot(firstResolution.ruleId));
    expect(connected.toJson().containsKey('rules'), isFalse);

    notifier.undoMap();
    final undone = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(undone.materialCells.where((cell) => cell != 0), hasLength(2));

    notifier.redoMap();
    final redone = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(redone.materialCells.where((cell) => cell != 0), hasLength(4));

    notifier.beginMapStroke();
    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 2, y: 2),
      materialId: null,
    );
    notifier.endMapStroke();
    final erased = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(erased.materialCells[12], 0);
  });

  test('terrain paint layers start empty and painted cells can be erased', () {
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

    var layer = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(layer.materialCells, <int>[0]);

    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 0, y: 0),
      materialId: 'grass',
    );
    layer = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(layer.materialCells, <int>[1]);

    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 0, y: 0),
      materialId: null,
    );

    layer = notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(layer.materialCells, <int>[0]);
    expect(notifier.state.errorMessage, isNull);
  });
}

final _manifest = _guidedManifest();

ProjectManifest _guidedManifest() {
  const geometry = SmartTileGridGeometry(
    imageWidth: 320,
    imageHeight: 320,
    cellWidth: 32,
    cellHeight: 32,
  );
  final controller = SmartTileAuthoringController.blank()
    ..configureIdentity(
      id: 'path',
      name: 'Path',
      materialId: 'dirt',
      materialName: 'Dirt',
    )
    ..configureAtlas(
      atlasId: 'erw-atlas',
      atlasName: 'ERW Atlas',
      tilesetId: 'erw-tileset',
      geometry: geometry,
    )
    ..selectUsage(SmartTileUsage.path);
  final placement = placeSmartTileGuide(
    guide: erwCorner16Guide,
    geometry: geometry,
    anchorColumn: 4,
    anchorRow: 4,
  );
  controller.applyGuidePlacement(
    guide: erwCorner16Guide,
    placement: placement,
  );
  final base = ProjectManifest(
    name: 'Project',
    version: ProjectVersion.v4,
    maps: <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'erw-tileset',
        name: 'ERW Tileset',
        relativePath: 'assets/erw.png',
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'grass',
          terrainType: TerrainType.grass,
        ),
      ],
      presets: const <ProjectSmartTilePreset>[
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
  final staged = controller.applyToManifest(base);
  final published = const SmartTilePublicationService().publish(
    manifest: staged,
    presetId: 'path',
  );
  if (!published.published) {
    throw StateError('Guided fixture must publish: ${published.diagnostics}');
  }
  return published.manifest;
}

SmartTileResolution _resolveLayerCell({
  required SmartTileLayer layer,
  required ProjectSmartTilePreset preset,
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  String? materialAt(int sampleX, int sampleY) {
    final paletteIndex = layer.materialCells[sampleY * width + sampleX];
    return paletteIndex == 0 ? null : layer.materialPalette[paletteIndex];
  }

  return resolveSmartTile(
    preset: preset,
    materials: _manifest.smartTileCatalog.materials,
    neighborhood: SmartTileNeighborhood.fromGrid(
      width: width,
      height: height,
      x: x,
      y: y,
      materialAt: materialAt,
    ),
    x: x,
    y: y,
    mapId: 'map',
    layerId: layer.id,
  );
}
