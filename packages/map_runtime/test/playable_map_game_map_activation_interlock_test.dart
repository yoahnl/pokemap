import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:path/path.dart' as p;

const _sourceMapId = 'activation_interlock_source';
const _targetMapId = 'activation_interlock_target';
const _eventId = 'evt_019abcde-2000-7000-8000-000000000001';
const _sceneId = 'scene_activation_interlock_target_enter';
const _factId = 'fact.activation_interlock.target_enter_completed';
const _targetMapEnterOutcomeId = 'target_map_enter_completed';
const _legacyFlag = 'test.activation_interlock.legacy_must_not_run';
const _legacyOutcomeId = 'activation_interlock_transition_requested';
const _legacyChildOutcomeId = 'activation_interlock_child_after_transition';
const _legacyOutcomeProducerSceneId =
    'scene_activation_interlock_outcome_producer';
const _legacyOutcomeProducerScenarioId = 'legacy_restored_outcome_transition';
const _legacyTransitionDialogueId = 'legacy_restored_outcome_dialogue';
const _legacyMapEnterAFlag = 'test.activation_interlock.map_enter_a';
const _legacyMapEnterBFlag = 'test.activation_interlock.map_enter_b';
const _legacyDeliveryId = 'outd_019abcde-4000-7000-8000-000000000001';
const _legacyExecutionId = 'evx_019abcde-4000-7000-8000-000000000002';
const _legacyCorrelationId = 'corr_019abcde-4000-7000-8000-000000000003';
const _retryOutcomeId = 'activation_interlock_retry_outcome';
const _retryDeliveryId = 'outd_019abcde-4000-7000-8000-000000000011';
const _retryExecutionId = 'evx_019abcde-4000-7000-8000-000000000012';
const _retryCorrelationId = 'corr_019abcde-4000-7000-8000-000000000013';
const _physicalWarpRetryEventId = 'evt_019abcde-4000-7000-8000-000000000021';
const _physicalWarpRetrySceneId = 'scene_physical_warp_retry_producer';
const _physicalWarpRetryOutcomeId = 'physical_warp.retry';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'connection mapEnter dispatch interlocks movement, transitions and checkpoints',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_map_activation_interlock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final preparationStarted = Completer<void>();
      final releasePreparation = Completer<void>();
      var targetPreparationCount = 0;
      final repository = _CountingGameSaveRepository(
        const GameState(
          saveId: 'load-must-not-run',
          currentMapId: _sourceMapId,
          playerPosition: GridPos(x: 1, y: 0),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source !=
              NarrativeEventSourceRef.mapEnter(_targetMapId)) {
            return;
          }
          targetPreparationCount++;
          if (!preparationStarted.isCompleted) {
            preparationStarted.complete();
          }
          await releasePreparation.future;
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivationId =
          game.debugLastCompletedMapActivation?.activationId;

      await _runSingleMove(game, RuntimeInputControl.right);
      await preparationStarted.future.timeout(const Duration(seconds: 2));

      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsMapActivationDispatchInFlight, isTrue);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.initialBoot,
      );
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState
            .overridesByFactId[_factId],
        isNot(isTrue),
      );

      expect(await game.loadGame(), isFalse);
      expect(repository.loadCount, 0);
      expect(await game.saveGame(), isFalse);
      expect(repository.saveCount, 0);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      for (var i = 0; i < 30; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        initialActivationId,
      );

      releasePreparation.complete();
      await _pumpUntil(
        game,
        () =>
            !game.debugIsMapActivationDispatchInFlight &&
            game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId[_factId] ==
                true,
      );

      final state = game.gameStateSnapshot;
      expect(targetPreparationCount, 1);
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds
            .where((id) => id == _eventId),
        hasLength(1),
      );
      expect(state.storyFlags.activeFlags, isNot(contains(_legacyFlag)));
      expect(game.debugCompletedMapActivationDispatchCount, 2);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.connection,
      );
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        isNot(initialActivationId),
      );
      expect(await game.saveGame(), isTrue);
      expect(repository.saveCount, 1);
    },
  );

  test(
    'load interlocks movement and connection until saveRestore dispatch',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_load_activation_interlock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final repository = _BlockingLoadGameSaveRepository(
        const GameState(
          saveId: 'blocked-load',
          currentMapId: _targetMapId,
          playerPosition: GridPos(x: 0, y: 0),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivationId =
          game.debugLastCompletedMapActivation?.activationId;

      final loadFuture = game.loadGame();
      await repository.loadStarted.future.timeout(const Duration(seconds: 2));

      expect(game.debugIsLoadActivationWorkInFlight, isTrue);
      expect(game.debugIsMapActivationDispatchInFlight, isFalse);
      expect(await game.loadGame(), isFalse);
      expect(repository.loadCount, 1);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      for (var i = 0; i < 30; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      expect(game.gameStateSnapshot.currentMapId, _sourceMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
      expect(game.debugHasPendingMapTransition, isFalse);
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        initialActivationId,
      );

      repository.releaseLoad();
      expect(await loadFuture, isTrue);

      expect(game.debugIsLoadActivationWorkInFlight, isFalse);
      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 2);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.saveRestore,
      );
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        isNot(initialActivationId),
      );
    },
  );

  test(
    'restored legacy outcome transition supersedes stale mapEnter activation',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_transition_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.legacyScenario,
        producerId: _legacyOutcomeProducerScenarioId,
        outcomeId: _legacyOutcomeId,
      );
      late PlayableMapGame game;
      bool? parentDeliveredBeforeTargetMapEnter;
      game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-outcome-transition',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source ==
              NarrativeEventSourceRef.mapEnter(_targetMapId)) {
            parentDeliveredBeforeTargetMapEnter = game.gameStateSnapshot
                .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds
                .contains(_legacyDeliveryId);
          }
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(
            const Duration(seconds: 2),
          );
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(state.currentMapId, _targetMapId);
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterAFlag)));
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterBFlag)));
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[_factId],
        isTrue,
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        contains(_legacyDeliveryId),
      );
      expect(
        parentDeliveredBeforeTargetMapEnter,
        isTrue,
        reason: 'The raw legacy parent must commit before its post-commit '
            'transition prepares the target mapEnter occurrence.',
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        hasLength(2),
        reason: 'The restored delivery and the target mapEnter Scene outcome '
            'must both be drained.',
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.warp,
      );
    },
  );

  test(
    'restored legacy outcome keeps transition ownership after an awaited '
    'dialogue continuation',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_dialogue_transition_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(
        root,
        awaitDialogueBeforeTransition: true,
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.legacyScenario,
        producerId: _legacyOutcomeProducerScenarioId,
        outcomeId: _legacyOutcomeId,
      );
      late PlayableMapGame game;
      var sourceMapEnterCount = 0;
      var targetMapEnterCount = 0;
      bool? parentDeliveredBeforeTargetMapEnter;
      game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-dialogue-transition',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
        dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source ==
              NarrativeEventSourceRef.mapEnter(_sourceMapId)) {
            sourceMapEnterCount++;
          }
          if (occurrence.source ==
              NarrativeEventSourceRef.mapEnter(_targetMapId)) {
            targetMapEnterCount++;
            parentDeliveredBeforeTargetMapEnter = game.gameStateSnapshot
                .narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds
                .contains(_legacyDeliveryId);
          }
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(const Duration(seconds: 2));
      await _pumpUntil(
        game,
        () =>
            game.debugFlowPhaseName == 'dialogue' &&
            !game.debugIsNarrativeOutcomeWorkInFlight,
      );

      expect(
        game.gameStateSnapshot.narrativeEventProgress
            .deliveredNarrativeOutcomeDeliveryIds,
        contains(_legacyDeliveryId),
      );
      expect(sourceMapEnterCount, 0);
      expect(targetMapEnterCount, 0);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == _targetMapId &&
            game.debugLastCompletedMapActivation?.mapId == _targetMapId &&
            !game.debugIsMapActivationDispatchInFlight &&
            !game.debugIsNarrativeOutcomeWorkInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(sourceMapEnterCount, 0);
      expect(targetMapEnterCount, 1);
      expect(parentDeliveredBeforeTargetMapEnter, isTrue);
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterAFlag)));
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterBFlag)));
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[_factId],
        isTrue,
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.warp,
      );
    },
  );

  test(
    'drains a child outcome after an outcome transition whose target mapEnter '
    'uses legacy fallback',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_legacy_target_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(
        root,
        emitChildBeforeTransition: true,
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.legacyScenario,
        producerId: _legacyOutcomeProducerScenarioId,
        outcomeId: _legacyOutcomeId,
      );
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-outcome-legacy-target',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(const Duration(seconds: 2));
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(state.currentMapId, _targetMapId);
      expect(state.storyFlags.activeFlags, contains(_legacyMapEnterBFlag));
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[_factId],
        isTrue,
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        hasLength(3),
        reason: 'The restored parent, the child emitted immediately before '
            'the transition, and the child consumer Scene outcome must all be '
            'drained even when the target mapEnter has no V2 match.',
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.warp,
      );
    },
  );

  test(
    'does not strand a child outcome when the transitioned mapEnter authority '
    'fails closed',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_failed_target_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(
        root,
        emitChildBeforeTransition: true,
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.legacyScenario,
        producerId: _legacyOutcomeProducerScenarioId,
        outcomeId: _legacyOutcomeId,
      );
      var rejectedTargetMapEnterCount = 0;
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-outcome-failed-target',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source ==
              NarrativeEventSourceRef.mapEnter(_targetMapId)) {
            rejectedTargetMapEnterCount++;
            throw StateError('Injected target mapEnter authority failure.');
          }
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(const Duration(seconds: 2));
      await _pumpUntil(
        game,
        () =>
            !game.debugIsMapActivationDispatchInFlight &&
            !game.debugIsNarrativeOutcomeWorkInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(state.currentMapId, _targetMapId);
      expect(rejectedTargetMapEnterCount, 1);
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[_factId],
        isTrue,
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        hasLength(3),
        reason: 'A failed mapEnter dispatch may reject that source, but it '
            'must not orphan outcomes already emitted by the parent adapter.',
      );
    },
  );

  test(
    'restored Scene outcome cannot enter the raw legacy Scenario adapter',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_scene_outcome_mismatch_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: _legacyOutcomeProducerSceneId,
        outcomeId: _legacyOutcomeId,
      );
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-scene-outcome-mismatch',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(const Duration(seconds: 2));
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(state.currentMapId, _sourceMapId);
      expect(state.storyFlags.activeFlags, contains(_legacyMapEnterAFlag));
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterBFlag)));
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[_factId],
        isNot(isTrue),
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        contains(_legacyDeliveryId),
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.saveRestore,
      );
    },
  );

  test(
    'failed restored outcome authority rolls back the pending delivery and load',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_retry_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final retryOutcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_activation_interlock_retry_producer',
        outcomeId: _retryOutcomeId,
      );
      final repository = _CountingGameSaveRepository(
        GameState(
          saveId: 'restore-outcome-retry',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _retryDeliveryId,
                outcome: retryOutcome,
                causationExecutionId: _retryExecutionId,
                rootCorrelationId: _retryCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.outcomeReceived) {
            throw StateError('Injected restored outcome authority failure.');
          }
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivation = game.debugLastCompletedMapActivation;

      expect(await game.loadGame(), isFalse);

      final state = game.gameStateSnapshot;
      expect(game.debugIsLoadActivationWorkInFlight, isFalse);
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(game.debugLastCompletedMapActivation, initialActivation);
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        isNot(contains(_retryDeliveryId)),
      );
    },
  );

  test(
    'physical warp contains a target mapEnter outcome retry',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_physical_warp_retry_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writePhysicalWarpRetryProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _targetMapId,
      );
      final repository = _CountingGameSaveRepository(
        const GameState(
          saveId: 'physical-warp-retry-save',
          currentMapId: _targetMapId,
          playerPosition: GridPos(x: 0, y: 0),
        ),
      );
      var outcomePreparationCount = 0;
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind !=
              NarrativeEventSourceKind.outcomeReceived) {
            return;
          }
          outcomePreparationCount++;
          throw StateError(
            'retryable physical warp outcome infrastructure failure',
          );
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);

      final uncaughtErrors = await _captureDetachedErrors(() async {
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
        await _pumpUntil(
          game,
          () =>
              game.gameStateSnapshot.currentMapId == _sourceMapId &&
              !game.debugIsMapActivationDispatchInFlight &&
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
      expect(state.currentMapId, _sourceMapId);
      expect(state.playerPosition, const GridPos(x: 1, y: 0));
      expect(pending, hasLength(1));
      expect(pending.single.outcome.outcomeId, _physicalWarpRetryOutcomeId);
      expect(pending.single.attemptCount, 1);
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_physicalWarpRetryEventId),
      );
      expect(game.debugCompletedMapActivationDispatchCount, 2);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.warp,
      );
      expect(game.debugLastCompletedMapActivation?.mapId, _sourceMapId);
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(await game.saveGame(), isTrue);
      expect(repository.saveCount, 1);
      expect(
        repository._state!.narrativeEventProgress
            .pendingNarrativeOutcomeDeliveries.single.attemptCount,
        1,
      );
    },
  );
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

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.saveRepository,
    super.dialogueSessionLoader,
    super.initialMapActivationReason,
    super.beforeNarrativeAuthorityPreparation,
  });

  @override
  bool get isLoaded => true;
}

