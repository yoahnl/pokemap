import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/services.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'spatial_relief_tools_support.dart';

void main() {
  testWidgets(
    'Shift arrows orbit the editor without changing the game camera',
    (tester) async {
      final map = reliefMap();
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
      );
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      final view = MapEditingViewportSession()
        ..tool = StudioMapTool.terrain
        ..spatialTerrainMode = SpatialTerrainMode.relief;
      addTearDown(controller.dispose);
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SpatialMapEditingViewport(
                document: document,
                controller: controller,
                project: workspaceProject,
                visuals: ReliefVisuals(),
                view: view,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ),
      );
      final scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      final yaw = scene.controller.yaw;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(view.spatialFreeView, isTrue);
      expect(scene.controller.view, SpatialEditorView.orbit);
      expect(scene.controller.yaw, isNot(yaw));
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      expect(document.current.spatialScene!.camera, map.spatialScene!.camera);
      final canvas = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(canvas.onDragStart!(1, 3, null), isTrue);
      canvas.onDragEnd!();
      expect(document.undoCount, 1);
    },
  );

  testWidgets('relief drag previews height and Escape discards the stroke', (
    tester,
  ) async {
    final map = reliefMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
    );
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    final view = MapEditingViewportSession()
      ..tool = StudioMapTool.terrain
      ..spatialTerrainMode = SpatialTerrainMode.relief
      ..spatialTerrainLevel = 2;
    addTearDown(controller.dispose);
    addTearDown(view.dispose);
    late VoidCallback redraw;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              redraw = () => setState(() {});
              return SpatialMapEditingViewport(
                document: document,
                controller: controller,
                project: workspaceProject,
                visuals: ReliefVisuals(),
                view: view,
                onChanged: () => setState(() {}),
              );
            },
          ),
        ),
      ),
    );
    var canvas = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    canvas.onHover!(
      SpatialSurfaceHit(
        cell: (1, 4),
        position: Model3dVector3(x: 1.25, y: 0, z: 4.75),
      ),
    );
    await tester.pump();
    canvas = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(
      canvas.cellOverlays.where(
        (item) =>
            item.kind == SpatialCellOverlayKind.preview &&
            item.cell == (1, 4) &&
            item.targetHeight == 2,
      ),
      hasLength(1),
    );
    expect(canvas.scene.heightAt(1, 4), 0);
    expect(
      canvas.cellOverlays.where(
        (item) =>
            item.kind == SpatialCellOverlayKind.preview &&
            item.cell == (1, 4) &&
            item.targetHeight == 0,
      ),
      hasLength(1),
    );
    expect(document.undoCount, 0);
    expect(canvas.onDragStart!(1, 4, null), isTrue);
    canvas.onDragUpdate!((5, 4));
    await tester.pump();
    canvas = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(canvas.scene.heightAt(3, 4), 2);
    expect(document.current, same(map));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    canvas.onDragEnd!();
    expect(document.current, map);
    expect(document.undoCount, 0);
    canvas = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(canvas.onDragStart!(1, 4, null), isTrue);
    canvas.onDragUpdate!((5, 4));
    canvas.onDragEnd!();
    expect(document.current.spatialScene!.heightAt(3, 4), 2);
    expect(document.undoCount, 1);
    canvas.onDragStart!(1, 2, null);
    canvas.onDragUpdate!((5, 2));
    document.commit(
      document.current.copyWith(name: 'Renommée pendant le trait'),
    );
    redraw();
    await tester.pump();
    canvas = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(canvas.scene, document.current.spatialScene);
    expect(canvas.groundMap, same(document.current));
    final changed = document.current;
    canvas.onDragEnd!();
    expect(document.current, same(changed));
  });
}
