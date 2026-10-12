import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  const preset = ProjectSmartTilePreset(
    id: 'grass',
    name: 'Herbe',
    usage: SmartTileUsage.terrain,
    topology: SmartTileTopology.uniform,
    templateHint: SmartTileTemplateHint.simple,
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    coverageProfile: SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: SmartTileTransformPolicy(),
    defaultMaterialId: 'grass',
    allowedMaterialIds: ['grass'],
  );
  final project = ProjectManifest(
    version: ProjectVersion.v9,
    name: 'Carte 3D',
    settings: ProjectSettings(
      dimension: ProjectDimension.threeD,
      spatialCamera: SpatialCameraProfile(),
    ),
    tilesets: const [],
    maps: const [
      ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'map.json'),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: [
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Herbe',
          connectionGroupId: 'grass',
        ),
      ],
      presets: [preset],
    ),
  );

  testWidgets('the same terrain toolbar is enabled for spatial maps', (
    tester,
  ) async {
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapWorkspaceToolStrip(
            view: view,
            onChanged: () {},
            onMoreTools: () {},
            onResources: () {},
            storyAvailable: false,
            paletteVisible: true,
            spatial: true,
            onUndo: () {},
            onRedo: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Terrains').first);
    expect(view.paletteTab, 'Terrains');
  });

  testWidgets(
    'ground drag interpolates cells and commits one undoable stroke',
    (tester) async {
      final map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v9,
        size: const GridSize(width: 6, height: 5),
        spatialScene: MapSpatialScene(width: 6, depth: 5),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'test'),
      );
      final view = MapWorkspaceViewState()
        ..terrain = preset
        ..tool = StudioMapTool.terrain;
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      final sand = preset.copyWith(
        id: 'sand',
        name: 'Sable',
        defaultMaterialId: 'sand',
        allowedMaterialIds: ['sand'],
      );
      final paintingProject = project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: [
            ...project.smartTileCatalog.materials,
            const ProjectSmartTileMaterial(
              id: 'sand',
              name: 'Sable',
              connectionGroupId: 'sand',
            ),
          ],
          presets: [preset, sand],
        ),
      );
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      Widget canvas() => MaterialApp(
        home: Scaffold(
          body: SpatialMapEditor(
            document: document,
            controller: controller,
            project: paintingProject,
            visuals: _SpatialVisuals(),
            view: view,
            onChanged: () {},
          ),
        ),
      );
      await tester.pumpWidget(canvas());
      var scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(scene.onDragStart!(1, 2, null), isTrue, reason: document.error);
      scene.onDragUpdate!((4, 2));
      expect(document.current.layers, isEmpty);
      view.spatialFreeView = true;
      await tester.pumpWidget(canvas());
      scene.onDragEnd!();
      expect(document.current, same(map));
      expect(document.canUndo, isFalse);
      view.spatialFreeView = false;
      await tester.pumpWidget(canvas());
      scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      expect(scene.onDragStart!(1, 2, null), isTrue);
      scene.onDragUpdate!((4, 2));
      scene.onDragEnd!();
      expect(document.undoCount, 1);
      final layer = document.current.layers.whereType<SmartTileLayer>().single;
      for (var x = 1; x <= 4; x++) {
        expect(
          smartTileMaterialIdAt(layer, mapSize: map.size, x: x, y: 2),
          'grass',
        );
      }
      expect(document.current.spatialScene, map.spatialScene);
      expect(MapData.fromJson(document.current.toJson()), document.current);
      document.restore(redo: false);
      expect(document.current, map);
      document.restore(redo: true);
      expect(document.current.layers.whereType<SmartTileLayer>(), hasLength(1));
      view.tool = StudioMapTool.erase;
      await tester.pumpWidget(canvas());
      scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      scene.onCell(2, 2);
      final erased = document.current.layers.whereType<SmartTileLayer>().single;
      expect(
        smartTileMaterialIdAt(erased, mapSize: map.size, x: 2, y: 2),
        isNull,
      );
      expect(
        smartTileMaterialIdAt(erased, mapSize: map.size, x: 1, y: 2),
        'grass',
      );
      document.restore(redo: false);
      expect(document.current.layers.single, layer);
      expect(scene.onDragStart!(-1, 2, null), isFalse);
      expect(document.undoCount, 1);
      view.tool = StudioMapTool.terrain;
      await tester.pumpWidget(canvas());
      scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      expect(scene.onDragStart!(0, 0, null), isTrue);
      document.commit(document.current.copyWith(name: 'Carte renommée'));
      final renamed = document.current;
      scene.onDragEnd!();
      expect(document.current, renamed);
      expect(scene.onDragStart!(0, 0, null), isTrue);
      scene.onDragUpdate!((2, 0));
      scene.onDragCancel!();
      await tester.pumpWidget(canvas());
      scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      expect(scene.groundMap, renamed);
      expect(document.current, renamed);
      view.terrain = sand;
      await tester.pumpWidget(canvas());
      scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      expect(scene.onDragStart!(1, 2, null), isTrue);
      scene.onDragUpdate!((4, 2));
      scene.onDragEnd!();
      final sandMap = document.current;
      view.terrain = preset;
      await tester.pumpWidget(canvas());
      scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      final beforeRepaintUndo = document.undoCount;
      expect(scene.onDragStart!(1, 2, null), isTrue);
      scene.onDragUpdate!((4, 2));
      expect(document.current, sandMap);
      scene.onDragEnd!();
      expect(document.undoCount, beforeRepaintUndo + 1);
      final repaintedSand = document.current.layers
          .whereType<SmartTileLayer>()
          .firstWhere((layer) => layer.presetId == sand.id);
      for (var x = 1; x <= 4; x++) {
        expect(
          smartTileMaterialIdAt(repaintedSand, mapSize: map.size, x: x, y: 2),
          isNull,
        );
      }
      document.restore(redo: false);
      expect(document.current, sandMap);
    },
  );

  testWidgets(
    'painting a raised map keeps its native relief and commits the ground',
    (tester) async {
      final map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v9,
        size: const GridSize(width: 2, height: 2),
        spatialScene: MapSpatialScene(
          width: 2,
          depth: 2,
          heightLevels: [0, 0, 1, 1],
        ),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'test'),
      );
      final view = MapWorkspaceViewState()
        ..terrain = preset
        ..tool = StudioMapTool.terrain;
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpatialMapEditor(
              document: document,
              controller: controller,
              project: project,
              visuals: _SpatialVisuals(),
              view: view,
              onChanged: () {},
            ),
          ),
        ),
      );
      final scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(scene.onDragStart!(0, 1, null), isTrue);
      scene.onDragEnd!();
      expect(document.current.spatialScene, map.spatialScene);
      expect(document.current.layers.whereType<SmartTileLayer>(), hasLength(1));
      expect(document.canUndo, isTrue);
      expect(document.error, isNull);
    },
  );

  testWidgets(
    'painting below a replacement preserves its cells until explicitly erased',
    (tester) async {
      final floorPreset = preset.copyWith(
        allowedMaterialIds: ['grass', 'sand'],
      );
      final replacement = preset.copyWith(
        id: 'replacement',
        defaultMaterialId: 'replacement',
        allowedMaterialIds: ['replacement'],
        rules: [
          SmartTileRule(
            id: 'replacement',
            centerMatch: const SmartTileSlotMatch.material('replacement'),
            candidates: [
              SmartTileCandidate(
                id: 'unit',
                parts: [
                  SmartTileVisualPart(
                    source: const SmartTileVisualSource.model3d(
                      modelId: 'unit',
                      replacesGround: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final paintingProject = project.copyWith(
        models3d: [
          ProjectModel3dEntry(
            id: 'unit',
            name: 'Pièce unitaire',
            sourceAssetId: 'unit-source',
            relativePath: 'assets/models3d/unit.glb',
            inspection: Model3dInspection(
              bounds: Model3dBounds(
                min: Model3dVector3(x: -.5, y: 0, z: -.5),
                max: Model3dVector3(x: .5, y: 1, z: .5),
              ),
              meshCount: 1,
              triangleCount: 2,
            ),
          ),
        ],
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: [
            ...project.smartTileCatalog.materials,
            const ProjectSmartTileMaterial(
              id: 'sand',
              name: 'Sable',
              connectionGroupId: 'sand',
            ),
            const ProjectSmartTileMaterial(
              id: 'replacement',
              name: 'Pièce',
              connectionGroupId: 'replacement',
            ),
          ],
          presets: [floorPreset, replacement],
        ),
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v9,
        size: const GridSize(width: 2, height: 2),
        spatialScene: MapSpatialScene(
          width: 2,
          depth: 2,
          heightLevels: [8, 8, 8, 8],
        ),
        layers: [
          SmartTileLayer(
            id: 'replacement',
            name: 'Pièces',
            presetId: replacement.id,
            usage: SmartTileUsage.terrain,
            materialPalette: ['', 'replacement'],
            field: const SmartTileField.cell(semanticCells: [1, 0, 1, 0]),
          ),
          SmartTileLayer(
            id: 'floor',
            name: 'Sol',
            presetId: floorPreset.id,
            usage: SmartTileUsage.terrain,
            materialPalette: ['', 'grass'],
            field: const SmartTileField.cell(semanticCells: [1, 1, 1, 1]),
          ),
        ],
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'test'),
      );
      final view = MapWorkspaceViewState()
        ..terrain = floorPreset
        ..terrainMaterialId = 'sand'
        ..tool = StudioMapTool.terrain;
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      Widget canvas() => MaterialApp(
        home: Scaffold(
          body: SpatialMapEditor(
            document: document,
            controller: controller,
            project: paintingProject,
            visuals: _SpatialVisuals(),
            view: view,
            onChanged: () {},
          ),
        ),
      );
      Set<(int, int)> owned() =>
          resolveSpatialSmartTileModelProjection(
            map: document.current,
            catalog: paintingProject.smartTileCatalog,
          ).groundReplacements['replacement'] ??
          {};
      await tester.pumpWidget(canvas());
      var scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(scene.onDragStart!(0, 1, null), isTrue);
      scene.onDragUpdate!((1, 1));
      scene.onDragEnd!();
      expect(document.error, isNull);
      expect(owned(), {(0, 0), (0, 1)});
      expect(document.current.layers.first, map.layers.first);
      expect(document.current.spatialScene, map.spatialScene);
      final painted = document.current;
      final floor = painted.layers[1] as SmartTileLayer;
      expect(
        smartTileMaterialIdAt(floor, mapSize: map.size, x: 0, y: 1),
        'sand',
      );
      view
        ..terrain = replacement
        ..terrainMaterialId = 'replacement'
        ..tool = StudioMapTool.erase;
      await tester.pumpWidget(canvas());
      scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      scene.onCell(0, 1);
      expect(document.error, isNull);
      expect(owned(), {(0, 0)});
      expect(document.current.layers[1], floor);
      expect(MapData.fromJson(document.current.toJson()), document.current);
      document.restore(redo: false);
      expect(document.current, painted);
      expect(owned(), {(0, 0), (0, 1)});
      document.restore(redo: true);
      expect(owned(), {(0, 0)});
      expect(document.current.layers[1], floor);
    },
  );
}

class _SpatialVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
