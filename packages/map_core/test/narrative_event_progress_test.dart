import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000002';
const _deliveryA = 'outd_019abcde-0000-7000-8000-000000000001';
const _deliveryB = 'outd_019abcde-0000-7000-8000-000000000002';
const _correlation = 'corr_019abcde-0000-7000-8000-000000000001';

void main() {
  test('empty progress has three empty immutable collections', () {
    const progress = NarrativeEventProgress.empty();

    expect(progress.consumedNarrativeEventIds, isEmpty);
    expect(progress.pendingNarrativeOutcomeDeliveries, isEmpty);
    expect(progress.deliveredNarrativeOutcomeDeliveryIds, isEmpty);
    expect(
      () => progress.consumedNarrativeEventIds.add(_eventA),
      throwsUnsupportedError,
    );
    expect(
      () => progress.pendingNarrativeOutcomeDeliveries.add(_pending()),
      throwsUnsupportedError,
    );
    expect(
      () => progress.deliveredNarrativeOutcomeDeliveryIds.add(_deliveryA),
      throwsUnsupportedError,
    );
  });

  test('defensively copies inputs and preserves pending FIFO', () {
    final consumed = <String>{_eventB};
    final pending = <NarrativeOutcomeDelivery>[
      _pending(deliveryId: _deliveryB),
      _pending(deliveryId: _deliveryA),
    ];
    final delivered = <String>{};

    final progress = NarrativeEventProgress(
      consumedNarrativeEventIds: consumed,
      pendingNarrativeOutcomeDeliveries: pending,
      deliveredNarrativeOutcomeDeliveryIds: delivered,
    );
    consumed.add(_eventA);
    pending.clear();
    delivered.add(_deliveryA);

    expect(progress.consumedNarrativeEventIds, {_eventB});
    expect(
      progress.pendingNarrativeOutcomeDeliveries
          .map((delivery) => delivery.deliveryId),
      [_deliveryB, _deliveryA],
    );
    expect(progress.deliveredNarrativeOutcomeDeliveryIds, isEmpty);
  });

  test('rejects duplicate pending and terminal identities and overlap', () {
    expect(
      () => NarrativeEventProgress(
        pendingNarrativeOutcomeDeliveries: [_pending(), _pending()],
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeEventProgress(
        deliveredNarrativeOutcomeDeliveryIds: [_deliveryA, _deliveryA],
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeEventProgress(
        pendingNarrativeOutcomeDeliveries: [_pending()],
        deliveredNarrativeOutcomeDeliveryIds: [_deliveryA],
      ),
      throwsArgumentError,
    );
  });

  test('preserves orphan consumed IDs without touching legacy state', () {
    final progress = NarrativeEventProgress(
      consumedNarrativeEventIds: const {_eventA, _eventB},
    );
    final state = GameState(
      saveId: 'save',
      consumedEventIds: const {'legacy_local_id'},
      storyFlags: const StoryFlags(activeFlags: {'legacy_flag'}),
      narrativeEventProgress: progress,
    );

    expect(state.narrativeEventProgress.consumedNarrativeEventIds, {
      _eventA,
      _eventB,
    });
    expect(state.consumedEventIds, {'legacy_local_id'});
    expect(state.storyFlags.activeFlags, {'legacy_flag'});
  });
}

NarrativeOutcomeDelivery _pending({String deliveryId = _deliveryA}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: 'scene',
      outcomeId: 'done',
    ),
    rootCorrelationId: _correlation,
    depth: 0,
    attemptCount: 0,
  );
}
