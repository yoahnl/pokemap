import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';

import '../support/map_workspace_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';

import 'spatial_shared_commands_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'canonical resource choice arms ground placement and selection uses content',
    (tester) async {
      final project = ProjectManifest.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/project.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final map = MapData.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/maps/first-map.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: map.copyWith(entities: []),
          mapId: map.id,
          revision: 'test',
        ),
      );
      final view = MapEditingViewportSession();
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      controller.project = project;
      controller.active = document;
      controller.documents[document.current.id] = document;
      final model = project.models3d.first;
      expect(
        await useMapResource(
          workspace: controller,
          item: resourceCatalog(project)
              .singleWhere((item) => item.model3d?.id == model.id),
          view: () => view,
          isActive: () => true,
          chooseMap: (_) async => null,
          chooseTile: (_) async => null,
        ),
        isTrue,
      );
      expect(view.model3d, model);
      expect(view.tool, StudioMapTool.place);
      final visuals = SpatialTestVisuals();
      Widget canvas() => MaterialApp(
        home: Scaffold(
          body: SpatialMapEditingViewport(
            document: document,
            controller: controller,
            project: project,
            visuals: visuals,
            view: view,
            onChanged: () {},
          ),
        ),
      );
      await tester.pumpWidget(canvas());
      final placement = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(placement.selectContent, isFalse);
      placement.onZoom!(-100);
      expect(view.scale, greaterThan(1));
      expect(placement.controller.zoom, closeTo(1 / view.scale, .00001));
      placement.onCell(3, 11);
      final added = document.current.spatialScene!.instances.last;
      expect(added.position.x, 3.5);
      expect(added.position.z, 11.5);
      view.tool = StudioMapTool.character;
      await tester.pumpWidget(canvas());
      expect(
        tester
            .widget<SpatialSceneView>(find.byType(SpatialSceneView))
            .selectContent,
        isFalse,
      );
      view.tool = StudioMapTool.select;
      await tester.pumpWidget(canvas());
      final selection = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(selection.selectContent, isTrue);
      expect(
        selection.onDragStart!(
          3,
          11,
          SpatialSceneContentHit(
            kind: SpatialSceneContentKind.model,
            id: added.id,
            cell: (3, 11),
          ),
        ),
        isTrue,
      );
      selection.onDragUpdate!((4, 11));
      selection.onDragEnd!();
      expect(document.current.spatialScene!.instances.last.position.x, 4.5);
      expect(document.current.spatialScene!.instances.last.position.z, 11.5);
      view.armMove(
        MapSelectionTarget(
          mapId: map.id,
          family: MapSelectionFamily.decor,
          id: added.id,
        ),
        'Déplacer',
      );
      expect(selection.onDragStart!(8, 11, null), isTrue);
      selection.onDragUpdate!((9, 11));
      selection.onDragEnd!();
      expect(document.current.spatialScene!.instances.last.position.x, 5.5);

      final commands = SpatialModelEditingCommands(document, project);
      commands.duplicate(added.id);
      final otherId = document.selectedId!;
      final firstHit = SpatialSceneContentHit(
        kind: SpatialSceneContentKind.model,
        id: added.id,
        cell: (5, 11),
      );
      selection.onContent!(firstHit);
      expect(document.selectedId, added.id);
      expect(selection.onDragStart!(5, 11, firstHit), isTrue);
      selection.onDragUpdate!((6, 11));
      selection.onDragEnd!();
      expect(commands.selected(added.id)!.position.x, 6.5);
      expect(commands.selected(otherId)!.position.x, 5.5);
      commands.update(added.id, x: 5.5);
      final npc = map.entities.first.copyWith(pos: const GridPos(x: 5, y: 11));
      document.commit(document.current.copyWith(entities: [npc]));
      selection.onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.actor,
          id: 'npc:${npc.id}',
          cell: (5, 11),
        ),
      );
      expect(view.selectedFor(map.id, MapSelectionFamily.character), npc.id);
      expect(document.selectedId, isNull);
      final secondNpc = npc.copyWith(
        id: 'second-npc',
        pos: const GridPos(x: 6, y: 11),
      );
      document.commit(document.current.copyWith(entities: [npc, secondNpc]));
      view.armMove(
        MapSelectionTarget(
          mapId: map.id,
          family: MapSelectionFamily.character,
          id: npc.id,
        ),
        'Déplacer',
      );
      expect(
        selection.onDragStart!(
          6,
          11,
          SpatialSceneContentHit(
            kind: SpatialSceneContentKind.actor,
            id: 'npc:${secondNpc.id}',
            cell: (6, 11),
          ),
        ),
        isTrue,
      );
      selection.onDragUpdate!((7, 11));
      selection.onDragEnd!();
      expect(
        document.current.entities
            .firstWhere((entity) => entity.id == npc.id)
            .pos,
        const GridPos(x: 6, y: 11),
      );
      expect(
        document.current.entities
            .firstWhere((entity) => entity.id == secondNpc.id)
            .pos,
        const GridPos(x: 6, y: 11),
      );

      view.tool = StudioMapTool.eraseDecor;
      selection.onContent!(firstHit);
      expect(commands.selected(added.id), isNull);
      expect(commands.selected(otherId), isNotNull);
      view.tool = StudioMapTool.select;
      selection.onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.model,
          id: otherId,
          cell: (5, 11),
        ),
      );
      view.transform.value = Matrix4.identity()..scaleByDouble(8, 8, 1, 1);
      expect(selection.controller.zoom, closeTo(.125, .00001));
      selection.onZoom!(-1000000);
      expect(view.scale, 8);
      expect(selection.controller.zoom, closeTo(.125, .00001));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
