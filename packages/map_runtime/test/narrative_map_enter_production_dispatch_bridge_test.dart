import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000001';
const _executionId = 'evx_019abcde-0000-7000-8000-000000000002';
const _correlationId = 'corr_019abcde-0000-7000-8000-000000000003';
const _generatedDeliveryId = 'outd_019abcde-0000-7000-8000-000000000004';
const _firstPendingDeliveryId = 'outd_019abcde-0000-7000-8000-000000000005';
const _secondPendingDeliveryId = 'outd_019abcde-0000-7000-8000-000000000006';
const _legacyFingerprint =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('NS-EVENT-V2-19 map-enter production dispatch bridge', () {
    test('rejects empty and whitespace-only activation identities', () {
      for (final invalid in ['', ' ', '\t\n']) {
        expect(
          () => MapActivation(
            activationId: invalid,
            mapId: 'map',
            reason: MapActivationReason.initialBoot,
          ),
          throwsArgumentError,
        );
        expect(
          () => MapActivation(
            activationId: 'activation-valid',
            mapId: invalid,
            reason: MapActivationReason.initialBoot,
          ),
          throwsArgumentError,
        );
      }
    });

    test('all activation reasons keep runtime metadata and deduplicate by id',
        () async {
      for (final reason in MapActivationReason.values) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        final legacyTrace = <MapActivation>[];
        final activation = MapActivation(
          activationId: 'activation-${reason.name}',
          mapId: 'map-${reason.name}',
          reason: reason,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          ),
          legacyFallback: (value, occurrence, gameState) async {
            expect(occurrence, value.occurrence);
            expect(gameState.saveId, 'save');
            legacyTrace.add(value);
          },
          isCurrentActivation: (value) => value == activation.activationId,
        );

        expect(
          activation.occurrence,
          NarrativeEventOccurrence(
            source: NarrativeEventSourceRef.mapEnter(activation.mapId),
          ),
        );

        final first = await bridge.dispatchCompletedActivation(activation);
        final duplicate = await bridge.dispatchCompletedActivation(activation);

        expect(first, isA<MapEnterProductionDispatchLegacyFallback>());
        expect(duplicate, isA<MapEnterProductionDispatchDuplicate>());
        expect(legacyTrace, [activation]);
      }
    });

    test('concurrent dispatches of one current activation execute once',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final legacyStarted = Completer<void>();
      final releaseLegacy = Completer<void>();
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-concurrent',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, ___) async {
          legacyCalls++;
          legacyStarted.complete();
          await releaseLegacy.future;
        },
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final firstDispatch = bridge.dispatchCompletedActivation(activation);
      await legacyStarted.future;
      final secondResult = await bridge.dispatchCompletedActivation(activation);
      releaseLegacy.complete();
      final firstResult = await firstDispatch;

      expect(firstResult, isA<MapEnterProductionDispatchLegacyFallback>());
      expect(secondResult, isA<MapEnterProductionDispatchDuplicate>());
      expect(legacyCalls, 1);
    });

    test('legacyOnly falls back while v2Only no-match stays closed', () async {
      for (final testCase in <({
        EventSystemMode mode,
        int expectedLegacyCalls,
        Type expectedResult,
      })>[
        (
          mode: EventSystemMode.legacyOnly,
          expectedLegacyCalls: 1,
          expectedResult: MapEnterProductionDispatchLegacyFallback,
        ),
        (
          mode: EventSystemMode.v2Only,
          expectedLegacyCalls: 0,
          expectedResult: MapEnterProductionDispatchNoFallback,
        ),
      ]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId: 'activation-authority-mode',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final registry = _registry(testCase.mode);
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: registry,
            occurrence: occurrence,
          ),
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(result.runtimeType, testCase.expectedResult);
        expect(legacyCalls, testCase.expectedLegacyCalls);
      }
    });

    test('dualRead handled event executes V2 and never invokes legacy',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.mapEnter('map');
      final registry = _registry(
        EventSystemMode.dualRead,
        records: [_record(source)],
      );
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-dual-read-handled',
        mapId: 'map',
        reason: MapActivationReason.warp,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: registry,
          occurrence: occurrence,
          legacyClaimIndex: buildValidatedLegacyClaimIndex(registry),
        ),
        executeScene: (request) async {
          v2Calls++;
          expect(request.eventId, _eventId);
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchV2Handled>());
      expect(v2Calls, 1);
      expect(legacyCalls, 0);
    });

    test('true re-entry resets before planning and duplicate activation once',
        () async {
      var currentState = GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          consumedNarrativeEventIds: const {_eventId},
          activeNarrativeMapId: 'other-map',
          visitedNarrativeMapIds: const {'map', 'other-map'},
        ),
      );
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.mapEnter('map');
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [
          _record(
            source,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            resetPolicy: const NarrativeEventResetPolicy.onMapReentry(),
          ),
        ],
      );
      var sceneCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-reentry',
        mapId: 'map',
        reason: MapActivationReason.warp,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: registry,
          occurrence: occurrence,
        ),
        executeScene: (request) async {
          sceneCalls++;
          expect(
            request.gameState.narrativeEventProgress.consumedNarrativeEventIds,
            isNot(contains(_eventId)),
          );
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async {},
        isCurrentActivation: (value) => value == activation.activationId,
      );

      expect(await bridge.dispatchCompletedActivation(activation),
          isA<MapEnterProductionDispatchV2Handled>());
      expect(await bridge.dispatchCompletedActivation(activation),
          isA<MapEnterProductionDispatchDuplicate>());
      expect(sceneCalls, 1);
      expect(currentState.narrativeEventProgress.consumedNarrativeEventIds,
          contains(_eventId));
      expect(
        currentState.narrativeEventProgress.appliedNarrativeResetTokens
            .where((token) => token == 'map:activation-reentry'),
        hasLength(1),
      );
    });

    test('save restore does not qualify as map re-entry', () async {
      var currentState = GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          consumedNarrativeEventIds: const {_eventId},
          activeNarrativeMapId: 'other-map',
          visitedNarrativeMapIds: const {'map', 'other-map'},
        ),
      );
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.mapEnter('map');
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [
          _record(
            source,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            resetPolicy: const NarrativeEventResetPolicy.onMapReentry(),
          ),
        ],
      );
      var sceneCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-restore-no-reset',
        mapId: 'map',
        reason: MapActivationReason.saveRestore,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: registry,
          occurrence: occurrence,
        ),
        executeScene: (request) async {
          sceneCalls++;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async {},
        isCurrentActivation: (value) => value == activation.activationId,
      );

      expect(await bridge.dispatchCompletedActivation(activation),
          isA<MapEnterProductionDispatchNoFallback>());
      expect(sceneCalls, 0);
      expect(currentState.narrativeEventProgress.consumedNarrativeEventIds,
          contains(_eventId));
    });

    test('stale activation during Scene rolls back its candidate state',
        () async {
      const originalState = GameState(
        saveId: 'save',
        metadata: {'runtime': 'original'},
      );
      var currentState = originalState;
      final transactions = NarrativeEventStateTransactions(currentState);
      final sceneStarted = Completer<void>();
      final releaseScene = Completer<void>();
      var currentActivationId = 'activation-stale-scene';
      var committedCalls = 0;
      var legacyCalls = 0;
      final source = NarrativeEventSourceRef.mapEnter('map');
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [_record(source)],
      );
      final activation = MapActivation(
        activationId: 'activation-stale-scene',
        mapId: 'map',
        reason: MapActivationReason.warp,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) {
          committedCalls++;
          currentState = value;
        },
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: registry,
          occurrence: occurrence,
        ),
        executeScene: (request) async {
          sceneStarted.complete();
          await releaseScene.future;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState.copyWith(
              metadata: const {'scene': 'must-not-commit'},
            ),
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await sceneStarted.future;
      currentActivationId = 'activation-newer';
      releaseScene.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(await transactions.read(), originalState);
      expect(currentState, originalState);
      expect(committedCalls, 0);
      expect(legacyCalls, 0);
    });

    test('claimed but ineligible dualRead event never falls back', () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.mapEnter('map');
      final provenance = LegacySourceRef.mapEvent('map', 'legacy-map-enter');
      final registry = _registry(
        EventSystemMode.dualRead,
        records: [_record(source, enabled: false)],
        claims: [_claim(source, provenance)],
      );
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-claimed-ineligible',
        mapId: 'map',
        reason: MapActivationReason.connection,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, __) async => _prepareAuthority(
          registry: registry,
          occurrence: NarrativeEventOccurrence(
            source: source,
            provenance: provenance,
          ),
          legacyClaimIndex: buildRuntimeValidatedLegacyClaimIndex(
            registry,
            runtimeEvidence: LegacyClaimRuntimeEvidence(
              entries: [
                LegacyClaimRuntimeEvidenceEntry(
                  provenance: provenance,
                  source: source,
                  sourceFingerprint: _legacyFingerprint,
                ),
              ],
            ),
          ),
        ),
        executeScene: (request) async {
          v2Calls++;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchClaimedIneligible>());
      expect(v2Calls, 0);
      expect(legacyCalls, 0);
    });

    test('blocked or failing authority preparation stays fail-closed',
        () async {
      for (final throwsDuringPreparation in [false, true]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId:
              'activation-authority-${throwsDuringPreparation ? 'error' : 'blocked'}',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, __) async {
            if (throwsDuringPreparation) {
              throw StateError('authority preparation failed');
            }
            return NarrativeEventDispatchAuthorityBlocked(
              reason:
                  NarrativeEventDispatchAuthorityBlockReason.invalidRegistry,
              diagnostics: const ['blocked fixture'],
            );
          },
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(
          result.runtimeType,
          throwsDuringPreparation
              ? MapEnterProductionDispatchFailed
              : MapEnterProductionDispatchAuthorityBlocked,
        );
        expect(legacyCalls, 0);
      }
    });

    test('failed or cancelled Scene rolls back without legacy fallback',
        () async {
      for (final testCase in <({
        NarrativeSceneExecutionResult sceneResult,
        Type expectedResult,
      })>[
        (
          sceneResult: NarrativeSceneExecutionResult.failed('scene failed'),
          expectedResult: MapEnterProductionDispatchFailed,
        ),
        (
          sceneResult:
              NarrativeSceneExecutionResult.cancelled('scene cancelled'),
          expectedResult: MapEnterProductionDispatchNoFallback,
        ),
      ]) {
        const originalState = GameState(
          saveId: 'save',
          metadata: {'runtime': 'original'},
        );
        var currentState = originalState;
        final transactions = NarrativeEventStateTransactions(currentState);
        final source = NarrativeEventSourceRef.mapEnter('map');
        final registry = _registry(
          EventSystemMode.v2Only,
          records: [_record(source)],
        );
        var committedCalls = 0;
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId: 'activation-scene-${testCase.expectedResult}',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) {
            committedCalls++;
            currentState = value;
          },
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: registry,
            occurrence: occurrence,
          ),
          executeScene: (_) async => testCase.sceneResult,
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(result.runtimeType, testCase.expectedResult);
        expect(await transactions.read(), originalState);
        expect(currentState, originalState);
        expect(committedCalls, 0);
        expect(legacyCalls, 0);
      }
    });

    test('saveRestore drains the real F1 outbox FIFO before mapEnter',
        () async {
      final trace = <String>[];
      GameState? legacyGameState;
      var currentState = GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          pendingNarrativeOutcomeDeliveries: [
            _pendingDelivery(
              _firstPendingDeliveryId,
              producerId: 'restore',
              outcomeId: 'first',
            ),
            _pendingDelivery(
              _secondPendingDeliveryId,
              producerId: 'restore',
              outcomeId: 'second',
            ),
          ],
        ),
      );
      final transactions = NarrativeEventStateTransactions(currentState);
      final activityPort = NoopNarrativeEventActivityPort();
      final processor = NarrativeOutcomeOutboxProcessor(
        stateTransactions: transactions,
        activityPort: activityPort,
        dispatcher: (request) async {
          trace.add('outcome:${request.delivery.outcome.outcomeId}');
          return NarrativeOutcomeDispatchResult.delivered(
            updatedGameState: request.gameState,
          );
        },
        deliveryIdFactory: () => _generatedDeliveryId,
      );
      final activation = MapActivation(
        activationId: 'activation-save-restore',
        mapId: 'map',
        reason: MapActivationReason.saveRestore,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, gameState) async {
          legacyGameState = gameState;
          trace.add('mapEnter:saveRestore');
        },
        activityPort: activityPort,
        beforeSaveRestoreDispatch: (_) async {
          while (true) {
            final result = await processor.processNext();
            if (result is NarrativeOutcomeOutboxEmpty) {
              return;
            }
            expect(result, isA<NarrativeOutcomeOutboxDelivered>());
          }
        },
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);
      final latestTransactionalState = await transactions.read();

      expect(result, isA<MapEnterProductionDispatchLegacyFallback>());
      expect(
        trace,
        ['outcome:first', 'outcome:second', 'mapEnter:saveRestore'],
      );
      expect(
        latestTransactionalState
            .narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(currentState, latestTransactionalState);
      expect(legacyGameState, latestTransactionalState);
    });

    test('newer activation suppresses stale saveRestore after async prehook',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final hookStarted = Completer<void>();
      final releaseHook = Completer<void>();
      var currentActivationId = 'activation-stale-restore';
      var authorityCalls = 0;
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-stale-restore',
        mapId: 'map',
        reason: MapActivationReason.saveRestore,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async {
          authorityCalls++;
          return _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          );
        },
        executeScene: (request) async {
          v2Calls++;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        beforeSaveRestoreDispatch: (_) async {
          hookStarted.complete();
          await releaseHook.future;
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await hookStarted.future;
      currentActivationId = 'activation-newer-warp';
      releaseHook.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(authorityCalls, 0);
      expect(v2Calls, 0);
      expect(legacyCalls, 0);
    });

    test('newer activation marks an awaited legacy fallback stale', () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final legacyStarted = Completer<void>();
      final releaseLegacy = Completer<void>();
      var currentActivationId = 'activation-stale-legacy';
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-stale-legacy',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, ___) async {
          legacyCalls++;
          legacyStarted.complete();
          await releaseLegacy.future;
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await legacyStarted.future;
      currentActivationId = 'activation-newer';
      releaseLegacy.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(legacyCalls, 1);
    });

    test('stale attempts are unclaimed while the current id stays claimed',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      var currentActivationId = 'activation-a';
      final legacyTrace = <String>[];
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (activation, _, __) async {
          legacyTrace.add(activation.activationId);
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );
      final activationA = MapActivation(
        activationId: 'activation-a',
        mapId: 'map-a',
        reason: MapActivationReason.initialBoot,
      );
      final activationB = MapActivation(
        activationId: 'activation-b',
        mapId: 'map-b',
        reason: MapActivationReason.warp,
      );
      final staleActivation = MapActivation(
        activationId: 'activation-stale',
        mapId: 'map-stale',
        reason: MapActivationReason.connection,
      );

      expect(
        await bridge.dispatchCompletedActivation(activationA),
        isA<MapEnterProductionDispatchLegacyFallback>(),
      );
      currentActivationId = activationB.activationId;
      expect(
        await bridge.dispatchCompletedActivation(activationB),
        isA<MapEnterProductionDispatchLegacyFallback>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(staleActivation),
        isA<MapEnterProductionDispatchStale>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(staleActivation),
        isA<MapEnterProductionDispatchStale>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(activationB),
        isA<MapEnterProductionDispatchDuplicate>(),
      );
      expect(legacyTrace, ['activation-a', 'activation-b']);
    });

    test('current activation lookup exception fails closed before claim',
        () async {
      var authorityCalls = 0;
      var legacyCalls = 0;
      final bridge = _bridge(
        stateTransactions: NarrativeEventStateTransactions(
          const GameState(saveId: 'save'),
        ),
        currentGameState: () => const GameState(saveId: 'save'),
        onGameStateCommitted: (_) {},
        prepareAuthority: (_, occurrence) async {
          authorityCalls++;
          return _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (_) => throw StateError('current lookup failed'),
      );
      final activation = MapActivation(
        activationId: 'activation-current-error',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchFailed>());
      expect(authorityCalls, 0);
      expect(legacyCalls, 0);
    });
  });
}