final class _BlockingLoadGameSaveRepository implements GameSaveRepository {
  _BlockingLoadGameSaveRepository(this._state);

  final GameState _state;
  final Completer<void> loadStarted = Completer<void>();
  final Completer<GameState?> _loadResult = Completer<GameState?>();
  int loadCount = 0;

  void releaseLoad() {
    if (!_loadResult.isCompleted) {
      _loadResult.complete(_state);
    }
  }

  @override
  Future<void> save(GameState state) async {}

  @override
  Future<GameState?> load() {
    loadCount++;
    if (!loadStarted.isCompleted) {
      loadStarted.complete();
    }
    return _loadResult.future;
  }

  @override
  Future<bool> exists() async => true;

  @override
  Future<void> delete() async {}
}

final class _CountingGameSaveRepository implements GameSaveRepository {
  _CountingGameSaveRepository(this._state);

  GameState? _state;
  int saveCount = 0;
  int loadCount = 0;

  @override
  Future<void> save(GameState state) async {
    saveCount++;
    _state = state;
  }

  @override
  Future<GameState?> load() async {
    loadCount++;
    return _state;
  }

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async {
    _state = null;
  }
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
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  await _pumpUntil(
    game,
    () => !game.debugIsPlayerStepping && !game.debugHasPendingMapTransition,
  );
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the runtime game to settle.');
}

