import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_menu_model.dart'
    show BattleCommandRootAction;
import 'package:path/path.dart' as path;

import 'source_converted_gym_reward_journey_test.dart'
    show installConvertedQaHeadlessAudio;
import 'source_converted_intro_journey_test.dart'
    show
        createConvertedSourceFreshGame,
        mountConvertedSourceIntroGame,
        ConvertedSourceIntroMounted,
        ConvertedSourceIntroDiskSave;

void main() => registerConvertedSourceCampaignJourney();

void registerConvertedSourceCampaignJourney({bool firstBadgeJourney = false}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => installConvertedQaHeadlessAudio(completePlayback: true));
  final root = Platform.environment['AVELUNE_CAMPAIGN_PREFIX_PROJECT'];
  final output = Platform.environment['AVELUNE_CAMPAIGN_PREFIX_RECEIPT'];
  final resumePath =
      Platform.environment['AVELUNE_CAMPAIGN_PREFIX_RESUME_SAVE'];
  final resumeSha =
      Platform.environment['AVELUNE_CAMPAIGN_PREFIX_RESUME_SHA256'];
  final stopAfterRival =
      Platform.environment['AVELUNE_CAMPAIGN_PREFIX_STOP_AFTER'] == 'rival';
  final stopAfterParcel =
      Platform.environment['AVELUNE_CAMPAIGN_PREFIX_STOP_AFTER'] == 'parcel';
  final stopAfterPewter =
      Platform.environment['AVELUNE_CAMPAIGN_PREFIX_STOP_AFTER'] == 'pewter';
  final stopAfterBadge =
      Platform.environment['AVELUNE_CAMPAIGN_PREFIX_STOP_AFTER'] == 'badge';
  final stopAfterTraining =
      Platform.environment['AVELUNE_CAMPAIGN_PREFIX_STOP_AFTER'] == 'training';
  final stopAfterPreforest =
      Platform.environment['AVELUNE_CAMPAIGN_PREFIX_STOP_AFTER'] == 'preforest';
  final reachFirstBadge =
      firstBadgeJourney ||
      stopAfterPewter ||
      stopAfterBadge ||
      stopAfterTraining ||
      stopAfterPreforest;
  final continueToParcel =
      reachFirstBadge ||
      stopAfterRival ||
      stopAfterParcel ||
      Platform.environment['AVELUNE_CAMPAIGN_PREFIX_CONTINUE_PARCEL'] == '1';
  final requestedStop =
      Platform.environment['AVELUNE_CAMPAIGN_PREFIX_STOP_AFTER'];
  final prepareBeforeForest =
      reachFirstBadge && (resumePath == null || stopAfterPreforest);
  final trainBeforeBrock = reachFirstBadge && resumePath == null;
  final trainingVictoryLimit = int.parse(
    Platform.environment['AVELUNE_CAMPAIGN_PREFIX_TRAINING_MAX_VICTORIES'] ??
        (trainBeforeBrock ? '10' : '8'),
  );
  if (trainingVictoryLimit < 1 || trainingVictoryLimit > 10) {
    throw StateError('Natural training allows one to ten victories per phase.');
  }
  if (requestedStop != null &&
      !{
        'rival',
        'parcel',
        'pewter',
        'badge',
        'training',
        'preforest',
      }.contains(requestedStop)) {
    throw StateError('Unsupported genuine campaign frontier: $requestedStop');
  }
  if (resumePath != null &&
      (resumeSha == null || !RegExp(r'^[a-f0-9]{64}$').hasMatch(resumeSha))) {
    throw StateError('A resumed natural save requires its exact SHA-256.');
  }
  testWidgets(
    stopAfterRival
        ? 'genuine saved source campaign completes its first rival'
        : stopAfterParcel
        ? 'genuine saved source campaign delivers the parcel'
        : stopAfterPewter
        ? 'genuine saved source campaign walks through Viridian Forest to Pewter'
        : stopAfterPreforest
        ? 'genuine source campaign prepares on Route 1 before Viridian Forest'
        : stopAfterTraining
        ? 'genuine source campaign trains through bounded natural wild encounters'
        : reachFirstBadge
        ? 'genuine source campaign reaches its first native badge'
        : continueToParcel
        ? 'genuine new game completes the source rival and parcel journey with cold saves'
        : 'genuine new game walks from Intro to its source laboratory starter',
    (tester) async {
      await tester.runAsync(() async {
        final projectFile = path.join(root!, 'project.json');
        final manifest = await loadProjectManifestFromFile(projectFile);
        expect(manifest.maps, hasLength(383));
        Future<Map<String, String>> protectedProjectHashes() async => {
          for (final relative in [
            'project.json',
            for (final map in manifest.maps) map.relativePath,
          ])
            relative: crypto.sha256
                .convert(await File(path.join(root, relative)).readAsBytes())
                .toString(),
        };
        final beforeProjectHashes = await protectedProjectHashes();
        final intro = manifest.maps.singleWhere((m) => m.name == 'Intro');
        final home = manifest.maps.singleWhere(
          (m) => m.name.endsWith("PN's House"),
        );
        final pallet = manifest.maps.singleWhere(
          (m) => m.name == 'Pallet Town',
        );
        final lab = manifest.maps.singleWhere((m) => m.name == "Oak's Lab");
        final routeOne = manifest.maps.singleWhere(
          (map) => map.name == 'Route 1',
        );
        final initial = resumePath == null
            ? await createConvertedSourceFreshGame(projectFile, 'preset')
            : null;
        final expectedRecovery = PlayerRecoveryPoint(
          mapId: home.id,
          position: const GridPos(x: 9, y: 7),
          facing: EntityFacing.north,
        );
        final recoveredFact = manifest.facts.singleWhere(
          (fact) => fact.id == manifest.defeatRecovery!.recoveredFactId,
        );
        NarrativeValue recoveryMarker(GameState state) =>
            state.narrativeFactRuntimeState.valueFor(recoveredFact.id) ??
            recoveredFact.initialValue;
        if (initial != null) {
          expect(PlayerRecoveryPoint.tryRead(initial), expectedRecovery);
          expect(recoveryMarker(initial), const NarrativeValue.boolean(false));
          expect(initial.currentMapId, intro.id);
          expect(initial.party.members, isEmpty);
        }
        GameState? resumed;
        if (resumePath != null) {
          final bytes = await File(resumePath).readAsBytes();
          expect(crypto.sha256.convert(bytes).toString(), resumeSha);
          resumed = await ConvertedSourceIntroDiskSave(resumePath).load();
          expect(resumed, isNotNull);
          expect(
            manifest.maps.map((map) => map.id),
            contains(resumed!.currentMapId),
          );
          expect(resumed.party.members.single.speciesId, 'bulbasaur');
          expect(resumed.party.members.single.level, greaterThanOrEqualTo(5));
          expect(
            resumed.party.members.single.provenance!.kind,
            PlayerPokemonOriginKind.gift,
          );
        }
        expect(manifest.newGame.initialParty, isEmpty);
        expect(manifest.newGame.starterOptions, isEmpty);
        final directory = await Directory.systemTemp.createTemp(
          'campaign-prefix-save-',
        );
        final repository = ConvertedSourceIntroDiskSave(
          path.join(directory.path, 'game.json'),
        );
        ConvertedSourceIntroMounted? mounted;
        final checkpoints = <Map<String, Object?>>[];
        final dialogues = <String>[];
        final movies = <String>[];
        final modalities = <String>[];
        final battleOutcomes = <Map<String, Object?>>[];
        final battleChoices = <Map<String, Object?>>[];
        final battleTurns = <Map<String, Object?>>[];
        final retainedSaves = <String, Map<String, String>>{};
        final serviceCommands = <Future<void>>[];
        Object? observedBattleSetup, observedBattleTurn;
        var battleCommandCount = 0, dialoguePresentationTicks = 0;
        final brockSupportChoices = <String, int>{};
        final brockGrowlChoices = <String, int>{};
        final forestSupportChoices = <String, int>{};
        final maps = <String, MapData>{};
        var handledModal = '', currentStage = 'intro';
        final blockedEdges = <(String, GridPos, GridPos)>{};
        final terrainCosts = <String, Map<GridPos, int>>{};
        var trainingIterations = 0,
            trainingMovements = 0,
            trainingRecoveries = 0,
            trainingVictories = 0;
        int? trainingExperienceBefore,
            trainingExperienceAfter,
            trainingPhaseElapsedMs,
            trainingFinalCenterReturnElapsedMs;
        const preforestStage = 'prepare_route_one_before_forest';
        Map<String, Object?>? preforestEvidence;
        int preforestVictories() => battleOutcomes
            .where(
              (outcome) =>
                  outcome['stage'] == preforestStage &&
                  outcome['isTrainerBattle'] == false &&
                  outcome['victory'] == true,
            )
            .length;
        const trainingStage = 'train_before_first_badge';
        Map<String, Object?>? successfulResult;
        Map<String, Object?>? firstBadgeEvidence;
        final watch = Stopwatch()..start();
        try {
          mounted = await mountConvertedSourceIntroGame(
            tester,
            projectFile,
            manifest,
            repository,
            resumed ?? initial!,
            restored: resumed == null ? null : saveDataFromGameState(resumed),
            loadActualPlayerServiceCaps: true,
          );
          var game = mounted.game;
          var controller = mounted.controller;
          NarrativeValue value(String suffix) {
            final fact = manifest.facts.singleWhere(
              (f) => f.description.endsWith(suffix),
            );
            return game.gameStateSnapshot.narrativeFactRuntimeState.valueFor(
                  fact.id,
                ) ??
                fact.initialValue;
          }

          void checkpoint(String name) {
            final row = <String, Object?>{
              'stage': name,
              'mapId': game.gameStateSnapshot.currentMapId,
              'position': game.debugPlayerGridPosition.toJson(),
              'partyCount': game.gameStateSnapshot.party.members.length,
              'party': [
                for (final member in game.gameStateSnapshot.party.members)
                  {
                    'individualId': member.individualId,
                    'speciesId': member.speciesId,
                    'level': member.level,
                    'hp': member.currentHp,
                  },
              ],
              'badges': game.gameStateSnapshot.trainerProfile.badgeIds,
              'elapsedMs': watch.elapsedMilliseconds,
            };
            checkpoints.add(row);
            stdout.writeln(
              jsonEncode({'kind': 'campaignPrefixProgress', ...row}),
            );
            if (output != null) {
              File('$output.progress.json').writeAsStringSync(
                jsonEncode({
                  'kind': 'genuineSourceCampaignProgress',
                  'projectPath': root,
                  'checkpoints': checkpoints,
                  'battleOutcomes': battleOutcomes,
                  'battleChoices': battleChoices,
                  'battleTurns': battleTurns,
                  'qaFlagsSeeded': false,
                  'qaPartySeeded': false,
                  'qaPositionSeeded': false,
                  'journeyComplete': false,
                }),
                flush: true,
              );
            }
          }

          Future<void> retainSave(String milestone, GameState state) async {
            if (output == null) return;
            final bytes = await File(repository.filePath).readAsBytes();
            final destination = '$output.$milestone.save.json';
            await File(destination).writeAsBytes(bytes, flush: true);
            expect(await File(destination).readAsBytes(), bytes);
            expect(
              (await ConvertedSourceIntroDiskSave(
                destination,
              ).load())!.toJson(),
              state.toJson(),
            );
            retainedSaves[milestone] = {
              'path': destination,
              'sha256': crypto.sha256.convert(bytes).toString(),
            };
          }

          void press(RuntimeInputControl control) {
            game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
            game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
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
              !game.debugPostBattleOverlayMounted &&
              game.debugCinematicDialogueLine == null &&
              game.dialoguePresentationListenable.value == null &&
              controller.worldServiceSnapshot == null;
          Future<void> tick() async {
            game.update(.025);
            await game.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
            if (game.debugBattleSessionSnapshot case final battle?) {
              final turn = battle.state.currentTurn;
              if (turn != null && !identical(observedBattleTurn, turn)) {
                observedBattleTurn = turn;
                battleTurns.add({
                  'stage': currentStage,
                  'trainerId': battle.setup.trainerId,
                  'playerHp': battle.state.player.currentHp,
                  'enemyHp': battle.state.enemy.currentHp,
                  'moves': [
                    for (final execution in turn.executions)
                      {
                        'side': execution.attackerSlot.side.name,
                        'moveId': execution.move.id,
                        'didHit': execution.didHit,
                        'damage': execution.damage,
                        'legacyReportedEffectiveness':
                            execution.typeEffectivenessMultiplier,
                        'didCrit': execution.didCrit,
                      },
                  ],
                });
              }
              if (battle.state.outcome != null &&
                  !identical(observedBattleSetup, battle.setup)) {
                observedBattleSetup = battle.setup;
                battleOutcomes.add({
                  'stage': currentStage,
                  'mapId': game.gameStateSnapshot.currentMapId,
                  'trainerId': battle.setup.trainerId,
                  'isTrainerBattle': battle.setup.isTrainerBattle,
                  'enemy': battle.state.enemy.speciesId,
                  'sourceRoster': [
                    for (final member in [
                      battle.setup.enemyPokemon,
                      ...battle.setup.enemyReservePokemon,
                    ])
                      {'speciesId': member.speciesId, 'level': member.level},
                  ],
                  'enemyLevel': battle.state.enemy.level,
                  'outcome': battle.state.outcome!.type.name,
                  'victory': battle.state.outcome!.isVictory,
                  'defeat': battle.state.outcome!.isDefeat,
                });
                if (currentStage == trainingStage &&
                    !battle.setup.isTrainerBattle &&
                    battle.state.outcome!.isVictory) {
                  trainingVictories++;
                }
              }
            }
            if (game.battleCommandOverlayListenable.value case final overlay?
                when overlay.interactionsEnabled &&
                    overlay.mode != BattleCommandOverlayMode.decision) {
              final enabled = overlay.entries.where((entry) => entry.enabled);
              final nativeBattle = game.debugBattleSessionSnapshot;
              final retreatWild =
                  nativeBattle != null &&
                  !nativeBattle.setup.isTrainerBattle &&
                  (currentStage == 'traverse_viridian_forest_after_healing' ||
                      currentStage == 'training_center_return' ||
                      currentStage == 'preforest_center_return' ||
                      (currentStage == preforestStage &&
                          (preforestVictories() >= 32 ||
                              nativeBattle.state.enemy.level > 3 ||
                              nativeBattle.state.enemy.level >
                                  nativeBattle.state.player.level - 2)) ||
                      (currentStage == trainingStage &&
                          trainingVictories >= trainingVictoryLimit) ||
                      nativeBattle.state.player.currentHp * 2 <
                          nativeBattle.state.player.maxHp);
              if (retreatWild &&
                  overlay.mode != BattleCommandOverlayMode.root &&
                  overlay.canGoBack) {
                if (game.dispatchBattlePresentationCommand(
                  BattleBackCommand(
                    snapshotRevision: overlay.revision,
                    expectedMode: overlay.mode,
                  ),
                )) {
                  battleCommandCount++;
                  battleChoices.add({
                    'stage': currentStage,
                    'action': 'back',
                    'mode': overlay.mode.name,
                    'enemy': nativeBattle.state.enemy.speciesId,
                    'playerHp': nativeBattle.state.player.currentHp,
                    'enemyHp': nativeBattle.state.enemy.currentHp,
                  });
                }
                return;
              }
              final preferGrass =
                  nativeBattle != null &&
                  {
                    'geodude',
                    'onix',
                    'rattata',
                    'sandshrew',
                  }.contains(nativeBattle.state.enemy.speciesId);
              final brockTargetKey = nativeBattle == null
                  ? null
                  : '${nativeBattle.setup.trainerId}:${nativeBattle.state.enemy.lineupIndex}';
              final brockSupportCount =
                  brockSupportChoices[brockTargetKey] ?? 0;
              final brockGrowlCount = brockGrowlChoices[brockTargetKey] ?? 0;
              final brockSupportMove =
                  currentStage == 'first_brock_badge' && nativeBattle != null
                  ? nativeBattle.state.enemy.speciesId == 'geodude'
                        ? brockGrowlCount == 0
                              ? 'growl'
                              : nativeBattle.state.enemy.currentHp ==
                                    nativeBattle.state.enemy.maxHp
                              ? 'leech_seed'
                              : brockGrowlCount < 6 ||
                                    nativeBattle.state.player.currentHp <
                                        nativeBattle.state.player.maxHp
                              ? 'growl'
                              : null
                        : !nativeBattle.state.player.moves.any(
                            (move) => move.id == 'vine_whip',
                          )
                        ? brockSupportCount == 0
                              ? 'leech_seed'
                              : brockSupportCount <= 3
                              ? 'growl'
                              : null
                        : null
                  : null;
              final forestSupportCount =
                  forestSupportChoices[brockTargetKey] ?? 0;
              final forestSupportMove =
                  {
                    'source-pbs-08ebff40f897a7b7082a6586',
                    'source-pbs-7843b6cf472f11e81123cb09',
                  }.contains(nativeBattle?.setup.trainerId)
                  ? nativeBattle!.setup.trainerId ==
                                'source-pbs-08ebff40f897a7b7082a6586' &&
                            forestSupportCount == 0
                        ? 'growl'
                        : nativeBattle.state.enemy.currentHp ==
                              nativeBattle.state.enemy.maxHp
                        ? 'leech_seed'
                        : forestSupportCount < 2
                        ? 'growl'
                        : null
                  : null;
              final supportMove = brockSupportMove ?? forestSupportMove;
              final entry =
                  overlay.mode == BattleCommandOverlayMode.fight &&
                      supportMove != null
                  ? enabled.firstWhere(
                      (entry) =>
                          entry.index >= 0 &&
                          entry.index <
                              nativeBattle!.state.player.moves.length &&
                          nativeBattle.state.player.moves[entry.index].id ==
                              supportMove,
                      orElse: () => enabled.firstWhere(
                        (entry) =>
                            entry.tone ==
                                BattleCommandOverlayEntryTone.attack ||
                            entry.tone == BattleCommandOverlayEntryTone.special,
                        orElse: () => enabled.first,
                      ),
                    )
                  : overlay.mode == BattleCommandOverlayMode.fight
                  ? enabled.firstWhere(
                      (entry) =>
                          preferGrass &&
                          entry.index >= 0 &&
                          entry.index <
                              nativeBattle.state.player.moves.length &&
                          nativeBattle.state.player.moves[entry.index].id ==
                              'vine_whip',
                      orElse: () => enabled.firstWhere(
                        (entry) =>
                            entry.tone ==
                                BattleCommandOverlayEntryTone.attack ||
                            entry.tone == BattleCommandOverlayEntryTone.special,
                        orElse: () => enabled.first,
                      ),
                    )
                  : enabled.first;
              final index = switch (overlay.mode) {
                BattleCommandOverlayMode.root =>
                  retreatWild &&
                          enabled.any(
                            (entry) =>
                                entry.index ==
                                BattleCommandRootAction.run.index,
                          )
                      ? BattleCommandRootAction.run.index
                      : BattleCommandRootAction.fight.index,
                BattleCommandOverlayMode.fight ||
                BattleCommandOverlayMode.continueOnly ||
                BattleCommandOverlayMode.pokemon => entry.index,
                _ => throw StateError(
                  'Unexpected campaign battle menu ${overlay.mode}: ${overlay.prompt}',
                ),
              };
              if (game.dispatchBattlePresentationCommand(
                BattleSelectEntryCommand(
                  snapshotRevision: overlay.revision,
                  expectedMode: overlay.mode,
                  entryIndex: index,
                ),
              )) {
                battleCommandCount++;
                battleChoices.add({
                  'stage': currentStage,
                  'mode': overlay.mode.name,
                  'entryIndex': index,
                  'trainerId': nativeBattle?.setup.trainerId,
                  'enemy': nativeBattle?.state.enemy.speciesId,
                  'enemyHp': nativeBattle?.state.enemy.currentHp,
                  'playerHp': nativeBattle?.state.player.currentHp,
                  'moveId':
                      overlay.mode == BattleCommandOverlayMode.fight &&
                          nativeBattle != null &&
                          index >= 0 &&
                          index < nativeBattle.state.player.moves.length
                      ? nativeBattle.state.player.moves[index].id
                      : null,
                });
                if (forestSupportMove == 'growl' &&
                    overlay.mode == BattleCommandOverlayMode.fight &&
                    brockTargetKey != null) {
                  forestSupportChoices[brockTargetKey] = forestSupportCount + 1;
                }
                if (currentStage == 'first_brock_badge' &&
                    overlay.mode == BattleCommandOverlayMode.fight &&
                    brockTargetKey != null) {
                  brockSupportChoices[brockTargetKey] = brockSupportCount + 1;
                  if (index >= 0 &&
                      index < nativeBattle!.state.player.moves.length &&
                      nativeBattle.state.player.moves[index].id == 'growl') {
                    brockGrowlChoices[brockTargetKey] = brockGrowlCount + 1;
                  }
                }
              }
            }
            if (game.postBattlePresentationListenable.value
                case final presentation? when !presentation.completed) {
              expect(presentation.hasFailure, isFalse);
              final command = presentation.choices.isEmpty
                  ? PostBattleAdvanceCommand(
                      snapshotRevision: presentation.revision,
                    )
                  : PostBattleSelectDecisionCommand(
                      snapshotRevision: presentation.revision,
                      decisionIndex: presentation.choices.first.index,
                    );
              game.dispatchPostBattlePresentationCommand(command);
            }
            if (game.debugCinematicDialogueLine case final line?) {
              dialoguePresentationTicks++;
              if (movies.isEmpty || movies.last != line) movies.add(line);
              press(RuntimeInputControl.primary);
            }
            final dialogue = game.dialoguePresentationListenable.value;
            if (dialogue != null) {
              dialoguePresentationTicks++;
              if (dialogues.isEmpty || dialogues.last != dialogue.fullText) {
                dialogues.add(dialogue.fullText);
              }
              press(RuntimeInputControl.primary);
            }
            final modal = controller.worldServiceSnapshot;
            if (modal != null &&
                modal.request.kind == RuntimeWorldServiceKind.heal) {
              expect(
                modal.stage,
                isNot(RuntimeWorldServiceStage.failed),
                reason: modal.safeMessage,
              );
              final key =
                  '${modal.request.interactionId}:${modal.revision}:${modal.stage.name}';
              final action = modal.stage == RuntimeWorldServiceStage.completed
                  ? RuntimeWorldServiceAction.close
                  : RuntimeWorldServiceAction.confirm;
              if (handledModal != key && modal.isActionEnabled(action)) {
                handledModal = key;
                serviceCommands.add(
                  controller
                      .dispatchWorldService(
                        RuntimeWorldServiceCommand(
                          action: action,
                          snapshotRevision: modal.revision,
                        ),
                      )
                      .then((result) {
                        expect(
                          result.status,
                          RuntimeWorldServiceCommandStatus.accepted,
                        );
                      }),
                );
                modalities.add('nativeHeal:${action.name}');
              }
            }
            if (modal?.content case final SceneInteractionRequest request) {
              final key = '${request.requestId}:${request.revision}';
              if (key == handledModal) return;
              handledModal = key;
              modalities.add(request.runtimeType.toString());
              final SceneInteractionResult result;
              if (request is SceneChoiceInteractionRequest &&
                  currentStage == 'intro') {
                expect(
                  request.options.map((option) => option.id),
                  contains('preset:1'),
                );
                result = SceneInteractionResult.choiceSelected(
                  requestId: request.requestId,
                  revision: request.revision,
                  selectedOptionId: 'preset:1',
                );
              } else if (request is SceneConfirmationInteractionRequest) {
                result = SceneInteractionResult.confirmed(
                  requestId: request.requestId,
                  revision: request.revision,
                  value: currentStage == 'intro',
                );
              } else if (request is SceneMessageInteractionRequest) {
                result = SceneInteractionResult.acknowledged(
                  requestId: request.requestId,
                  revision: request.revision,
                );
              } else {
                fail('Unexpected $currentStage modal: ${request.toJson()}');
              }
              final outcome = await controller.dispatchWorldService(
                RuntimeWorldServiceCommand(
                  action: RuntimeWorldServiceAction.confirm,
                  snapshotRevision: modal!.revision,
                  interactionResult: result,
                ),
              );
              expect(outcome.status, RuntimeWorldServiceCommandStatus.accepted);
            }
          }

          Future<void> until(
            bool Function() condition,
            String frontier, {
            int limit = 18000,
          }) async {
            var stable = 0;
            for (var step = 0; step < limit; step++) {
              await tick();
              stable = condition() ? stable + 1 : 0;
              if (stable >= 8) return;
            }
            fail(
              '$frontier blocked: stage=$currentStage map=${game.gameStateSnapshot.currentMapId} '
              'position=${game.debugPlayerGridPosition} phase=${game.debugFlowPhaseName} '
              'dialogue=${game.dialoguePresentationListenable.value?.fullText} '
              'modal=${controller.worldServiceSnapshot?.content} '
              'pending=${game.debugPendingSceneWaitCount}',
            );
          }

          Future<MapData> authoredMap(String id) async {
            if (maps[id] case final cached?) return cached;
            final entry = manifest.maps.singleWhere((m) => m.id == id);
            final map = MapData.fromJson(
              Map<String, dynamic>.from(
                jsonDecode(
                  await File(path.join(root, entry.relativePath))
                      .readAsString(),
                ) as Map,
              ),
            );
            maps[id] = map;
            return map;
          }

          int traversalCost(MapData map, GridPos position) =>
              (terrainCosts[map.id] ??= {}).putIfAbsent(
                position,
                () =>
                    map.gameplayZones.any(
                      (zone) =>
                          zone.kind == GameplayZoneKind.encounter &&
                          gameplayZoneContainsPosition(zone, position),
                    )
                    ? 101
                    : 1,
              );

          int routeCost(MapData map, Iterable<GridPos> route) =>
              route.fold(0, (sum, cell) => sum + traversalCost(map, cell));

          Future<List<GridPos>> routeTo(
            GridPos goal,
            Set<GridPos> avoid, {
            bool required = true,
          }) async {
            final authored = await authoredMap(
              game.gameStateSnapshot.currentMapId,
            );
            final active = projectMapEntityPresentations(
              project: manifest,
              map: authored,
              gameState: game.gameStateSnapshot,
            );
            final located = active.copyWith(
              entities: [
                for (final entity in active.entities)
                  if (game.debugMapEntityPosition(entity.id)
                      case final position?)
                    entity.copyWith(pos: position)
                  else
                    entity,
              ],
            );
            final start = game.debugPlayerGridPosition;
            final world = GameplayWorldState.initial(
              map: located,
              project: manifest,
              playerPos: start,
              gameState: game.gameStateSnapshot,
              tileWidth: manifest.settings.tileWidth,
              tileHeight: manifest.settings.tileHeight,
            );
            final pending = SplayTreeMap<int, Queue<GridPos>>()
              ..[0] = (Queue<GridPos>()..add(start));
            final distances = <GridPos, int>{start: 0};
            final previous = <GridPos, GridPos?>{start: null};
            while (pending.isNotEmpty) {
              final cost = pending.firstKey()!;
              final bucket = pending[cost]!;
              final cell = bucket.removeFirst();
              if (bucket.isEmpty) pending.remove(cost);
              if (distances[cell] != cost) continue;
              if (cell == goal) break;
              for (final delta in [(0, -1), (-1, 0), (1, 0), (0, 1)]) {
                final next = GridPos(
                  x: cell.x + delta.$1,
                  y: cell.y + delta.$2,
                );
                if (avoid.contains(next) ||
                    blockedEdges.contains((authored.id, cell, next)) ||
                    world.isBlocked(next.x, next.y)) {
                  continue;
                }
                final nextCost = cost + traversalCost(located, next);
                if (nextCost >= (distances[next] ?? 1 << 62)) continue;
                distances[next] = nextCost;
                previous[next] = cell;
                (pending[nextCost] ??= Queue<GridPos>()).add(next);
              }
            }
            if (!previous.containsKey(goal)) {
              if (!required) return const [];
              fail(
                'No native collision route in ${authored.name}: $start -> $goal',
              );
            }
            final reversed = <GridPos>[];
            for (GridPos? cell = goal; cell != null; cell = previous[cell]) {
              reversed.add(cell);
            }
            return reversed.reversed.toList();
          }

          Future<void> step(RuntimeInputControl control) async {
            final startMap = game.gameStateSnapshot.currentMapId,
                start = game.debugPlayerGridPosition;
            final startBattleCount = battleOutcomes.length;
            final startDefeats =
                int.tryParse(
                  game.gameStateSnapshot.metadata['player.defeat.count'] ?? '0',
                ) ??
                0;
            game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
            try {
              for (var frame = 0; frame < 60; frame++) {
                await tick();
                if (game.gameStateSnapshot.currentMapId != startMap ||
                    game.debugPlayerGridPosition != start ||
                    game.debugIsCinematicPlaying ||
                    game.dialoguePresentationListenable.value != null) {
                  break;
                }
              }
            } finally {
              game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
            }
            await until(idle, 'finish keyboard step', limit: 6000);
            if ((currentStage == trainingStage ||
                    currentStage == preforestStage) &&
                battleOutcomes
                    .skip(startBattleCount)
                    .any(
                      (outcome) =>
                          outcome['isTrainerBattle'] == false &&
                          outcome['defeat'] == true,
                    )) {
              final recovery = PlayerRecoveryPoint.tryRead(
                game.gameStateSnapshot,
              )!;
              expect(game.gameStateSnapshot.currentMapId, recovery.mapId);
              expect(game.debugPlayerGridPosition, recovery.position);
              expect(
                int.parse(
                  game.gameStateSnapshot.metadata['player.defeat.count']!,
                ),
                startDefeats + 1,
              );
              trainingRecoveries++;
              checkpoint('native_wild_defeat_recovered');
              throw const _NativeWildDefeatRecovered();
            }

            if ((currentStage == trainingStage ||
                    currentStage == preforestStage) &&
                battleOutcomes.length > startBattleCount) {
              if (currentStage == trainingStage) {
                trainingExperienceAfter =
                    game.gameStateSnapshot.party.members.single.experience;
              }
              checkpoint(
                currentStage == preforestStage
                    ? 'natural_preforest_battle_resolved'
                    : 'natural_training_battle_resolved',
              );
              expect(await game.saveGame(), isTrue);
              await retainSave(
                '$currentStage-battle-${battleOutcomes.length}',
                (await repository.load())!,
              );
            }
            if (currentStage == trainingStage &&
                (game.gameStateSnapshot.currentMapId != startMap ||
                    game.debugPlayerGridPosition != start)) {
              trainingMovements++;
            }
          }

          Future<void> walkTo(
            GridPos goal, {
            Set<GridPos> avoid = const {},
          }) async {
            final expectedMapId = game.gameStateSnapshot.currentMapId;
            for (var attempt = 0; attempt < 250; attempt++) {
              expect(game.gameStateSnapshot.currentMapId, expectedMapId);
              final beforeMapId = game.gameStateSnapshot.currentMapId;
              final before = game.debugPlayerGridPosition;
              if (before == goal) return;
              final route = await routeTo(goal, avoid);
              final next = route[1];
              final control = next.x < before.x
                  ? RuntimeInputControl.left
                  : next.x > before.x
                  ? RuntimeInputControl.right
                  : next.y < before.y
                  ? RuntimeInputControl.up
                  : RuntimeInputControl.down;
              await step(control);
              expect(
                game.gameStateSnapshot.currentMapId,
                expectedMapId,
                reason: 'Unexpected map transition while walking to $goal',
              );
              if (game.gameStateSnapshot.currentMapId == beforeMapId &&
                  game.debugPlayerGridPosition == before) {
                blockedEdges.add((beforeMapId, before, next));
              }
            }
            fail(
              'Keyboard walk did not reach $goal from ${game.debugPlayerGridPosition}',
            );
          }

          Future<(GridPos, GridPos)> nearestEncounterPair() async {
            final trainingMap = await authoredMap(
              game.gameStateSnapshot.currentMapId,
            );
            final start = game.debugPlayerGridPosition;
            final candidates =
                [
                  for (var y = 0; y < trainingMap.size.height; y++)
                    for (var x = 0; x < trainingMap.size.width; x++)
                      if (traversalCost(trainingMap, GridPos(x: x, y: y)) ==
                          101)
                        GridPos(x: x, y: y),
                ]..sort(
                  (a, b) => ((a.x - start.x).abs() + (a.y - start.y).abs())
                      .compareTo((b.x - start.x).abs() + (b.y - start.y).abs()),
                );
            List<GridPos>? encounterRoute;
            for (final candidate in candidates) {
              final route = await routeTo(candidate, {}, required: false);
              if (route.length > 1) {
                encounterRoute = route;
                break;
              }
            }
            expect(encounterRoute, isNotNull);
            return (
              encounterRoute!.last,
              encounterRoute[encounterRoute.length - 2],
            );
          }

          Future<void> crossConnection(
            MapConnectionDirection direction,
            String targetMapId,
          ) async {
            final source = await authoredMap(
              game.gameStateSnapshot.currentMapId,
            );
            final target = await authoredMap(targetMapId);
            final connection = source.connections.singleWhere(
              (connection) =>
                  connection.direction == direction &&
                  connection.targetMapId == targetMapId,
            );
            final targetWorld = GameplayWorldState.initial(
              map: projectMapEntityPresentations(
                project: manifest,
                map: target,
                gameState: game.gameStateSnapshot,
              ),
              project: manifest,
              playerPos: const GridPos(x: 0, y: 0),
              gameState: game.gameStateSnapshot,
              tileWidth: manifest.settings.tileWidth,
              tileHeight: manifest.settings.tileHeight,
            );
            final candidates = <(GridPos, int)>[];
            final count =
                direction == MapConnectionDirection.north ||
                    direction == MapConnectionDirection.south
                ? source.size.width
                : source.size.height;
            for (var index = 0; index < count; index++) {
              final border = switch (direction) {
                MapConnectionDirection.north => GridPos(x: index, y: 0),
                MapConnectionDirection.south => GridPos(
                  x: index,
                  y: source.size.height - 1,
                ),
                MapConnectionDirection.west => GridPos(x: 0, y: index),
                MapConnectionDirection.east => GridPos(
                  x: source.size.width - 1,
                  y: index,
                ),
              };
              final arrival = resolveConnectedMapTargetPos(
                sourcePos: border,
                sourceSize: source.size,
                targetSize: target.size,
                direction: direction,
                offset: connection.offset,
              );
              if (arrival == null ||
                  targetWorld.isBlocked(arrival.x, arrival.y)) {
                continue;
              }
              final route = await routeTo(border, const {}, required: false);
              if (route.isNotEmpty) {
                candidates.add((
                  border,
                  routeCost(source, route.skip(1)) +
                      traversalCost(target, arrival),
                ));
              }
            }
            candidates.sort((a, b) => a.$2.compareTo(b.$2));
            expect(
              candidates,
              isNotEmpty,
              reason: 'No walkable ${source.name} -> ${target.name} boundary',
            );
            await walkTo(candidates.first.$1);
            await step(switch (direction) {
              MapConnectionDirection.north => RuntimeInputControl.up,
              MapConnectionDirection.south => RuntimeInputControl.down,
              MapConnectionDirection.west => RuntimeInputControl.left,
              MapConnectionDirection.east => RuntimeInputControl.right,
            });
            expect(game.gameStateSnapshot.currentMapId, targetMapId);
            checkpoint('connection_${source.name}_${target.name}');
            expect(await game.saveGame(), isTrue);
            await retainSave(
              'connection-$targetMapId',
              (await repository.load())!,
            );
          }

          if (resumed == null) {
            await until(
              () => game.gameStateSnapshot.currentMapId == home.id && idle(),
              'source intro',
            );
            expect(game.debugPlayerGridPosition, const GridPos(x: 27, y: 8));
            expect(value(':variable:28').stringValue, 'Gary');
            expect(value(':switch:99').boolValue, isTrue);
            expect(game.gameStateSnapshot.party.members, isEmpty);
            expect(value(':variable:29').intValue, 0);
            if (continueToParcel) {
              expect(
                game
                    .gameStateSnapshot
                    .pauseMenuState
                    .visibilityOverrides[ProjectPauseActionId.pokedex],
                isFalse,
              );
            }
            checkpoint('source_intro_completed');
            currentStage = 'home';
            await walkTo(
              const GridPos(x: 31, y: 4),
              avoid: {const GridPos(x: 30, y: 4)},
            );
            await step(RuntimeInputControl.left);
            expect(game.gameStateSnapshot.currentMapId, home.id);
            expect(game.debugPlayerGridPosition.x, lessThan(20));
            checkpoint('stairs_down');
            await walkTo(const GridPos(x: 5, y: 10));
            await step(RuntimeInputControl.down);
            expect(game.gameStateSnapshot.currentMapId, pallet.id);
            expect(game.debugPlayerGridPosition, const GridPos(x: 12, y: 8));
            checkpoint('home_exit');
            currentStage = 'escort';
            await walkTo(const GridPos(x: 18, y: 2));
            await step(RuntimeInputControl.up);
            await until(
              () =>
                  game.gameStateSnapshot.currentMapId == lab.id &&
                  idle() &&
                  value(':switch:75').boolValue == true,
              'Oak escort and source laboratory preparation',
            );
            expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 6));
            expect(value(':switch:74').boolValue, isFalse);
            expect(value(':variable:29').intValue, 0);
            expect(game.gameStateSnapshot.party.members, isEmpty);
            checkpoint('laboratory_offer_enabled');
            currentStage = 'starter';
            final offer = manifest.scenes.singleWhere(
              (s) =>
                  s.metadata['sourcePageIndex'] == '1' &&
                  s.graph.nodes
                      .map((n) => n.payload)
                      .whereType<SceneActionPayload>()
                      .any(
                        (a) =>
                            a.interactiveCommand
                                is SceneReceivePokemonFromCatalogInteractiveCommand &&
                            (a.interactiveCommand
                                        as SceneReceivePokemonFromCatalogInteractiveCommand)
                                    .speciesId ==
                                'bulbasaur',
                      ),
            );
            final ball = (await authoredMap(lab.id)).entities.singleWhere(
              (e) =>
                  e.properties['sourceEventIdentity'] ==
                  offer.metadata['sourceEventIdentity'],
            );
            await walkTo(
              GridPos(x: ball.pos.x, y: ball.pos.y + ball.size.height),
            );
            await step(RuntimeInputControl.up);
            expect(
              game.overworldInteractionSnapshot.primaryAction?.request.targetId,
              ball.id,
            );
            press(RuntimeInputControl.primary);
            await until(
              () => idle() && game.gameStateSnapshot.party.members.length == 1,
              'source Bulbasaur choice',
            );
          } else {
            await until(idle, 'cold continue from natural starter save');
            checkpoint('natural_starter_save_loaded');
          }
          final pokemon = game.gameStateSnapshot.party.members.single;
          expect(pokemon.speciesId, 'bulbasaur');
          expect(
            pokemon.level,
            resumed == null ? 5 : resumed.party.members.single.level,
          );
          expect(pokemon.provenance!.kind, PlayerPokemonOriginKind.gift);
          expect(value(':variable:29').intValue, 1);
          expect(value(':switch:75').boolValue, isFalse);
          expect(value(':map:9:event:4:self:A').boolValue, isTrue);
          checkpoint(
            resumed == null
                ? 'bulbasaur_received'
                : 'natural_starter_state_retained',
          );
          expect(await game.saveGame(), isTrue);
          final saved = (await repository.load())!;
          expect(
            PlayerRecoveryPoint.tryRead(saved),
            resumed == null
                ? expectedRecovery
                : PlayerRecoveryPoint.tryRead(resumed),
          );
          expect(
            recoveryMarker(saved),
            resumed == null
                ? const NarrativeValue.boolean(false)
                : recoveryMarker(resumed),
          );
          String? retainedSavePath, retainedSaveSha256;
          if (output != null) {
            final bytes = await File(repository.filePath).readAsBytes();
            retainedSavePath = resumed == null
                ? '$output.starter.save.json'
                : '$output.cold.save.json';
            retainedSaveSha256 = crypto.sha256.convert(bytes).toString();
            await File(retainedSavePath).writeAsBytes(bytes, flush: true);
            expect(await File(retainedSavePath).readAsBytes(), bytes);
            final retained = await ConvertedSourceIntroDiskSave(
              retainedSavePath,
            ).load();
            expect(retained!.toJson(), saved.toJson());
            stdout.writeln(
              jsonEncode({
                'kind': 'campaignPrefixStarterSave',
                'path': retainedSavePath,
                'sha256': retainedSaveSha256,
              }),
            );
          }
          await mounted.close(tester);
          mounted = null;
          mounted = await mountConvertedSourceIntroGame(
            tester,
            projectFile,
            manifest,
            repository,
            saved,
            loadActualPlayerServiceCaps: true,
            restored: saveDataFromGameState(saved),
          );
          expect(
            mounted.game.gameStateSnapshot.mapInstanceWorldState,
            saved.mapInstanceWorldState,
          );
          for (var frame = 0; frame < 50; frame++) {
            mounted.game.update(.025);
            await mounted.game.ready();
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          final restored = mounted.game.gameStateSnapshot;
          expect(
            PlayerRecoveryPoint.tryRead(restored),
            PlayerRecoveryPoint.tryRead(saved),
          );
          expect(recoveryMarker(restored), recoveryMarker(saved));
          expect(restored.party, saved.party);
          expect(restored.currentMapId, saved.currentMapId);
          expect(restored.playerPosition, saved.playerPosition);
          expect(
            restored.narrativeFactRuntimeState,
            saved.narrativeFactRuntimeState,
          );
          Future<void> expectFullyHealed() async {
            final state = game.gameStateSnapshot;
            final caps = await loadRuntimePlayerServiceRecoveryCaps(
              gameState: state,
              projectRootDirectory: root,
              pokemonConfig: manifest.pokemon,
            );
            for (var index = 0; index < state.party.members.length; index++) {
              final member = state.party.members[index];
              expect(member.currentHp, caps.maxHpByPartyIndex[index]);
              expect(member.statusId, isEmpty);
              for (final move in member.knownMoveIds) {
                expect(
                  member.currentPpByMoveId![move],
                  caps.maxPpByPartyIndex[index]![move],
                );
              }
            }
          }

          Future<void> healAtHome() async {
            expect(game.gameStateSnapshot.currentMapId, pallet.id);
            await walkTo(const GridPos(x: 12, y: 8));
            await step(RuntimeInputControl.up);
            expect(game.gameStateSnapshot.currentMapId, home.id);
            await walkTo(const GridPos(x: 9, y: 7));
            await step(RuntimeInputControl.up);
            expect(
              game.overworldInteractionSnapshot.primaryAction?.request.targetId,
              (await authoredMap(home.id)).entities
                  .singleWhere((entity) => entity.name == 'Mom')
                  .id,
            );
            press(RuntimeInputControl.primary);
            await until(idle, 'voluntary source Mom healing');
            await expectFullyHealed();
            checkpoint('source_mom_healed');
            await walkTo(const GridPos(x: 5, y: 10));
            await step(RuntimeInputControl.down);
            expect(game.gameStateSnapshot.currentMapId, pallet.id);
            expect(await game.saveGame(), isTrue);
            await retainSave('naturally-healed', (await repository.load())!);
          }

          if (continueToParcel) {
            game = mounted.game;
            controller = mounted.controller;
            void expectRecoveryUnchanged() {
              expect(
                PlayerRecoveryPoint.tryRead(game.gameStateSnapshot),
                PlayerRecoveryPoint.tryRead(saved),
              );
              expect(
                recoveryMarker(game.gameStateSnapshot),
                recoveryMarker(saved),
              );
            }

            void expectRivalCompleted() {
              for (final event in [2, 3, 9, 14, 17, 18, 19]) {
                expect(value(':map:9:event:$event:self:A').boolValue, isTrue);
              }
            }

            void expectPokedexVisible(bool visible) {
              expect(
                game
                    .gameStateSnapshot
                    .pauseMenuState
                    .visibilityOverrides[ProjectPauseActionId.pokedex],
                visible,
              );
            }

            final rival = manifest.trainers.singleWhere(
              (trainer) =>
                  trainer.trainerClass == 'FRLG_RIVAL1' &&
                  trainer.team.length == 1 &&
                  trainer.team.single.speciesId == 'bulbasaur' &&
                  trainer.team.single.level == 5,
            );
            final parcelAlreadyDelivered =
                value(':switch:60').boolValue == true;
            expectPokedexVisible(parcelAlreadyDelivered);
            checkpoint('starter_cold_continued');
            final rivalAlreadyCompleted =
                value(':map:9:event:2:self:A').boolValue == true;
            if (!rivalAlreadyCompleted) {
              currentStage = 'first_rival_and_laboratory_exit';
              await walkTo(const GridPos(x: 8, y: 9));
              await step(RuntimeInputControl.down);
              await walkTo(const GridPos(x: 8, y: 14));
              await step(RuntimeInputControl.down);
              expect(game.gameStateSnapshot.currentMapId, pallet.id);
              expect(battleCommandCount, greaterThan(0));
              expect(battleOutcomes, hasLength(1));
              expect(
                battleOutcomes.every(
                  (outcome) =>
                      outcome['stage'] == 'first_rival_and_laboratory_exit' &&
                      outcome['mapId'] == lab.id &&
                      outcome['trainerId'] == rival.id &&
                      outcome['isTrainerBattle'] == true &&
                      ((outcome['victory'] == true) !=
                          (outcome['defeat'] == true)),
                ),
                isTrue,
              );
              expect(
                game.gameStateSnapshot.party.members.single.individualId,
                pokemon.individualId,
              );
              expect(battleOutcomes.single['sourceRoster'], [
                {'speciesId': 'bulbasaur', 'level': 5},
              ]);
            } else {
              expect(
                parcelAlreadyDelivered
                    ? manifest.maps.map((map) => map.id)
                    : {pallet.id},
                contains(game.gameStateSnapshot.currentMapId),
              );
              expect(battleOutcomes, isEmpty);
              checkpoint('resumed_after_source_first_rival');
            }
            expectRivalCompleted();
            expectRecoveryUnchanged();
            expectPokedexVisible(parcelAlreadyDelivered);
            checkpoint('source_first_rival_completed');
            expect(await game.saveGame(), isTrue);
            await retainSave('rival-complete', (await repository.load())!);
            if (!stopAfterRival) {
              if (!parcelAlreadyDelivered) {
                currentStage = 'heal_after_first_rival';
                await healAtHome();

                final viridian = manifest.maps.singleWhere(
                  (map) => map.name == 'Viridian City',
                );
                final mart = manifest.maps.singleWhere(
                  (map) => map.name == 'Viridian City Poké Mart',
                );
                final itemCatalog = await const RuntimeItemCatalogLoader().load(
                  projectRootDirectory: root,
                  pokemonConfig: manifest.pokemon,
                );
                final parcelId = itemCatalog!.entries
                    .singleWhere(
                      (item) =>
                          item.displayName == "Oak's Parcel" &&
                          item.pocketId == 'key-items',
                    )
                    .id;
                final ballId = itemCatalog.entries
                    .singleWhere(
                      (item) =>
                          item.displayName == 'Poké Ball' &&
                          item.pocketId == 'balls',
                    )
                    .id;
                int quantity(String itemId) => const BagOperations().quantityOf(
                  game.gameStateSnapshot.bag,
                  itemId,
                );
                expect(quantity(parcelId), 0);
                final ballsBefore = quantity(ballId);
                currentStage = 'walk_to_viridian';
                await crossConnection(
                  MapConnectionDirection.north,
                  routeOne.id,
                );
                await crossConnection(
                  MapConnectionDirection.north,
                  viridian.id,
                );
                await walkTo(const GridPos(x: 36, y: 20));
                await step(RuntimeInputControl.up);
                await until(
                  () =>
                      game.gameStateSnapshot.currentMapId == mart.id &&
                      quantity(parcelId) == 1 &&
                      idle(),
                  'source Mart parcel autorun',
                );
                checkpoint('source_parcel_obtained');
                expect(await game.saveGame(), isTrue);
                final parcelSave = (await repository.load())!;
                await retainSave('parcel', parcelSave);
                await mounted.close(tester);
                mounted = null;
                mounted = await mountConvertedSourceIntroGame(
                  tester,
                  projectFile,
                  manifest,
                  repository,
                  parcelSave,
                  loadActualPlayerServiceCaps: true,
                  restored: saveDataFromGameState(parcelSave),
                );
                game = mounted.game;
                controller = mounted.controller;
                await until(idle, 'cold continue with source parcel');
                expect(quantity(parcelId), 1);
                expect(game.gameStateSnapshot.currentMapId, mart.id);
                expect(value(':map:12:event:22:self:A').boolValue, isTrue);
                expectRecoveryUnchanged();
                expectPokedexVisible(false);
                currentStage = 'return_parcel_to_oak';
                await walkTo(const GridPos(x: 6, y: 9));
                await step(RuntimeInputControl.down);
                expect(game.gameStateSnapshot.currentMapId, viridian.id);
                await crossConnection(
                  MapConnectionDirection.south,
                  routeOne.id,
                );
                await crossConnection(MapConnectionDirection.south, pallet.id);
                await walkTo(const GridPos(x: 22, y: 14));
                await step(RuntimeInputControl.up);
                expect(game.gameStateSnapshot.currentMapId, lab.id);
                expectRivalCompleted();
                expect(
                  battleOutcomes.where(
                    (battle) => battle['isTrainerBattle'] == true,
                  ),
                  hasLength(rivalAlreadyCompleted ? 0 : 1),
                );
                await walkTo(const GridPos(x: 8, y: 6));
                await step(RuntimeInputControl.up);
                expect(
                  game
                      .overworldInteractionSnapshot
                      .primaryAction
                      ?.request
                      .targetId,
                  (await authoredMap(lab.id)).entities
                      .singleWhere((entity) => entity.name == 'Professor')
                      .id,
                );
                press(RuntimeInputControl.primary);
                await until(
                  () =>
                      quantity(parcelId) == 0 &&
                      value(':switch:60').boolValue == true &&
                      idle(),
                  'source Oak parcel delivery and Pokedex',
                );
                expect(quantity(ballId), ballsBefore + 5);
                expect(value(':player:has_pokedex').boolValue, isTrue);
                expect(value(':player:pokedex:unlocked:1').boolValue, isTrue);
                expect(game.gameStateSnapshot.trainerProfile.badgeIds, isEmpty);
                expectPokedexVisible(true);
                expectRivalCompleted();
                expectRecoveryUnchanged();
                expect(
                  battleOutcomes.where(
                    (battle) => battle['isTrainerBattle'] == true,
                  ),
                  hasLength(rivalAlreadyCompleted ? 0 : 1),
                );
                checkpoint('source_parcel_delivered_pokedex_obtained');
                expect(await game.saveGame(), isTrue);
                final delivered = (await repository.load())!;
                await retainSave('parcel-delivered', delivered);
                await mounted.close(tester);
                mounted = null;
                mounted = await mountConvertedSourceIntroGame(
                  tester,
                  projectFile,
                  manifest,
                  repository,
                  delivered,
                  loadActualPlayerServiceCaps: true,
                  restored: saveDataFromGameState(delivered),
                );
                game = mounted.game;
                controller = mounted.controller;
                final lineCount = dialogues.length;
                await until(idle, 'cold continue after source parcel delivery');
                expect(dialogues, hasLength(lineCount));
                expect(quantity(parcelId), 0);
                expect(quantity(ballId), ballsBefore + 5);
                expect(game.gameStateSnapshot.party, delivered.party);
                expect(
                  game.gameStateSnapshot.narrativeFactRuntimeState,
                  delivered.narrativeFactRuntimeState,
                );
                expectPokedexVisible(true);
                expectRivalCompleted();
                expectRecoveryUnchanged();
                expect(
                  battleOutcomes.where(
                    (battle) => battle['isTrainerBattle'] == true,
                  ),
                  hasLength(rivalAlreadyCompleted ? 0 : 1),
                );
                checkpoint('parcel_delivery_cold_continued');
              } else {
                expectPokedexVisible(true);
                checkpoint('resumed_after_natural_parcel_delivery');
              }
              if (reachFirstBadge && !stopAfterParcel) {
                currentStage = 'heal_before_forest';
                if (game.gameStateSnapshot.currentMapId == lab.id) {
                  await walkTo(const GridPos(x: 8, y: 14));
                  await step(RuntimeInputControl.down);
                }
                if (game.gameStateSnapshot.currentMapId == pallet.id) {
                  await healAtHome();
                }
                final viridian = manifest.maps.singleWhere(
                  (map) => map.name == 'Viridian City',
                );
                final center = manifest.maps.singleWhere(
                  (map) => map.name == 'Viridian City Poké Center',
                );
                final routeTwoSouth = manifest.maps.singleWhere(
                  (map) => map.name == 'Route 2-S',
                );
                final routeTwoNorth = manifest.maps.singleWhere(
                  (map) => map.name == 'Route 2-N',
                );
                final gate = manifest.maps.singleWhere(
                  (map) => map.name == 'Viridian Forest Gate',
                );
                final forest = manifest.maps.singleWhere(
                  (map) => map.id == 'map_83c9d76a943ddf9389bc84493ff6beb09f5c790a812131b550a61975',
                );
                final pewter = manifest.maps.singleWhere(
                  (map) => map.name == 'Pewter City',
                );
                final pewterClinic = manifest.maps.singleWhere(
                  (map) => map.name == 'Pewter City Poké Center',
                );
                if (game.gameStateSnapshot.currentMapId == pewterClinic.id) {
                  await expectFullyHealed();
                  await walkTo(const GridPos(x: 9, y: 10));
                  await step(RuntimeInputControl.down);
                  expect(game.gameStateSnapshot.currentMapId, pewter.id);
                }
                currentStage = 'walk_to_viridian_for_forest';
                if (game.gameStateSnapshot.currentMapId == pallet.id) {
                  await crossConnection(
                    MapConnectionDirection.north,
                    routeOne.id,
                  );
                }
                if (game.gameStateSnapshot.currentMapId == routeOne.id) {
                  await crossConnection(
                    MapConnectionDirection.north,
                    viridian.id,
                  );
                }
                if (game.gameStateSnapshot.currentMapId == center.id) {
                  await expectFullyHealed();
                  await walkTo(const GridPos(x: 9, y: 10));
                  await step(RuntimeInputControl.down);
                  expect(game.gameStateSnapshot.currentMapId, viridian.id);
                }
                Future<void> healAtViridianCenter() async {
                  await walkTo(const GridPos(x: 26, y: 27));
                  await step(RuntimeInputControl.up);
                  expect(game.gameStateSnapshot.currentMapId, center.id);
                  await walkTo(const GridPos(x: 9, y: 6));
                  await step(RuntimeInputControl.up);
                  expect(
                    game
                        .overworldInteractionSnapshot
                        .primaryAction
                        ?.request
                        .targetId,
                    (await authoredMap(center.id)).entities
                        .singleWhere((entity) => entity.name == 'Nurse')
                        .id,
                  );
                  press(RuntimeInputControl.primary);
                  await until(idle, 'natural Viridian Pokemon Center healing');
                  await expectFullyHealed();
                  checkpoint('viridian_center_healed');
                  await walkTo(const GridPos(x: 9, y: 10));
                  await step(RuntimeInputControl.down);
                  expect(game.gameStateSnapshot.currentMapId, viridian.id);
                }

                if (game.gameStateSnapshot.currentMapId == viridian.id) {
                  await healAtViridianCenter();
                }
                if (prepareBeforeForest &&
                    game.gameStateSnapshot.party.members.single.level < 10) {
                  expect(game.gameStateSnapshot.currentMapId, viridian.id);
                  final experienceBefore =
                      game.gameStateSnapshot.party.members.single.experience;
                  final preparationWatch = Stopwatch()..start();
                  var alternations = 0, centerReturns = 0;
                  currentStage = preforestStage;
                  await crossConnection(
                    MapConnectionDirection.south,
                    routeOne.id,
                  );
                  final (encounterCell, approachCell) =
                      await nearestEncounterPair();
                  await walkTo(encounterCell);
                  while (preforestVictories() < 32 &&
                      game.gameStateSnapshot.party.members.single.level < 10 &&
                      alternations < 512 &&
                      preparationWatch.elapsed < const Duration(minutes: 8)) {
                    final state = game.gameStateSnapshot;
                    final caps = await loadRuntimePlayerServiceRecoveryCaps(
                      gameState: state,
                      projectRootDirectory: root,
                      pokemonConfig: manifest.pokemon,
                    );
                    if (state.party.members.single.currentHp * 2 <=
                        caps.maxHpByPartyIndex[0]!) {
                      currentStage = 'preforest_center_return';
                      await crossConnection(
                        MapConnectionDirection.north,
                        viridian.id,
                      );
                      await healAtViridianCenter();
                      centerReturns++;
                      expect(await game.saveGame(), isTrue);
                      await retainSave(
                        'preforest-healed-$centerReturns',
                        (await repository.load())!,
                      );
                      currentStage = preforestStage;
                      await crossConnection(
                        MapConnectionDirection.south,
                        routeOne.id,
                      );
                      await walkTo(encounterCell);
                    }
                    alternations++;
                    await walkTo(
                      game.debugPlayerGridPosition == encounterCell
                          ? approachCell
                          : encounterCell,
                    );
                  }
                  preparationWatch.stop();
                  expect(
                    preparationWatch.elapsedMilliseconds,
                    lessThanOrEqualTo(480000),
                  );
                  expect(preforestVictories(), inInclusiveRange(1, 32));
                  final experienceAfter =
                      game.gameStateSnapshot.party.members.single.experience;
                  expect(experienceAfter, greaterThan(experienceBefore!));
                  final finalReturnWatch = Stopwatch()..start();
                  currentStage = 'preforest_center_return';
                  await crossConnection(
                    MapConnectionDirection.north,
                    viridian.id,
                  );
                  await healAtViridianCenter();
                  preforestEvidence = {
                    'sourceMapId': routeOne.id,
                    'targetLevel': 10,
                    'victories': preforestVictories(),
                    'victoryLimit': 32,
                    'alternations': alternations,
                    'alternationLimit': 512,
                    'experienceBefore': experienceBefore,
                    'experienceAfter': experienceAfter,
                    'phaseElapsedMs': preparationWatch.elapsedMilliseconds,
                    'phaseBudgetMs': 480000,
                    'centerReturnsDuringPhase': centerReturns,
                    'finalCenterReturnElapsedMs':
                        finalReturnWatch.elapsedMilliseconds,
                    'levelAfter':
                        game.gameStateSnapshot.party.members.single.level,
                  };
                  expect(
                    game.gameStateSnapshot.party.members.single.level,
                    greaterThanOrEqualTo(10),
                  );
                  checkpoint('bounded_preforest_preparation_completed');
                  expect(await game.saveGame(), isTrue);
                  await retainSave(
                    'preforest-ready',
                    (await repository.load())!,
                  );
                }
                if (prepareBeforeForest) {
                  expect(
                    game.gameStateSnapshot.party.members.single.level,
                    greaterThanOrEqualTo(10),
                  );
                }
                if (!stopAfterPreforest) {
                  currentStage = 'walk_to_viridian_forest';
                  if (game.gameStateSnapshot.currentMapId == viridian.id) {
                    await crossConnection(
                      MapConnectionDirection.north,
                      routeTwoSouth.id,
                    );
                  }
                  if (game.gameStateSnapshot.currentMapId == routeTwoSouth.id) {
                    await walkTo(const GridPos(x: 19, y: 52));
                    await step(RuntimeInputControl.up);
                    expect(game.gameStateSnapshot.currentMapId, gate.id);
                  }
                  if (game.gameStateSnapshot.currentMapId == gate.id &&
                      game.debugPlayerGridPosition.x < 20) {
                    await walkTo(const GridPos(x: 8, y: 4));
                    await step(RuntimeInputControl.up);
                    expect(game.gameStateSnapshot.currentMapId, forest.id);
                    checkpoint('viridian_forest_entered');
                    expect(await game.saveGame(), isTrue);
                    await retainSave(
                      'forest-entered',
                      (await repository.load())!,
                    );
                  }
                  if (game.gameStateSnapshot.currentMapId == forest.id &&
                      !game.gameStateSnapshot.storyFlags.activeFlags.contains(
                        'trainer_defeated:source-pbs-7843b6cf472f11e81123cb09',
                      )) {
                    currentStage = 'first_forest_trainer';
                    await walkTo(const GridPos(x: 47, y: 46));
                    await step(RuntimeInputControl.right);
                    expect(
                      game.gameStateSnapshot.currentMapId,
                      forest.id,
                      reason: 'The natural first forest trainer battle must finish without defeat recovery.',
                    );
                    if (!game.gameStateSnapshot.storyFlags.activeFlags.contains(
                      'trainer_defeated:source-pbs-7843b6cf472f11e81123cb09',
                    )) {
                      final rick = (await authoredMap(forest.id)).entities
                          .singleWhere(
                            (entity) =>
                                entity.id == 'ac13_ca05f16a5a7a06354bc5aa1f',
                          );
                      final position =
                          game.debugMapEntityPosition(rick.id) ?? rick.pos;
                      await walkTo(GridPos(x: position.x - 1, y: position.y));
                      await step(RuntimeInputControl.right);
                      expect(
                        game
                            .overworldInteractionSnapshot
                            .primaryAction
                            ?.request
                            .targetId,
                        rick.id,
                      );
                      press(RuntimeInputControl.primary);
                      await until(
                        () =>
                            idle() &&
                            game.gameStateSnapshot.storyFlags.activeFlags
                                .contains(
                                  'trainer_defeated:source-pbs-7843b6cf472f11e81123cb09',
                                ),
                        'genuine first forest trainer battle',
                      );
                    }
                    expect(
                      game.gameStateSnapshot.storyFlags.activeFlags,
                      contains(
                        'trainer_defeated:source-pbs-7843b6cf472f11e81123cb09',
                      ),
                    );
                    expect(
                      battleOutcomes.last['trainerId'],
                      'source-pbs-7843b6cf472f11e81123cb09',
                    );
                    expect(battleOutcomes.last['victory'], isTrue);
                    checkpoint('first_forest_trainer_won');
                    expect(await game.saveGame(), isTrue);
                    await retainSave(
                      'first-forest-trainer-won',
                      (await repository.load())!,
                    );
                    currentStage = 'return_to_viridian_center';
                    await walkTo(const GridPos(x: 34, y: 63));
                    await step(RuntimeInputControl.down);
                    expect(game.gameStateSnapshot.currentMapId, gate.id);
                    await walkTo(const GridPos(x: 8, y: 12));
                    await step(RuntimeInputControl.down);
                    expect(
                      game.gameStateSnapshot.currentMapId,
                      routeTwoSouth.id,
                    );
                    await crossConnection(
                      MapConnectionDirection.south,
                      viridian.id,
                    );
                    await walkTo(const GridPos(x: 26, y: 27));
                    await step(RuntimeInputControl.up);
                    expect(game.gameStateSnapshot.currentMapId, center.id);
                    await walkTo(const GridPos(x: 9, y: 6));
                    await step(RuntimeInputControl.up);
                    expect(
                      game
                          .overworldInteractionSnapshot
                          .primaryAction
                          ?.request
                          .targetId,
                      (await authoredMap(center.id)).entities
                          .singleWhere((entity) => entity.name == 'Nurse')
                          .id,
                    );
                    press(RuntimeInputControl.primary);
                    await until(
                      idle,
                      'natural healing after the first forest trainer',
                    );
                    await expectFullyHealed();
                    checkpoint('first_forest_trainer_healed');
                    expect(await game.saveGame(), isTrue);
                    await retainSave(
                      'first-forest-trainer-healed',
                      (await repository.load())!,
                    );
                    await walkTo(const GridPos(x: 9, y: 10));
                    await step(RuntimeInputControl.down);
                    expect(game.gameStateSnapshot.currentMapId, viridian.id);
                    await crossConnection(
                      MapConnectionDirection.north,
                      routeTwoSouth.id,
                    );
                    await walkTo(const GridPos(x: 19, y: 52));
                    await step(RuntimeInputControl.up);
                    expect(game.gameStateSnapshot.currentMapId, gate.id);
                    await walkTo(const GridPos(x: 8, y: 4));
                    await step(RuntimeInputControl.up);
                    expect(game.gameStateSnapshot.currentMapId, forest.id);
                  }
                  currentStage = 'traverse_viridian_forest_after_healing';
                  if (game.gameStateSnapshot.currentMapId == forest.id) {
                    await walkTo(const GridPos(x: 10, y: 11));
                    await step(RuntimeInputControl.up);
                    expect(game.gameStateSnapshot.currentMapId, gate.id);
                  }
                  if (game.gameStateSnapshot.currentMapId == gate.id &&
                      game.debugPlayerGridPosition.x >= 20) {
                    await walkTo(const GridPos(x: 29, y: 4));
                    await step(RuntimeInputControl.up);
                    expect(
                      game.gameStateSnapshot.currentMapId,
                      routeTwoNorth.id,
                    );
                  }
                  if (game.gameStateSnapshot.currentMapId == routeTwoNorth.id) {
                    await crossConnection(
                      MapConnectionDirection.north,
                      pewter.id,
                    );
                  }
                  expect(game.gameStateSnapshot.currentMapId, pewter.id);
                  checkpoint('pewter_reached_naturally');
                  expect(await game.saveGame(), isTrue);
                  await retainSave('pewter', (await repository.load())!);
                  if (!stopAfterPewter) {
                    currentStage = 'heal_before_brock';
                    final pewterCenter = manifest.maps.singleWhere(
                      (map) => map.name == 'Pewter City Poké Center',
                    );
                    final centerDoor = (await authoredMap(pewter.id)).entities
                        .singleWhere(
                          (entity) => entity.name == 'Poké Center door',
                        );
                    await walkTo(
                      GridPos(
                        x: centerDoor.pos.x,
                        y: centerDoor.pos.y + centerDoor.size.height,
                      ),
                    );
                    await step(RuntimeInputControl.up);
                    expect(
                      game.gameStateSnapshot.currentMapId,
                      pewterCenter.id,
                    );
                    await walkTo(const GridPos(x: 9, y: 6));
                    await step(RuntimeInputControl.up);
                    expect(
                      game
                          .overworldInteractionSnapshot
                          .primaryAction
                          ?.request
                          .targetId,
                      (await authoredMap(pewterCenter.id)).entities
                          .singleWhere((entity) => entity.name == 'Nurse')
                          .id,
                    );
                    press(RuntimeInputControl.primary);
                    await until(idle, 'natural Pewter Pokemon Center healing');
                    await expectFullyHealed();
                    await walkTo(const GridPos(x: 9, y: 10));
                    await step(RuntimeInputControl.down);
                    expect(game.gameStateSnapshot.currentMapId, pewter.id);
                    if (stopAfterTraining ||
                        (trainBeforeBrock &&
                            game.gameStateSnapshot.party.members.single.level <
                                11)) {
                      trainingExperienceBefore = game
                          .gameStateSnapshot
                          .party
                          .members
                          .single
                          .experience;
                      int victories() => trainingVictories;
                      Future<void> returnToCenter() async {
                        currentStage = 'training_center_return';
                        await crossConnection(
                          MapConnectionDirection.north,
                          pewter.id,
                        );
                        await walkTo(
                          GridPos(
                            x: centerDoor.pos.x,
                            y: centerDoor.pos.y + centerDoor.size.height,
                          ),
                        );
                        await step(RuntimeInputControl.up);
                        expect(
                          game.gameStateSnapshot.currentMapId,
                          pewterCenter.id,
                        );
                        await walkTo(const GridPos(x: 9, y: 6));
                        await step(RuntimeInputControl.up);
                        expect(
                          game
                              .overworldInteractionSnapshot
                              .primaryAction
                              ?.request
                              .targetId,
                          (await authoredMap(pewterCenter.id)).entities
                              .singleWhere((entity) => entity.name == 'Nurse')
                              .id,
                        );
                        press(RuntimeInputControl.primary);
                        await until(
                          idle,
                          'native healing between bounded wild encounters',
                        );
                        await expectFullyHealed();
                        checkpoint('natural_training_center_healed');
                        expect(await game.saveGame(), isTrue);
                        await retainSave(
                          'training-healed-${victories()}',
                          (await repository.load())!,
                        );
                        await walkTo(const GridPos(x: 9, y: 10));
                        await step(RuntimeInputControl.down);
                        expect(game.gameStateSnapshot.currentMapId, pewter.id);
                      }

                      final trainingWatch = Stopwatch()..start();
                      currentStage = trainingStage;
                      await crossConnection(
                        MapConnectionDirection.south,
                        routeTwoNorth.id,
                      );
                      final (encounterCell, approachCell) =
                          await nearestEncounterPair();
                      await walkTo(encounterCell);
                      while (victories() < trainingVictoryLimit &&
                          game.gameStateSnapshot.party.members.single.level <
                              11 &&
                          trainingIterations < 512 &&
                          trainingWatch.elapsed < const Duration(minutes: 5)) {
                        trainingIterations++;
                        final state = game.gameStateSnapshot;
                        final caps = await loadRuntimePlayerServiceRecoveryCaps(
                          gameState: state,
                          projectRootDirectory: root,
                          pokemonConfig: manifest.pokemon,
                        );
                        if (state.party.members.single.currentHp * 2 <=
                            caps.maxHpByPartyIndex[0]!) {
                          await returnToCenter();
                          currentStage = trainingStage;
                          await crossConnection(
                            MapConnectionDirection.south,
                            routeTwoNorth.id,
                          );
                          await walkTo(encounterCell);
                        }
                        currentStage = trainingStage;
                        await walkTo(
                          game.debugPlayerGridPosition == encounterCell
                              ? approachCell
                              : encounterCell,
                        );
                      }
                      trainingExperienceAfter = game
                          .gameStateSnapshot
                          .party
                          .members
                          .single
                          .experience;
                      trainingWatch.stop();
                      trainingPhaseElapsedMs =
                          trainingWatch.elapsedMilliseconds;
                      expect(trainingPhaseElapsedMs, lessThanOrEqualTo(300000));
                      expect(victories() <= trainingVictoryLimit, isTrue);
                      expect(victories() > 0, isTrue);
                      expect(
                        trainingExperienceAfter,
                        greaterThan(trainingExperienceBefore!),
                      );
                      final finalReturnWatch = Stopwatch()..start();
                      await returnToCenter();
                      trainingFinalCenterReturnElapsedMs =
                          finalReturnWatch.elapsedMilliseconds;
                      if (trainBeforeBrock) {
                        expect(
                          game.gameStateSnapshot.party.members.single.level,
                          greaterThanOrEqualTo(11),
                        );
                      }
                      checkpoint('bounded_brock_training_completed');
                      expect(await game.saveGame(), isTrue);
                      await retainSave(
                        'brock-training-complete',
                        (await repository.load())!,
                      );
                    }
                    if (!stopAfterTraining) {
                      currentStage = 'enter_pewter_gym';
                      final gym = manifest.maps.singleWhere(
                        (map) => map.name == 'Pewter Gym',
                      );
                      await walkTo(const GridPos(x: 19, y: 23));
                      await step(RuntimeInputControl.up);
                      expect(game.gameStateSnapshot.currentMapId, gym.id);
                      final brock = (await authoredMap(gym.id)).entities
                          .singleWhere(
                            (entity) =>
                                entity.npc?.trainerId != null &&
                                manifest.trainers
                                        .singleWhere(
                                          (trainer) =>
                                              trainer.id ==
                                              entity.npc!.trainerId,
                                        )
                                        .name ==
                                    'Brock',
                          );
                      final trainer = manifest.trainers.singleWhere(
                        (trainer) => trainer.id == brock.npc!.trainerId,
                      );
                      expect(
                        trainer.team.map(
                          (member) => (member.speciesId, member.level),
                        ),
                        [('geodude', 12), ('onix', 14)],
                      );
                      expect(trainer.moneyReward, 1400);
                      final records = manifest.eventRegistry!.records
                          .map((record) => record.toJson())
                          .where((record) => record['state'] == 'configured')
                          .map(
                            (record) => Map<String, dynamic>.from(
                              record['definition'] as Map,
                            ),
                          )
                          .where(
                            (record) =>
                                (record['source'] as Map?)?['entityId'] ==
                                brock.id,
                          )
                          .toList();
                      expect(records, hasLength(2));
                      final battleScene = manifest.scenes
                          .where(
                            (scene) => records.any(
                              (record) => record['sceneId'] == scene.id,
                            ),
                          )
                          .singleWhere(
                            (scene) => scene.graph.nodes.any(
                              (node) => node.toJson()['kind'] == 'battle',
                            ),
                          );
                      final actions = battleScene.graph.nodes
                          .map((node) => node.toJson()['payload'] as Map)
                          .toList();
                      final badgeId =
                          actions
                                  .map((payload) => payload['consequence'])
                                  .whereType<Map>()
                                  .singleWhere(
                                    (consequence) =>
                                        consequence['kind'] == 'awardBadge',
                                  )['badgeId']
                              as String;
                      final reward = actions
                          .map((payload) => payload['interactiveCommand'])
                          .whereType<Map>()
                          .singleWhere(
                            (command) => command['kind'] == 'giveItem',
                          );
                      final itemId = reward['itemId'] as String;
                      expect(reward['quantity'], 1);
                      final catalog = await const RuntimeItemCatalogLoader()
                          .load(
                            projectRootDirectory: root,
                            pokemonConfig: manifest.pokemon,
                          );
                      expect(
                        catalog!.entries
                            .singleWhere((item) => item.id == itemId)
                            .displayName,
                        'TM100',
                      );
                      final avoidLiam = {
                        for (var x = 6; x <= 9; x++) GridPos(x: x, y: 10),
                      };
                      await walkTo(
                        const GridPos(x: 10, y: 9),
                        avoid: avoidLiam,
                      );
                      await walkTo(
                        GridPos(
                          x: brock.pos.x,
                          y: brock.pos.y + brock.size.height,
                        ),
                        avoid: avoidLiam,
                      );
                      await step(RuntimeInputControl.up);
                      expect(
                        game
                            .overworldInteractionSnapshot
                            .primaryAction
                            ?.request
                            .targetId,
                        brock.id,
                      );
                      currentStage = 'first_brock_badge';
                      final beforeBrock = game.gameStateSnapshot;
                      final itemsBefore = const BagOperations().quantityOf(
                        beforeBrock.bag,
                        itemId,
                      );
                      final counterBefore = value(':variable:30').intValue;
                      final battlesBefore = battleOutcomes.length;
                      expect(beforeBrock.trainerProfile.badgeIds, isEmpty);
                      expect(await game.saveGame(), isTrue);
                      await retainSave(
                        'before-brock',
                        (await repository.load())!,
                      );
                      press(RuntimeInputControl.primary);
                      await until(
                        () => idle() && battleOutcomes.length > battlesBefore,
                        'genuine Brock battle and source rewards',
                        limit: 36000,
                      );
                      final won = game.gameStateSnapshot;
                      expect(battleOutcomes.skip(battlesBefore), hasLength(1));
                      expect(battleOutcomes.last['trainerId'], trainer.id);
                      expect(battleOutcomes.last['victory'], isTrue);
                      expect(won.trainerProfile.badgeIds, [badgeId]);
                      expect(
                        won.trainerProfile.money,
                        beforeBrock.trainerProfile.money + 1400,
                      );
                      expect(
                        const BagOperations().quantityOf(won.bag, itemId),
                        itemsBefore + 1,
                      );
                      expect(value(':switch:51').boolValue, isTrue);
                      expect(value(':variable:30').intValue, counterBefore + 1);
                      expect(
                        won.completedBattleRequestIds.length,
                        beforeBrock.completedBattleRequestIds.length + 1,
                      );
                      expect(
                        won.storyFlags.activeFlags,
                        contains('trainer_defeated:${trainer.id}'),
                      );
                      final badge = manifest.badges.singleWhere(
                        (badge) => badge.id == badgeId,
                      );
                      if (badge.fieldAbilityUnlock != null) {
                        expect(
                          won.progression.unlockedFieldAbilities,
                          contains(badge.fieldAbilityUnlock),
                        );
                      }
                      checkpoint('first_brock_badge_obtained_naturally');
                      await step(RuntimeInputControl.up);
                      expect(
                        game
                            .overworldInteractionSnapshot
                            .primaryAction
                            ?.request
                            .targetId,
                        brock.id,
                      );
                      final firstRepeatDialogueTicks =
                          dialoguePresentationTicks;
                      press(RuntimeInputControl.primary);
                      await until(
                        () =>
                            idle() &&
                            dialoguePresentationTicks >
                                firstRepeatDialogueTicks,
                        'observed Brock repeat interaction after victory',
                      );
                      expect(battleOutcomes.length, battlesBefore + 1);
                      expect(
                        game.gameStateSnapshot.trainerProfile,
                        won.trainerProfile,
                      );
                      expect(game.gameStateSnapshot.bag, won.bag);
                      expect(
                        game.gameStateSnapshot.completedBattleRequestIds,
                        won.completedBattleRequestIds,
                      );
                      expect(value(':variable:30').intValue, counterBefore + 1);
                      expect(await game.saveGame(), isTrue);
                      final badgeSave = (await repository.load())!;
                      await retainSave('first-badge', badgeSave);
                      await mounted.close(tester);
                      mounted = null;
                      mounted = await mountConvertedSourceIntroGame(
                        tester,
                        projectFile,
                        manifest,
                        repository,
                        badgeSave,
                        loadActualPlayerServiceCaps: true,
                        restored: saveDataFromGameState(badgeSave),
                      );
                      game = mounted.game;
                      controller = mounted.controller;
                      await until(
                        idle,
                        'cold continue after first native badge',
                      );
                      expect(
                        game.gameStateSnapshot.currentMapId,
                        badgeSave.currentMapId,
                      );
                      expect(
                        game.gameStateSnapshot.playerPosition,
                        badgeSave.playerPosition,
                      );
                      expect(
                        game.gameStateSnapshot.playerFacing,
                        badgeSave.playerFacing,
                      );
                      expect(
                        game.gameStateSnapshot.trainerProfile,
                        badgeSave.trainerProfile,
                      );
                      expect(game.gameStateSnapshot.party, badgeSave.party);
                      expect(game.gameStateSnapshot.bag, badgeSave.bag);
                      expect(
                        game.gameStateSnapshot.narrativeFactRuntimeState,
                        badgeSave.narrativeFactRuntimeState,
                      );
                      expect(
                        game.gameStateSnapshot.completedBattleRequestIds,
                        badgeSave.completedBattleRequestIds,
                      );
                      expect(
                        game.gameStateSnapshot.progression.copyWith(
                          storyFlags: [],
                        ),
                        badgeSave.progression.copyWith(storyFlags: []),
                      );
                      expect(
                        game.gameStateSnapshot.progression.storyFlags.toSet(),
                        {
                          ...badgeSave.progression.storyFlags,
                          ...badgeSave.storyFlags.activeFlags,
                        },
                      );
                      expect(
                        game.gameStateSnapshot.storyFlags,
                        badgeSave.storyFlags,
                      );
                      expect(
                        PlayerRecoveryPoint.tryRead(game.gameStateSnapshot),
                        PlayerRecoveryPoint.tryRead(badgeSave),
                      );
                      await step(RuntimeInputControl.up);
                      expect(
                        game
                            .overworldInteractionSnapshot
                            .primaryAction
                            ?.request
                            .targetId,
                        brock.id,
                      );
                      final coldRepeatDialogueTicks = dialoguePresentationTicks;
                      press(RuntimeInputControl.primary);
                      await until(
                        () =>
                            idle() &&
                            dialoguePresentationTicks > coldRepeatDialogueTicks,
                        'observed Brock repeat interaction after cold continue',
                      );
                      expect(battleOutcomes.length, battlesBefore + 1);
                      expect(
                        game.gameStateSnapshot.trainerProfile,
                        badgeSave.trainerProfile,
                      );
                      expect(game.gameStateSnapshot.bag, badgeSave.bag);
                      expect(
                        game.gameStateSnapshot.completedBattleRequestIds,
                        badgeSave.completedBattleRequestIds,
                      );
                      expect(value(':variable:30').intValue, counterBefore + 1);
                      firstBadgeEvidence = {
                        'trainerId': trainer.id,
                        'sceneId': battleScene.id,
                        'badgeId': badgeId,
                        'itemId': itemId,
                        'itemQuantity': 1,
                        'moneyDelta': 1400,
                        'sourceCounterDelta': 1,
                        'battleVictory': true,
                        'replayInteractionObserved': true,
                        'replayRewardsUnchanged': true,
                        'coldSaveReloadAndReplay': true,
                        'coldReloadSameTesterProcess': true,
                        'newOsProcessQualified': false,
                      };
                      checkpoint('first_badge_cold_continued_and_replay_safe');
                    }
                  }
                }
              }
            }
          }
          await Future.wait(serviceCommands);
          final reachedFrontiers = checkpoints
              .map((row) => row['stage'])
              .toSet();
          if (stopAfterRival) {
            expect(reachedFrontiers, contains('source_first_rival_completed'));
          }
          if (stopAfterParcel) {
            expect(
              reachedFrontiers.any(
                (stage) =>
                    stage == 'parcel_delivery_cold_continued' ||
                    stage == 'resumed_after_natural_parcel_delivery',
              ),
              isTrue,
            );
          }
          if (stopAfterPewter) {
            expect(reachedFrontiers, contains('pewter_reached_naturally'));
          }
          if (stopAfterPreforest) {
            expect(
              reachedFrontiers,
              contains('bounded_preforest_preparation_completed'),
            );
            expect(preforestEvidence, isNotNull);
          }
          if (stopAfterTraining) {
            expect(
              reachedFrontiers,
              contains('bounded_brock_training_completed'),
            );
          }
          if (reachFirstBadge && (requestedStop == null || stopAfterBadge)) {
            expect(firstBadgeEvidence, isNotNull);
          }
          expect(await protectedProjectHashes(), beforeProjectHashes);
          if (output != null) {
            successfulResult = {
              'journeyComplete': true,
              'kind': 'genuineSourceCampaignPrefixJourney',
              'projectPath': root,
              'checkpoints': checkpoints,
              'movies': movies,
              'dialogues': dialogues,
              'modals': modalities,
              'nativeNewGameFlow': resumed == null,
              'identitySceneExecuted': resumed == null,
              'resumedNaturalSave': resumePath == null
                  ? null
                  : {'path': resumePath, 'sha256': resumeSha},
              'preforestPreparationRequired': prepareBeforeForest,
              'preforestPreparationEvidence': preforestEvidence,
              'requestedStop': stopAfterPreforest
                  ? 'preforest'
                  : stopAfterTraining
                  ? 'training'
                  : stopAfterRival
                  ? 'rival'
                  : stopAfterParcel
                  ? 'parcel'
                  : stopAfterPewter
                  ? 'pewter'
                  : reachFirstBadge
                  ? 'first-badge'
                  : continueToParcel
                  ? 'parcel'
                  : 'starter',
              'qaFlagsSeeded': false,
              'qaPartySeeded': false,
              'qaPositionSeeded': false,
              'movements': 'nativeKeyboardOnly',
              'savedAndColdContinued': true,
              'savedRecoveryPoint': {
                'mapId': PlayerRecoveryPoint.tryRead(saved)!.mapId,
                'position': PlayerRecoveryPoint.tryRead(saved)!.position
                    .toJson(),
                'facing': PlayerRecoveryPoint.tryRead(saved)!.facing.name,
              },
              'recoveryMarkerOutsideDefeat': recoveryMarker(saved).boolValue,
              'retainedSaves': retainedSaves,
              'starterSavePath': resumed == null ? retainedSavePath : null,
              'coldContinuedSavePath': retainedSavePath,
              'starterSaveSha256': resumed == null ? retainedSaveSha256 : null,
              'coldContinuedSaveSha256': retainedSaveSha256,
              'coldReloadReason': 'saveRestore',
              'parcelJourneyRequested': continueToParcel,
              'parcelJourneyQualified': continueToParcel && !stopAfterRival,
              'runtimeProcessId': pid,
              'firstBadgeJourneyQualified': firstBadgeEvidence != null,
              'newGameToFirstBadgeQualified':
                  firstBadgeEvidence != null && resumed == null,
              'firstBadgeEvidence': firstBadgeEvidence,
              'battleCommands': battleCommandCount,
              'dialoguePresentationTicksObserved': dialoguePresentationTicks,
              'brockSupportMoveSelectionsByEnemy': brockSupportChoices,
              'starterTrainedBeforeParcel': false,
              'trainingRecoveries': trainingRecoveries,
              'trainingWildVictories': trainingVictories,
              'trainingExperienceBefore': trainingExperienceBefore,
              'trainingExperienceAfter': trainingExperienceAfter,
              'trainingRequested': stopAfterTraining,
              'trainingBeforeBrockRequired': trainBeforeBrock,
              'trainingPerformed': trainingExperienceBefore != null,
              'trainingPhaseElapsedMs': trainingPhaseElapsedMs,
              'trainingPhaseBudgetMs': 300000,
              'trainingFinalCenterReturnElapsedMs':
                  trainingFinalCenterReturnElapsedMs,
              'trainingAlternationIterationLimit': 512,
              'trainingWildVictoryLimit': trainingVictoryLimit,
              'trainingTargetLevel': 11,
              'trainingTargetReached':
                  trainingExperienceBefore != null &&
                  game.gameStateSnapshot.party.members.single.level >= 11,
              'trainingIterations': trainingIterations,
              'trainingMovementCommands': trainingMovements,
              'routePolicy': 'dijkstraNonEncounter1Encounter101',
              'battleOutcomes': battleOutcomes,
              'battleChoices': battleChoices,
              'battleTurns': battleTurns,
              'projectManifestAnd383MapsUnchanged': true,
              'scriptsExecuted': 0,
              'aiCalls': 0,
              'defeatRecoveryQualified': false,
              'audibleOutputQualified': false,
              'studioVisualJourneyQualified': false,
            };
          }
        } catch (error, stack) {
          if (output != null) {
            Map<String, String>? failureSave;
            String? failureSaveError;
            try {
              if (mounted != null && await mounted.game.saveGame()) {
                final bytes = await File(repository.filePath).readAsBytes();
                final destination = '$output.failure.save.json';
                await File(destination).writeAsBytes(bytes, flush: true);
                expect(await File(destination).readAsBytes(), bytes);
                failureSave = {
                  'path': destination,
                  'sha256': crypto.sha256.convert(bytes).toString(),
                };
              }
            } catch (saveError) {
              failureSaveError = saveError.toString();
            }
            try {
              await File('$output.failure.json').writeAsString(
                jsonEncode({
                  'kind': 'genuineSourceCampaignJourneyFailure',
                  'runtimeProcessId': pid,
                  'publicFailureSave': failureSave,
                  'publicFailureSaveError': failureSaveError,
                  'projectPath': root,
                  'stage': currentStage,
                  'elapsedMs': watch.elapsedMilliseconds,
                  'error': error.toString(),
                  'stackTrace': stack.toString(),
                  'state': mounted?.game.gameStateSnapshot.toJson(),
                  'checkpoints': checkpoints,
                  'battleCommands': battleCommandCount,
                  'dialoguePresentationTicksObserved':
                      dialoguePresentationTicks,
                  'brockSupportMoveSelectionsByEnemy': brockSupportChoices,
                  'battleOutcomes': battleOutcomes,
                  'battleChoices': battleChoices,
                  'battleTurns': battleTurns,
                  'trainingRecoveries': trainingRecoveries,
                  'trainingWildVictories': trainingVictories,
                  'trainingExperienceBefore': trainingExperienceBefore,
                  'trainingExperienceAfter': trainingExperienceAfter,
                  'trainingIterations': trainingIterations,
                  'trainingMovementCommands': trainingMovements,
                  'qaFlagsSeeded': false,
                  'qaPartySeeded': false,
                  'qaPositionSeeded': false,
                  'journeyComplete': false,
                  'firstBadgeJourneyQualified': false,
                  'newGameToFirstBadgeQualified': false,
                  'firstBadgeEvidence': firstBadgeEvidence,
                }),
                flush: true,
              );
            } catch (diagnosticError) {
              stdout.writeln(
                jsonEncode({
                  'kind': 'campaignFailureReceiptWriteFailed',
                  'error': diagnosticError.toString(),
                  'originalFailure': error.toString(),
                }),
              );
            }
          }
          rethrow;
        } finally {
          await mounted?.close(tester);
          await directory.delete(recursive: true);
          expect(await protectedProjectHashes(), beforeProjectHashes);
        }
        if (output != null) {
          expect(successfulResult, isNotNull);
          successfulResult!['playerClosed'] = true;
          await File(output)
              .writeAsString(jsonEncode(successfulResult), flush: true);
        }
      });
    },
    skip: root == null,
    timeout: Timeout(
      Duration(
        minutes: stopAfterPreforest
            ? 11
            : stopAfterTraining && trainingVictoryLimit <= 2
            ? 3
            : stopAfterRival
            ? 3
            : stopAfterParcel ||
                  stopAfterPewter ||
                  stopAfterBadge ||
                  stopAfterTraining ||
                  stopAfterPreforest
            ? 5
            : reachFirstBadge
            ? 20
            : continueToParcel
            ? 40
            : 6,
      ),
    ),
  );
}

final class _NativeWildDefeatRecovered implements Exception {
  const _NativeWildDefeatRecovered();
}
