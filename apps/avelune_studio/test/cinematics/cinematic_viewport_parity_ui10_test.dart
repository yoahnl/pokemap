import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_preview_transport.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_map_model.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_map_scene.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../support/map_workspace_fixture.dart';
import '../support/ui10_cinematic_fixture.dart';
import '../support/ui07_story_fixture.dart';

void main() {
  late Ui07StoryFixture fixture;
  late CinematicMapModel model;
  setUp(() async {
    fixture = await createUi10Fixture();
    final project = await fixture.readFresh();
    final map = await fixture.maps.loadMap(fixture.session, project.maps.first);
    model = CinematicMapModel(project.cinematics.single, project, map.map);
  });
  tearDown(() => fixture.dispose());
  testWidgets(
    'scrub applies camera and fade while stop restores the work view',
    (tester) async {
      final view = CinematicViewState();
      final transport = CinematicPreviewTransport();
      final visuals = WorkspaceTestVisuals();
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: model.asset,
        actorDisplayPreviewModel: model.actors,
        stageBounds: model.bounds,
        resolvedMovementTargets: model.targets,
      );
      transport.install(plan);
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
              onPoint: (_) {},
              onPointMove: (_, _) {},
              beforeSelect: () => true,
            ),
          ),
        ),
      );
      await tester.pump();
      final saved = view.mapTransform.value.clone();
      final camera = plan.timelineItems.firstWhere(
        (s) => s.kind == CinematicTimelineStepKind.camera,
      );
      transport.seek(camera.startMs);
      await tester.pump();
      Matrix4 transform() => tester
          .widget<Transform>(
            find.byKey(const ValueKey('cinematic-runtime-transform')),
          )
          .transform
          .clone();
      final before = transform();
      transport.seek(camera.endMs);
      await tester.pump();
      expect(transform(), isNot(before));
      expect(view.mapTransform.value, saved);
      expect(find.byKey(const ValueKey('cinematic-point-start')), findsNothing);
      final fade = plan.timelineItems.firstWhere(
        (s) => s.kind == CinematicTimelineStepKind.fade,
      );
      transport.seek(fade.endMs);
      await tester.pump();
      expect(
        tester
            .widget<ColoredBox>(
              find.byKey(const ValueKey('cinematic-preview-fade')),
            )
            .color
            .a,
        1,
      );
      transport.stop();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('cinematic-runtime-transform')),
        findsNothing,
      );
      expect(view.mapTransform.value, saved);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      transport.dispose();
      view.dispose();
      await visuals.dispose();
    },
  );
}