Future<String> _writeProject(Directory root) async {
  final maps = <MapData>[_sourceMap(), _targetMap()];
  final manifest = ProjectManifest(
    name: 'Map activation interlock integration',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Target map enter completed',
      ),
    ],
    scenarios: const <ScenarioAsset>[_legacyTargetMapEnterScenario],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: <NarrativeEventRecord>[
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventId,
            name: 'Target map enter',
            source: NarrativeEventSourceRef.mapEnter(_targetMapId),
            conditions: const <NarrativeEventCondition>[],
            sceneId: _sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenes: <SceneAsset>[_scene()],
  );
  final mapsDirectory = Directory(p.join(root.path, 'maps'));
  await mapsDirectory.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDirectory.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

Future<String> _writePhysicalWarpRetryProject(Directory root) async {
  final maps = <MapData>[_sourceMap(), _targetMap()];
  final manifest = ProjectManifest(
    name: 'Physical warp retry integration',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const <ProjectTilesetEntry>[],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: <NarrativeEventRecord>[
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _physicalWarpRetryEventId,
            name: 'Physical warp retry producer',
            source: NarrativeEventSourceRef.mapEnter(_sourceMapId),
            conditions: const <NarrativeEventCondition>[],
            sceneId: _physicalWarpRetrySceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenes: <SceneAsset>[_physicalWarpRetryScene()],
  );
  final mapsDirectory = Directory(p.join(root.path, 'maps'));
  await mapsDirectory.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDirectory.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

Future<String> _writeLegacyOutcomeTransitionProject(
  Directory root, {
  bool emitChildBeforeTransition = false,
  bool awaitDialogueBeforeTransition = false,
}) async {
  final maps = <MapData>[_sourceMap(), _targetMap()];
  final manifest = ProjectManifest(
    name: 'Restored legacy outcome transition integration',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Target map enter completed',
      ),
    ],
    scenarios: <ScenarioAsset>[
      if (awaitDialogueBeforeTransition)
        _legacyOutcomeDialogueTransitionScenario
      else if (emitChildBeforeTransition)
        _legacyOutcomeEmitChildTransitionScenario
      else
        _legacyOutcomeTransitionScenario,
      _legacyMapEnterAScenario,
      _legacyMapEnterBScenario,
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: <NarrativeEventRecord>[
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventId,
            name: emitChildBeforeTransition
                ? 'Child outcome after restored transition'
                : 'Target map enter after restored outcome',
            source: emitChildBeforeTransition
                ? NarrativeEventSourceRef.outcomeReceived(
                    NarrativeOutcomeRef(
                      producerKind: NarrativeOutcomeProducerKind.legacyScenario,
                      producerId: _legacyOutcomeProducerScenarioId,
                      outcomeId: _legacyChildOutcomeId,
                    ),
                  )
                : NarrativeEventSourceRef.mapEnter(_targetMapId),
            conditions: const <NarrativeEventCondition>[],
            sceneId: _sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenes: <SceneAsset>[
      _scene(),
      _legacyOutcomeProducerScene(),
    ],
    dialogues: <ProjectDialogueEntry>[
      if (awaitDialogueBeforeTransition)
        const ProjectDialogueEntry(
          id: _legacyTransitionDialogueId,
          name: 'Restored outcome transition dialogue',
          relativePath: 'dialogues/legacy_restored_outcome_dialogue.yarn',
        ),
    ],
  );
  final mapsDirectory = Directory(p.join(root.path, 'maps'));
  await mapsDirectory.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDirectory.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

SceneAsset _legacyOutcomeProducerScene() => SceneAsset(
      id: _legacyOutcomeProducerSceneId,
      name: 'Legacy transition outcome producer',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(
          id: _legacyOutcomeId,
          label: 'Transition requested',
        ),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _legacyOutcomeId,
            ),
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

SceneAsset _physicalWarpRetryScene() => SceneAsset(
      id: _physicalWarpRetrySceneId,
      name: 'Physical warp retry producer',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(
          id: _physicalWarpRetryOutcomeId,
          label: 'Physical warp retry',
        ),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _physicalWarpRetryOutcomeId,
            ),
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

MapData _sourceMap() => const MapData(
      id: _sourceMapId,
      name: 'Activation interlock source',
      size: GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_source',
          name: 'Source spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      connections: <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: _targetMapId,
          offset: 0,
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_source'),
    );

MapData _targetMap() => const MapData(
      id: _targetMapId,
      name: 'Activation interlock target',
      size: GridSize(width: 3, height: 2),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_target',
          name: 'Target spawn',
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
          id: 'warp_back_to_source',
          pos: GridPos(x: 1, y: 0),
          targetMapId: _sourceMapId,
          targetPos: GridPos(x: 1, y: 0),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_target'),
    );

SceneAsset _scene() => SceneAsset(
      id: _sceneId,
      name: 'Target map enter Scene',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(
          id: _targetMapEnterOutcomeId,
          label: 'Target map enter completed',
        ),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'set_fact',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(factId: _factId, value: true),
            ),
          ),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _targetMapEnterOutcomeId,
            ),
          ),
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

