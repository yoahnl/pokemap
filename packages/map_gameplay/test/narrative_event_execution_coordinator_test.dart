import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/f1_runtime_catalog_fixture.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _executionA = 'evx_019abcde-0000-7000-8000-000000000002';
const _correlationA = 'corr_019abcde-0000-7000-8000-000000000003';
const _deliveryA = 'outd_019abcde-0000-7000-8000-000000000004';
const _deliveryB = 'outd_019abcde-0000-7000-8000-000000000005';

void main() {
  test('success commits Scene state consumption and ordered outcomes',
      () async {
    final original = const GameState(saveId: 'save');
    final transactions = NarrativeEventStateTransactions(original);
    final outcomes = [
      _outcome(NarrativeOutcomeProducerKind.scene, 'scene_a', 'first'),
      _outcome(NarrativeOutcomeProducerKind.battle, 'battle_a', 'second'),
    ];
    final deliveryIds = [_deliveryA, _deliveryB].iterator;
    var callbacks = 0;
    final coordinator = NarrativeEventExecutionCoordinator(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: transactions,
      planner: NarrativeEventDispatchPlanner(),
      executeScene: (request) async {
        callbacks++;
        expect(request.eventId, _eventA);
        expect(request.sceneId, 'scene_$_eventA');
        expect(request.executionId, _executionA);
        return NarrativeSceneExecutionResult.completed(
          updatedGameState: request.gameState.copyWith(
            metadata: const {'scene': 'complete'},
          ),
          qualifiedOutcomes: outcomes,
        );
      },
      executionIdFactory: () => _executionA,
      correlationIdFactory: () => _correlationA,
      deliveryIdFactory: () {
        deliveryIds.moveNext();
        return deliveryIds.current;
      },
    );

    final result = await coordinator.execute(authority: _authority());
    final committed = await transactions.read();

    expect(result, isA<NarrativeEventExecutionSucceeded>());
    expect(callbacks, 1);
    expect(committed.metadata, {'scene': 'complete'});
    expect(
      committed.narrativeEventProgress.consumedNarrativeEventIds,
      {_eventA},
    );
    final pending =
        committed.narrativeEventProgress.pendingNarrativeOutcomeDeliveries;
    expect(pending.map((value) => value.deliveryId), [_deliveryA, _deliveryB]);
    expect(pending.map((value) => value.outcome), outcomes);
    expect(pending.map((value) => value.causationExecutionId),
        everyElement(_executionA));
    expect(pending.map((value) => value.rootCorrelationId),
        everyElement(_correlationA));
    expect(pending.map((value) => value.depth), everyElement(0));
    expect(pending.map((value) => value.attemptCount), everyElement(0));
  });

  test('incoming occurrence preserves correlation and increments depth',
      () async {
    final transactions =
        NarrativeEventStateTransactions(const GameState(saveId: 'save'));
    final coordinator = NarrativeEventExecutionCoordinator(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: transactions,
      planner: NarrativeEventDispatchPlanner(),
      executeScene: (request) async => NarrativeSceneExecutionResult.completed(
        updatedGameState: request.gameState,
        qualifiedOutcomes: [
          _outcome(NarrativeOutcomeProducerKind.legacyScenario, 'legacy', 'ok'),
        ],
      ),
      executionIdFactory: () => _executionA,
      correlationIdFactory: () => throw StateError('must not create root'),
      deliveryIdFactory: () => _deliveryA,
    );

    await coordinator.execute(
      authority: _authority(rootCorrelationId: _correlationA, depth: 4),
    );
    final delivery = (await transactions.read())
        .narrativeEventProgress
        .pendingNarrativeOutcomeDeliveries
        .single;

    expect(delivery.rootCorrelationId, _correlationA);
    expect(delivery.depth, 5);
  });

  test('failure and cancellation preserve the authoritative state', () async {
    for (final sceneResult in <NarrativeSceneExecutionResult>[
      NarrativeSceneExecutionResult.failed('sceneFailure'),
      NarrativeSceneExecutionResult.cancelled('playerCancelled'),
    ]) {
      final original = const GameState(
        saveId: 'save',
        metadata: {'original': 'true'},
      );
      final transactions = NarrativeEventStateTransactions(original);
      final coordinator = NarrativeEventExecutionCoordinator(
        activityPort: NoopNarrativeEventActivityPort(),
        stateTransactions: transactions,
        planner: NarrativeEventDispatchPlanner(),
        executeScene: (_) async => sceneResult,
        executionIdFactory: () => _executionA,
        correlationIdFactory: () => _correlationA,
        deliveryIdFactory: () => _deliveryA,
      );

      final result = await coordinator.execute(authority: _authority());

      expect(
        result,
        sceneResult is NarrativeSceneExecutionFailed
            ? isA<NarrativeEventExecutionFailed>()
            : isA<NarrativeEventExecutionCancelled>(),
      );
      expect(await transactions.read(), original);
    }
  });

  test('reusable success never consumes the event', () async {
    final transactions =
        NarrativeEventStateTransactions(const GameState(saveId: 'save'));
    var callbacks = 0;
    final coordinator = NarrativeEventExecutionCoordinator(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: transactions,
      planner: NarrativeEventDispatchPlanner(),
      executeScene: (request) async {
        callbacks++;
        return NarrativeSceneExecutionResult.completed(
          updatedGameState: request.gameState,
          qualifiedOutcomes: const [],
        );
      },
      executionIdFactory: () => _executionA,
      correlationIdFactory: () => _correlationA,
      deliveryIdFactory: () => _deliveryA,
    );
    final authority = _authority(
      reusePolicy: NarrativeEventReusePolicy.reusable,
    );

    await coordinator.execute(authority: authority);
    await coordinator.execute(authority: authority);

    expect(callbacks, 2);
    expect(
      (await transactions.read())
          .narrativeEventProgress
          .consumedNarrativeEventIds,
      isEmpty,
    );
  });
}

NarrativeEventDispatchAuthorityReady _authority({
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
  String? rootCorrelationId,
  int? depth,
}) {
  final source = NarrativeEventSourceRef.mapEnter('map');
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: [
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _eventA,
          name: _eventA,
          source: source,
          conditions: const [],
          sceneId: 'scene_$_eventA',
          reusePolicy: reusePolicy,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
    ],
    legacyClaims: const [],
  );
  return NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: NarrativeEventOccurrence(
      source: source,
      rootCorrelationId: rootCorrelationId,
      depth: depth,
    ),
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    projectCatalog: f1ProjectCatalogForRegistry(registry),
  ) as NarrativeEventDispatchAuthorityReady;
}

NarrativeOutcomeRef _outcome(
  NarrativeOutcomeProducerKind producerKind,
  String producerId,
  String outcomeId,
) {
  return NarrativeOutcomeRef(
    producerKind: producerKind,
    producerId: producerId,
    outcomeId: outcomeId,
  );
}
