import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_shortcuts.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import 'spatial_shared_commands_support.dart';

class _Harness {
  _Harness(this.document, this.view, this.controller);
  final EditableMapDocument document;
  final MapEditingViewportSession view;
  final MapWorkspaceController controller;
}

Future<_Harness> _pump(WidgetTester tester) async {
  const root = 'test/fixtures/spatial_first_map';
  final project = ProjectManifest.fromJson(
    jsonDecode(File('$root/project.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final source = MapData.fromJson(
    jsonDecode(File('$root/maps/first-map.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final map = source.copyWith(
    spatialScene: source.spatialScene!.copyWith(
      instances: [
        SpatialModelInstance(
          id: 'oak_a',
          modelId: 'house',
          position: Model3dVector3(x: 3.5, y: 0, z: 3.5),
        ),
        SpatialModelInstance(
          id: 'oak_b',
          modelId: 'house',
          position: Model3dVector3(x: 6.5, y: 0, z: 3.5),
        ),
      ],
    ),
    entities: [source.entities.first.copyWith(pos: const GridPos(x: 9, y: 3))],
  );
  final document = EditableMapDocument(
    MapWorkspaceDocument(map: map, mapId: map.id, revision: 'multi'),
  );
  final view = MapEditingViewportSession()..tool = StudioMapTool.select;
  final controller =
      MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
        ..project = project
        ..active = document;
  addTearDown(view.dispose);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => CallbackShortcuts(
            bindings: mapEditingShortcuts(controller, view, (action) {
              action();
              setState(() {});
            }),
            child: SpatialMapEditingViewport(
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
    ),
  );
  await tester.pump();
  return _Harness(document, view, controller);
}

SpatialSceneView _scene(WidgetTester tester) =>
    tester.widget(find.byType(SpatialSceneView));

SpatialSceneContentHit _model(String id, int x) => SpatialSceneContentHit(
  kind: SpatialSceneContentKind.model,
  id: id,
  cell: (x, 3),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'shift-click builds a mixed selection outlined element by element',
    (tester) async {
      final h = await _pump(tester);
      final npc = h.document.current.entities.single;
      _scene(tester).onContent!(_model('oak_a', 3));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      _scene(tester).onContent!(_model('oak_b', 6));
      _scene(tester).onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.actor,
          id: 'npc:${npc.id}',
          cell: (9, 3),
        ),
      );
      await tester.pump();
      expect(
        h.view.selectionIn(h.document.current.id).map((target) => target.id),
        ['oak_a', 'oak_b', npc.id],
      );
      expect(_scene(tester).selectedContent?.id, 'oak_a');
      expect(_scene(tester).additionalSelectedContent.map((hit) => hit.id), [
        'oak_b',
        'npc:${npc.id}',
      ]);
      _scene(tester).onContent!(_model('oak_b', 6));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(
        h.view.selectionIn(h.document.current.id).map((target) => target.id),
        ['oak_a', npc.id],
      );
      expect(h.document.undoCount, 0);
    },
  );

  testWidgets('a press that never leaves its cell does not move the decor', (
    tester,
  ) async {
    final h = await _pump(tester);
    final before = h.document.current;
    final scene = _scene(tester);
    expect(scene.onDragStart!(3, 3, _model('oak_a', 3)), isTrue);
    scene.onDragUpdate!((3, 3));
    scene.onDragEnd!();
    await tester.pump();
    expect(h.document.current, same(before));
    expect(h.document.undoCount, 0);
    expect(h.view.selectionIn(before.id).single.id, 'oak_a');
  });

  testWidgets('arrows and delete act on every selected element at once', (
    tester,
  ) async {
    final h = await _pump(tester);
    _scene(tester).onContent!(_model('oak_a', 3));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    _scene(tester).onContent!(_model('oak_b', 6));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    final oaks = h.document.current.spatialScene!.instances;
    expect(oaks.map((item) => item.position.z), [4.5, 4.5]);
    expect(h.document.undoCount, 1);
    expect(_scene(tester).contentPreview, isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(h.document.current.spatialScene!.instances, isEmpty);
    expect(h.document.undoCount, 2);
    expect(h.view.selectionIn(h.document.current.id), isEmpty);
  });
}