const _legacyTargetMapEnterScenario = ScenarioAsset(
  id: 'legacy_target_map_enter_must_not_run',
  name: 'Legacy target mapEnter must not run',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _targetMapId),
    ),
    ScenarioNode(
      id: 'set_legacy_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source',
    ),
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

const _legacyOutcomeTransitionScenario = ScenarioAsset(
  id: _legacyOutcomeProducerScenarioId,
  name: 'Legacy restored outcome transition',
  scope: ScenarioScope.globalStory,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_outcome',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
      binding: ScenarioNodeBinding(outcomeId: _legacyOutcomeId),
    ),
    ScenarioNode(
      id: 'transition_to_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
      binding: ScenarioNodeBinding(
        mapId: _targetMapId,
        warpId: 'warp_back_to_source',
      ),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source_outcome',
    ),
    ScenarioEdge(
      id: 'source_to_transition',
      fromNodeId: 'source_outcome',
      toNodeId: 'transition_to_b',
    ),
    ScenarioEdge(
      id: 'transition_to_end',
      fromNodeId: 'transition_to_b',
      toNodeId: 'end',
    ),
  ],
);

const _legacyOutcomeDialogueTransitionScenario = ScenarioAsset(
  id: _legacyOutcomeProducerScenarioId,
  name: 'Legacy restored outcome dialogue then transition',
  scope: ScenarioScope.globalStory,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_outcome',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
      binding: ScenarioNodeBinding(outcomeId: _legacyOutcomeId),
    ),
    ScenarioNode(
      id: 'dialogue',
      type: ScenarioNodeType.dialogue,
      binding: ScenarioNodeBinding(dialogueId: _legacyTransitionDialogueId),
    ),
    ScenarioNode(
      id: 'transition_to_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
      binding: ScenarioNodeBinding(
        mapId: _targetMapId,
        warpId: 'warp_back_to_source',
      ),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source_outcome',
    ),
    ScenarioEdge(
      id: 'source_to_dialogue',
      fromNodeId: 'source_outcome',
      toNodeId: 'dialogue',
    ),
    ScenarioEdge(
      id: 'dialogue_to_transition',
      fromNodeId: 'dialogue',
      toNodeId: 'transition_to_b',
    ),
    ScenarioEdge(
      id: 'transition_to_end',
      fromNodeId: 'transition_to_b',
      toNodeId: 'end',
    ),
  ],
);

