import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/application/resolve_dialogue.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart'
    show RuntimeMapBundleLoader;

const _mapId = 'qualified_outcome_map';
const _trainerId = 'qualified_outcome_trainer';
const _trainerBattleRefId = 'trainer:$_trainerId';
const _trainerDefeatedFlag = 'trainer_defeated:$_trainerId';
const _sceneVictoryProducerId = 'scene_qualified_victory_producer';
const _sharedOutcomeId = 'victory';

const _sceneConsumerFact = 'fact.qualified.scene_consumer';
const _battleConsumerFact = 'fact.qualified.battle_consumer';
const _legacyConsumerFact = 'fact.qualified.legacy_consumer';
const _legacyAsyncConsumerFact = 'fact.qualified.legacy_async_consumer';
const _legacySynchronousChildConsumerFact =
    'fact.qualified.legacy_synchronous_child_consumer';
const _legacyBattleConsumerFact = 'fact.qualified.legacy_battle_consumer';
const _legacyBattleAfterConsumerFact =
    'fact.qualified.legacy_battle_after_consumer';
const _legacyOverlapFirstConsumerFact =
    'fact.qualified.legacy_overlap_first_consumer';
const _legacyOverlapSecondConsumerFact =
    'fact.qualified.legacy_overlap_second_consumer';
const _legacyRawFirstOutcomeId = 'raw.first';
const _legacyRawSecondOutcomeId = 'raw.second';
const _legacySynchronousParentOutcomeId = 'raw.synchronous_parent';
const _legacySynchronousChildOutcomeId = 'synchronous.child';
const _legacySynchronousParentDeliveryId =
    'outd_019abcde-5170-7000-8000-000000000001';
const _legacySynchronousParentCausationId =
    'evx_019abcde-5170-7000-8000-000000000002';
const _legacySynchronousRootCorrelationId =
    'corr_019abcde-5170-7000-8000-000000000003';
const _legacySameSourceCycleMarkedFlag = 'legacy.same_source_cycle.marked';
const _legacySameSourceCycleCompletedFlag =
    'legacy.same_source_cycle.completed';
const _legacyInvalidBattleOutcomeId = 'raw.invalid_battle';
const _legacyScriptWarpOutcomeId = 'raw.script_warp';
const _legacyRawFirstDeliveryId = 'outd_019abcde-5180-7000-8000-000000000001';
const _legacyRawSecondDeliveryId = 'outd_019abcde-5180-7000-8000-000000000002';
const _legacyRawRootCorrelationId = 'corr_019abcde-5180-7000-8000-000000000003';
const _legacyInvalidBattleDeliveryId =
    'outd_019abcde-5180-7000-8000-000000000003';
const _legacyScriptWarpDeliveryId = 'outd_019abcde-5180-7000-8000-000000000004';
const _legacyRawFirstCompletedFlag = 'legacy.raw.first.completed';
const _legacyRawSecondCompletedFlag = 'legacy.raw.second.completed';
const _legacyProducerSeedFact = 'fact.legacy.producer.seed';
const _legacyProducerAfterFact = 'fact.legacy.producer.after_dialogue';
const _legacyMoveWarpCompletedFlag = 'legacy.move_warp.completed';
const _legacyFollowMoveWarpOutcomeId = 'raw.follow_move_warp';
const _legacyFollowMoveWarpChildOutcomeId = 'follow_move_warp.child';
const _legacyFollowMoveWarpDeliveryId =
    'outd_019abcde-5180-7000-8000-000000000006';
const _legacyFollowMoveWarpCompletedFlag = 'legacy.follow_move_warp.completed';
const _legacyFollowMoveWarpTargetMapId =
    'qualified_outcome_follow_move_warp_target';
const _legacyScriptWarpCompletedFlag = 'legacy.script_warp.completed';
const _legacyScriptWarpTargetMapId = 'qualified_outcome_script_warp_target';
const _legacyScriptFailureOutcomeId = 'raw.script_failure';
const _legacyScriptFailureDeliveryId =
    'outd_019abcde-5180-7000-8000-000000000005';
const _legacyScriptFailureCompletedFlag = 'legacy.script_failure.completed';
const _legacyChainedEffectCompletedFlag = 'legacy.chained_effect.completed';
const _legacyMoveReplacementFirstFlag = 'legacy.move_replace.first';
const _legacyMoveReplacementSecondFlag = 'legacy.move_replace.second';
const _legacyPlayerWarpCompletedFlag = 'legacy.player_warp.completed';
const _legacyPlayerWarpTargetMapId = 'qualified_outcome_player_warp_target';
const _legacyPhysicalWarpTargetMapId = 'qualified_outcome_physical_target';
const _legacyTransitionTargetMapId = 'qualified_outcome_transition_target';
const _hostedBattleConsumerFact = 'fact.hosted.battle_consumer';
const _hostedSceneConsumerFact = 'fact.hosted.scene_after_battle';
const _rollbackBattleConsumerFact = 'fact.hosted.rollback_must_not_dispatch';

