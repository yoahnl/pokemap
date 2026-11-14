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
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

import 'spatial_shared_commands_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('free camera moves selected content and returns to game view', (
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
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'camera-test'),
    );
    final view = MapEditingViewportSession()
      ..tool = StudioMapTool.place
      ..model3d = project.models3d.first;
    final controller =
        MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
          ..project = project
          ..active = document;
    controller.documents[map.id] = document;
    final visuals = SpatialTestVisuals();
    addTearDown(view.dispose);
    addTearDown(controller.dispose);
    late VoidCallback refresh;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              void changed() => setState(() {});
              refresh = changed;
              return Column(
                children: [
                  Expanded(
                    child: SpatialMapEditingViewport(
                      document: document,
                      controller: controller,
                      project: project,
                      visuals: visuals,
                      view: view,
                      onChanged: changed,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
    expect(scene().controller.view, SpatialEditorView.game);
    view.spatialFreeView = !view.spatialFreeView;
    refresh();
    await tester.pump();
    expect(scene().controller.view, SpatialEditorView.orbit);
    expect(scene().onDragStart, isNotNull);
    expect(scene().onContent, isNotNull);
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
    final instance = map.spatialScene!.instances.firstWhere(
      (item) => item.blocksMovement,
    );
    final cell = (instance.position.x.floor(), instance.position.z.floor());
    final hit = SpatialSceneContentHit(
      kind: SpatialSceneContentKind.model,
      id: instance.id,
      cell: cell,
    );
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isFalse);
    view.tool = StudioMapTool.select;
    scene().onCell(0, 0);
    await tester.pump();
    expect(scene().selectContent, isTrue);
    expect(scene().onDragStart!(0, 0, null), isFalse);
    scene().onContent!(hit);
    await tester.pump();
    expect(document.selectedId, instance.id);
    expect(scene().selectedContent?.id, instance.id);
    expect(scene().selectionColor, isNotNull);
    expect(document.canUndo, isFalse);
    final yaw = scene().controller.yaw;
    final pitch = scene().controller.pitch;
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isTrue);
    scene().onDragUpdate!((cell.$1 + 1, cell.$2));
    await tester.pump();
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
    expect(scene().contentPreview?.id, instance.id);
    expect(scene().contentPreview?.position.x, instance.position.x + 1);
    expect(scene().contentPreview?.position.z, instance.position.z);
    expect(scene().scene, same(map.spatialScene));
    scene().onDragEnd!();
    await tester.pump();
    expect(scene().contentPreview, isNull);
    final moved = document.current.spatialScene!.instances.firstWhere(
      (item) => item.id == instance.id,
    );
    expect(moved.position.x, instance.position.x + 1);
    expect(moved.position.z, instance.position.z);
    expect(document.undoCount, 1);
    expect(document.current.spatialScene!.camera, map.spatialScene!.camera);
    expect(scene().controller.yaw, yaw);
    expect(scene().controller.pitch, pitch);
    document.restore(redo: false);
    expect(document.current, map);
    document.restore(redo: true);
    expect(
      document.current.spatialScene!.instances.firstWhere(
        (item) => item.id == instance.id,
      ),
      moved,
    );
    document.restore(redo: false);
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isTrue);
    scene().onDragUpdate!((cell.$1 + 2, cell.$2));
    view.spatialFreeView = false;
    scene().onDragEnd!();
    await tester.pump();
    expect(document.current, map);
    expect(document.canUndo, isFalse);
    expect(scene().contentPreview, isNull);
    view.spatialFreeView = true;
    scene().onCell(0, 0);
    await tester.pump();
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isTrue);
    scene().onDragUpdate!((cell.$1 + 2, cell.$2));
    document.saving = true;
    scene().onDragEnd!();
    document.saving = false;
    await tester.pump();
    expect(document.current, map);
    expect(document.canUndo, isFalse);
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isTrue);
    scene().onDragUpdate!((cell.$1 + 1, cell.$2));
    await tester.pump();
    expect(scene().contentPreview, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(scene().contentPreview, isNull);
    expect(scene().selectedContent, isNull);
    expect(scene().controller.view, SpatialEditorView.orbit);
    scene().onDragEnd!();
    expect(document.current, map);
    expect(document.canUndo, isFalse);
    scene().controller.orbit(150, 50);
    expect(scene().controller.yaw, isNot(.5));
    view.viewport.zoomBy(1.25);
    await tester.pump();
    expect(view.scale, 1.25);
    view.spatialFreeView = !view.spatialFreeView;
    refresh();
    await tester.pump();
    expect(scene().controller.view, SpatialEditorView.game);
    expect(scene().onDragStart, isNotNull);
    view.spatialFreeView = !view.spatialFreeView;
    refresh();
    await tester.pump();
    view.recenter!();
    await tester.pump();
    expect(scene().controller.view, SpatialEditorView.game);
    expect(view.scale, 1);
    expect(document.current, map);
    expect(tester.takeException(), isNull);
  });
}
