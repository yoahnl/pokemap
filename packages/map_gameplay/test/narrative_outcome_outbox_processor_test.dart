import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/f1_runtime_catalog_fixture.dart';

const _deliveryA = 'outd_019abcde-0000-7000-8000-000000000001';
const _deliveryB = 'outd_019abcde-0000-7000-8000-000000000002';
const _deliveryC = 'outd_019abcde-0000-7000-8000-000000000003';
const _executionA = 'evx_019abcde-0000-7000-8000-000000000004';
const _correlationA = 'corr_019abcde-0000-7000-8000-000000000005';
const _eventA = 'evt_019abcde-0000-7000-8000-000000000006';

void main() {
  test('processes one FIFO head and appends children after existing tail',
      () async {
    final head = _delivery(_deliveryA, outcomeId: 'head', depth: 3);
    final tail = _delivery(_deliveryB, outcomeId: 'tail');
    final transactions = _transactions([head, tail]);
    final child = _outcome('child');
    final seen = <String>[];
    final processor = NarrativeOutcomeOutboxProcessor(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: transactions,
      dispatcher: (request) async {
        seen.add(request.delivery.deliveryId);
        expect(request.occurrence.source.kind,
            NarrativeEventSourceKind.outcomeReceived);
        return NarrativeOutcomeDispatchResult.delivered(
          updatedGameState: request.gameState.copyWith(
            metadata: const {'consumer': 'complete'},
          ),
          qualifiedChildOutcomes: [child],
          causationExecutionId: _executionA,
        );
      },
      deliveryIdFactory: () => _deliveryC,
    );

    final result = await processor.processNext();
    final state = await transactions.read();

    expect(result, isA<NarrativeOutcomeOutboxDelivered>());
    expect(seen, [_deliveryA]);
    expect(state.metadata, {'consumer': 'complete'});
    expect(
      state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries
          .map((value) => value.deliveryId),
      [_deliveryB, _deliveryC],
    );
    final childDelivery =
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries.last;
    expect(childDelivery.outcome, child);
    expect(childDelivery.causationExecutionId, _executionA);
    expect(childDelivery.rootCorrelationId, _correlationA);
    expect(childDelivery.depth, 4);
    expect(childDelivery.attemptCount, 0);
    expect(
      state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
      {_deliveryA},
    );
  });

  test('depth 8 dispatches while depth 9 terminalizes without callback',
      () async {
    for (final depth in [8, 9]) {
      var callbacks = 0;
      final transactions = _transactions([
        _delivery(_deliveryA, outcomeId: 'depth_$depth', depth: depth),
      ]);
      final processor = NarrativeOutcomeOutboxProcessor(
        activityPort: NoopNarrativeEventActivityPort(),
        stateTransactions: transactions,
        dispatcher: (request) async {
          callbacks++;
          return NarrativeOutcomeDispatchResult.delivered(
            updatedGameState: request.gameState,
          );
        },
        deliveryIdFactory: () => _deliveryB,
      );

      final result = await processor.processNext();

      expect(callbacks, depth == 8 ? 1 : 0);
      expect(
        result,
        depth == 8
            ? isA<NarrativeOutcomeOutboxDelivered>()
            : isA<NarrativeOutcomeOutboxTerminalized>().having(
                (value) => value.reason,
                'reason',
                NarrativeOutcomeTerminalReason.depthExceeded,
              ),
      );
      final state = await transactions.read();
      expect(state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
          isEmpty);
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        {_deliveryA},
      );
    }
  });

  test('empty outbox returns empty without dispatch', () async {
    var callbacks = 0;
    final processor = NarrativeOutcomeOutboxProcessor(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: _transactions(const []),
      dispatcher: (_) async {
        callbacks++;
        throw StateError('must not dispatch');
      },
      deliveryIdFactory: () => _deliveryA,
    );

    expect(await processor.processNext(), isA<NarrativeOutcomeOutboxEmpty>());
    expect(callbacks, 0);
  });

  test('memory overlap cleans pending without dispatch or children', () async {
    final overlapped = _delivery(_deliveryA, outcomeId: 'overlap');
    final transactions = _transactions(const []);
    var callbacks = 0;
    final processor = NarrativeOutcomeOutboxProcessor(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: transactions,
      snapshotFactory: (gameState) => _InjectedOverlapSnapshot(
        gameState,
        overlapped,
      ),
      dispatcher: (_) async {
        callbacks++;
        throw StateError('must not dispatch');
      },
      deliveryIdFactory: () => _deliveryB,
    );

    final result = await processor.processNext();
    final state = await transactions.read();

    expect(result, isA<NarrativeOutcomeOutboxDataInconsistency>());
    expect(
      (result as NarrativeOutcomeOutboxDataInconsistency).diagnosticCode,
      'dataInconsistency',
    );
    expect(callbacks, 0);
    expect(state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty);
    expect(
      state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
      {_deliveryA},
    );
  });

  test('composes with coordinator on the same transaction authority', () async {
    final head = _delivery(_deliveryA, outcomeId: 'head');
    final tail = _delivery(_deliveryB, outcomeId: 'tail');
    final transactions = _transactions([head, tail]);
    final source = NarrativeEventSourceRef.outcomeReceived(head.outcome);
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
            sceneId: 'scene_consumer',
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    );
    final authority = NarrativeEventDispatchAuthority.prepare(
      registryResult: EventRegistryDecodeResult.decoded(registry),
      occurrence: NarrativeEventOccurrence(
        source: source,
        rootCorrelationId: head.rootCorrelationId,
        depth: head.depth,
      ),
      factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
      projectCatalog: f1ProjectCatalogForRegistry(registry),
    ) as NarrativeEventDispatchAuthorityReady;
    final coordinator = NarrativeEventExecutionCoordinator(
      stateTransactions: transactions,
      planner: NarrativeEventDispatchPlanner(),
      executeScene: (request) async => NarrativeSceneExecutionResult.completed(
        updatedGameState: request.gameState.copyWith(
          metadata: const {'consumer': 'complete'},
        ),
        qualifiedOutcomes: [_outcome('consumer_child')],
      ),
      activityPort: NoopNarrativeEventActivityPort(),
      executionIdFactory: () => _executionA,
      correlationIdFactory: () => throw StateError('root already exists'),
      deliveryIdFactory: () => _deliveryC,
    );
    final processor = NarrativeOutcomeOutboxProcessor(
      stateTransactions: transactions,
      activityPort: NoopNarrativeEventActivityPort(),
      dispatcher: (request) async {
        final result = await coordinator.execute(authority: authority);
        final succeeded = result as NarrativeEventExecutionSucceeded;
        return NarrativeOutcomeDispatchResult.delivered(
          updatedGameState: succeeded.updatedGameState,
        );
      },
      deliveryIdFactory: () => throw StateError('no direct child'),
    );

    final result =
        await processor.processNext().timeout(const Duration(seconds: 2));
    final state = await transactions.read();

    expect(result, isA<NarrativeOutcomeOutboxDelivered>());
    expect(state.metadata, {'consumer': 'complete'});
    expect(
      state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries
          .map((delivery) => delivery.deliveryId),
      [_deliveryB, _deliveryC],
    );
    expect(
      state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
      {_deliveryA},
    );
  });
}

