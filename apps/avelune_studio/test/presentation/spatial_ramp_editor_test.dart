import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_ramp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_ramp_editing_session.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_ramp_fixture.dart';

void main() {
  test('project metadata refresh preserves an unapplied ramp draft', () {
    final document = rampDocument(precisionRampMap(instances: false));
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    final project = ProjectManifest(name: 'Initial', maps: [], tilesets: []);
    final editing = SpatialRampEditingSession(document, view, project: project);
    addTearDown(editing.dispose);
    editing.x = '2,1875';
    editing.updateProject(project.copyWith(name: 'Renamed'));
    expect(editing.x, '2,1875');
    expect(document.canUndo, isFalse);
  });

  test('ramp surface choices exclude blocking decors and can return to terrain with undo', () {
    final original = precisionRampMap(instances: false);
    final map = original.copyWith(
      spatialScene: original.spatialScene!.copyWith(
        instances: [
          SpatialModelInstance(
            id: 'stairs',
            modelId: 'stair-model',
            position: Model3dVector3(x: 3.5, y: 1, z: 4.5),
            blocksMovement: false,
          ),
          SpatialModelInstance(
            id: 'wall',
            modelId: 'wall-model',
            position: Model3dVector3(x: 8, y: 1, z: 8),
            blocksMovement: true,
          ),
        ],
      ),
    );
    final document = rampDocument(map);
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    final editing = SpatialRampEditingSession(document, view);
    addTearDown(editing.dispose);
    expect(editing.surfaceChoices.map((instance) => instance.id), ['stairs']);
    editing.surfaceInstanceId = 'stairs';
    editing.preview();
    expect(view.rampPreview!.updatedRamp.surfaceInstanceId, 'stairs');
    expect(document.current, map);
    editing.apply();
    expect(
      document.current.spatialScene!.navigation.ramps.first.surfaceInstanceId,
      'stairs',
    );
    expect(
      document.current.spatialScene!.instances,
      map.spatialScene!.instances,
    );
    final linked = document.current;
    editing.surfaceInstanceId = null;
    editing.preview();
    editing.apply();
    expect(document.current, map);
    document.restore(redo: false);
    expect(document.current, linked);
  });

  test('French fractional draft previews cancels and applies once without altering other ramps', () {
    final map = precisionRampMap();
    final document = rampDocument(map);
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    final editing = SpatialRampEditingSession(document, view);
    addTearDown(editing.dispose);
    expect(editing.x, '2.125');
    expect(editing.width, '3.625');
    editing.x = '2,1875';
    editing.width = '3,5625';
    editing.preview();
    final preview = view.rampPreview!;
    expect(preview.updatedRamp.x, 2.1875);
    expect(preview.updatedRamp.width, 3.5625);
    expect(document.current, same(map));
    expect(document.undoCount, 0);
    editing.clearPreview(view);
    expect(view.rampPreview, isNull);
    expect(document.current, same(map));
    editing.preview();
    editing.apply();
    expect(document.current, preview.result);
    expect(
      document.current.spatialScene!.navigation.ramps.last,
      map.spatialScene!.navigation.ramps.last,
    );
    expect(document.undoCount, 1);
    expect(view.rampPreview, isNull);
    expect(
      editing.notice,
      'Pente appliquée. Une seule annulation restaure la carte.',
    );
    document.restore(redo: false);
    expect(document.current, map);
  });

  test('selection exact values validation and concurrent changes invalidate owned previews', () {
    final map = precisionRampMap();
    final document = rampDocument(map);
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    final editing = SpatialRampEditingSession(document, view);
    addTearDown(editing.dispose);
    editing.depth = '2,75';
    editing.preview();
    expect(view.rampPreview, isNotNull);
    editing.edit(() => editing.x = 'NaN');
    expect(view.rampPreview, isNull);
    editing.preview();
    expect(editing.error, 'X doit être un nombre fini, par exemple 1,25.');
    expect(document.current, same(map));
    editing.edit(
      () =>
          editing.load(map, rampId: map.spatialScene!.navigation.ramps.last.id),
    );
    expect(editing.x, '9.0');
    expect(editing.width, '2.75');
    expect(editing.error, isNull);
    editing.depth = '1,75';
    editing.preview();
    expect(view.rampPreview, isNull);
    expect(
      editing.error,
      'Les deux extrémités de la pente doivent toucher les sols aux niveaux bas et haut choisis.',
    );
    expect(document.current, same(map));
    editing.depth = '2,75';
    editing.preview();
    final preview = view.rampPreview!;
    view.spatialFreeView = true;
    editing.synchronize();
    expect(view.rampPreview, same(preview));
    document.commit(map.copyWith(name: 'Changement concurrent'));
    editing.synchronize();
    expect(view.rampPreview, isNull);
    expect(editing.depth, '3.0');
    expect(
      editing.notice,
      'La carte a changé. Les valeurs affichées ont été actualisées.',
    );
    document.saving = true;
    expect(editing.enabled, isFalse);
    editing.preview();
    expect(view.rampPreview, isNull);
    document.saving = false;
  });

  test(
    'all four native stair footprints load without rounding or redundant undo',
    () {
      final footprints = [
        SpatialRamp(
          id: 'high',
          x: 11.6875,
          z: 13,
          width: 3.625,
          depth: 2,
          lowLevel: 28,
          highLevel: 36,
          direction: SpatialRampDirection.north,
        ),
        SpatialRamp(
          id: 'mid',
          x: 11.6875,
          z: 17,
          width: 3.625,
          depth: 2,
          lowLevel: 20,
          highLevel: 28,
          direction: SpatialRampDirection.north,
        ),
        SpatialRamp(
          id: 'east',
          x: 18,
          z: 20.6875,
          width: 4,
          depth: 1.625,
          lowLevel: 4,
          highLevel: 20,
          direction: SpatialRampDirection.west,
        ),
        SpatialRamp(
          id: 'route',
          x: 54.998046875,
          z: 13.125,
          width: 5.001953125,
          depth: 1.75,
          lowLevel: 3,
          highLevel: 23,
          direction: SpatialRampDirection.east,
        ),
      ];
      for (final footprint in footprints) {
        final document = rampDocument(sourceRampFootprint(footprint));
        final view = MapEditingViewportSession();
        addTearDown(view.dispose);
        final editing = SpatialRampEditingSession(document, view);
        expect(editing.x, '${footprint.x}');
        expect(editing.y, '${footprint.z}');
        expect(editing.width, '${footprint.width}');
        expect(editing.depth, '${footprint.depth}');
        expect(editing.highLevel, '${footprint.highLevel}');
        expect(editing.direction, footprint.direction);
        editing.preview();
        expect(view.rampPreview!.hasChanges, isFalse);
        expect(document.undoCount, 0);
        editing.dispose();
        expect(view.rampPreview, isNull);
      }
    },
  );

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
