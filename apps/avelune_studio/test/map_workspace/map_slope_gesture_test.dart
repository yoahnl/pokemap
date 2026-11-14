import 'package:avelune_studio/features/map_workspace/application/map_relief_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_slope_commands.dart';
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

ProjectManifest _project() {
  final project = reliefToolProject();
  return project.copyWith(
    models3d: [
      ...project.models3d,
      ProjectModel3dEntry(
        id: 'stone-stair',
        name: 'Escalier de pierre',
        sourceAssetId: 'stone-stair-source',
        relativePath: 'assets/models3d/stone-stair.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3(x: -1.69, y: 0, z: -.5),
            max: Model3dVector3(x: 1.69, y: 1.19, z: .5),
          ),
          meshCount: 1,
          triangleCount: 1,
        ),
      ),
    ],
  );
}

void main() {
  final project = _project();
  testWidgets('the slope and stair tools preview, apply and cancel', (
    tester,
  ) async {
    final plateau = reliefDocument(reliefToolMap());
    MapReliefCommands(plateau, project).apply(
      MapReliefStroke(
        source: plateau.current,
        origin: const GridPos(x: 2, y: 1),
        level: 2,
        rectangle: true,
      )..paint(const GridPos(x: 8, y: 4)),
      MapReliefToolState()..profileId = 'fence',
    );
    final map = plateau.current;
    final document = reliefDocument(map);
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    final view = MapEditingViewportSession()..tool = StudioMapTool.slope;
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
        canvas().cellOverlays.where((item) => item.id.startsWith('slope:'));

    expect(canvas().onDragStart!(5, 8, null), isTrue);
    canvas().onDragUpdate!((5, 3));
    await tester.pump();
    expect(previews().map((item) => item.cell).toSet(), {
      for (var y = 5; y <= 8; y++) (5, y),
    });
    expect(document.current, same(map));
    canvas().onDragEnd!();
    await tester.pump();
    expect(document.undoCount, 1);
    expect(view.slope.outcome?.problem, isNull);
    expect(
      document.current.spatialScene!.terrainSurfaces.surfaces.last.closedFlanks,
      isTrue,
    );

    expect(canvas().onDragStart!(10, 8, null), isTrue);
    canvas().onDragUpdate!((10, 6));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(previews().where((item) => item.cell == (10, 7)), isEmpty);
    canvas().onDragEnd!();
    expect(document.undoCount, 1);

    view.tool = StudioMapTool.stair;
    await tester.pump();
    canvas().onCell(7, 4);
    expect(view.slope.outcome?.problem, MapSlopeProblem.noStairModel);
    view.slope.stairModelId = 'stone-stair';
    canvas().onCell(7, 4);
    await tester.pump();
    expect(view.slope.outcome?.problem, isNull);
    expect(document.undoCount, 2);
    expect(
      document.current.spatialScene!.instances.where((i) => i.id == 'stair-1'),
      hasLength(1),
    );
  });
}
