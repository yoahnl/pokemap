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
