import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart'
    show RuntimeDialogueSessionLoader;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NS-EVENT-V2-21 PlayableMapGame triggerEnter integration', () {
    test('routes event and custom trigger fronts through Event V2', () async {
      const mapId = 'trigger_enter_positive_map';
      const eventTriggerId = 'trigger_event';
      const customTriggerId = 'trigger_custom';
      const eventId = 'evt_019abcde-3000-7000-8000-000000000001';
      const customEventId = 'evt_019abcde-3000-7000-8000-000000000002';
      const eventSceneId = 'scene_trigger_event';
      const customSceneId = 'scene_trigger_custom';
      const eventFactId = 'fact.trigger_enter.event';
      const customFactId = 'fact.trigger_enter.custom';
      final eventSource = NarrativeEventSourceRef.triggerEnter(
        mapId,
        eventTriggerId,
      );
      final customSource = NarrativeEventSourceRef.triggerEnter(
        mapId,
        customTriggerId,
      );
      final preparedSources = <NarrativeEventSourceRef>[];
      final game = await _loadGame(
        _bundle(
          mapId: mapId,
          triggers: const <MapTrigger>[
            MapTrigger(
              id: eventTriggerId,
              name: 'Event trigger',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
            MapTrigger(
              id: customTriggerId,
              name: 'Custom trigger',
              type: TriggerType.custom,
              area: MapRect(
                pos: GridPos(x: 2, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          factIds: const <String>[eventFactId, customFactId],
          records: <NarrativeEventRecord>[
            _record(
              id: eventId,
              name: 'Event trigger Event V2',
              source: eventSource,
              sceneId: eventSceneId,
            ),
            _record(
              id: customEventId,
              name: 'Custom trigger Event V2',
              source: customSource,
              sceneId: customSceneId,
            ),
          ],
          scenes: <SceneAsset>[
            _factScene(sceneId: eventSceneId, factId: eventFactId),
            _factScene(sceneId: customSceneId, factId: customFactId),
          ],
        ),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source == eventSource ||
              occurrence.source == customSource) {
            preparedSources.add(occurrence.source);
          }
        },
      );

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(
        game,
        () => _factValue(game, eventFactId) == true,
      );

      expect(_factValue(game, eventFactId), isTrue);
      expect(_factValue(game, customFactId), isNot(isTrue));

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(
        game,
        () => _factValue(game, customFactId) == true,
      );

      expect(preparedSources, <NarrativeEventSourceRef>[
        eventSource,
        customSource,
      ]);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        containsAll(<String>[eventId, customEventId]),
      );
    });

    test(
      'retains a queued trigger occurrence while a checkpoint owns the gate',
      () async {
        const mapId = 'trigger_enter_checkpoint_map';
        const triggerId = 'trigger_checkpoint';
        const eventId = 'evt_019abcde-3000-7000-8000-000000000008';
        const sceneId = 'scene_trigger_checkpoint';
        const factId = 'fact.trigger_enter.checkpoint';
        final source = NarrativeEventSourceRef.triggerEnter(mapId, triggerId);
        final gate = NarrativeRuntimeActivityGate();
        var preparationCount = 0;
        final game = await _loadGame(
          _bundle(
            mapId: mapId,
            triggers: const <MapTrigger>[
              MapTrigger(
                id: triggerId,
                name: 'Checkpoint event trigger',
                type: TriggerType.event,
                area: MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 1, height: 1),
                ),
              ),
            ],
            factIds: const <String>[factId],
            records: <NarrativeEventRecord>[
              _record(
                id: eventId,
                name: 'Checkpoint-retained trigger Event',
                source: source,
                sceneId: sceneId,
              ),
            ],
            scenes: <SceneAsset>[
              _factScene(sceneId: sceneId, factId: factId),
            ],
          ),
          narrativeRuntimeActivityGate: gate,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source == source) {
              preparationCount++;
            }
          },
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.right),
          ),
          isTrue,
        );
        game.update(0.016);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.right),
          ),
          isTrue,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(game.debugPendingNarrativeTriggerEntryCount, 1);

        final checkpointStarted = Completer<void>();
        final releaseCheckpoint = Completer<void>();
        final checkpoint = gate.runCheckpoint<void>(
          NarrativeRuntimeCheckpointOperation.save,
          () async {
            checkpointStarted.complete();
            await releaseCheckpoint.future;
          },
        );
        await checkpointStarted.future;

        await _pumpFrames(game, 30);

        expect(gate.checkpointInProgress, isTrue);
        expect(game.debugPendingNarrativeTriggerEntryCount, 1);
        expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
        expect(preparationCount, 0);
        expect(_factValue(game, factId), isNot(isTrue));

        releaseCheckpoint.complete();
        await checkpoint;
        await _pumpUntil(game, () => _factValue(game, factId) == true);
        await _pumpFrames(game, 4);

        expect(preparationCount, 1);
        expect(game.debugPendingNarrativeTriggerEntryCount, 0);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds
              .where((id) => id == eventId),
          hasLength(1),
        );
      },
    );

    test(
      'pending warp blocks save and waits for an active checkpoint to finish',
      () async {
        const mapId = 'pending_warp_checkpoint_map';
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        final game = await _loadGame(
          _bundle(
            mapId: mapId,
            triggers: const <MapTrigger>[],
            warps: const <MapWarp>[
              MapWarp(
                id: 'checkpoint_warp',
                pos: GridPos(x: 1, y: 1),
                targetMapId: mapId,
                targetPos: GridPos(x: 3, y: 1),
                triggerMode: MapWarpTriggerMode.onEnter,
              ),
            ],
            scenes: const <SceneAsset>[],
          ),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
        );

        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.right),
          ),
          isTrue,
        );
        game.update(0.016);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.right),
          ),
          isTrue,
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(game.debugHasPendingMapTransition, isTrue);

        expect(await game.saveGame(), isFalse);
        expect(repository.saveCount, 0);

        final checkpointStarted = Completer<void>();
        final releaseCheckpoint = Completer<void>();
        final checkpoint = gate.runCheckpoint<void>(
          NarrativeRuntimeCheckpointOperation.save,
          () async {
            checkpointStarted.complete();
            await releaseCheckpoint.future;
          },
        );
        await checkpointStarted.future;

        await _pumpFrames(game, 30);

        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(game.debugHasPendingMapTransition, isTrue);
        expect(game.debugFlowPhaseName, 'overworld');

        releaseCheckpoint.complete();
        await checkpoint;
        await _pumpUntil(
          game,
          () =>
              game.debugPlayerGridPosition == const GridPos(x: 3, y: 1) &&
              !game.debugHasPendingMapTransition &&
              game.debugFlowPhaseName == 'overworld' &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(repository.saveCount, 0);
        expect(game.debugFlowPhaseName, 'overworld');
      },
    );

    test('does not emit triggerEnter for a system trigger kind', () async {
      const mapId = 'trigger_enter_system_excluded_map';
      const triggerId = 'trigger_camera_system';
      final excludedSource = NarrativeEventSourceRef.triggerEnter(
        mapId,
        triggerId,
      );
      final preparedSources = <NarrativeEventSourceRef>[];
      final game = await _loadGame(
        _bundle(
          mapId: mapId,
          triggers: const <MapTrigger>[
            MapTrigger(
              id: triggerId,
              name: 'System camera trigger',
              type: TriggerType.camera,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          records: const <NarrativeEventRecord>[],
          scenes: const <SceneAsset>[],
        ),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          preparedSources.add(occurrence.source);
        },
      );
      preparedSources.clear();

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpFrames(game, 8);

      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      expect(preparedSources, isNot(contains(excludedSource)));
      expect(preparedSources, isEmpty);
    });

    test('spawn inside is silent and exit then re-entry rearms the trigger',
        () async {
      const mapId = 'trigger_enter_rearm_map';
      const triggerId = 'trigger_spawn_area';
      const eventId = 'evt_019abcde-3000-7000-8000-000000000003';
      const sceneId = 'scene_trigger_rearm';
      const factId = 'fact.trigger_enter.rearmed';
      final source = NarrativeEventSourceRef.triggerEnter(mapId, triggerId);
      final preparedSources = <NarrativeEventSourceRef>[];
      final game = await _loadGame(
        _bundle(
          mapId: mapId,
          triggers: const <MapTrigger>[
            MapTrigger(
              id: triggerId,
              name: 'Spawn-area event trigger',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 0, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          factIds: const <String>[factId],
          records: <NarrativeEventRecord>[
            _record(
              id: eventId,
              name: 'Reusable spawn-area trigger',
              source: source,
              sceneId: sceneId,
              reusePolicy: NarrativeEventReusePolicy.reusable,
            ),
          ],
          scenes: <SceneAsset>[
            _factScene(sceneId: sceneId, factId: factId),
          ],
        ),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source == source) {
            preparedSources.add(occurrence.source);
          }
        },
      );

      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
      expect(preparedSources, isEmpty);
      expect(_factValue(game, factId), isNot(isTrue));

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpFrames(game, 4);
      expect(preparedSources, isEmpty);

      await _runSingleMove(game, RuntimeInputControl.left);
      await _pumpUntil(game, () => preparedSources.length == 1);
      expect(_factValue(game, factId), isTrue);

      await _runSingleMove(game, RuntimeInputControl.right);
      await _runSingleMove(game, RuntimeInputControl.left);
      await _pumpUntil(game, () => preparedSources.length == 2);

      expect(preparedSources, <NarrativeEventSourceRef>[source, source]);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(eventId)),
        reason: 'A reusable Event must remain eligible after re-entry.',
      );
    });

    test('overlapping entries remain FIFO while the first Scene has dialogue',
        () async {
      const mapId = 'trigger_enter_overlap_map';
      const firstTriggerId = 'a_dialogue_trigger';
      const secondTriggerId = 'z_followup_trigger';
      const firstEventId = 'evt_019abcde-3000-7000-8000-000000000004';
      const secondEventId = 'evt_019abcde-3000-7000-8000-000000000005';
      const firstSceneId = 'scene_trigger_dialogue_first';
      const secondSceneId = 'scene_trigger_followup_second';
      const dialogueId = 'dialogue_trigger_fifo';
      const firstFactId = 'fact.trigger_enter.fifo_first';
      const secondFactId = 'fact.trigger_enter.fifo_second';
      final firstSource = NarrativeEventSourceRef.triggerEnter(
        mapId,
        firstTriggerId,
      );
      final secondSource = NarrativeEventSourceRef.triggerEnter(
        mapId,
        secondTriggerId,
      );
      final preparationOrder = <NarrativeEventSourceRef>[];
      final game = await _loadGame(
        _bundle(
          mapId: mapId,
          triggers: const <MapTrigger>[
            MapTrigger(
              id: secondTriggerId,
              name: 'Second overlapping trigger',
              type: TriggerType.custom,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
            MapTrigger(
              id: firstTriggerId,
              name: 'First overlapping trigger',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          factIds: const <String>[firstFactId, secondFactId],
          dialogueIds: const <String>[dialogueId],
          records: <NarrativeEventRecord>[
            _record(
              id: firstEventId,
              name: 'First overlapping Event',
              source: firstSource,
              sceneId: firstSceneId,
            ),
            _record(
              id: secondEventId,
              name: 'Second overlapping Event',
              source: secondSource,
              sceneId: secondSceneId,
            ),
          ],
          scenes: <SceneAsset>[
            _dialogueFactScene(
              sceneId: firstSceneId,
              dialogueId: dialogueId,
              factId: firstFactId,
            ),
            _factScene(sceneId: secondSceneId, factId: secondFactId),
          ],
        ),
        dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source == firstSource ||
              occurrence.source == secondSource) {
            preparationOrder.add(occurrence.source);
          }
        },
      );

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');

      expect(preparationOrder, <NarrativeEventSourceRef>[firstSource]);
      expect(_factValue(game, firstFactId), isNot(isTrue));
      expect(_factValue(game, secondFactId), isNot(isTrue));

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      await _pumpUntil(
        game,
        () =>
            _factValue(game, firstFactId) == true &&
            _factValue(game, secondFactId) == true,
      );

      expect(preparationOrder, <NarrativeEventSourceRef>[
        firstSource,
        secondSource,
      ]);
      expect(game.debugFlowPhaseName, 'overworld');
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        containsAll(<String>[firstEventId, secondEventId]),
      );
    });

    test(
      'holds an on-enter warp until the trigger occurrence is committed',
      () async {
        const mapId = 'trigger_enter_warp_interlock_map';
        const triggerId = 'trigger_before_warp';
        const eventId = 'evt_019abcde-3000-7000-8000-000000000007';
        const sceneId = 'scene_trigger_before_warp';
        const factId = 'fact.trigger_enter.before_warp';
        final source = NarrativeEventSourceRef.triggerEnter(mapId, triggerId);
        final preparationStarted = Completer<void>();
        final releasePreparation = Completer<void>();
        var preparationCount = 0;
        final game = await _loadGame(
          _bundle(
            mapId: mapId,
            triggers: const <MapTrigger>[
              MapTrigger(
                id: triggerId,
                name: 'Trigger before warp',
                type: TriggerType.event,
                area: MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 1, height: 1),
                ),
              ),
            ],
            warps: const <MapWarp>[
              MapWarp(
                id: 'warp_after_trigger',
                pos: GridPos(x: 1, y: 1),
                targetMapId: mapId,
                targetPos: GridPos(x: 3, y: 1),
                triggerMode: MapWarpTriggerMode.onEnter,
              ),
            ],
            factIds: const <String>[factId],
            records: <NarrativeEventRecord>[
              _record(
                id: eventId,
                name: 'Commit trigger before warp',
                source: source,
                sceneId: sceneId,
              ),
            ],
            scenes: <SceneAsset>[
              _factScene(sceneId: sceneId, factId: factId),
            ],
          ),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source != source) {
              return;
            }
            preparationCount++;
            if (!preparationStarted.isCompleted) {
              preparationStarted.complete();
            }
            await releasePreparation.future;
          },
        );

        await _runSingleMove(game, RuntimeInputControl.right);
        await preparationStarted.future.timeout(const Duration(seconds: 2));
        expect(game.debugIsNarrativeSpatialDispatchInFlight, isTrue);
        expect(game.debugHasPendingMapTransition, isTrue);

        await _pumpFrames(game, 30);

        expect(game.gameStateSnapshot.currentMapId, mapId);
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(game.debugHasPendingMapTransition, isTrue);
        expect(_factValue(game, factId), isNot(isTrue));

        releasePreparation.complete();
        await _pumpUntil(
          game,
          () =>
              _factValue(game, factId) == true &&
              game.debugPlayerGridPosition == const GridPos(x: 3, y: 1) &&
              !game.debugHasPendingMapTransition &&
              !game.debugIsMapActivationDispatchInFlight,
        );

        expect(preparationCount, 1);
        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds
              .where((id) => id == eventId),
          hasLength(1),
        );
      },
    );

    test('validated claimed-ineligible entry never invokes legacy fallback',
        () async {
      const mapId = 'trigger_enter_claimed_map';
      const triggerId = 'trigger_claimed';
      const eventId = 'evt_019abcde-3000-7000-8000-000000000006';
      const sceneId = 'scene_trigger_claimed';
      const factId = 'fact.trigger_enter.claimed_scene';
      const legacyFlag = 'legacy.trigger_enter.claimed_must_not_run';
      const legacyScenario = ScenarioAsset(
        id: 'legacy_trigger_enter_claimed',
        name: 'Legacy claimed trigger must not run',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source',
        nodes: <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(
              actionKind: kScenarioSourceTriggerEnter,
            ),
            binding: ScenarioNodeBinding(
              mapId: mapId,
              triggerId: triggerId,
            ),
          ),
          ScenarioNode(
            id: 'set_legacy_flag',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionSetFlag,
            ),
            binding: ScenarioNodeBinding(flagName: legacyFlag),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(
            id: 'source_to_flag',
            fromNodeId: 'source',
            toNodeId: 'set_legacy_flag',
          ),
          ScenarioEdge(
            id: 'flag_to_end',
            fromNodeId: 'set_legacy_flag',
            toNodeId: 'end',
          ),
        ],
      );
      final source = NarrativeEventSourceRef.triggerEnter(mapId, triggerId);
      final provenance = LegacySourceRef.scenarioSourceNode(
        legacyScenario.id,
        'source',
      );
      final member = LegacySourceClaimMember(
        provenance: provenance,
        sourceFingerprint: computeScenarioSourceFingerprint(
          scenarioId: legacyScenario.id,
          nodeId: 'source',
          scenario: legacyScenario,
        ),
      );
      final cohortId = computeLegacySourceCohortId(source, <LegacySourceRef>[
        provenance,
      ]);
      final claim = LegacySourceClaim(
        cohortId: cohortId,
        source: source,
        members: <LegacySourceClaimMember>[member],
        cohortFingerprint: computeLegacySourceCohortFingerprint(
          cohortId,
          <LegacySourceClaimMember>[member],
        ),
        targetEventIds: const <String>[eventId],
        migrationReceiptId: 'receipt-trigger-enter-claimed',
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.dualRead,
        records: <NarrativeEventRecord>[
          _record(
            id: eventId,
            name: 'Disabled claimed trigger Event',
            source: source,
            sceneId: sceneId,
            enabled: false,
          ),
        ],
        legacyClaims: <LegacySourceClaim>[claim],
      );
      var preparationCount = 0;
      final game = await _loadGame(
        _bundle(
          mapId: mapId,
          triggers: const <MapTrigger>[
            MapTrigger(
              id: triggerId,
              name: 'Claimed event trigger',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          factIds: const <String>[factId],
          scenarios: const <ScenarioAsset>[legacyScenario],
          registry: registry,
          scenes: <SceneAsset>[
            _factScene(sceneId: sceneId, factId: factId),
          ],
        ),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source == source) {
            preparationCount++;
          }
        },
      );

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(game, () => preparationCount == 1);
      await _pumpFrames(game, 8);

      expect(_factValue(game, factId), isNot(isTrue));
      expect(
        game.gameStateSnapshot.storyFlags.activeFlags,
        isNot(contains(legacyFlag)),
        reason: 'A validated claim blocks legacy even when V2 is ineligible.',
      );
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(eventId)),
      );
    });

    test(
      'trigger outcome retry stays pending and releases the detached queue',
      () async {
        const mapId = 'trigger_enter_retry_map';
        const triggerId = 'trigger_retry';
        const eventId = 'evt_019abcde-3000-7000-8000-00000000000a';
        const sceneId = 'scene_trigger_retry';
        const outcomeId = 'trigger.retry';
        final source = NarrativeEventSourceRef.triggerEnter(mapId, triggerId);
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        var outcomePreparationCount = 0;
        final game = await _loadGame(
          _bundle(
            mapId: mapId,
            triggers: const <MapTrigger>[
              MapTrigger(
                id: triggerId,
                name: 'Retry event trigger',
                type: TriggerType.event,
                area: MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 1, height: 1),
                ),
              ),
            ],
            records: <NarrativeEventRecord>[
              _record(
                id: eventId,
                name: 'Trigger retry producer',
                source: source,
                sceneId: sceneId,
              ),
            ],
            scenes: <SceneAsset>[
              _outcomeScene(sceneId: sceneId, outcomeId: outcomeId),
            ],
          ),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind !=
                NarrativeEventSourceKind.outcomeReceived) {
              return;
            }
            outcomePreparationCount++;
            throw StateError(
              'retryable trigger outcome infrastructure failure',
            );
          },
        );

        final uncaughtErrors = await _captureDetachedErrors(() async {
          await _runSingleMove(game, RuntimeInputControl.right);
          await _pumpUntil(
            game,
            () =>
                game.debugPendingNarrativeTriggerEntryCount == 0 &&
                !game.debugIsNarrativeSpatialDispatchInFlight &&
                !game.debugIsNarrativeOutcomeWorkInFlight &&
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isNotEmpty,
          );
          await Future<void>.delayed(Duration.zero);
        });

        final state = game.gameStateSnapshot;
        final pending =
            state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries;
        expect(uncaughtErrors, isEmpty);
        expect(outcomePreparationCount, 1);
        expect(pending, hasLength(1));
        expect(pending.single.outcome.outcomeId, outcomeId);
        expect(pending.single.attemptCount, 1);
        expect(
          state.narrativeEventProgress.consumedNarrativeEventIds,
          contains(eventId),
        );
        expect(game.debugPendingNarrativeTriggerEntryCount, 0);
        expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
        expect(game.debugIsNarrativeOutcomeWorkInFlight, isFalse);
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
        expect(
          repository.storedState!.narrativeEventProgress
              .pendingNarrativeOutcomeDeliveries.single.attemptCount,
          1,
        );
      },
    );
  });
}