MapEnterProductionDispatchBridge _bridge({
  required NarrativeEventStateTransactions stateTransactions,
  required GameState Function() currentGameState,
  required void Function(GameState gameState) onGameStateCommitted,
  required Future<NarrativeEventDispatchAuthorityPreparation> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
  ) prepareAuthority,
  required Future<void> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
    GameState gameState,
  ) legacyFallback,
  required bool Function(String activationId) isCurrentActivation,
  NarrativeSceneExecutionCallback? executeScene,
  NarrativeEventActivityPort? activityPort,
  Future<void> Function(MapActivation activation)? beforeSaveRestoreDispatch,
}) {
  return MapEnterProductionDispatchBridge(
    stateTransactions: stateTransactions,
    currentGameState: currentGameState,
    onGameStateCommitted: onGameStateCommitted,
    prepareAuthority: prepareAuthority,
    executeScene: executeScene ??
        (request) async => NarrativeSceneExecutionResult.completed(
              updatedGameState: request.gameState,
              qualifiedOutcomes: const [],
            ),
    legacyFallback: legacyFallback,
    activityPort: activityPort ?? NoopNarrativeEventActivityPort(),
    beforeSaveRestoreDispatch: beforeSaveRestoreDispatch ?? (_) async {},
    isCurrentActivation: isCurrentActivation,
    executionIdFactory: () => _executionId,
    correlationIdFactory: () => _correlationId,
    deliveryIdFactory: () => _generatedDeliveryId,
  );
}

