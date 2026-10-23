import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

import 'source_converted_gym_reward_journey_test.dart'
    show installConvertedQaHeadlessAudio;
import 'source_converted_intro_journey_test.dart'
    show
        ConvertedSourceIntroDiskSave,
        ConvertedSourceIntroMounted,
        mountConvertedSourceIntroGame;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => installConvertedQaHeadlessAudio(completePlayback: true));
  final root = Platform.environment['AVELUNE_FIRST_BADGE_COLD_PROJECT'];
  final savePath = Platform.environment['AVELUNE_FIRST_BADGE_COLD_SAVE'];
  final saveSha = Platform.environment['AVELUNE_FIRST_BADGE_COLD_SHA256'];
  final originPath =
      Platform.environment['AVELUNE_FIRST_BADGE_COLD_ORIGIN_RECEIPT'];
  final originSha =
      Platform.environment['AVELUNE_FIRST_BADGE_COLD_ORIGIN_SHA256'];
  final diagnosticResume =
      Platform.environment['AVELUNE_FIRST_BADGE_COLD_DIAGNOSTIC_RESUME'] == '1';
  final output = Platform.environment['AVELUNE_FIRST_BADGE_COLD_RECEIPT'];
  testWidgets(
    'a second native process restores the genuine first badge and repeats Brock without reward',
    (tester) async {
      await tester.runAsync(() async {
        expect(saveSha, matches(RegExp(r'^[a-f0-9]{64}$')));
        final bytes = await File(savePath!).readAsBytes();
        expect(crypto.sha256.convert(bytes).toString(), saveSha);
        expect(originSha, matches(RegExp(r'^[a-f0-9]{64}$')));
        final originBytes = await File(originPath!).readAsBytes();
        expect(crypto.sha256.convert(originBytes).toString(), originSha);
        final origin = jsonDecode(utf8.decode(originBytes)) as Map;
        expect(origin['journeyComplete'], isTrue);
        expect(origin['firstBadgeJourneyQualified'], isTrue);
        if (!diagnosticResume) {
          expect(origin['newGameToFirstBadgeQualified'], isTrue);
        }
        final originPid = origin['runtimeProcessId'];
        expect(originPid, isA<int>());
        expect(originPid, isNot(pid));
        final retained = (origin['retainedSaves'] as Map)['first-badge'] as Map;
        expect(retained['path'], savePath);
        expect(retained['sha256'], saveSha);
        final expected = (await ConvertedSourceIntroDiskSave(savePath).load())!;
        final projectFile = path.join(root!, 'project.json');
        final manifest = await loadProjectManifestFromFile(projectFile);
        expect(manifest.maps, hasLength(383));
        final before = await _projectHashes(root, manifest);
        final gym = manifest.maps.singleWhere(
          (map) => map.id == expected.currentMapId,
        );
        expect(gym.name, 'Pewter Gym');
        final authored = MapData.fromJson(
          jsonDecode(
            await File(path.join(root, gym.relativePath)).readAsString(),
          ) as Map<String, dynamic>,
        );
        final brock = authored.entities.singleWhere(
          (entity) => entity.name == 'Gym Leader Brock',
        );
        expect(expected.trainerProfile.badgeIds, hasLength(1));
        final evidence = origin['firstBadgeEvidence'] as Map;
        expect(expected.trainerProfile.badgeIds, [evidence['badgeId']]);
        expect(
          expected.storyFlags.activeFlags,
          contains('trainer_defeated:${evidence['trainerId']}'),
        );
        expect(
          const BagOperations().quantityOf(
            expected.bag,
            evidence['itemId'] as String,
          ),
          greaterThanOrEqualTo(1),
        );
        final directory = await Directory.systemTemp.createTemp(
          'first-badge-cold-process-',
        );
        final repository = ConvertedSourceIntroDiskSave(
          path.join(directory.path, 'game.json'),
        );
        ConvertedSourceIntroMounted? mounted;
        final watch = Stopwatch()..start();
        var presentations = 0, battleObserved = false;
        Map<String, Object?>? successfulResult;
        final lines = <String>[];
        try {
          mounted = await mountConvertedSourceIntroGame(
            tester,
            projectFile,
            manifest,
            repository,
            expected,
            restored: saveDataFromGameState(expected),
            loadActualPlayerServiceCaps: true,
          );
          final game = mounted.game;
          final controller = mounted.controller;
          void expectPersisted() {
            final actual = game.gameStateSnapshot;
            expect(actual.currentMapId, expected.currentMapId);
            expect(actual.playerPosition, expected.playerPosition);
            expect(actual.playerFacing, expected.playerFacing);
            expect(actual.party, expected.party);
            expect(actual.bag, expected.bag);
            expect(actual.trainerProfile, expected.trainerProfile);
            expect(
              actual.narrativeFactRuntimeState,
              expected.narrativeFactRuntimeState,
            );
            expect(
              actual.completedBattleRequestIds,
              expected.completedBattleRequestIds,
            );
            expect(actual.storyFlags, expected.storyFlags);
            expect(
              actual.progression.copyWith(storyFlags: []),
              expected.progression.copyWith(storyFlags: []),
            );
            expect(actual.progression.storyFlags.toSet(), {
              ...expected.progression.storyFlags,
              ...expected.storyFlags.activeFlags,
            });
            expect(
              PlayerRecoveryPoint.tryRead(actual),
              PlayerRecoveryPoint.tryRead(expected),
            );
          }

          expectPersisted();
          expect(
            game.gameStateSnapshot.mapInstanceWorldState,
            expected.mapInstanceWorldState,
          );
          void press() {
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            );
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.release(RuntimeInputControl.primary),
            );
          }

          bool idle() =>
              game.debugFlowPhaseName == 'overworld' &&
              game.debugCompletedMapActivationDispatchCount > 0 &&
              !game.debugIsEntityAutorunInFlight &&
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugIsNarrativeSpatialDispatchInFlight &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsLoadActivationWorkInFlight &&
              !game.debugHasPendingDialogueLoad &&
              !game.debugHasPendingMapTransition &&
              !game.debugIsPlayerStepping &&
              game.debugCinematicDialogueLine == null &&
              game.dialoguePresentationListenable.value == null &&
              controller.worldServiceSnapshot == null;
          Future<void> tick() async {
            game.update(.025);
            await game.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
            battleObserved |=
                game.debugBattleSessionSnapshot != null ||
                game.debugFlowPhaseName == 'battle';
            if (game.debugCinematicDialogueLine case final line?) {
              presentations++;
              lines.add(line);
              press();
            }
            if (game.dialoguePresentationListenable.value
                case final dialogue?) {
              presentations++;
              lines.add(dialogue.fullText);
              press();
            }
            final modal = controller.worldServiceSnapshot;
            if (modal?.content
                case final SceneMessageInteractionRequest request) {
              presentations++;
              final result = await controller.dispatchWorldService(
                RuntimeWorldServiceCommand(
                  action: RuntimeWorldServiceAction.confirm,
                  snapshotRevision: modal!.revision,
                  interactionResult: SceneInteractionResult.acknowledged(
                    requestId: request.requestId,
                    revision: request.revision,
                  ),
                ),
              );
              expect(result.status, RuntimeWorldServiceCommandStatus.accepted);
            } else {
              expect(modal, isNull);
            }
          }

          Future<void> until(bool Function() condition) async {
            var stable = 0;
            for (var frame = 0; frame < 6000; frame++) {
              await tick();
              stable = condition() ? stable + 1 : 0;
              if (stable >= 8) return;
            }
            fail('Second-process badge restore or repeat did not become idle.');
          }

          await until(idle);
          expectPersisted();
          expect(presentations, 0);
          expect(
            game.overworldInteractionSnapshot.primaryAction?.request.targetId,
            brock.id,
          );
          press();
          await until(() => idle() && presentations > 0);
          expectPersisted();
          expect(battleObserved, isFalse);
          expect(await _projectHashes(root, manifest), before);
          expect(
            crypto.sha256
                .convert(await File(savePath).readAsBytes())
                .toString(),
            saveSha,
          );
          successfulResult = {
            'kind': 'genuineFirstBadgeSecondNativeProcess',
            'projectPath': root,
            'originReceipt': {'path': originPath, 'sha256': originSha},
            'newGameToFirstBadgeColdProcessQualified':
                origin['newGameToFirstBadgeQualified'] == true,
            'diagnosticResumeAllowed': diagnosticResume,
            'originRuntimeProcessId': originPid,
            'runtimeProcessId': pid,
            'inputSave': {'path': savePath, 'sha256': saveSha},
            'elapsedMs': watch.elapsedMilliseconds,
            'secondOsProcessQualified': true,
            'persistedStateQualified': true,
            'brockRepeatObserved': true,
            'dialoguePresentations': presentations,
            'dialogueLines': lines,
            'newBattleObserved': false,
            'repeatRewardsUnchanged': true,
            'projectManifestAnd383MapsUnchanged': true,
            'qaFlagsSeeded': false,
            'qaPartySeeded': false,
            'qaPositionSeeded': false,
          };
        } finally {
          if (mounted != null) await mounted.close(tester);
          await directory.delete(recursive: true);
        }
        expect(successfulResult, isNotNull);
        successfulResult['playerClosed'] = true;
        await File(output!)
            .writeAsString(jsonEncode(successfulResult), flush: true);
      });
    },
    skip:
        root == null ||
        savePath == null ||
        originPath == null ||
        output == null,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<Map<String, String>> _projectHashes(
  String root,
  ProjectManifest manifest,
) async => {
  for (final relative in [
    'project.json',
    ...manifest.maps.map((map) => map.relativePath),
  ])
    relative: crypto.sha256
        .convert(await File(path.join(root, relative)).readAsBytes())
        .toString(),
};
