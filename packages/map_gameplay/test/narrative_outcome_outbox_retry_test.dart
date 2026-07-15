import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const _deliveryA = 'outd_019abcde-0000-7000-8000-000000000001';
const _executionA = 'evx_019abcde-0000-7000-8000-000000000002';
const _correlationA = 'corr_019abcde-0000-7000-8000-000000000003';

void main() {
  test('retries only infrastructure-before-planning with stable fields',
      () async {
    final original = _delivery();
    final transactions = _transactions(original);
    final attempts = <NarrativeOutcomeDelivery>[];
    final processor = NarrativeOutcomeOutboxProcessor(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: transactions,
      dispatcher: (request) async {
        attempts.add(request.delivery);
        return NarrativeOutcomeDispatchResult
            .infrastructureFailureBeforePlanning(
          'offline',
        );
      },
      deliveryIdFactory: () => throw StateError('no child'),
    );

    final first = await processor.processNext();
    final second = await processor.processNext();
    final third = await processor.processNext();
    final state = await transactions.read();

    expect(first, isA<NarrativeOutcomeOutboxRetryScheduled>());
    expect(second, isA<NarrativeOutcomeOutboxRetryScheduled>());
    expect(
      third,
      isA<NarrativeOutcomeOutboxTerminalized>().having(
        (value) => value.reason,
        'reason',
        NarrativeOutcomeTerminalReason.retryLimitReached,
      ),
    );
    expect(attempts.map((value) => value.attemptCount), [0, 1, 2]);
    for (final attempt in attempts) {
      expect(attempt.deliveryId, original.deliveryId);
      expect(attempt.outcome, original.outcome);
      expect(attempt.causationExecutionId, original.causationExecutionId);
      expect(attempt.rootCorrelationId, original.rootCorrelationId);
      expect(attempt.depth, original.depth);
    }
    expect(state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty);
    expect(
      state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
      {_deliveryA},
    );
  });

  test('terminal dispatcher result never retries', () async {
    final transactions = _transactions(_delivery());
    var callbacks = 0;
    final processor = NarrativeOutcomeOutboxProcessor(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: transactions,
      dispatcher: (_) async {
        callbacks++;
        return NarrativeOutcomeDispatchResult.terminalFailure('consumerFailed');
      },
      deliveryIdFactory: () => throw StateError('no child'),
    );

    final result = await processor.processNext();
    final next = await processor.processNext();

    expect(
      result,
      isA<NarrativeOutcomeOutboxTerminalized>().having(
        (value) => value.reason,
        'reason',
        NarrativeOutcomeTerminalReason.dispatcherTerminalFailure,
      ),
    );
    expect(next, isA<NarrativeOutcomeOutboxEmpty>());
    expect(callbacks, 1);
  });

  test('unknown dispatcher exception terminalizes without retry', () async {
    final transactions = _transactions(_delivery());
    var callbacks = 0;
    final processor = NarrativeOutcomeOutboxProcessor(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: transactions,
      dispatcher: (_) async {
        callbacks++;
        throw StateError('unknown');
      },
      deliveryIdFactory: () => throw StateError('no child'),
    );

    final result = await processor.processNext();

    expect(
      result,
      isA<NarrativeOutcomeOutboxTerminalized>().having(
        (value) => value.reason,
        'reason',
        NarrativeOutcomeTerminalReason.dispatcherException,
      ),
    );
    expect(callbacks, 1);
    expect(
      (await transactions.read())
          .narrativeEventProgress
          .deliveredNarrativeOutcomeDeliveryIds,
      {_deliveryA},
    );
  });

  test('attempt count already at limit terminalizes without dispatch',
      () async {
    final transactions = _transactions(_delivery(attemptCount: 3));
    var callbacks = 0;
    final processor = NarrativeOutcomeOutboxProcessor(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: transactions,
      dispatcher: (_) async {
        callbacks++;
        return NarrativeOutcomeDispatchResult.delivered(
          updatedGameState: const GameState(saveId: 'save'),
        );
      },
      deliveryIdFactory: () => throw StateError('no child'),
    );

    final result = await processor.processNext();

    expect(callbacks, 0);
    expect(
      result,
      isA<NarrativeOutcomeOutboxTerminalized>().having(
        (value) => value.reason,
        'reason',
        NarrativeOutcomeTerminalReason.retryLimitReached,
      ),
    );
  });

  test('post-dispatch child construction exception terminalizes', () async {
    final transactions = _transactions(_delivery());
    var callbacks = 0;
    final processor = NarrativeOutcomeOutboxProcessor(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: transactions,
      dispatcher: (request) async {
        callbacks++;
        return NarrativeOutcomeDispatchResult.delivered(
          updatedGameState: request.gameState,
          qualifiedChildOutcomes: [
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'scene',
              outcomeId: 'child',
            ),
          ],
        );
      },
      deliveryIdFactory: () => 'invalid',
    );

    final result = await processor.processNext();

    expect(callbacks, 1);
    expect(
      result,
      isA<NarrativeOutcomeOutboxTerminalized>().having(
        (value) => value.reason,
        'reason',
        NarrativeOutcomeTerminalReason.dispatcherException,
      ),
    );
    expect(
      (await transactions.read())
          .narrativeEventProgress
          .deliveredNarrativeOutcomeDeliveryIds,
      {_deliveryA},
    );
  });
}

NarrativeEventStateTransactions _transactions(
  NarrativeOutcomeDelivery delivery,
) {
  return NarrativeEventStateTransactions(
    GameState(
      saveId: 'save',
      narrativeEventProgress: NarrativeEventProgress(
        pendingNarrativeOutcomeDeliveries: [delivery],
      ),
    ),
  );
}

NarrativeOutcomeDelivery _delivery({int attemptCount = 0}) {
  return NarrativeOutcomeDelivery(
    deliveryId: _deliveryA,
    outcome: NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.battle,
      producerId: 'battle',
      outcomeId: 'victory',
    ),
    causationExecutionId: _executionA,
    rootCorrelationId: _correlationA,
    depth: 2,
    attemptCount: attemptCount,
  );
}