NarrativeEventDispatchAuthorityPreparation _prepareAuthority({
  required NarrativeEventRegistry registry,
  required NarrativeEventOccurrence occurrence,
  ValidatedLegacyClaimIndex? legacyClaimIndex,
}) {
  return NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: occurrence,
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    legacyClaimIndex: legacyClaimIndex,
    projectCatalog: _catalog(registry, occurrence.source),
  );
}

NarrativeEventRegistry _registry(
  EventSystemMode mode, {
  List<NarrativeEventRecord> records = const [],
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: mode,
    records: records,
    legacyClaims: claims,
  );
}

NarrativeEventRecord _record(
  NarrativeEventSourceRef source, {
  bool enabled = true,
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.reusable,
  NarrativeEventResetPolicy resetPolicy =
      const NarrativeEventResetPolicy.never(),
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Map enter event',
      source: source,
      conditions: const [],
      sceneId: 'scene_map_enter',
      reusePolicy: reusePolicy,
      priority: 0,
      order: 0,
      resetPolicy: resetPolicy,
    ),
    enabled: enabled,
  );
}

LegacySourceClaim _claim(
  NarrativeEventSourceRef source,
  LegacySourceRef provenance,
) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _legacyFingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: const [_eventId],
    migrationReceiptId: 'receipt',
  );
}