const _battleStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame qualified outcome V2 integration', () {
    test(
      'keeps identical Scene/Battle outcome ids isolated and publishes '
      'standalone trainer outcome after write-back',
      () async {
        final sceneOutcome = NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: _sceneVictoryProducerId,
          outcomeId: _sharedOutcomeId,
        );
        final battleOutcome = NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.battle,
          producerId: _trainerBattleRefId,
          outcomeId: _sharedOutcomeId,
        );
        late PlayableMapGame game;
        int? hpObservedBeforeBattleOutcomePlanning;
        bool? trainerFlagObservedBeforeBattleOutcomePlanning;

        game = _game(
          project: _crossProducerProject(),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source !=
                NarrativeEventSourceRef.outcomeReceived(battleOutcome)) {
              return;
            }
            final state = game.gameStateSnapshot;
            hpObservedBeforeBattleOutcomePlanning =
                state.party.members.single.currentHp;
            trainerFlagObservedBeforeBattleOutcomePlanning =
                state.storyFlags.activeFlags.contains(_trainerDefeatedFlag);
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () => _factValue(game, _sceneConsumerFact) == true,
        );

        expect(_factValue(game, _sceneConsumerFact), isTrue);
        expect(
          _factValue(game, _battleConsumerFact),
          isNot(isTrue),
          reason: 'A Scene producer must not match the Battle producer even '
              'when both publish outcomeId="$_sharedOutcomeId".',
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(1),
        );

        game.debugApplyBattleOutcomeForTest(
          context: _trainerContext(),
          outcome: _victoryOutcome(playerCurrentHp: 4),
        );
        await _waitUntil(
          game,
          () => _factValue(game, _battleConsumerFact) == true,
        );

        final state = game.gameStateSnapshot;
        expect(hpObservedBeforeBattleOutcomePlanning, 4);
        expect(trainerFlagObservedBeforeBattleOutcomePlanning, isTrue);
        expect(state.party.members.single.currentHp, 4);
        expect(state.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
        expect(_factValue(game, _sceneConsumerFact), isTrue);
        expect(_factValue(game, _battleConsumerFact), isTrue);
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          hasLength(2),
        );
        expect(
          sceneOutcome,
          isNot(battleOutcome),
          reason: 'Producer kind/id are part of the structural identity.',
        );
      },
    );

    test(
      'root outcome reserves outbox authority before fire-and-forget enqueue',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        final game = _game(
          project: _crossProducerProject(),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              _factValue(game, _sceneConsumerFact) == true &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        game.debugApplyBattleOutcomeForTest(
          context: _trainerContext(),
          outcome: _victoryOutcome(playerCurrentHp: 4),
        );

        expect(game.debugIsNarrativeOutcomeWorkInFlight, isTrue);
        expect(gate.activity, NarrativeRuntimeActivity.outboxProcessing);
        expect(await game.saveGame(), isFalse);
        expect(repository.saveCount, 0);

        await _waitUntil(
          game,
          () =>
              _factValue(game, _battleConsumerFact) == true &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
        expect(
          repository.storedState!.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(2),
        );
      },
    );

    test(
      'defers a legacy Scenario emission then routes its qualified producer '
      'through the V2 outbox',
      () async {
        final game = _game(project: _legacyScenarioProject());

        await _load(game);
        await _waitUntil(
          game,
          () => _factValue(game, _legacyConsumerFact) == true,
        );

        final state = game.gameStateSnapshot;
        expect(
          state.storyFlags.activeFlags,
          contains(scenarioOutcomeFlagName('legacy.completed')),
        );
        expect(_factValue(game, _legacyConsumerFact), isTrue);
        expect(
          state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
          isEmpty,
        );
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          hasLength(1),
        );
      },
    );

    test(
      'inherits causation, correlation, and depth for a synchronous child '
      'emitted by the raw legacy fallback',
      () async {
        const parentDepth = 3;
        final childOutcome = NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.legacyScenario,
          producerId: 'legacy_synchronous_child_scenario',
          outcomeId: _legacySynchronousChildOutcomeId,
        );
        final childOccurrences = <NarrativeEventOccurrence>[];
        final childDeliveries = <NarrativeOutcomeDelivery>[];
        late PlayableMapGame game;
        game = _game(
          project: _legacySynchronousChildProject(),
          initialMapActivationReason: MapActivationReason.saveRestore,
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                NarrativeOutcomeDelivery(
                  deliveryId: _legacySynchronousParentDeliveryId,
                  outcome: NarrativeOutcomeRef(
                    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
                    producerId: 'raw_restore_fixture',
                    outcomeId: _legacySynchronousParentOutcomeId,
                  ),
                  causationExecutionId: _legacySynchronousParentCausationId,
                  rootCorrelationId: _legacySynchronousRootCorrelationId,
                  depth: parentDepth,
                  attemptCount: 0,
                ),
              ],
            ),
          ),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source !=
                NarrativeEventSourceRef.outcomeReceived(childOutcome)) {
              return;
            }
            childOccurrences.add(occurrence);
            childDeliveries.add(
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries
                  .singleWhere((delivery) => delivery.outcome == childOutcome),
            );
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () => _factValue(game, _legacySynchronousChildConsumerFact) == true,
        );

        expect(childOccurrences, hasLength(1));
        expect(
          childOccurrences.single.rootCorrelationId,
          _legacySynchronousRootCorrelationId,
        );
        expect(childOccurrences.single.depth, parentDepth + 1);
        expect(childDeliveries, hasLength(1));
        expect(
          childDeliveries.single.causationExecutionId,
          _legacySynchronousParentCausationId,
        );
        expect(
          childDeliveries.single.rootCorrelationId,
          _legacySynchronousRootCorrelationId,
        );
        expect(childDeliveries.single.depth, parentDepth + 1);
      },
    );

    test(
      'latches a synchronous completion when a valid Scenario cycle reuses '
      'the current runtime source',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final project = _legacySameSourceCycleProject();
        expect(() => ProjectValidator.validate(project), returnsNormally);
        final game = _game(
          project: project,
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacySameSourceCycleCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          containsAll(<String>[
            _legacySameSourceCycleMarkedFlag,
            _legacySameSourceCycleCompletedFlag,
          ]),
        );
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'keeps correlation and depth when a legacy Scenario emits after an '
      'awaited dialogue continuation',
      () async {
        final outcomeOccurrences = <NarrativeEventOccurrence>[];
        final game = _game(
          project: _legacyAsyncScenarioProject(),
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              outcomeOccurrences.add(occurrence);
            }
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () => _factValue(game, _legacyAsyncConsumerFact) == true,
        );

        expect(outcomeOccurrences, hasLength(2));
        expect(outcomeOccurrences[0].rootCorrelationId, isNotNull);
        expect(
          outcomeOccurrences[1].rootCorrelationId,
          outcomeOccurrences[0].rootCorrelationId,
        );
        expect(outcomeOccurrences.map((value) => value.depth), <int?>[0, 1]);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(2),
        );
      },
    );

    test(
      'keeps both outcomes from overlapping legacy system triggers',
      () async {
        const firstTriggerId = 'a_legacy_camera_trigger';
        const secondTriggerId = 'b_legacy_camera_trigger';
        final outcomeOccurrences = <NarrativeEventOccurrence>[];
        final game = _game(
          project: _legacyOverlappingTriggerOutcomeProject(),
          triggers: const <MapTrigger>[
            MapTrigger(
              id: secondTriggerId,
              name: 'Second legacy camera trigger',
              type: TriggerType.camera,
              area: MapRect(
                pos: GridPos(x: 1, y: 2),
                size: GridSize(width: 1, height: 1),
              ),
            ),
            MapTrigger(
              id: firstTriggerId,
              name: 'First legacy camera trigger',
              type: TriggerType.camera,
              area: MapRect(
                pos: GridPos(x: 1, y: 2),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              outcomeOccurrences.add(occurrence);
            }
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          ),
          isTrue,
        );
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.down),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              _factValue(game, _legacyOverlapFirstConsumerFact) == true &&
              _factValue(game, _legacyOverlapSecondConsumerFact) == true,
        );

        expect(outcomeOccurrences, hasLength(2));
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.source),
          <NarrativeEventSourceRef>[
            NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.legacyScenario,
                producerId: 'legacy_overlap_first_scenario',
                outcomeId: 'overlap.first',
              ),
            ),
            NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.legacyScenario,
                producerId: 'legacy_overlap_second_scenario',
                outcomeId: 'overlap.second',
              ),
            ),
          ],
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .pendingNarrativeOutcomeDeliveries,
          isEmpty,
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(2),
        );
      },
    );

    test(
      'commits a suspended raw legacy head but keeps the next FIFO delivery '
      'pending until its dialogue continuation completes',
      () async {
        final outcomeOccurrences = <NarrativeEventOccurrence>[];
        final game = _game(
          project: _legacyRawDialogueBarrierProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyRawFirstDeliveryId,
                  outcomeId: _legacyRawFirstOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              outcomeOccurrences.add(occurrence);
            }
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        final suspendedState = game.gameStateSnapshot;
        expect(
          suspendedState
              .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          {_legacyRawFirstDeliveryId},
          reason: 'The raw parent is committed before its continuation.',
        );
        expect(
          suspendedState
              .narrativeEventProgress.pendingNarrativeOutcomeDeliveries
              .map((delivery) => delivery.deliveryId),
          [_legacyRawSecondDeliveryId],
        );
        expect(outcomeOccurrences, hasLength(1));
        expect(
          suspendedState.storyFlags.activeFlags,
          isNot(contains(_legacyRawSecondCompletedFlag)),
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries.isEmpty &&
              game.gameStateSnapshot.narrativeEventProgress
                      .deliveredNarrativeOutcomeDeliveryIds.length ==
                  2 &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        final completedState = game.gameStateSnapshot;
        expect(outcomeOccurrences, hasLength(2));
        expect(
          completedState.storyFlags.activeFlags,
          containsAll(<String>[
            _legacyRawFirstCompletedFlag,
            _legacyRawSecondCompletedFlag,
          ]),
        );
        expect(
          completedState
              .narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
          isEmpty,
        );
        expect(
          completedState
              .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          {_legacyRawFirstDeliveryId, _legacyRawSecondDeliveryId},
        );
      },
    );

    test(
      'keeps save and load checkpoints blocked for the complete suspended '
      'Scenario continuation lifetime',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        final game = _game(
          project: _legacyRawDialogueBarrierProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyRawFirstDeliveryId,
                  outcomeId: _legacyRawFirstOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(gate.activity, NarrativeRuntimeActivity.sceneSuspended);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(repository.saveCount, 0);
        expect(repository.loadCount, 0);
        expect(gate.activity, NarrativeRuntimeActivity.sceneSuspended);

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags.contains(
                _legacyRawFirstCompletedFlag,
              ) &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
      },
    );

    test(
      'finishes restored raw continuation and FIFO before preparing mapEnter',
      () async {
        var mapEnterPreparationCount = 0;
        Set<String>? deliveredAtMapEnter;
        List<String>? pendingAtMapEnter;
        Set<String>? flagsAtMapEnter;
        late PlayableMapGame game;
        game = _game(
          project: _legacyRawDialogueBarrierProject(),
          initialMapActivationReason: MapActivationReason.saveRestore,
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyRawFirstDeliveryId,
                  outcomeId: _legacyRawFirstOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source != NarrativeEventSourceRef.mapEnter(_mapId)) {
              return;
            }
            mapEnterPreparationCount++;
            final state = game.gameStateSnapshot;
            deliveredAtMapEnter = state
                .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds;
            pendingAtMapEnter = state
                .narrativeEventProgress.pendingNarrativeOutcomeDeliveries
                .map((delivery) => delivery.deliveryId)
                .toList(growable: false);
            flagsAtMapEnter = state.storyFlags.activeFlags;
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        expect(mapEnterPreparationCount, 0);
        expect(game.debugIsMapActivationDispatchInFlight, isTrue);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          {_legacyRawFirstDeliveryId},
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .pendingNarrativeOutcomeDeliveries
              .map((delivery) => delivery.deliveryId),
          [_legacyRawSecondDeliveryId],
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              mapEnterPreparationCount == 1 &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(deliveredAtMapEnter, {
          _legacyRawFirstDeliveryId,
          _legacyRawSecondDeliveryId,
        });
        expect(pendingAtMapEnter, isEmpty);
        expect(
            flagsAtMapEnter,
            containsAll(<String>[
              _legacyRawFirstCompletedFlag,
              _legacyRawSecondCompletedFlag,
            ]));
      },
    );

    test(
      'keeps an emit-before-dialogue producer head pending and reuses its '
      'root correlation after the continuation',
      () async {
        final outcomeOccurrences = <NarrativeEventOccurrence>[];
        final game = _game(
          project: _legacySuspendedProducerProject(),
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              outcomeOccurrences.add(occurrence);
            }
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        final suspendedState = game.gameStateSnapshot;
        expect(
          suspendedState
              .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          isEmpty,
        );
        expect(
          suspendedState
              .narrativeEventProgress.pendingNarrativeOutcomeDeliveries
              .map((delivery) => delivery.outcome.outcomeId),
          ['producer.seed'],
        );
        expect(outcomeOccurrences, isEmpty);

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              _factValue(game, _legacyProducerSeedFact) == true &&
              _factValue(game, _legacyProducerAfterFact) == true,
        );

        expect(outcomeOccurrences, hasLength(2));
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.rootCorrelationId),
          everyElement(outcomeOccurrences.first.rootCorrelationId),
        );
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.depth),
          <int?>[0, 0],
        );
      },
    );

    test(
      'carries the raw outcome owner through a Scenario runScript warp before '
      'resuming and releasing the continuation lease',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final project = _legacyScriptWarpProject();
        final game = _game(
          project: project,
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyScriptWarpDeliveryId,
                  outcomeId: _legacyScriptWarpOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          narrativeRuntimeActivityGate: gate,
          initialMapActivationReason: MapActivationReason.saveRestore,
          runtimeMapBundleLoader: ({
            required projectFilePath,
            required mapId,
          }) async {
            expect(mapId, _legacyScriptWarpTargetMapId);
            return RuntimeMapBundle(
              manifest: project,
              map: _scriptWarpTargetMap(),
              projectRootDirectory: '/tmp/qualified_outcome_v2',
              tilesetAbsolutePathsById: const <String, String>{},
            );
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              gate.activity == NarrativeRuntimeActivity.sceneSuspended &&
              game.debugHasPendingMapTransition &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              game.debugIsMapActivationDispatchInFlight,
        );

        final suspendedProgress = game.gameStateSnapshot.narrativeEventProgress;
        expect(
          suspendedProgress.deliveredNarrativeOutcomeDeliveryIds,
          {_legacyScriptWarpDeliveryId},
        );
        expect(
          suspendedProgress.pendingNarrativeOutcomeDeliveries
              .map((delivery) => delivery.deliveryId),
          [_legacyRawSecondDeliveryId],
        );
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyScriptWarpCompletedFlag)),
        );

        await _waitUntil(
          game,
          () =>
              game.debugLastCompletedMapActivation?.mapId ==
                  _legacyScriptWarpTargetMapId &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyScriptWarpCompletedFlag) &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyRawSecondCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 600,
        );

        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .pendingNarrativeOutcomeDeliveries,
          isEmpty,
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          {_legacyScriptWarpDeliveryId, _legacyRawSecondDeliveryId},
        );
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'releases the continuation lease and drains the FIFO after a Scenario '
      'dialogue load failure',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyRawDialogueBarrierProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyRawFirstDeliveryId,
                  outcomeId: _legacyRawFirstOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) async => null,
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries.isEmpty &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        final state = game.gameStateSnapshot;
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          {_legacyRawFirstDeliveryId, _legacyRawSecondDeliveryId},
        );
        expect(
          state.storyFlags.activeFlags,
          isNot(contains(_legacyRawFirstCompletedFlag)),
        );
        expect(
          state.storyFlags.activeFlags,
          contains(_legacyRawSecondCompletedFlag),
        );
      },
    );

    test(
      'releases Scenario dialogue ownership after a synchronous loader '
      'exception and keeps checkpoints available',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        final game = _game(
          project: _legacyRawDialogueBarrierProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyRawFirstDeliveryId,
                  outcomeId: _legacyRawFirstOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) {
            throw StateError('synchronous Scenario dialogue load failed');
          },
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries.isEmpty &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        final state = game.gameStateSnapshot;
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          {_legacyRawFirstDeliveryId, _legacyRawSecondDeliveryId},
        );
        expect(
          state.storyFlags.activeFlags,
          isNot(contains(_legacyRawFirstCompletedFlag)),
        );
        expect(
          state.storyFlags.activeFlags,
          contains(_legacyRawSecondCompletedFlag),
        );
        expect(await game.saveGame(), isTrue);
        expect(await game.loadGame(), isTrue);
        expect(repository.saveCount, 1);
        expect(repository.loadCount, 1);
      },
    );

    test(
      'keeps a Scenario script warp owner when the same step also triggers a '
      'different physical warp',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final project = _legacyWarpConflictProject();
        final game = _game(
          project: project,
          map: _warpConflictMap(),
          narrativeRuntimeActivityGate: gate,
          runtimeMapBundleLoader: ({
            required projectFilePath,
            required mapId,
          }) async {
            final targetMap = mapId == _legacyScriptWarpTargetMapId
                ? _scriptWarpTargetMap()
                : _physicalWarpTargetMap();
            return RuntimeMapBundle(
              manifest: project,
              map: targetMap,
              projectRootDirectory: '/tmp/qualified_outcome_v2',
              tilesetAbsolutePathsById: const <String, String>{},
            );
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () => !game.debugIsMapActivationDispatchInFlight,
        );
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          ),
          isTrue,
        );
        game.update(0.016);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.down),
          ),
          isTrue,
        );

        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.currentMapId ==
                  _legacyScriptWarpTargetMapId &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyScriptWarpCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 900,
        );

        expect(
          game.gameStateSnapshot.currentMapId,
          isNot(_legacyPhysicalWarpTargetMapId),
        );
      },
    );

    test(
      'does not adopt a pre-existing transition into an unrelated raw outcome '
      'continuation',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final project = _legacyTransitionOwnershipProject();
        final game = _game(
          project: project,
          map: _transitionOwnershipMap(),
          narrativeRuntimeActivityGate: gate,
          runtimeMapBundleLoader: ({
            required projectFilePath,
            required mapId,
          }) async {
            expect(mapId, _legacyTransitionTargetMapId);
            return RuntimeMapBundle(
              manifest: project,
              map: _transitionTargetMap(),
              projectRootDirectory: '/tmp/qualified_outcome_v2',
              tilesetAbsolutePathsById: const <String, String>{},
            );
          },
        );

        await _load(game);
        await _waitUntil(
          game,
          () => !game.debugIsMapActivationDispatchInFlight,
        );
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          ),
          isTrue,
        );
        game.update(0.016);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.down),
          ),
          isTrue,
        );
        await _waitUntilWithoutUpdate(
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyRawSecondCompletedFlag) &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        expect(game.debugHasPendingScenarioTransitionMap, isTrue);
        expect(
          game.debugPendingScenarioTransitionTargetMapId,
          _legacyTransitionTargetMapId,
        );
        expect(gate.activity, NarrativeRuntimeActivity.idle);

        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.currentMapId ==
              _legacyTransitionTargetMapId,
          maxTicks: 900,
        );
      },
    );

    for (final throwsFromCommand in <bool>[false, true]) {
      test(
        'terminalizes a Scenario runScript ${throwsFromCommand ? 'exception' : 'error result'} '
        'after dialogue without orphaning its continuation',
        () async {
          final gate = NarrativeRuntimeActivityGate();
          final game = _game(
            project: _legacyScriptFailureProject(
              throwsFromCommand: throwsFromCommand,
            ),
            initialState: _initialState().copyWith(
              narrativeEventProgress: NarrativeEventProgress(
                pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                  _rawLegacyDelivery(
                    deliveryId: _legacyScriptFailureDeliveryId,
                    outcomeId: _legacyScriptFailureOutcomeId,
                  ),
                  _rawLegacyDelivery(
                    deliveryId: _legacyRawSecondDeliveryId,
                    outcomeId: _legacyRawSecondOutcomeId,
                  ),
                ],
              ),
            ),
            dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
            narrativeRuntimeActivityGate: gate,
          );

          await _load(game);
          await _waitUntilWithoutUpdate(
            () =>
                game.debugFlowPhaseName == 'dialogue' &&
                !game.debugIsNarrativeOutcomeWorkInFlight,
          );

          expect(
            () => game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            returnsNormally,
          );
          await _waitUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isEmpty &&
                gate.activity == NarrativeRuntimeActivity.idle,
          );

          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            isNot(contains(_legacyScriptFailureCompletedFlag)),
          );
          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            contains(_legacyRawSecondCompletedFlag),
          );
          expect(game.debugNotificationText, 'Script interrompu');
        },
      );
    }

    for (final throwsFromCommand in <bool>[false, true]) {
      test(
        'terminalizes an initial Scenario runScript '
        '${throwsFromCommand ? 'exception' : 'error result'} before barrier '
        'registration without orphaning the FIFO',
        () async {
          final gate = NarrativeRuntimeActivityGate();
          final repository = _CheckpointCountingRepository(gate);
          final game = _game(
            project: _legacyImmediateScriptFailureProject(
              throwsFromCommand: throwsFromCommand,
            ),
            initialState: _initialState().copyWith(
              narrativeEventProgress: NarrativeEventProgress(
                pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                  _rawLegacyDelivery(
                    deliveryId: _legacyScriptFailureDeliveryId,
                    outcomeId: _legacyScriptFailureOutcomeId,
                  ),
                  _rawLegacyDelivery(
                    deliveryId: _legacyRawSecondDeliveryId,
                    outcomeId: _legacyRawSecondOutcomeId,
                  ),
                ],
              ),
            ),
            narrativeRuntimeActivityGate: gate,
            saveRepository: repository,
          );

          await _load(game);
          await _waitUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isEmpty &&
                gate.activity == NarrativeRuntimeActivity.idle,
          );

          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            isNot(contains(_legacyScriptFailureCompletedFlag)),
          );
          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            contains(_legacyRawSecondCompletedFlag),
          );
          expect(game.debugNotificationText, 'Script interrompu');
          expect(await game.saveGame(), isTrue);
          expect(await game.loadGame(), isTrue);
          expect(repository.saveCount, 1);
          expect(repository.loadCount, 1);
        },
      );
    }

    for (final scriptBehavior in <String>['end', 'error', 'exception']) {
      test(
        'transfers a dialogue continuation owner before a synchronous '
        'runScript $scriptBehavior completion',
        () async {
          final gate = NarrativeRuntimeActivityGate();
          final game = _game(
            project: _legacyDialogueThenScriptProject(
              scriptBehavior: scriptBehavior,
            ),
            initialState: _initialState().copyWith(
              narrativeEventProgress: NarrativeEventProgress(
                pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                  _rawLegacyDelivery(
                    deliveryId: _legacyScriptFailureDeliveryId,
                    outcomeId: _legacyScriptFailureOutcomeId,
                  ),
                  _rawLegacyDelivery(
                    deliveryId: _legacyRawSecondDeliveryId,
                    outcomeId: _legacyRawSecondOutcomeId,
                  ),
                ],
              ),
            ),
            dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
            narrativeRuntimeActivityGate: gate,
          );

          await _load(game);
          await _waitUntilWithoutUpdate(
            () =>
                game.debugFlowPhaseName == 'dialogue' &&
                !game.debugIsNarrativeOutcomeWorkInFlight,
          );

          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _waitUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isEmpty &&
                gate.activity == NarrativeRuntimeActivity.idle,
          );

          expect(
            game.gameStateSnapshot.storyFlags.activeFlags.contains(
              _legacyChainedEffectCompletedFlag,
            ),
            scriptBehavior == 'end',
          );
          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            contains(_legacyRawSecondCompletedFlag),
          );
        },
      );
    }

    for (final loaderThrows in <bool>[false, true]) {
      test(
        'transfers a dialogue continuation owner before the next dialogue '
        'loader ${loaderThrows ? 'throws' : 'returns null'}',
        () async {
          final gate = NarrativeRuntimeActivityGate();
          var loadCount = 0;
          final game = _game(
            project: _legacyDialogueThenDialogueProject(),
            initialState: _initialState().copyWith(
              narrativeEventProgress: NarrativeEventProgress(
                pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                  _rawLegacyDelivery(
                    deliveryId: _legacyScriptFailureDeliveryId,
                    outcomeId: _legacyScriptFailureOutcomeId,
                  ),
                  _rawLegacyDelivery(
                    deliveryId: _legacyRawSecondDeliveryId,
                    outcomeId: _legacyRawSecondOutcomeId,
                  ),
                ],
              ),
            ),
            dialogueSessionLoader: (_) {
              loadCount++;
              if (loadCount == 1) {
                return Future<DialogueSession?>.value(
                  _singleLineDialogueSession(),
                );
              }
              if (loaderThrows) {
                return Future<DialogueSession?>.error(
                  StateError('second dialogue load failed'),
                );
              }
              return Future<DialogueSession?>.value(null);
            },
            narrativeRuntimeActivityGate: gate,
          );

          await _load(game);
          await _waitUntilWithoutUpdate(
            () =>
                game.debugFlowPhaseName == 'dialogue' &&
                !game.debugIsNarrativeOutcomeWorkInFlight,
          );

          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _waitUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isEmpty &&
                gate.activity == NarrativeRuntimeActivity.idle,
          );

          expect(loadCount, 2);
          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            isNot(contains(_legacyChainedEffectCompletedFlag)),
          );
          expect(
            game.gameStateSnapshot.storyFlags.activeFlags,
            contains(_legacyRawSecondCompletedFlag),
          );
          expect(
            game.debugNotificationText,
            startsWith('Dialogue introuvable'),
          );
        },
      );
    }

    test(
      'transfers a dialogue continuation owner before the next dialogue '
      'loader throws synchronously',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        var loadCount = 0;
        final game = _game(
          project: _legacyDialogueThenDialogueProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyScriptFailureDeliveryId,
                  outcomeId: _legacyScriptFailureOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          dialogueSessionLoader: (_) {
            loadCount++;
            if (loadCount == 1) {
              return Future<DialogueSession?>.value(
                _singleLineDialogueSession(),
              );
            }
            throw StateError('second dialogue load failed synchronously');
          },
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugFlowPhaseName == 'dialogue' &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries.isEmpty &&
              gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(loadCount, 2);
        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyChainedEffectCompletedFlag)),
        );
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          contains(_legacyRawSecondCompletedFlag),
        );
        expect(
          game.debugNotificationText,
          startsWith('Dialogue introuvable'),
        );
        expect(await game.saveGame(), isTrue);
        expect(await game.loadGame(), isTrue);
        expect(repository.saveCount, 1);
        expect(repository.loadCount, 1);
      },
    );

    test(
      'closes a runScript continuation without adopting an unrelated pending '
      'Battle handoff',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final normalBattle = _trainerContext().request;
        final game = _game(
          project: _legacyScriptNoWarpProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyScriptFailureDeliveryId,
                  outcomeId: _legacyScriptFailureOutcomeId,
                ),
              ],
            ),
          ),
          narrativeRuntimeActivityGate: gate,
        );
        expect(
          game.debugTryEnqueueBattleRequestForTest(normalBattle),
          isTrue,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyScriptFailureCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(game.debugPendingBattleRequest, same(normalBattle));
        expect(game.debugHasPendingScenarioBattle, isFalse);
      },
    );

    test(
      'advances and releases a wait-for-completion move continuation when the '
      'NPC enters its target warp',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyMoveWarpProject(),
          map: _moveWarpMap(),
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 0),
          ),
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyMoveWarpCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 600,
        );

        expect(game.debugNpcGridPosition('moving_npc'), isNull);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'keeps a restored raw follow leader warp owned until the exact player '
      'handoff completes before continuation and FIFO',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        final project = _legacyFollowMoveWarpProject();
        final outcomeOrder = <String>[];
        final outcomeCorrelations = <String?>[];
        final outcomeDepths = <int?>[];
        var targetMapEnterCount = 0;
        String? mapAtTargetMapEnter;
        GridPos? positionAtTargetMapEnter;
        Set<String>? flagsAtTargetMapEnter;
        List<String>? pendingAtTargetMapEnter;
        NarrativeRuntimeActivity? activityAtTargetMapEnter;
        late PlayableMapGame game;
        game = _game(
          project: project,
          map: _followMoveWarpSourceMap(),
          initialMapActivationReason: MapActivationReason.saveRestore,
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 1),
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyFollowMoveWarpDeliveryId,
                  outcomeId: _legacyFollowMoveWarpOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          runtimeMapBundleLoader: ({
            required projectFilePath,
            required mapId,
          }) async {
            expect(mapId, _legacyFollowMoveWarpTargetMapId);
            return RuntimeMapBundle(
              manifest: project,
              map: _followMoveWarpTargetMap(),
              projectRootDirectory: '/tmp/qualified_outcome_v2',
              tilesetAbsolutePathsById: const <String, String>{},
            );
          },
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              occurrence.source.when<void>(
                entityInteract: (_, __) {},
                triggerEnter: (_, __) {},
                mapEnter: (_) {},
                outcomeReceived: (outcome) {
                  outcomeOrder.add(outcome.outcomeId);
                  outcomeCorrelations.add(occurrence.rootCorrelationId);
                  outcomeDepths.add(occurrence.depth);
                },
              );
            }
            if (occurrence.source !=
                NarrativeEventSourceRef.mapEnter(
                  _legacyFollowMoveWarpTargetMapId,
                )) {
              return;
            }
            targetMapEnterCount++;
            final state = game.gameStateSnapshot;
            mapAtTargetMapEnter = state.currentMapId;
            positionAtTargetMapEnter = state.playerPosition;
            flagsAtTargetMapEnter = state.storyFlags.activeFlags;
            pendingAtTargetMapEnter = state
                .narrativeEventProgress.pendingNarrativeOutcomeDeliveries
                .map((delivery) => delivery.deliveryId)
                .toList(growable: false);
            activityAtTargetMapEnter = gate.activity;
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              gate.activity == NarrativeRuntimeActivity.sceneSuspended &&
              game.debugIsMapActivationDispatchInFlight,
        );

        expect(await game.loadGame(), isFalse);
        expect(repository.loadCount, 0);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyFollowMoveWarpCompletedFlag)),
        );

        await _waitUntil(
          game,
          () =>
              targetMapEnterCount == 1 &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyFollowMoveWarpCompletedFlag) &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyRawSecondCompletedFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 900,
        );

        expect(mapAtTargetMapEnter, _legacyFollowMoveWarpTargetMapId);
        expect(positionAtTargetMapEnter, const GridPos(x: 2, y: 1));
        expect(
          flagsAtTargetMapEnter,
          isNot(contains(_legacyFollowMoveWarpCompletedFlag)),
          reason: 'The Scenario continuation must wait for the owned warp.',
        );
        expect(
          flagsAtTargetMapEnter,
          isNot(contains(_legacyRawSecondCompletedFlag)),
          reason: 'The next FIFO head must not overtake the owner.',
        );
        expect(
          pendingAtTargetMapEnter,
          [_legacyRawSecondDeliveryId],
        );
        expect(
          activityAtTargetMapEnter,
          NarrativeRuntimeActivity.dispatching,
          reason: 'The target mapEnter dispatch temporarily sits above the '
              'still-open Scenario suspension lease.',
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          containsAll(<String>{
            _legacyFollowMoveWarpDeliveryId,
            _legacyRawSecondDeliveryId,
          }),
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(3),
        );
        expect(
          outcomeOrder,
          [
            _legacyFollowMoveWarpOutcomeId,
            _legacyRawSecondOutcomeId,
            _legacyFollowMoveWarpChildOutcomeId,
          ],
        );
        expect(
          outcomeCorrelations,
          everyElement(_legacyRawRootCorrelationId),
        );
        expect(outcomeDepths, <int?>[0, 0, 1]);
        expect(
          game.gameStateSnapshot.currentMapId,
          _legacyFollowMoveWarpTargetMapId,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
        expect(game.debugHasPendingLeaderWarpHandoff, isFalse);
        expect(game.debugHasActiveScenarioFollow, isFalse);
      },
    );

    test(
      'preserves a wait-for-completion warp owner when an unreachable '
      'replacement is rejected',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyMoveWarpProject(),
          map: _moveWarpMap(),
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 0),
          ),
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              gate.activity == NarrativeRuntimeActivity.sceneSuspended &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        game.update(0.016);
        final forcedFailure = game.startScriptedNpcMove(
          entityId: 'moving_npc',
          destination: const GridPos(x: 99, y: 99),
        );
        expect(
          forcedFailure.state,
          ScriptedEntityMovementState.failed,
        );

        await _waitUntil(
          game,
          () =>
              gate.activity == NarrativeRuntimeActivity.idle &&
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyMoveWarpCompletedFlag),
          maxTicks: 600,
        );

        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          contains(_legacyMoveWarpCompletedFlag),
        );
        expect(game.debugNpcGridPosition('moving_npc'), isNull);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'current-cell replacement cancels the previous warp owner and stale '
      'movement task',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyMoveWarpProject(),
          map: _moveWarpMap(),
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 0),
          ),
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              gate.activity == NarrativeRuntimeActivity.sceneSuspended &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        final replacement = game.startScriptedNpcMove(
          entityId: 'moving_npc',
          destination: const GridPos(x: 1, y: 1),
        );
        expect(
          replacement.state,
          ScriptedEntityMovementState.completed,
        );

        await _waitUntil(
          game,
          () => gate.activity == NarrativeRuntimeActivity.idle,
        );
        for (var i = 0; i < 10; i++) {
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);
        }

        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyMoveWarpCompletedFlag)),
        );
        expect(
          game.debugNpcGridPosition('moving_npc'),
          const GridPos(x: 1, y: 1),
        );
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'cancels the first wait owner when a second move replaces the same entity',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyMoveReplacementProject(),
          map: _moveReplacementMap(),
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 0),
          ),
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntil(
          game,
          () => !game.debugIsMapActivationDispatchInFlight,
        );
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          ),
          isTrue,
        );
        game.update(0.016);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.down),
          ),
          isTrue,
        );

        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.storyFlags.activeFlags
                  .contains(_legacyMoveReplacementSecondFlag) &&
              gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 900,
        );

        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyMoveReplacementFirstFlag)),
        );
        expect(game.debugNpcGridPosition('moving_npc'), isNull);
      },
    );

    test(
      'cancels a player move-to-warp owner when its target map fails to load',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyPlayerMoveWarpProject(),
          map: _playerMoveWarpMap(),
          initialState: _initialState().copyWith(
            playerPosition: const GridPos(x: 0, y: 0),
          ),
          narrativeRuntimeActivityGate: gate,
          runtimeMapBundleLoader: ({
            required projectFilePath,
            required mapId,
          }) async {
            throw StateError('target loader failed for $mapId');
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              gate.activity == NarrativeRuntimeActivity.sceneSuspended &&
              !game.debugIsMapActivationDispatchInFlight,
        );
        await _waitUntil(
          game,
          () => gate.activity == NarrativeRuntimeActivity.idle,
          maxTicks: 900,
        );

        expect(game.gameStateSnapshot.currentMapId, _mapId);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyPlayerWarpCompletedFlag)),
        );
        expect(game.debugHasPendingMapTransition, isFalse);
      },
    );

    test(
      'does not orphan a continuation lease when an outcome-caused Battle '
      'handoff is invalid',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyInvalidBattleProject(),
          initialState: _initialState().copyWith(
            narrativeEventProgress: NarrativeEventProgress(
              pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
                _rawLegacyDelivery(
                  deliveryId: _legacyInvalidBattleDeliveryId,
                  outcomeId: _legacyInvalidBattleOutcomeId,
                ),
                _rawLegacyDelivery(
                  deliveryId: _legacyRawSecondDeliveryId,
                  outcomeId: _legacyRawSecondOutcomeId,
                ),
              ],
            ),
          ),
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntil(
          game,
          () =>
              game.gameStateSnapshot.narrativeEventProgress
                  .pendingNarrativeOutcomeDeliveries.isEmpty &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(game.debugHasPendingScenarioBattle, isFalse);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          {_legacyInvalidBattleDeliveryId, _legacyRawSecondDeliveryId},
        );
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          contains(_legacyRawSecondCompletedFlag),
        );
      },
    );

    test(
      'cancels an accepted Scenario Battle continuation when async setup '
      'fails',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyBattleContinuationProject(),
          includeTrainerNpc: true,
          narrativeRuntimeActivityGate: gate,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugHasPendingScenarioBattle &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );
        expect(gate.activity, NarrativeRuntimeActivity.sceneSuspended);

        game.update(0.016);
        expect(game.debugFlowPhaseName, 'battleTransition');
        await Future<void>.delayed(const Duration(milliseconds: 450));
        await _waitUntil(
          game,
          () => game.debugFlowPhaseName == 'overworld',
        );

        expect(game.debugHasPendingScenarioBattle, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains('battle:legacy_outcome_battle:victory')),
        );
        expect(
          _factValue(game, _legacyBattleAfterConsumerFact),
          isNot(isTrue),
        );
      },
    );

    test(
      'does not overwrite a normal pending Battle with a Scenario Battle',
      () async {
        final normalBattle = _trainerContext().request;
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          project: _legacyBattleContinuationProject(),
          includeTrainerNpc: true,
          narrativeRuntimeActivityGate: gate,
        );
        expect(
          game.debugTryEnqueueBattleRequestForTest(normalBattle),
          isTrue,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        expect(game.debugPendingBattleRequest, same(normalBattle));
        expect(game.debugHasPendingScenarioBattle, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'does not overwrite a pending Scenario Battle with an unrelated Battle',
      () async {
        final game = _game(
          project: _legacyBattleContinuationProject(),
          includeTrainerNpc: true,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugHasPendingScenarioBattle &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );
        final scenarioBattle = game.debugPendingBattleRequest!;
        final unrelatedBattle = _trainerContext().request;

        expect(
          game.debugTryEnqueueBattleRequestForTest(unrelatedBattle),
          isFalse,
        );
        expect(game.debugPendingBattleRequest, same(scenarioBattle));

        game.debugApplyBattleOutcomeForTest(
          context: RuntimeActiveBattleContext(
            request: scenarioBattle,
            playerPartyIndex: 0,
          ),
          outcome: _victoryOutcome(playerCurrentHp: 5),
        );
        await _waitUntil(
          game,
          () => game.gameStateSnapshot.storyFlags.activeFlags
              .contains('battle:legacy_outcome_battle:victory'),
        );
        expect(game.debugHasPendingScenarioBattle, isFalse);
      },
    );

    test(
      'publishes an outcome-caused Scenario Battle before its continuation '
      'with the inherited correlation and depth',
      () async {
        final battleOutcome = NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.battle,
          producerId: _trainerBattleRefId,
          outcomeId: 'victory',
        );
        final scenarioOutcome = NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.legacyScenario,
          producerId: 'legacy_outcome_battle_scenario',
          outcomeId: 'after.battle',
        );
        final outcomeOccurrences = <NarrativeEventOccurrence>[];
        final game = _game(
          project: _legacyBattleContinuationProject(),
          includeTrainerNpc: true,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.outcomeReceived) {
              outcomeOccurrences.add(occurrence);
            }
          },
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugHasPendingScenarioBattle &&
              !game.debugIsNarrativeOutcomeWorkInFlight &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(game.debugHasPendingScenarioBattle, isTrue);
        expect(outcomeOccurrences, hasLength(1));

        final scenarioBattleRequest = game.debugPendingBattleRequest!;
        game.debugApplyBattleOutcomeForTest(
          context: RuntimeActiveBattleContext(
            request: scenarioBattleRequest,
            playerPartyIndex: 0,
          ),
          outcome: _victoryOutcome(playerCurrentHp: 5),
        );
        await _waitUntil(
          game,
          () =>
              _factValue(game, _legacyBattleConsumerFact) == true &&
              _factValue(game, _legacyBattleAfterConsumerFact) == true,
        );

        expect(outcomeOccurrences, hasLength(3));
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.source),
          <NarrativeEventSourceRef>[
            NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.legacyScenario,
                producerId: 'legacy_async_seed_scenario',
                outcomeId: 'seed',
              ),
            ),
            NarrativeEventSourceRef.outcomeReceived(battleOutcome),
            NarrativeEventSourceRef.outcomeReceived(scenarioOutcome),
          ],
          reason: 'The qualified Battle outcome must enter the outbox before '
              'the resumed Scenario emission.',
        );
        final rootCorrelationId = outcomeOccurrences.first.rootCorrelationId;
        expect(rootCorrelationId, isNotNull);
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.rootCorrelationId),
          everyElement(rootCorrelationId),
        );
        expect(
          outcomeOccurrences.map((occurrence) => occurrence.depth),
          <int?>[0, 1, 1],
        );
        expect(_factValue(game, _legacyBattleConsumerFact), isTrue);
        expect(_factValue(game, _legacyBattleAfterConsumerFact), isTrue);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          hasLength(3),
        );
      },
    );

    test(
      'refuses a hosted Scene Battle while a normal Battle owns the queue '
      'then attributes only the normal Battle outcome',
      () async {
        final project = _hostedBattleProject();
        _expectScenesValid(project);
        final gate = NarrativeRuntimeActivityGate();
        final normalBattleContext = _trainerContext();
        final normalBattle = normalBattleContext.request;
        final game = _game(
          project: project,
          narrativeRuntimeActivityGate: gate,
        );
        expect(
          game.debugTryEnqueueBattleRequestForTest(normalBattle),
          isTrue,
        );

        await _load(game);
        await _waitUntilWithoutUpdate(
          () =>
              game.debugHasPendingSceneBattle ||
              (!game.debugIsMapActivationDispatchInFlight &&
                  !game.debugIsNarrativeOutcomeWorkInFlight &&
                  gate.activity == NarrativeRuntimeActivity.idle),
        );

        expect(game.debugHasPendingSceneBattle, isFalse);
        expect(game.debugHasPendingScenarioBattle, isFalse);
        expect(game.debugPendingBattleRequest, same(normalBattle));
        expect(game.debugFlowPhaseName, 'overworld');
        expect(_factValue(game, _hostedBattleConsumerFact), isNot(isTrue));
        expect(_factValue(game, _hostedSceneConsumerFact), isNot(isTrue));
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .deliveredNarrativeOutcomeDeliveryIds,
          isEmpty,
        );

        game.update(0.016);
        expect(game.debugPendingBattleRequest, isNull);
        expect(game.debugFlowPhaseName, 'battleTransition');

        game.debugApplyBattleOutcomeForTest(
          context: normalBattleContext,
          outcome: _victoryOutcome(playerCurrentHp: 6),
        );
        await _waitUntil(
          game,
          () =>
              _factValue(game, _hostedBattleConsumerFact) == true &&
              !game.debugIsNarrativeOutcomeWorkInFlight,
        );

        for (var i = 0; i < 3; i++) {
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);
        }
        final state = game.gameStateSnapshot;
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugPendingBattleRequest, isNull);
        expect(game.debugHasPendingSceneBattle, isFalse);
        expect(game.debugHasPendingScenarioBattle, isFalse);
        expect(_factValue(game, _hostedBattleConsumerFact), isTrue);
        expect(_factValue(game, _hostedSceneConsumerFact), isNot(isTrue));
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          hasLength(1),
          reason: 'Only the normal trainer Battle may publish an outcome; '
              'the refused Scene Battle must not be started or attributed.',
        );
      },
    );

    test(
      'cleans a V2 Scene dialogue after a synchronous loader exception and '
      'accepts a second launch',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        var loadCount = 0;
        final project = _sceneDialogueLoaderFailureProject();
        _expectScenesValid(project);
        final game = _game(
          project: project,
          dialogueSessionLoader: (_) {
            loadCount++;
            throw StateError('synchronous V2 Scene dialogue load failed');
          },
          narrativeRuntimeActivityGate: gate,
        );
        await _load(game);
        await _waitUntil(
          game,
          () => !game.debugIsMapActivationDispatchInFlight,
        );

        Future<NarrativeSceneExecutionResult> launch(String executionId) {
          return game.debugExecuteNarrativeSceneForTest(
            NarrativeSceneExecutionRequest(
              eventId: 'event_scene_dialogue_loader_failure',
              sceneId: 'scene_dialogue_loader_failure',
              executionId: executionId,
              gameState: game.gameStateSnapshot,
            ),
          );
        }

        final first = await launch('execution_first');

        expect(first, isA<NarrativeSceneExecutionFailed>());
        expect(loadCount, 1);
        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);

        final second = await launch('execution_second');

        expect(second, isA<NarrativeSceneExecutionFailed>());
        expect(loadCount, 2);
        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'cleans a V1 MapEvent Scene dialogue after a synchronous loader '
      'exception and accepts a second interaction',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        var loadCount = 0;
        final project = _sceneDialogueLoaderFailureProject();
        _expectScenesValid(project, map: _sceneDialogueMap());
        final game = _game(
          project: project,
          map: _sceneDialogueMap(),
          dialogueSessionLoader: (_) {
            loadCount++;
            throw StateError('synchronous V1 Scene dialogue load failed');
          },
          narrativeRuntimeActivityGate: gate,
        );
        await _load(game);
        await _waitUntil(
          game,
          () => !game.debugIsMapActivationDispatchInFlight,
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntilWithoutUpdate(
          () =>
              loadCount == 1 && gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
        await _waitUntilWithoutUpdate(
          () =>
              loadCount == 2 && gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugIsGameplayInputLocked, isFalse);
      },
    );

    test(
      'commits hosted Battle write-back and drains Battle outcome before the '
      'parent Scene outcome',
      () async {
        final project = _hostedBattleProject();
        _expectScenesValid(project);
        final game = _game(project: project);

        await _load(game);
        await _waitUntil(game, () => game.debugHasPendingSceneBattle);

        game.debugApplyBattleOutcomeForTest(
          context: _trainerContext(),
          outcome: _victoryOutcome(playerCurrentHp: 6),
        );
        await _waitUntil(
          game,
          () => _factValue(game, _hostedSceneConsumerFact) == true,
        );

        final state = game.gameStateSnapshot;
        expect(state.party.members.single.currentHp, 6);
        expect(state.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
        expect(_factValue(game, _hostedBattleConsumerFact), isTrue);
        expect(
          _factValue(game, _hostedSceneConsumerFact),
          isTrue,
          reason: 'The Scene outcome Event is conditioned on the fact written '
              'by the preceding hosted Battle outcome Event.',
        );
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          hasLength(2),
        );
      },
    );

    test(
      'discards hosted Battle working state and provisional outcome when the '
      'parent Scene fails',
      () async {
        final project = _hostedBattleRollbackProject();
        _expectScenesValid(project);
        final game = _game(
          project: project,
          dialogueSessionLoader: (_) async => null,
        );

        await _load(game);
        await _waitUntil(game, () => game.debugHasPendingSceneBattle);

        game.debugApplyBattleOutcomeForTest(
          context: _trainerContext(),
          outcome: _victoryOutcome(playerCurrentHp: 2),
        );
        await _waitUntil(
          game,
          () =>
              !game.debugIsMapActivationDispatchInFlight &&
              !game.debugHasPendingSceneBattle,
        );

        final state = game.gameStateSnapshot;
        expect(state.party.members.single.currentHp, 20);
        expect(
          state.storyFlags.activeFlags,
          isNot(contains(_trainerDefeatedFlag)),
        );
        expect(_factValue(game, _rollbackBattleConsumerFact), isNot(isTrue));
        expect(
          state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
          isEmpty,
        );
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          isEmpty,
        );
        expect(
          state.narrativeEventProgress.consumedNarrativeEventIds,
          isNot(contains('evt_019abcde-5200-7000-8000-000000000001')),
        );
      },
    );
  });
}

