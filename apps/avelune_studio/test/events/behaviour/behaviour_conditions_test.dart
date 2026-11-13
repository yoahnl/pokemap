import 'dart:convert';

import 'package:avelune_studio/features/events/application/behaviour/behaviour_conditions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

NarrativeEventRecord _record(Map<String, Object?> definitionPatch) =>
    NarrativeEventRecord.fromJson({
      'state': 'configured',
      'definition': {
        'id': 'evt_01a16b62-614a-741c-be2e-18a338e7bcd6',
        'name': 'Case',
        'source': {'kind': 'mapEnter', 'mapId': 'map'},
        'conditions': <Object?>[],
        'sceneId': 'scene',
        'reusePolicy': 'oneShot',
        'priority': 0,
        'order': 0,
        ...definitionPatch,
      },
      'enabled': true,
    });

NarrativeEventRecord _draft(Map<String, Object?> patch) =>
    NarrativeEventRecord.fromJson({
      'state': 'draft',
      'draft': {
        'id': 'evt_01a16b62-614a-741c-be2e-18a338e7bcd7',
        'name': 'Draft',
        'conditions': <Object?>[],
        'priority': 0,
        'order': 0,
        ...patch,
      },
    });

const _boolFact = {
  'kind': 'fact',
  'factId': 'fact_door',
  'expectedValue': false,
};
const _typedBoolFact = {
  'kind': 'fact',
  'factId': 'fact_lamp',
  'operator': 'equals',
  'valueType': 'bool',
  'expectedValue': true,
};
const _intFact = {
  'kind': 'fact',
  'factId': 'fact_phase',
  'operator': 'equals',
  'valueType': 'int',
  'expectedValue': 2,
};
const _greater = {
  'kind': 'fact',
  'factId': 'fact_phase',
  'operator': 'greaterThan',
  'valueType': 'int',
  'expectedValue': 1,
};
const _consumed = {
  'kind': 'narrativeEventConsumed',
  'eventId': 'evt_01a16b62-614a-7302-a9a2-0ab2445543de',
  'expectedValue': true,
};
const _weekday = {
  'kind': 'civilWeekday',
  'weekday': 'monday',
  'expectedValue': true,
};

Map<String, Object?> _leaf(Map<String, Object?> condition) => {
  'kind': 'leaf',
  'condition': condition,
};

String _json(NarrativeEventRecord record) => jsonEncode(record.toJson());

