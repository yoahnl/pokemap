import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000002';
const _eventC = 'evt_019abcde-0000-7000-8000-000000000003';
const _eventD = 'evt_019abcde-0000-7000-8000-000000000004';

void main() {
  group('Narrative Event V2 B4 structural source index', () {
    test(
        'keeps an empty registry empty and excludes drafts and disabled records',
        () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final empty = buildNarrativeEventSourceIndex(const []);
      final filtered = buildNarrativeEventSourceIndex([
        NarrativeEventRecord.draft(_draft(_eventA)),
        _configured(_eventB, source: source, enabled: false),
      ]);

      expect(empty.index.sources, isEmpty);
      expect(empty.conflicts, isEmpty);
      expect(filtered.index.sources, isEmpty);
      expect(filtered.index.recordsFor(source), isEmpty);
    });

    test('groups all four structural source kinds without conflating outcomes',
        () {
      final sceneOutcome = NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'producer',
          outcomeId: 'victory',
        ),
      );
      final battleOutcome = NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.battle,
          producerId: 'producer',
          outcomeId: 'victory',
        ),
      );
      final sources = [
        NarrativeEventSourceRef.entityInteract('map_port', 'npc'),
        NarrativeEventSourceRef.triggerEnter('map_port', 'zone'),
        NarrativeEventSourceRef.mapEnter('map_port'),
        sceneOutcome,
        battleOutcome,
      ];
      final result = buildNarrativeEventSourceIndex([
        for (var index = 0; index < sources.length; index++)
          _configured(
            _ids[index],
            source: sources[index],
            enabled: true,
          ),
      ]);

      expect(result.index.sources, hasLength(5));
      for (final source in sources) {
        expect(result.index.recordsFor(source), hasLength(1));
      }
      expect(
        result.index.recordsFor(
          NarrativeEventSourceRef.entityInteract('map_port', 'npc'),
        ),
        hasLength(1),
        reason: 'lookup must use structural equality, not object identity',
      );
      expect(sceneOutcome, isNot(battleOutcome));
    });

    test('sorts priority DESC order ASC then Event ID ASC', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final result = buildNarrativeEventSourceIndex([
        _configured(
          _eventA,
          source: source,
          enabled: true,
          priority: 1,
          order: 2,
        ),
        _configured(
          _eventD,
          source: source,
          enabled: true,
          priority: 2,
          order: 5,
        ),
        _configured(
          _eventC,
          source: source,
          enabled: true,
          priority: 2,
          order: 1,
        ),
        _configured(
          _eventB,
          source: source,
          enabled: true,
          priority: 2,
          order: 1,
        ),
      ]);

      expect(
        result.index.recordsFor(source).map((record) => record.id),
        [_eventB, _eventC, _eventD, _eventA],
      );
    });

    test('reports exact ties while retaining every conflicting record', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final result = buildNarrativeEventSourceIndex([
        _configured(
          _eventC,
          source: source,
          enabled: true,
          priority: 4,
          order: 2,
        ),
        _configured(
          _eventA,
          source: source,
          enabled: true,
          priority: 4,
          order: 2,
        ),
        _configured(
          _eventB,
          source: source,
          enabled: true,
          priority: 3,
          order: 0,
        ),
      ]);

      expect(result.hasConflicts, isTrue);
      expect(result.conflicts, hasLength(1));
      final conflict = result.conflicts.single;
      expect(conflict.source, source);
      expect(conflict.priority, 4);
      expect(conflict.order, 2);
      expect(conflict.records.map((record) => record.id), [_eventA, _eventC]);
      expect(result.index.recordsFor(source), hasLength(3));
      expect(conflict.diagnostic, contains(_eventA));
      expect(conflict.diagnostic, contains(_eventC));
      expect(() => conflict.records.clear(), throwsUnsupportedError);
    });

    test('orders multiple conflict groups stably without declaring a winner',
        () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final result = buildNarrativeEventSourceIndex([
        _configured(
          _eventA,
          source: source,
          enabled: true,
          priority: 2,
          order: 1,
        ),
        _configured(
          _eventB,
          source: source,
          enabled: true,
          priority: 2,
          order: 1,
        ),
        _configured(
          _eventC,
          source: source,
          enabled: true,
          priority: 4,
          order: 3,
        ),
        _configured(
          _eventD,
          source: source,
          enabled: true,
          priority: 4,
          order: 3,
        ),
      ]);

      expect(result.conflicts.map((conflict) => conflict.priority), [4, 2]);
      expect(result.conflicts[0].records.map((record) => record.id), [
        _eventC,
        _eventD,
      ]);
      expect(result.conflicts[1].records.map((record) => record.id), [
        _eventA,
        _eventB,
      ]);
      expect(result.index.recordsFor(source), hasLength(4));
    });

    test('indexes enabled records without evaluating their conditions', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final result = buildNarrativeEventSourceIndex([
        _configured(
          _eventA,
          source: source,
          enabled: true,
          conditions: [NarrativeEventCondition.fact('gate', true)],
        ),
        _configured(
          _eventB,
          source: source,
          enabled: true,
          conditions: [NarrativeEventCondition.fact('gate', false)],
        ),
      ]);

      expect(result.index.recordsFor(source), hasLength(2));
      expect(result.conflicts.single.records, hasLength(2));
    });

    test('does not mutate registry author order and exposes immutable lookups',
        () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final records = [
        _configured(_eventC, source: source, enabled: true, priority: 0),
        _configured(_eventA, source: source, enabled: true, priority: 2),
        _configured(_eventB, source: source, enabled: true, priority: 1),
      ];
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: records,
        legacyClaims: const [],
      );
      final before = registry.toJson();
      final result = buildNarrativeEventSourceIndex(registry.records);

      expect(registry.records.map((record) => record.id), [
        _eventC,
        _eventA,
        _eventB,
      ]);
      expect(registry.toJson(), before);
      expect(
        () => result.index.recordsFor(source).clear(),
        throwsUnsupportedError,
      );
      expect(
        () => result.conflicts.clear(),
        throwsUnsupportedError,
      );
    });

    test('returns an immutable empty lookup for an unknown source', () {
      final result = buildNarrativeEventSourceIndex([
        _configured(
          _eventA,
          source: NarrativeEventSourceRef.mapEnter('known'),
          enabled: true,
        ),
      ]);
      final unknown = NarrativeEventSourceRef.mapEnter('unknown');

      expect(result.index.containsSource(unknown), isFalse);
      expect(result.index.recordsFor(unknown), isEmpty);
      expect(
        () => result.index.recordsFor(unknown).add(
              _configured(_eventB, source: unknown, enabled: true),
            ),
        throwsUnsupportedError,
      );
    });
  });
}

const _ids = [_eventA, _eventB, _eventC, _eventD, _eventE];
const _eventE = 'evt_019abcde-0000-7000-8000-000000000005';

NarrativeEventDraft _draft(String id) => NarrativeEventDraft(
      id: id,
      name: id,
      conditions: const [],
      priority: 0,
      order: 0,
    );

NarrativeEventRecord _configured(
  String id, {
  required NarrativeEventSourceRef source,
  required bool enabled,
  int priority = 0,
  int order = 0,
  List<NarrativeEventCondition> conditions = const [],
}) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: id,
        name: id,
        source: source,
        conditions: conditions,
        sceneId: 'scene',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: priority,
        order: order,
      ),
      enabled: enabled,
    );
