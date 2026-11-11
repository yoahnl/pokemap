import 'package:map_core/map_core_domain.dart';

NarrativeEventConditionExpression changeEventConditionGroupKind(
  NarrativeEventConditionExpression group, {
  required bool any,
}) {
  final children = switch (group) {
    NarrativeEventConditionAll(:final children) => children,
    NarrativeEventConditionAny(:final children) => children,
    _ => throw ArgumentError.value(group, 'group'),
  };
  return any
      ? NarrativeEventConditionExpression.any(children)
      : NarrativeEventConditionExpression.all(children);
}

NarrativeEventConditionExpression rebuildEventConditionGroup(
  NarrativeEventConditionExpression group,
  List<NarrativeEventConditionExpression> children,
) => group is NarrativeEventConditionAny
    ? NarrativeEventConditionExpression.any(children)
    : NarrativeEventConditionExpression.all(children);

NarrativeEventConditionExpression removeEventConditionChild(
  NarrativeEventConditionExpression group,
  int index,
) => rebuildEventConditionGroup(
  group,
  [
    ...switch (group) {
      NarrativeEventConditionAll(:final children) => children,
      NarrativeEventConditionAny(:final children) => children,
      _ => throw ArgumentError.value(group, 'group'),
    },
  ]..removeAt(index),
);

List<NarrativeEventConditionExpression> eventConditionGroupChildren(
  NarrativeEventConditionExpression value,
) => switch (value) {
  NarrativeEventConditionAll(:final children) => children,
  NarrativeEventConditionAny(:final children) => children,
  _ => const <NarrativeEventConditionExpression>[],
};

bool canInvertEventCondition(NarrativeEventConditionExpression value) =>
    value is NarrativeEventConditionLeaf ||
    value is! NarrativeEventConditionNot &&
        eventConditionGroupChildren(value).isNotEmpty;

NarrativeEventConditionExpression invertedEventCondition(
  NarrativeEventConditionExpression value,
) => NarrativeEventConditionExpression.not(value);

NarrativeEventConditionExpression withEventConditionChild(
  NarrativeEventConditionExpression group,
  int index,
  NarrativeEventConditionExpression child,
) => rebuildEventConditionGroup(
  group,
  [...eventConditionGroupChildren(group)]..[index] = child,
);

NarrativeEventConditionExpression withAddedEventCondition(
  NarrativeEventConditionExpression value,
  NarrativeEventCondition condition,
) {
  final leaf = NarrativeEventConditionExpression.leaf(condition);
  return value is NarrativeEventConditionLeaf
      ? leaf
      : rebuildEventConditionGroup(value, [
          ...eventConditionGroupChildren(value),
          leaf,
        ]);
}

NarrativeEventConditionExpression withAddedEventConditionGroup(
  NarrativeEventConditionExpression group,
  NarrativeEventCondition condition,
) => rebuildEventConditionGroup(group, [
  ...eventConditionGroupChildren(group),
  NarrativeEventConditionExpression.all([
    NarrativeEventConditionExpression.leaf(condition),
  ]),
]);

NarrativeEventConditionExpression groupedEventCondition(
  NarrativeEventConditionExpression leaf,
  NarrativeEventCondition other,
) => NarrativeEventConditionExpression.all([
  leaf,
  NarrativeEventConditionExpression.leaf(other),
]);
