import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/m3_runtime_driver.dart';
import 'support/ui06_scene_fixture.dart';

void main() {
  for (final passObtained in [false, true]) {
    test(
      'real scene executor commits the $passObtained branch after reopen',
      () async {
        final fixture = await Ui06SceneFixture.create(
          passObtained: passObtained,
        );
        addTearDown(fixture.dispose);
        final project = await LocalMapWorkspaceAdapter().loadProject(
          fixture.session,
        );
        expect(project.scenes.single.toJson(), fixture.scene.toJson());
        const state = GameState(saveId: 'ui06_scene_executor');
        final visitedDialogues = <String>[];
        var currentState = state;
        final writer = SceneConsequenceRuntimeWriter(project: project);
        final result = await SceneRuntimeExecutor(
          callbacks: SceneRuntimeExecutionCallbacks(
            applyConsequence: (consequence) {
              final written = writer.applyOne(currentState, consequence);
              expect(written.success, isTrue);
              currentState = written.gameState;
              return 'completed';
            },
            evaluateCondition: (intent) =>
                evaluateCanonicalNarrativeFactSceneCondition(
                  source: intent.conditionSource!,
                  gameState: state,
                  resolver: NarrativeFactRuntimeResolver.fromFacts(
                    project.facts,
                  ),
                )
                ? 'true'
                : 'false',
            showDialogue: (intent) {
              expect(
                project.dialogues.any((entry) => entry.id == intent.dialogueId),
                isTrue,
              );
              visitedDialogues.add(intent.dialogueId!);
              return 'completed';
            },
            startBattle: (_) => throw StateError('Unexpected battle'),
            playCinematic: (_) => throw StateError('Unexpected cinematic'),
          ),
        ).execute(buildSceneRuntimePlan(project.scenes.single).plan!);
        expect(result.status, SceneRuntimeExecutionStatus.completed);
        expect(visitedDialogues, [
          'station_welcome',
          passObtained ? 'station_agreement' : 'station_refusal',
        ]);
        expect(
          result.sceneOutcomeId,
          passObtained ? 'embarquement' : 'attente',
        );
        expect(
          currentState
              .narrativeFactRuntimeState
              .overridesByFactId[Ui06SceneFixture.departureFactId],
          passObtained ? true : null,
        );
        expect(state.narrativeFactRuntimeState.overridesByFactId, isEmpty);
      },
    );

    testWidgets(
      'real runtime plays Yarn and ${passObtained ? 'cinematic agreement' : 'refusal'}',
      (tester) async {
        tester.view.physicalSize = const Size(1120, 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        late Ui06SceneFixture fixture;
        await tester.runAsync(() async {
          fixture = await Ui06SceneFixture.create(
            passObtained: passObtained,
            withCinematic: passObtained,
          );
        });
        addTearDown(() => tester.runAsync(fixture.dispose));
        final saves = StudioPlaytestSession();
        addTearDown(saves.delete);
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: StudioPlaytestView(
                session: fixture.session,
                entry: fixture.manifest.maps.first,
                expectedRevision: fixture.receipt.revision,
                port: fixture.maps,
                testSession: saves,
                onClose: () {},
              ),
            ),
          ),
        );
        final driver = M3RuntimeDriver(tester);
        await driver.until(() {
          final finder = find.byType(GameWidget<PlayableMapGame>);
          if (finder.evaluate().isEmpty) return false;
          driver.game = tester
              .widget<GameWidget<PlayableMapGame>>(finder)
              .game!;
          return driver.game.isLoaded &&
              driver.game.dialoguePresentationListenable.value != null;
        });
        final lines = <String>{};
        await driver.until(() {
          final snapshot = driver.game.dialoguePresentationListenable.value;
          if (snapshot != null) {
            if (snapshot.fullText.isNotEmpty) lines.add(snapshot.fullText);
            driver.press(RuntimeInputControl.primary);
          }
          return lines.length >= 2 &&
              !driver.game.debugIsMapActivationDispatchInFlight &&
              !driver.game.debugIsNarrativeOutcomeWorkInFlight &&
              driver.game.debugFlowPhaseName == 'overworld';
        });
        expect(lines, {
          Ui06SceneFixture.lines['station_welcome']!,
          Ui06SceneFixture.lines[passObtained
              ? 'station_agreement'
              : 'station_refusal']!,
        });
        expect(
          driver
              .game
              .gameStateSnapshot
              .narrativeFactRuntimeState
              .overridesByFactId[Ui06SceneFixture.departureFactId],
          passObtained ? true : null,
        );
        expect(
          driver
              .game
              .gameStateSnapshot
              .narrativeEventProgress
              .consumedNarrativeEventIds,
          contains(Ui06SceneFixture.eventId),
        );
        expect(await tester.runAsync(driver.game.saveGame), isTrue);
        expect(saves.hasSave, isTrue);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
