import 'package:avelune_studio/features/map_workspace/application/map_relief_tool.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import 'map_relief_fixture.dart';
import 'spatial_relief_tools_support.dart';

void main() {
  final project = reliefToolProject();
  testWidgets('the relief tool previews, paints, picks and changes levels', (
    tester,
  ) async {
    final map = reliefToolMap();
    final document = reliefDocument(map);
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    final view = MapEditingViewportSession()..tool = StudioMapTool.relief;
    view.relief
      ..profileId = 'fence'
      ..level = 2;
    addTearDown(controller.dispose);
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SpatialMapEditingViewport(
              document: document,
              controller: controller,
              project: project,
              visuals: ReliefVisuals(),
              view: view,
              onChanged: () => setState(() {}),
            ),
          ),
        ),
      ),
    );
    SpatialSceneView canvas() =>
        tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    Iterable<SpatialCellOverlay> previews() =>
        canvas().cellOverlays.where((item) => item.id.startsWith('relief:'));

    Iterable<SpatialCellOverlay> cursor() =>
        canvas().cellOverlays.where((item) => item.id == 'relief-cursor');
    canvas().onHover!(
      SpatialSurfaceHit(
        cell: (3, 2),
        position: Model3dVector3(x: 3.5, y: 1, z: 2.5),
      ),
    );
    await tester.pump();
    expect(previews(), isEmpty);
    expect(cursor().single.cell, (3, 2));
    expect(cursor().single.targetHeight, 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    expect(canvas().onDragStart!(3, 2, null), isTrue);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    canvas().onDragUpdate!((6, 5));
    await tester.pump();
    expect(previews().map((item) => item.cell).toSet(), hasLength(12));
    expect(previews().every((item) => item.targetHeight == 2), isTrue);
    expect(cursor().single.targetHeight, 1);
    expect(document.current, same(map));
    expect(canvas().scene.worldHeightAt(4.5, 3.5), 1);

    canvas().onDragEnd!();
    await tester.pump();
    expect(document.undoCount, 1);
    expect(document.current.spatialScene!.worldHeightAt(4.5, 3.5), 2);
    expect(document.current.spatialScene!.worldHeightAt(6.5, 5.5), 2);
    expect(reliefFeatures(document.current), ['relief-1']);
    expect(view.relief.outcome?.warnings, {MapReliefWarning.unreachable});

    view.relief.level = 0;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    canvas().onCell(4, 3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(view.relief.level, 2);
    expect(document.undoCount, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    expect(view.relief.level, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    expect(view.relief.level, 1);

    expect(canvas().onDragStart!(9, 8, null), isTrue);
    canvas().onDragUpdate!((10, 8));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(previews().where((item) => item.cell == (10, 8)), isEmpty);
    canvas().onDragEnd!();
    expect(document.undoCount, 1);

    view.tool = StudioMapTool.select;
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    expect(view.relief.level, 1);
  });

  testWidgets('a single click paints one cell and a refusal is reported', (
    tester,
  ) async {
    final map = reliefToolMap();
    final document = reliefDocument(map);
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    final view = MapEditingViewportSession()..tool = StudioMapTool.relief;
    view.relief.level = 3;
    addTearDown(controller.dispose);
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpatialMapEditingViewport(
            document: document,
            controller: controller,
            project: project,
            visuals: ReliefVisuals(),
            view: view,
            onChanged: () {},
          ),
        ),
      ),
    );
    final canvas = tester.widget<SpatialSceneView>(
      find.byType(SpatialSceneView),
    );
    canvas.onCell(4, 4);
    expect(view.relief.outcome?.problem, MapReliefProblem.noProfile);
    view.relief.profileId = 'fence';
    canvas.onCell(4, 4);
    expect(view.relief.outcome?.problem, MapReliefProblem.twoLevelMissing);
    expect(document.current, same(map));
  });
}
