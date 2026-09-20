import 'package:avelune_studio/presentation/features/stories/story_inspector.dart';
import 'package:avelune_studio/presentation/features/stories/story_structure_view.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui06_scene_fixture.dart';
import '../support/ui07_journey_driver.dart';
import '../support/ui07_workspace_harness.dart';

void main() {
  testWidgets(
    'UI07 authors chapters steps scene association and true side relation from empty stories',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = (await tester.runAsync(
        () => Ui07WorkspaceHarness.create(tester, withStories: false),
      ))!;
      addTearDown(f.dispose);
      await tester.pumpWidget(f.app());
      await pumpIo(tester);
      await openStoryPage(tester);
      final controller = storyPage(tester).controller;
      expect(controller.stories, isEmpty);
      await tester.tap(find.text('Nouvelle histoire').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '   ',
      );
      await tester.pump();
      expect(
        tester
            .widget<StudioButton>(find.widgetWithText(StudioButton, 'Créer'))
            .onPressed,
        isNull,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Annuler'),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.stories, isEmpty);
      expect(controller.dirty, false);
      await tester.tap(find.text('Nouvelle histoire').first);
      await tester.pumpAndSettle();
      await storyNameDialog(tester, 'Préparer le départ');
      final mainId = controller.activeId!;
      expect(controller.active!.type, StorylineType.main);
      await tester.tap(find.text('Ajouter un chapitre'));
      await tester.pumpAndSettle();
      await storyNameDialog(tester, 'Arrivée à Hanazuki');
      final firstId = controller.active!.chapters.single.id;
      await tester.tap(find.text('Ajouter un chapitre'));
      await tester.pumpAndSettle();
      await storyNameDialog(tester, 'Préparer le voyage');
      final lastId = controller.active!.chapters.last.id;
      await tester.tap(find.text('Structure'));
      await tester.pumpAndSettle();
      for (final title in [
        'Trouver la gare',
        'Parler au chef de gare',
        'Obtenir le billet',
      ]) {
        await _addStep(tester, 0, title);
      }
      for (final title in [
        'Monter dans le train',
        'Attendre le prochain départ',
      ]) {
        await _addStep(tester, 1, title);
      }
      expect(controller.active!.chapters.map((c) => c.id), [firstId, lastId]);
      expect(controller.active!.chapters.expand((c) => c.steps).length, 5);
      expect(controller.active!.relationships, isEmpty);
      expect(
        buildStorylineProgressionProjection(
          project: controller.project,
          storylineId: mainId,
        ).edgesOfKind(StorylineProgressionEdgeKind.requires),
        isEmpty,
      );
      final structureScroll = find
          .descendant(
            of: find.byType(StoryStructureView),
            matching: find.byType(Scrollable),
          )
          .first;
      final talkRow = find.text('2. Parler au chef de gare');
      await tester.scrollUntilVisible(
        talkRow,
        -180,
        scrollable: structureScroll,
      );
      await tester.tap(talkRow);
      await tester.pumpAndSettle();
      await _select(
        tester,
        'Associer une scène',
        'Rencontre en gare · ${Ui06SceneFixture.sceneId}',
      );
      final talk = controller.active!.chapters.first.steps[1];
      expect(talk.sceneLinkIds, [Ui06SceneFixture.sceneId]);
      await _select(
        tester,
        'Associer un scénario existant',
        'Prêt ou attendre · station_readiness',
      );
      expect(controller.active!.sceneLinks.single.stepId, talk.id);
      expect(controller.active!.sceneLinks.single.expectedOutcomeIds, [
        'ready',
        'wait',
      ]);
      await tester.tap(find.text('Graphe').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cadrer l’histoire'));
      await tester.pumpAndSettle();
      final readyId =
          'outcome:$mainId:${controller.active!.sceneLinks.single.id}:outcome-ready';
      final board = controller.active!.chapters.last.steps.first;
      await _connect(
        tester,
        readyId,
        'step:${board.id}',
        'Activer cette étape',
      );
      expect(
        controller
            .active!
            .sceneLinks
            .single
            .outcomeLinks
            .single
            .effects
            .single
            .type,
        StorylineEffectType.activateStep,
      );
      await tester.tap(find.text('Nouvelle histoire').first);
      await tester.pumpAndSettle();
      final dialogType = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(StudioSelect),
      );
      await tester.tap(dialogType);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Secondaire').last);
      await tester.pumpAndSettle();
      await storyNameDialog(tester, 'Le sac oublié');
      final sideId = controller.activeId!;
      expect(controller.active!.type, StorylineType.sideQuest);
      await tester.tap(find.byTooltip('Afficher une source'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Histoire · Préparer le départ'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cadrer l’histoire'));
      await tester.pumpAndSettle();
      await _connect(
        tester,
        'storyline:$sideId',
        'storyline:$mainId',
        'Nécessite cette histoire',
      );
      final relation = controller.active!.relationships.single;
      expect(relation.sourceStorylineId, sideId);
      expect(relation.targetStorylineId, mainId);
      expect(
        controller.stories.singleWhere((s) => s.id == mainId).relationships,
        isEmpty,
      );
      await tester.tap(find.text('Enregistrer').first);
      await f.settleWrites(tester);
      expect(controller.error, isNull);
      expect(controller.dirty, false);
      expect(f.ports.storyWrites, 2);
      final fresh = (await tester.runAsync(f.source.readFresh))!;
      expect(fresh.storylines, unorderedEquals(controller.stories));
      expect(
        fresh.storylines
            .singleWhere((s) => s.id == sideId)
            .relationships
            .single,
        relation,
      );
      expect(f.ports.sceneWrites, 0);
      expect(f.maps.active!.dirty, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<void> _addStep(WidgetTester tester, int chapter, String title) async {
  final action = find
      .descendant(
        of: find.byType(StoryStructureView),
        matching: find.text('Ajouter une étape'),
      )
      .at(chapter);
  await tester.scrollUntilVisible(
    action,
    180,
    scrollable: find
        .descendant(
          of: find.byType(StoryStructureView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(action);
  await tester.pumpAndSettle();
  await storyNameDialog(tester, title);
}

Future<void> _select(WidgetTester tester, String label, String choice) async {
  final select = find.descendant(
    of: find.byType(StoryInspector),
    matching: find.byWidgetPredicate(
      (w) => w is StudioSelect && w.label == label,
    ),
  );
  await tester.scrollUntilVisible(
    select,
    200,
    scrollable: find
        .descendant(
          of: find.byType(StoryInspector),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(select);
  await tester.pumpAndSettle();
  await tester.tap(find.text(choice).last);
  await tester.pumpAndSettle();
}

Future<void> _connect(
  WidgetTester tester,
  String source,
  String target,
  String choice,
) async {
  final output = find.byKey(ValueKey('story-graph-output-$source'));
  final input = find.byKey(ValueKey('story-graph-input-$target'));
  await tester.dragFrom(
    tester.getCenter(output),
    tester.getCenter(input) - tester.getCenter(output),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(choice));
  await tester.pumpAndSettle();
}
