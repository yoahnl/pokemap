import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_ramp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_ramp_fixture.dart';

void main() {

  testWidgets(
    'scene and ground use qualified preview and Escape or mutations cancel it without changing the map',
    (tester) async {
      final map = precisionRampMap(instances: false);
      final document = rampDocument(map);
      final project = workspaceProject.copyWith(
        version: ProjectVersion.v9,
        elements: [],
        tilesets: [],
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      );
      final controller =
          MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
            ..project = project
            ..active = document;
      final view = MapEditingViewportSession()
        ..tool = StudioMapTool.terrain
        ..spatialTerrainMode = SpatialTerrainMode.ramp;
      addTearDown(controller.dispose);
      addTearDown(view.dispose);
      final preview = SpatialRampEditingCommands(
        document,
      ).preview(map.spatialScene!.navigation.ramps.first.copyWith(depth: 2.75));
      view.rampPreview = preview;
      late StateSetter refresh;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                refresh = setter;
                return SpatialMapEditingViewport(
                  document: document,
                  controller: controller,
                  project: project,
                  visuals: _RampVisuals(),
                  view: view,
                  onChanged: () => refresh(() {}),
                );
              },
            ),
          ),
        ),
      );
      SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
      expect(scene().scene, preview.result.spatialScene);
      expect(scene().groundMap, preview.result);
      expect(document.current, same(map));
      expect(view.hasSelectionIn(map.id), isFalse);
      expect(view.pendingMove, isNull);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(view.rampPreview, isNull);
      expect(scene().scene, map.spatialScene);
      expect(scene().groundMap, map);
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      view.rampPreview = preview;
      refresh(() {});
      await tester.pump();
      view.tool = StudioMapTool.pan;
      refresh(() {});
      await tester.pump();
      expect(scene().scene, map.spatialScene);
      expect(view.rampPreview, same(preview));
      view.tool = StudioMapTool.terrain;
      refresh(() {});
      await tester.pump();
      expect(scene().scene, preview.result.spatialScene);
      scene().onDragStart!(12, 10, null);
      await tester.pump();
      expect(view.rampPreview, isNull);
      scene().onDragEnd!();
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}

class _RampVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
