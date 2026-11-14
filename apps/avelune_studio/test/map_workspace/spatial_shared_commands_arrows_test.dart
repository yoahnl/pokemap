import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:map_render_3d/map_render_3d.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';

import '../support/map_workspace_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';

import 'spatial_shared_commands_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'arrows preview selected models and NPCs with one held-key undo',
    (tester) async {
      final project = ProjectManifest.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/project.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final source = MapData.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/maps/first-map.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final model = source.spatialScene!.instances.first.copyWith(
        position: Model3dVector3(x: 3.5, y: 0, z: 3.5),
      );
      final npc = source.entities.first.copyWith(
        pos: const GridPos(x: 3, y: 3),
      );
      final map = source.copyWith(
        spatialScene: source.spatialScene!.copyWith(instances: [model]),
        entities: [npc],
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: map,
          mapId: map.id,
          revision: 'keyboard-test',
        ),
      );
      final view = MapEditingViewportSession()..tool = StudioMapTool.select;
      final controller =
          MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
            ..project = project
            ..active = document;
      final visuals = SpatialTestVisuals();
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  const TextField(key: ValueKey('inspector-input')),
                  Expanded(
                    child: SpatialMapEditingViewport(
                      document: document,
                      controller: controller,
                      project: project,
                      visuals: visuals,
                      view: view,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
      scene().onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.model,
          id: model.id,
          cell: (3, 3),
        ),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(document.current, same(map));
      expect(scene().contentPreview?.position.x, 6.5);
      expect(document.undoCount, 0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(document.current.spatialScene!.instances.single.position.x, 6.5);
      expect(document.undoCount, 1);
      expect(scene().contentPreview, isNull);
      document.restore(redo: false);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(scene().contentPreview?.position.x, 2.5);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(document.current, map);
      expect(scene().contentPreview, isNull);
      expect(document.undoCount, 0);
      expect(scene().selectedContent, isNull);
      expect(document.selectedId, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(document.current, map);
      await tester.tap(find.byKey(const ValueKey('inspector-input')));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(document.current, map);
      expect(scene().contentPreview, isNull);
      scene().onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.actor,
          id: 'npc:${npc.id}',
          cell: (3, 3),
        ),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(scene().contentPreview?.id, 'npc:${npc.id}');
      expect(scene().contentPreview?.position.z, 2.5);
      expect(document.current.entities.single.pos, npc.pos);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(document.current.entities.single.pos, const GridPos(x: 3, y: 2));
      expect(document.undoCount, 1);
      expect(scene().contentPreview, isNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      for (var repeat = 0; repeat < 8; repeat++) {
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);
      }
      await tester.pump();
      expect(scene().contentPreview?.position.x, .5);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(scene().contentPreview?.position.x, 1.5);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(document.current.entities.single.pos, const GridPos(x: 1, y: 2));
      expect(document.undoCount, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(scene().selectedContent, isNull);
      expect(view.target, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'spatial models use decor catalog and canonical grounded editing history',
    () {
      final root = 'test/fixtures/spatial_first_map';
      final project = ProjectManifest.fromJson(
        jsonDecode(File('$root/project.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final map = MapData.fromJson(
        jsonDecode(File('$root/maps/first-map.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'test'),
      );
      final item = resourceCatalog(project)
          .where((item) => item.kind == ResourceKind.decors)
          .first;
      expect(item.model3d, isNotNull);
      expect(item.element, isNull);
      final commands = SpatialModelEditingCommands(document, project);
      final before = document.current;
      final instance = commands.place(item.model3d!, const GridPos(x: 3, y: 3));
      expect(document.selectedId, instance.id);
      expect(instance.position.y, map.spatialScene!.worldHeightAt(3.5, 3.5));
      commands.update(instance.id, x: 4.5, z: 4.5, rotation: 90, scale: 1.2);
      expect(
        commands.selected()!.position.y,
        map.spatialScene!.worldHeightAt(4.5, 4.5),
      );
      commands.duplicate(instance.id);
      expect(
        document.current.spatialScene!.instances.length,
        before.spatialScene!.instances.length + 2,
      );
      final duplicated = document.selectedId!;
      final target = locateMapContextTarget(
        document,
        project,
        MapContextFamily.decor,
        duplicated,
      )!;
      final context = MapContextActionContext(
        document: document,
        project: project,
        position: target.at,
      );
      expect(
        MapContextCommandRunner(context)
            .run(MapContextCommand.delete, target.target),
        isNull,
      );
      document.restore(redo: false);
      expect(
        document.current.spatialScene!.instances.length,
        before.spatialScene!.instances.length + 2,
      );
      expect(() => commands.update(instance.id, x: -1), throwsStateError);
      expect(
        document.current.spatialScene!.instances
            .firstWhere((v) => v.id == instance.id)
            .position
            .x,
        4.5,
      );
    },
  );
}
