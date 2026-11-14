import 'package:avelune_studio/features/events/application/behaviour/behaviour_cases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'behaviour_cases_fixtures.dart';

void main() {
  group('can never play', () {
    BehaviourCaseGroup group(List<NarrativeEventRecord> records) =>
        behaviourCaseGroups(records, EventSystemMode.v2Only).single;

    test('a case after an always-true reusable case is shadowed by it', () {
      final shadows = shadowedBehaviourCases(
        group([
          behaviourCase('01', order: 0),
          behaviourCase('02', order: 1, always: true),
          behaviourCase('03', order: 2),
          behaviourCase('04', order: 3, enabled: false),
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
        behaviourCase('02', order: 0, always: true, enabled: false),
        behaviourCase(
          '02',
          order: 0,
          always: true,
          reuse: NarrativeEventReusePolicy.oneShot,
        ),
        behaviourCase('02', order: 0),
      ]) {
        expect(
          shadowedBehaviourCases(
            group([first, behaviourCase('03', order: 1)]),
            uncertainIds: const {},
          ),
          isEmpty,
        );
      }
      expect(
        shadowedBehaviourCases(
          group([
            behaviourCase('02', order: 0, always: true),
            behaviourCase('03', order: 1),
          ]),
          uncertainIds: {eventId('02')},
        ),
        isEmpty,
      );
    });

    test('ignores parallel cases and autorun triggers', () {
      final parallel = behaviourCase(
        '02',
        order: 0,
        always: true,
        source: _autorun,
        parallel: NarrativeEventParallelPolicy(cadenceMs: 1000),
      );
      expect(
        shadowedBehaviourCases(
          group([parallel, behaviourCase('03', order: 1, source: _autorun)]),
          uncertainIds: const {},
        ),
        isEmpty,
      );
      expect(
        shadowedBehaviourCases(
          group([
            behaviourCase('02', order: 0, always: true, source: _autorun),
            behaviourCase('03', order: 1, source: _autorun),
          ]),
          uncertainIds: const {},
        ),
        isEmpty,
      );
    });
  });
}

final _autorun = NarrativeEventSourceRef.entityAutorun('map', 'npc');