PlayableMapGame _game({
  required ProjectManifest project,
  bool includeTrainerNpc = false,
  List<MapTrigger> triggers = const <MapTrigger>[],
  MapData? map,
  GameState? initialState,
  Future<DialogueSession?> Function(ResolvedDialogue)? dialogueSessionLoader,
  Future<void> Function(NarrativeEventOccurrence occurrence)?
      beforeNarrativeAuthorityPreparation,
  NarrativeRuntimeActivityGate? narrativeRuntimeActivityGate,
  GameSaveRepository? saveRepository,
  RuntimeMapBundleLoader? runtimeMapBundleLoader,
  MapActivationReason initialMapActivationReason =
      MapActivationReason.initialBoot,
}) {
  return _QualifiedOutcomeTestGame(
    bundle: RuntimeMapBundle(
      manifest: project,
      map: map ??
          _map(
            includeTrainerNpc: includeTrainerNpc,
            triggers: triggers,
          ),
      projectRootDirectory: '/tmp/qualified_outcome_v2',
      tilesetAbsolutePathsById: const <String, String>{},
    ),
    projectFilePath: '/tmp/qualified_outcome_v2/project.json',
    saveData: saveDataFromGameState(initialState ?? _initialState()),
    dialogueSessionLoader: dialogueSessionLoader,
    beforeNarrativeAuthorityPreparation: beforeNarrativeAuthorityPreparation,
    narrativeRuntimeActivityGate: narrativeRuntimeActivityGate,
    saveRepository: saveRepository,
    runtimeMapBundleLoader: runtimeMapBundleLoader,
    runtimePlayerPokemonProgressionCatalogLoader:
        _loadQualifiedOutcomeProgressionCatalogs,
    initialMapActivationReason: initialMapActivationReason,
  );
}

