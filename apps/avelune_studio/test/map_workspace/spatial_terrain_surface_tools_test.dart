import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_terrain_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
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
      final view = MapWorkspaceViewState()
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
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => Row(
                children: [
                  Expanded(
                    child: SpatialMapEditor(
                      document: document,
                      controller: controller,
                      project: project,
                      visuals: ReliefVisuals(),
                      view: view,
                      onChanged: () => refresh(() {}),
                    ),
                  ),
                  SizedBox(
                    width: 330,
                    child: SingleChildScrollView(
                      child: SpatialTerrainControls(
                        document: document,
                        project: project,
                        view: view,
                        visuals: ReliefVisuals(),
                        onChanged: () => refresh(() {}),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final picker = find.byKey(const ValueKey('spatial-relief-shape'));
      expect(picker, findsOneWidget);
      tester.widget<StudioSelect>(picker).onChanged!('surface');
      await tester.pump();
      final modelHeights = find.byKey(
        const ValueKey('spatial-surface-model-heights'),
      );
      expect(modelHeights, findsOneWidget);
      tester.widget<StudioSelect>(modelHeights).onChanged!('keep');
      await tester.pump();
      expect(view.spatialSurfaceReanchorInstances, isFalse);
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
      final editPicker = find.byKey(const ValueKey('terrain-surface-picker'));
      expect(editPicker, findsOneWidget);
      expect(tester.widget<StudioSelect>(editPicker).value, surface.id);
      expect(
        canvas().cellOverlays.any(
          (overlay) => overlay.id.startsWith('terrain-surface-selection:'),
        ),
        isTrue,
      );
      final xInput = find.descendant(
        of: find.byKey(const ValueKey('terrain-surface-x')),
        matching: find.byType(TextField),
      );
      await tester.enterText(xInput, '4');
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('terrain-surface-preview')),
          )
          .onPressed!();
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
      tester.widget<StudioSelect>(editPicker).onChanged!(surface.id);
      await tester.pump();
      await tester.enterText(xInput, '4');
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('terrain-surface-preview')),
          )
          .onPressed!();
      await tester.pump();
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('terrain-surface-apply')),
          )
          .onPressed!();
      await tester.pump();
      expect(
        document.current.spatialScene!.terrainSurfaces.surfaces.single.x,
        4,
      );
      expect(document.undoCount, 2);
      tester
          .widget<StudioButton>(
            find.widgetWithText(StudioButton, 'Sélectionner'),
          )
          .onPressed!();
      await tester.pump();
      expect(canvas().onDragStart!(0, 0, null), isFalse);
      await tester.pump();
      expect(view.spatialSurfaceId, isNull);
      expect(canvas().onDragStart!(4, 1, null), isFalse);
      await tester.pump();
      expect(view.spatialSurfaceId, surface.id);
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('terrain-surface-delete')),
          )
          .onPressed!();
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
      tester
          .widget<StudioButton>(find.widgetWithText(StudioButton, 'Dessiner'))
          .onPressed!();
      await tester.pump();
      expect(canvas().onDragStart!(1, 1, null), isTrue);
      canvas().onDragUpdate!((3, 2));
      await tester.pump();
      tester.widget<StudioSelect>(picker).onChanged!('blocks');
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
