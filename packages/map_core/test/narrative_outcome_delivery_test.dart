import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _deliveryId = 'outd_019abcde-0000-7000-8000-000000000001';
const _executionId = 'evx_019abcde-0000-7000-8000-000000000002';
const _correlationId = 'corr_019abcde-0000-7000-8000-000000000003';

void main() {
  test('round-trips exactly the six ratified fields', () {
    final delivery = NarrativeOutcomeDelivery(
      deliveryId: _deliveryId,
      outcome: NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: 'battle_rival',
        outcomeId: 'victory',
      ),
      causationExecutionId: _executionId,
      rootCorrelationId: _correlationId,
      depth: 9,
      attemptCount: 2,
    );

    final json = delivery.toJson();

    expect(json.keys.toSet(), {
      'deliveryId',
      'outcome',
      'causationExecutionId',
      'rootCorrelationId',
      'depth',
      'attemptCount',
    });
    expect(NarrativeOutcomeDelivery.fromJson(json), delivery);
  });

  test('encodes nullable causation explicitly', () {
    final delivery = NarrativeOutcomeDelivery(
      deliveryId: _deliveryId,
      outcome: NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_intro',
        outcomeId: 'done',
      ),
      rootCorrelationId: _correlationId,
      depth: 0,
      attemptCount: 0,
    );

    expect(delivery.toJson(), containsPair('causationExecutionId', null));
  });

  test('rejects malformed IDs, negative counters, and extra wire fields', () {
    final valid = <String, Object?>{
      'deliveryId': _deliveryId,
      'outcome': {
        'producerKind': 'scene',
        'producerId': 'scene_intro',
        'outcomeId': 'done',
      },
      'causationExecutionId': null,
      'rootCorrelationId': _correlationId,
      'depth': 0,
      'attemptCount': 0,
    };

    expect(
      () => NarrativeOutcomeDelivery.fromJson({...valid, 'dispatchId': 'x'}),
      throwsFormatException,
    );
    expect(
      () => NarrativeOutcomeDelivery.fromJson({...valid, 'depth': -1}),
      throwsFormatException,
    );
    expect(
      () => NarrativeOutcomeDelivery.fromJson(
        {...valid, 'attemptCount': -1},
      ),
      throwsFormatException,
    );
    expect(
      () => NarrativeOutcomeDelivery.fromJson(
        {...valid, 'deliveryId': 'outd_invalid'},
      ),
      throwsFormatException,
    );
    expect(
      () => NarrativeOutcomeDelivery.fromJson(
        {...valid, 'causationExecutionId': 'evx_invalid'},
      ),
      throwsFormatException,
    );
  });
}
