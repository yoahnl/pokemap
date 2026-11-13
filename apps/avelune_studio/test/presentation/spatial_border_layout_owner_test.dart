import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../application/spatial_border_commands_test.dart' show borderDocument;
import '../support/map_workspace_fixture.dart';
import '../support/spatial_border_fixture.dart';

void main() {
  testWidgets('refused 3D border preserves source and viewport', (
    tester,
  ) async {
    final fixture = await _mount(tester);
    final source = fixture.document.current;
    final viewport = tester.getRect(find.byType(SpatialSceneView));
    fixture.scene(tester).onCell(2, 6);
    fixture.scene(tester).onCell(8, 8);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    final failure = fixture.document.error;
    expect(failure, contains('border.spatial.straight_only_geometry_required'));
    expect(tester.getRect(find.byType(SpatialSceneView)), viewport);
    expect(fixture.document.current, same(source));
    expect(fixture.document.undoCount, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(fixture.document.error, isNull);
    expect(fixture.view.borderDraft, isNull);
    expect(tester.getRect(find.byType(SpatialSceneView)), viewport);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Escape preserves a later non-border document error', (
    tester,
  ) async {
    final fixture = await _mount(tester);
    fixture.scene(tester).onCell(2, 6);
    fixture.scene(tester).onCell(8, 8);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    fixture.document.error = 'Échec de sauvegarde distinct';
    fixture.refresh();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(fixture.document.error, 'Échec de sauvegarde distinct');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'finish and hover retain one owned refusal until an angle is removed',
    (tester) async {
      final fixture = await _mount(tester, size: const Size(1440, 900));
      final viewport = tester.getRect(find.byType(SpatialSceneView));
      final source = fixture.document.current;
      fixture.scene(tester).onCell(2, 6);
      fixture.scene(tester).onCell(8, 8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      final failure = fixture.document.error!;
      fixture.scene(tester).onHover!(
        SpatialSurfaceHit(
          cell: (9, 8),
          position: Model3dVector3(x: 9.5, y: 0, z: 8.5),
        ),
      );
      await tester.pump();
      expect(fixture.document.error, failure);
      expect(tester.getRect(find.byType(SpatialSceneView)), viewport);
      fixture.view.removeLastBorderAngle(fixture.document);
      fixture.refresh();
      await tester.pump();
      expect(fixture.document.error, isNull);
      expect(fixture.view.borderDraft!.anchors, hasLength(1));
      expect(tester.getRect(find.byType(SpatialSceneView)), viewport);
      expect(fixture.document.current, same(source));
      expect(fixture.document.undoCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancel clears its refusal while retaining a different error', (
    tester,
  ) async {
    final fixture = await _mount(tester, size: const Size(1440, 900));
    fixture.scene(tester).onCell(2, 6);
    fixture.scene(tester).onCell(8, 8);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    fixture.document.error = 'Échec de sauvegarde après le refus';
    fixture.refresh();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(fixture.view.borderDraft, isNull);
    expect(fixture.document.error, 'Échec de sauvegarde après le refus');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a corrected border finishes after a refusal with no lingering error',
    (tester) async {
      final fixture = await _mount(tester, size: const Size(1440, 900));
      final source = fixture.document.current;
      fixture.scene(tester).onCell(2, 6);
      fixture.scene(tester).onCell(8, 8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(fixture.document.error, isNotNull);
      fixture.view.removeLastBorderAngle(fixture.document);
      fixture.refresh();
      await tester.pump();
      fixture.scene(tester).onCell(8, 6);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(fixture.document.current, isNot(same(source)));
      expect(fixture.document.current.spatialScene!.instances, isNotEmpty);
      expect(fixture.document.error, isNull);
      expect(fixture.view.borderDraftFailure, isNull);
      expect(fixture.view.borderDraft, isNull);
      expect(fixture.document.undoCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'controller errors stay globally visible during a refused border',
    (tester) async {
      final fixture = await _mount(tester);
      fixture.scene(tester).onCell(2, 6);
      fixture.scene(tester).onCell(8, 8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      fixture.controller.error = 'Impossible de charger le projet';
      fixture.refresh();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(fixture.controller.error, 'Impossible de charger le projet');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a controller failure with the same text is not owned by the draft',
    (tester) async {
      final fixture = await _mount(tester);
      fixture.scene(tester).onCell(2, 6);
      fixture.scene(tester).onCell(8, 8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      final failure = fixture.document.error!;
      fixture.controller.error = failure;
      fixture.refresh();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(fixture.controller.error, failure);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<_Fixture> _mount(
  WidgetTester tester, {
  Size size = const Size(1024, 640),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = spatialBorderProject(straightOnly: true);
  final map = MapData(
    id: 'a',
    name: 'Atelier vierge',
    version: ProjectVersion.v9,
    size: const GridSize(width: 16, height: 16),
    spatialScene: MapSpatialScene(width: 16, depth: 16),
  );
  final document = borderDocument(map);
  final controller =
      MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
        ..project = project
        ..active = document;
  controller.documents[map.id] = document;
  final view = MapEditingViewportSession()
    ..tool = StudioMapTool.border
    ..borderBlueprintId = 'fence';
  addTearDown(controller.dispose);
  addTearDown(view.dispose);
  late VoidCallback refresh;
  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (context, update) {
          refresh = () => update(() {});
          return Scaffold(
            body: SpatialMapEditingViewport(
              document: document,
              controller: controller,
              project: project,
              view: view,
              visuals: _Visuals(),
              onChanged: refresh,
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
  return _Fixture(document, controller, view, refresh);
}

class _Fixture {
  _Fixture(this.document, this.controller, this.view, this.refresh);
  final EditableMapDocument document;
  final MapWorkspaceController controller;
  final MapEditingViewportSession view;
  final VoidCallback refresh;
  SpatialSceneView scene(WidgetTester tester) =>
      tester.widget(find.byType(SpatialSceneView));
}

class _Visuals extends WorkspaceTestVisuals implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async =>
      throw StateError('Layout fixture');
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