final class _QualifiedOutcomeTestGame extends PlayableMapGame {
  _QualifiedOutcomeTestGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.dialogueSessionLoader,
    super.beforeNarrativeAuthorityPreparation,
    super.narrativeRuntimeActivityGate,
    super.saveRepository,
    super.runtimeMapBundleLoader,
    super.runtimePlayerPokemonProgressionCatalogLoader,
    super.initialMapActivationReason,
  });

  @override
  bool get isLoaded => true;
}

Future<RuntimePlayerPokemonProgressionCatalogs>
    _loadQualifiedOutcomeProgressionCatalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  return const RuntimePlayerPokemonProgressionCatalogs(
    growthRateIdBySpeciesId: <String, String>{
      'sproutle': 'medium_slow',
    },
    maxPpByMoveId: <String, int>{
      'tackle': 35,
    },
  );
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
}

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 360,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  final state = game.gameStateSnapshot;
  fail(
    'Timed out waiting for the qualified outcome runtime condition: '
    'outcomeWork=${game.debugIsNarrativeOutcomeWorkInFlight} '
    'activationWork=${game.debugIsMapActivationDispatchInFlight} '
    'pending=${state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries} '
    'delivered=${state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds} '
    'facts=${state.narrativeFactRuntimeState.overridesByFactId}.',
  );
}