Future<List<Object>> _captureDetachedErrors(
  Future<void> Function() body,
) async {
  final errors = <Object>[];
  final bodyCompleted = Completer<void>();
  runZonedGuarded(
    () {
      body().then<void>(
        (_) => bodyCompleted.complete(),
        onError: (Object error, StackTrace stackTrace) {
          bodyCompleted.completeError(error, stackTrace);
        },
      );
    },
    (error, _) => errors.add(error),
  );
  await bodyCompleted.future;
  return errors;
}

NarrativeEventRecord _record({
  required String id,
  required String name,
  required NarrativeEventSourceRef source,
  required String sceneId,
  bool enabled = true,
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: const <NarrativeEventCondition>[],
      sceneId: sceneId,
      reusePolicy: reusePolicy,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

RuntimeMapBundle _bundle({
  required String mapId,
  required List<MapTrigger> triggers,
  required List<SceneAsset> scenes,
  List<MapWarp> warps = const <MapWarp>[],
  List<NarrativeEventRecord> records = const <NarrativeEventRecord>[],
  List<String> factIds = const <String>[],
  List<String> dialogueIds = const <String>[],
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  NarrativeEventRegistry? registry,
}) {
  final manifest = ProjectManifest(
    name: 'V2-21 triggerEnter $mapId',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: mapId,
        name: mapId,
        relativePath: 'maps/$mapId.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      for (final factId in factIds)
        NarrativeFactDefinition(id: factId, label: factId),
    ],
    dialogues: <ProjectDialogueEntry>[
      for (final dialogueId in dialogueIds)
        ProjectDialogueEntry(
          id: dialogueId,
          name: dialogueId,
          relativePath: 'dialogues/$dialogueId.yarn',
        ),
    ],
    scenarios: scenarios,
    eventRegistry: registry ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: records,
          legacyClaims: const <LegacySourceClaim>[],
        ),
    scenes: scenes,
  );
  return RuntimeMapBundle(
    manifest: manifest,
    map: MapData(
      id: mapId,
      name: mapId,
      size: const GridSize(width: 4, height: 3),
      layers: const <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: const <MapEntity>[
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
      ],
      triggers: triggers,
      warps: warps,
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/v2_21_trigger_enter_$mapId',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

SceneAsset _factScene({
  required String sceneId,
  required String factId,
}) {
  return SceneAsset(
    id: sceneId,
    name: sceneId,
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

SceneAsset _outcomeScene({
  required String sceneId,
  required String outcomeId,
}) {
  return SceneAsset(
    id: sceneId,
    name: sceneId,
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

SceneAsset _dialogueFactScene({
  required String sceneId,
  required String dialogueId,
  required String factId,
}) {
  return SceneAsset(
    id: sceneId,
    name: sceneId,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: dialogueId),
        ),
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
          id: 'start_to_dialogue',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'dialogue_to_fact',
          fromNodeId: 'dialogue',
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

DialogueSession _singleLineDialogueSession() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Entrée détectée.')],
      ),
    ],
    'Start',
  )!;
}

Future<_TestPlayableMapGame> _loadGame(
  RuntimeMapBundle bundle, {
  RuntimeDialogueSessionLoader? dialogueSessionLoader,
  NarrativeRuntimeActivityGate? narrativeRuntimeActivityGate,
  GameSaveRepository? saveRepository,
  Future<void> Function(NarrativeEventOccurrence occurrence)?
      beforeNarrativeAuthorityPreparation,
}) async {
  final game = _TestPlayableMapGame(
    bundle: bundle,
    projectFilePath: '${bundle.projectRootDirectory}/project.json',
    dialogueSessionLoader: dialogueSessionLoader,
    narrativeRuntimeActivityGate: narrativeRuntimeActivityGate,
    saveRepository: saveRepository,
    beforeNarrativeAuthorityPreparation: beforeNarrativeAuthorityPreparation,
  );
  game.onGameResize(Vector2(640, 480));
  await game.onLoad().timeout(const Duration(seconds: 2));
  await _pumpUntil(
    game,
    () => !game.debugIsMapActivationDispatchInFlight,
  );
  return game;
}

bool? _factValue(PlayableMapGame game, String factId) {
  return game
      .gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId[factId];
}

Future<void> _runSingleMove(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  await Future<void>.delayed(Duration.zero);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );

  for (var i = 0; i < 180; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
    if (!game.debugIsPlayerStepping) {
      return;
    }
  }
  fail('Timed out waiting for the V2-21 movement step to settle.');
}

Future<void> _pumpFrames(PlayableMapGame game, int count) async {
  for (var i = 0; i < count; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 360,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the V2-21 runtime integration.');
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.dialogueSessionLoader,
    super.narrativeRuntimeActivityGate,
    super.saveRepository,
    super.beforeNarrativeAuthorityPreparation,
  });

  bool _onLoadCompleted = false;

  @override
  bool get isLoaded => _onLoadCompleted;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _onLoadCompleted = true;
  }
}

final class _CheckpointCountingRepository implements GameSaveRepository {
  _CheckpointCountingRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;

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
  Future<GameState?> load() async => storedState;

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}
