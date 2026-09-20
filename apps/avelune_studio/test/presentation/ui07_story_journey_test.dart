import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_inspector.dart';
import 'package:avelune_studio/presentation/features/stories/story_inspector.dart';
import 'package:avelune_studio/presentation/features/stories/story_progression_page.dart';
import 'package:avelune_studio/presentation/features/stories/story_structure_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/capture_m3_widget.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui06_scene_fixture.dart';
import '../support/ui07_journey_driver.dart';
import '../support/ui07_story_fixture.dart';
import '../support/ui07_workspace_harness.dart';

void main() {
  testWidgets(
    'UI07 real workspace preserves drafts and canonical owner through graph structure scene and save',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = (await tester.runAsync(
        () => Ui07WorkspaceHarness.create(tester),
      ))!;
      addTearDown(f.dispose);
      final mapBytes = await tester.runAsync(f.mapBytes);
      await tester.pumpWidget(f.app());
      await pumpIo(tester);
      await openStoryPage(tester);
      final controller = storyPage(tester).controller;
      final view = storyPage(
        tester,
      ).views.forStory(f.maps, Ui07StoryFixture.mainId);
      expect(controller.activeId, Ui07StoryFixture.mainId);
      expect(controller.dirty, false);
      expect(f.ports.storyWrites, 0);
      expect(f.narrative.dialogueReads, 0);
      await captureM3Widget(tester, f.captureKey, '01-histoire-complete');
      final original = controller.active!;
      final map = f.maps.active!;
      map.commit(map.current.copyWith(name: 'Carte gardée en mémoire'));
      final mapDraft = map.current;
      var projection = buildStorylineProgressionProjection(
        project: controller.project,
        storylineId: original.id,
      );
      final relationship = projection
          .edgesOfKind(StorylineProgressionEdgeKind.requires)
          .single;
      await storyEdge(tester, relationship);
      await captureM3Widget(tester, f.captureKey, '03-inspecteur-relation');
      await storyInspectorAction(tester, 'Déconnecter');
      expect(controller.narrative.pendingStories.keys, [
        Ui07StoryFixture.sideId,
      ]);
      expect(controller.active, same(original));
      await tester.tap(find.text('Annuler').first);
      await tester.pumpAndSettle();
      expect(controller.narrative.pendingStories, isEmpty);
      await storyNode(tester, 'step:${Ui07StoryFixture.talkId}');
      final title = find.descendant(
        of: find.byType(StoryInspector),
        matching: find.widgetWithText(TextField, 'Nom'),
      );
      await tester.enterText(title, 'Parler au chef de gare — avant le départ');
      await storyNode(tester, 'step:find_station');
      expect(
        controller.active!.chapters.first.steps.first.title,
        'Trouver la gare',
      );
      expect(
        controller.active!.chapters.first.steps[1].title,
        'Parler au chef de gare — avant le départ',
      );
      await storyNode(tester, 'step:${Ui07StoryFixture.talkId}');
      await storyInspectorAction(tester, 'Modifier la scène');
      expect(find.byType(SceneBuilderPage), findsOneWidget);
      final scenes = tester
          .widget<SceneBuilderPage>(find.byType(SceneBuilderPage))
          .controller;
      final scene = scenes.active!;
      expect(scene.current.id, Ui06SceneFixture.sceneId);
      await tester.drag(
        find.byKey(const ValueKey('scene-graph-node-drag-target-start')),
        const Offset(38, 24),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('scene-graph-node-drag-target-start')),
      );
      await tester.pumpAndSettle();
      final blockTitle = find.descendant(
        of: find.byType(SceneInspector),
        matching: find.widgetWithText(TextField, 'Nom du bloc'),
      );
      await tester.enterText(
        blockTitle,
        'Accueillir le voyageur avant le départ',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        scene.current.graph.nodes.firstWhere((n) => n.id == 'start').title,
        'Accueillir le voyageur avant le départ',
      );
      await tester.tap(find.text('Enregistrer').first);
      await f.settleWrites(tester);
      expect(scene.dirty, false);
      expect(f.ports.sceneWrites, 1);
      final savedScene = (await tester.runAsync(
        f.source.readFresh,
      ))!.scenes.singleWhere((s) => s.id == scene.current.id);
      expect(savedScene, scene.current);
      expect(controller.dirty, true);
      final otherScene = scenes.create('Autre scène conservée')!;
      final otherSceneDraft = otherScene.current;
      scenes.open(scene.current.id);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('scene-graph-node-drag-target-start')),
        const Offset(38, 24),
      );
      await tester.pumpAndSettle();
      expect(scene.dirty, true);
      final sceneDraft = scene.current;
      await captureM3Widget(tester, f.captureKey, '05-scene-modifiee');
      await tester.tap(find.text('Histoires et progression').first);
      await tester.pumpAndSettle();
      expect(find.byType(StoryProgressionPage), findsOneWidget);
      expect(storyPage(tester).views.forStory(f.maps, original.id), same(view));
      expect(view.selection!.id, 'step:${Ui07StoryFixture.talkId}');
      expect(map.current, same(mapDraft));
      expect(scene.current, same(sceneDraft));
      await captureM3Widget(tester, f.captureKey, '05-retour-scene');
      await tester.tap(find.text('Structure').first);
      await tester.pumpAndSettle();
      expect(find.byType(StoryStructureView), findsOneWidget);
      await captureM3Widget(tester, f.captureKey, '04-structure');
      await tester.tap(find.text('Graphe').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cadrer l’histoire'));
      await tester.pumpAndSettle();
      final output = find.byKey(
        const ValueKey('story-graph-output-fact:${Ui07StoryFixture.factId}'),
      );
      final input = find.byKey(
        const ValueKey('story-graph-input-step:${Ui07StoryFixture.waitId}'),
      );
      final gesture = await tester.startGesture(tester.getCenter(output));
      await gesture.moveTo(tester.getCenter(input));
      await tester.pump();
      await captureM3Widget(tester, f.captureKey, '02-connexion-progression');
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Achèvement · vrai'));
      await tester.pumpAndSettle();
      expect(
        controller.active!.chapters.last.steps.last.completionCondition,
        ScriptConditionFactory.flagIsSet(Ui07StoryFixture.factId),
      );
      await tester.tap(find.text('Enregistrer').first);
      await f.settleWrites(tester);
      expect(controller.dirty, false);
      expect(f.ports.storyWrites, 1);
      expect(scene.dirty, true);
      expect(scene.current, same(sceneDraft));
      expect(f.ports.sceneWrites, 1);
      expect(otherScene.current, same(otherSceneDraft));
      expect(otherScene.dirty, true);
      expect(map.current, same(mapDraft));
      expect(map.dirty, true);
      final reopened = (await tester.runAsync(f.source.readFresh))!;
      expect(
        reopened.storylines.singleWhere((s) => s.id == original.id),
        controller.active,
      );
      expect(await tester.runAsync(f.mapBytes), mapBytes);
      for (final size in [const Size(1440, 900), const Size(1280, 800)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      tester.view.physicalSize = const Size(1024, 640);
      await tester.pumpWidget(f.app(textScale: 1.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await captureM3Widget(tester, f.captureKey, '06-compact-texte150');
      await tester.tap(find.text('Bibliothèque').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(scene.current, same(sceneDraft));
      expect(map.current, same(mapDraft));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
