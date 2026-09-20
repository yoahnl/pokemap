import 'package:avelune_studio/presentation/features/stories/story_inspector.dart';
import 'package:avelune_studio/presentation/features/stories/story_library_panel.dart';
import 'package:avelune_studio/presentation/features/stories/story_structure_view.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui07_journey_driver.dart';
import '../support/ui07_story_fixture.dart';
import '../support/ui07_workspace_harness.dart';

void main() {
  testWidgets(
    'UI07 rapid selection commits only original target and removed target remains unavailable',
    (tester) async {
      final f = await _open(tester);
      final controller = storyPage(tester).controller;
      final relationship = buildStorylineProgressionProjection(
        project: controller.project,
        storylineId: Ui07StoryFixture.mainId,
      ).edgesOfKind(StorylineProgressionEdgeKind.requires).single;
      await storyEdge(tester, relationship);
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(
        controller.stories
            .singleWhere((s) => s.id == Ui07StoryFixture.sideId)
            .relationships,
        isEmpty,
      );
      await tester.tap(find.text('Annuler').first);
      await tester.pumpAndSettle();
      expect(controller.dirty, false);
      await storyNode(tester, 'step:find_station');
      final title = find.descendant(
        of: find.byType(StoryInspector),
        matching: find.widgetWithText(TextField, 'Nom'),
      );
      await tester.enterText(title, 'Trouver la gare après la pluie');
      await tester.tap(
        find.byKey(
          const ValueKey('story-graph-node-step:${Ui07StoryFixture.talkId}'),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('story-graph-node-step:obtain_ticket')),
      );
      await tester.pumpAndSettle();
      expect(
        controller.active!.chapters.first.steps.first.title,
        'Trouver la gare après la pluie',
      );
      expect(
        controller.active!.chapters.first.steps[1].title,
        'Parler au chef de gare',
      );
      expect(
        controller.active!.chapters.first.steps[2].title,
        'Obtenir le billet',
      );
      final parentTitle = controller.active!.title;
      controller.apply(
        deleteStorylineStep(
          controller.project,
          storylineId: Ui07StoryFixture.mainId,
          chapterId: Ui07StoryFixture.arrivalId,
          stepId: 'obtain_ticket',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sélection indisponible'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StoryInspector),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      expect(controller.active!.title, parentTitle);
      expect(controller.error, isNull);
      expect(f.ports.storyWrites, 0);
      expect(f.maps.active!.dirty, false);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'UI07 homonym story IDs and filtering retain the exact active dirty document',
    (tester) async {
      final f = await _open(tester);
      final controller = storyPage(tester).controller;
      await tester.tap(find.text('Nouvelle histoire').first);
      await tester.pumpAndSettle();
      await storyNameDialog(tester, 'Préparer le départ');
      final createdId = controller.activeId!;
      expect(createdId, isNot(Ui07StoryFixture.mainId));
      final original = controller.stories.singleWhere(
        (s) => s.id == Ui07StoryFixture.mainId,
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(StoryInspector),
          matching: find.widgetWithText(TextField, 'Nom'),
        ),
        'Préparer le départ — autre histoire',
      );
      await tester.tap(
        find.byKey(const ValueKey('story-library-${Ui07StoryFixture.mainId}')),
      );
      await tester.pumpAndSettle();
      expect(controller.activeId, Ui07StoryFixture.mainId);
      expect(controller.active, same(original));
      expect(
        controller.stories.singleWhere((s) => s.id == createdId).title,
        'Préparer le départ — autre histoire',
      );
      await tester.tap(find.byKey(ValueKey('story-library-$createdId')));
      await tester.pumpAndSettle();
      final created = controller.active!;
      await tester.enterText(
        find.descendant(
          of: find.byType(StoryLibraryPanel),
          matching: find.byType(TextField),
        ),
        'Le sac',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('story-library-$createdId')), findsNothing);
      expect(controller.active, same(created));
      expect(
        find.text(
          'L’histoire ouverte est hors filtre. Son brouillon reste ouvert.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Histoire').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Histoires et progression').first);
      await tester.pumpAndSettle();
      expect(storyPage(tester).controller.active, same(created));
      expect(storyPage(tester).views.search.text, 'Le sac');
      expect(f.ports.storyWrites, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'UI07 coherence reveals the actual missing reference from structure without publishing',
    (tester) async {
      final f = await _open(tester);
      final controller = storyPage(tester).controller;
      final board = controller.active!.chapters.last.steps.first;
      controller.apply(
        updateStorylineStep(
          controller.project,
          storylineId: Ui07StoryFixture.mainId,
          chapterId: Ui07StoryFixture.journeyId,
          stepId: board.id,
          step: board.copyWith(
            entryCondition: ScriptConditionFactory.flagIsSet('fact_absent'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final projection = buildStorylineProgressionProjection(
        project: controller.project,
        storylineId: Ui07StoryFixture.mainId,
      );
      expect(projection.diagnostics, isNotEmpty);
      final unchanged = controller.active;
      await tester.tap(find.text('Structure'));
      await tester.pumpAndSettle();
      expect(find.byType(StoryStructureView), findsOneWidget);
      await tester.tap(find.text('Vérifier la cohérence'));
      await tester.pumpAndSettle();
      final reveal = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(StudioButton, 'Retrouver dans le graphe'),
      );
      final enabled = reveal
          .evaluate()
          .where((e) => (e.widget as StudioButton).onPressed != null)
          .first;
      await tester.tap(find.byWidget(enabled.widget));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(StoryStructureView), findsNothing);
      final view = storyPage(
        tester,
      ).views.forStory(f.maps, Ui07StoryFixture.mainId);
      expect(view.selection, isNotNull);
      expect(
        projection.nodes.any((n) => n.id == view.selection!.id) ||
            projection.edges.any((e) => e.id == view.selection!.id),
        true,
      );
      expect(controller.active, same(unchanged));
      expect(f.ports.storyWrites, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'UI07 save button persists focused text without another selection',
    (tester) async {
      final f = await _open(tester);
      final controller = storyPage(tester).controller;
      final title = find.descendant(
        of: find.byType(StoryInspector),
        matching: find.widgetWithText(TextField, 'Nom'),
      );
      await tester.enterText(title, 'Préparer le départ après la pluie');
      await tester.tap(find.text('Enregistrer').first);
      await f.settleWrites(tester);
      expect(controller.active!.title, 'Préparer le départ après la pluie');
      expect(controller.error, isNull);
      expect(controller.dirty, false);
      final fresh = (await tester.runAsync(f.source.readFresh))!;
      expect(
        fresh.storylines
            .singleWhere((s) => s.id == Ui07StoryFixture.mainId)
            .title,
        'Préparer le départ après la pluie',
      );
      expect(f.ports.storyWrites, 1);
      expect(f.ports.sceneWrites, 0);
      expect(f.maps.active!.dirty, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<Ui07WorkspaceHarness> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final f = (await tester.runAsync(() => Ui07WorkspaceHarness.create(tester)))!;
  addTearDown(f.dispose);
  await tester.pumpWidget(f.app());
  await pumpIo(tester);
  await openStoryPage(tester);
  return f;
}
