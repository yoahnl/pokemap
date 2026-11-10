import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_surface_editing_session.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import 'spatial_relief_tools_test.dart' show ReliefVisuals;

void main() {
  testWidgets(
    'continuous terrain is drawn with a live preview and one undo in the existing relief tool',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final map = MapData(
        id: 'a',
        name: 'Terrain',
        version: ProjectVersion.v9,
        size: const GridSize(width: 8, height: 6),
        spatialScene: MapSpatialScene(width: 8, depth: 6),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
      );
      final view = MapEditingViewportSession()
        ..tool = StudioMapTool.terrain
        ..spatialTerrainMode = SpatialTerrainMode.relief;
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      final project = workspaceProject.copyWith(
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
      );
      late VoidCallback refresh;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) {
                refresh = () => update(() {});
                return SpatialMapEditingViewport(
                  document: document,
                  controller: controller,
                  project: project,
                  visuals: ReliefVisuals(),
                  view: view,
                  onChanged: refresh,
                );
              },
            ),
          ),
        ),
      );
      view.spatialContinuousTerrain = true;
      view.spatialSurfaceReanchorInstances = false;
      refresh();
      await tester.pump();
      expect(view.spatialSurfaceReanchorInstances, isFalse);
      final editing = SpatialTerrainSurfaceEditingSession(document, view);
      addTearDown(editing.dispose);
      SpatialSceneView canvas() => tester.widget(find.byType(SpatialSceneView));
      expect(canvas().onDragStart!(1, 1, null), isTrue);
      canvas().onDragUpdate!((3, 2));
      await tester.pump();
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      expect(canvas().scene.terrainSurfaces.surfaces, hasLength(1));
      expect(canvas().scene.worldHeightAt(2.5, 1.5), closeTo(.75, 1e-12));
      canvas().onDragEnd!();
      await tester.pump();
      expect(
        document.current.spatialScene!.terrainSurfaces.surfaces,
        hasLength(1),
      );
      expect(document.current.spatialScene!.worldHeightAt(.5, .5), 0);
      expect(document.undoCount, 1);
      expect(document.current.layers, map.layers);
      expect(
        document.current.spatialScene!.heightLevels,
        map.spatialScene!.heightLevels,
      );
      final surface =
          document.current.spatialScene!.terrainSurfaces.surfaces.single;
      editing.load();
      expect(editing.surface!.id, surface.id);
      expect(
        canvas().cellOverlays.any(
          (overlay) => overlay.id.startsWith('terrain-surface-selection:'),
        ),
        isTrue,
      );
      editing.values['x'] = '4';
      editing.preview();
      refresh();
      await tester.pump();
      expect(
        document.current.spatialScene!.terrainSurfaces.surfaces.single,
        surface,
      );
      expect(canvas().scene.terrainSurfaces.surfaces.single.x, 4);
      expect(canvas().scene.worldHeightAt(4.5, 1.5), closeTo(.75, 1e-12));
      Focus.of(tester.element(find.byType(SpatialSceneView))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(view.terrainSurfacePreview, isNull);
      expect(view.spatialSurfaceId, isNull);
      expect(
        document.current.spatialScene!.terrainSurfaces.surfaces.single,
        surface,
      );
      view.spatialSurfaceId = surface.id;
      editing.load();
      editing.values['x'] = '4';
      editing.preview();
      refresh();
      await tester.pump();
      editing.apply();
      refresh();
      await tester.pump();
      expect(
        document.current.spatialScene!.terrainSurfaces.surfaces.single.x,
        4,
      );
      expect(document.undoCount, 2);
      editing.edit(() => view.spatialSurfaceSelect = true);
      refresh();
      await tester.pump();
      expect(canvas().onDragStart!(0, 0, null), isFalse);
      await tester.pump();
      expect(view.spatialSurfaceId, isNull);
      expect(canvas().onDragStart!(4, 1, null), isFalse);
      await tester.pump();
      expect(view.spatialSurfaceId, surface.id);
      editing.load();
      editing.delete();
      refresh();
      await tester.pump();
      expect(document.current.spatialScene!.terrainSurfaces.surfaces, isEmpty);
      expect(document.undoCount, 3);
      document.restore(redo: false);
      await tester.pump();
      expect(
        document.current.spatialScene!.terrainSurfaces.surfaces.single.x,
        4,
      );
      document.restore(redo: false);
      await tester.pump();
      expect(
        document.current.spatialScene!.terrainSurfaces.surfaces.single,
        surface,
      );
      document.restore(redo: false);
      await tester.pump();
      expect(document.current, map);
      editing.edit(() => view.spatialSurfaceSelect = false);
      refresh();
      await tester.pump();
      expect(canvas().onDragStart!(1, 1, null), isTrue);
      canvas().onDragUpdate!((3, 2));
      await tester.pump();
      view.spatialContinuousTerrain = false;
      view.terrainSurfacePreview = null;
      refresh();
      await tester.pump();
      canvas().onDragEnd!();
      await tester.pump();
      expect(document.current, map);
      expect(document.undoCount, 0);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