void main() {
  final shapes = <String, NarrativeEventRecord>{
    'no condition': _record({}),
    'legacy AND of facts': _record({
      'conditions': [_boolFact, _intFact, _typedBoolFact],
    }),
    'legacy AND with fixed leaves': _record({
      'conditions': [_boolFact, _consumed, _weekday, _greater],
    }),
    'single leaf expression': _record({
      'conditions': [_boolFact],
      'conditionExpression': _leaf(_boolFact),
    }),
    'root any': _record({
      'conditions': [_boolFact, _intFact],
      'conditionExpression': {
        'kind': 'any',
        'children': [_leaf(_boolFact), _leaf(_intFact)],
      },
    }),
    'root not': _record({
      'conditions': [_boolFact],
      'conditionExpression': {'kind': 'not', 'child': _leaf(_boolFact)},
    }),
    'nested all inside all': _record({
      'conditions': [_boolFact, _intFact, _consumed],
      'conditionExpression': {
        'kind': 'all',
        'children': [
          _leaf(_boolFact),
          {
            'kind': 'all',
            'children': [_leaf(_intFact), _leaf(_consumed)],
          },
        ],
      },
    }),
    'draft with any': _draft({
      'conditions': [_boolFact, _weekday],
      'conditionExpression': {
        'kind': 'any',
        'children': [_leaf(_boolFact), _leaf(_weekday)],
      },
    }),
  };

  group('read then write without edits', () {
    for (final entry in shapes.entries) {
      test('keeps ${entry.key} byte-for-byte', () {
        final record = entry.value;
        final written = writeBehaviourConditions(
          record,
          readBehaviourConditions(record),
        );
        expect(_json(written), _json(record));
        expect(written, record);
      });
    }
  });

  test('exposes facts as editable and other forms as fixed', () {
    final view = readBehaviourConditions(
      shapes['legacy AND with fixed leaves']!,
    );
    expect(view.items.map((item) => item.runtimeType), [
      BehaviourEditableCondition,
      BehaviourFixedCondition,
      BehaviourFixedCondition,
      BehaviourFixedCondition,
    ]);
    final fact = view.items.first as BehaviourEditableCondition;
    expect(fact.factId, 'fact_door');
    expect(fact.test, BehaviourConditionTest.isFalse);
    expect(view.fullyEditable, isFalse);

    final facts = readBehaviourConditions(shapes['legacy AND of facts']!);
    expect(facts.fullyEditable, isTrue);
    final number = facts.items[1] as BehaviourEditableCondition;
    expect(number.test, BehaviourConditionTest.equalsNumber);
    expect(number.number, 2);
    expect(
      (facts.items[2] as BehaviourEditableCondition).test,
      BehaviourConditionTest.isTrue,
    );
  });

  test('editing an editable leaf keeps fixed leaves byte-for-byte', () {
    final record = shapes['legacy AND with fixed leaves']!;
    final view = readBehaviourConditions(record);
    final edited = writeBehaviourConditions(
      record,
      view
          .replacing(0, BehaviourEditableCondition.equalsNumber('fact_gate', 3))
          .adding(BehaviourEditableCondition.isTrue('fact_new')),
    );
    final conditions =
        (edited.toJson()['definition']! as Map<String, Object?>)['conditions']!
            as List<Object?>;
    expect(
      jsonEncode(conditions.sublist(1, 4)),
      jsonEncode([_consumed, _weekday, _greater]),
    );
    expect(conditions.first, {
      'kind': 'fact',
      'factId': 'fact_gate',
      'operator': 'equals',
      'valueType': 'int',
      'expectedValue': 3,
    });
    expect(conditions.last, {
      'kind': 'fact',
      'factId': 'fact_new',
      'expectedValue': true,
    });
    final removed = writeBehaviourConditions(record, view.removing(0));
    expect(
      jsonEncode(
        (removed.toJson()['definition']! as Map<String, Object?>)['conditions'],
      ),
      jsonEncode([_consumed, _weekday, _greater]),
    );
  });

  test('adding to a root any wraps it untouched under AND', () {
    final record = shapes['root any']!;
    final edited = writeBehaviourConditions(
      record,
      readBehaviourConditions(record)
          .adding(BehaviourEditableCondition.isFalse('fact_new')),
    );
    final expression =
        (edited.toJson()['definition']!
            as Map<String, Object?>)['conditionExpression']!;
    expect(
      jsonEncode(expression),
      jsonEncode({
        'kind': 'all',
        'children': [
          {
            'kind': 'any',
            'children': [_leaf(_boolFact), _leaf(_intFact)],
          },
          _leaf({'kind': 'fact', 'factId': 'fact_new', 'expectedValue': false}),
        ],
      }),
    );
  });

  test('fixed items and out-of-range indexes cannot be edited', () {
    final view = readBehaviourConditions(
      shapes['legacy AND with fixed leaves']!,
    );
    expect(
      () => view.replacing(1, BehaviourEditableCondition.isTrue('fact_x')),
      throwsArgumentError,
    );
    expect(() => view.removing(2), throwsArgumentError);
    expect(() => view.removing(9), throwsRangeError);
  });

  test('removing the last editable condition leaves an unconditional case', () {
    final record = shapes['single leaf expression']!;
    final edited = writeBehaviourConditions(
      record,
      readBehaviourConditions(record).removing(0),
    );
    expect(
      (edited.toJson()['definition']! as Map<String, Object?>)['conditions'],
      isEmpty,
    );
    expect(
      (edited.toJson()['definition']! as Map<String, Object?>).containsKey(
        'conditionExpression',
      ),
      isFalse,
    );
  });

  test('offers only the tests that match a fact type', () {
    expect(behaviourConditionTests(NarrativeValueKind.boolean), [
      BehaviourConditionTest.isTrue,
      BehaviourConditionTest.isFalse,
    ]);
    expect(behaviourConditionTests(NarrativeValueKind.integer), [
      BehaviourConditionTest.equalsNumber,
    ]);
    expect(behaviourConditionTests(NarrativeValueKind.string), isEmpty);
  });
}
