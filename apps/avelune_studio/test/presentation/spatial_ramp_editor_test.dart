import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_ramp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_ramp_editor.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_ramp_fixture.dart';

Finder input(String label) => find.descendant(
  of: find.byKey(ValueKey('spatial-ramp-$label')),
  matching: find.byType(TextField),
);

StudioButton button(WidgetTester tester, String action) =>
    tester.widget(find.byKey(ValueKey('spatial-ramp-$action')));

void main() {
  testWidgets(
    'a guided ramp surface can select a walkable decor then return to terrain with undo',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => SingleChildScrollView(
                child: SpatialRampEditor(
                  document: document,
                  view: view,
                  onChanged: () => refresh(() {}),
                ),
              ),
            ),
          ),
        ),
      );
      final finder = find.byKey(const ValueKey('spatial-ramp-surface'));
      expect(finder, findsOneWidget);
      final selector = tester.widget<StudioSelect>(finder);
      expect(selector.options.keys, contains('stairs'));
      expect(selector.options.keys, isNot(contains('wall')));
      selector.onChanged!('stairs');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-preview')));
      await tester.pump();
      expect(
        view.rampPreview!.updatedRamp.toJson()['surfaceInstanceId'],
        'stairs',
      );
      expect(document.current, map);
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-apply')));
      await tester.pump();
      expect(
        document.current.spatialScene!.navigation.ramps.first
            .toJson()['surfaceInstanceId'],
        'stairs',
      );
      expect(
        document.current.spatialScene!.instances,
        map.spatialScene!.instances,
      );
      final linked = document.current;
      tester.widget<StudioSelect>(finder).onChanged!('');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-preview')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-apply')));
      await tester.pump();
      expect(document.current, map);
      document.restore(redo: false);
      expect(document.current, linked);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'French fractional draft previews cancels and applies once without altering other ramps',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final map = precisionRampMap();
      final document = rampDocument(map);
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => SingleChildScrollView(
                child: SpatialRampEditor(
                  document: document,
                  view: view,
                  onChanged: () => refresh(() {}),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.widget<TextField>(input('X')).controller!.text, '2.125');
      expect(
        tester.widget<TextField>(input('Largeur')).controller!.text,
        '3.625',
      );
      await tester.enterText(input('X'), '2,1875');
      await tester.enterText(input('Largeur'), '3,5625');
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-preview')));
      await tester.pump();
      final preview = view.rampPreview!;
      expect(preview.updatedRamp.x, 2.1875);
      expect(preview.updatedRamp.width, 3.5625);
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      expect(button(tester, 'apply').onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-cancel')));
      await tester.pump();
      expect(view.rampPreview, isNull);
      expect(document.current, same(map));
      expect(button(tester, 'apply').onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-preview')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-apply')));
      await tester.pump();
      expect(document.current, preview.result);
      expect(
        document.current.spatialScene!.navigation.ramps.last,
        map.spatialScene!.navigation.ramps.last,
      );
      expect(document.undoCount, 1);
      expect(view.rampPreview, isNull);
      expect(
        find.text('Pente appliquée. Une seule annulation restaure la carte.'),
        findsOneWidget,
      );
      document.restore(redo: false);
      expect(document.current, map);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'guided selection exact fields validation and concurrent changes invalidate previews',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final map = precisionRampMap();
      final document = rampDocument(map);
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      late StateSetter refresh;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                refresh = setter;
                return SingleChildScrollView(
                  child: SpatialRampEditor(
                    document: document,
                    view: view,
                    onChanged: () => refresh(() {}),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.enterText(input('Profondeur'), '2,75');
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-preview')));
      await tester.pump();
      expect(view.rampPreview, isNotNull);
      await tester.enterText(input('X'), 'NaN');
      await tester.pump();
      expect(view.rampPreview, isNull);
      expect(button(tester, 'apply').onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-preview')));
      await tester.pump();
      expect(
        find.text('X doit être un nombre fini, par exemple 1,25.'),
        findsOneWidget,
      );
      expect(document.current, same(map));
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pente 2 · X 9.0, Y 3.0').last);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(input('X')).controller!.text, '9.0');
      expect(
        tester.widget<TextField>(input('Largeur')).controller!.text,
        '2.75',
      );
      expect(
        find.text('X doit être un nombre fini, par exemple 1,25.'),
        findsNothing,
      );
      await tester.enterText(input('Profondeur'), '1,75');
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-preview')));
      await tester.pump();
      expect(view.rampPreview, isNull);
      expect(button(tester, 'apply').onPressed, isNull);
      expect(
        find.text(
          'Les deux extrémités de la pente doivent toucher les sols aux niveaux bas et haut choisis.',
        ),
        findsOneWidget,
      );
      expect(document.current, same(map));
      await tester.enterText(input('Profondeur'), '2,75');
      await tester.tap(find.byKey(const ValueKey('spatial-ramp-preview')));
      await tester.pump();
      final preview = view.rampPreview!;
      view.spatialFreeView = true;
      refresh(() {});
      await tester.pump();
      expect(view.rampPreview, same(preview));
      document.commit(map.copyWith(name: 'Changement concurrent'));
      refresh(() {});
      await tester.pump();
      expect(view.rampPreview, isNull);
      expect(button(tester, 'apply').onPressed, isNull);
      expect(
        tester.widget<TextField>(input('Profondeur')).controller!.text,
        '3.0',
      );
      expect(
        find.text(
          'La carte a changé. Les valeurs affichées ont été actualisées.',
        ),
        findsOneWidget,
      );
      document.saving = true;
      refresh(() {});
      await tester.pump();
      expect(button(tester, 'preview').onPressed, isNull);
      expect(tester.widget<TextField>(input('X')).enabled, isFalse);
      document.saving = false;
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all four native stair footprints load without rounding and direction remains guided',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      for (final footprint in footprints) {
        final document = rampDocument(sourceRampFootprint(footprint));
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: SpatialRampEditor(
                  key: ValueKey(footprint.id),
                  document: document,
                  view: view,
                  onChanged: () {},
                ),
              ),
            ),
          ),
        );
        for (final (label, value) in [
          ('X', footprint.x),
          ('Y', footprint.z),
          ('Largeur', footprint.width),
          ('Profondeur', footprint.depth),
        ]) {
          expect(
            tester.widget<TextField>(input(label)).controller!.text,
            '$value',
          );
        }
        expect(
          tester
              .widget<StudioSelect>(
                find.byKey(const ValueKey('spatial-ramp-high-level')),
              )
              .value,
          '${footprint.highLevel}',
        );
        expect(
          tester
              .widget<StudioSelect>(
                find.byKey(const ValueKey('spatial-ramp-direction')),
              )
              .value,
          footprint.direction.name,
        );
        await tester.tap(find.byKey(const ValueKey('spatial-ramp-preview')));
        await tester.pump();
        expect(view.rampPreview!.hasChanges, isFalse);
        expect(document.undoCount, 0);
        expect(button(tester, 'apply').onPressed, isNull);
      }
      await tester.pumpWidget(const SizedBox());
      expect(view.rampPreview, isNull);
      expect(tester.takeException(), isNull);
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
      final view = MapWorkspaceViewState()
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
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                refresh = setter;
                return SpatialMapEditor(
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