NarrativeEventProjectCatalog _catalog(
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef source,
) {
  final mapId = source.when(
    entityInteract: (value, _) => value,
    triggerEnter: (value, _) => value,
    mapEnter: (value) => value,
    outcomeReceived: (_) => 'map',
  );
  final sceneIds = {
    for (final record in registry.records)
      if (record.definitionOrNull case final definition?) definition.sceneId,
  };
  final project = ProjectManifest(
    name: 'Map enter bridge fixture',
    maps: [
      ProjectMapEntry(
        id: mapId,
        name: mapId,
        relativePath: 'maps/$mapId.json',
      ),
    ],
    tilesets: const [],
    eventRegistry: registry,
    scenes: [for (final sceneId in sceneIds) _scene(sceneId)],
  );
  return buildNarrativeEventProjectCatalog(
    project: project,
    maps: [
      MapData(
        id: mapId,
        name: mapId,
        size: const GridSize(width: 1, height: 1),
        layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
      ),
    ],
  );
}

SceneAsset _scene(String id) {
  return SceneAsset.fromJson({
    'id': id,
    'name': id,
    'graph': const {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
        {'id': 'end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge',
          'fromNodeId': 'start',
          'fromPortId': 'completed',
          'toNodeId': 'end',
          'kind': 'default',
        },
      ],
    },
  });
}

NarrativeOutcomeDelivery _pendingDelivery(
  String deliveryId, {
  required String producerId,
  required String outcomeId,
}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: producerId,
      outcomeId: outcomeId,
    ),
    causationExecutionId: _executionId,
    rootCorrelationId: _correlationId,
    depth: 0,
    attemptCount: 0,
  );
}
