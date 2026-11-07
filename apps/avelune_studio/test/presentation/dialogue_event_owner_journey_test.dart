import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_workspace_page.dart';
import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui06_scene_fixture.dart';
import '../support/ui08_journey_driver.dart';
import '../support/ui08_workspace_harness.dart';
import '../support/ui09_dialogue_fixture.dart';

void main() {
  Future<Ui08WorkspaceHarness> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1584, 994);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final f = (await tester.runAsync(
      () => Ui08WorkspaceHarness.create(tester),
    ))!;
    final dialogues = WidgetDialoguePort(
      LocalDialogueAdapter(session: f.source.session, mapAdapter: f.source.maps),
      tester,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(f.dispose);
    });
    await tester.pumpWidget(f.app(dialoguePort: dialogues));
    await pumpIo(tester);
    return f;
  }

  Future<void> selectChief(WidgetTester tester, Ui08WorkspaceHarness f) async {
    tester
        .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
        .view!
        .select(f.maps.active!, MapSelectionFamily.character, 'chief');
    f.maps.notify();
    await pumpIo(tester);
  }

  String? selectedCharacter(WidgetTester tester, Ui08WorkspaceHarness f) =>
      tester
          .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
          .view
          ?.selectedFor(f.maps.active!.current.id, MapSelectionFamily.character);

  testWidgets(
    'UX-23.1 a selected character opens the scene its interaction plays and comes back to it',
    (tester) async {
      final f = await open(tester);
      final mapId = f.maps.active!.current.id;
      await selectChief(tester, f);
      await ui08Tap(tester, 'Ouvrir sa scène');
      final page = tester.widget<SceneBuilderPage>(
        find.byType(SceneBuilderPage),
      );
      expect(page.controller.active!.current.id, Ui06SceneFixture.sceneId);
      expect(page.views.forScene(Ui06SceneFixture.sceneId).nodeId, 'start');
      expect(page.onBackLabel, 'Carte');
      await ui08Tap(tester, 'Carte');
      expect(find.byType(SceneBuilderPage), findsNothing);
      expect(f.maps.active!.current.id, mapId);
      expect(selectedCharacter(tester, f), 'chief');
      expect(f.events.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'UX-23.2 an event opens its scene dialogue without copying it and returns to the event',
    (tester) async {
      await open(tester);
      await ui08Open(tester);
      await ui08Tap(tester, 'PNJ Chef de gare');
      final event = ui08Page(tester).controller.activeId;
      final dialoguesBefore = ui08Page(tester).controller.project.dialogues
          .map((entry) => entry.id)
          .toList();
      expect(find.text('Dialogues joués par la scène'), findsOneWidget);
      final welcome = Ui06SceneFixture.names['station_welcome']!;
      await ui08Tap(tester, 'Ouvrir le dialogue $welcome · Start');
      final dialogue = tester.widget<DialogueWorkspacePage>(
        find.byType(DialogueWorkspacePage),
      );
      expect(dialogue.controller.activeId, 'station_welcome');
      expect(dialogue.backLabel, 'Événements');
      expect(
        dialogue.controller.project.dialogues.map((entry) => entry.id),
        dialoguesBefore,
      );
      await ui08Tap(tester, 'Retour à Événements');
      expect(find.byType(EventWorkspacePage), findsOneWidget);
      expect(ui08Page(tester).controller.activeId, event);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'UX-23.2 a branch reaches its outcome, then the journey returns to the event and the map',
    (tester) async {
      final f = await open(tester);
      final mapId = f.maps.active!.current.id;
      await selectChief(tester, f);
      await ui08Tap(tester, 'Écrire son interaction');
      await ui08Tap(tester, 'PNJ Chef de gare');
      expect(find.byType(EventWorkspacePage), findsOneWidget);
      final event = ui08Page(tester).controller.activeId;
      await ui08Tap(tester, 'Ouvrir la scène');
      final page = tester.widget<SceneBuilderPage>(
        find.byType(SceneBuilderPage),
      );
      final scene = page.controller.active!.current;
      final view = page.views.forScene(scene.id);
      String? walk(String branch) {
        view.choices.clear();
        for (var step = 0; step < 12; step++) {
          view.calculate(scene);
          final result = view.preview!;
          final awaiting = result.awaitingNodeId;
          if (result.status != SceneDryRunPreviewStatus.awaitingInput ||
              awaiting == null) {
            return result.sceneOutcomeId;
          }
          view.choices[awaiting] = awaiting == 'pass'
              ? branch
              : result.acceptedOutputPortIds.first;
        }
        return null;
      }

      expect(walk('false'), 'attente');
      expect(view.previewError, isNull);
      expect(walk('true'), 'embarquement');
      expect(page.onBackLabel, 'Événements');
      await ui08Tap(tester, 'Événements');
      expect(ui08Page(tester).controller.activeId, event);
      await ui08Tap(tester, 'Retour');
      expect(find.byType(EventWorkspacePage), findsNothing);
      expect(f.maps.active!.current.id, mapId);
      expect(selectedCharacter(tester, f), 'chief');
      expect(page.controller.active!.dirty, isFalse);
      expect(f.events.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
