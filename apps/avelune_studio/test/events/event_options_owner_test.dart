import 'package:avelune_studio/features/events/application/event_labels.dart';
import 'package:avelune_studio/features/events/application/event_option_choices.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final outcome = NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.scene,
    producerId: 'bg-labo',
    outcomeId: 'oeuf-recu',
  );
  final noOutcomes = NarrativeOutcomeEventSourceCatalog(
    options: const [],
    diagnostics: const [],
  );

  NarrativeEventRecord record({
    NarrativeEventReusePolicy? reuse = NarrativeEventReusePolicy.oneShot,
    NarrativeEventResetPolicy reset = const NarrativeEventResetPolicy.never(),
    NarrativeEventSourceRef? source,
    NarrativeEventParallelPolicy? parallel,
  }) => NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: 'evt_00000000-0000-7000-8000-000000000001',
      name: 'Arrivée',
      source: source ?? NarrativeEventSourceRef.mapEnter('map'),
      conditions: const [],
      reusePolicy: reuse,
      resetPolicy: reset,
      priority: 100,
      order: 0,
      parallelPolicy: parallel,
    ),
  );

  test('the in-game effect is stated for a single occurrence never reset', () {
    expect(
      eventRepeatEffect(record(), noOutcomes),
      'Une seule fois dans la partie.',
    );
    expect(eventResetNote(record()), isNull);
  });

  test('each verified replay rule has its own sentence', () {
    expect(
      eventRepeatEffect(
        record(reset: const NarrativeEventResetPolicy.onMapReentry()),
        noOutcomes,
      ),
      'Une fois par visite : se rejoue après avoir quitté puis retrouvé sa carte.',
    );
    expect(
      eventRepeatEffect(
        record(reset: NarrativeEventResetPolicy.onOutcomeReceived(outcome)),
        noOutcomes,
      ),
      'Une fois, puis à nouveau après le résultat « oeuf-recu ».',
    );
    final reusable = record(reuse: NarrativeEventReusePolicy.reusable);
    expect(
      eventRepeatEffect(reusable, noOutcomes),
      'À chaque déclenchement, tant que ses conditions sont remplies.',
    );
    expect(
      eventResetNote(reusable),
      'Sans effet : l’événement peut déjà se rejouer.',
    );
    expect(
      eventRepeatEffect(record(reuse: null), noOutcomes),
      'À définir : choisissez ce qui se passe après une première lecture.',
    );
  });

  test('the summary states the repeat effect with a unique outcome label', () {
    final labelled = NarrativeOutcomeEventSourceCatalog(
      options: [
        _option(outcome, 'Œuf reçu'),
      ],
      diagnostics: const [],
    );
    final ambiguous = NarrativeOutcomeEventSourceCatalog(
      options: [
        for (final label in ['Œuf reçu', 'Œuf donné'])
          _option(outcome, label),
      ],
      diagnostics: const [],
    );
    final value = record(
      reset: NarrativeEventResetPolicy.onOutcomeReceived(outcome),
    );

    expect(
      eventRepeatEffect(value, labelled),
      'Une fois, puis à nouveau après le résultat « Œuf reçu ».',
    );
    expect(
      eventRepeatEffect(value, ambiguous),
      'Une fois, puis à nouveau après le résultat « oeuf-recu ».',
    );
  });

  test('reset choices map to their policies and outcome needs a producer', () {
    expect(eventResetChoice(const NarrativeEventResetPolicy.never()), 'never');
    expect(
      eventResetChoice(const NarrativeEventResetPolicy.onMapReentry()),
      'map',
    );
    expect(
      eventResetChoice(NarrativeEventResetPolicy.onOutcomeReceived(outcome)),
      'outcome',
    );
    expect(
      eventResetWithoutOutcome('never'),
      const NarrativeEventResetPolicy.never(),
    );
    expect(
      eventResetWithoutOutcome('map'),
      const NarrativeEventResetPolicy.onMapReentry(),
    );
    expect(eventResetWithoutOutcome('outcome'), isNull);
  });

  test('parallel owner picker distinguishes an actual all page from every page', () {
    final policy = NarrativeEventParallelPolicy(
      cadenceMs: 350,
      ownerVariantId: 'all',
    );

    expect(eventParallelOwnerChoice(policy), 'all');
    final every = eventParallelOwnerPage(policy, eventAllOwnerPages);
    expect(every.ownerVariantId, isNull);
    expect(every.cadenceMs, 350);
    expect(eventParallelOwnerChoice(every), eventAllOwnerPages);
    final page = eventParallelOwnerPage(every, 'all');
    expect(page.ownerVariantId, 'all');
    expect(page.cadenceMs, 350);
  });

  test('guided options expose execution mode and validated cadence', () {
    final policy = NarrativeEventParallelPolicy(
      cadenceMs: 350,
      ownerVariantId: 'page-2',
    );

    expect(eventAllowsParallel(record()), isTrue);
    expect(
      eventAllowsParallel(
        record(source: NarrativeEventSourceRef.entityAutorun('map', 'owner')),
      ),
      isTrue,
    );
    expect(
      eventAllowsParallel(
        record(source: NarrativeEventSourceRef.entityInteract('map', 'owner')),
      ),
      isFalse,
    );
    expect(eventParallelChoice('parallel')!.cadenceMs, 1000);
    expect(eventParallelChoice('sequential'), isNull);
    for (final invalid in ['99', '60001', 'abc', '']) {
      expect(eventParallelCadence(policy, invalid), isNull, reason: invalid);
    }
    final next = eventParallelCadence(policy, '500')!;
    expect(next.cadenceMs, 500);
    expect(next.ownerVariantId, 'page-2');
    expect(eventParallelCadence(policy, '100')!.cadenceMs, 100);
    expect(eventParallelCadence(policy, '60000')!.cadenceMs, 60000);
  });

  test('owner pages are numbered only for a unique automatic owner', () {
    final source = NarrativeEventSourceRef.entityAutorun('map', 'owner');
    final variants = MapEntityPresentation(
      variants: [
        for (final id in ['all', 'night'])
          MapEntityPresentationVariant(
            id: id,
            condition: NarrativeEventConditionExpression.all(const []),
            blocksMovement: false,
          ),
      ],
    );
    MapData map(List<MapEntity> entities) => MapData(
      id: 'map',
      name: 'Carte',
      size: const GridSize(width: 4, height: 4),
      layers: const [],
      entities: entities,
    );
    final owner = MapEntity(
      id: 'owner',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 1),
      presentation: variants,
    );

    expect(eventOwnerPages(record(source: source), [map([owner])]), {
      'all': 'Page 1',
      'night': 'Page 2',
    });
    expect(eventOwnerPages(record(source: source), [map([owner, owner])]), isEmpty);
    expect(
      eventOwnerPages(record(source: source), [map([owner]), map([owner])]),
      isEmpty,
    );
    expect(
      eventOwnerPages(
        record(source: NarrativeEventSourceRef.entityInteract('map', 'owner')),
        [map([owner])],
      ),
      isEmpty,
    );
    expect(eventOwnerPages(record(source: source), const []), isEmpty);
  });
}

NarrativeOutcomeEventSourceOption _option(
  NarrativeOutcomeRef outcome,
  String label,
) => NarrativeOutcomeEventSourceOption(
  outcome: outcome,
  producerLabel: 'Laboratoire',
  outcomeLabel: label,
  humanSourceSentence: 'Quand le laboratoire émet $label',
  status: NarrativeOutcomeReachabilityStatus.reachable,
  selectable: true,
  origin: NarrativeOutcomeSourceOrigin.scene,
  debugTechnicalLabel: 'scene:bg-labo:oeuf-recu',
);