Future<void> _waitUntilWithoutUpdate(
  bool Function() done, {
  int maxTurns = 360,
}) async {
  for (var i = 0; i < maxTurns; i++) {
    if (done()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the asynchronous qualified outcome condition.');
}

bool? _factValue(PlayableMapGame game, String factId) =>
    game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId[factId];

void _expectScenesValid(ProjectManifest project, {MapData? map}) {
  for (final scene in project.scenes) {
    final report = diagnoseSceneAgainstProject(
      scene,
      project,
      mapsById: <String, MapData>{_mapId: map ?? _map()},
    );
    expect(
      report.hasErrors,
      isFalse,
      reason: report.diagnostics
          .map((diagnostic) => '${diagnostic.code.name}: ${diagnostic.message}')
          .join('\n'),
    );
  }
}

GameState _initialState() => const GameState(
      saveId: 'qualified-outcome-save',
      currentMapId: _mapId,
      playerPosition: GridPos(x: 1, y: 1),
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 5,
            knownMoveIds: <String>['tackle'],
            currentHp: 20,
          ),
        ],
      ),
    );

MapData _map({
  bool includeTrainerNpc = false,
  List<MapTrigger> triggers = const <MapTrigger>[],
}) =>
    MapData(
      id: _mapId,
      name: 'Qualified Outcome Map',
      size: const GridSize(width: 3, height: 3),
      layers: const <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        const MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
        if (includeTrainerNpc)
          const MapEntity(
            id: 'trainer_npc',
            name: 'Qualified Outcome Trainer',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 2),
            npc: MapEntityNpcData(
              displayName: 'Qualified Outcome Trainer',
              trainerId: _trainerId,
            ),
          ),
      ],
      triggers: triggers,
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _sceneDialogueMap() => const MapData(
      id: _mapId,
      name: 'Scene Dialogue Loader Failure Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      events: <MapEventDefinition>[
        MapEventDefinition(
          id: 'scene_dialogue_event',
          title: 'Scene Dialogue Event',
          position: EventPosition(layerId: 'objects', x: 1, y: 2),
          pages: <MapEventPage>[
            MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(
                sceneId: 'scene_dialogue_loader_failure',
              ),
            ),
          ],
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _moveWarpMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Move Warp Map',
      size: GridSize(width: 5, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
        MapEntity(
          id: 'moving_npc',
          name: 'Moving NPC',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(
            displayName: 'Moving NPC',
            characterId: 'moving_npc_character',
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'npc_exit',
          pos: GridPos(x: 4, y: 1),
          targetMapId: 'unused_npc_target',
          targetPos: GridPos(x: 0, y: 0),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _followMoveWarpSourceMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Follow Move Warp Source',
      size: GridSize(width: 8, height: 4),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
        MapEntity(
          id: 'moving_npc',
          name: 'Moving NPC',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 1),
          npc: MapEntityNpcData(
            displayName: 'Moving NPC',
            characterId: 'moving_npc_character',
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'leader_exit',
          pos: GridPos(x: 4, y: 1),
          targetMapId: _legacyFollowMoveWarpTargetMapId,
          targetPos: GridPos(x: 2, y: 1),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _followMoveWarpTargetMap() => const MapData(
      id: _legacyFollowMoveWarpTargetMapId,
      name: 'Qualified Outcome Follow Move Warp Target',
      size: GridSize(width: 6, height: 4),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'target_spawn',
          name: 'Target Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 2, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'target_spawn'),
    );

MapData _moveReplacementMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Move Replacement Map',
      size: GridSize(width: 6, height: 4),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
        MapEntity(
          id: 'moving_npc',
          name: 'Moving NPC',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(
            displayName: 'Moving NPC',
            characterId: 'moving_npc_character',
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'first_exit',
          pos: GridPos(x: 5, y: 1),
          targetMapId: 'unused_first_target',
          targetPos: GridPos(x: 0, y: 0),
        ),
        MapWarp(
          id: 'second_exit',
          pos: GridPos(x: 5, y: 2),
          targetMapId: 'unused_second_target',
          targetPos: GridPos(x: 0, y: 0),
        ),
      ],
      triggers: <MapTrigger>[
        MapTrigger(
          id: 'b_move_replacement',
          name: 'Second move replacement',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 0, y: 1),
            size: GridSize(width: 1, height: 1),
          ),
        ),
        MapTrigger(
          id: 'a_move_replacement',
          name: 'First move replacement',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 0, y: 1),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _playerMoveWarpMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Player Move Warp Map',
      size: GridSize(width: 5, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'player_exit',
          pos: GridPos(x: 4, y: 0),
          targetMapId: _legacyPlayerWarpTargetMapId,
          targetPos: GridPos(x: 1, y: 1),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _scriptWarpTargetMap() => const MapData(
      id: _legacyScriptWarpTargetMapId,
      name: 'Qualified Outcome Script Warp Target',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'target_spawn',
          name: 'Target Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'target_spawn'),
    );

MapData _warpConflictMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Warp Conflict Map',
      size: GridSize(width: 3, height: 4),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'physical_exit',
          pos: GridPos(x: 1, y: 2),
          targetMapId: _legacyPhysicalWarpTargetMapId,
          targetPos: GridPos(x: 1, y: 1),
        ),
      ],
      triggers: <MapTrigger>[
        MapTrigger(
          id: 'warp_conflict_trigger',
          name: 'Warp Conflict Trigger',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 1, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _physicalWarpTargetMap() => const MapData(
      id: _legacyPhysicalWarpTargetMapId,
      name: 'Qualified Outcome Physical Warp Target',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'target_spawn',
          name: 'Target Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'target_spawn'),
    );

MapData _transitionOwnershipMap() => const MapData(
      id: _mapId,
      name: 'Qualified Outcome Transition Ownership Map',
      size: GridSize(width: 3, height: 4),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      triggers: <MapTrigger>[
        MapTrigger(
          id: 'b_transition_outcome',
          name: 'Transition outcome producer',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 1, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
        MapTrigger(
          id: 'a_transition_owner',
          name: 'Independent transition owner',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 1, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
        MapTrigger(
          id: 'c_transition_rejected',
          name: 'Rejected concurrent transition',
          type: TriggerType.camera,
          area: MapRect(
            pos: GridPos(x: 1, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

MapData _transitionTargetMap() => const MapData(
      id: _legacyTransitionTargetMapId,
      name: 'Qualified Outcome Transition Target',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'target_spawn',
          name: 'Target Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'arrival',
          pos: GridPos(x: 1, y: 1),
          targetMapId: _mapId,
          targetPos: GridPos(x: 1, y: 1),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'target_spawn'),
    );

ProjectManifest _crossProducerProject() {
  final sceneOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.scene,
    producerId: _sceneVictoryProducerId,
    outcomeId: _sharedOutcomeId,
  );
  final battleOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.battle,
    producerId: _trainerBattleRefId,
    outcomeId: _sharedOutcomeId,
  );
  return _project(
    facts: const <String>[_sceneConsumerFact, _battleConsumerFact],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5000-7000-8000-000000000001',
        name: 'Produce Scene victory',
        source: NarrativeEventSourceRef.mapEnter(_mapId),
        sceneId: _sceneVictoryProducerId,
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5000-7000-8000-000000000002',
        name: 'Consume qualified Scene victory',
        source: NarrativeEventSourceRef.outcomeReceived(sceneOutcome),
        sceneId: 'scene_consume_scene_victory',
        order: 1,
      ),
      _record(
        id: 'evt_019abcde-5000-7000-8000-000000000003',
        name: 'Consume qualified Battle victory',
        source: NarrativeEventSourceRef.outcomeReceived(battleOutcome),
        sceneId: 'scene_consume_battle_victory',
        order: 2,
      ),
    ],
    scenes: <SceneAsset>[
      _outcomeScene(
        id: _sceneVictoryProducerId,
        outcomeId: _sharedOutcomeId,
      ),
      _factScene(
        id: 'scene_consume_scene_victory',
        factId: _sceneConsumerFact,
      ),
      _factScene(
        id: 'scene_consume_battle_victory',
        factId: _battleConsumerFact,
      ),
    ],
  );
}

ProjectManifest _legacyScenarioProject() {
  final legacyOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_map_enter_scenario',
    outcomeId: 'legacy.completed',
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[_legacyConsumerFact],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5100-7000-8000-000000000001',
        name: 'Consume qualified legacy outcome',
        source: NarrativeEventSourceRef.outcomeReceived(legacyOutcome),
        sceneId: 'scene_consume_legacy_outcome',
        order: 0,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_legacy_outcome',
        factId: _legacyConsumerFact,
      ),
    ],
    scenarios: <ScenarioAsset>[_legacyMapEnterScenario()],
  );
}

ProjectManifest _legacySynchronousChildProject() {
  final childOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_synchronous_child_scenario',
    outcomeId: _legacySynchronousChildOutcomeId,
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[_legacySynchronousChildConsumerFact],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5170-7000-8000-000000000004',
        name: 'Consume synchronous raw fallback child',
        source: NarrativeEventSourceRef.outcomeReceived(childOutcome),
        sceneId: 'scene_consume_synchronous_raw_fallback_child',
        order: 0,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_synchronous_raw_fallback_child',
        factId: _legacySynchronousChildConsumerFact,
      ),
    ],
    scenarios: const <ScenarioAsset>[
      ScenarioAsset(
        id: 'legacy_synchronous_child_scenario',
        name: 'Legacy synchronous child producer',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'source',
        declaredOutcomes: <String>[_legacySynchronousChildOutcomeId],
        nodes: <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
            binding: ScenarioNodeBinding(
              outcomeId: _legacySynchronousParentOutcomeId,
            ),
          ),
          ScenarioNode(
            id: 'emit',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionEmitOutcome,
            ),
            binding: ScenarioNodeBinding(
              outcomeId: _legacySynchronousChildOutcomeId,
            ),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(
            id: 'source_to_emit',
            fromNodeId: 'source',
            toNodeId: 'emit',
          ),
          ScenarioEdge(
            id: 'emit_to_end',
            fromNodeId: 'emit',
            toNodeId: 'end',
          ),
        ],
      ),
    ],
  );
}

