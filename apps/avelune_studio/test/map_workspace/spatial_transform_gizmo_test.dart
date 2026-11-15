import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_transform_gizmo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import 'spatial_shared_commands_support.dart';

Offset? _project(Model3dVector3 point) => Offset(
  100 + point.x * 40 + point.z * 10,
  300 - point.y * 40 + point.z * 20,
);

late StateSetter _redraw;

Future<void> _rebuild(WidgetTester tester) async {
  _redraw(() {});
  await tester.pump();
}

Future<(EditableMapDocument, MapEditingViewportSession)> _pump(
  WidgetTester tester,
) async {
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
    entities: const [],
  );
  final document = EditableMapDocument(
    MapWorkspaceDocument(map: map, mapId: map.id, revision: 'gizmo'),
  );
  final view = MapEditingViewportSession()..tool = StudioMapTool.select;
  final controller =
      MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
        ..project = project
        ..active = document;
  addTearDown(view.dispose);
  addTearDown(controller.dispose);
  final visuals = SpatialTestVisuals();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            _redraw = setState;
            return SpatialMapEditingViewport(
              document: document,
              controller: controller,
              project: project,
              visuals: visuals,
              view: view,
              onChanged: () => setState(() {}),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
  view
    ..select(document, MapSelectionFamily.decor, 'oak_a')
    ..toggleInSelection(document, MapSelectionFamily.decor, 'oak_b');
  await _rebuild(tester);
  return (document, view);
}

SpatialTransformGizmo _gizmo(WidgetTester tester) =>
    tester.widget(find.byType(SpatialTransformGizmo));

SpatialSceneView _scene(WidgetTester tester) =>
    tester.widget(find.byType(SpatialSceneView));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each axis arrow follows the projected world axis', () {
    final origin = Model3dVector3(x: 1, y: 0, z: 1);
    final x = spatialGizmoHandle(_project, origin, SpatialGizmoAxis.x)!;
    final z = spatialGizmoHandle(_project, origin, SpatialGizmoAxis.z)!;
    expect(x.start, const Offset(150, 320));
    expect(x.end.dy, 320);
    expect(x.end.dx, greaterThan(x.start.dx));
    expect(z.end.dx, z.start.dx);
    expect(z.end.dy, lessThan(z.start.dy));
    expect(x.pixelsPerUnit, 40);
    expect(
      spatialGizmoAxisAt(_project, origin, x.end - const Offset(2, 3)),
      SpatialGizmoAxis.x,
    );
    expect(spatialGizmoAxisAt(_project, origin, const Offset(0, 0)), isNull);
    expect(spatialGizmoDistance(x, x.start, x.start + const Offset(80, 0)), 2);
  });

  test('gizmo steps snap to the grid unless the fine modifier is held', () {
    expect(spatialGizmoStep(SpatialGizmoAxis.x, 1.4, fine: false), 1);
    expect(spatialGizmoStep(SpatialGizmoAxis.y, -0.6, fine: false), -1);
    expect(spatialGizmoStep(SpatialGizmoAxis.z, 0.6, fine: false), .5);
    expect(spatialGizmoStep(SpatialGizmoAxis.x, 1.374, fine: true), 1.37);
  });

  testWidgets('dragging the Z arrow lifts the whole group in one undo step', (
    tester,
  ) async {
    final (document, view) = await _pump(tester);
    final before = document.current;
    _gizmo(tester).onDrag(SpatialGizmoAxis.z, .6, false);
    await tester.pump();
    expect(document.current, same(before));
    expect(_scene(tester).contentPreview?.position.y, .5);
    expect(_scene(tester).additionalContentPreviews.single.position.y, .5);
    _gizmo(tester).onEnd();
    await tester.pump();
    final instances = document.current.spatialScene!.instances;
    expect(instances.map((item) => item.position.y), [.5, .5]);
    expect(document.undoCount, 1);
    _gizmo(tester).onDrag(SpatialGizmoAxis.x, 1.4, false);
    _gizmo(tester).onEnd();
    await tester.pump();
    expect(
      document.current.spatialScene!.instances.map((item) => item.position.x),
      [4.5, 7.5],
    );
    expect(document.undoCount, 2);
    _gizmo(tester).onDrag(SpatialGizmoAxis.y, .26, true);
    _gizmo(tester).onCancel();
    await tester.pump();
    expect(_scene(tester).contentPreview, isNull);
    expect(document.undoCount, 2);
    document.restore(redo: false);
    document.restore(redo: false);
    expect(document.current, before);
    expect(view.selectionIn(before.id), hasLength(2));
  });

  testWidgets('the axis gizmo only exists for a 3D selection with Sélection', (
    tester,
  ) async {
    final (document, view) = await _pump(tester);
    expect(find.byType(SpatialTransformGizmo), findsOneWidget);
    view.tool = StudioMapTool.pan;
    await _rebuild(tester);
    expect(find.byType(SpatialTransformGizmo), findsNothing);
    view
      ..tool = StudioMapTool.select
      ..clearSelection(document);
    await _rebuild(tester);
    expect(find.byType(SpatialTransformGizmo), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  });
}
