import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
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
  setUp(() => installConvertedQaHeadlessAudio(completePlayback: true));
  final root = Platform.environment['AVELUNE_FOREST_PASSAGE_PROJECT'];
  final receiptPath = Platform.environment['AVELUNE_FOREST_PASSAGE_RECEIPT'];
  const gateMapId =
      'map_7284cbc5900776bfc8d3987fc108540aead1faacaa928e73fc03b9be';
  const forestMapId =
      'map_d4687dfcdb5cefd836b7f185a5aa07a432a50ccad4a1eae4312da318';
  final proofs = <Map<String, Object?>>[];

  for (final northExit in [false, true]) {
    testWidgets(
      northExit
          ? 'source north forest passage preserves its destination and facing'
          : 'source forest entrance and three-cell return survive cold restore',
      (tester) async {
        await tester.runAsync(() async {
          final projectFile = path.join(root!, 'project.json');
          final manifest = await loadProjectManifestFromFile(projectFile);
          expect(manifest.maps, hasLength(383));
          final protected = <String, String>{};
          Future<String> hash(String relative) async => crypto.sha256
              .convert(await File(path.join(root, relative)).readAsBytes())
              .toString();
          for (final relative in [
            'project.json',
            ...manifest.maps.map((map) => map.relativePath),
          ]) {
            protected[relative] = await hash(relative);
          }
          final directory = await Directory.systemTemp.createTemp(
            'forest-passage-save-',
          );
          addTearDown(() => directory.delete(recursive: true));
          final repository = ConvertedQaDiskSave(
            path.join(directory.path, 'game.json'),
          );
          final initial = GameState(
            saveId: northExit ? 'forest-north-passage' : 'forest-round-trip',
            currentMapId: gateMapId,
            playerPosition: northExit
                ? const GridPos(x: 29, y: 12)
                : const GridPos(x: 8, y: 4),
            playerFacing: northExit ? EntityFacing.south : EntityFacing.north,
            trainerProfile: const TrainerProfile(name: 'Forest passage QA'),
          );
          PlayableMapGame? mounted;
          final phases = <String>{};
          final sourceFacts = manifest.facts.where(
            (fact) => fact.description.startsWith('Persistent source '),
          );
          void assertNoSourceProgress(PlayableMapGame game) {
            final state = game.gameStateSnapshot;
            expect(state.party.members, isEmpty);
            expect(state.bag.entries, isEmpty);
            for (final fact in sourceFacts) {
              expect(
                state.narrativeFactRuntimeState.valueFor(fact.id) ??
                    fact.initialValue,
                fact.initialValue,
                reason: fact.description,
              );
            }
          }

          Future<void> walk(
            PlayableMapGame game,
            RuntimeInputControl control,
            String destination,
          ) async {
            expect(
              game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
              isTrue,
            );
            try {
              for (var tick = 0; tick < 8000; tick++) {
                game.update(.025);
                await game.ready();
                await Future<void>.delayed(const Duration(milliseconds: 1));
                for (final overlay
                    in game.camera.viewport.children
                        .whereType<WarpPresentationOverlayComponent>()) {
                  expect(
                    overlay.controller.presentation.mode,
                    SceneWarpPresentationMode.illustrated,
                  );
                  phases.add(overlay.controller.phase.name);
                }
                if (game.gameStateSnapshot.currentMapId == destination) return;
              }
              fail(
                'Forest passage blocked: map=${game.gameStateSnapshot.currentMapId} '
                'position=${game.debugPlayerGridPosition} '
                'phase=${game.debugFlowPhaseName}',
              );
            } finally {
              game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
            }
          }

          try {
            mounted = await mountConvertedQaGame(
              tester,
              projectFile,
              repository,
              initial,
            );
            assertNoSourceProgress(mounted);
            await walk(
              mounted,
              northExit ? RuntimeInputControl.down : RuntimeInputControl.up,
              forestMapId,
            );
            await waitConvertedQaIdle(mounted);
            expect(
              mounted.debugPlayerGridPosition,
              northExit
                  ? const GridPos(x: 10, y: 11)
                  : const GridPos(x: 34, y: 63),
            );
            expect(
              mounted.gameStateSnapshot.playerFacing,
              northExit ? EntityFacing.south : EntityFacing.north,
            );
            expect(phases, isNotEmpty);
            assertNoSourceProgress(mounted);
            if (!northExit) {
              for (final column in [34, 33, 35]) {
                if (column != 34) {
                  await walk(mounted, RuntimeInputControl.up, forestMapId);
                  await waitConvertedQaIdle(mounted);
                  final control = column == 33
                      ? RuntimeInputControl.left
                      : RuntimeInputControl.right;
                  expect(
                    mounted.handleRuntimeInputEvent(
                      RuntimeInputEvent.press(control),
                    ),
                    isTrue,
                  );
                  try {
                    for (var tick = 0; tick < 1000; tick++) {
                      mounted.update(.025);
                      await mounted.ready();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 1),
                      );
                      if (mounted.debugPlayerGridPosition.x == column) break;
                    }
                  } finally {
                    mounted.handleRuntimeInputEvent(
                      RuntimeInputEvent.release(control),
                    );
                  }
                  await waitConvertedQaIdle(mounted);
                  expect(
                    mounted.debugPlayerGridPosition,
                    GridPos(x: column, y: 63),
                  );
                }
                await walk(mounted, RuntimeInputControl.down, gateMapId);
                await waitConvertedQaIdle(mounted);
                expect(
                  mounted.debugPlayerGridPosition,
                  const GridPos(x: 8, y: 4),
                );
                expect(
                  mounted.gameStateSnapshot.playerFacing,
                  EntityFacing.south,
                );
                final tone = mounted.debugWorldToneValue;
                expect([
                  tone.red,
                  tone.green,
                  tone.blue,
                  tone.gray,
                ], everyElement(0));
                assertNoSourceProgress(mounted);
              }
            }
            final savedPosition = mounted.debugPlayerGridPosition;
            final savedFacing = mounted.gameStateSnapshot.playerFacing;
            expect(await mounted.saveGame(), isTrue);
            final saved = (await repository.load())!;
            expect(saved.playerPosition, savedPosition);
            mounted.onRemove();
            mounted = null;
            await tester.pumpWidget(const SizedBox.shrink());
            final reopened = await mountConvertedQaGame(
              tester,
              projectFile,
              repository,
              saved,
              restoredSave: saveDataFromGameState(saved),
            );
            mounted = reopened;
            expect(reopened.debugPlayerGridPosition, savedPosition);
            expect(reopened.gameStateSnapshot.playerFacing, savedFacing);
            expect(
              reopened.gameStateSnapshot.currentMapId,
              northExit ? forestMapId : gateMapId,
            );
            assertNoSourceProgress(reopened);
            for (final entry in protected.entries) {
              expect(await hash(entry.key), entry.value, reason: entry.key);
            }
            proofs.add({
              'sourceEvents': northExit ? ['148/5'] : ['148/2', '149/4'],
              'returnContactColumnsVerified': northExit ? [] : [34, 33, 35],
              'arrival': northExit ? {'x': 10, 'y': 11} : {'x': 34, 'y': 63},
              'savedPosition': savedPosition.toJson(),
              'savedFacing': savedFacing.name,
              'illustratedTransitionPhasesObserved': phases.toList()..sort(),
              'savedAndColdRestored': true,
              'protectedProjectFilesUnchanged': protected.length,
              'qaPositionSeeded': true,
              'qaPartySeeded': false,
              'qaProgressionSeeded': false,
              'continuousCampaignQualified': false,
              'sourcePresentationParityQualified': false,
              'audibleOutputQualified': false,
              'aiCalls': 0,
              'sourceScriptsExecuted': 0,
            });
            if (receiptPath != null) {
              await File(receiptPath).writeAsString(
                jsonEncode({
                  'kind': 'sourceForestPassagePlayerProof',
                  'cases': proofs,
                }),
              );
            }
          } finally {
            mounted?.onRemove();
            await tester.pumpWidget(const SizedBox.shrink());
          }
        });
      },
      skip: root == null,
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