ProjectManifest _legacySameSourceCycleProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: const <ScenarioAsset>[
      ScenarioAsset(
        id: 'legacy_same_source_cycle_scenario',
        name: 'Legacy same runtime source cycle',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
            binding: ScenarioNodeBinding(mapId: _mapId),
          ),
          ScenarioNode(
            id: 'run_script',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionRunScript),
            binding: ScenarioNodeBinding(scriptId: 'legacy_chain_script'),
          ),
          ScenarioNode(
            id: 'already_marked',
            type: ScenarioNodeType.condition,
            payload: ScenarioNodePayload(
              condition: ScriptCondition(
                type: ScriptConditionType.flagIsSet,
                params: <String, String>{
                  ScriptConditionParams.flagName:
                      _legacySameSourceCycleMarkedFlag,
                },
              ),
            ),
          ),
          ScenarioNode(
            id: 'mark_cycle',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(
              flagName: _legacySameSourceCycleMarkedFlag,
            ),
          ),
          ScenarioNode(
            id: 'complete_cycle',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(
              flagName: _legacySameSourceCycleCompletedFlag,
            ),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(
            id: 'source_to_script',
            fromNodeId: 'source',
            toNodeId: 'run_script',
          ),
          ScenarioEdge(
            id: 'script_to_condition',
            fromNodeId: 'run_script',
            toNodeId: 'already_marked',
          ),
          ScenarioEdge(
            id: 'condition_true_to_complete',
            fromNodeId: 'already_marked',
            toNodeId: 'complete_cycle',
            kind: ScenarioEdgeKind.trueBranch,
          ),
          ScenarioEdge(
            id: 'condition_false_to_mark',
            fromNodeId: 'already_marked',
            toNodeId: 'mark_cycle',
            kind: ScenarioEdgeKind.falseBranch,
          ),
          ScenarioEdge(
            id: 'mark_to_same_script',
            fromNodeId: 'mark_cycle',
            toNodeId: 'run_script',
          ),
          ScenarioEdge(
            id: 'complete_to_end',
            fromNodeId: 'complete_cycle',
            toNodeId: 'end',
          ),
        ],
      ),
    ],
    scripts: <ProjectScriptEntry>[
      _legacySynchronousScript(scriptBehavior: 'end'),
    ],
  );
}

ProjectManifest _legacyAsyncScenarioProject() {
  final legacyOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_async_outcome_scenario',
    outcomeId: 'after.dialogue',
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[_legacyAsyncConsumerFact],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5150-7000-8000-000000000002',
        name: 'Consume async qualified legacy outcome',
        source: NarrativeEventSourceRef.outcomeReceived(legacyOutcome),
        sceneId: 'scene_consume_async_legacy_outcome',
        order: 0,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_async_legacy_outcome',
        factId: _legacyAsyncConsumerFact,
      ),
    ],
    scenarios: <ScenarioAsset>[
      _legacyAsyncSeedScenario(),
      _legacyAsyncOutcomeScenario(),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_async_dialogue',
        name: 'Legacy async dialogue',
        relativePath: 'dialogues/legacy_async_dialogue.yarn',
      ),
    ],
  );
}

ProjectManifest _legacyOverlappingTriggerOutcomeProject() {
  final firstOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_overlap_first_scenario',
    outcomeId: 'overlap.first',
  );
  final secondOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_overlap_second_scenario',
    outcomeId: 'overlap.second',
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[
      _legacyOverlapFirstConsumerFact,
      _legacyOverlapSecondConsumerFact,
    ],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5160-7000-8000-000000000001',
        name: 'Consume first overlapping legacy outcome',
        source: NarrativeEventSourceRef.outcomeReceived(firstOutcome),
        sceneId: 'scene_consume_legacy_overlap_first',
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5160-7000-8000-000000000002',
        name: 'Consume second overlapping legacy outcome',
        source: NarrativeEventSourceRef.outcomeReceived(secondOutcome),
        sceneId: 'scene_consume_legacy_overlap_second',
        order: 1,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_legacy_overlap_first',
        factId: _legacyOverlapFirstConsumerFact,
      ),
      _factScene(
        id: 'scene_consume_legacy_overlap_second',
        factId: _legacyOverlapSecondConsumerFact,
      ),
    ],
    scenarios: <ScenarioAsset>[
      _legacyTriggerOutcomeScenario(
        scenarioId: 'legacy_overlap_first_scenario',
        triggerId: 'a_legacy_camera_trigger',
        outcomeId: 'overlap.first',
      ),
      _legacyTriggerOutcomeScenario(
        scenarioId: 'legacy_overlap_second_scenario',
        triggerId: 'b_legacy_camera_trigger',
        outcomeId: 'overlap.second',
      ),
    ],
  );
}

ProjectManifest _legacyRawDialogueBarrierProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyRawFirstDialogueScenario(),
      _legacyRawSecondScenario(),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_raw_first_dialogue',
        name: 'Legacy raw first dialogue',
        relativePath: 'dialogues/legacy_raw_first_dialogue.yarn',
      ),
    ],
  );
}

ProjectManifest _legacySuspendedProducerProject() {
  final seedOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_suspended_producer',
    outcomeId: 'producer.seed',
  );
  final afterOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_suspended_producer',
    outcomeId: 'producer.after_dialogue',
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[
      _legacyProducerSeedFact,
      _legacyProducerAfterFact,
    ],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5185-7000-8000-000000000001',
        name: 'Consume suspended producer seed',
        source: NarrativeEventSourceRef.outcomeReceived(seedOutcome),
        sceneId: 'scene_consume_suspended_producer_seed',
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5185-7000-8000-000000000002',
        name: 'Consume suspended producer continuation',
        source: NarrativeEventSourceRef.outcomeReceived(afterOutcome),
        sceneId: 'scene_consume_suspended_producer_after',
        order: 1,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_suspended_producer_seed',
        factId: _legacyProducerSeedFact,
      ),
      _factScene(
        id: 'scene_consume_suspended_producer_after',
        factId: _legacyProducerAfterFact,
      ),
    ],
    scenarios: <ScenarioAsset>[_legacySuspendedProducerScenario()],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_suspended_producer_dialogue',
        name: 'Legacy suspended producer dialogue',
        relativePath: 'dialogues/legacy_suspended_producer_dialogue.yarn',
      ),
    ],
  );
}

ProjectManifest _legacyMoveWarpProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[_legacyMoveWarpScenario()],
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'moving_npc_character',
        name: 'Moving NPC Character',
        tilesetId: 'missing_test_tileset',
        frameWidth: 2,
        frameHeight: 2,
      ),
    ],
  );
}

ProjectManifest _legacyFollowMoveWarpProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyFollowMoveWarpScenario(),
      _legacyRawSecondScenario(),
    ],
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'moving_npc_character',
        name: 'Moving NPC Character',
        tilesetId: 'missing_test_tileset',
        frameWidth: 2,
        frameHeight: 2,
      ),
    ],
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Qualified Outcome Follow Move Warp Source',
        relativePath: 'maps/qualified_outcome_map.json',
      ),
      ProjectMapEntry(
        id: _legacyFollowMoveWarpTargetMapId,
        name: 'Qualified Outcome Follow Move Warp Target',
        relativePath: 'maps/qualified_outcome_follow_move_warp_target.json',
      ),
    ],
  );
}

ProjectManifest _legacyMoveReplacementProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyMoveReplacementScenario(
        id: 'legacy_move_replacement_first',
        triggerId: 'a_move_replacement',
        warpId: 'first_exit',
        completedFlag: _legacyMoveReplacementFirstFlag,
      ),
      _legacyMoveReplacementScenario(
        id: 'legacy_move_replacement_second',
        triggerId: 'b_move_replacement',
        warpId: 'second_exit',
        completedFlag: _legacyMoveReplacementSecondFlag,
      ),
    ],
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'moving_npc_character',
        name: 'Moving NPC Character',
        tilesetId: 'missing_test_tileset',
        frameWidth: 2,
        frameHeight: 2,
      ),
    ],
  );
}

ProjectManifest _legacyPlayerMoveWarpProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[_legacyPlayerMoveWarpScenario()],
  );
}

ProjectManifest _legacyScriptWarpProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyScriptWarpScenario(),
      _legacyRawSecondScenario(),
    ],
    scripts: <ProjectScriptEntry>[_legacyWarpScript()],
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Qualified Outcome Map',
        relativePath: 'maps/qualified_outcome_map.json',
      ),
      ProjectMapEntry(
        id: _legacyScriptWarpTargetMapId,
        name: 'Qualified Outcome Script Warp Target',
        relativePath: 'maps/qualified_outcome_script_warp_target.json',
      ),
    ],
  );
}

ProjectManifest _legacyWarpConflictProject() {
  return _project(
    mode: EventSystemMode.legacyOnly,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[_legacyWarpConflictScenario()],
    scripts: <ProjectScriptEntry>[_legacyWarpScript()],
  );
}

ProjectManifest _legacyTransitionOwnershipProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyIndependentTransitionScenario(),
      _legacyRejectedTransitionScenario(),
      _legacyTriggerOutcomeScenario(
        scenarioId: 'legacy_transition_outcome_producer',
        triggerId: 'b_transition_outcome',
        outcomeId: _legacyRawSecondOutcomeId,
      ),
      _legacyRawSecondScenario(),
    ],
  );
}

ProjectManifest _legacyScriptFailureProject({
  required bool throwsFromCommand,
}) {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyScriptFailureScenario(),
      _legacyRawSecondScenario(),
    ],
    scripts: <ProjectScriptEntry>[
      _legacyFailureScript(throwsFromCommand: throwsFromCommand),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_script_failure_dialogue',
        name: 'Legacy Script Failure Dialogue',
        relativePath: 'dialogues/script_failure.yarn',
      ),
    ],
  );
}

ProjectManifest _legacyImmediateScriptFailureProject({
  required bool throwsFromCommand,
}) {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyScriptFailureScenario(),
      _legacyRawSecondScenario(),
    ],
    scripts: <ProjectScriptEntry>[
      _legacyImmediateFailureScript(throwsFromCommand: throwsFromCommand),
    ],
  );
}

ProjectManifest _legacyDialogueThenScriptProject({
  required String scriptBehavior,
}) {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyDialogueThenScriptScenario(),
      _legacyRawSecondScenario(),
    ],
    scripts: <ProjectScriptEntry>[
      _legacySynchronousScript(scriptBehavior: scriptBehavior),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_chain_first_dialogue',
        name: 'Legacy chain first dialogue',
        relativePath: 'dialogues/chain_first.yarn',
      ),
    ],
  );
}

ProjectManifest _legacyDialogueThenDialogueProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyDialogueThenDialogueScenario(),
      _legacyRawSecondScenario(),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'legacy_chain_first_dialogue',
        name: 'Legacy chain first dialogue',
        relativePath: 'dialogues/chain_first.yarn',
      ),
      ProjectDialogueEntry(
        id: 'legacy_chain_second_dialogue',
        name: 'Legacy chain second dialogue',
        relativePath: 'dialogues/chain_second.yarn',
      ),
    ],
  );
}

ProjectManifest _legacyScriptNoWarpProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[_legacyScriptFailureScenario()],
    scripts: const <ProjectScriptEntry>[
      ProjectScriptEntry(
        id: 'legacy_failure_script',
        name: 'Legacy No-Warp Script',
        asset: ScriptAsset(
          id: 'legacy_failure_script',
          defaultStartNode: 'start',
          nodes: <ScriptNode>[
            ScriptNode(
              id: 'start',
              commands: <ScriptCommand>[
                ScriptCommand(type: ScriptCommandType.end),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _legacyInvalidBattleProject() {
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: const <SceneAsset>[],
    scenarios: <ScenarioAsset>[
      _legacyInvalidBattleScenario(),
      _legacyRawSecondScenario(),
    ],
  );
}

ProjectManifest _legacyBattleContinuationProject() {
  final battleOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.battle,
    producerId: _trainerBattleRefId,
    outcomeId: 'victory',
  );
  final scenarioOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: 'legacy_outcome_battle_scenario',
    outcomeId: 'after.battle',
  );
  return _project(
    mode: EventSystemMode.dualRead,
    facts: const <String>[
      _legacyBattleConsumerFact,
      _legacyBattleAfterConsumerFact,
    ],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5175-7000-8000-000000000001',
        name: 'Consume correlated legacy Scenario Battle outcome',
        source: NarrativeEventSourceRef.outcomeReceived(battleOutcome),
        sceneId: 'scene_consume_legacy_battle_outcome',
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5175-7000-8000-000000000002',
        name: 'Consume correlated post-Battle Scenario outcome',
        source: NarrativeEventSourceRef.outcomeReceived(scenarioOutcome),
        sceneId: 'scene_consume_legacy_battle_after',
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_legacyBattleConsumerFact, true),
        ],
        order: 1,
      ),
    ],
    scenes: <SceneAsset>[
      _factScene(
        id: 'scene_consume_legacy_battle_outcome',
        factId: _legacyBattleConsumerFact,
      ),
      _factScene(
        id: 'scene_consume_legacy_battle_after',
        factId: _legacyBattleAfterConsumerFact,
      ),
    ],
    scenarios: <ScenarioAsset>[
      _legacyAsyncSeedScenario(),
      _legacyOutcomeBattleScenario(),
    ],
  );
}

ProjectManifest _hostedBattleProject() {
  final battleOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.battle,
    producerId: _trainerBattleRefId,
    outcomeId: 'victory',
  );
  final sceneOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.scene,
    producerId: 'scene_hosted_battle_parent',
    outcomeId: 'scene.completed',
  );
  return _project(
    facts: const <String>[
      _hostedBattleConsumerFact,
      _hostedSceneConsumerFact,
    ],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5200-7000-8000-000000000011',
        name: 'Run hosted Battle parent Scene',
        source: NarrativeEventSourceRef.mapEnter(_mapId),
        sceneId: 'scene_hosted_battle_parent',
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5200-7000-8000-000000000012',
        name: 'Consume hosted Battle victory',
        source: NarrativeEventSourceRef.outcomeReceived(battleOutcome),
        sceneId: 'scene_consume_hosted_battle',
        order: 1,
      ),
      _record(
        id: 'evt_019abcde-5200-7000-8000-000000000013',
        name: 'Consume parent Scene outcome after Battle',
        source: NarrativeEventSourceRef.outcomeReceived(sceneOutcome),
        sceneId: 'scene_consume_hosted_parent',
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_hostedBattleConsumerFact, true),
        ],
        order: 2,
      ),
    ],
    scenes: <SceneAsset>[
      _hostedBattleScene(
        id: 'scene_hosted_battle_parent',
        sceneOutcomeId: 'scene.completed',
      ),
      _factScene(
        id: 'scene_consume_hosted_battle',
        factId: _hostedBattleConsumerFact,
      ),
      _factScene(
        id: 'scene_consume_hosted_parent',
        factId: _hostedSceneConsumerFact,
      ),
    ],
  );
}

