import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000002';
const _deliveryA = 'outd_019abcde-0000-7000-8000-000000000001';
const _deliveryB = 'outd_019abcde-0000-7000-8000-000000000002';
const _correlation = 'corr_019abcde-0000-7000-8000-000000000001';

void main() {
  test('encodes consumed and delivered sets lexically and pending FIFO', () {
    final progress = NarrativeEventProgress(
      consumedNarrativeEventIds: const {_eventB, _eventA},
      pendingNarrativeOutcomeDeliveries: [
        _pending(_deliveryB),
        _pending(_deliveryA),
      ],
      deliveredNarrativeOutcomeDeliveryIds: const {
        'outd_019abcde-0000-7000-8000-000000000004',
        'outd_019abcde-0000-7000-8000-000000000003',
      },
    );

    final json = progress.toJson();

    expect(json['consumedNarrativeEventIds'], [_eventA, _eventB]);
    expect(
      (json['pendingNarrativeOutcomeDeliveries'] as List)
          .map((entry) => (entry as Map)['deliveryId']),
      [_deliveryB, _deliveryA],
    );
    expect(json['deliveredNarrativeOutcomeDeliveryIds'], [
      'outd_019abcde-0000-7000-8000-000000000003',
      'outd_019abcde-0000-7000-8000-000000000004',
    ]);
    expect(NarrativeEventProgress.fromJson(json), progress);
  });

  test('round-trips progress through GameState JSON', () {
    final progress = NarrativeEventProgress(
      consumedNarrativeEventIds: const {_eventA},
      pendingNarrativeOutcomeDeliveries: [_pending(_deliveryA)],
      deliveredNarrativeOutcomeDeliveryIds: const {
        'outd_019abcde-0000-7000-8000-000000000003',
      },
    );
    final state = GameState(
      saveId: 'round_trip',
      narrativeEventProgress: progress,
    );

    final restored = GameState.fromJson(state.toJson());

    expect(restored.narrativeEventProgress, progress);
  });

  test('strict decoder rejects duplicates overlap nulls and unknown fields',
      () {
    final pending = _pending(_deliveryA).toJson();
    final base = <String, Object?>{
      'consumedNarrativeEventIds': <Object?>[],
      'pendingNarrativeOutcomeDeliveries': <Object?>[],
      'deliveredNarrativeOutcomeDeliveryIds': <Object?>[],
    };

    expect(
      () => NarrativeEventProgress.fromJson({
        ...base,
        'pendingNarrativeOutcomeDeliveries': [pending, pending],
      }),
      throwsFormatException,
    );
    expect(
      () => NarrativeEventProgress.fromJson({
        ...base,
        'deliveredNarrativeOutcomeDeliveryIds': [_deliveryA, _deliveryA],
      }),
      throwsFormatException,
    );
    expect(
      () => NarrativeEventProgress.fromJson({
        ...base,
        'pendingNarrativeOutcomeDeliveries': [pending],
        'deliveredNarrativeOutcomeDeliveryIds': [_deliveryA],
      }),
      throwsFormatException,
    );
    expect(
      () => NarrativeEventProgress.fromJson({
        ...base,
        'pendingNarrativeOutcomeDeliveries': null,
      }),
      throwsFormatException,
    );
    expect(
      () => NarrativeEventProgress.fromJson({...base, 'status': 'pending'}),
      throwsFormatException,
    );
  });

  test('missing aggregate defaults empty while explicit null rejects', () {
    final state = GameState.fromJson({
      'saveId': 'old',
      'consumedEventIds': ['legacy_local'],
      'storyFlags': {
        'activeFlags': ['legacy_flag'],
      },
    });
    final save = SaveData.fromJson({
      'saveId': 'old',
      'progression': {
        'storyFlags': ['legacy_flag'],
      },
    });

    expect(state.narrativeEventProgress, const NarrativeEventProgress.empty());
    expect(save.narrativeEventProgress, const NarrativeEventProgress.empty());
    expect(state.consumedEventIds, {'legacy_local'});
    expect(state.storyFlags.activeFlags, {'legacy_flag'});
    expect(save.progression.storyFlags, ['legacy_flag']);
    expect(
      () => GameState.fromJson({
        'saveId': 'bad',
        'narrativeEventProgress': null,
      }),
      throwsFormatException,
    );
    expect(
      () => SaveData.fromJson({
        'saveId': 'bad',
        'narrativeEventProgress': null,
      }),
      throwsFormatException,
    );
  });
}

NarrativeOutcomeDelivery _pending(String deliveryId) {
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
