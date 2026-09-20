import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_workspace_page.dart';
import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/stories/story_progression_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'support/m2_ui_fixture.dart';
import 'support/ui07_journey_driver.dart';
import 'support/ui07_story_fixture.dart';
import 'support/ui08_journey_driver.dart';
import 'support/ui08_workspace_harness.dart';
import 'support/ui09_dialogue_fixture.dart';

void main() {
  for (final origin in ['events', 'stories']) {
    testWidgets('nested $origin → scene → dialogue returns to exact owner', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = (await tester.runAsync(
        () => Ui08WorkspaceHarness.create(tester),
      ))!;
      final port = WidgetDialoguePort(
        LocalDialogueAdapter(
          session: h.source.session,
          mapAdapter: h.source.maps,
        ),
        tester,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(h.dispose);
      });
      await tester.pumpWidget(h.app(dialoguePort: port));
      await pumpIo(tester);
      String? selectedEvent;
      if (origin == 'events') {
        await ui08Open(tester);
        await ui08Tap(tester, 'PNJ Chef de gare');
        selectedEvent = ui08Page(tester).controller.activeId;
        await ui08Tap(tester, 'Scène');
        await ui08Tap(tester, 'Ouvrir la scène');
      } else {
        await openStoryPage(tester);
        await ui08Tap(tester, 'Préparer le départ');
        await storyNode(tester, 'step:${Ui07StoryFixture.talkId}');
        await storyInspectorAction(tester, 'Modifier la scène');
      }
      final scene = tester.widget<SceneBuilderPage>(
        find.byType(SceneBuilderPage),
      );
      scene.controller.active!.rename('Brouillon scène conservé');
      final before = scene.controller.active!.current;
      final node = before.graph.nodes.firstWhere(
        (n) => n.payload is SceneYarnDialoguePayload,
      );
      scene.views.forScene(before.id).nodeId = node.id;
      scene.controller.changed();
      await pumpIo(tester);
      await ui08Tap(tester, 'Ouvrir le dialogue');
      final dialogue = tester.widget<DialogueWorkspacePage>(
        find.byType(DialogueWorkspacePage),
      );
      expect(
        dialogue.controller.activeId,
        (node.payload as SceneYarnDialoguePayload).dialogueId,
      );
      await ui08Tap(tester, 'Retour à la scène');
      expect(scene.controller.active!.current, before);
      expect(scene.controller.active!.dirty, isTrue);
      await ui08Tap(
        tester,
        origin == 'events' ? 'Événements' : 'Histoires et progression',
      );
      if (origin == 'events') {
        expect(find.byType(EventWorkspacePage), findsOneWidget);
        expect(ui08Page(tester).controller.activeId, selectedEvent);
      } else {
        expect(find.byType(StoryProgressionPage), findsOneWidget);
        expect(storyPage(tester).controller.activeId, Ui07StoryFixture.mainId);
        expect(
          storyPage(
            tester,
          ).views.forStory(h.maps, Ui07StoryFixture.mainId).selection!.id,
          'step:${Ui07StoryFixture.talkId}',
        );
      }
      expect(port.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