const _legacyOutcomeEmitChildTransitionScenario = ScenarioAsset(
  id: _legacyOutcomeProducerScenarioId,
  name: 'Legacy restored outcome child then transition',
  scope: ScenarioScope.globalStory,
  entryNodeId: 'start',
  declaredOutcomes: <String>[_legacyChildOutcomeId],
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_outcome',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
      binding: ScenarioNodeBinding(outcomeId: _legacyOutcomeId),
    ),
    ScenarioNode(
      id: 'emit_child',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionEmitOutcome),
      binding: ScenarioNodeBinding(outcomeId: _legacyChildOutcomeId),
    ),
    ScenarioNode(
      id: 'transition_to_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
      binding: ScenarioNodeBinding(
        mapId: _targetMapId,
        warpId: 'warp_back_to_source',
      ),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source_outcome',
    ),
    ScenarioEdge(
      id: 'source_to_emit',
      fromNodeId: 'source_outcome',
      toNodeId: 'emit_child',
    ),
    ScenarioEdge(
      id: 'emit_to_transition',
      fromNodeId: 'emit_child',
      toNodeId: 'transition_to_b',
    ),
    ScenarioEdge(
      id: 'transition_to_end',
      fromNodeId: 'transition_to_b',
      toNodeId: 'end',
    ),
  ],
);