ProjectManifest _hostedBattleRollbackProject() {
  final battleOutcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.battle,
    producerId: _trainerBattleRefId,
    outcomeId: 'victory',
  );
  return _project(
    facts: const <String>[_rollbackBattleConsumerFact],
    records: <NarrativeEventRecord>[
      _record(
        id: 'evt_019abcde-5200-7000-8000-000000000001',
        name: 'Run failing hosted Battle parent Scene',
        source: NarrativeEventSourceRef.mapEnter(_mapId),
        sceneId: 'scene_hosted_battle_rollback',
        order: 0,
      ),
      _record(
        id: 'evt_019abcde-5200-7000-8000-000000000002',
        name: 'Provisional Battle outcome must be discarded',
        source: NarrativeEventSourceRef.outcomeReceived(battleOutcome),
        sceneId: 'scene_rollback_battle_consumer',
        order: 1,
      ),
    ],
    scenes: <SceneAsset>[
      _hostedBattleScene(
        id: 'scene_hosted_battle_rollback',
        dialogueAfterVictoryId: 'missing_runtime_dialogue',
      ),
      _factScene(
        id: 'scene_rollback_battle_consumer',
        factId: _rollbackBattleConsumerFact,
      ),
    ],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'missing_runtime_dialogue',
        name: 'Authored but unavailable at runtime',
        relativePath: 'dialogues/missing_runtime_dialogue.yarn',
      ),
    ],
  );
}

ProjectManifest _sceneDialogueLoaderFailureProject() {
  return _project(
    facts: const <String>[],
    records: const <NarrativeEventRecord>[],
    scenes: <SceneAsset>[_sceneDialogueLoaderFailureScene()],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'scene_dialogue_loader_failure',
        name: 'Scene dialogue loader failure',
        relativePath: 'dialogues/scene_dialogue_loader_failure.yarn',
      ),
    ],
  );
}

