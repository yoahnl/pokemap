import 'package:avelune_studio/features/events/application/behaviour/behaviour_cases.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

final _talk = NarrativeEventSourceRef.entityInteract('map', 'npc');
final _bump = NarrativeEventSourceRef.entityBump('map', 'npc');
final _autorun = NarrativeEventSourceRef.entityAutorun('map', 'npc');

String _id(String suffix) => 'evt_01a16b62-614a-7000-8000-0000000000$suffix';

NarrativeEventRecord _case(
  String suffix, {
  int priority = 0,
  int order = 0,
  NarrativeEventSourceRef? source,
  bool enabled = true,
  bool always = false,
  NarrativeEventReusePolicy reuse = NarrativeEventReusePolicy.reusable,
  NarrativeEventParallelPolicy? parallel,
  bool legacy = false,
}) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: _id(suffix),
    name: 'Case $suffix',
    source: source ?? _talk,
    conditions: always
        ? const []
        : [NarrativeEventCondition.fact('fact_$suffix', true)],
    sceneId: 'scene_$suffix',
    reusePolicy: reuse,
    priority: priority,
    order: order,
    parallelPolicy: parallel,
  ),
  enabled: enabled,
  activeInLegacyMode: legacy,
);

NarrativeEventRecord _draft(String suffix, {int priority = 0, int order = 0}) =>
    NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: _id(suffix),
        name: 'Draft $suffix',
        source: _talk,
        conditions: const [],
        priority: priority,
        order: order,
      ),
    );

List<String> _ids(Iterable<NarrativeEventRecord> records) => [
  for (final record in records) record.id.substring(record.id.length - 2),
];

List<NarrativeEventRecord> _apply(
  List<NarrativeEventRecord> cases,
  List<NarrativeEventRecord> changed,
) {
  final byId = {for (final record in changed) record.id: record};
  return [for (final record in cases) byId[record.id] ?? record];
}

List<NarrativeEventRecord> _engineOrder(List<NarrativeEventRecord> records) {
  final configured = [
    for (final record in records)
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: record.id,
          name: record.name,
          source: _talk,
          conditions: const [],
          sceneId: 'scene',
          reusePolicy: NarrativeEventReusePolicy.reusable,
          priority: record.priority,
          order: record.order,
        ),
        enabled: true,
      ),
  ];
  final byId = {for (final record in records) record.id: record};
  return [
    for (final record in narrativeEventDispatchCandidates(
      configured,
      _talk,
      EventSystemMode.v2Only,
    ))
      byId[record.id]!,
  ];
}

