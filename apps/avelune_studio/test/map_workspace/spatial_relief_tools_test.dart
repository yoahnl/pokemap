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
    'slope viewport preserves complete preview geometry and invalid diagnostics',
    (tester) async {
      final map = reliefMap(raised: true);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
      );
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      final view = MapEditingViewportSession()
        ..tool = StudioMapTool.terrain
        ..spatialTerrainMode = SpatialTerrainMode.ramp;
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
      SpatialSceneView canvas() => tester.widget(find.byType(SpatialSceneView));
      expect(canvas().onDragStart!(3, 5, null), isTrue);
      canvas().onDragUpdate!((4, 3));
      await tester.pump();
      expect(
        canvas().cellOverlays.where(
          (item) => item.kind == SpatialCellOverlayKind.preview,
        ),
        hasLength(6),
      );
      final ramp = canvas().scene.navigation.ramps.single;
      expect(ramp.direction, SpatialRampDirection.north);
      expect(ramp.lowLevel, 0);
      expect(ramp.highLevel, 1);
      expect(ramp.width, 2);
      expect(ramp.depth, 3);
      expect(document.current, same(map));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(canvas().scene.navigation.ramps, hasLength(1));
      expect(document.undoCount, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(canvas().scene.navigation.ramps, isEmpty);
      expect(canvas().onDragStart!(0, 5, null), isTrue);
      canvas().onDragUpdate!((1, 3));
      await tester.pump();
      expect(document.error, contains('La pente doit relier un sol bas'));
      expect(document.undoCount, 0);
      canvas().onDragEnd!();
      expect(document.current, same(map));
      expect(document.undoCount, 0);
    },
  );

  testWidgets(
    'model hover is temporary, Shift is precise, and click matches preview',
    (tester) async {
      final model = ProjectModel3dEntry(
        id: 'rock',
        name: 'Rocher',
        sourceAssetId: 'rock_source',
        relativePath: 'assets/models3d/rock.glb',
        inspection: Model3dInspection(
          meshCount: 1,
          triangleCount: 12,
          bounds: Model3dBounds(
            min: Model3dVector3.zero,
            max: Model3dVector3(x: 1, y: 1, z: 1),
          ),
        ),
      );
      final project = workspaceProject.copyWith(models3d: [model]);
      final map = reliefMap();
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
      );
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      final view = MapEditingViewportSession()
        ..tool = StudioMapTool.place
        ..model3d = model;
      addTearDown(controller.dispose);
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  const TextField(key: ValueKey('precision-focus-field')),
                  Expanded(
                    child: SpatialMapEditingViewport(
                      document: document,
                      controller: controller,
                      project: project,
                      visuals: ReliefVisuals(),
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
      SpatialSceneView canvas() => tester.widget(find.byType(SpatialSceneView));
      final hit = SpatialSurfaceHit(
        cell: (2, 3),
        position: Model3dVector3(x: 2.2, y: 0, z: 3.7),
      );
      expect(canvas().onHover, isNotNull);
      canvas().onHover!(hit);
      await tester.pump();
      expect(canvas().placementPreview!.position.x, 2.5);
      expect(canvas().placementPreview!.position.z, 3.5);
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      canvas().onHover!(null);
      await tester.pump();
      expect(canvas().placementPreview, isNull);
      canvas().onHover!(hit);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('precision-focus-field')));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      canvas().onHover!(hit);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(canvas().controller.view, SpatialEditorView.orbit);
      expect(canvas().placementPreview!.position, hit.position);
      canvas().onSurfaceTap!(hit);
      await tester.pump();
      expect(
        document.current.spatialScene!.instances.single.position,
        hit.position,
      );
      expect(document.undoCount, 1);
      expect(canvas().placementPreview, isNull);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(MapData.fromJson(document.current.toJson()), document.current);
      view.tool = StudioMapTool.select;
      canvas().onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.model,
          id: document.current.spatialScene!.instances.single.id,
          cell: (2, 3),
        ),
      );
      await tester.pump();
      final placed = document.current;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(document.current, same(placed));
      expect(document.undoCount, 1);
    },
  );
}