ProjectManifest _project({
  required List<String> facts,
  required List<NarrativeEventRecord> records,
  required List<SceneAsset> scenes,
  EventSystemMode mode = EventSystemMode.v2Only,
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
  List<ProjectCharacterEntry> characters = const <ProjectCharacterEntry>[],
  List<ProjectScriptEntry> scripts = const <ProjectScriptEntry>[],
  List<ProjectMapEntry> maps = const <ProjectMapEntry>[
    ProjectMapEntry(
      id: _mapId,
      name: 'Qualified Outcome Map',
      relativePath: 'maps/qualified_outcome_map.json',
    ),
  ],
}) {
  return ProjectManifest(
    name: 'Qualified Outcome V2 Integration',
    maps: maps,
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: dialogues,
    characters: characters,
    scripts: scripts,
    scenarios: scenarios,
    facts: <NarrativeFactDefinition>[
      for (final factId in facts)
        NarrativeFactDefinition(id: factId, label: factId),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: mode,
      records: records,
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenes: scenes,
    trainers: const <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: _trainerId,
        name: 'Qualified Outcome Trainer',
        trainerClass: 'Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(speciesId: 'embercub', level: 5),
        ],
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

NarrativeEventRecord _record({
  required String id,
  required String name,
  required NarrativeEventSourceRef source,
  required String sceneId,
  required int order,
  List<NarrativeEventCondition> conditions = const <NarrativeEventCondition>[],
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: order,
    ),
    enabled: true,
  );
}

SceneAsset _outcomeScene({required String id, required String outcomeId}) {
  return SceneAsset(
    id: id,
    name: id,
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: outcomeId, label: outcomeId),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _factScene({required String id, required String factId}) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _sceneDialogueLoaderFailureScene() {
  return SceneAsset(
    id: 'scene_dialogue_loader_failure',
    name: 'Scene dialogue loader failure',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
            dialogueId: 'scene_dialogue_loader_failure',
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_dialogue',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'dialogue_to_end',
          fromNodeId: 'dialogue',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _hostedBattleScene({
  required String id,
  String? sceneOutcomeId,
  String? dialogueAfterVictoryId,
}) {
  final victoryTarget =
      dialogueAfterVictoryId == null ? 'victory_end' : 'dialogue';
  return SceneAsset(
    id: id,
    name: id,
    declaredOutcomes: <SceneOutcome>[
      if (sceneOutcomeId != null) ...<SceneOutcome>[
        SceneOutcome(id: sceneOutcomeId, label: sceneOutcomeId),
        SceneOutcome(id: 'scene.defeated', label: 'Scene defeated'),
      ],
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: _trainerId,
            npcEntityId: 'trainer_npc',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        if (dialogueAfterVictoryId != null)
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: dialogueAfterVictoryId,
            ),
          ),
        SceneNode(
          id: 'victory_end',
          kind: SceneNodeKind.end,
          payload: sceneOutcomeId == null
              ? null
              : SceneEndPayload(sceneOutcomeId: sceneOutcomeId),
        ),
        SceneNode(
          id: 'defeat_end',
          kind: SceneNodeKind.end,
          payload: sceneOutcomeId == null
              ? null
              : SceneEndPayload(sceneOutcomeId: 'scene.defeated'),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: victoryTarget,
          kind: SceneEdgeKind.battleVictory,
        ),
        if (dialogueAfterVictoryId != null)
          SceneEdge(
            id: 'dialogue_to_end',
            fromNodeId: 'dialogue',
            fromPortId: 'completed',
            toNodeId: 'victory_end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        SceneEdge(
          id: 'battle_defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}

ScenarioAsset _legacyMapEnterScenario() {
  return const ScenarioAsset(
    id: 'legacy_map_enter_scenario',
    name: 'Legacy mapEnter outcome producer',
    entryNodeId: 'source',
    declaredOutcomes: <String>['legacy.completed'],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _mapId),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'legacy.completed'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
          id: 'source_to_emit', fromNodeId: 'source', toNodeId: 'emit'),
      ScenarioEdge(id: 'emit_to_end', fromNodeId: 'emit', toNodeId: 'end'),
    ],
  );
}

ScenarioAsset _legacyTriggerOutcomeScenario({
  required String scenarioId,
  required String triggerId,
  required String outcomeId,
}) {
  return ScenarioAsset(
    id: scenarioId,
    name: scenarioId,
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    declaredOutcomes: <String>[outcomeId],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: const ScenarioNodePayload(
          actionKind: kScenarioSourceTriggerEnter,
        ),
        binding: ScenarioNodeBinding(
          mapId: _mapId,
          triggerId: triggerId,
        ),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        payload: const ScenarioNodePayload(
          actionKind: kScenarioActionEmitOutcome,
        ),
        binding: ScenarioNodeBinding(outcomeId: outcomeId),
      ),
      const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: const <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_emit',
        fromNodeId: 'source',
        toNodeId: 'emit',
      ),
      ScenarioEdge(
        id: 'emit_to_end',
        fromNodeId: 'emit',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyAsyncOutcomeScenario() {
  return const ScenarioAsset(
    id: 'legacy_async_outcome_scenario',
    name: 'Legacy async outcome producer',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    declaredOutcomes: <String>['after.dialogue'],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'seed'),
      ),
      ScenarioNode(
        id: 'dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(dialogueId: 'legacy_async_dialogue'),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'after.dialogue'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_dialogue',
        fromNodeId: 'source',
        toNodeId: 'dialogue',
      ),
      ScenarioEdge(
        id: 'dialogue_to_emit',
        fromNodeId: 'dialogue',
        toNodeId: 'emit',
      ),
      ScenarioEdge(id: 'emit_to_end', fromNodeId: 'emit', toNodeId: 'end'),
    ],
  );
}

ScenarioAsset _legacyRawFirstDialogueScenario() {
  return const ScenarioAsset(
    id: 'legacy_raw_first_scenario',
    name: 'Legacy raw first dialogue consumer',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyRawFirstOutcomeId),
      ),
      ScenarioNode(
        id: 'dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(dialogueId: 'legacy_raw_first_dialogue'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyRawFirstCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_dialogue',
        fromNodeId: 'source',
        toNodeId: 'dialogue',
      ),
      ScenarioEdge(
        id: 'dialogue_to_complete',
        fromNodeId: 'dialogue',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyRawSecondScenario() {
  return const ScenarioAsset(
    id: 'legacy_raw_second_scenario',
    name: 'Legacy raw second FIFO consumer',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyRawSecondOutcomeId),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyRawSecondCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_complete',
        fromNodeId: 'source',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacySuspendedProducerScenario() {
  return const ScenarioAsset(
    id: 'legacy_suspended_producer',
    name: 'Legacy suspended producer',
    entryNodeId: 'source',
    declaredOutcomes: <String>[
      'producer.seed',
      'producer.after_dialogue',
    ],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _mapId),
      ),
      ScenarioNode(
        id: 'emit_seed',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'producer.seed'),
      ),
      ScenarioNode(
        id: 'dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(
          dialogueId: 'legacy_suspended_producer_dialogue',
        ),
      ),
      ScenarioNode(
        id: 'emit_after',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'producer.after_dialogue'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_seed',
        fromNodeId: 'source',
        toNodeId: 'emit_seed',
      ),
      ScenarioEdge(
        id: 'seed_to_dialogue',
        fromNodeId: 'emit_seed',
        toNodeId: 'dialogue',
      ),
      ScenarioEdge(
        id: 'dialogue_to_after',
        fromNodeId: 'dialogue',
        toNodeId: 'emit_after',
      ),
      ScenarioEdge(
        id: 'after_to_end',
        fromNodeId: 'emit_after',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyMoveWarpScenario() {
  return const ScenarioAsset(
    id: 'legacy_move_warp_scenario',
    name: 'Legacy move-to-warp continuation',
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _mapId),
      ),
      ScenarioNode(
        id: 'move',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionMoveCharacter,
          params: <String, String>{
            'targetKind': 'warp',
            'targetId': 'npc_exit',
            'waitForCompletion': 'true',
          },
        ),
        binding: ScenarioNodeBinding(entityId: 'moving_npc'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyMoveWarpCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_move',
        fromNodeId: 'source',
        toNodeId: 'move',
      ),
      ScenarioEdge(
        id: 'move_to_complete',
        fromNodeId: 'move',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyFollowMoveWarpScenario() {
  return const ScenarioAsset(
    id: 'legacy_follow_move_warp_scenario',
    name: 'Legacy raw follow move-to-warp continuation',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    declaredOutcomes: <String>[_legacyFollowMoveWarpChildOutcomeId],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(
          outcomeId: _legacyFollowMoveWarpOutcomeId,
        ),
      ),
      ScenarioNode(
        id: 'follow',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionFollowCharacter,
          params: <String, String>{'leaderId': 'moving_npc'},
        ),
      ),
      ScenarioNode(
        id: 'move',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionMoveCharacter,
          params: <String, String>{
            'targetKind': 'warp',
            'targetId': 'leader_exit',
            'waitForCompletion': 'true',
          },
        ),
        binding: ScenarioNodeBinding(entityId: 'moving_npc'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(
          flagName: _legacyFollowMoveWarpCompletedFlag,
        ),
      ),
      ScenarioNode(
        id: 'emit_child',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(
          outcomeId: _legacyFollowMoveWarpChildOutcomeId,
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_follow',
        fromNodeId: 'source',
        toNodeId: 'follow',
      ),
      ScenarioEdge(
        id: 'follow_to_move',
        fromNodeId: 'follow',
        toNodeId: 'move',
      ),
      ScenarioEdge(
        id: 'move_to_complete',
        fromNodeId: 'move',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_child',
        fromNodeId: 'complete',
        toNodeId: 'emit_child',
      ),
      ScenarioEdge(
        id: 'child_to_end',
        fromNodeId: 'emit_child',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyMoveReplacementScenario({
  required String id,
  required String triggerId,
  required String warpId,
  required String completedFlag,
}) {
  return ScenarioAsset(
    id: id,
    name: id,
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: const ScenarioNodePayload(
          actionKind: kScenarioSourceTriggerEnter,
        ),
        binding: ScenarioNodeBinding(mapId: _mapId, triggerId: triggerId),
      ),
      ScenarioNode(
        id: 'move',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionMoveCharacter,
          params: <String, String>{
            'targetKind': 'warp',
            'targetId': warpId,
            'waitForCompletion': 'true',
          },
        ),
        binding: const ScenarioNodeBinding(entityId: 'moving_npc'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: const ScenarioNodePayload(
          actionKind: kScenarioActionSetFlag,
        ),
        binding: ScenarioNodeBinding(flagName: completedFlag),
      ),
      const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: const <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_move',
        fromNodeId: 'source',
        toNodeId: 'move',
      ),
      ScenarioEdge(
        id: 'move_to_complete',
        fromNodeId: 'move',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyPlayerMoveWarpScenario() {
  return const ScenarioAsset(
    id: 'legacy_player_move_warp_scenario',
    name: 'Legacy player move-to-warp continuation',
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _mapId),
      ),
      ScenarioNode(
        id: 'move',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionMoveCharacter,
          params: <String, String>{
            'targetKind': 'warp',
            'targetId': 'player_exit',
            'waitForCompletion': 'true',
          },
        ),
        binding: ScenarioNodeBinding(entityId: 'player'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyPlayerWarpCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_move',
        fromNodeId: 'source',
        toNodeId: 'move',
      ),
      ScenarioEdge(
        id: 'move_to_complete',
        fromNodeId: 'move',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyOutcomeBattleScenario() {
  return const ScenarioAsset(
    id: 'legacy_outcome_battle_scenario',
    name: 'Legacy outcome-caused Battle producer',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    declaredOutcomes: <String>['after.battle'],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'seed'),
      ),
      ScenarioNode(
        id: 'battle',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionStartTrainerBattle,
          params: <String, String>{
            'battleId': 'legacy_outcome_battle',
          },
        ),
        binding: ScenarioNodeBinding(
          trainerId: _trainerId,
          entityId: 'trainer_npc',
        ),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'after.battle'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
          id: 'source_to_battle', fromNodeId: 'source', toNodeId: 'battle'),
      ScenarioEdge(
          id: 'battle_to_emit', fromNodeId: 'battle', toNodeId: 'emit'),
      ScenarioEdge(id: 'emit_to_end', fromNodeId: 'emit', toNodeId: 'end'),
    ],
  );
}

ScenarioAsset _legacyScriptWarpScenario() {
  return const ScenarioAsset(
    id: 'legacy_script_warp_scenario',
    name: 'Legacy raw Scenario script warp',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyScriptWarpOutcomeId),
      ),
      ScenarioNode(
        id: 'run_script',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionRunScript),
        binding: ScenarioNodeBinding(scriptId: 'legacy_warp_script'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyScriptWarpCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_script',
        fromNodeId: 'source',
        toNodeId: 'run_script',
      ),
      ScenarioEdge(
        id: 'script_to_complete',
        fromNodeId: 'run_script',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyWarpConflictScenario() {
  return const ScenarioAsset(
    id: 'legacy_warp_conflict_scenario',
    name: 'Legacy Scenario/physical warp conflict',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceTriggerEnter),
        binding: ScenarioNodeBinding(
          mapId: _mapId,
          triggerId: 'warp_conflict_trigger',
        ),
      ),
      ScenarioNode(
        id: 'run_script',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionRunScript),
        binding: ScenarioNodeBinding(scriptId: 'legacy_warp_script'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyScriptWarpCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_script',
        fromNodeId: 'source',
        toNodeId: 'run_script',
      ),
      ScenarioEdge(
        id: 'script_to_complete',
        fromNodeId: 'run_script',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyIndependentTransitionScenario() {
  return const ScenarioAsset(
    id: 'legacy_independent_transition',
    name: 'Legacy independent transition owner',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceTriggerEnter),
        binding: ScenarioNodeBinding(
          mapId: _mapId,
          triggerId: 'a_transition_owner',
        ),
      ),
      ScenarioNode(
        id: 'transition',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
        binding: ScenarioNodeBinding(
          mapId: _legacyTransitionTargetMapId,
          warpId: 'arrival',
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_transition',
        fromNodeId: 'source',
        toNodeId: 'transition',
      ),
      ScenarioEdge(
        id: 'transition_to_end',
        fromNodeId: 'transition',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyRejectedTransitionScenario() {
  return const ScenarioAsset(
    id: 'legacy_rejected_transition',
    name: 'Legacy rejected concurrent transition',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceTriggerEnter),
        binding: ScenarioNodeBinding(
          mapId: _mapId,
          triggerId: 'c_transition_rejected',
        ),
      ),
      ScenarioNode(
        id: 'transition',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
        binding: ScenarioNodeBinding(
          mapId: _legacyPhysicalWarpTargetMapId,
          warpId: 'never_adopted',
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_transition',
        fromNodeId: 'source',
        toNodeId: 'transition',
      ),
      ScenarioEdge(
        id: 'transition_to_end',
        fromNodeId: 'transition',
        toNodeId: 'end',
      ),
    ],
  );
}

ProjectScriptEntry _legacyWarpScript() {
  return const ProjectScriptEntry(
    id: 'legacy_warp_script',
    name: 'Legacy Warp Script',
    asset: ScriptAsset(
      id: 'legacy_warp_script',
      defaultStartNode: 'start',
      nodes: <ScriptNode>[
        ScriptNode(
          id: 'start',
          commands: <ScriptCommand>[
            ScriptCommand(
              type: ScriptCommandType.warpPlayer,
              params: <String, String>{
                'mapId': _legacyScriptWarpTargetMapId,
                'x': '1',
                'y': '1',
                'facing': 'south',
              },
            ),
            ScriptCommand(type: ScriptCommandType.end),
          ],
        ),
      ],
    ),
  );
}

ScenarioAsset _legacyScriptFailureScenario() {
  return const ScenarioAsset(
    id: 'legacy_script_failure_scenario',
    name: 'Legacy raw Scenario script failure',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyScriptFailureOutcomeId),
      ),
      ScenarioNode(
        id: 'run_script',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionRunScript),
        binding: ScenarioNodeBinding(scriptId: 'legacy_failure_script'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(
          flagName: _legacyScriptFailureCompletedFlag,
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_script',
        fromNodeId: 'source',
        toNodeId: 'run_script',
      ),
      ScenarioEdge(
        id: 'script_to_complete',
        fromNodeId: 'run_script',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ProjectScriptEntry _legacyFailureScript({required bool throwsFromCommand}) {
  final failingCommand = throwsFromCommand
      ? const ScriptCommand(
          type: ScriptCommandType.setVariable,
          params: <String, String>{
            'variableName': 'legacy.script.failure',
            'value': 'not-an-int',
            'type': 'int',
          },
        )
      : const ScriptCommand(type: ScriptCommandType.setFlag);
  return ProjectScriptEntry(
    id: 'legacy_failure_script',
    name: 'Legacy Failure Script',
    asset: ScriptAsset(
      id: 'legacy_failure_script',
      defaultStartNode: 'start',
      nodes: <ScriptNode>[
        ScriptNode(
          id: 'start',
          commands: <ScriptCommand>[
            const ScriptCommand(
              type: ScriptCommandType.openDialogue,
              params: <String, String>{
                'filePath': 'dialogues/script_failure.yarn',
              },
            ),
            failingCommand,
            const ScriptCommand(type: ScriptCommandType.end),
          ],
        ),
      ],
    ),
  );
}

ProjectScriptEntry _legacyImmediateFailureScript({
  required bool throwsFromCommand,
}) {
  final failingCommand = throwsFromCommand
      ? const ScriptCommand(
          type: ScriptCommandType.setVariable,
          params: <String, String>{
            'variableName': 'legacy.script.failure',
            'value': 'not-an-int',
            'type': 'int',
          },
        )
      : const ScriptCommand(type: ScriptCommandType.setFlag);
  return ProjectScriptEntry(
    id: 'legacy_failure_script',
    name: 'Legacy Immediate Failure Script',
    asset: ScriptAsset(
      id: 'legacy_failure_script',
      defaultStartNode: 'start',
      nodes: <ScriptNode>[
        ScriptNode(
          id: 'start',
          commands: <ScriptCommand>[
            failingCommand,
            const ScriptCommand(type: ScriptCommandType.end),
          ],
        ),
      ],
    ),
  );
}

ProjectScriptEntry _legacySynchronousScript({
  required String scriptBehavior,
}) {
  final firstCommand = switch (scriptBehavior) {
    'end' => const ScriptCommand(type: ScriptCommandType.end),
    'error' => const ScriptCommand(type: ScriptCommandType.setFlag),
    'exception' => const ScriptCommand(
        type: ScriptCommandType.setVariable,
        params: <String, String>{
          'variableName': 'legacy.script.failure',
          'value': 'not-an-int',
          'type': 'int',
        },
      ),
    _ => throw ArgumentError.value(scriptBehavior, 'scriptBehavior'),
  };
  return ProjectScriptEntry(
    id: 'legacy_chain_script',
    name: 'Legacy Synchronous Chain Script',
    asset: ScriptAsset(
      id: 'legacy_chain_script',
      defaultStartNode: 'start',
      nodes: <ScriptNode>[
        ScriptNode(
          id: 'start',
          commands: <ScriptCommand>[firstCommand],
        ),
      ],
    ),
  );
}

ScenarioAsset _legacyDialogueThenScriptScenario() {
  return const ScenarioAsset(
    id: 'legacy_dialogue_then_script_scenario',
    name: 'Legacy dialogue then synchronous script',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyScriptFailureOutcomeId),
      ),
      ScenarioNode(
        id: 'first_dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(
          dialogueId: 'legacy_chain_first_dialogue',
        ),
      ),
      ScenarioNode(
        id: 'run_script',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionRunScript),
        binding: ScenarioNodeBinding(scriptId: 'legacy_chain_script'),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding:
            ScenarioNodeBinding(flagName: _legacyChainedEffectCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_dialogue',
        fromNodeId: 'source',
        toNodeId: 'first_dialogue',
      ),
      ScenarioEdge(
        id: 'dialogue_to_script',
        fromNodeId: 'first_dialogue',
        toNodeId: 'run_script',
      ),
      ScenarioEdge(
        id: 'script_to_complete',
        fromNodeId: 'run_script',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyDialogueThenDialogueScenario() {
  return const ScenarioAsset(
    id: 'legacy_dialogue_then_dialogue_scenario',
    name: 'Legacy dialogue then failing dialogue',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyScriptFailureOutcomeId),
      ),
      ScenarioNode(
        id: 'first_dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(
          dialogueId: 'legacy_chain_first_dialogue',
        ),
      ),
      ScenarioNode(
        id: 'second_dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(
          dialogueId: 'legacy_chain_second_dialogue',
        ),
      ),
      ScenarioNode(
        id: 'complete',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding:
            ScenarioNodeBinding(flagName: _legacyChainedEffectCompletedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_first_dialogue',
        fromNodeId: 'source',
        toNodeId: 'first_dialogue',
      ),
      ScenarioEdge(
        id: 'first_to_second_dialogue',
        fromNodeId: 'first_dialogue',
        toNodeId: 'second_dialogue',
      ),
      ScenarioEdge(
        id: 'second_dialogue_to_complete',
        fromNodeId: 'second_dialogue',
        toNodeId: 'complete',
      ),
      ScenarioEdge(
        id: 'complete_to_end',
        fromNodeId: 'complete',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyInvalidBattleScenario() {
  return const ScenarioAsset(
    id: 'legacy_invalid_battle_scenario',
    name: 'Legacy invalid Battle handoff',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: _legacyInvalidBattleOutcomeId),
      ),
      ScenarioNode(
        id: 'battle',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionStartTrainerBattle,
          params: <String, String>{'battleId': 'invalid_battle'},
        ),
        binding: ScenarioNodeBinding(
          trainerId: _trainerId,
          entityId: 'missing_trainer_npc',
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_battle',
        fromNodeId: 'source',
        toNodeId: 'battle',
      ),
      ScenarioEdge(
        id: 'battle_to_end',
        fromNodeId: 'battle',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _legacyAsyncSeedScenario() {
  return const ScenarioAsset(
    id: 'legacy_async_seed_scenario',
    name: 'Legacy async seed producer',
    entryNodeId: 'source',
    declaredOutcomes: <String>['seed'],
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _mapId),
      ),
      ScenarioNode(
        id: 'emit',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'seed'),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_emit',
        fromNodeId: 'source',
        toNodeId: 'emit',
      ),
      ScenarioEdge(id: 'emit_to_end', fromNodeId: 'emit', toNodeId: 'end'),
    ],
  );
}

DialogueSession _singleLineDialogueSession() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Continuer.')],
      ),
    ],
    'Start',
  )!;
}

NarrativeOutcomeDelivery _rawLegacyDelivery({
  required String deliveryId,
  required String outcomeId,
}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.legacyScenario,
      producerId: 'raw_restore_fixture',
      outcomeId: outcomeId,
    ),
    rootCorrelationId: _legacyRawRootCorrelationId,
    depth: 0,
    attemptCount: 0,
  );
}

RuntimeActiveBattleContext _trainerContext() {
  return const RuntimeActiveBattleContext(
    request: TrainerBattleStartRequest(
      requestId: 'qualified-outcome-trainer-request',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: _mapId,
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.south,
      ),
      trainerId: _trainerId,
      npcEntityId: 'trainer_npc',
      mapId: _mapId,
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: 0,
  );
}

BattleOutcome _victoryOutcome({required int playerCurrentHp}) {
  return BattleOutcome(
    type: BattleOutcomeType.victory,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: BattleCombatant(
        speciesId: 'sproutle',
        level: 5,
        currentHp: playerCurrentHp,
        maxHp: 20,
        stats: _battleStats,
        moves: const <BattleMove>[
          BattleMove(id: 'tackle', name: 'Tackle', power: 10),
        ],
      ),
      enemy: const BattleCombatant(
        speciesId: 'embercub',
        level: 5,
        currentHp: 0,
        maxHp: 18,
        stats: _battleStats,
        moves: <BattleMove>[
          BattleMove(id: 'scratch', name: 'Scratch', power: 10),
        ],
      ),
      currentTurn: null,
      outcome: null,
    ),
  );
}

final class _CheckpointCountingRepository implements GameSaveRepository {
  _CheckpointCountingRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;
  int loadCount = 0;

  @override
  Future<void> save(GameState state) {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.save,
      () async {
        saveCount++;
        storedState = state;
      },
    );
  }

  @override
  Future<GameState?> load() {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.load,
      () async {
        loadCount++;
        return storedState;
      },
    );
  }

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}
