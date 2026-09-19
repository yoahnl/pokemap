import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction_reader.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/m3_story_fixture.dart';
import 'support/m3_runtime_driver.dart';
import 'support/load_desktop_capture_fonts.dart';
import 'support/capture_m3_widget.dart';

void main() {
  testWidgets(
    'published story plays choices, conditions, one-shot and isolated save/load',
    (tester) async {
      tester.view.physicalSize = const Size(1120, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(loadDesktopCaptureFonts);
      final captureKey = GlobalKey();
      late M3StoryFixture fixture;
      await tester.runAsync(
        () async => fixture = await M3StoryFixture.create(),
      );
      addTearDown(() => fixture.directory.delete(recursive: true));
      expect(
        fixture.receipt.manifest.eventRegistry!.mode,
        EventSystemMode.legacyOnly,
      );
      final saves = StudioPlaytestSession();
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: RepaintBoundary(
            key: captureKey,
            child: Scaffold(
              body: StudioPlaytestView(
                session: fixture.session,
                entry: fixture.receipt.manifest.maps.first,
                expectedRevision: fixture.receipt.revision,
                port: fixture.maps,
                testSession: saves,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      final driver = M3RuntimeDriver(tester);
      final captured = <String>{};
      driver.onPresentation = (snapshot) async {
        final name = snapshot.choices.isNotEmpty
            ? '05-runtime-choix'
            : snapshot.fullText == 'Tout est prêt, départ autorisé !'
            ? '06-runtime-conclusion'
            : null;
        if (name != null && captured.add(name)) {
          await tester.pump(const Duration(seconds: 2));
          await captureM3Widget(tester, captureKey, name);
        }
      };
      await driver.ready();
      final game = driver.game;
      await driver.walk(RuntimeInputControl.right, 2);
      await driver.walk(RuntimeInputControl.down);
      expect(await driver.talk(), contains('Je patiente avant le départ.'));
      expect(game.gameStateSnapshot.progression.completedStepIds, isEmpty);
      await driver.walk(RuntimeInputControl.left, 2);
      await driver.walk(RuntimeInputControl.down);
      expect(
        await driver.talk(choice: 1),
        contains('Revenez quand vous voulez.'),
      );
      expect(game.gameStateSnapshot.progression.completedStepIds, isEmpty);
      await driver.talk();
      expect(game.gameStateSnapshot.progression.completedStepIds, ['prepare']);
      await driver.walk(RuntimeInputControl.right, 2);
      await driver.walk(RuntimeInputControl.down);
      expect(await driver.talk(), contains('Merci, ma place est prête !'));
      expect(game.gameStateSnapshot.progression.completedStepIds, [
        'prepare',
        'help',
      ]);
      await driver.walk(RuntimeInputControl.left, 2);
      await driver.walk(RuntimeInputControl.down);
      expect(await driver.talk(), contains('Tout est prêt, départ autorisé !'));
      expect(game.gameStateSnapshot.progression.completedStepIds, [
        'prepare',
        'help',
        'finish',
      ]);
      final consumed = game
          .gameStateSnapshot
          .narrativeEventProgress
          .consumedNarrativeEventIds;
      expect(consumed.length, 2);
      expect(await driver.talk(), contains('Merci encore pour votre aide.'));
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        consumed,
      );
      await driver.walk(RuntimeInputControl.right, 3);
      expect(await driver.finishTalk(), contains('Bienvenue sur le quai.'));
      await driver.walk(RuntimeInputControl.left);
      await driver.walk(RuntimeInputControl.right);
      expect(game.dialoguePresentationListenable.value, isNull);
      expect(await tester.runAsync(game.saveGame), isTrue);
      expect(saves.hasSave, isTrue);
      bool? resumed;
      await tester.runAsync(() async {
        game.loadGame().then((value) => resumed = value);
      });
      await driver.until(() => resumed != null);
      expect(resumed, isTrue);
      await driver.until(() => !game.debugIsMapActivationDispatchInFlight);
      expect(game.gameStateSnapshot.progression.completedStepIds, [
        'prepare',
        'help',
        'finish',
      ]);
      expect(
        game
            .gameStateSnapshot
            .narrativeEventProgress
            .consumedNarrativeEventIds
            .length,
        3,
      );
      await driver.walk(RuntimeInputControl.left);
      await driver.walk(RuntimeInputControl.right);
      expect(game.dialoguePresentationListenable.value, isNull);
      await tester.tap(find.text('Nouvelle partie'));
      await tester.pump();
      await driver.until(() {
        final finder = find.byType(StudioPlaytestView);
        return finder.evaluate().isNotEmpty && !saves.hasSave;
      });
      await driver.ready(previous: game);
      expect(
        driver.game.gameStateSnapshot.progression.completedStepIds,
        isEmpty,
      );
      expect(saves.hasSave, isFalse);
      expect(await tester.runAsync(driver.game.saveGame), isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(saves.hasSave, isTrue);
      await tester.runAsync(() async {
        final freshMaps = LocalMapWorkspaceAdapter();
        final project = await freshMaps.loadProject(fixture.session);
        final port = LocalNarrativeAdapter(
          session: fixture.session,
          mapAdapter: freshMaps,
        );
        for (final entry in project.dialogues) {
          expect(
            const DialogueDraftCodec().decode(await port.readDialogue(entry)),
            isNotNull,
          );
        }
        for (final record in project.eventRegistry!.records) {
          expect(readStudioInteraction(record, project), isNotNull);
        }
        expect(project.storylines.single.chapters.single.steps.length, 3);
      });
      await saves.delete();
      expect(saves.hasSave, isFalse);
    },
  );
}