const _legacyMapEnterAScenario = ScenarioAsset(
  id: 'legacy_map_enter_a',
  name: 'Legacy map enter A',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_map_enter_a',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _sourceMapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_a',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyMapEnterAFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source_a',
      fromNodeId: 'start',
      toNodeId: 'source_map_enter_a',
    ),
    ScenarioEdge(
      id: 'source_to_flag_a',
      fromNodeId: 'source_map_enter_a',
      toNodeId: 'set_map_enter_a',
    ),
    ScenarioEdge(
      id: 'flag_to_end_a',
      fromNodeId: 'set_map_enter_a',
      toNodeId: 'end',
    ),
  ],
);

const _legacyMapEnterBScenario = ScenarioAsset(
  id: 'legacy_map_enter_b',
  name: 'Legacy map enter B',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_map_enter_b',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _targetMapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyMapEnterBFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source_b',
      fromNodeId: 'start',
      toNodeId: 'source_map_enter_b',
    ),
    ScenarioEdge(
      id: 'source_to_flag_b',
      fromNodeId: 'source_map_enter_b',
      toNodeId: 'set_map_enter_b',
    ),
    ScenarioEdge(
      id: 'flag_to_end_b',
      fromNodeId: 'set_map_enter_b',
      toNodeId: 'end',
    ),
  ],
);

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
