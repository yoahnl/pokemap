import 'package:map_core/map_core_domain.dart';

import '../../domain/event_record_view.dart';
import 'behaviour_record_edit.dart';

enum BehaviourConditionTest { isTrue, isFalse, equalsNumber }

List<BehaviourConditionTest> behaviourConditionTests(NarrativeValueKind kind) =>
    switch (kind) {
      NarrativeValueKind.boolean => const [
        BehaviourConditionTest.isTrue,
        BehaviourConditionTest.isFalse,
      ],
      NarrativeValueKind.integer => const [BehaviourConditionTest.equalsNumber],
      NarrativeValueKind.string => const [],
    };

sealed class BehaviourConditionItem {
  const BehaviourConditionItem();

  NarrativeEventConditionExpression get expression;
}

final class BehaviourEditableCondition extends BehaviourConditionItem {
  BehaviourEditableCondition.isTrue(String factId)
    : this._(
        factId,
        BehaviourConditionTest.isTrue,
        null,
        NarrativeEventConditionLeaf(NarrativeEventCondition.fact(factId, true)),
      );

  BehaviourEditableCondition.isFalse(String factId)
    : this._(
        factId,
        BehaviourConditionTest.isFalse,
        null,
        NarrativeEventConditionLeaf(
          NarrativeEventCondition.fact(factId, false),
        ),
      );

  BehaviourEditableCondition.equalsNumber(String factId, int number)
    : this._(
        factId,
        BehaviourConditionTest.equalsNumber,
        number,
        NarrativeEventConditionLeaf(
          NarrativeEventCondition.factValue(
            factId,
            operator: NarrativeFactOperator.equals,
            expectedValue: NarrativeValue.integer(number),
          ),
        ),
      );

  const BehaviourEditableCondition._(
    this.factId,
    this.test,
    this.number,
    this.expression,
  );

  final String factId;
  final BehaviourConditionTest test;
  final int? number;

  @override
  final NarrativeEventConditionLeaf expression;
}

final class BehaviourFixedCondition extends BehaviourConditionItem {
  const BehaviourFixedCondition(this.expression);

  @override
  final NarrativeEventConditionExpression expression;
}

final class BehaviourConditions {
  BehaviourConditions._(List<BehaviourConditionItem> items, this._grouped)
    : items = List.unmodifiable(items);

  final List<BehaviourConditionItem> items;
  final bool _grouped;

  bool get fullyEditable =>
      items.every((item) => item is BehaviourEditableCondition);

  NarrativeEventConditionExpression get expression =>
      !_grouped && items.length == 1
      ? items.single.expression
      : NarrativeEventConditionExpression.all([
          for (final item in items) item.expression,
        ]);

  BehaviourConditions adding(BehaviourEditableCondition condition) =>
      BehaviourConditions._([...items, condition], _grouped);

  BehaviourConditions replacing(
    int index,
    BehaviourEditableCondition condition,
  ) {
    _requireEditable(index);
    return BehaviourConditions._([...items]..[index] = condition, _grouped);
  }

  BehaviourConditions removing(int index) {
    _requireEditable(index);
    return BehaviourConditions._([...items]..removeAt(index), _grouped);
  }

  void _requireEditable(int index) {
    RangeError.checkValidIndex(index, items, 'index');
    if (items[index] is! BehaviourEditableCondition) {
      throw ArgumentError.value(index, 'index');
    }
  }
}

BehaviourConditions readBehaviourConditions(NarrativeEventRecord record) {
  final root = record.expression;
  return root is NarrativeEventConditionAll
      ? BehaviourConditions._([
          for (final child in root.children) _item(child),
        ], true)
      : BehaviourConditions._([_item(root)], false);
}

NarrativeEventRecord writeBehaviourConditions(
  NarrativeEventRecord record,
  BehaviourConditions conditions,
) => editBehaviourRecord(record, conditionExpression: conditions.expression);

BehaviourConditionItem _item(NarrativeEventConditionExpression expression) {
  if (expression is! NarrativeEventConditionLeaf) {
    return BehaviourFixedCondition(expression);
  }
  BehaviourConditionItem fixed(Object? _, Object? _) =>
      BehaviourFixedCondition(expression);
  return expression.condition.whenTyped<BehaviourConditionItem>(
    fact: (factId, operator, value) {
      if (operator != NarrativeFactOperator.equals) {
        return BehaviourFixedCondition(expression);
      }
      return switch (value.kind) {
        NarrativeValueKind.boolean => BehaviourEditableCondition._(
          factId,
          value.boolValue
              ? BehaviourConditionTest.isTrue
              : BehaviourConditionTest.isFalse,
          null,
          expression,
        ),
        NarrativeValueKind.integer => BehaviourEditableCondition._(
          factId,
          BehaviourConditionTest.equalsNumber,
          value.intValue,
          expression,
        ),
        NarrativeValueKind.string => BehaviourFixedCondition(expression),
      };
    },
    narrativeEventConsumed: fixed,
    mapEventInstanceBoolean: (_, _, _, _) =>
        BehaviourFixedCondition(expression),
    civilWeekday: fixed,
    periodicRewardAvailable: fixed,
  );
}