void main() {
  group('listing', () {
    test('groups per trigger in the order the engine tries them', () {
      final groups = behaviourCaseGroups([
        _case('01', priority: 0, order: 3),
        _case('02', priority: 5, order: 9),
        _case('03', source: _bump),
        _case('04', priority: 0, order: 1),
        _case('06', priority: 0, order: 1),
        _case('05', priority: 0, order: 1),
      ], EventSystemMode.v2Only);
      expect(groups.map((group) => group.kind), [
        NarrativeEventSourceKind.entityInteract,
        NarrativeEventSourceKind.entityBump,
      ]);
      expect(_ids(groups.first.records), ['02', '04', '05', '06', '01']);
      expect(_ids(groups.last.records), ['03']);
    });

    test('keeps drafts in place and labels the state of each case', () {
      final groups = behaviourCaseGroups([
        _draft('01', order: 1),
        _case('02', order: 0),
        _case('03', order: 2, enabled: false),
        _case('04', order: 3, legacy: false),
      ], EventSystemMode.legacyOnly);
      expect(_ids(groups.single.records), ['02', '01', '03', '04']);
      expect(groups.single.cases.map((item) => item.state), [
        BehaviourCaseState.outsideLegacyMode,
        BehaviourCaseState.draft,
        BehaviourCaseState.outsideLegacyMode,
        BehaviourCaseState.outsideLegacyMode,
      ]);
      final v2 = behaviourCaseGroups([
        _case('02'),
        _case('03', order: 2, enabled: false),
      ], EventSystemMode.v2Only);
      expect(v2.single.cases.map((item) => item.state), [
        BehaviourCaseState.tried,
        BehaviourCaseState.disabled,
      ]);
    });
  });

  group('moving a case', () {
    final sameGroup = [
      _case('01', order: 0),
      _case('02', order: 1),
      _case('03', order: 2),
      _case('04', order: 3),
    ];

    test('moving down rewrites only the orders that must change', () {
      final changed = moveBehaviourCase(sameGroup, 0, 2);
      final result = _engineOrder(_apply(sameGroup, changed));
      expect(_ids(result), ['02', '03', '01', '04']);
      expect(_ids(changed), ['01']);
      expect(changed.single.order, 3);
      expect(changed.single.priority, 0);
    });

    test('moving up to the top renumbers below when nothing fits above', () {
      final changed = moveBehaviourCase(sameGroup, 3, 0);
      expect(_ids(_engineOrder(_apply(sameGroup, changed))), [
        '04',
        '01',
        '02',
        '03',
      ]);
      expect(_ids(changed), unorderedEquals(['04', '01']));
    });

    test('uses free gaps without touching neighbours', () {
      final gaps = [
        _case('01', order: 0),
        _case('02', order: 10),
        _case('03', order: 20),
      ];
      final changed = moveBehaviourCase(gaps, 2, 1);
      expect(_ids(_engineOrder(_apply(gaps, changed))), ['01', '03', '02']);
      expect(_ids(changed), ['03']);
    });

    test('a no-op move changes nothing', () {
      expect(moveBehaviourCase(sameGroup, 1, 1), isEmpty);
    });

    test('crossing into a lower priority group takes its priority', () {
      final mixed = [
        _case('01', priority: 10, order: 0),
        _case('02', priority: 10, order: 1),
        _case('03', priority: 5, order: 0),
        _case('04', priority: 5, order: 1),
      ];
      final changed = moveBehaviourCase(mixed, 0, 2);
      final result = _engineOrder(_apply(mixed, changed));
      expect(_ids(result), ['02', '03', '01', '04']);
      final moved = changed.singleWhere((record) => record.id == _id('01'));
      expect(moved.priority, 5);
      expect(changed.every((record) => record.priority == 5), isTrue);
      expect(_ids(changed), isNot(contains('02')));
    });

    test('crossing into a higher priority group takes its priority', () {
      final mixed = [
        _case('01', priority: 10, order: 0),
        _case('02', priority: 5, order: 0),
        _case('03', priority: 5, order: 1),
      ];
      final changed = moveBehaviourCase(mixed, 2, 0);
      expect(_ids(_engineOrder(_apply(mixed, changed))), ['03', '01', '02']);
      expect(
        changed.singleWhere((record) => record.id == _id('03')).priority,
        10,
      );
    });

    test('every move lands where asked and returns only real changes', () {
      final records = _engineOrder([
        _case('01', priority: 10, order: 0),
        _case('02', priority: 10, order: 0),
        _case('03', priority: 5, order: 0),
        _case('04', priority: 5, order: 4),
        _case('05', priority: 5, order: 4),
        _case('06', priority: 0, order: 7),
      ]);
      for (var from = 0; from < records.length; from++) {
        for (var to = 0; to < records.length; to++) {
          final changed = moveBehaviourCase(records, from, to);
          final expected = [...records]
            ..removeAt(from)
            ..insert(to, records[from]);
          final result = _engineOrder(_apply(records, changed));
          expect(_ids(result), _ids(expected), reason: '$from -> $to');
          for (final record in changed) {
            final before = records.singleWhere((r) => r.id == record.id);
            expect(
              record.order != before.order ||
                  record.priority != before.priority,
              isTrue,
            );
            if (record.id != records[from].id) {
              expect(record.priority, before.priority);
            }
          }
        }
      }
    });

    test('refuses cases that are not in engine order or mix triggers', () {
      expect(
        () => moveBehaviourCase([sameGroup[1], sameGroup[0]], 0, 1),
        throwsArgumentError,
      );
      expect(
        () =>
            moveBehaviourCase([sameGroup[0], _case('09', source: _bump)], 0, 1),
        throwsArgumentError,
      );
      expect(() => moveBehaviourCase(sameGroup, 0, 9), throwsRangeError);
    });
  });

  group('can never play', () {
    BehaviourCaseGroup group(List<NarrativeEventRecord> records) =>
        behaviourCaseGroups(records, EventSystemMode.v2Only).single;

    test('a case after an always-true reusable case is shadowed by it', () {
      final shadows = shadowedBehaviourCases(
        group([
          _case('01', order: 0),
          _case('02', order: 1, always: true),
          _case('03', order: 2),
          _case('04', order: 3, enabled: false),
        ]),
        uncertainIds: const {},
      );
      expect(
        [
          for (final shadow in shadows)
            (shadow.caseId.substring(38), shadow.shadowedBy.substring(38)),
        ],
        [('03', '02'), ('04', '02')],
      );
    });

    test('stays silent whenever the earlier case may not play', () {
      for (final first in [
        _case('02', order: 0, always: true, enabled: false),
        _case(
          '02',
          order: 0,
          always: true,
          reuse: NarrativeEventReusePolicy.oneShot,
        ),
        _case('02', order: 0),
      ]) {
        expect(
          shadowedBehaviourCases(
            group([first, _case('03', order: 1)]),
            uncertainIds: const {},
          ),
          isEmpty,
        );
      }
      expect(
        shadowedBehaviourCases(
          group([_case('02', order: 0, always: true), _case('03', order: 1)]),
          uncertainIds: {_id('02')},
        ),
        isEmpty,
      );
    });

    test('ignores parallel cases and autorun triggers', () {
      final parallel = _case(
        '02',
        order: 0,
        always: true,
        source: _autorun,
        parallel: NarrativeEventParallelPolicy(cadenceMs: 1000),
      );
      expect(
        shadowedBehaviourCases(
          group([parallel, _case('03', order: 1, source: _autorun)]),
          uncertainIds: const {},
        ),
        isEmpty,
      );
      expect(
        shadowedBehaviourCases(
          group([
            _case('02', order: 0, always: true, source: _autorun),
            _case('03', order: 1, source: _autorun),
          ]),
          uncertainIds: const {},
        ),
        isEmpty,
      );
    });
  });
}
