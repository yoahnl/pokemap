import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const _deliveryA = 'outd_019abcde-0000-7000-8000-000000000001';
const _deliveryB = 'outd_019abcde-0000-7000-8000-000000000003';
const _correlationA = 'corr_019abcde-0000-7000-8000-000000000002';

void main() {
  test('reentrant processing returns busy immediately', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    var callbacks = 0;
    final activity = _RecordingActivityPort();
    final transactions = NarrativeEventStateTransactions(
      GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          pendingNarrativeOutcomeDeliveries: [_delivery()],
        ),
      ),
    );
    final processor = NarrativeOutcomeOutboxProcessor(
      stateTransactions: transactions,
      activityPort: activity,
      dispatcher: (request) async {
        callbacks++;
        started.complete();
        await release.future;
        return NarrativeOutcomeDispatchResult.delivered(
          updatedGameState: request.gameState,
        );
      },
      deliveryIdFactory: () => throw StateError('no child'),
    );

    final first = processor.processNext();
    await started.future;
    final second = await processor.processNext();

    expect(second, isA<NarrativeOutcomeOutboxBusy>());
    expect(callbacks, 1);
    expect(activity.active, [NarrativeEventActivity.outboxProcessing]);
    release.complete();
    expect(await first, isA<NarrativeOutcomeOutboxDelivered>());
    expect(activity.active, isEmpty);
    expect(activity.entries, [NarrativeEventActivity.outboxProcessing]);
  });

  test('processors sharing transactions serialize different FIFO heads',
      () async {
    final started = Completer<void>();
    final release = Completer<void>();
    final seen = <String>[];
    final transactions = NarrativeEventStateTransactions(
      GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          pendingNarrativeOutcomeDeliveries: [
            _delivery(_deliveryA),
            _delivery(_deliveryB),
          ],
        ),
      ),
    );
    Future<NarrativeOutcomeDispatchResult> dispatch(
      NarrativeOutcomeDispatchRequest request,
    ) async {
      seen.add(request.delivery.deliveryId);
      if (request.delivery.deliveryId == _deliveryA) {
        started.complete();
        await release.future;
      }
      return NarrativeOutcomeDispatchResult.delivered(
        updatedGameState: request.gameState,
      );
    }

    final firstProcessor = NarrativeOutcomeOutboxProcessor(
      stateTransactions: transactions,
      activityPort: NoopNarrativeEventActivityPort(),
      dispatcher: dispatch,
      deliveryIdFactory: () => throw StateError('no child'),
    );
    final secondProcessor = NarrativeOutcomeOutboxProcessor(
      stateTransactions: transactions,
      activityPort: NoopNarrativeEventActivityPort(),
      dispatcher: dispatch,
      deliveryIdFactory: () => throw StateError('no child'),
    );

    final first = firstProcessor.processNext();
    await started.future;
    final second = secondProcessor.processNext();
    await Future<void>.delayed(Duration.zero);
    expect(seen, [_deliveryA]);

    release.complete();
    expect(await first, isA<NarrativeOutcomeOutboxDelivered>());
    expect(await second, isA<NarrativeOutcomeOutboxDelivered>());
    expect(seen, [_deliveryA, _deliveryB]);
    final state = await transactions.read();
    expect(
      state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
      isEmpty,
    );
  });
}

NarrativeOutcomeDelivery _delivery([String deliveryId = _deliveryA]) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.legacyScenario,
      producerId: 'legacy',
      outcomeId: 'done',
    ),
    rootCorrelationId: _correlationA,
    depth: 0,
    attemptCount: 0,
  );
}

final class _RecordingActivityPort implements NarrativeEventActivityPort {
  final List<NarrativeEventActivity> entries = [];
  final List<NarrativeEventActivity> active = [];

  @override
  Future<T> runWithActivity<T>(
    NarrativeEventActivity activity,
    Future<T> Function() action,
  ) async {
    entries.add(activity);
    active.add(activity);
    try {
      return await action();
    } finally {
      active.removeLast();
    }
  }
}
