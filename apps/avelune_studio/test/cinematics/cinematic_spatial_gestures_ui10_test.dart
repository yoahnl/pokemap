import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_preview_transport.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_map_model.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_map_scene.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../support/map_workspace_fixture.dart';
import '../support/ui10_cinematic_fixture.dart';
import '../support/ui07_story_fixture.dart';

void main() {
  for (final tile in [16, 32]) {
    late Ui07StoryFixture fixture;
    late CinematicMapModel model;
    setUp(() async {
      fixture = await createUi10Fixture(tileSize: tile);
      final project = await fixture.readFresh();
      final map = await fixture.maps.loadMap(
        fixture.session,
        project.maps.first,
      );
      model = CinematicMapModel(project.cinematics.single, project, map.map);
    });
    tearDown(() => fixture.dispose());
    testWidgets('map clicks and point drag respect pan zoom resize at $tile px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 600);
      addTearDown(tester.view.resetDevicePixelRatio);
      final view = CinematicViewState()..mode = CinematicMapMode.destination;
      final transport = CinematicPreviewTransport();
      final visuals = WorkspaceTestVisuals();
      final chosen = <Offset>[], moved = <Offset>[];
      final original = model.map.toJson();
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: CinematicMapScene(
              model: model,
              visuals: visuals,
              view: view,
              transport: transport,
              changed: () {},
              beforeSelect: () => true,
              onPoint: chosen.add,
              onPointMove: (_, point) => moved.add(point),
            ),
          ),
        ),
      );
      await tester.pump();
      view.mapTransform.value = Matrix4.identity()
        ..translateByDouble(41, 53, 0, 1)
        ..scaleByDouble(1.8, 1.8, 1, 1);
      await tester.pump();
      final map = find.byKey(const ValueKey('cinematic-map-pick'));
      Offset at(double x, double y) => tester
          .renderObject<RenderBox>(map)
          .localToGlobal(Offset((x + .5) * tile, (y + .5) * tile));
      await tester.tapAt(at(7, 5));
      await tester.pump();
      expect(chosen.single, const Offset(7, 5));
      tester.view.physicalSize = const Size(1000, 700);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pump();
      await tester.pump();
      expect(
        tester.getRect(find.byType(CinematicMapScene)).contains(at(6, 4)),
        isTrue,
        reason:
            'Target ${at(6, 4)} in ${tester.getRect(find.byType(CinematicMapScene))}',
      );
      await tester.tapAt(at(6, 4));
      await tester.pump();
      expect(chosen.last, const Offset(6, 4));
      view.mode = CinematicMapMode.select;
      tester.element(find.byType(CinematicMapScene)).markNeedsBuild();
      await tester.pump();
      final point = model.asset.stageContext!.stagePoints.first;
      final handle = find.byKey(ValueKey('cinematic-point-${point.id}'));
      final drag = await tester.startGesture(tester.getCenter(handle));
      for (var i = 0; i < 10; i++) {
        await drag.moveBy(Offset(2 * tile * 1.8 / 10, 0));
      }
      await tester.pump();
      expect(moved, isEmpty);
      await drag.up(); await tester.pump();
      expect(moved, [Offset(point.x + 2, point.y)]);
      final cancel = await tester.startGesture(tester.getCenter(handle));
      await cancel.moveBy(const Offset(60, 0)); await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await cancel.up(); await tester.pump();
      expect(moved, hasLength(1));
      expect(model.map.toJson(), original);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      view.dispose();
      transport.dispose();
      await visuals.dispose();
    });
  }
}