NarrativeEventStateTransactions _transactions(
  List<NarrativeOutcomeDelivery> pending,
) {
  return NarrativeEventStateTransactions(
    GameState(
      saveId: 'save',
      narrativeEventProgress: NarrativeEventProgress(
        pendingNarrativeOutcomeDeliveries: pending,
      ),
    ),
  );
}

NarrativeOutcomeDelivery _delivery(
  String deliveryId, {
  required String outcomeId,
  int depth = 0,
  int attemptCount = 0,
}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: _outcome(outcomeId),
    causationExecutionId: _executionA,
    rootCorrelationId: _correlationA,
    depth: depth,
    attemptCount: attemptCount,
  );
}

NarrativeOutcomeRef _outcome(String outcomeId) {
  return NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.scene,
    producerId: 'scene',
    outcomeId: outcomeId,
  );
}

final class _InjectedOverlapSnapshot implements NarrativeOutcomeOutboxSnapshot {
  _InjectedOverlapSnapshot(this.gameState, this.delivery);

  @override
  final GameState gameState;
  final NarrativeOutcomeDelivery delivery;

  @override
  Set<String> get consumedNarrativeEventIds => const {};

  @override
  List<NarrativeOutcomeDelivery> get pendingDeliveries => [delivery];

  @override
  Set<String> get deliveredDeliveryIds => {delivery.deliveryId};

  @override
  GameState replaceProgress(NarrativeEventProgress progress) {
    return gameState.copyWith(narrativeEventProgress: progress);
  }
}
