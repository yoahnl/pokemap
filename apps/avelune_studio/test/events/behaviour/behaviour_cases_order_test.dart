import 'package:avelune_studio/features/events/application/behaviour/behaviour_cases.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

final _talk = NarrativeEventSourceRef.entityInteract('map', 'npc');

NarrativeEventRecord _case(int index, {int priority = 0, required int order}) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: 'evt_01a16b62-614a-7000-8000-0000000000${index}0',
        name: 'Case $index',
        source: _talk,
        conditions: const [],
        sceneId: 'scene_$index',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: priority,
        order: order,
      ),
      enabled: true,
    );

void main() {
  test('a move never leaves two cases of one priority on the same order', () {
    final sets = [
      [for (var index = 1; index <= 4; index++) _case(index, order: index - 1)],
      [_case(1, order: 0), _case(2, order: 10), _case(3, order: 20)],
      [
        _case(1, priority: 10, order: 0),
        _case(2, priority: 10, order: 1),
        _case(3, priority: 5, order: 0),
        _case(4, priority: 5, order: 1),
      ],
    ];
    for (final cases in sets) {
      for (var from = 0; from < cases.length; from++) {
        for (var to = 0; to < cases.length; to++) {
          final changed = {
            for (final record in moveBehaviourCase(cases, from, to))
              record.id: record,
          };
          final result = [
            for (final record in cases) changed[record.id] ?? record,
          ];
          expect(
            {for (final record in result) (record.priority, record.order)},
            hasLength(result.length),
            reason: '$from -> $to',
          );
          expect(result.every((record) => record.order >= 0), isTrue);
        }
      }
    }
  });
}
