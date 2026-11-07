import 'package:avelune_studio/features/cinematics/data/local_cinematic_adapter.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_workspace_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_action_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui06_scene_fixture.dart';
import '../support/ui07_story_fixture.dart';
import '../support/ui08_event_fixture.dart';
import '../support/ui08_journey_driver.dart';
import '../support/ui08_workspace_harness.dart';
import '../support/ui10_cinematic_fixture.dart';
import '../support/ui10_fixture_visuals.dart';
import '../support/ui10_widget_port.dart';

Future<Ui07StoryFixture> _fixtureKeepingOutcomes() async {
  final fixture = await createUi08Fixture();
  try {
    await seedUi10Visuals(fixture);
    final manifest = await fixture.readFresh();
    final base = await fixture.maps.loadMap(
      fixture.session,
      manifest.maps.first,
    );
    await LocalNarrativeAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
    ).publish(
      NarrativePublication(
        base: base,
        current: base.map,
        expectedScenes: {Ui06SceneFixture.sceneId: manifest.scenes.single},
        expectedCinematics: {ui10CinematicId: manifest.cinematics.single},
        scenes: [Ui06SceneFixture.buildScene(withCinematic: true)],
        cinematics: [ui10Cinematic()],
      ),
    );
    return fixture;
  } catch (_) {
    await fixture.dispose();
    rethrow;
  }
}

void main() {
  testWidgets(
    'UX-23.4 a cinematic opens the scene that plays it at its block and both return to each other',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final workspace = (await tester.runAsync(() async {
        final fixture = await _fixtureKeepingOutcomes();
        final workspace = await Ui08WorkspaceHarness.create(
          tester,
          fixture: fixture,
        );
        final map = await fixture.maps.loadMap(
          fixture.session,
          workspace.maps.project!.maps.first,
        );
        workspace.visuals.setActiveMap(map.map);
        await workspace.visuals.settled;
        return workspace;
      }))!;
      final port = Ui10WidgetPort(
        LocalCinematicAdapter(
          session: workspace.source.session,
          mapAdapter: workspace.source.maps,
        ),
        tester,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(workspace.dispose);
      });
      await tester.pumpWidget(workspace.app(cinematicPort: port));
      await pumpIo(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(StudioPrimaryNavigation),
          matching: find.byTooltip('Histoire'),
        ),
      );
      await pumpIo(tester, frames: 8);
      await tester.tap(
        find.widgetWithText(StudioActionCard, 'Cinématiques sur carte'),
      );
      await pumpIo(tester, frames: 15);
      await tester.tap(
        find.byKey(const ValueKey('cinematic-library-$ui10CinematicId')),
      );
      await pumpIo(tester, frames: 30);
      expect(
        tester
            .widget<CinematicWorkspacePage>(find.byType(CinematicWorkspacePage))
            .controller
            .activeId,
        ui10CinematicId,
      );

      await ui08Tap(tester, 'Scène déclenchante');
      final scene = tester.widget<SceneBuilderPage>(
        find.byType(SceneBuilderPage),
      );
      expect(scene.controller.active!.current.id, Ui06SceneFixture.sceneId);
      expect(
        scene.views.forScene(Ui06SceneFixture.sceneId).nodeId,
        'cinematic',
      );
      expect(scene.onBackLabel, 'Cinématique');

      await ui08Tap(tester, 'Cinématique');
      final cinematic = tester.widget<CinematicWorkspacePage>(
        find.byType(CinematicWorkspacePage),
      );
      expect(cinematic.controller.activeId, ui10CinematicId);

      await ui08Tap(tester, 'Scène déclenchante');
      await ui08Tap(tester, 'Ouvrir la cinématique');
      expect(find.byType(CinematicWorkspacePage), findsOneWidget);
      expect(find.byTooltip('Retour à Histoire'), findsOneWidget);

      await ui08Open(tester);
      await ui08Tap(tester, 'PNJ Chef de gare');
      await ui08Tap(tester, 'Ouvrir la scène');
      final fromEvent = tester.widget<SceneBuilderPage>(
        find.byType(SceneBuilderPage),
      );
      fromEvent.views.forScene(Ui06SceneFixture.sceneId).nodeId = 'cinematic';
      fromEvent.controller.changed();
      await pumpIo(tester);
      await ui08Tap(tester, 'Ouvrir la cinématique');
      await tester.tap(find.byTooltip('Retour à la scène'));
      await pumpIo(tester);
      final back = tester.widget<SceneBuilderPage>(
        find.byType(SceneBuilderPage),
      );
      expect(back.views.forScene(Ui06SceneFixture.sceneId).nodeId, 'cinematic');
      expect(back.onBackLabel, 'Événements');
      expect(back.controller.active!.dirty, isFalse);
      expect(port.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
