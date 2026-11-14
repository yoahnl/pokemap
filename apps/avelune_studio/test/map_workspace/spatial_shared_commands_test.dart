import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:map_render_3d/map_render_3d.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';

import '../support/map_workspace_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

import 'spatial_shared_commands_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final key in [LogicalKeyboardKey.delete, LogicalKeyboardKey.backspace]) {
    testWidgets('${key.keyLabel} removes the selected 3D decor and undoes', (
      tester,
    ) async {
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
      final map = source.copyWith(
        spatialScene: source.spatialScene!.copyWith(
          instances: [model, ...source.spatialScene!.instances.skip(1)],
        ),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'delete-test'),
      );
      final view = MapEditingViewportSession()
        ..tool = StudioMapTool.select
        ..spatialFreeView = true;
      final controller =
          MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
            ..project = project
            ..active = document;
      controller.documents[map.id] = document;
      final visuals = SpatialTestVisuals();
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  const TextField(key: ValueKey('delete-inspector-input')),
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
      SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
      void select() => scene().onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.model,
          id: model.id,
          cell: (model.position.x.floor(), model.position.z.floor()),
        ),
      );
      select();
      await tester.pump();
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      await tester.tap(find.byType(TextField).first);
      await tester.sendKeyEvent(key);
      await tester.pump();
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      select();
      await tester.pump();
      document.saving = true;
      await tester.sendKeyEvent(key);
      await tester.pump();
      expect(document.current, same(map));
      document.saving = false;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(scene().contentPreview, isNotNull);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        document.current.spatialScene!.instances,
        map.spatialScene!.instances.where((item) => item.id != model.id),
      );
      expect(document.current.entities, map.entities);
      expect(document.undoCount, 1);
      expect(document.selectedId, isNull);
      expect(view.target, isNull);
      expect(scene().selectedContent, isNull);
      expect(scene().contentPreview, isNull);
      await tester.sendKeyEvent(key);
      expect(document.undoCount, 1);
      document.restore(redo: false);
      await tester.pump();
      expect(document.current, map);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Shift-drag moves a 3D decor and Shift-click toggles it', (
    tester,
  ) async {
    final project = ProjectManifest.fromJson(
      jsonDecode(
        File('test/fixtures/spatial_first_map/project.json').readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final map = MapData.fromJson(
      jsonDecode(
        File('test/fixtures/spatial_first_map/maps/first-map.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    ).copyWith(entities: []);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'shift-test'),
    );
    final view = MapEditingViewportSession()..tool = StudioMapTool.select;
    final controller =
        MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
          ..project = project
          ..active = document;
    controller.documents[map.id] = document;
    addTearDown(view.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SpatialMapEditingViewport(
              document: document,
              controller: controller,
              project: project,
              visuals: SpatialTestVisuals(),
              view: view,
              onChanged: () => setState(() {}),
            ),
          ),
        ),
      ),
    );
    SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
    final instance = map.spatialScene!.instances.firstWhere(
      (item) => item.blocksMovement,
    );
    final cell = (instance.position.x.floor(), instance.position.z.floor());
    final hit = SpatialSceneContentHit(
      kind: SpatialSceneContentKind.model,
      id: instance.id,
      cell: cell,
    );
    scene().onContent!(hit);
    await tester.pump();
    expect(document.selectedId, instance.id);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isTrue);
    scene().onDragUpdate!((cell.$1 + 1, cell.$2));
    scene().onDragEnd!();
    await tester.pump();
    expect(
      document.current.spatialScene!.instances
          .firstWhere((item) => item.id == instance.id)
          .position
          .x,
      instance.position.x + 1,
    );
    expect(document.undoCount, 1);
    expect(document.selectedId, instance.id);
    scene().onContent!(hit);
    await tester.pump();
    expect(document.selectedId, isNull);
    expect(document.undoCount, 1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'empty spatial preview requires neither a hero nor a gameplay session',
    () async {
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
      final resources = await StudioMapResources.load(
        ProjectSession(
          sessionId: 'preview',
          name: 'Preview',
          directoryPath: File('test/fixtures/spatial_first_map/project.json')
              .absolute
              .parent
              .path,
        ),
        project.copyWith(
          settings: project.settings.copyWith(defaultPlayerCharacterId: null),
          characters: [],
        ),
      );
      addTearDown(resources.dispose);
      final preview = await resources.spatialPreview(
        map.copyWith(entities: []),
      );
      expect(preview.frames, isEmpty);
      preview.dispose();
    },
  );
}
