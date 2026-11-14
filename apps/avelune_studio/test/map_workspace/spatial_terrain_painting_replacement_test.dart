import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import 'spatial_terrain_painting_fixture.dart';

void main() {
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
      final view = MapEditingViewportSession()
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
          body: SpatialMapEditingViewport(
            document: document,
            controller: controller,
            project: paintingProject,
            visuals: PaintingVisuals(),
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
