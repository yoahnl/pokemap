import 'dart:typed_data';


import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../application/spatial_terrain_draft_test.dart' show spatialPathDraft;
import '../support/map_workspace_fixture.dart';
import '../terrain_creation_test.dart'
    show terrainDraft, assignAll, publishFixture;

void main() {
  for (final previousMode in [
    SpatialTerrainMode.relief,
    SpatialTerrainMode.ramp,
  ]) {
    testWidgets(
      'choosing a model path after ${previousMode.name} paints cells without changing height',
      (tester) async {
        final draft = spatialPathDraft();
        final preset = draft.previewPreset;
        final project = draft.manifest.copyWith(
          elements: const [],
          tilesets: const [],
          settings: draft.manifest.settings.copyWith(
            spatialCamera: SpatialCameraProfile(),
          ),
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: draft.draft.materials,
            presets: [preset],
          ),
        );
        final map = MapData(
          id: 'a',
          name: 'Pilote',
          version: ProjectVersion.v9,
          size: const GridSize(width: 8, height: 8),
          spatialScene: MapSpatialScene(width: 8, depth: 8),
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
        );
        final controller =
            MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
              ..project = project
              ..active = document;
        final view = MapEditingViewportSession()
          ..spatialTerrainMode = previousMode
          ..spatialTerrainLevel = 4;
        addTearDown(controller.dispose);
        addTearDown(view.dispose);
        expect(
          await useMapResource(
            workspace: controller,
            item: ResourceItem(
              id: preset.id,
              name: preset.name,
              kind: ResourceKind.terrains,
              terrain: preset,
            ),
            view: () => view,
            isActive: () => true,
            chooseMap: (_) async => null,
            chooseTile: (_) async => null,
          ),
          isTrue,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SpatialMapEditingViewport(
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
        expect(view.spatialTerrainMode, SpatialTerrainMode.ground);
        expect(view.spatialTerrainLevel, 4);
        final scene = tester.widget<SpatialSceneView>(
          find.byType(SpatialSceneView),
        );
        expect(scene.onDragStart!(2, 3, null), isTrue, reason: document.error);
        scene.onDragEnd!();
        expect(
          document.current.spatialScene!.heightLevels,
          map.spatialScene!.heightLevels,
        );
        expect(
          document.current.layers.whereType<SmartTileLayer>(),
          hasLength(1),
        );
        expect(
          resolveSpatialSmartTileInstances(
            map: document.current,
            catalog: project.smartTileCatalog,
          ),
          hasLength(1),
        );
        expect(document.current.spatialScene!.instances, isEmpty);
        document.restore(redo: false);
        expect(document.current, map);
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final spatial in [false, true]) {
    test(
      'allowed material paints and resets with another preset in ${spatial ? '3D' : '2D'}',
      () {
        final draft = terrainDraft();
        assignAll(draft);
        final spatialDraft = spatialPathDraft();
        final base = spatial ? spatialDraft.manifest : publishFixture(draft);
        final original = spatial
            ? spatialDraft.previewPreset
            : base.smartTileCatalog.presets.single;
        final preset = original.copyWith(
          allowedMaterialIds: [original.defaultMaterialId, 'paving'],
          rules: [
            ...original.rules,
            for (final rule in original.rules)
              rule.copyWith(
                id: '${rule.id}-paving',
                centerMatch: const SmartTileSlotMatch.material('paving'),
              ),
          ],
        );
        final next = original.copyWith(id: 'another', name: 'Autre chemin');
        final project = base.copyWith(
          elements: spatial ? const [] : base.elements,
          tilesets: spatial ? const [] : base.tilesets,
          settings: spatial
              ? base.settings.copyWith(spatialCamera: SpatialCameraProfile())
              : base.settings,
          smartTileCatalog: ProjectSmartTileCatalog(
            atlases: base.smartTileCatalog.atlases,
            presets: [preset, next],
            materials: [
              ...(spatial
                  ? spatialDraft.draft.materials
                  : base.smartTileCatalog.materials),
              const ProjectSmartTileMaterial(
                id: 'paving',
                name: 'Pavés de pierre',
                connectionGroupId: 'paving',
              ),
            ],
          ),
        );
        final map = MapData(
          id: 'a',
          name: 'Pilote',
          version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
          size: const GridSize(width: 8, height: 8),
          spatialScene: spatial ? MapSpatialScene(width: 8, depth: 8) : null,
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
        );
        final view = MapEditingViewportSession()
          ..prepareTerrainPainting(preset);
        addTearDown(view.dispose);
        view.terrainMaterialId = 'paving';
        expect(view.terrainMaterialId, 'paving');
        final stroke = MapCanvasStroke.start(
          map: document.current,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 2, y: 3),
        )!;
        document.commit(stroke.commit());
        expect(
          smartTileMaterialIdAt(
            document.current.layers.whereType<SmartTileLayer>().single,
            mapSize: map.size,
            x: 2,
            y: 3,
          ),
          'paving',
        );
        document.restore(redo: false);
        expect(document.current, map);
        view.prepareTerrainPainting(preset);
        expect(view.terrainMaterialId, 'paving');
        view.prepareTerrainPainting(next);
        expect(view.terrainMaterialId, next.defaultMaterialId);
        expect(view.spatialTerrainMode, SpatialTerrainMode.ground);
      },
    );
  }

  test(
    'model paths preserve dimensions and expose paint in the shared catalogue',
    () {
      final model = spatialPathDraft();
      final item = ResourceItem(
        id: 'grass',
        name: 'Herbes',
        kind: ResourceKind.terrains,
        terrain: model.previewPreset,
      );
      expect(item.compatibleWith(ProjectDimension.twoD), isFalse);
      expect(item.compatibleWith(ProjectDimension.threeD), isTrue);
      expect(
        resourceCatalog(model.manifest)
            .firstWhere((item) => item.model3d != null)
            .usages,
        contains(ResourceCatalogUsage.paint),
      );
    },
  );

}

class _SpatialVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
