import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _correlationId = 'corr_019abcde-0000-7000-8000-000000000001';

void main() {
  test('wraps each qualified V0 source kind', () {
    final outcome = NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: 'scene_intro',
      outcomeId: 'accepted',
    );
    final sources = <NarrativeEventSourceRef>[
      NarrativeEventSourceRef.entityInteract('map_town', 'entity_professor'),
      NarrativeEventSourceRef.triggerEnter('map_town', 'trigger_gate'),
      NarrativeEventSourceRef.mapEnter('map_town'),
      NarrativeEventSourceRef.outcomeReceived(outcome),
    ];

    final occurrences = [
      for (final source in sources) NarrativeEventOccurrence(source: source),
    ];

    expect(
      occurrences.map((occurrence) => occurrence.source.kind),
      [
        NarrativeEventSourceKind.entityInteract,
        NarrativeEventSourceKind.triggerEnter,
        NarrativeEventSourceKind.mapEnter,
        NarrativeEventSourceKind.outcomeReceived,
      ],
    );
  });

  test('keeps optional legacy provenance and orchestration identity', () {
    final source = NarrativeEventSourceRef.mapEnter('map_town');
    final provenance = LegacySourceRef.mapEvent('map_town', 'legacy_intro');

    final occurrence = NarrativeEventOccurrence(
      source: source,
      provenance: provenance,
      rootCorrelationId: _correlationId,
      depth: 9,
    );

    expect(occurrence.source, source);
    expect(occurrence.provenance, provenance);
    expect(occurrence.rootCorrelationId, _correlationId);
    expect(occurrence.depth, 9);
  });

  test('rejects malformed correlation IDs and negative depth', () {
    final source = NarrativeEventSourceRef.mapEnter('map_town');

    expect(
      () => NarrativeEventOccurrence(
        source: source,
        rootCorrelationId: 'corr_invalid',
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeEventOccurrence(source: source, depth: -1),
      throwsArgumentError,
    );
  });
}
