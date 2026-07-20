import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/f1_runtime_catalog_fixture.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000002';
const _eventC = 'evt_019abcde-0000-7000-8000-000000000003';

void main() {
  test('uses canonical Fact default and override values', () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final authority = _prepare(
      source,
      [
        _record(
          _eventA,
          source,
          conditions: [NarrativeEventCondition.fact('fact_gate', false)],
        ),
      ],
      facts: [
        NarrativeFactDefinition(
          id: 'fact_gate',
          label: 'Gate',
          defaultValue: true,
        ),
      ],
    );
    final planner = NarrativeEventDispatchPlanner();

    final defaultDecision = planner.plan(
      authority: authority,
      gameState: const GameState(saveId: 'save'),
    );
    final overrideDecision = planner.plan(
      authority: authority,
      gameState: GameState(
        saveId: 'save',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_gate': false},
        ),
      ),
    );

    expect(defaultDecision, isA<NarrativeEventDispatchNoMatch>());
    expect(defaultDecision.reasons,
        contains(NarrativeEventDispatchReason.factConditionFalse));
    expect(overrideDecision, isA<NarrativeEventDispatchHandled>());
  });

  test('evaluates typed integer and Unicode string Fact conditions', () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final authority = _prepare(
      source,
      [
        _record(
          _eventA,
          source,
          conditions: [
            NarrativeEventCondition.factValue(
              'fact_reputation',
              operator: NarrativeFactOperator.greaterThanOrEqual,
              expectedValue: NarrativeValue.integer(3),
            ),
            NarrativeEventCondition.factValue(
              'fact_codename',
              operator: NarrativeFactOperator.equals,
              expectedValue: const NarrativeValue.string('Brume 🌫️'),
            ),
          ],
        ),
      ],
      facts: [
        NarrativeFactDefinition(
          id: 'fact_reputation',
          label: 'Réputation',
          initialValue: NarrativeValue.integer(0),
        ),
        NarrativeFactDefinition(
          id: 'fact_codename',
          label: 'Nom de code',
          initialValue: const NarrativeValue.string('inconnu'),
        ),
      ],
    );

    final decision = NarrativeEventDispatchPlanner().plan(
      authority: authority,
      gameState: GameState(
        saveId: 'save',
        narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
          valuesByFactId: {
            'fact_reputation': NarrativeValue.integer(4),
            'fact_codename': const NarrativeValue.string('Brume 🌫️'),
          },
        ),
      ),
    );

    expect(decision, isA<NarrativeEventDispatchHandled>());
  });

  test('reads consumed conditions only from narrative progress', () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final authority = _prepare(
      source,
      [
        _record(
          _eventA,
          source,
          conditions: [
            NarrativeEventCondition.narrativeEventConsumed(_eventB, true),
          ],
        ),
        _record(
          _eventB,
          NarrativeEventSourceRef.mapEnter('other_map'),
        ),
      ],
    );
    final planner = NarrativeEventDispatchPlanner();

    final legacyOnly = planner.plan(
      authority: authority,
      gameState: const GameState(
        saveId: 'save',
        consumedEventIds: {_eventB},
      ),
    );
    final v2Progress = planner.plan(
      authority: authority,
      gameState: GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          consumedNarrativeEventIds: const {_eventB},
        ),
      ),
    );

    expect(legacyOnly, isA<NarrativeEventDispatchNoMatch>());
    expect(v2Progress, isA<NarrativeEventDispatchHandled>());
  });

  test('oneShot is blocked when consumed while reusable remains eligible', () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final authority = _prepare(source, [
      _record(_eventA, source, priority: 10),
      _record(
        _eventB,
        source,
        reusePolicy: NarrativeEventReusePolicy.reusable,
      ),
    ]);

    final decision = NarrativeEventDispatchPlanner().plan(
      authority: authority,
      gameState: GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          consumedNarrativeEventIds: const {_eventA, _eventB},
        ),
      ),
    );

    expect((decision as NarrativeEventDispatchHandled).eventId, _eventB);
  });

  test('excludes draft and disabled records and orders deterministically', () {
    final source = NarrativeEventSourceRef.mapEnter('map');
    final records = <NarrativeEventRecord>[
      NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: 'evt_019abcde-0000-7000-8000-000000000004',
          name: 'draft',
          source: source,
          conditions: const [],
          priority: 100,
          order: 0,
        ),
      ),
      _record('evt_019abcde-0000-7000-8000-000000000005', source,
          enabled: false, priority: 100),
      _record(_eventC, source, priority: 5, order: 0),
      _record(_eventB, source, priority: 10, order: 1),
      _record(_eventA, source, priority: 10, order: 1),
    ];
    final authority = _prepare(source, records);
    final planner = NarrativeEventDispatchPlanner();

    final decisions = List.generate(
      10,
      (_) => planner.plan(
        authority: authority,
        gameState: const GameState(saveId: 'save'),
      ),
    );

    expect(
      decisions
          .cast<NarrativeEventDispatchHandled>()
          .map((value) => value.eventId),
      everyElement(_eventA),
    );
    expect(records.map((value) => value.id), [
      'evt_019abcde-0000-7000-8000-000000000004',
      'evt_019abcde-0000-7000-8000-000000000005',
      _eventC,
      _eventB,
      _eventA,
    ]);
  });
}

NarrativeEventDispatchAuthorityReady _prepare(
  NarrativeEventSourceRef source,
  List<NarrativeEventRecord> records, {
  List<NarrativeFactDefinition> facts = const [],
}) {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: records,
    legacyClaims: const [],
  );
  return NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: NarrativeEventOccurrence(source: source),
    factResolver: NarrativeFactRuntimeResolver.fromFacts(facts),
    projectCatalog: f1ProjectCatalogForRegistry(registry),
  ) as NarrativeEventDispatchAuthorityReady;
}

NarrativeEventRecord _record(
  String id,
  NarrativeEventSourceRef source, {
  List<NarrativeEventCondition> conditions = const [],
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
  int priority = 0,
  int order = 0,
  bool enabled = true,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: id,
      source: source,
      conditions: conditions,
      sceneId: 'scene_$id',
      reusePolicy: reusePolicy,
      priority: priority,
      order: order,
    ),
    enabled: enabled,
  );
}
