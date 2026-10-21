import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

import 'source_converted_gym_reward_journey_test.dart'
    show
        ConvertedQaDiskSave,
        installConvertedQaHeadlessAudio,
        mountConvertedQaGame,
        waitConvertedQaIdle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(installConvertedQaHeadlessAudio);
  final root = Platform.environment['AVELUNE_HOME_DOOR_PROJECT'];
  final receipt = Platform.environment['AVELUNE_HOME_DOOR_PLAYER_RECEIPT'];
  testWidgets(
    'original home exit and return work without seeded progression',
    (tester) async {
      await tester.runAsync(() async {
        final projectFile = path.join(root!, 'project.json');
        final manifest = await loadProjectManifestFromFile(projectFile);
        final home = manifest.maps.singleWhere((m) => m.name == r"\PN's House");
        final pallet = manifest.maps.singleWhere(
          (m) => m.name == 'Pallet Town',
        );
        final saveRoot = await Directory.systemTemp.createTemp(
          'home-door-save-',
        );
        addTearDown(() => saveRoot.delete(recursive: true));
        final saves = ConvertedQaDiskSave(
          path.join(saveRoot.path, 'save.json'),
        );
        final initial = GameState(
          saveId: 'original-home-door',
          currentMapId: home.id,
          playerPosition: const GridPos(x: 5, y: 10),
          playerFacing: EntityFacing.south,
          trainerProfile: const TrainerProfile(name: 'Door qualification'),
        );
        final game = await mountConvertedQaGame(
          tester,
          projectFile,
          saves,
          initial,
        );
        Future<void> walk(RuntimeInputControl control, String targetMap) async {
          expect(
            game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
            isTrue,
          );
          try {
            for (var tick = 0; tick < 4000; tick++) {
              game.update(.025);
              await game.ready();
              await Future<void>.delayed(const Duration(milliseconds: 1));
              if (game.gameStateSnapshot.currentMapId == targetMap) return;
            }
            fail(
              'Door did not reach $targetMap: ${game.debugFlowPhaseName}, ${game.debugPlayerGridPosition}',
            );
          } finally {
            game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
          }
        }

        void assertNoProgressionSeed(PlayableMapGame value) {
          expect(value.gameStateSnapshot.party.members, isEmpty);
          final starter = manifest.facts.singleWhere(
            (f) => f.description == 'Persistent source integer: source:ev09-real-source-defects:variable:29',
          );
          expect(
            value.gameStateSnapshot.narrativeFactRuntimeState
                    .valueFor(starter.id)
                    ?.intValue ??
                starter.initialValue.intValue,
            0,
          );
        }

        try {
          assertNoProgressionSeed(game);
          await walk(RuntimeInputControl.down, pallet.id);
          await waitConvertedQaIdle(game);
          expect(game.debugPlayerGridPosition, const GridPos(x: 12, y: 8));
          assertNoProgressionSeed(game);
          await walk(RuntimeInputControl.up, home.id);
          await waitConvertedQaIdle(game);
          expect(game.debugPlayerGridPosition, const GridPos(x: 5, y: 10));
          expect(game.gameStateSnapshot.playerFacing, EntityFacing.north);
          assertNoProgressionSeed(game);
          expect(await game.saveGame(), isTrue);
          final saved = (await saves.load())!;
          expect(saved.currentMapId, home.id);
          game.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          final reopened = await mountConvertedQaGame(
            tester,
            projectFile,
            saves,
            saved,
            restoredSave: saveDataFromGameState(saved),
          );
          try {
            expect(
              reopened.debugPlayerGridPosition,
              const GridPos(x: 5, y: 10),
            );
            expect(reopened.gameStateSnapshot.playerFacing, EntityFacing.north);
            assertNoProgressionSeed(reopened);
          } finally {
            reopened.onRemove();
            await tester.pumpWidget(const SizedBox.shrink());
          }
          if (receipt != null) {
            await File(receipt).writeAsString(
              jsonEncode({
                'homeExit': {
                  'sourceMap': 7,
                  'sourceEvent': 1,
                  'targetMap': 6,
                  'arrival': {'x': 12, 'y': 8},
                },
                'homeReturn': {
                  'sourceMap': 6,
                  'sourceEvent': 1,
                  'targetMap': 7,
                  'arrival': {'x': 5, 'y': 10},
                  'facing': 'north',
                },
                'sourceVariable29': 0,
                'partyCount': 0,
                'progressionFlagsSeeded': false,
                'savedAndColdReloaded': true,
                'coldReloadReason': 'saveRestore',
                'scriptsExecuted': 0,
                'aiCalls': 0,
              }),
            );
          }
        } finally {
          game.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });
    },
    skip: root == null,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
